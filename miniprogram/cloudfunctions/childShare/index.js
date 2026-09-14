// cloudfunctions/childShare/index.js —— 孩子共享：邀请 / 加入 / 成员管理
//
// 共享模型（以孩子为中心，childId 作为共享锚点）：
//   child_members：孩子↔家长 多对多成员关系（isOwner=true 为创建者，可邀请/移除）
//   child_invites：一次性邀请码（6 位，24h 过期，usedBy=null 表示未使用）
//
// 为什么用云函数（信任端）：
//   - 邀请码生成 / 校验、成员写入、移除，均需服务端鉴权，避免前端越权乱写；
//   - 生成小程序码（wxacode.getUnlimited）只能在服务端调用。
//
// 统一入参：{ action, ...payload }；统一返回：{ ok, ... } | { ok:false, error }
// 身份：ownerId = UNIONID || OPENID（与 utils/auth.js、login 云函数口径一致）
//
// 【安全规则协同（2026-09）】业务集合改用「自定义安全规则」做前端鉴权：
//   规则判定式 "auth.openid in doc.members"（members = 有权访问该孩子的 openid 数组）。
//   ⚠️ 安全规则只认 auth.openid，拿不到 unionid；且 childId 存的是自定义 uuid（非 _id），
//      get(`database.children.${doc.childId}`) 按 _id 寻址无法命中 —— 故只能把 members(openid)
//      冗余到 children 与各业务文档上。本云函数负责在成员加入/移除后重算并回填 members。
const cloud = require('wx-server-sdk');

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const db = cloud.database();
const _ = db.command;

const C_MEMBERS = 'child_members';
const C_INVITES = 'child_invites';
const C_CHILDREN = 'children';
const C_USERS = 'users';
const C_TODOS = 'todos';
const C_RECORDS = 'daily_records';

// 受「以孩子为锚点」共享的业务集合：成员变更时需同步回填 members(openid) 数组
const BIZ_COLLECTIONS = [
  'daily_records', 'books', 'todos', 'schedule_items',
  'reading_logs', 'series', 'weekly_reports',
];

const INVITE_TTL = 24 * 3600 * 1000; // 邀请码有效期 24h
// 邀请码字符集：去掉易混淆的 0/O/1/I/L
const CODE_CHARS = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

function genUuid() {
  const s = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).slice(1);
  return `${s()}${s()}-${s()}-${s()}-${s()}-${s()}${s()}${s()}`;
}
function genCode(len = 6) {
  let out = '';
  for (let i = 0; i < len; i++) out += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  return out;
}
function ctxOwnerId() {
  const { OPENID, UNIONID } = (cloud.getWXContext && cloud.getWXContext()) || {};
  return UNIONID || OPENID || '';
}
/** 当前调用者的原始 openid（安全规则里 auth.openid 的口径，与 ownerId 可能不同） */
function ctxOpenid() {
  const { OPENID } = (cloud.getWXContext && cloud.getWXContext()) || {};
  return OPENID || '';
}

/**
 * 把 ownerId(=unionid||openid) 解析成原始 openid。
 * 安全规则只认 auth.openid，故 members 数组必须存 openid 而非 ownerId。
 * 优先查 users.openid；查不到则回退 ownerId 本身（无 unionid 时 ownerId===openid）。
 */
async function openidOf(ownerId) {
  if (!ownerId) return '';
  try {
    const { data } = await db.collection(C_USERS)
      .where({ ownerId, isDeleted: _.neq(true) })
      .limit(1)
      .get();
    const u = data && data[0];
    if (u && u.openid) return u.openid;
  } catch (e) { /* ignore, fall back */ }
  return ownerId;
}

/**
 * 重算某孩子的成员 openid 集合，并回写 children 文档与全部业务集合的 members 字段。
 * 供安全规则 "auth.openid in doc.members" 判定。成员加入/移除后调用即可保持一致。
 * 说明：node-sdk 的 where().update() 为批量更新，会更新该 childId 下所有匹配文档。
 */
async function syncChildMembers(childId) {
  if (!childId) return [];
  const { data: mems } = await db.collection(C_MEMBERS)
    .where({ childId, isDeleted: _.neq(true) })
    .limit(100)
    .get();
  const ownerIds = Array.from(new Set((mems || []).map((m) => m.ownerId).filter(Boolean)));
  const ownerToOpenid = {};
  for (const oid of ownerIds) {
    // eslint-disable-next-line no-await-in-loop
    ownerToOpenid[oid] = await openidOf(oid);
  }
  // 顺带回填 child_members.openid（历史成员记录仅有 ownerId，安全规则读取需要 openid）
  for (const m of (mems || [])) {
    const openid = ownerToOpenid[m.ownerId];
    if (openid && m.openid !== openid) {
      try {
        // eslint-disable-next-line no-await-in-loop
        await db.collection(C_MEMBERS).doc(m._id).update({ data: { openid } });
      } catch (e) { /* ignore */ }
    }
  }
  const members = Array.from(new Set(Object.values(ownerToOpenid).filter(Boolean)));
  const now = Date.now();
  // 回写 children（按 uuid 定位真实 _id）
  try {
    const childRes = await db.collection(C_CHILDREN).where({ uuid: childId }).limit(1).get();
    if (childRes.data && childRes.data[0]) {
      await db.collection(C_CHILDREN).doc(childRes.data[0]._id)
        .update({ data: { members, updatedAt: now } });
    }
  } catch (e) { console.warn('[childShare] syncChildMembers children 回写失败', e); }
  // 批量回填业务集合
  for (const col of BIZ_COLLECTIONS) {
    try {
      // eslint-disable-next-line no-await-in-loop
      await db.collection(col).where({ childId }).update({ data: { members } });
    } catch (e) { console.warn(`[childShare] syncChildMembers ${col} 回填失败`, e); }
  }
  return members;
}

/** 我在某孩子下的有效成员记录（null=非成员） */
async function findMembership(childId, ownerId) {
  if (!childId || !ownerId) return null;
  const { data } = await db.collection(C_MEMBERS)
    .where({ childId, ownerId, isDeleted: _.neq(true) })
    .limit(1)
    .get();
  return (data && data[0]) || null;
}

/**
 * 创建孩子档案并登记创建者成员关系。
 * child_members 前端写权限关闭，因此这两个写入必须在同一受信云函数中完成。
 */
async function createChild(input, ownerId, openid) {
  const child = input && typeof input === 'object' ? input : {};
  const name = String(child.name || '').trim();
  if (!name) return { ok: false, error: '孩子姓名不能为空' };
  if (!openid) return { ok: false, error: '未获取到 openid，无法创建孩子档案' };
  const now = Date.now();
  const uuid = genUuid();
  let role = 'other';
  try {
    const u = await db.collection(C_USERS).where({ ownerId, isDeleted: _.neq(true) }).limit(1).get();
    if (u.data && u.data[0] && u.data[0].role) role = u.data[0].role;
  } catch (e) { /* ignore */ }
  const doc = {
    uuid,
    ownerId,
    members: [openid],
    name,
    birthDate: child.birthDate == null ? null : child.birthDate,
    gender: child.gender || 'unknown',
    avatarFileId: child.avatarFileId || null,
    gradeOverride: child.gradeOverride == null ? null : child.gradeOverride,
    sortOrder: Number.isFinite(child.sortOrder) ? child.sortOrder : 0,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  };
  const addRes = await db.collection(C_CHILDREN).add({ data: doc });
  try {
    await db.collection(C_MEMBERS).add({
      data: {
        uuid: genUuid(),
        childId: uuid,
        ownerId,
        openid,
        role,
        isOwner: true,
        joinedAt: now,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      },
    });
  } catch (err) {
    // 成员关系失败则回滚孩子档案，避免产生无人可管理的孤儿数据。
    try { await db.collection(C_CHILDREN).doc(addRes._id).remove(); } catch (e) { /* ignore rollback */ }
    throw err;
  }
  return { ok: true, child: doc };
}

/**
 * 返回当前登录家长可见的孩子列表。
 * 由云函数读取成员关系，避免前端安全规则查询与复合索引缺失导致列表被静默降级为空。
 */
async function listChildren(openid, ownerId) {
  if (!openid) return { ok: false, error: '未获取到 openid' };
  const memberRes = await db.collection(C_MEMBERS)
    .where({ openid })
    .limit(100)
    .get();
  const memberRows = memberRes.data || [];
  const childIds = Array.from(new Set(memberRows
    .filter((member) => !member.isDeleted && member.childId)
    .map((member) => member.childId)));

  // 兼容创建成员关系失败但孩子档案已落库的异常数据：创建者可见自己的孩子，并补齐成员关系。
  const ownedRes = await db.collection(C_CHILDREN)
    .where({ ownerId, isDeleted: _.neq(true) })
    .limit(100)
    .get();
  const now = Date.now();
  for (const child of (ownedRes.data || [])) {
    if (!child.uuid) continue;
    if (childIds.indexOf(child.uuid) === -1) childIds.push(child.uuid);
    if (!Array.isArray(child.members) || child.members.indexOf(openid) === -1) {
      child.members = Array.from(new Set((child.members || []).concat(openid)));
      // eslint-disable-next-line no-await-in-loop
      await db.collection(C_CHILDREN).doc(child._id).update({
        data: { members: child.members, updatedAt: now },
      });
    }
    const membership = memberRows.find((member) => member.childId === child.uuid);
    if (!membership) {
      // eslint-disable-next-line no-await-in-loop
      await db.collection(C_MEMBERS).add({ data: {
        uuid: genUuid(), childId: child.uuid, ownerId, openid, role: 'other', isOwner: true,
        joinedAt: now, createdAt: now, updatedAt: now, isDeleted: false,
      } });
    } else if (membership.isDeleted) {
      // eslint-disable-next-line no-await-in-loop
      await db.collection(C_MEMBERS).doc(membership._id).update({ data: {
        ownerId, openid, isOwner: true, isDeleted: false, updatedAt: now,
      } });
    }
  }
  if (!childIds.length) return { ok: true, children: [] };

  const children = [];
  const chunkSize = 10;
  for (let i = 0; i < childIds.length; i += chunkSize) {
    const chunk = childIds.slice(i, i + chunkSize);
    // eslint-disable-next-line no-await-in-loop
    const childRes = await db.collection(C_CHILDREN)
      .where({ uuid: _.in(chunk) })
      .limit(chunkSize)
      .get();
    children.push(...(childRes.data || []).filter((child) => (
      !child.isDeleted && Array.isArray(child.members) && child.members.indexOf(openid) !== -1
    )));
  }
  children.sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0));
  return { ok: true, children };
}

/** 当前成员读取指定孩子的全部待办，绕开前端安全规则查询被拒绝时的空列表问题。 */
async function listTodos(childId, ownerId) {
  if (!childId) return { ok: false, error: '缺少 childId' };
  const membership = await findMembership(childId, ownerId);
  if (!membership) return { ok: false, error: '无权访问该孩子的待办' };
  const todos = [];
  const pageSize = 100;
  let offset = 0;
  while (true) {
    // eslint-disable-next-line no-await-in-loop
    const res = await db.collection(C_TODOS)
      .where({ childId, isDeleted: _.neq(true) })
      .skip(offset)
      .limit(pageSize)
      .get();
    const page = res.data || [];
    todos.push(...page);
    if (page.length < pageSize) break;
    offset += pageSize;
  }
  return { ok: true, todos };
}

/**
 * 把已完成待办原子转换为成长记录。
 * 事务同时校验待办、创建确定性 ID 的记录并回写 convertedRecordId；并发请求只会保留一条记录。
 */
async function convertTodoToRecord(event, ownerId, openid) {
  const sourceTodoId = String(event.sourceTodoId || '').trim();
  const input = event.record && typeof event.record === 'object' ? event.record : {};
  const title = String(input.title || '').trim();
  if (!sourceTodoId) return { ok: false, error: '缺少来源待办' };
  if (!title) return { ok: false, error: '成长记录标题不能为空' };
  if (!openid) return { ok: false, error: '未获取到 openid，无法记录成长' };

  const todoQuery = await db.collection(C_TODOS)
    .where({ uuid: sourceTodoId, isDeleted: false })
    .limit(1)
    .get();
  const todoDoc = todoQuery.data && todoQuery.data[0];
  if (!todoDoc) return { ok: false, error: '来源待办不存在' };
  if (!Array.isArray(todoDoc.members) || todoDoc.members.indexOf(openid) === -1) {
    return { ok: false, error: '无权操作该待办' };
  }

  const recordId = `todo_${sourceTodoId}`;
  const txResult = await db.runTransaction(async (transaction) => {
    const currentTodoRes = await transaction.collection(C_TODOS).doc(todoDoc._id).get();
    const currentTodo = currentTodoRes && currentTodoRes.data;
    if (!currentTodo || currentTodo.isDeleted) throw new Error('来源待办不存在');
    if (!Array.isArray(currentTodo.members) || currentTodo.members.indexOf(openid) === -1) {
      throw new Error('无权操作该待办');
    }
    if (!currentTodo.done) throw new Error('仅已完成待办可记录成长');

    let existing = null;
    try {
      const existingRes = await transaction.collection(C_RECORDS).doc(recordId).get();
      existing = existingRes && existingRes.data;
    } catch (err) {
      const msg = `${(err && (err.errMsg || err.message)) || err}`;
      if (!/not exist|not found|不存在/i.test(msg)) throw err;
    }
    if (existing && !existing.isDeleted) {
      if (currentTodo.convertedRecordId !== existing.uuid) {
        await transaction.collection(C_TODOS).doc(todoDoc._id).update({
          data: { convertedRecordId: existing.uuid, updatedAt: Date.now() },
        });
      }
      return { ok: true, alreadyConverted: true, record: existing };
    }

    const now = Date.now();
    const record = {
      uuid: recordId,
      ownerId,
      childId: currentTodo.childId,
      members: currentTodo.members.slice(),
      title,
      note: input.note ? String(input.note).trim() : null,
      tags: Array.isArray(input.tags) ? input.tags.slice(0, 20) : [],
      category: input.category || null,
      mood: input.mood || null,
      imageFileIds: Array.isArray(input.imageFileIds) ? input.imageFileIds.slice(0, 9) : [],
      eventDate: Number(input.eventDate) || now,
      source: 'todo',
      sourceType: 'todo',
      sourceTodoId,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    };
    await transaction.collection(C_RECORDS).doc(recordId).set({ data: record });
    await transaction.collection(C_TODOS).doc(todoDoc._id).update({
      data: { convertedRecordId: recordId, updatedAt: now },
    });
    return { ok: true, alreadyConverted: false, record };
  });
  return (txResult && txResult.result) || txResult;
}

/** 生成一个未与现存有效邀请码冲突的新码（最多重试 5 次） */
async function genUniqueCode() {
  for (let i = 0; i < 5; i++) {
    const code = genCode(6);
    // eslint-disable-next-line no-await-in-loop
    const { data } = await db.collection(C_INVITES)
      .where({ inviteCode: code, isDeleted: _.neq(true), usedBy: _.eq(null) })
      .limit(1)
      .get();
    if (!data || !data.length) return code;
  }
  // 兜底：拼接时间戳尾数降低碰撞概率
  return genCode(4) + String(Date.now()).slice(-2);
}

/** 创建邀请码（要求调用者是该孩子成员） */
async function createInvite(childId, ownerId) {
  if (!childId) return { ok: false, error: '缺少 childId' };
  const mem = await findMembership(childId, ownerId);
  if (!mem) return { ok: false, error: '你不是该孩子的家长，无法邀请' };
  const now = Date.now();
  const inviteCode = await genUniqueCode();
  const doc = {
    uuid: genUuid(),
    childId,
    inviteCode,
    createdBy: ownerId,
    usedBy: null,
    usedAt: null,
    expiredAt: now + INVITE_TTL,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  };
  await db.collection(C_INVITES).add({ data: doc });
  return { ok: true, inviteCode, childId, expiredAt: doc.expiredAt };
}

/** 生成小程序码（scene=inviteCode），返回可访问的 fileID */
async function getQrCode(event, ownerId) {
  const { childId } = event;
  let inviteCode = event.inviteCode;
  // 未带邀请码则先创建一个
  if (!inviteCode) {
    const r = await createInvite(childId, ownerId);
    if (!r.ok) return r;
    inviteCode = r.inviteCode;
  } else {
    // 校验调用者仍是成员
    const mem = await findMembership(childId, ownerId);
    if (!mem) return { ok: false, error: '你不是该孩子的家长，无法邀请' };
  }
  const page = event.page || 'pages/mine/mine';
  const envVersion = event.envVersion || 'release'; // release | trial | develop
  try {
    const res = await cloud.openapi.wxacode.getUnlimited({
      scene: inviteCode,          // 仅传邀请码，接收端凭码反查 childId
      page,
      checkPath: false,           // 允许码指向尚未发布/未在 app.json 声明的路径
      envVersion,
      width: 320,
      autoColor: false,
      lineColor: { r: 255, g: 140, b: 66 }, // 主题橙
    });
    const buffer = res.buffer;
    if (!buffer) return { ok: false, error: '生成小程序码失败（无返回图像）' };
    const upload = await cloud.uploadFile({
      cloudPath: `invites/${childId}/${inviteCode}_${Date.now()}.png`,
      fileContent: buffer,
    });
    return { ok: true, inviteCode, childId, fileID: upload.fileID };
  } catch (err) {
    console.error('[childShare] getUnlimited 失败', err);
    return { ok: false, error: '生成小程序码失败：' + (err.errMsg || err.message || 'unknown') };
  }
}

/** 接受邀请（凭邀请码加入孩子） */
async function acceptInvite(inviteCode, ownerId) {
  if (!inviteCode) return { ok: false, error: '缺少邀请码' };
  const code = String(inviteCode).trim().toUpperCase();
  const now = Date.now();
  // 取最新一条未使用、未过期、未删除的邀请
  const { data } = await db.collection(C_INVITES)
    .where({ inviteCode: code, isDeleted: _.neq(true), usedBy: _.eq(null) })
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();
  const invite = data && data[0];
  if (!invite) return { ok: false, error: '邀请码无效或已被使用' };
  if (invite.expiredAt && invite.expiredAt < now) return { ok: false, error: '邀请码已过期，请让家人重新生成' };

  const childId = invite.childId;
  // 孩子是否存在
  const childRes = await db.collection(C_CHILDREN).where({ uuid: childId, isDeleted: _.neq(true) }).limit(1).get();
  const child = childRes.data && childRes.data[0];
  if (!child) return { ok: false, error: '该孩子档案不存在或已删除' };

  // 邀请人不能扫自己的码（无意义）
  if (invite.createdBy === ownerId) {
    return { ok: false, error: '不能加入自己创建的邀请', childId, childName: child.name || '' };
  }

  // 已是成员则幂等返回
  const exist = await findMembership(childId, ownerId);
  if (exist) {
    return { ok: true, alreadyMember: true, childId, childName: child.name || '' };
  }

  // 读取加入者角色（users.role），兜底 other
  let role = 'other';
  try {
    const u = await db.collection(C_USERS).where({ ownerId, isDeleted: _.neq(true) }).limit(1).get();
    if (u.data && u.data[0] && u.data[0].role) role = u.data[0].role;
  } catch (e) { /* ignore */ }

  await db.collection(C_MEMBERS).add({
    data: {
      uuid: genUuid(),
      childId,
      ownerId,
      openid: ctxOpenid(),   // 冗余原始 openid，便于 syncChildMembers 直接取用
      role,
      isOwner: false,
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    },
  });
  // 标记邀请码已使用（一次性）
  await db.collection(C_INVITES).doc(invite._id).update({
    data: { usedBy: ownerId, usedAt: now, updatedAt: now },
  });
  // 同步 members(openid) 到 children + 业务集合，使新家长立即可读写共享数据
  await syncChildMembers(childId);
  return { ok: true, childId, childName: child.name || '' };
}

/** 列出某孩子的全部成员（合并 users 展示信息） */
async function listMembers(childId, ownerId) {
  if (!childId) return { ok: false, error: '缺少 childId' };
  const self = await findMembership(childId, ownerId);
  if (!self) return { ok: false, error: '你不是该孩子的家长' };
  const { data: members } = await db.collection(C_MEMBERS)
    .where({ childId, isDeleted: _.neq(true) })
    .orderBy('createdAt', 'asc')
    .limit(100)
    .get();
  const ownerIds = Array.from(new Set((members || []).map((m) => m.ownerId).filter(Boolean)));
  const userMap = {};
  if (ownerIds.length) {
    // in 查询批量拉用户
    const { data: users } = await db.collection(C_USERS)
      .where({ ownerId: _.in(ownerIds) })
      .limit(100)
      .get();
    (users || []).forEach((u) => { userMap[u.ownerId] = u; });
  }
  const list = (members || []).map((m) => {
    const u = userMap[m.ownerId] || {};
    const phone = u.phone ? String(u.phone) : '';
    return {
      ownerId: m.ownerId,
      role: m.role || 'other',
      isOwner: !!m.isOwner,
      joinedAt: m.joinedAt || m.createdAt || null,
      nickname: u.nickname || '',
      avatar: u.avatar || '',
      phoneTail: phone ? phone.slice(-4) : '',
      isSelf: m.ownerId === ownerId,
    };
  });
  return { ok: true, members: list, selfIsOwner: !!self.isOwner, childId };
}

async function deleteChild(childId, ownerId) {
  if (!childId) return { ok: false, error: '缺少 childId' };
  const membership = await findMembership(childId, ownerId);
  if (!membership || !membership.isOwner) {
    return { ok: false, error: '仅孩子档案创建者可以删除' };
  }
  const childRes = await db.collection(C_CHILDREN)
    .where({ uuid: childId, isDeleted: _.neq(true) })
    .limit(1)
    .get();
  const child = childRes.data && childRes.data[0];
  if (!child) return { ok: true, alreadyDeleted: true, childId };

  const now = Date.now();
  await Promise.all([
    ...BIZ_COLLECTIONS.map((col) => db.collection(col)
      .where({ childId, isDeleted: _.neq(true) })
      .update({ data: { isDeleted: true, deletedAt: now, updatedAt: now } })),
    db.collection(C_MEMBERS)
      .where({ childId, isDeleted: _.neq(true) })
      .update({ data: { isDeleted: true, deletedAt: now, updatedAt: now } }),
    db.collection(C_INVITES)
      .where({ childId, isDeleted: _.neq(true) })
      .update({ data: { isDeleted: true, deletedAt: now, updatedAt: now } }),
  ]);
  await db.collection(C_CHILDREN).doc(child._id).update({
    data: { isDeleted: true, deletedAt: now, updatedAt: now },
  });
  return { ok: true, childId };
}

/** 移除成员（仅创建者可操作，不能移除自己/其他 owner） */
async function removeMember(childId, targetOwnerId, ownerId) {
  if (!childId || !targetOwnerId) return { ok: false, error: '参数不完整' };
  const self = await findMembership(childId, ownerId);
  if (!self || !self.isOwner) return { ok: false, error: '只有创建者可以移除成员' };
  if (targetOwnerId === ownerId) return { ok: false, error: '不能移除自己' };
  const target = await findMembership(childId, targetOwnerId);
  if (!target) return { ok: false, error: '该成员不存在或已移除' };
  if (target.isOwner) return { ok: false, error: '不能移除创建者' };
  await db.collection(C_MEMBERS).doc(target._id).update({
    data: { isDeleted: true, updatedAt: Date.now() },
  });
  // 从共享数据的 members 中剔除被移除成员的 openid
  await syncChildMembers(childId);
  return { ok: true, childId, removed: targetOwnerId };
}

/** 主动退出共享（非创建者；创建者需先移交或移除他人） */
async function leaveChild(childId, ownerId) {
  if (!childId) return { ok: false, error: '缺少 childId' };
  const self = await findMembership(childId, ownerId);
  if (!self) return { ok: false, error: '你不是该孩子的家长' };
  if (self.isOwner) return { ok: false, error: '创建者不能退出，请先移除其他成员' };
  await db.collection(C_MEMBERS).doc(self._id).update({
    data: { isDeleted: true, updatedAt: Date.now() },
  });
  // 退出后同步 members(openid)，回收该成员对共享数据的访问权
  await syncChildMembers(childId);
  return { ok: true, childId, left: ownerId };
}

exports.main = async (event = {}) => {
  const ownerId = ctxOwnerId();
  if (!ownerId) return { ok: false, error: '未登录，无法操作' };
  const action = event.action || '';
  try {
    switch (action) {
      case 'createChild':
        return await createChild(event.child, ownerId, ctxOpenid());
      case 'listChildren':
        return await listChildren(ctxOpenid(), ownerId);
      case 'listTodos':
        return await listTodos(event.childId, ownerId);
      case 'convertTodoToRecord':
        return await convertTodoToRecord(event, ownerId, ctxOpenid());
      case 'createInvite':
        return await createInvite(event.childId, ownerId);
      case 'getQrCode':
        return await getQrCode(event, ownerId);
      case 'acceptInvite':
        return await acceptInvite(event.inviteCode, ownerId);
      case 'listMembers':
        return await listMembers(event.childId, ownerId);
      case 'deleteChild':
        return await deleteChild(event.childId, ownerId);
      case 'removeMember':
        return await removeMember(event.childId, event.targetOwnerId, ownerId);
      case 'leaveChild':
        return await leaveChild(event.childId, ownerId);
      default:
        return { ok: false, error: `未知 action: ${action}` };
    }
  } catch (err) {
    console.error(`[childShare] action=${action} 异常`, err);
    return { ok: false, error: err.errMsg || err.message || '服务异常' };
  }
};
