// pages/reading/reading.js —— 阅读书架：书籍卡片网格，按状态分组
const app = getApp();
const db = require('../../utils/db');
const { BOOK_STATUS } = require('../../utils/constants');

Page({
  data: {
    tabs: [
      { key: 'all', label: '全部' },
      { key: 'reading', label: '在读' },
      { key: 'want', label: '想读' },
      { key: 'done', label: '读完' },
    ],
    activeTab: 'all',
    books: [], // 当前筛选后的书
    loading: false,
    // 新增书籍弹层
    showAdd: false,
    form: { title: '', author: '' },
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
    this._all = await db.books.listAll();
    this._applyFilter();
    this.setData({ loading: false });
    this._hydrateCovers();
  },

  _applyFilter() {
    const { activeTab } = this.data;
    const list = (this._all || [])
      .filter((b) => activeTab === 'all' || b.status === activeTab)
      .map((b) => ({
        ...b,
        statusLabel: (BOOK_STATUS[b.status] || {}).label || '想读',
        coverUrl: '',
      }));
    this.setData({ books: list });
  },

  async _hydrateCovers() {
    const ids = (this.data.books || []).map((b) => b.cover).filter(Boolean);
    if (!ids.length) return;
    const map = await db.getTempUrls(ids);
    const books = this.data.books.map((b) => ({ ...b, coverUrl: map[b.cover] || '' }));
    this.setData({ books });
  },

  switchTab(e) {
    this.setData({ activeTab: e.currentTarget.dataset.key }, () => {
      this._applyFilter();
      this._hydrateCovers();
    });
  },

  // ---- 新增书籍 ----
  openAdd() {
    this.setData({ showAdd: true, form: { title: '', author: '' } });
  },
  closeAdd() {
    this.setData({ showAdd: false });
  },
  onFormInput(e) {
    const field = e.currentTarget.dataset.field;
    this.setData({ [`form.${field}`]: e.detail.value });
  },
  async saveBook() {
    const { title, author } = this.data.form;
    if (!title.trim()) {
      wx.showToast({ title: '请填写书名', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '添加中...', mask: true });
    try {
      await db.books.create({
        title: title.trim(),
        author: author.trim() || null,
        status: 'want',
      });
      wx.hideLoading();
      this.setData({ showAdd: false });
      wx.showToast({ title: '已加入书架', icon: 'success' });
      this.refresh();
    } catch (err) {
      wx.hideLoading();
      wx.showToast({ title: '添加失败', icon: 'none' });
    }
  },

  // 切换阅读状态：want → reading → done → want
  cycleStatus(e) {
    const uuid = e.currentTarget.dataset.uuid;
    const book = (this._all || []).find((b) => b.uuid === uuid);
    if (!book) return;
    const next = book.status === 'want' ? 'reading' : book.status === 'reading' ? 'done' : 'want';
    db.books.update(uuid, { status: next }).then(() => this.refresh());
  },
});
