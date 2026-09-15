// pages/mine/privacy/privacy.js —— 隐私设置：撤回同意 / 清缓存 / 申请删除账号 + 使用偏好
const app = getApp();
const auth = require('../../../utils/auth');
const settings = require('../../../utils/settings');

Page({
  data: {
    isLoggedIn: false,
    showPolicy: false,
    showDeleteRequest: false,
    // 使用偏好：完成待办后自动转为成长记录（本地开关，默认关闭）
    autoTodoToRecord: false,
    policyText: [
      '• 家长身份（openid/unionid）：用于登录与多端同步；',
      '• 手机号（可选）：账号找回；',
      '• 孩子档案（姓名/生日/性别）：本地+云端存储，用于生成成长周报；',
      '• 成长记录 / 图片 / 阅读打卡：仅本账号可见，不对外共享；',
      '所有云端数据均存储于中国大陆境内腾讯云（CloudBase）。',
      '如需完整 PDF 版隐私政策：设置 → 帮助与反馈。',
    ],
  },

  onLoad() {
    const u = (app && app.globalData && app.globalData.currentUser) || auth.currentUser();
    this.setData({
      isLoggedIn: !!u,
      autoTodoToRecord: !!settings.get('autoTodoToRecord'),
    });
  },

  // 切换「完成待办后自动转为成长记录」——本地存储，即时生效
  onToggleAutoTodoToRecord(e) {
    const on = !!(e && e.detail && e.detail.value);
    settings.set('autoTodoToRecord', on);
    this.setData({ autoTodoToRecord: on });
    wx.showToast({ title: on ? '已开启自动记录' : '已关闭', icon: 'none' });
  },

  onViewPolicy() {
    this.setData({ showPolicy: true });
  },
  closePolicy() {
    this.setData({ showPolicy: false });
  },

  onRevokeConsent() {
    wx.showActionSheet({
      itemList: ['确认撤回同意并退出登录', '取消'],
      itemColor: '#FF4D4F',
      success: (res) => {
        if (res.tapIndex === 0) {
          auth.logout();
          this.setData({ isLoggedIn: false });
          wx.showToast({ title: '已撤回同意并退出', icon: 'none' });
          setTimeout(() => wx.navigateBack({ delta: 1 }), 900);
        }
      },
    });
  },

  onClearCache() {
    try {
      wx.clearStorageSync();
    } catch (e) { /* ignore quota */ }
    wx.showLoading({ title: '清除中...', mask: true });
    wx.getStorageInfo({
      success: () => {
        wx.hideLoading();
        wx.showToast({ title: '本地缓存已清除', icon: 'success' });
      },
      fail: () => {
        wx.hideLoading();
        wx.showToast({ title: '本地缓存已清除', icon: 'success' });
      },
    });
  },

  onRequestDeleteAccount() {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    this.setData({ showDeleteRequest: true });
  },
  closeDeleteRequest() {
    this.setData({ showDeleteRequest: false });
  },
  onCopyOwnerId() {
    const ownerId = auth.ownerId() || '';
    const tail = ownerId.length > 6 ? ownerId.slice(-6) : ownerId;
    wx.setClipboardData({
      data: `[Sprout 删除申请] ownerId=${ownerId}`,
      success: () => {
        wx.showToast({ title: `账号标识末6位 ${tail} 已复制`, icon: 'none' });
        this.setData({ showDeleteRequest: false });
      },
      fail: () => {
        wx.showToast({ title: `账号末6位：${tail}`, icon: 'none' });
        this.setData({ showDeleteRequest: false });
      },
    });
  },

  onFeedback() {
    wx.setClipboardData({
      data: 'sprout-support@example.com',
      success: () => wx.showToast({ title: '反馈邮箱已复制', icon: 'none' }),
    });
  },
});
