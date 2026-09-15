// pages/schedule/course-library/index.js —— 课程库：课程模板的增删改（名称 / 分类 / 颜色）
const app = getApp();
const db = require('../../../utils/db');
const auth = require('../../../utils/auth');

// 可选颜色（校内偏冷色、兴趣班偏暖色，但不强制）
const COLORS = [
  '#6FB0E3', '#4FB6D9', '#7FC29B', '#B79BE0', '#5C6BC0',
  '#FF8C42', '#F0837E', '#F06B9A', '#F4B740', '#8D9440',
];

Page({
  data: {
    loading: false,
    hasChild: false,
    schoolList: [],
    extraList: [],
    colors: COLORS,
    // 新增 / 编辑弹层
    showSheet: false,
    editingUuid: '',
    form: { name: '', type: 'school', color: COLORS[0] },
    submitting: false,
  },

  onLoad() {
    this._onChild = () => this.refresh(true);
    app.on && app.on('activeChildChanged', this._onChild);
  },
  onShow() {
    this.refresh(true);
  },
  onUnload() {
    app.off && app.off('activeChildChanged', this._onChild);
  },
  onPullDownRefresh() {
    this.refresh(true).then(() => wx.stopPullDownRefresh()).catch(() => wx.stopPullDownRefresh());
  },

  // seed=true 时，若课程库为空则写入预置课程
  async refresh(seed) {
    const childId = app.globalData.activeChildId;
    if (!auth.ownerId() || !childId) {
      this.setData({ hasChild: false, schoolList: [], extraList: [] });
      return;
    }
    this.setData({ loading: true, hasChild: true });
    let list = [];
    try {
      list = seed ? await db.courseTemplates.ensureSeed() : await db.courseTemplates.listAll();
    } catch (e) {
      list = [];
    }
    this.setData({
      loading: false,
      schoolList: list.filter((t) => t.type === 'school'),
      extraList: list.filter((t) => t.type !== 'school'),
    });
  },

  openAdd() {
    if (auth.openLoginPage()) return;
    if (!app.globalData.activeChildId) {
      wx.showToast({ title: '请先添加/选择孩子', icon: 'none' });
      return;
    }
    this.setData({
      showSheet: true,
      editingUuid: '',
      form: { name: '', type: 'school', color: COLORS[0] },
    });
  },
  openEdit(e) {
    const t = e.currentTarget.dataset.tpl;
    if (!t) return;
    this.setData({
      showSheet: true,
      editingUuid: t.uuid,
      form: { name: t.name || '', type: t.type === 'school' ? 'school' : 'extra', color: t.color || COLORS[0] },
    });
  },
  closeSheet() {
    this.setData({ showSheet: false, editingUuid: '', submitting: false });
  },
  onNameInput(e) {
    this.setData({ 'form.name': e.detail.value });
  },
  onTypeSelect(e) {
    this.setData({ 'form.type': e.currentTarget.dataset.type });
  },
  onColorSelect(e) {
    this.setData({ 'form.color': e.currentTarget.dataset.color });
  },

  async onSave() {
    const f = this.data.form;
    if (this.data.submitting) return;
    if (!f.name.trim()) {
      wx.showToast({ title: '请填写课程名称', icon: 'none' });
      return;
    }
    this.setData({ submitting: true });
    wx.showLoading({ title: '保存中...', mask: true });
    try {
      const payload = { name: f.name.trim(), type: f.type, color: f.color };
      if (this.data.editingUuid) {
        await db.courseTemplates.update(this.data.editingUuid, payload);
      } else {
        await db.courseTemplates.create(payload);
      }
      wx.hideLoading();
      this.setData({ showSheet: false, editingUuid: '', submitting: false });
      wx.showToast({ title: '已保存', icon: 'success' });
      this.refresh(false);
    } catch (err) {
      wx.hideLoading();
      this.setData({ submitting: false });
      wx.showToast({ title: '保存失败', icon: 'none' });
    }
  },

  onDelete() {
    const uuid = this.data.editingUuid;
    if (!uuid) return;
    wx.showModal({
      title: '删除课程',
      content: '删除后不影响课表里已排好的课程，确认删除吗？',
      confirmColor: '#e5702a',
      success: async (res) => {
        if (!res.confirm) return;
        try {
          await db.courseTemplates.remove(uuid);
          this.setData({ showSheet: false, editingUuid: '' });
          wx.showToast({ title: '已删除', icon: 'success' });
          this.refresh(false);
        } catch (e) {
          wx.showToast({ title: '删除失败', icon: 'none' });
        }
      },
    });
  },

  // 长按卡片也可快速删除
  onCardLongPress(e) {
    const t = e.currentTarget.dataset.tpl;
    if (!t) return;
    wx.showModal({
      title: '删除课程',
      content: `确认从课程库删除「${t.name}」吗？`,
      confirmColor: '#e5702a',
      success: async (res) => {
        if (!res.confirm) return;
        try {
          await db.courseTemplates.remove(t.uuid);
          wx.showToast({ title: '已删除', icon: 'success' });
          this.refresh(false);
        } catch (err) {
          wx.showToast({ title: '删除失败', icon: 'none' });
        }
      },
    });
  },
});
