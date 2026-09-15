// utils/db.js —— CloudBase 云数据库操作封装
// 统一处理：childId 归属过滤（多家长共享同一孩子）、软删（isDeleted）、
// 同步三件套、uuid 主键、毫秒时间戳。所有查询默认排除 isDeleted=true。
// 云不可用/查询失败时返回空集合，保证页面可渲染空态（MVP 友好）。
//
// 【共享模型（2026-09）】以「孩子」为中心，childId 作为共享锚点：
//   - child_members：孩子↔家长 的成员关系（一个孩子可被多位家长共享）
//   - 业务数据集合（daily_records/books/todos/schedule_items/reading_logs/
//     series/weekly_reports）归属过滤只按 childId，不再按 ownerId ——
//     凡加入该孩子的家长均可读写同一份数据。
//   - children 集合不再按 ownerId 过滤，改由 child_members 反查可见孩子列表。
//   - ownerId 仍写入每条业务数据（标记「谁创建的」，用于展示/审计），但不参与过滤。

const auth = require('./auth');

/** 集合名常量 */
const COLLECTIONS = {
  users: 'users',
  children: 'children',
  // 共享：孩子↔家长 成员关系 & 邀请码
  childMembers: 'child_members',
  childInvites: 'child_invites',
  dailyRecords: 'daily_records',
  series: 'series',
  books: 'books',
  readingLogs: 'reading_logs',
  scheduleItems: 'schedule_items',
  // 课程库模板（课程分类）：以孩子为锚点共享，schedule_items 引用其 uuid（templateId）
  courseTemplates: 'course_templates',
  todos: 'todos',
  weeklyReports: 'weekly_reports',
  // 公共只读集合：官方/共建精选书库（无 ownerId/childId 归属，所有人可读）
  bookLibrary: 'book_library',
};

// CloudBase 安全规则查询身份占位符：服务端会替换成当前调用者 openid。
// 必须在 where 中显式使用该值，规则引擎才能证明查询结果满足 auth.openid 约束。
const AUTH_OPENID = '{openid}';

// 以孩子为锚点、走安全规则 "auth.openid in doc.members" 的共享业务集合。
// 这些集合的写操作（更新 / 软删）统一经 childShare 受信端执行：前端 doc().update()
// 仍受 update 规则限制，历史数据 / 其他家长创建的文档若 members 不含当前 openid，会被
// -502003 DATABASE_PERMISSION_DENIED 拒绝（课表拖拽调时间、长按删除即命中）。
// ⚠️ 必须与 cloudfunctions/childShare/index.js 的 BIZ_COLLECTIONS 保持一致。
const SHARED_BIZ_COLLECTIONS = [
  'daily_records', 'books', 'todos', 'schedule_items',
  'reading_logs', 'series', 'weekly_reports', 'course_templates',
];

function db() {
  if (!wx.cloud) throw new Error('云能力不可用');
  return wx.cloud.database();
}
function _() {
  return db().command;
}

/** 生成跨端稳定 uuid（对齐 drift uuid 主键） */
function genUuid() {
  const s = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).slice(1);
  return `${s()}${s()}-${s()}-${s()}-${s()}-${s()}${s()}${s()}`;
}

/** 当前上下文归属：{ ownerId, childId } */
function scope() {
  const app = getApp();
  return {
    ownerId: auth.ownerId(),
    childId: (app && app.globalData && app.globalData.activeChildId) || '',
  };
}

// ============================================================
// 通用 CRUD（按 uuid 主键；软删；带归属过滤）
// ============================================================

// 小程序端 collection.get() 单次最多返回 20 条（wx.cloud 硬约束）。
const PAGE_SIZE = 20;
// listAllPaged 默认最多拉取的总条数上限（防止异常数据导致死循环/拉爆）。
const PAGE_CAP = 200;
// getTempFileURL 单次最多解析 50 个 fileID。
const TEMP_URL_BATCH = 50;

/**
 * 构造归属过滤 + 排除软删的 where 条件。
 * 【共享模型】业务数据只按 childId 过滤，不再按 ownerId —— 加入该孩子的
 * 所有家长共享同一份数据。ownerId 仅作登录闸门（未登录一律不允许查）。
 * ⚠️ withChild:false（不带孩子归属）已无业务集合使用（children 走
 *    listChildrenForUser 单独反查），此处保留兜底：无 childId 时按传入
 *    where 过滤，若 where 也为空则返回 null 避免全表裸查泄露。
 */
function _buildWhere(opts = {}) {
  const { ownerId, childId } = scope();
  const openid = auth.openid ? auth.openid() : '';
  // 未登录：一律不允许查
  if (!ownerId || !openid) return null;
  // 要求带孩子归属（默认 true）但未选孩子：强制空结果，防止多孩子交叉泄露
  if (opts.withChild !== false && !childId) return null;
  if (opts.withChild === false) {
    // 防御：无额外 where 时不允许无条件全表查询
    if (!opts.where || !Object.keys(opts.where).length) return null;
    return Object.assign({ isDeleted: _().neq(true) }, opts.where);
  }
  return Object.assign(
    { childId, members: AUTH_OPENID, isDeleted: false },
    opts.where || {}
  );
}

/**
 * 列表查询（单次，最多 20 条）。默认按归属(ownerId[/childId]) + 排除软删。
 * ⚠️ 受小程序端 20 条上限影响：结果可能被静默截断。
 *    对可能 >20 条的数据（记录/书籍/打卡等）请改用 {@link listAllPaged}。
 * @param {string} col 集合名
 * @param {object} opts { where, orderBy:[field,'desc'], limit, withChild:true }
 */
async function list(col, opts = {}) {
  try {
    const where = _buildWhere(opts);
    if (!where) return [];
    let q = db().collection(col).where(where);
    if (opts.orderBy) q = q.orderBy(opts.orderBy[0], opts.orderBy[1] || 'asc');
    if (opts.limit) q = q.limit(opts.limit);
    const { data } = await q.get();
    return data || [];
  } catch (err) {
    console.warn(`[db] list(${col}) 失败，返回空`, err);
    return [];
  }
}

/**
 * 分页全量拉取，破解小程序端「单次查询最多 20 条」上限。
 * 内部 skip/limit(20) 循环，直到返回不足一页或达到 cap 上限为止。
 * 日历三源聚合、记录/书籍列表等一律走此方法保证数据完整性。
 * @param {string} col 集合名
 * @param {object} opts { where, orderBy:[field,'desc'], withChild:true }
 * @param {number} cap 总条数上限（默认 200），防御性兜底避免异常数据拉爆
 * @returns {Promise<Array>} 全量结果（可能因 cap 截断，会告警）
 */
async function listAllPaged(col, opts = {}, cap = PAGE_CAP) {
  try {
    const where = _buildWhere(opts);
    if (!where) return [];
    const out = [];
    let skip = 0;
    // 循环拉取，每次 20 条，直到「返回 <20」或「累计达 cap」
    while (skip < cap) {
      let q = db().collection(col).where(where);
      if (opts.orderBy) q = q.orderBy(opts.orderBy[0], opts.orderBy[1] || 'asc');
      // eslint-disable-next-line no-await-in-loop
      const { data } = await q.skip(skip).limit(PAGE_SIZE).get();
      const batch = data || [];
      out.push(...batch);
      if (batch.length < PAGE_SIZE) break; // 最后一页
      skip += PAGE_SIZE;
    }
    if (out.length >= cap) {
      console.warn(`[db] listAllPaged(${col}) 达到 cap=${cap} 上限，可能仍有更多数据未拉取`);
    }
    return out;
  } catch (err) {
    console.warn(`[db] listAllPaged(${col}) 失败，返回空`, err);
    return [];
  }
}

/**
 * 通过受信云函数读取当前孩子的共享业务集合。
 * 列表读取不再依赖前端安全规则的查询可证明性；云函数会校验 child_members。
 */
async function listSharedData(col) {
  const { ownerId, childId } = scope();
  if (!ownerId || !childId) return [];
  try {
    const response = await wx.cloud.callFunction({
      name: 'childShare',
      data: { action: 'listChildData', collection: col, childId },
    });
    const result = (response && response.result) || {};
    if (!result.ok) throw new Error(result.error || `读取 ${col} 失败`);
    return Array.isArray(result.items) ? result.items : [];
  } catch (err) {
    console.warn(`[db] listSharedData(${col}) 失败，返回空`, err);
    return [];
  }
}

/**
 * 通过受信云函数获取当前孩子权威的 members(openid) 数组。
 * 前端不能直读 children（安全规则无法证明 members 数组查询），create() 写入前
 * 用它盖 members，确保同孩子的其他家长也能读写这条新数据。
 */
async function fetchChildMembers(childId) {
  if (!childId) return [];
  try {
    const response = await wx.cloud.callFunction({
      name: 'childShare',
      data: { action: 'getChildMembers', childId },
    });
    const result = (response && response.result) || {};
    if (result.ok && Array.isArray(result.members)) return result.members.slice();
  } catch (err) {
    console.warn('[db] fetchChildMembers 失败', err);
  }
  return [];
}


function sortByField(items, field, direction = 'asc') {
  const factor = direction === 'desc' ? -1 : 1;
  return items.slice().sort((a, b) => {
    const av = a[field];
    const bv = b[field];
    if (av === bv) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    return (av < bv ? -1 : 1) * factor;
  });
}

/**
 * 公共集合分页全量拉取（**不做 ownerId/childId 归属过滤**）。
 * 用于 book_library 等「所有人可读」的公共只读集合，破除单次 20 条上限。
 * @param {string} col 集合名
 * @param {object} where 查询条件（可为空对象，表示不加过滤）
 * @param {Array} orderBy [field, 'asc'|'desc']，可选
 * @param {number} cap 总条数上限（默认 500，公共集合体量更大）
 * @returns {Promise<Array>} 全量结果（异常返回空数组保证空态可渲染）
 */
async function listAllPublic(col, where = {}, orderBy = null, cap = 500) {
  try {
    const baseWhere = Object.assign({ isDeleted: _().neq(true) }, where);
    const hasWhere = Object.keys(baseWhere).length > 0;
    const out = [];
    let skip = 0;
    while (skip < cap) {
      let q = db().collection(col);
      if (hasWhere) q = q.where(baseWhere);
      if (orderBy) q = q.orderBy(orderBy[0], orderBy[1] || 'asc');
      // eslint-disable-next-line no-await-in-loop
      const { data } = await q.skip(skip).limit(PAGE_SIZE).get();
      const batch = data || [];
      out.push(...batch);
      if (batch.length < PAGE_SIZE) break;
      skip += PAGE_SIZE;
    }
    if (out.length >= cap) {
      console.warn(`[db] listAllPublic(${col}) 达到 cap=${cap} 上限，可能仍有更多数据未拉取`);
    }
    return out;
  } catch (err) {
    console.warn(`[db] listAllPublic(${col}) 失败，返回空`, err);
    return [];
  }
}

/** 按 uuid 取单条（uuid 全局唯一，共享模型下不再按 ownerId 过滤，
 *  凡加入该孩子的家长均可读取同一条数据）。
 *  ⚠️ 前端安全规则无法证明 members 数组查询，直读会被 DATABASE_PERMISSION_DENIED；
 *  故统一走 childShare 云函数读取当前孩子的该集合数据后按 uuid 命中（与列表读取同源）。 */
async function getByUuid(col, uuid) {
  try {
    const openid = auth.openid ? auth.openid() : '';
    if (!openid || !uuid) return null;
    const items = await listSharedData(col);
    return items.find((item) => item.uuid === uuid) || null;
  } catch (err) {
    console.warn(`[db] getByUuid(${col}) 失败`, err);
    return null;
  }
}

/**
 * 新增。自动补齐 uuid / 归属 / 同步三件套。
 * @returns {Promise<object>} 写入的文档（含 uuid）
 */
async function create(col, doc, { withChild = true } = {}) {
  const { ownerId, childId } = scope();
  if (!ownerId) throw new Error('未登录，无法写入');
  const now = Date.now();
  // 归属口径与 _buildWhere 对齐：withChild=true 但 childId 空时不写 childId，
  // 同时读层会强制 null（禁止归属模糊的写入，后续页面层会在 childId 空时拦截写操作）
  const scopeFields = Object.assign(
    { ownerId },
    withChild && childId ? { childId } : {}
  );
  // 共享鉴权：给文档盖 members(openid 数组)，供安全规则 "auth.openid in doc.members" 判定。
  // 安全规则只认 auth.openid，故 members 存原始 openid（非 ownerId）。
  //   - children：以创建者自身 openid 起步（后续成员由 childShare 云函数同步维护）
  //   - 业务集合：从所属 children 文档复制 members，确保同孩子家长共享读写权
  let members;
  const myOpenid = auth.openid ? auth.openid() : '';
  if (col === COLLECTIONS.children) {
    members = myOpenid ? [myOpenid] : [];
  } else if (withChild && childId) {
    // 前端不能直读 children，改由云函数返回权威 members(openid) 盖章，
    // 确保同孩子的其他家长也能读写这条新数据。
    members = await fetchChildMembers(childId);
    if (myOpenid && members.indexOf(myOpenid) === -1) members.push(myOpenid);
  }
  const payload = Object.assign(
    {
      uuid: genUuid(),
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    },
    scopeFields,
    members ? { members } : {},
    doc
  );
  await db().collection(col).add({ data: payload });
  return payload;
}

/** 按 uuid 更新（自动刷新 updatedAt）。共享模型下按 uuid 定位（不再按
 *  ownerId），加入该孩子的家长均可编辑同一条数据。
 *  ⚠️ 共享业务集合（SHARED_BIZ_COLLECTIONS）的写操作走 childShare 受信端：前端
 *  doc().update() 仍受 update 安全规则限制，历史数据 / 其他家长创建的文档若 members 不含
 *  当前 openid 会 -502003；受信端先校验成员身份再以管理员权限按 uuid 更新。
 *  其余集合（children/users 等各有自身规则）仍在前端按 uuid 命中后按 _id 更新。 */
async function updateByUuid(col, uuid, patch) {
  const openid = auth.openid ? auth.openid() : '';
  if (!openid) throw new Error('未登录，无法更新');
  if (SHARED_BIZ_COLLECTIONS.indexOf(col) !== -1) {
    const { childId } = scope();
    if (!childId) throw new Error('未选择孩子，无法更新');
    const response = await wx.cloud.callFunction({
      name: 'childShare',
      data: { action: 'updateChildData', collection: col, childId, uuid, patch },
    });
    const result = (response && response.result) || {};
    if (!result.ok) throw new Error(result.error || `更新 ${col} 失败`);
    return true;
  }
  const { data } = await db()
    .collection(col)
    .where({ uuid, members: AUTH_OPENID })
    .limit(1)
    .get();
  if (!data || !data.length) throw new Error('记录不存在');
  await db()
    .collection(col)
    .doc(data[0]._id)
    .update({ data: Object.assign({}, patch, { updatedAt: Date.now() }) });
  return true;
}

/** 软删除（isDeleted=true，保证可同步） */
async function softDelete(col, uuid) {
  return updateByUuid(col, uuid, { isDeleted: true });
}

// ============================================================
// 业务快捷方法：records / books / children / scheduleItems / readingLogs
// 读列表统一走 listAllPaged 破 20 条上限，保证聚合/列表数据完整。
// ============================================================

const records = {
  /** 某日/某月记录列表，按 eventDate 倒序 */
  async listByRange(startMs, endMs) {
    const items = await listSharedData(COLLECTIONS.dailyRecords);
    return sortByField(
      items.filter((item) => item.eventDate >= startMs && item.eventDate < endMs),
      'eventDate',
      'desc'
    );
  },
  /** 全部记录（倒序）。cap 控制最大返回条数，默认 200 */
  async listAll(cap = 200) {
    const items = await listSharedData(COLLECTIONS.dailyRecords);
    return sortByField(items, 'eventDate', 'desc').slice(0, cap);
  },
  create(rec) {
    // rec: { title, note, tags[], imageFileIds[], category, mood, source, eventDate, durationMinutes }
    return create(COLLECTIONS.dailyRecords, Object.assign({ source: 'manual' }, rec));
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.dailyRecords, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.dailyRecords, uuid);
  },
};

const books = {
  async listAll() {
    const items = await listSharedData(COLLECTIONS.books);
    return sortByField(items, 'updatedAt', 'desc');
  },
  async listByStatus(status) {
    const items = await listSharedData(COLLECTIONS.books);
    return sortByField(items.filter((item) => item.status === status), 'updatedAt', 'desc');
  },
  getByUuid(uuid) {
    return getByUuid(COLLECTIONS.books, uuid);
  },
  create(book) {
    // book: { title, author, cover, coverExternalUrl, isbn, status, totalPages,
    //         totalChapters, seriesUuid, seriesIndex }
    // 说明：coverExternalUrl（扫码外链封面）/ isbn / seriesUuid / seriesIndex 均随
    //       book 透传写入，无需在此逐字段列举（generic create 会整体展开）。
    return create(COLLECTIONS.books, Object.assign({ status: 'want' }, book));
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.books, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.books, uuid);
  },
};

// ============================================================
// 共享成员：child_members（孩子↔家长 多对多关系）
// 一个孩子可被多位家长加入；创建者 isOwner=true（可邀请/移除他人）。
// ============================================================
const childMembers = {
  /** 我（当前登录用户）加入的全部成员关系（未过滤 childId，反查可见孩子用） */
  async listMine() {
    const openid = auth.openid ? auth.openid() : '';
    if (!openid) return [];
    return listAllPublic(COLLECTIONS.childMembers, { openid: AUTH_OPENID, isDeleted: false }, ['createdAt', 'asc'], 200);
  },
  /** 我在某孩子下的成员记录（判断是否成员/是否 owner） */
  async mineForChild(childId) {
    const openid = auth.openid ? auth.openid() : '';
    if (!openid || !childId) return null;
    try {
      const { data } = await db()
        .collection(COLLECTIONS.childMembers)
        .where({ openid: AUTH_OPENID, childId, isDeleted: false })
        .limit(1)
        .get();
      return (data && data[0]) || null;
    } catch (err) {
      console.warn('[db] childMembers.mineForChild 失败', err);
      return null;
    }
  },
};

const children = {
  /**
   * 当前用户可见的孩子列表（共享模型）：
   *   1. 查 child_members 得到我加入的 childId 列表；
   *   2. 按 uuid 批量拉取 children（安全规则会再次校验 doc.members）。
   * 项目未上线，不保留历史数据回填分支。
   */
  async listAll() {
    const { ownerId } = scope();
    if (!ownerId) return [];
    try {
      const res = await wx.cloud.callFunction({
        name: 'childShare',
        data: { action: 'listChildren' },
      });
      const result = (res && res.result) || {};
      if (result.ok && Array.isArray(result.children)) return result.children;
      console.warn('[db] childShare.listChildren 未成功，回退前端查询', result.error || result);
    } catch (err) {
      console.warn('[db] childShare.listChildren 调用失败，回退前端查询', err);
    }
    const mem = await childMembers.listMine();
    const childIds = Array.from(new Set(mem.map((m) => m.childId).filter(Boolean)));
    if (!childIds.length) return [];
    return listAllPublic(
      COLLECTIONS.children,
      { uuid: _().in(childIds), members: AUTH_OPENID, isDeleted: false },
      ['sortOrder', 'asc'],
      200
    );
  },
  /** 新增孩子：通过 childShare 云函数原子化创建档案 + owner 成员关系 */
  async create(child) {
    const res = await wx.cloud.callFunction({
      name: 'childShare',
      data: { action: 'createChild', child: Object.assign({ sortOrder: 0 }, child) },
    });
    const result = (res && res.result) || {};
    if (!result.ok || !result.child) throw new Error(result.error || '创建孩子档案失败');
    return result.child;
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.children, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.children, uuid);
  },
};

// 课表：规则集合（数据量小，仍走分页兜底）
const scheduleItems = {
  /** 全部课表项，按开始时间升序 */
  async listAll() {
    const items = await listSharedData(COLLECTIONS.scheduleItems);
    return sortByField(items, 'startTime', 'asc');
  },
  create(item) {
    // item: { courseName, type, location, teacher, weekday, recurrence, startTime, endTime, startDate, endDate, emoji, color }
    return create(COLLECTIONS.scheduleItems, Object.assign({ recurrence: 'weekly' }, item));
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.scheduleItems, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.scheduleItems, uuid);
  },
};

// 课程库模板（课程分类）：名称 + 分类(school/extra) + 颜色，供课表拖拽排课引用
const COURSE_TEMPLATE_PRESETS = [
  { name: '语文', type: 'school', color: '#6FB0E3' },
  { name: '数学', type: 'school', color: '#6FB0E3' },
  { name: '英语', type: 'school', color: '#6FB0E3' },
  { name: '体育', type: 'school', color: '#7FC29B' },
  { name: '科学', type: 'school', color: '#7FC29B' },
  { name: '音乐', type: 'school', color: '#B79BE0' },
  { name: '钢琴', type: 'extra', color: '#FF8C42' },
  { name: '游泳', type: 'extra', color: '#4FB6D9' },
  { name: '美术', type: 'extra', color: '#F0837E' },
  { name: '编程', type: 'extra', color: '#5C6BC0' },
  { name: '篮球', type: 'extra', color: '#FF8C42' },
  { name: '舞蹈', type: 'extra', color: '#F06B9A' },
];

const courseTemplates = {
  /** 全部课程模板，未删除，按创建时间升序 */
  async listAll() {
    const items = await listSharedData(COLLECTIONS.courseTemplates);
    return sortByField(items, 'createdAt', 'asc');
  },
  create(tpl) {
    // tpl: { name, type('school'|'extra'), color, emoji }
    return create(COLLECTIONS.courseTemplates, Object.assign({ type: 'extra', color: '#FF8C42' }, tpl));
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.courseTemplates, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.courseTemplates, uuid);
  },
  /**
   * 确保当前孩子已有课程库：若为空则写入一批预置课程。
   * 返回最终的课程模板列表。首次进入课程库页调用。
   */
  async ensureSeed() {
    const existing = await this.listAll();
    if (existing.length > 0) return existing;
    for (const p of COURSE_TEMPLATE_PRESETS) {
      try {
        await create(COLLECTIONS.courseTemplates, Object.assign({ isPreset: true }, p));
      } catch (e) {
        console.warn('[db] courseTemplates.ensureSeed 写入失败', p.name, e);
      }
    }
    return this.listAll();
  },
};

// 阅读打卡：日历第三源上游数据（补齐写入闭环）
const readingLogs = {
  /** 某时间范围内的打卡（按 readDate 聚合） */
  async listByRange(startMs, endMs) {
    const items = await listSharedData(COLLECTIONS.readingLogs);
    return sortByField(
      items.filter((item) => item.readDate >= startMs && item.readDate < endMs),
      'readDate',
      'desc'
    );
  },
  /** 某本书的全部打卡历史（按 readDate 倒序） */
  async listByBook(bookUuid) {
    const items = await listSharedData(COLLECTIONS.readingLogs);
    return sortByField(items.filter((item) => item.bookUuid === bookUuid), 'readDate', 'desc');
  },
  /** 全部打卡 */
  async listAll() {
    const items = await listSharedData(COLLECTIONS.readingLogs);
    return sortByField(items, 'readDate', 'desc');
  },
  create(log) {
    // log: { bookUuid, readDate, chapter, chapterIndex, pageFrom, pageTo, durationMinutes, mood, note, source }
    return create(COLLECTIONS.readingLogs, Object.assign({ source: 'manual' }, log));
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.readingLogs, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.readingLogs, uuid);
  },
};

// 套书/系列：一套书的元信息（已读册数不冗余存储，由 books 聚合派生）
// 与 books 风格一致：列表读取走受信云函数，写入/更新沿用通用 CRUD。
const series = {
  /** 当前孩子的全部系列（按创建时间升序） */
  async listAll() {
    const items = await listSharedData(COLLECTIONS.series);
    return sortByField(items, 'createdAt', 'asc');
  },
  getByUuid(uuid) {
    return getByUuid(COLLECTIONS.series, uuid);
  },
  create(item) {
    // item: { name, totalVolumes }
    return create(COLLECTIONS.series, Object.assign({ totalVolumes: 0 }, item));
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.series, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.series, uuid);
  },
};

// 周报：周度汇总（V1 P1：云端云函数 generateWeeklyReport 生成，本地只读 + 手动再生成）
// 主键：weekStart（本周一 00:00 毫秒）+ ownerId + childId 保证一周一份（云函数做幂等 upsert）
const weeklyReports = {
  async listAll() {
    const items = await listSharedData(COLLECTIONS.weeklyReports);
    return sortByField(items, 'weekStart', 'desc');
  },
  async listByRange(startMs, endMs) {
    const items = await listSharedData(COLLECTIONS.weeklyReports);
    return sortByField(
      items.filter((item) => item.weekStart >= startMs && item.weekStart < endMs),
      'weekStart',
      'desc'
    );
  },
  async getByWeek(weekStartMs) {
    const items = await listSharedData(COLLECTIONS.weeklyReports);
    return items.find((item) => item.weekStart === weekStartMs) || null;
  },
  create(report) {
    return create(COLLECTIONS.weeklyReports, report, { withChild: true });
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.weeklyReports, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.weeklyReports, uuid);
  },
};

// 精选书库：官方/共建公共只读集合（无 ownerId/childId 归属）。
// 与 books/series 不同，**不走 _buildWhere 归属过滤**，走 listAllPublic 分页拉全。
// 权限约定：云开发控制台建集合时设「所有人可读」（写入由后台/导入完成）。
const bookLibrary = {
  /**
   * 全量拉取书库（分页破 20 条上限，无归属过滤）。
   * @param {object} filter 可选过滤 { ageRange, isOfficial }
   */
  listAll(filter = {}) {
    const where = {};
    if (filter && filter.ageRange) where.ageRange = filter.ageRange;
    if (filter && filter.isOfficial != null) where.isOfficial = filter.isOfficial;
    return listAllPublic(COLLECTIONS.bookLibrary, where, ['createdAt', 'desc'], 500);
  },
  /** 按 uuid 取单条书库条目（无归属过滤） */
  async getByUuid(uuid) {
    try {
      const { data } = await db()
        .collection(COLLECTIONS.bookLibrary)
        .where({ uuid })
        .limit(1)
        .get();
      return (data && data[0]) || null;
    } catch (err) {
      console.warn('[db] bookLibrary.getByUuid 失败', err);
      return null;
    }
  },
};

// ============================================================
// 媒体：选图 → 上传云存储 → 存 fileID；批量换临时链接
// ============================================================

/**
 * 上传单个本地临时文件到云存储，返回 fileID。
 * 路径约定：{ownerId}/{childId}/{yyyyMM}/{uuid}.{ext}
 */
async function uploadFile(tempFilePath) {
  const { ownerId, childId } = scope();
  const now = new Date();
  const ym = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;
  const ext = (tempFilePath.split('.').pop() || 'jpg').split('?')[0];
  const prefix = childId ? `${ownerId || 'anonymous'}/${childId}` : `no-child/${ownerId || 'anonymous'}`;
  const cloudPath = `${prefix}/${ym}/${genUuid()}.${ext}`;
  const res = await wx.cloud.uploadFile({ cloudPath, filePath: tempFilePath });
  return res.fileID;
}

/** 批量上传，返回 fileID 数组 */
async function uploadFiles(tempFilePaths = []) {
  const out = [];
  for (const p of tempFilePaths) {
    // 串行上传，避免并发过高触发限流
    out.push(await uploadFile(p)); // eslint-disable-line no-await-in-loop
  }
  return out;
}

/**
 * 批量把 fileID 换成临时可访问 URL（带 2h 有效期）。
 * getTempFileURL 单次最多 50 个 fileID，超出自动分批（≤50）串行请求后合并。
 * @returns {Promise<Object>} { fileID: tempUrl }
 */
async function getTempUrls(fileIds = []) {
  const map = {};
  const valid = (fileIds || []).filter(Boolean);
  if (!valid.length) return map;
  // 去重，避免重复 fileID 占用批次额度
  const unique = Array.from(new Set(valid));
  for (let i = 0; i < unique.length; i += TEMP_URL_BATCH) {
    const chunk = unique.slice(i, i + TEMP_URL_BATCH);
    try {
      // eslint-disable-next-line no-await-in-loop
      const { fileList } = await wx.cloud.getTempFileURL({ fileList: chunk });
      (fileList || []).forEach((f) => {
        if (f.fileID) map[f.fileID] = f.tempFileURL;
      });
    } catch (err) {
      console.warn('[db] getTempFileURL 分批失败', err);
    }
  }
  return map;
}

module.exports = {
  COLLECTIONS,
  genUuid,
  scope,
  // 通用
  list,
  listAllPaged,
  listAllPublic,
  getByUuid,
  create,
  updateByUuid,
  softDelete,
  // 业务
  records,
  books,
  children,
  childMembers,
  scheduleItems,
  courseTemplates,
  readingLogs,
  series,
  weeklyReports,
  bookLibrary,
  // 媒体
  uploadFile,
  uploadFiles,
  getTempUrls,
};
