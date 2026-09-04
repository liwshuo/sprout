// cloudfunctions/login/index.js —— 登录：解析 openid 并 upsert users
// 入参：无（云函数自动携带 openid/unionid）
// 逻辑：cloud.getWXContext() 拿 openid → 查 users → 不存在则创建 → 返回身份
// 返回：{ openid, unionid, appid, isNew, userInfo }
const cloud = require('wx-server-sdk');

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const db = cloud.database();
const USERS = 'users';

exports.main = async () => {
  const { OPENID, UNIONID, APPID } = cloud.getWXContext();
  const openid = OPENID || '';
  const unionid = UNIONID || null;
  // ownerId 优先 unionid，否则 openid（对齐 utils/auth.js 与技术方案 §2）
  const ownerId = unionid || openid;

  const col = db.collection(USERS);
  const { data } = await col.where({ ownerId }).limit(1).get();

  // 已存在：刷新 openid/unionid/updatedAt，返回既有用户
  if (data && data.length) {
    const doc = data[0];
    const now = Date.now();
    await col.doc(doc._id).update({
      data: { openid, unionid: unionid || doc.unionid || null, updatedAt: now },
    });
    return {
      openid,
      unionid: unionid || doc.unionid || null,
      appid: APPID || '',
      isNew: false,
      userInfo: Object.assign({}, doc, {
        openid,
        unionid: unionid || doc.unionid || null,
        updatedAt: now,
      }),
    };
  }

  // 不存在：创建新用户（nickname 默认「宝贝的爸爸/妈妈」，avatar 默认空）
  const now = Date.now();
  const userInfo = {
    ownerId,
    openid,
    unionid,
    phone: null,
    nickname: '宝贝的爸爸/妈妈',
    avatar: '',
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  };
  const addRes = await col.add({ data: userInfo });
  return {
    openid,
    unionid,
    appid: APPID || '',
    isNew: true,
    userInfo: Object.assign({ _id: addRes._id }, userInfo),
  };
};
