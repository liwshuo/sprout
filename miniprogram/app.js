// app.js
App({
  onLaunch() {
    if (!wx.cloud) {
      console.error('请使用 2.2.3 或以上的基础库以使用云能力');
    } else {
      wx.cloud.init({
        // env 需替换为实际云开发环境 ID
        env: 'YOUR_ENV_ID',
        traceUser: true,
      });
    }
  },
  globalData: {
    userInfo: null,
    themeColor: '#FF8C42',
  },
});
