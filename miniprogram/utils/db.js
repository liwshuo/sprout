// utils/db.js —— CloudBase 云数据库操作封装
// 统一处理：ownerId + childId 归属过滤、软删（isDeleted）、同步三件套、
// uuid 主键、毫秒时间戳。所有查询默认排除 isDeleted=true。
// 云不可用/查询失败时返回空集合，保证页面可渲染空态（MVP 友好）。

const auth = require('./auth');

/** 集合名常量 */
const COLLECTIONS = {
  users: 'users',
  children: 'children',
  dailyRecords: 'daily_records',
  series: 'series',
  books: 'books',
  readingLogs: 'reading_logs',
  scheduleItems: 'schedule_items',
  weeklyReports: 'weekly_reports',
};

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

/**
 * 列表查询。默认按归属(ownerId[/childId]) + 排除软删。
 * @param {string} col 集合名
 * @param {object} opts { where, orderBy:[field,'desc'], limit, withChild:true }
 */
async function list(col, opts = {}) {
  try {
    const { ownerId, childId } = scope();
    if (!ownerId) return [];
    const where = Object.assign(
      { ownerId, isDeleted: _().neq(true) },
      opts.withChild === false ? {} : childId ? { childId } : {},
      opts.where || {}
    );
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

/** 按 uuid 取单条 */
async function getByUuid(col, uuid) {
  try {
    const { ownerId } = scope();
    const { data } = await db()
      .collection(col)
      .where({ ownerId, uuid })
      .limit(1)
      .get();
    return (data && data[0]) || null;
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
  const payload = Object.assign(
    {
      uuid: genUuid(),
      ownerId,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    },
    withChild ? { childId } : {},
    doc
  );
  await db().collection(col).add({ data: payload });
  return payload;
}

/** 按 uuid 更新（自动刷新 updatedAt） */
async function updateByUuid(col, uuid, patch) {
  const { ownerId } = scope();
  const { data } = await db()
    .collection(col)
    .where({ ownerId, uuid })
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
// 业务快捷方法：records / books / children
// ============================================================

const records = {
  /** 某日/某月记录列表，按 eventDate 倒序 */
  listByRange(startMs, endMs) {
    const cmd = _();
    return list(COLLECTIONS.dailyRecords, {
      where: { eventDate: cmd.gte(startMs).and(cmd.lt(endMs)) },
      orderBy: ['eventDate', 'desc'],
    });
  },
  /** 全部记录（倒序，可分页 limit） */
  listAll(limit = 50) {
    return list(COLLECTIONS.dailyRecords, {
      orderBy: ['eventDate', 'desc'],
      limit,
    });
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
  listAll() {
    return list(COLLECTIONS.books, { orderBy: ['updatedAt', 'desc'] });
  },
  listByStatus(status) {
    return list(COLLECTIONS.books, { where: { status }, orderBy: ['updatedAt', 'desc'] });
  },
  getByUuid(uuid) {
    return getByUuid(COLLECTIONS.books, uuid);
  },
  create(book) {
    // book: { title, author, cover, isbn, status, totalPages, totalChapters, seriesUuid, seriesIndex }
    return create(COLLECTIONS.books, Object.assign({ status: 'want' }, book));
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.books, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.books, uuid);
  },
};

const children = {
  /** 当前用户的孩子列表（不按 childId 过滤） */
  listAll() {
    return list(COLLECTIONS.children, { withChild: false, orderBy: ['sortOrder', 'asc'] });
  },
  create(child) {
    // child: { name, birthDate, avatarFileId, sortOrder }
    return create(
      COLLECTIONS.children,
      Object.assign({ sortOrder: 0 }, child),
      { withChild: false }
    );
  },
  update(uuid, patch) {
    return updateByUuid(COLLECTIONS.children, uuid, patch);
  },
  remove(uuid) {
    return softDelete(COLLECTIONS.children, uuid);
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
  const cloudPath = `${ownerId || 'anonymous'}/${childId || 'default'}/${ym}/${genUuid()}.${ext}`;
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
 * @returns {Promise<Object>} { fileID: tempUrl }
 */
async function getTempUrls(fileIds = []) {
  const map = {};
  const valid = (fileIds || []).filter(Boolean);
  if (!valid.length) return map;
  try {
    const { fileList } = await wx.cloud.getTempFileURL({ fileList: valid });
    (fileList || []).forEach((f) => {
      if (f.fileID) map[f.fileID] = f.tempFileURL;
    });
  } catch (err) {
    console.warn('[db] getTempFileURL 失败', err);
  }
  return map;
}

module.exports = {
  COLLECTIONS,
  genUuid,
  scope,
  // 通用
  list,
  getByUuid,
  create,
  updateByUuid,
  softDelete,
  // 业务
  records,
  books,
  children,
  // 媒体
  uploadFile,
  uploadFiles,
  getTempUrls,
};
