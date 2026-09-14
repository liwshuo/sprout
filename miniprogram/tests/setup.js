// tests/setup.js —— 小程序运行时全局桩
// utils/db.js、utils/auth.js、services/* 在模块顶层直接引用了 wx / getApp 等
// 小程序宿主全局对象。Node/Jest 环境没有这些全局，需在 require 之前注入桩，
// 否则一 require 就抛 ReferenceError。
//
// 约定：
//   - wx.cloud.callFunction 默认返回空实现，具体用例用 jest.fn 覆写。
//   - getApp() 返回可变的 globalData，用例可通过 __setActiveChild 调整当前孩子。

const globalData = {
  activeChildId: '',
  children: [],
  currentUser: null,
  loginVerified: false,
};

function resetGlobalData() {
  globalData.activeChildId = '';
  globalData.children = [];
  globalData.currentUser = null;
  globalData.loginVerified = false;
}

// 供用例设置「当前孩子 / 登录态」
global.__setActiveChild = (childId) => {
  globalData.activeChildId = childId || '';
};
// 供用例设置登录用户（auth.ownerId()/openid() 读取此处）
global.__setUser = (user) => {
  globalData.currentUser = user || null;
  globalData.loginVerified = !!user;
};
global.__resetGlobalData = resetGlobalData;

global.getApp = () => ({
  globalData,
  on() {},
  off() {},
  emit() {},
});

// App / Page / Component / getCurrentPages —— 仅需存在，不需实现
global.App = () => {};
global.Page = () => {};
global.Component = () => {};
global.getCurrentPages = () => [];

// wx 宿主 API 桩：默认最小实现，用例可覆盖 wx.cloud.callFunction
global.wx = {
  cloud: {
    callFunction: jest.fn(async () => ({ result: { ok: true, items: [], todos: [] } })),
    database: jest.fn(),
    uploadFile: jest.fn(),
  },
  getStorageSync: jest.fn(() => ''),
  setStorageSync: jest.fn(),
  removeStorageSync: jest.fn(),
  showToast: jest.fn(),
  showModal: jest.fn(),
};

beforeEach(() => {
  resetGlobalData();
  // clearMocks:true 已清除调用记录，这里恢复 callFunction 的默认实现
  global.wx.cloud.callFunction.mockImplementation(async () => ({
    result: { ok: true, items: [], todos: [] },
  }));
  // 被测代码在「回退 / 鉴权失败」等分支会主动打印 warn/error，属预期行为，
  // 静默以保持测试输出干净（如需排查可临时注释）。
  jest.spyOn(console, 'warn').mockImplementation(() => {});
  jest.spyOn(console, 'error').mockImplementation(() => {});
});
