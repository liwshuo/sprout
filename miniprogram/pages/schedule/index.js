// pages/schedule/index.js —— 课表：按周几分组的课程网格
const app = getApp();
const db = require('../../utils/db');
const { WEEKDAYS } = require('../../utils/constants');

const COL = db.COLLECTIONS.scheduleItems;

Page({
  data: {
    weekdays: WEEKDAYS, // ['一'..'日']
    grouped: [], // [{ weekday:1, label:'周一', items:[...] }]
    loading: false,
    // 新增弹层
    showAdd: false,
    form: { courseName: '', location: '', weekday: 1, startTime: '09:00', endTime: '10:00', type: 'extra' },
  },

  onLoad() {
    this._onChild = () => this.refresh();
    app.on && app.on('activeChildChanged', this._onChild);
  },
  onShow() {
    this.refresh();
  },
  onUnload() {
    app.off && app.off('activeChildChanged', this._onChild);
  },
  onPullDownRefresh() {
    this.refresh().then(() => wx.stopPullDownRefresh());
  },

  async refresh() {
    this.setData({ loading: true });
    const items = await db.list(COL, { orderBy: ['startTime', 'asc'] });
    const grouped = [1, 2, 3, 4, 5, 6, 7].map((wd) => ({
      weekday: wd,
      label: `周${WEEKDAYS[wd - 1]}`,
      items: items.filter((i) => i.weekday === wd),
    }));
    this.setData({ grouped, loading: false });
  },

  // ---- 新增课程 ----
  openAdd() {
    this.setData({
      showAdd: true,
      form: { courseName: '', location: '', weekday: 1, startTime: '09:00', endTime: '10:00', type: 'extra' },
    });
  },
  closeAdd() {
    this.setData({ showAdd: false });
  },
  onFormInput(e) {
    const field = e.currentTarget.dataset.field;
    this.setData({ [`form.${field}`]: e.detail.value });
  },
  onWeekdayChange(e) {
    this.setData({ 'form.weekday': Number(e.detail.value) + 1 });
  },
  onStartChange(e) {
    this.setData({ 'form.startTime': e.detail.value });
  },
  onEndChange(e) {
    this.setData({ 'form.endTime': e.detail.value });
  },

  async saveCourse() {
    const f = this.data.form;
    if (!f.courseName.trim()) {
      wx.showToast({ title: '请填写课程名', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '添加中...', mask: true });
    try {
      await db.create(COL, {
        courseName: f.courseName.trim(),
        location: f.location.trim() || null,
        teacher: null,
        weekday: f.weekday,
        type: f.type,
        recurrence: 'weekly',
        startTime: f.startTime,
        endTime: f.endTime,
        startDate: null,
        endDate: null,
      });
      wx.hideLoading();
      this.setData({ showAdd: false });
      wx.showToast({ title: '已添加', icon: 'success' });
      this.refresh();
    } catch (err) {
      wx.hideLoading();
      wx.showToast({ title: '添加失败', icon: 'none' });
    }
  },

  onDelete(e) {
    const uuid = e.currentTarget.dataset.uuid;
    wx.showModal({
      title: '删除课程',
      content: '确定从课表中移除吗？',
      confirmColor: '#E5702A',
      success: (res) => {
        if (!res.confirm) return;
        db.softDelete(COL, uuid).then(() => this.refresh());
      },
    });
  },
});
