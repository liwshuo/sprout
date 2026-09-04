// pages/mine/mine.js —— 我的：孩子信息 + 多孩子切换 + 周报入口 + 登录/绑手机
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const dateUtil = require('../../utils/date');

Page({
  data: {
    user: null,
    children: [],
    activeChildId: '',
    activeChild: null,
    stats: { records: 0, books: 0 },
    // 添加孩子弹层
    showAddChild: false,
    childForm: { name: '', birthDate: '' },
  },

  onLoad() {
    this._onUser = (u) => this.setData({ user: u });
    app.on && app.on('userChanged', this._onUser);
  },
  onShow() {
    this.setData({ user: auth.currentUser(), activeChildId: app.globalData.activeChildId });
    this.refresh();
  },
  onUnload() {
    app.off && app.off('userChanged', this._onUser);
  },

  async refresh() {
    const children = await db.children.listAll();
    let activeChildId = app.globalData.activeChildId;
    // 无选中孩子时默认选第一个
    if ((!activeChildId || !children.find((c) => c.uuid === activeChildId)) && children.length) {
      activeChildId = children[0].uuid;
      app.setActiveChild(activeChildId);
    }
    const activeChild = children.find((c) => c.uuid === activeChildId) || null;
    this.setData({ children, activeChildId, activeChild });
    this._loadStats();
  },

  async _loadStats() {
    const [records, books] = await Promise.all([db.records.listAll(999), db.books.listAll()]);
    this.setData({ stats: { records: records.length, books: books.length } });
  },

  switchChild(e) {
    const uuid = e.currentTarget.dataset.uuid;
    app.setActiveChild(uuid);
    this.setData({ activeChildId: uuid, activeChild: this.data.children.find((c) => c.uuid === uuid) || null });
    this._loadStats();
    wx.showToast({ title: '已切换', icon: 'none' });
  },

  // ---- 登录 ----
  doLogin() {
    if (!app.globalData.cloudReady) {
      wx.showToast({ title: '云环境未配置', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '登录中...', mask: true });
    auth
      .ensureLogin()
      .then((u) => {
        app.globalData.currentUser = u;
        wx.hideLoading();
        this.setData({ user: u });
        this.refresh();
        wx.showToast({ title: '登录成功', icon: 'success' });
      })
      .catch(() => {
        wx.hideLoading();
        wx.showToast({ title: '登录失败，请部署 login 云函数', icon: 'none' });
      });
  },

  // 手机号快速验证按钮回调
  onGetPhone(e) {
    if (!e.detail || !e.detail.cloudID) return;
    auth
      .bindPhone(e.detail.cloudID)
      .then(() => {
        wx.showToast({ title: '已绑定手机号', icon: 'success' });
        this.setData({ user: auth.currentUser() });
      })
      .catch(() => wx.showToast({ title: '绑定失败', icon: 'none' }));
  },

  // ---- 添加孩子 ----
  openAddChild() {
    this.setData({ showAddChild: true, childForm: { name: '', birthDate: '' } });
  },
  closeAddChild() {
    this.setData({ showAddChild: false });
  },
  onChildInput(e) {
    this.setData({ 'childForm.name': e.detail.value });
  },
  onBirthChange(e) {
    this.setData({ 'childForm.birthDate': e.detail.value });
  },
  async saveChild() {
    const { name, birthDate } = this.data.childForm;
    if (!name.trim()) {
      wx.showToast({ title: '请填写昵称', icon: 'none' });
      return;
    }
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '保存中...', mask: true });
    try {
      const birthTs = birthDate ? dateUtil.startOfDay(new Date(birthDate.replace(/-/g, '/'))) : null;
      const child = await db.children.create({
        name: name.trim(),
        birthDate: birthTs,
        sortOrder: this.data.children.length,
      });
      wx.hideLoading();
      this.setData({ showAddChild: false });
      app.setActiveChild(child.uuid);
      this.refresh();
      wx.showToast({ title: '已添加', icon: 'success' });
    } catch (err) {
      wx.hideLoading();
      wx.showToast({ title: '保存失败', icon: 'none' });
    }
  },

  goReport() {
    wx.showToast({ title: '周报生成开发中', icon: 'none' });
  },
});
