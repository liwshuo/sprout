// utils/ui.js —— 全局 Toast/交互 统一入口
// 所有页面不再直接调用 wx.showToast，改走本文件 3 个语义化方法，便于日后统一样式/埋点。

function toastSuccess(title, opts = {}) {
  try {
    wx.showToast({
      title: title || '',
      icon: 'success',
      duration: opts.duration || 1500,
      mask: !!opts.mask,
    });
  } catch (e) { /* ignore */ }
}

function toastError(title, opts = {}) {
  try {
    wx.showToast({
      title: title || '操作失败',
      icon: 'none',
      duration: opts.duration || 2000,
      mask: !!opts.mask,
    });
  } catch (e) { /* ignore */ }
}

function toastInfo(title, opts = {}) {
  try {
    wx.showToast({
      title: title || '',
      icon: 'none',
      duration: opts.duration || 1500,
      mask: !!opts.mask,
    });
  } catch (e) { /* ignore */ }
}

module.exports = {
  toastSuccess,
  toastError,
  toastInfo,
};
