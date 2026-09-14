// pages/schedule/index.js —— 课表：按周几分组的课程网格
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const { WEEKDAYS } = require('../../utils/constants');
const dateUtil = require('../../utils/date');

const COL = db.COLLECTIONS.scheduleItems;

function _yesterdayYYYYMMDD() {
  const d = new Date(Date.now() - 86400000);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

Page({
  data: {
    weekdays: WEEKDAYS,
    grouped: [],
    loading: false,
    submitting: false,
    showAdd: false,
    showEdit: false,
    editingUuid: '',
    form: {
      courseName: '',
      location: '',
      teacher: '',
      weekday: 1,
      startTime: '09:00',
      endTime: '10:00',
      type: 'extra',
      recurrence: 'weekly',
      startDate: '',
      endDate: '',
      excludedDates: [],
    },
    minStartDate: _yesterdayYYYYMMDD(),
    todayStr: '',
  },

  onLoad() {
    this._onChild = () => this.refresh();
    app.on && app.on('activeChildChanged', this._onChild);
    this.setData({ todayStr: dateUtil.todayStr() });
  },
  onShow() {
    this.refresh();
    this.setData({ todayStr: dateUtil.todayStr() });
  },
  onUnload() {
    app.off && app.off('activeChildChanged', this._onChild);
  },
  onPullDownRefresh() {
    this.refresh()
      .then(() => wx.stopPullDownRefresh())
      .catch(() => wx.stopPullDownRefresh());
  },

  async refresh() {
    this.setData({ loading: true });
    const childId = app.globalData.activeChildId;
    if (!childId) {
      const grouped = [1, 2, 3, 4, 5, 6, 7].map((wd) => ({
        weekday: wd,
        label: `周${WEEKDAYS[wd - 1]}`,
        items: [],
      }));
      this.setData({ grouped, loading: false });
      return;
    }
    const items = await db.list(COL, { orderBy: ['startTime', 'asc'] });
    const todayOffUuids = dateUtil.markExcludedUuidsForDate(items);
    const grouped = [1, 2, 3, 4, 5, 6, 7].map((wd) => ({
      weekday: wd,
      label: `周${WEEKDAYS[wd - 1]}`,
      items: items
        .filter((i) => i.weekday === wd)
        .map((it) => Object.assign({}, it, {
          _todayOff: todayOffUuids.has(it.uuid),
        })),
    }));
    this.setData({ grouped, loading: false });
  },

  openAdd() {
    this.setData({
      showAdd: true,
      showEdit: false,
      editingUuid: '',
      form: {
        courseName: '',
        location: '',
        teacher: '',
        weekday: 1,
        startTime: '09:00',
        endTime: '10:00',
        type: 'extra',
        recurrence: 'weekly',
        startDate: '',
        endDate: '',
        excludedDates: [],
      },
    });
  },
  openEdit(e) {
    const uuid = e.currentTarget.dataset.uuid;
    const item = (this.data.grouped.flatMap((g) => g.items) || []).find((i) => i.uuid === uuid);
    if (!item) return;
    this.setData({
      showEdit: true,
      showAdd: false,
      editingUuid: uuid,
      form: {
        courseName: item.courseName || '',
        location: item.location || '',
        teacher: item.teacher || '',
        weekday: item.weekday || 1,
        startTime: item.startTime || '09:00',
        endTime: item.endTime || '10:00',
        type: item.type || 'extra',
        recurrence: item.recurrence || 'weekly',
        startDate: item.startDate || '',
        endDate: item.endDate || '',
        excludedDates: item.excludedDates || [],
      },
    });
  },
  closeAdd() {
    this.setData({ showAdd: false, showEdit: false, editingUuid: '', submitting: false });
  },
  onFormInput(e) {
    const field = e.currentTarget.dataset.field;
    this.setData({ [`form.${field}`]: e.detail.value });
  },
  onWeekdayChange(e) {
    this.setData({ 'form.weekday': Number(e.detail.value) + 1 });
  },
  onStartChange(e) {
    const startTime = e.detail.value;
    this.setData({ 'form.startTime': startTime });
    if (this.data.form.endTime && startTime >= this.data.form.endTime) {
      wx.showToast({ title: '开始时间需早于结束时间', icon: 'none' });
    }
  },
  onEndChange(e) {
    const endTime = e.detail.value;
    this.setData({ 'form.endTime': endTime });
    if (this.data.form.startTime && this.data.form.startTime >= endTime) {
      wx.showToast({ title: '结束时间需晚于开始时间', icon: 'none' });
    }
  },
  onStartDateChange(e) {
    this.setData({ 'form.startDate': e.detail.value });
  },
  onEndDateChange(e) {
    this.setData({ 'form.endDate': e.detail.value });
  },
  onTypeSelect(e) {
    this.setData({ 'form.type': e.currentTarget.dataset.type });
  },
  onToggleTodayOff() {
    const today = this.data.todayStr || dateUtil.todayStr();
    const now = (this.data.form.excludedDates || []).slice();
    const idx = now.indexOf(today);
    if (idx >= 0) now.splice(idx, 1); else now.push(today);
    this.setData({ 'form.excludedDates': now });
  },

  async saveCourse() {
    const f = this.data.form;
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    if (this.data.submitting) return;
    if (!f.courseName.trim()) {
      wx.showToast({ title: '请填写课程名', icon: 'none' });
      return;
    }
    if (f.startTime >= f.endTime) {
      wx.showToast({ title: '结束时间必须晚于开始时间', icon: 'none' });
      return;
    }
    if (f.startDate && f.endDate && f.startDate > f.endDate) {
      wx.showToast({ title: '结束日期必须晚于开始日期', icon: 'none' });
      return;
    }
    const weekday = Number(f.weekday);
    const allItems = (this.data.grouped || []).flatMap((g) => g.items || []);
    const conflict = allItems.find((i) => {
      if (this.data.showEdit && this.data.editingUuid && i.uuid === this.data.editingUuid) return false;
      if (Number(i.weekday) !== weekday) return false;
      return !(f.endTime <= i.startTime || f.startTime >= i.endTime);
    });
    if (conflict) {
      const wdLabel = `周${WEEKDAYS[weekday - 1]}`;
      wx.showToast({ title: `${wdLabel} ${conflict.startTime}-${conflict.endTime} 已有课程，时间冲突`, icon: 'none' });
      return;
    }
    this.setData({ submitting: true });
    wx.showLoading({ title: this.data.showEdit ? '保存中...' : '添加中...', mask: true });
    try {
      const payload = {
        courseName: f.courseName.trim(),
        location: f.location.trim() || null,
        teacher: f.teacher.trim() || null,
        weekday: Number(f.weekday),
        type: f.type,
        recurrence: f.recurrence || 'weekly',
        startTime: f.startTime,
        endTime: f.endTime,
        startDate: f.startDate || null,
        endDate: f.endDate || null,
        excludedDates: f.excludedDates || [],
      };
      if (this.data.showEdit && this.data.editingUuid) {
        await db.updateByUuid(COL, this.data.editingUuid, payload);
        wx.hideLoading();
        this.setData({ showEdit: false, editingUuid: '', submitting: false });
        wx.showToast({ title: '已更新', icon: 'success' });
      } else {
        await db.create(COL, payload);
        wx.hideLoading();
        this.setData({ showAdd: false, submitting: false });
        wx.showToast({ title: '已添加', icon: 'success' });
      }
      this.refresh();
    } catch (err) {
      wx.hideLoading();
      this.setData({ submitting: false });
      wx.showToast({ title: '保存失败', icon: 'none' });
    }
  },

  onDelete(e) {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    const uuid = e.currentTarget.dataset.uuid;
    wx.showActionSheet({
      itemList: ['确认删除该课程', '取消'],
      success: async (res) => {
        if (res.tapIndex !== 0) return;
        await db.softDelete(COL, uuid);
        this.refresh();
        wx.showToast({ title: '已删除', icon: 'success' });
      },
    });
  },
});
