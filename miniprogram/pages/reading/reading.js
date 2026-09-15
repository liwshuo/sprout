// pages/reading/reading.js —— 阅读书架：书籍/系列卡片网格 + 扫码录入 + 系列面板 + 阅读打卡
const app = getApp();
const db = require('../../utils/db');
const auth = require('../../utils/auth');
const dateUtil = require('../../utils/date');
const readingService = require('../../services/reading-service');
const seriesService = require('../../services/series-service');
const { BOOK_STATUS, BOOK_TYPES, PICTURE_MAX_PAGES } = require('../../utils/constants');

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
    _lock: {},

    // 书架概览统计（含系列分册）：藏书 / 在读 / 读完
    stats: { total: 0, reading: 0, done: 0 },
    // 各状态 tab 计数（与筛选口径一致）
    tabCounts: { all: 0, reading: 0, want: 0, done: 0 },

    // 添加方式选择弹层（手动 / 扫码 / 新建系列）
    showAddChoice: false,
    // 手动添加书籍弹层
    showAdd: false,
    form: {
      title: '', author: '', bookType: 'picture', totalPages: '',
      chapterCount: '', chapterNames: '',
      belongsSeries: false, seriesChoice: '', // '' 未选 | '__new__' 新建 | seriesUuid
      newSeriesName: '', newSeriesTotal: '', seriesIndex: '',
    },
    // 书型选项（segmented picker）
    bookTypeOptions: [
      { key: 'picture', label: '绘本' },
      { key: 'chapter', label: '章节书' },
      { key: 'free', label: '自由阅读' },
    ],
    // 方案 B：加书时「归入系列」的可选系列（含末尾「＋ 新建系列」），refresh 时刷新
    seriesOptions: [],
    seriesPickerIndex: 0,
    addInSeriesCtx: false, // true=从系列面板添加分册（方案A），隐藏「归入系列」区
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
    // 分书型打卡上下文（openCheckin 计算）
    checkinMode: 'free', // picture | chapter | free（历史书按有无章节推断）
    checkinIsSeriesVol: false, // 是否系列分册（决定是否显示「读完这册」）
    checkinOneTap: false, // 绘本/短书：默认一键读完整本
    checkinPicturePartial: false, // 绘本切到「只读了一部分」
    checkinTotalPages: 0,
    checkinTotalChapters: 0,
    checkinCurrentPage: 0, // 上次读到的页（自由阅读带进度用）
    checkinChapters: [], // 章节书 chips：[{ idx, label, read }]
    checkinSelChapter: -1, // 当前选中的章 index（0-based）
    checkinMarkDone: false, // 系列分册「读完这册」勾选态
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
    this.refresh()
      .then(() => wx.stopPullDownRefresh())
      .catch(() => wx.stopPullDownRefresh());
  },

  // 手动加书表单的初始态（每次打开弹层重置）
  _blankForm() {
    return {
      title: '', author: '', bookType: 'picture', totalPages: '',
      chapterCount: '', chapterNames: '',
      belongsSeries: false, seriesChoice: '',
      newSeriesName: '', newSeriesTotal: '', seriesIndex: '',
    };
  },

  // ============ 取数 / 渲染 ============
  async refresh() {
    this.setData({ loading: true });
    const childId = app.globalData.activeChildId;
    if (!childId) {
      this._all = [];
      this._seriesList = [];
      this._grouped = {};
      this.setData({
        renderList: [],
        loading: false,
        stats: { total: 0, reading: 0, done: 0 },
        tabCounts: { all: 0, reading: 0, want: 0, done: 0 },
      });
      return;
    }
    const [books, seriesList] = await Promise.all([
      db.books.listAll(),
      db.series.listAll(),
    ]);
    // 书库 join 水合：带 libraryUuid 的书回填书库元信息（书名/作者/封面/年龄段/类型/简介），
    // 已有手动值不覆盖。放在封面水合之前，让 coverExternalUrl 能被后续 _hydrateCovers 复用。
    const hydratedBooks = await this._hydrateFromLibrary(books);
    // 再水合封面（fileID → 临时链接；外链 coverExternalUrl 直接用），供分组/面板复用
    this._all = await this._hydrateCovers(hydratedBooks);
    this._seriesList = seriesList;
    this._grouped = seriesService.groupBySeries(this._all, this._seriesList);
    // 方案 B「归入系列」下拉：现有系列 + 末尾「＋ 新建系列」
    const seriesOptions = (this._seriesList || []).map((s) => ({
      label: s.name || '未命名系列',
      value: s.uuid,
    }));
    seriesOptions.push({ label: '＋ 新建系列', value: '__new__' });
    this._computeStats();
    this._applyFilter();
    this.setData({ loading: false, seriesOptions });
  },

  /**
   * 计算书架概览统计（含系列分册）+ 各状态 tab 计数。
   * - stats：藏书总数 / 在读 / 读完（按所有单本书统计，口径直观）。
   * - tabCounts：与 _applyFilter 的筛选口径一致（单本按 status；系列含 ≥1 本该状态分册即计入）。
   */
  _computeStats() {
    const all = this._all || [];
    const total = all.length;
    let reading = 0;
    let done = 0;
    all.forEach((b) => {
      if (b.status === 'reading') reading += 1;
      else if (b.status === 'done') done += 1;
    });
    const g = this._grouped || { seriesCards: [], soloBooks: [] };
    const cards = g.seriesCards || [];
    const solos = g.soloBooks || [];
    const countFor = (status) =>
      solos.filter((b) => b.status === status).length +
      cards.filter((c) => (c.volumes || []).some((v) => v.status === status)).length;
    const tabCounts = {
      all: cards.length + solos.length,
      reading: countFor('reading'),
      want: countFor('want'),
      done: countFor('done'),
    };
    this.setData({ stats: { total, reading, done }, tabCounts });
  },

  /**
   * 书库 join 水合：一次性拉 book_library 建 Map，对带 libraryUuid 的书回填元信息。
   * 回填字段：title / author / coverExternalUrl / ageRange / type / description。
   * 原则：书自身已有非空值则保留（用户手动改过的不覆盖）。
   * @param {Array} books 原始书籍列表
   * @returns {Promise<Array>} 回填后的书籍列表
   */
  async _hydrateFromLibrary(books) {
    const list = books || [];
    const needs = list.filter((b) => b && b.libraryUuid);
    if (!needs.length) return list;
    const app = getApp();
    // B3：优先用全局缓存，命中则不再重复拉取；未命中（首次）才拉全量书库并回写缓存
    let libBooks = app.globalData.bookLibraryCache;
    if (!Array.isArray(libBooks)) {
      libBooks = await db.bookLibrary.listAll();
      app.globalData.bookLibraryCache = Array.isArray(libBooks) ? libBooks : [];
      libBooks = app.globalData.bookLibraryCache;
    }
    if (!libBooks.length) return list;
    const map = {};
    libBooks.forEach((lb) => {
      if (lb && lb.uuid) map[lb.uuid] = lb;
    });
    const FIELDS = ['title', 'author', 'coverExternalUrl', 'ageRange', 'type', 'description'];
    const isEmpty = (v) => v == null || v === '';
    return list.map((b) => {
      if (!b || !b.libraryUuid) return b;
      const lb = map[b.libraryUuid];
      if (!lb) return b;
      const patch = {};
      FIELDS.forEach((f) => {
        // 仅在书自身该字段为空时，用书库值回填（保留用户手动值）
        if (isEmpty(b[f]) && !isEmpty(lb[f])) patch[f] = lb[f];
      });
      return Object.keys(patch).length ? Object.assign({}, b, patch) : b;
    });
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
    if (auth.openLoginPage()) return;
    this.setData({ showAddChoice: true });
  },
  closeAddChoice() {
    this.setData({ showAddChoice: false });
  },
  // 跳转「精选书库」浏览页（从书库加入书架后，回到书架会 onShow→refresh 自动水合）
  goLibrary() {
    this.setData({ showAddChoice: false });
    wx.navigateTo({ url: '/pages/library/library' });
  },
  chooseManual() {
    this._volumeCtx = null; // 普通新增：无系列上下文
    this.setData({ showAddChoice: false, showAdd: true, addInSeriesCtx: false, seriesPickerIndex: 0, form: this._blankForm() });
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
          this.setData({ showAdd: true, addInSeriesCtx: false, seriesPickerIndex: 0, form: this._blankForm() });
          return;
        }
        this._lookupIsbn(isbn);
      },
      fail: (err) => {
        const errMsg = (err && err.errMsg) || '';
        if (errMsg.indexOf('cancel') < 0 && errMsg.indexOf('auth deny') >= 0) {
          wx.showToast({ title: '无法使用相机，请手动录入', icon: 'none' });
          this._volumeCtx = null;
          this.setData({ showAdd: true, addInSeriesCtx: false, seriesPickerIndex: 0, form: this._blankForm() });
        }
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
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先到「我的」登录', icon: 'none' });
      return;
    }
    if (this._tryLock('saveScanBook', 1500)) return;
    const { scanForm } = this.data;
    if (!scanForm.title || !scanForm.title.trim()) {
      this._unlock('saveScanBook');
      wx.showToast({ title: '请填写书名', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '添加中...', mask: true });
    try {
      const totalPages =
        scanForm.totalPages !== '' && scanForm.totalPages != null
          ? Number(scanForm.totalPages) || null
          : null;
      const created = await db.books.create({
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
      // 加入书架成功后：对 book_library.hotScore 原子自增（若该书库条目存在）
      this._incLibraryHotScoreByIsbn(scanForm.isbn, created.uuid);
      this.refresh();
    } catch (err) {
      wx.hideLoading();
      console.error('[reading] 保存扫码书籍失败', err);
      wx.showToast({ title: '添加失败', icon: 'none' });
    } finally {
      this._unlock('saveScanBook');
    }
  },

  // 扫码加入书架后：尝试用 isbn 在 book_library 里找对应条目，命中则 +1 热度
  // 失败静默（不影响加入书架的用户体验；热度属于锦上添花字段）
  async _incLibraryHotScoreByIsbn(isbn, createdBookUuid) {
    try {
      if (!isbn) return;
      const list = Array.isArray(this._libraryList)
        ? this._libraryList
        : (await db.bookLibrary.listAll());
      this._libraryList = list;
      const hit = list.find((lb) => lb.isbn === isbn);
      if (!hit) return;
      const delta = 1;
      if (Math.abs(delta) > 10) {
        console.warn('[reading] bookLibraryInc delta 超 ±10 上限，拦截', delta);
        return;
      }
      await wx.cloud.callFunction({
        name: 'bookLibraryInc',
        data: { bookLibraryUuid: hit.uuid, delta },
      });
    } catch (err) {
      console.warn('[reading] bookLibraryInc(hotScore) 失败，跳过', err);
    }
  },
  // ============ 手动新增书籍 ============
  openAdd() {
    this._volumeCtx = null;
    this.setData({ showAdd: true, addInSeriesCtx: false, seriesPickerIndex: 0, form: this._blankForm() });
  },
  closeAdd() {
    this._volumeCtx = null;
    this.setData({ showAdd: false });
  },
  onFormInput(e) {
    const field = e.currentTarget.dataset.field;
    this.setData({ [`form.${field}`]: e.detail.value });
  },
  // 选择书型（绘本 / 章节书 / 自由阅读）
  selectBookType(e) {
    this.setData({ 'form.bookType': e.currentTarget.dataset.key });
  },
  // 方案 B：切换「这本书属于某个系列」
  onBelongsSeriesChange(e) {
    this.setData({ 'form.belongsSeries': !!e.detail.value });
  },
  // 方案 B：从下拉选择已有系列或「＋ 新建系列」
  onSeriesPick(e) {
    const idx = Number(e.detail.value);
    const opt = (this.data.seriesOptions || [])[idx];
    this.setData({ seriesPickerIndex: idx, 'form.seriesChoice': opt ? opt.value : '' });
  },
  async saveBook() {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先到「我的」登录', icon: 'none' });
      return;
    }
    if (this._tryLock('saveBook', 1500)) return;
    const f = this.data.form;
    const title = (f.title || '').trim();
    if (!title) {
      this._unlock('saveBook');
      wx.showToast({ title: '请填写书名', icon: 'none' });
      return;
    }
    const ctx = this._volumeCtx; // 系列面板内「添加分册」时携带（方案 A）
    // 方案 B 校验：勾选归入系列时必须选定系列 / 填新系列名
    if (!ctx && f.belongsSeries) {
      if (!f.seriesChoice) {
        this._unlock('saveBook');
        wx.showToast({ title: '请选择或新建系列', icon: 'none' });
        return;
      }
      if (f.seriesChoice === '__new__' && !(f.newSeriesName || '').trim()) {
        this._unlock('saveBook');
        wx.showToast({ title: '请填写系列名', icon: 'none' });
        return;
      }
    }
    wx.showLoading({ title: '添加中...', mask: true });
    try {
      const bookType = f.bookType || 'picture';
      const payload = {
        title,
        author: (f.author || '').trim() || null,
        status: 'want',
        bookType,
      };
      // 总页数（选填）
      if (f.totalPages !== '' && f.totalPages != null) {
        payload.totalPages = Number(f.totalPages) || null;
      }
      // 章节书：优先按「章节名（每行一个）」，否则按「章节数」生成 totalChapters
      if (bookType === 'chapter') {
        const names = (f.chapterNames || '')
          .split('\n')
          .map((s) => s.trim())
          .filter(Boolean);
        if (names.length) {
          payload.chapters = names;
          payload.totalChapters = names.length;
        } else if (f.chapterCount !== '' && f.chapterCount != null) {
          const n = Number(f.chapterCount) || 0;
          if (n > 0) payload.totalChapters = n;
        }
      }
      // 系列归属：方案 A（系列面板上下文）优先；否则方案 B（表单勾选）
      if (ctx && ctx.seriesUuid) {
        payload.seriesUuid = ctx.seriesUuid;
        payload.seriesIndex = ctx.seriesIndex;
      } else if (f.belongsSeries && f.seriesChoice) {
        let seriesUuid = f.seriesChoice;
        if (seriesUuid === '__new__') {
          const created = await db.series.create({
            name: (f.newSeriesName || '').trim(),
            totalVolumes:
              f.newSeriesTotal !== '' && f.newSeriesTotal != null ? Number(f.newSeriesTotal) || 0 : 0,
          });
          seriesUuid = created && created.uuid;
        }
        if (seriesUuid) {
          payload.seriesUuid = seriesUuid;
          payload.seriesIndex =
            f.seriesIndex !== '' && f.seriesIndex != null
              ? Number(f.seriesIndex) || seriesService.nextSeriesIndex(seriesUuid, this._all)
              : seriesService.nextSeriesIndex(seriesUuid, this._all);
        }
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
    } finally {
      this._unlock('saveBook');
    }
  },

  // 切换阅读状态：want → reading → done → want（单本卡片封面点击）
  cycleStatus(e) {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先到「我的」登录', icon: 'none' });
      return;
    }
    if (this._tryLock('cycleStatus', 600)) {
      wx.showToast({ title: '操作太频繁啦～', icon: 'none' });
      return;
    }
    const uuid = e.currentTarget.dataset.uuid;
    const book = (this._all || []).find((b) => b.uuid === uuid);
    if (!book) { this._unlock('cycleStatus'); return; }
    const next =
      book.status === 'want' ? 'reading' : book.status === 'reading' ? 'done' : 'want';
    db.books.update(uuid, { status: next })
      .then(() => this.refresh())
      .catch((err) => {
        console.error('[reading] cycleStatus 失败', err);
        wx.showToast({ title: err.message || '更新失败', icon: 'none' });
      })
      .finally(() => this._unlock('cycleStatus'));
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
    // 方案 A：分册序号已由系列上下文决定，表单隐藏「归入系列」区
    this.setData({ showAdd: true, showSeriesPanel: false, addInSeriesCtx: true, seriesPickerIndex: 0, form: this._blankForm() });
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
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先到「我的」登录', icon: 'none' });
      return;
    }
    if (this._tryLock('saveCreateSeries', 2000)) return;
    const { name, totalVolumes } = this.data.seriesForm;
    if (!name || !name.trim()) {
      this._unlock('saveCreateSeries');
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
    } finally {
      this._unlock('saveCreateSeries');
    }
  },

  // ============ 阅读打卡 ============
  openCheckin(e) {
    const { uuid, title, from } = e.currentTarget.dataset;
    const book = (this._all || []).find((b) => b.uuid === uuid) || {};
    // 书型：显式 bookType 优先；历史书按「有 totalChapters → chapter，否则 free」推断
    const bookType = book.bookType || (Number(book.totalChapters) > 0 ? 'chapter' : 'free');
    const totalPages = Number(book.totalPages) || 0;
    const totalChapters =
      Number(book.totalChapters) || (Array.isArray(book.chapters) ? book.chapters.length : 0);
    const currentPage = Number(book.currentPage) || 0;
    const currentChapter = Number.isFinite(Number(book.currentChapter))
      ? Number(book.currentChapter)
      : -1;
    const isSeriesVol = !!book.seriesUuid;
    // 绘本/短书（总页数 ≤ 阈值）默认走「读完整本」一键打卡
    const oneTap = bookType === 'picture' || (totalPages > 0 && totalPages <= PICTURE_MAX_PAGES);
    // 章节书 chips（已知总章数时）：标注已读、默认选中「下一章」
    let checkinChapters = [];
    let selChapter = -1;
    if (bookType === 'chapter' && totalChapters > 0) {
      const names = Array.isArray(book.chapters) ? book.chapters : [];
      for (let i = 0; i < totalChapters; i += 1) {
        checkinChapters.push({ idx: i, label: names[i] || `第${i + 1}章`, read: i <= currentChapter });
      }
      selChapter = Math.min(currentChapter + 1, totalChapters - 1);
      if (selChapter < 0) selChapter = 0;
    }
    // 自由阅读：起始页自动带上次进度（上次结束页 + 1）
    const nextStartPage = currentPage > 0 ? currentPage + 1 : '';
    this.setData({
      showCheckin: true,
      checkinBookId: uuid,
      checkinBookTitle: title || book.title || '',
      checkinFrom: from || '',
      checkinMode: bookType,
      checkinIsSeriesVol: isSeriesVol,
      checkinOneTap: oneTap,
      checkinPicturePartial: false,
      checkinTotalPages: totalPages,
      checkinTotalChapters: totalChapters,
      checkinCurrentPage: currentPage,
      checkinChapters,
      checkinSelChapter: selChapter,
      checkinMarkDone: false,
      checkinForm: {
        pageFrom: nextStartPage === '' ? '' : String(nextStartPage),
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
  // 章节书：选中「读到第几章」
  selectChapter(e) {
    this.setData({ checkinSelChapter: Number(e.currentTarget.dataset.idx) });
  },
  // 绘本：在「读完整本」与「只读了一部分」之间切换
  togglePicturePartial() {
    this.setData({ checkinPicturePartial: !this.data.checkinPicturePartial });
  },
  // 系列分册：切换「读完这册」勾选
  toggleMarkDone() {
    this.setData({ checkinMarkDone: !this.data.checkinMarkDone });
  },
  onCheckinInput(e) {
    const field = e.currentTarget.dataset.field;
    this.setData({ [`checkinForm.${field}`]: e.detail.value });
  },
  onCheckinDateChange(e) {
    this.setData({ 'checkinForm.date': e.detail.value });
  },
  async saveCheckin() {
    if (!auth.ownerId()) {
      wx.showToast({ title: '请先登录', icon: 'none' });
      return;
    }
    if (this._tryLock('saveCheckin', 1500)) return;
    const { checkinBookId, checkinForm, checkinMode } = this.data;
    if (!checkinBookId) { this._unlock('saveCheckin'); return; }

    // 按书型组装打卡数据 + 判定是否有内容
    const note = (checkinForm.note || '').trim() || null;
    const data = { note };
    let hasContent = !!note;
    let markDone = false;

    if (checkinMode === 'picture') {
      if (this.data.checkinPicturePartial) {
        // 只读了一部分：记录页码区间
        data.pageFrom = checkinForm.pageFrom;
        data.pageTo = checkinForm.pageTo;
        hasContent = hasContent || !!checkinForm.pageFrom || !!checkinForm.pageTo;
      } else {
        // 读完整本：一键打卡
        markDone = true;
        if (this.data.checkinTotalPages) data.pageTo = this.data.checkinTotalPages;
        hasContent = true;
      }
    } else if (checkinMode === 'chapter') {
      if (this.data.checkinTotalChapters > 0 && this.data.checkinSelChapter >= 0) {
        const idx = this.data.checkinSelChapter;
        const ch = (this.data.checkinChapters || [])[idx];
        data.chapterIndex = idx;
        data.chapter = (ch && ch.label) || `第${idx + 1}章`;
        hasContent = true;
        // 读到最后一章 → 视为读完
        if (idx >= this.data.checkinTotalChapters - 1) markDone = true;
      } else {
        // 无章节元信息：手填章节文本
        data.chapter = (checkinForm.chapter || '').trim() || null;
        hasContent = hasContent || !!data.chapter;
      }
    } else {
      // 自由阅读：起始页 + 结束页（+ 选填章节）
      data.pageFrom = checkinForm.pageFrom;
      data.pageTo = checkinForm.pageTo;
      data.chapter = (checkinForm.chapter || '').trim() || null;
      hasContent = hasContent || !!checkinForm.pageFrom || !!checkinForm.pageTo || !!data.chapter;
    }

    // 系列分册「读完这册」：显式勾选则强制完成（幂等，已 done 不重复计数）
    if (this.data.checkinIsSeriesVol && this.data.checkinMarkDone) {
      markDone = true;
      hasContent = true;
    }
    if (markDone) data.markDone = true;

    if (!hasContent) {
      this._unlock('saveCheckin');
      wx.showToast({ title: '填点内容再打卡吧～', icon: 'none' });
      return;
    }
    wx.showLoading({ title: '打卡中...', mask: true });
    try {
      const readDateStr = checkinForm.date || dateUtil.ymd(new Date());
      const readDate = dateUtil.startOfDay(new Date(readDateStr.replace(/-/g, '/')));
      const todayEnd = dateUtil.startOfNextDay(new Date());
      if (readDate >= todayEnd) {
        this._unlock('saveCheckin');
        wx.hideLoading();
        wx.showToast({ title: '打卡日期不能晚于今天', icon: 'none' });
        return;
      }
      data.readDate = readDate;
      await readingService.addReadingLog(app.globalData.activeChildId, checkinBookId, data);
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
    } finally {
      this._unlock('saveCheckin');
    }
  },

  // 防抖提交锁（mine/library 同款）
  _tryLock(key, ms = 1000) {
    const now = Date.now();
    const lock = this.data._lock || {};
    if (lock[key] && now - lock[key] < ms) return true;
    lock[key] = now;
    this.setData({ _lock: lock });
    return false;
  },
  _unlock(key) {
    const lock = Object.assign({}, this.data._lock || {});
    delete lock[key];
    this.setData({ _lock: lock });
  },
});
