// pages/todo/todo.js —— 孩子待办清单：按孩子过滤 + 分类筛选 + 勾选完成 + 增删改
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const dateUtil = require('../../utils/date');
const { TODO_CATEGORIES, DEFAULT_CATEGORY, categoryMeta, todo } = require('../../utils/todo');

// 分类筛选 tab：「全部」+ 4 个业务分类
const FILTER_ALL = '全部';

Page({
  data: {
    // 登录/孩子
    isLoggedIn: false,
    children: [],
    activeChildId: '',
    activeChildName: '',

    // 分类
    categories: TODO_CATEGORIES,     // [{key,emoji,color}]
    filterTabs: [FILTER_ALL].concat(TODO_CATEGORIES.map((c) => c.key)),
    activeFilter: FILTER_ALL,

    // 列表
    todos: [],          // 当前孩子全部待办（已挂派生字段、已排序）
    displayTodos: [],   // 经分类筛选后的展示列表
    stats: { total: 0, done: 0 },
    loading: false,

    // 新增 / 编辑弹层
    showSheet: false,
    editingUuid: '',
    submitting: false,
    form: { title: '', category: DEFAULT_CATEGORY, dueDate: '', remark: '' },

    todayStr: '',
  },

  // ==================== 生命周期 ====================
  onLoad() {
    this._onChild = (id) => {
      this.setData({ activeChildId: id });
      this.refresh();
    };
    app.on && app.on('activeChildChanged', this._onChild);
    this.setData({ todayStr: dateUtil.ymd(new Date()) });
  },

  onShow() {
    const u = app.globalData.currentUser || auth.currentUser();
    this.setData({
      isLoggedIn: !!u,
      activeChildId: app.globalData.activeChildId,
      todayStr: dateUtil.ymd(new Date()),
    });
    this.refresh();
  },

  onUnload() {
    app.off && app.off('activeChildChanged', this._onChild);
  },

  onPullDownRefresh() {
    this.refresh()
      .then(() => wx.stopPullDownRefresh())
      .catch(() => wx.stopPullDownRefresh());
  },

  // ==================== 数据加载 ====================
  async refresh() {
    this.setData({ loading: true });
    // 顶部孩子过滤 chip 数据（不按 childId 过滤）
    const children = await db.children.listAll();
    let activeChildId = app.globalData.activeChildId;
    if ((!activeChildId || !children.find((c) => c.uuid === activeChildId)) && children.length) {
      activeChildId = children[0].uuid;
      app.setActiveChild(activeChildId);
    }
    const activeChild = children.find((c) => c.uuid === activeChildId) || null;
    (children || []).forEach((c) => {
      c._displayName = c.name || '宝贝';
    });

    // 无孩子档案：短路空态
    if (!activeChildId) {
      this.setData({
        children,
        activeChildId: '',
        activeChildName: '',
        todos: [],
        displayTodos: [],
        stats: { total: 0, done: 0 },
        loading: false,
      });
      return;
    }

    const raw = await todo.listAll();
    const list = this._decorate(raw);
    this.setData({
      children,
      activeChildId,
      activeChildName: (activeChild && (activeChild.name || '宝贝')) || '',
      todos: list,
      stats: { total: list.length, done: list.filter((t) => t.done).length },
      loading: false,
    });
    this._applyFilter();
  },

  // 挂派生字段（分类元信息 / 截止日期文案 / 逾期标记）并排序
  _decorate(list) {
    const today = this.data.todayStr || dateUtil.ymd(new Date());
    const out = (list || []).map((t) => {
      const meta = categoryMeta(t.category);
      const overdue = !t.done && !!t.dueDate && t.dueDate < today;
      const dueSoon = !t.done && !!t.dueDate && t.dueDate === today;
      return Object.assign({}, t, {
        _catEmoji: meta.emoji,
        _catColor: meta.color,
        _catLabel: t.category || '其他',
        _dueLabel: t.dueDate ? (dueSoon ? '今天' : t.dueDate) : '',
        _overdue: overdue,
      });
    });
    // 排序：未完成在前、已完成在后；组内按截止日期升序（无截止排后），再按创建时间倒序
    out.sort((a, b) => {
      if (!!a.done !== !!b.done) return a.done ? 1 : -1;
      const da = a.dueDate || '9999-99-99';
      const dbb = b.dueDate || '9999-99-99';
      if (da !== dbb) return da < dbb ? -1 : 1;
      return (b.createdAt || 0) - (a.createdAt || 0);
    });
    return out;
  },

  _applyFilter() {
    const { todos, activeFilter } = this.data;
    const displayTodos = activeFilter === FILTER_ALL
      ? todos
      : todos.filter((t) => (t.category || '其他') === activeFilter);
    this.setData({ displayTodos });
  },

  // ==================== 顶部过滤交互 ====================
  onSwitchChild(e) {
    const uuid = e.currentTarget.dataset.uuid;
    if (!uuid || uuid === this.data.activeChildId) return;
    app.setActiveChild(uuid); // 触发 activeChildChanged → refresh
  },

  onFilterTap(e) {
    const key = e.currentTarget.dataset.key;
    if (key === this.data.activeFilter) return;
    this.setData({ activeFilter: key }, () => this._applyFilter());
  },

  // ==================== 勾选完成 ====================
  async onToggleDone(e) {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    const uuid = e.currentTarget.dataset.uuid;
    const item = this.data.todos.find((t) => t.uuid === uuid);
    if (!item) return;
    const next = !item.done;
    // 乐观更新：先本地翻转，再落库
    const todos = this.data.todos.map((t) => (t.uuid === uuid ? Object.assign({}, t, { done: next }) : t));
    const sorted = this._decorate(todos);
    this.setData({ todos: sorted, stats: { total: sorted.length, done: sorted.filter((t) => t.done).length } }, () => this._applyFilter());
    try {
      await todo.toggleDone(uuid, next);
      if (next) this._offerGrowthRecord(item);
    } catch (err) {
      console.error('[todo] toggleDone 失败', err);
      wx.showToast({ title: '操作失败', icon: 'none' });
      this.refresh();
    }
  },

  async _offerGrowthRecord(item) {
    if (item.convertedRecordId) {
      const existing = await db.getByUuid(db.COLLECTIONS.dailyRecords, item.convertedRecordId);
      if (existing && !existing.isDeleted) {
        wx.showToast({ title: '已记录到成长档案', icon: 'none' });
        return;
      }
      await todo.markConverted(item.uuid, null).catch(() => {});
    }
    wx.showModal({
      title: '完成啦 🎉',
      content: '要把这次完成记录到成长档案吗？',
      confirmText: '记录成长',
      cancelText: '暂不记录',
      success: (res) => {
        if (!res.confirm) return;
        wx.navigateTo({
          url: `/pages/records/add/add?sourceTodoId=${encodeURIComponent(item.uuid)}`,
        });
      },
    });
  },

  // ==================== 新增 / 编辑 ====================
  openAdd() {
    if (auth.openLoginPage()) return;
    if (!this.data.activeChildId) {
      wx.showToast({ title: '请先在「我的」添加孩子', icon: 'none' });
      return;
    }
    this.setData({
      showSheet: true,
      editingUuid: '',
      submitting: false,
      form: { title: '', category: DEFAULT_CATEGORY, dueDate: '', remark: '' },
    });
  },

  openEdit(e) {
    const uuid = e.currentTarget.dataset.uuid;
    const item = this.data.todos.find((t) => t.uuid === uuid);
    if (!item) return;
    this.setData({
      showSheet: true,
      editingUuid: uuid,
      submitting: false,
      form: {
        title: item.title || '',
        category: item.category || DEFAULT_CATEGORY,
        dueDate: item.dueDate || '',
        remark: item.remark || '',
      },
    });
  },

  closeSheet() {
    this.setData({ showSheet: false, editingUuid: '', submitting: false });
  },

  onTitleInput(e) {
    this.setData({ 'form.title': e.detail.value });
  },
  onRemarkInput(e) {
    this.setData({ 'form.remark': e.detail.value });
  },
  onCategorySelect(e) {
    this.setData({ 'form.category': e.currentTarget.dataset.key });
  },
  onDueDateChange(e) {
    this.setData({ 'form.dueDate': e.detail.value });
  },
  onClearDueDate() {
    this.setData({ 'form.dueDate': '' });
  },

  async saveTodo() {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    if (this.data.submitting) return;
    const f = this.data.form;
    if (!f.title.trim()) {
      wx.showToast({ title: '请填写待办内容', icon: 'none' });
      return;
    }
    this.setData({ submitting: true });
    wx.showLoading({ title: this.data.editingUuid ? '保存中...' : '添加中...', mask: true });
    try {
      const payload = {
        title: f.title.trim(),
        category: f.category || DEFAULT_CATEGORY,
        dueDate: f.dueDate || null,
        remark: (f.remark || '').trim(),
      };
      if (this.data.editingUuid) {
        await todo.update(this.data.editingUuid, payload);
        wx.hideLoading();
        this.setData({ showSheet: false, editingUuid: '', submitting: false });
        wx.showToast({ title: '已更新', icon: 'success' });
      } else {
        await todo.create(payload);
        wx.hideLoading();
        this.setData({ showSheet: false, submitting: false });
        wx.showToast({ title: '已添加', icon: 'success' });
      }
      this.refresh();
    } catch (err) {
      wx.hideLoading();
      this.setData({ submitting: false });
      console.error('[todo] saveTodo 失败', err);
      wx.showToast({ title: '保存失败', icon: 'none' });
    }
  },

  // ==================== 删除 ====================
  onDelete(e) {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    const uuid = e.currentTarget.dataset.uuid;
    wx.showActionSheet({
      itemList: ['确认删除该待办', '取消'],
      itemColor: '#FF4D4F',
      success: async (res) => {
        if (res.tapIndex !== 0) return;
        try {
          await todo.remove(uuid);
          this.refresh();
          wx.showToast({ title: '已删除', icon: 'success' });
        } catch (err) {
          console.error('[todo] onDelete 失败', err);
          wx.showToast({ title: '删除失败', icon: 'none' });
        }
      },
    });
  },
});
