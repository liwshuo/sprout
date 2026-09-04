// app.js —— 应用入口：云开发初始化 + 全局登录态管理
const auth = require('./utils/auth');

// 云开发环境 ID：部署时替换为真实环境 ID；
// 留空时使用「当前所属环境」，便于本地未配置环境也能编译运行。
const CLOUD_ENV = 'cloud1-d3gh6o81f2ba198c9'; // e.g. 'sprout-prod-xxxx'

App({
  globalData: {
    cloudReady: false,
    // 登录用户：{ ownerId, openid, unionid, phone, nickname, avatar }
    currentUser: null,
    // 当前选中孩子 uuid 与孩子列表（多孩子切换）
    activeChildId: '',
    children: [],
    syncStatus: 'idle', // idle | syncing | error
    themeColor: '#FF8C42',
  },

  onLaunch() {
    this._initCloud();
    // 恢复本地缓存的登录态与当前孩子，加速冷启动
    this.globalData.activeChildId = wx.getStorageSync('activeChildId') || '';
    this.globalData.currentUser = wx.getStorageSync('currentUser') || null;

    // 静默登录（非阻塞）：解析 openid/unionid 并 upsert users
    if (this.globalData.cloudReady) {
      auth
        .ensureLogin()
        .then((user) => {
          this.globalData.currentUser = user;
          this._emit('userChanged', user);
        })
        .catch((err) => {
          if (auth.isCloudFunctionMissing && auth.isCloudFunctionMissing(err)) {
            console.warn(
              '[app] 静默登录失败：login 云函数未部署。请在微信开发者工具中右键 cloudfunctions/login →「上传并部署（云端安装依赖）」，bindPhone 同理。',
              err
            );
          } else {
            console.warn('[app] 静默登录失败（可稍后在「我的」重试）', err);
          }
        });
    }
  },

  _initCloud() {
    if (!wx.cloud) {
      console.error('[app] 基础库过低，无法使用云能力（需 >= 2.2.3）');
      return;
    }
    try {
      wx.cloud.init({
        env: CLOUD_ENV || wx.cloud.DYNAMIC_CURRENT_ENV,
        traceUser: true,
      });
      this.globalData.cloudReady = true;
    } catch (err) {
      console.error('[app] wx.cloud.init 失败', err);
      this.globalData.cloudReady = false;
    }
  },

  // ---- 极简全局事件总线：页面订阅 activeChildId / user 变化后自刷新 ----
  _listeners: {},
  on(evt, cb) {
    (this._listeners[evt] = this._listeners[evt] || []).push(cb);
  },
  off(evt, cb) {
    const arr = this._listeners[evt];
    if (arr) this._listeners[evt] = arr.filter((f) => f !== cb);
  },
  _emit(evt, payload) {
    (this._listeners[evt] || []).forEach((cb) => {
      try {
        cb(payload);
      } catch (e) {
        console.error('[app] listener error', e);
      }
    });
  },

  // 切换当前孩子并广播
  setActiveChild(childId) {
    this.globalData.activeChildId = childId;
    wx.setStorageSync('activeChildId', childId);
    this._emit('activeChildChanged', childId);
  },
});
