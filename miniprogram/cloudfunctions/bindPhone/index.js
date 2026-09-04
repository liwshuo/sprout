// cloudfunctions/bindPhone/index.js —— 绑定手机号
// 入参：{ code }（getPhoneNumber 返回的动态令牌，新版基础库 >= 2.21.2）
//       兼容旧版：{ cloudID }（手机号快速验证 cloudID）
// 逻辑：调用 phonenumber.getPhoneNumber 拿手机号 → 更新当前 openid 用户 phone 字段
// 返回：{ phone, maskedPhone }（maskedPhone 为脱敏号码）
const cloud = require('wx-server-sdk');

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const db = cloud.database();
const USERS = 'users';

/** 手机号脱敏：138****8000 */
function maskPhone(phone) {
  if (!phone || phone.length < 7) return phone || '';
  return `${phone.slice(0, 3)}****${phone.slice(-4)}`;
}

exports.main = async (event) => {
  const { code, cloudID } = event || {};
  const { OPENID, UNIONID } = cloud.getWXContext();
  const ownerId = UNIONID || OPENID;

  // 1) 解析手机号：优先 code（新版），回退 cloudID（旧版快速验证）
  let phoneInfo = null;
  if (code) {
    const res = await cloud.openapi.phonenumber.getPhoneNumber({ code });
    phoneInfo = (res && res.phoneInfo) || null;
  } else if (cloudID) {
    const res = await cloud.getOpenData({ list: [cloudID] });
    const item = (res && res.list && res.list[0]) || {};
    phoneInfo = (item.data && item.data.phoneInfo) || item.data || null;
  } else {
    throw new Error('缺少 code 或 cloudID');
  }

  const phone = (phoneInfo && (phoneInfo.purePhoneNumber || phoneInfo.phoneNumber)) || '';
  if (!phone) throw new Error('未能解析到手机号');

  // 2) 更新当前用户 phone 字段
  const col = db.collection(USERS);
  const { data } = await col.where({ ownerId }).limit(1).get();
  if (data && data.length) {
    await col.doc(data[0]._id).update({
      data: { phone, updatedAt: Date.now() },
    });
  }

  return { phone, maskedPhone: maskPhone(phone) };
};
