// utils/auth.js —— 登录与用户初始化
// 设计：小程序端无需自维护 token；每次云调用自带身份。
// ownerId 优先 unionid，否则 openid（对齐技术方案 §2）。

/**
 * 确保已登录：解析 openid/unionid → upsert users → 返回用户对象。
 * 依赖名为 `login` 的云函数（返回 { openid, unionid, appid }）。
 * 若云函数未部署，降级为本地匿名用户，保证页面可渲染。
 * @returns {Promise<Object>} user: { ownerId, openid, unionid, phone, nickname, avatar }
 */
function ensureLogin() {
  return new Promise((resolve, reject) => {
    if (!wx.cloud) {
      return reject(new Error('云能力不可用'));
    }
    wx.cloud.callFunction({
      name: 'login',
      data: {},
    })
      .then(async (res) => {
        const { openid, unionid } = (res && res.result) || {};
        if (!openid) throw new Error('login 云函数未返回 openid');
        const ownerId = unionid || openid;
        const user = await upsertUser({ ownerId, openid, unionid });
        wx.setStorageSync('currentUser', user);
        resolve(user);
      })
      .catch((err) => {
        console.warn('[auth] 云登录失败，降级本地态', err);
        reject(err);
      });
  });
}

/**
 * upsert users 集合：以 ownerId 为唯一键，存在则更新，否则创建。
 */
async function upsertUser({ ownerId, openid, unionid }) {
  const db = wx.cloud.database();
  const now = Date.now();
  const col = db.collection('users');
  const { data } = await col.where({ ownerId }).limit(1).get();
  if (data && data.length) {
    const doc = data[0];
    await col.doc(doc._id).update({
      data: { openid, unionid: unionid || doc.unionid || null, updatedAt: now },
    });
    return { ...doc, openid, unionid: unionid || doc.unionid || null };
  }
  const user = {
    ownerId,
    openid,
    unionid: unionid || null,
    phone: null,
    nickname: null,
    avatar: null,
    createdAt: now,
    updatedAt: now,
  };
  const addRes = await col.add({ data: user });
  return { _id: addRes._id, ...user };
}

/**
 * 绑定手机号：将 getPhoneNumber 返回的 code（新版）或 cloudID（旧版快速验证）
 * 交给 bindPhone 云函数换取手机号。
 * @param {object|string} payload { code } | { cloudID } | cloudID 字符串
 */
function bindPhone(payload) {
  const data = typeof payload === 'string' ? { cloudID: payload } : payload || {};
  return wx.cloud
    .callFunction({ name: 'bindPhone', data })
    .then((res) => (res && res.result) || {});
}

/**
 * 读取当前登录用户（内存/缓存），未登录返回 null。
 */
function currentUser() {
  const app = getApp();
  if (app && app.globalData && app.globalData.currentUser) {
    return app.globalData.currentUser;
  }
  return wx.getStorageSync('currentUser') || null;
}

/** 当前 ownerId，未登录返回空串 */
function ownerId() {
  const u = currentUser();
  return (u && u.ownerId) || '';
}

module.exports = {
  ensureLogin,
  upsertUser,
  bindPhone,
  currentUser,
  ownerId,
};
