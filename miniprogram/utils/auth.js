// utils/auth.js —— 登录与用户初始化
// 设计：小程序端无需自维护 token；每次云调用自带身份。
// ownerId 优先 unionid，否则 openid（对齐技术方案 §2）。

/**
 * 判断错误是否为「login/bindPhone 云函数未部署或不存在」。
 * 微信在调用未部署的云函数时会返回 errCode -501000 或 errMsg 含 FunctionName Not Found。
 * ⚠️ 此类错误无法通过前端代码修复，必须在「微信开发者工具」中右键
 *    cloudfunctions/login →「上传并部署（云端安装依赖）」后才能解决。
 * @param {*} err
 * @returns {boolean}
 */
function isCloudFunctionMissing(err) {
  if (!err) return false;
  const code = err.errCode;
  const msg = `${(err && (err.errMsg || err.message)) || err}`;
  return (
    code === -501000 ||
    /FunctionName\s*Not\s*Found/i.test(msg) ||
    /cloud function.*not\s*found/i.test(msg) ||
    /FUNCTION[_\s]?NOT[_\s]?FOUND/i.test(msg)
  );
}

/**
 * 确保已登录：解析 openid/unionid → upsert users → 返回用户对象。
 * 依赖名为 `login` 的云函数（返回 { openid, unionid, appid }）。
 * ⚠️ 该云函数必须先在微信开发者工具中「上传并部署」，否则调用会失败
 *    （FunctionName Not Found / -501000），此时无法登录、也无法写入记录。
 *    本方法不做匿名降级写入，避免脏数据；失败时 reject 并标记 err.cloudFnMissing。
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
        const missing = isCloudFunctionMissing(err);
        if (err && typeof err === 'object') err.cloudFnMissing = missing;
        console.warn(
          missing
            ? '[auth] 云登录失败：login 云函数未部署/不存在，请在微信开发者工具中右键 cloudfunctions/login →「上传并部署（云端安装依赖）」'
            : '[auth] 云登录失败',
          err
        );
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
  isCloudFunctionMissing,
};
