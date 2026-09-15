// utils/settings.js —— 本地「使用偏好」读写（仅存 wx storage，不入云、不随账号同步）
// 目前仅一项：autoTodoToRecord —— 完成待办后是否自动转为成长记录（默认关闭）。
// 之所以走本地存储：这是「本机使用习惯」类开关，不属于孩子档案 / 成长数据，
// 无需云端多端一致，读写零网络成本，勾选待办时同步读取不阻塞。

const KEY = 'sprout_local_settings';

const DEFAULTS = {
  autoTodoToRecord: false, // 完成待办后自动静默生成一条成长记录
};

function all() {
  try {
    const saved = wx.getStorageSync(KEY);
    return Object.assign({}, DEFAULTS, saved && typeof saved === 'object' ? saved : {});
  } catch (e) {
    return Object.assign({}, DEFAULTS);
  }
}

function get(key) {
  return all()[key];
}

function set(key, value) {
  const next = all();
  next[key] = value;
  try {
    wx.setStorageSync(KEY, next);
  } catch (e) { /* ignore quota */ }
  return next;
}

module.exports = {
  KEY,
  DEFAULTS,
  all,
  get,
  set,
};
