// cloudfunctions/bookLibraryInc/index.js —— 精选书库热度原子自增
//
// 为什么要做云函数：
//   book_library 是公共集合（无 ownerId 归属过滤，小程序端"所有人可读"）。
//   如果允许前端直接 .update() 自增，任何用户可随意修改任意字段，存在越权/脏写风险。
//   云函数作为信任端，只允许对指定字段做 delta 原子自增，其它字段一律拒绝。
//
// 入参 event：
//   { bookLibraryUuid, delta?: number (默认 1), field?: 'hotScore'|'readFinishCount' (默认 'hotScore') }
// 返回：
//   { ok: true,  uuid, field, delta, oldValue, newValue }
//   { ok: false, error }
const cloud = require('wx-server-sdk');

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const db = cloud.database();
const _ = db.command;

const COL = 'book_library';
const ALLOWED_FIELDS = ['hotScore', 'readFinishCount'];

exports.main = async (event = {}) => {
  const uuid = String(event.bookLibraryUuid || '').trim();
  const delta = Number.isFinite(event.delta) ? Number(event.delta) : 1;
  const field = ALLOWED_FIELDS.indexOf(event.field) >= 0 ? event.field : 'hotScore';

  if (!uuid) return { ok: false, error: 'missing bookLibraryUuid' };
  if (delta === 0) return { ok: false, error: 'delta 不能为 0' };
  if (Math.abs(delta) > 10) return { ok: false, error: '单次自增绝对值不能超过 10（防脏刷）' };

  // 身份存在性校验：必须来自真实登录用户，否则匿名脚本也能刷热度
  const { OPENID, UNIONID } = cloud.getWXContext && cloud.getWXContext() || {};
  const ownerId = UNIONID || OPENID;
  if (!ownerId) return { ok: false, error: '未登录，无法操作' };

  // 先查原值（以便返回 old / new 对比，前端可选做乐观展示）
  const { data } = await db.collection(COL).where({ uuid }).limit(1).get();
  const row = data && data[0];
  if (!row) return { ok: false, error: 'book_library 中不存在该 uuid' };

  const oldValue = Number(row[field]) || 0;
  const patch = { lastIncAt: Date.now() };
  patch[field] = _.inc(delta);
  await db.collection(COL).doc(row._id).update({ data: patch });
  const newValue = oldValue + delta;
  return { ok: true, uuid, field, delta, oldValue, newValue };
};
