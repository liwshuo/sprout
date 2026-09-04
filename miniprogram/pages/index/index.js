// pages/index/index.js - 首页（日历记录）
Page({
  data: {
    title: '日历',
    today: '',
  },
  onLoad() {
    const d = new Date();
    this.setData({
      today: `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`,
    });
  },
});
