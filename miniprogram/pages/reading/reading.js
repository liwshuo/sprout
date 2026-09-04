// pages/reading/reading.js —— 阅读书架：书籍/系列卡片网格 + 扫码录入 + 系列面板 + 阅读打卡
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const dateUtil = require('../../utils/date');
const readingService = require('../../services/reading-service');
const seriesService = require('../../services/series-service');
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
    renderList: [], // 混合渲染：系列卡片(isSeries:true) + 单本书(isSeries:false)
    loading: false,

    // 添加方式选择弹层（手动 / 扫码 / 新建系列）
    showAddChoice: false,
    // 手动添加书籍弹层
    showAdd: false,
    form: { title: '', author: '' },
    // 扫码确认弹层
    showScanConfirm: false,
    scanForm: { title: '', author: '', cover: '', totalPages: '', isbn: '' },

    // 系列面板
    showSeriesPanel: false,
    seriesPanel: null,
    // 新建系列弹层
    showCreateSeries: false,
    seriesForm: { name: '', totalVolumes: '' },

    // 阅读打卡弹层
    showCheckin: false,
    checkinBookId: '',
    checkinBookTitle: '',
    checkinFrom: '', // '' | 'series'：来源，用于打卡后是否重开系列面板
    checkinForm: { pageFrom: '', pageTo: '', chapter: '', note: '', date: '' },
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

  // ============ 取数 / 渲染 ============
  async refresh() {
    this.setData({ loading: true });
    const [books, seriesList] = await Promise.all([
      db.books.listAll(),
      db.series.listAll(),
    ]);
    // 先水合封面（fileID → 临时链接；外链 coverExternalUrl 直接用），供分组/面板复用
    this._all = await this._hydrateCovers(books);
    this._seriesList = seriesList;
    this._grouped = seriesService.groupBySeries(this._all, this._seriesList);
    this._applyFilter();
    this.setData({ loading: false });
  },

  /**
   * 封面水合：coverExternalUrl（扫码外链）优先直接用；否则 cover(fileID) 批量换临时链接。
   * 返回带 statusLabel / coverUrl 的书籍数组。
   */
  async _hydrateCovers(books) {
    const list = (books || []).map((b) => ({
      ...b,
      statusLabel: (BOOK_STATUS[b.status] || {}).label || '想读',
      coverUrl: b.coverExternalUrl || '',
    }));
    const ids = list.filter((b) => !b.coverExternalUrl && b.cover).map((b) => b.cover);
    if (!ids.length) return list;
    const map = await db.getTempUrls(ids);
    return list.map((b) => ({
      ...b,
      coverUrl: b.coverExternalUrl || map[b.cover] || '',
    }));
  },

  _applyFilter() {
    const { activeTab } = this.data;
    const g = this._grouped || { seriesCards: [], soloBooks: [] };
    let cards = g.seriesCards;
    let solos = g.soloBooks;
    if (activeTab !== 'all') {
      // 单本按状态过滤；系列保留「含 ≥1 本该状态分册」的
      solos = solos.filter((b) => b.status === activeTab);
      cards = cards.filter((c) => (c.volumes || []).some((v) => v.status === activeTab));
    }
    const renderList = [
      ...cards.map((c) => ({ ...c, key: `series_${c.seriesUuid}` })),
      ...solos.map((b) => ({ ...b, key: b.uuid })),
    ];
    this.setData({ renderList });
  },

  switchTab(e) {
    this.setData({ activeTab: e.currentTarget.dataset.key }, () => this._applyFilter());
  },

  // ============ 添加方式选择 ============
  openAddChoice() {
    this.setData({ showAddChoice: true });
  },
  closeAddChoice() {
    this.setData({ showAddChoice: false });
  },
  chooseManual() {
    this._volumeCtx = null; // 普通新增：无系列上下文
    this.setData({ showAddChoice: false, showAdd: true, form: { title: '', author: '' } });
  },
  chooseScan() {
    this.setData({ showAddChoice: false });
    this.openScan();
  },
  chooseCreateSeries() {
    this.setData({ showAddChoice: false });
    this.openCreateSeries();
  },

  // ============ 线 A：扫码录入 ============
  openScan() {
    wx.scanCode({
      onlyFromCamera: true,
      scanType: ['barCode'],
      success: (res) => {
        const isbn = (res.result || '').trim();
        // 校验：13 位数字且 978/979 前缀（图书 EAN-13）
        if (!/^97[89]\d{10}$/.test(isbn)) {
          wx.showToast({ title: '不是有效图书条码，请手动录入', icon: 'none' });
          this._volumeCtx = null;
          this.setData({ showAdd: true, form: { title: '', author: '' } });
          return;
        }
        this._lookupIsbn(isbn);
      },
      fail: () => {
        // 用户主动取消扫码：静默，不打扰
      },
    });
  },

  async _lookupIsbn(isbn) {
    wx.showLoading({ title: '查询中...', mask: true });
    try {
      const res = await wx.cloud.callFunction({ name: 'bookLookup', data: { isbn } });
      wx.hideLoading();
      const r = (res && res.result) || {};
      if (!r.found) {
        wx.showToast({ title: '没查到，手动补充一下吧', icon: 'none' });
      }
      this._openScanConfirm({
        title: r.title || '',
        author: r.author || '',
        cover: r.cover || '',
        totalPages: r.totalPages || '',
        isbn,
      });
    } catch (err) {
      wx.hideLoading();
      console.error('[reading] bookLookup 调用失败', err);
      if (auth.isCloudFunctionMissing && auth.isCloudFunctionMissing(err)) {
        wx.showToast({ title: 'bookLookup 云函数未部署', icon: 'none' });
      } else {
        wx.showToast({ title: '查询失败，可手动录入', icon: 'none' });
      }
      // 兜底：仍打开确认层让用户手填
      this._openScanConfirm({ title: '', author: '', cover: '', totalPages: '', isbn });
    }
  },

  _openScanConfirm(scanForm) {
    this.setData({ showScanConfirm: true, scanForm });
  },
  onScanInput(e) {
    const field = e.currentTarget.dataset.field;
    this.setData({ [`scanForm.${field}`]: e.detail.value });
  },
  closeScanConfirm() {
    this.setData({
      showScanConfirm: false,
      scanForm: { title: '', author: '', cover: '', totalPages: '', isbn: '' },
    });
  },
  async saveScanBook() {
    const { scanForm } = this.data;
    if (!scanForm.title || !scanForm.title.trim()) {
      wx.showToast({ title: '请填写书名', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '添加中...', mask: true });
    try {
      const totalPages =
        scanForm.totalPages !== '' && scanForm.totalPages != null
          ? Number(scanForm.totalPages) || null
          : null;
      await db.books.create({
        title: scanForm.title.trim(),
        author: (scanForm.author || '').trim() || null,
        isbn: scanForm.isbn || null,
        totalPages,
        coverExternalUrl: scanForm.cover || null,
        cover: null,
        status: 'want',
      });
      wx.hideLoading();
      this.setData({ showScanConfirm: false });
      wx.showToast({ title: '已加入书架', icon: 'success' });
      this.refresh();
    } catch (err) {
      wx.hideLoading();
      console.error('[reading] 保存扫码书籍失败', err);
      wx.showToast({ title: '添加失败', icon: 'none' });
    }
  },

  // ============ 手动新增书籍 ============
  openAdd() {
    this._volumeCtx = null;
    this.setData({ showAdd: true, form: { title: '', author: '' } });
  },
  closeAdd() {
    this._volumeCtx = null;
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
      const ctx = this._volumeCtx; // 系列面板内「添加分册」时携带
      const payload = {
        title: title.trim(),
        author: author.trim() || null,
        status: 'want',
      };
      if (ctx && ctx.seriesUuid) {
        payload.seriesUuid = ctx.seriesUuid;
        payload.seriesIndex = ctx.seriesIndex;
      }
      await db.books.create(payload);
      wx.hideLoading();
      this._volumeCtx = null;
      this.setData({ showAdd: false });
      wx.showToast({ title: '已加入书架', icon: 'success' });
      await this.refresh();
      // 若是在系列面板内添加分册，刷新后重开面板保持上下文
      if (ctx && ctx.seriesUuid) {
        const seriesPanel = seriesService.buildPanelVM(ctx.seriesUuid, this._all, this._seriesList);
        this.setData({ showSeriesPanel: true, seriesPanel });
      }
    } catch (err) {
      wx.hideLoading();
      console.error('[reading] 添加书籍失败', err);
      wx.showToast({ title: '添加失败', icon: 'none' });
    }
  },

  // 切换阅读状态：want → reading → done → want（单本卡片封面点击）
  cycleStatus(e) {
    const uuid = e.currentTarget.dataset.uuid;
    const book = (this._all || []).find((b) => b.uuid === uuid);
    if (!book) return;
    const next =
      book.status === 'want' ? 'reading' : book.status === 'reading' ? 'done' : 'want';
    db.books.update(uuid, { status: next }).then(() => this.refresh());
  },

  // ============ 线 B：系列面板 ============
  openSeries(e) {
    const seriesUuid = e.currentTarget.dataset.uuid;
    const seriesPanel = seriesService.buildPanelVM(seriesUuid, this._all, this._seriesList);
    this.setData({ showSeriesPanel: true, seriesPanel });
  },
  closeSeries() {
    this.setData({ showSeriesPanel: false });
  },
  // 在系列面板内新增分册：带 seriesUuid + 下一册序号，复用手动添加弹层
  addVolume(e) {
    const seriesUuid = e.currentTarget.dataset.uuid;
    const seriesIndex = seriesService.nextSeriesIndex(seriesUuid, this._all);
    this._volumeCtx = { seriesUuid, seriesIndex };
    this.setData({ showAdd: true, form: { title: '', author: '' } });
  },

  // ============ 新建系列 ============
  openCreateSeries() {
    this.setData({ showCreateSeries: true, seriesForm: { name: '', totalVolumes: '' } });
  },
  closeCreateSeries() {
    this.setData({ showCreateSeries: false });
  },
  onSeriesFormInput(e) {
    const field = e.currentTarget.dataset.field;
    this.setData({ [`seriesForm.${field}`]: e.detail.value });
  },
  async saveCreateSeries() {
    const { name, totalVolumes } = this.data.seriesForm;
    if (!name || !name.trim()) {
      wx.showToast({ title: '请填写系列名', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '创建中...', mask: true });
    try {
      await db.series.create({
        name: name.trim(),
        totalVolumes:
          totalVolumes !== '' && totalVolumes != null ? Number(totalVolumes) || 0 : 0,
      });
      wx.hideLoading();
      this.setData({ showCreateSeries: false });
      wx.showToast({ title: '系列已创建', icon: 'success' });
      this.refresh();
    } catch (err) {
      wx.hideLoading();
      console.error('[reading] 创建系列失败', err);
      wx.showToast({ title: '创建失败', icon: 'none' });
    }
  },

  // ============ 阅读打卡 ============
  openCheckin(e) {
    const { uuid, title, from } = e.currentTarget.dataset;
    this.setData({
      showCheckin: true,
      checkinBookId: uuid,
      checkinBookTitle: title || '',
      checkinFrom: from || '',
      checkinForm: {
        pageFrom: '',
        pageTo: '',
        chapter: '',
        note: '',
        date: dateUtil.ymd(new Date()), // 默认今天
      },
    });
  },
  closeCheckin() {
    this.setData({ showCheckin: false });
  },
  onCheckinInput(e) {
    const field = e.currentTarget.dataset.field;
    this.setData({ [`checkinForm.${field}`]: e.detail.value });
  },
  onCheckinDateChange(e) {
    this.setData({ 'checkinForm.date': e.detail.value });
  },
  async saveCheckin() {
    const { checkinBookId, checkinForm } = this.data;
    if (!checkinBookId) return;
    const hasContent =
      checkinForm.pageFrom || checkinForm.pageTo || checkinForm.chapter || checkinForm.note;
    if (!hasContent) {
      wx.showToast({ title: '填点内容再打卡吧～', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '打卡中...', mask: true });
    try {
      const readDate = dateUtil.startOfDay(
        new Date((checkinForm.date || dateUtil.ymd(new Date())).replace(/-/g, '/'))
      );
      await readingService.addReadingLog(app.globalData.activeChildId, checkinBookId, {
        readDate,
        pageFrom: checkinForm.pageFrom,
        pageTo: checkinForm.pageTo,
        chapter: checkinForm.chapter.trim() || null,
        note: checkinForm.note.trim() || null,
      });
      wx.hideLoading();
      this.setData({ showCheckin: false });
      wx.showToast({ title: '打卡成功', icon: 'success' });
      // 打卡会派生书籍状态（want→reading / 读完），刷新书架
      const fromSeries = this.data.checkinFrom === 'series';
      const seriesUuid = this.data.seriesPanel && this.data.seriesPanel.seriesUuid;
      await this.refresh();
      // 若从系列面板打卡：重算面板数据并保持面板打开
      if (fromSeries && seriesUuid) {
        const seriesPanel = seriesService.buildPanelVM(seriesUuid, this._all, this._seriesList);
        this.setData({ showSeriesPanel: true, seriesPanel });
      }
    } catch (err) {
      wx.hideLoading();
      console.error('[reading] 打卡失败', err);
      wx.showToast({ title: '打卡失败，请重试', icon: 'none' });
    }
  },
});
