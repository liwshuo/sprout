// jest.config.js —— Sprout 小程序端单测配置
// 只覆盖 utils / services / cloudfunctions 中的纯逻辑与鉴权逻辑；
// WXML 渲染、真机交互不在此范围（见 tests/README.md 的分层测试说明）。
module.exports = {
  rootDir: '.',
  testEnvironment: 'node',
  // 全局注入 wx / getApp 等小程序运行时桩，使 utils/db.js 等模块可在 Node 下 require
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  testMatch: ['<rootDir>/tests/**/*.test.js'],
  // node_modules 与云函数各自依赖不纳入覆盖率统计
  collectCoverageFrom: [
    'utils/**/*.js',
    'services/**/*.js',
    'cloudfunctions/childShare/index.js',
  ],
  coveragePathIgnorePatterns: ['/node_modules/', '/miniprogram_npm/'],
  clearMocks: true,
};
