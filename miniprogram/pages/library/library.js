// pages/library/library.js —— 精选书库浏览：分龄筛选 + 搜索 + 加入书架（单本 / 系列分册）
// 数据源：公共只读集合 book_library（db.bookLibrary.listAll，无归属过滤）。
// 加入书架：写用户私有 books；系列书按「方案 A」在私有 series 新建一条并回填 libraryUuid，
//           分册以 seriesUuid + seriesIndex 落库，供书架页 series-service 分组复用。
const app = getApp();
const db = require('../../utils/db');

// 年龄段 Tab（含「官方精选」聚合视图）
const AGE_TABS = [
  { key: 'all', label: '全部' },
  { key: '0-3', label: '0-3岁' },
  { key: '3-6', label: '3-6岁' },
  { key: '6-9', label: '6-9岁' },
  { key: '9-12', label: '9-12岁' },
  { key: 'official', label: '官方精选' },
];

// 年龄段 badge：0-3 粉 / 3-6 橙 / 6-9 绿 / 9-12 蓝（class 在 wxss 定义）
const AGE_BADGE = {
  '0-3': { label: '0-3岁', cls: 'age-03' },
  '3-6': { label: '3-6岁', cls: 'age-36' },
  '6-9': { label: '6-9岁', cls: 'age-69' },
  '9-12': { label: '9-12岁', cls: 'age-912' },
};

// 类型中文名
const TYPE_LABEL = {
  picture: '绘本',
  bridge: '桥梁书',
  chapter: '章节书',
  science: '科普',
};

Page({
  data: {
    ageTabs: AGE_TABS,
    selectedAge: 'all',
    searchKeyword: '',
    displayBooks: [],
    loading: false,

    // 单本「加入书架」面板
    showAddPanel: false,
    activeBook: null,

    // 系列分册面板
    showSeriesPanel: false,
    seriesPanel: null, // { libraryUuid, title, author, ageBadge, ageBadgeCls, typeLabel, volumes:[{index,title}] }
  },

  onLoad() {
    this.loadLibrary();
  },
  onPullDownRefresh() {
    this.loadLibrary().then(() => wx.stopPullDownRefresh());
  },

  // ============ 取数 / 渲染 ============
  async loadLibrary() {
    this.setData({ loading: true });
    const books = await db.bookLibrary.listAll();
    this._allBooks = (books || []).map((b) => this._decorate(b));
    this.applyFilter();
    this.setData({ loading: false });
  },

  // 给书库条目补展示字段（是否系列 / 徽标 / 兜底封面首字）
  _decorate(b) {
    const isSeries = Array.isArray(b.volumes) && b.volumes.length > 0;
    const badge = AGE_BADGE[b.ageRange] || { label: b.ageRange || '', cls: '' };
    const title = b.title || '';
    return Object.assign({}, b, {
      isSeries,
      volumeCount: isSeries ? b.volumes.length : 0,
      ageBadge: badge.label,
      ageBadgeCls: badge.cls,
      typeLabel: TYPE_LABEL[b.type] || '',
      coverUrl: b.coverExternalUrl || '',
      firstChar: title.trim().charAt(0) || '书',
    });
  },

  // 按「年龄段 Tab + 搜索关键词」过滤
  applyFilter() {
    const { selectedAge, searchKeyword } = this.data;
    const kw = (searchKeyword || '').trim().toLowerCase();
    let list = this._allBooks || [];
    if (selectedAge === 'official') {
      list = list.filter((b) => b.isOfficial);
    } else if (selectedAge !== 'all') {
      list = list.filter((b) => b.ageRange === selectedAge);
    }
    if (kw) {
      list = list.filter(
        (b) =>
          (b.title || '').toLowerCase().indexOf(kw) >= 0 ||
          (b.author || '').toLowerCase().indexOf(kw) >= 0
      );
    }
    this.setData({ displayBooks: list });
  },

  onAgeTabChange(e) {
    this.setData({ selectedAge: e.currentTarget.dataset.key }, () => this.applyFilter());
  },
  onSearch(e) {
    this.setData({ searchKeyword: e.detail.value }, () => this.applyFilter());
  },
  clearSearch() {
    this.setData({ searchKeyword: '' }, () => this.applyFilter());
  },

  // 封面加载失败 → 回退为兜底色块（把 coverUrl 清空触发 wx:else 分支）
  onCoverError(e) {
    const uuid = e.currentTarget.dataset.uuid;
    const idx = (this.data.displayBooks || []).findIndex((b) => b.uuid === uuid);
    if (idx >= 0) this.setData({ [`displayBooks[${idx}].coverUrl`]: '' });
  },

  // ============ 书卡点击：单本 → 加入面板；系列 → 分册面板 ============
  onBookTap(e) {
    const uuid = e.currentTarget.dataset.uuid;
    const book = (this._allBooks || []).find((b) => b.uuid === uuid);
    if (!book) return;
    if (book.isSeries) {
      const volumes = (book.volumes || [])
        .slice()
        .sort((a, b) => (Number(a.index) || 0) - (Number(b.index) || 0))
        .map((v) => ({ index: v.index, title: v.title }));
      this.setData({
        showSeriesPanel: true,
        seriesPanel: {
          libraryUuid: book.uuid,
          title: book.title,
          author: book.author || '',
          ageBadge: book.ageBadge,
          ageBadgeCls: book.ageBadgeCls,
          typeLabel: book.typeLabel,
          volumes,
        },
      });
    } else {
      this.setData({ showAddPanel: true, activeBook: book });
    }
  },
  closeAddPanel() {
    this.setData({ showAddPanel: false, activeBook: null });
  },
  closeSeriesPanel() {
    this.setData({ showSeriesPanel: false, seriesPanel: null });
  },
  noop() {},

  // ============ 加入书架 ============
  // 单本面板「加入书架」
  onAddSingle() {
    const book = this.data.activeBook;
    if (book) this.onAddToShelf(book.uuid);
  },
  // 系列面板：加入某一分册
  onAddVolume(e) {
    const { uuid, index } = e.currentTarget.dataset;
    this.onAddToShelf(uuid, Number(index));
  },
  // 系列面板：加入整套
  onAddWholeSeries() {
    const panel = this.data.seriesPanel;
    if (panel) this.onAddToShelf(panel.libraryUuid);
  },

  /**
   * 加入书架主流程：拉孩子 → （多孩子）选择器 → 设为当前孩子 → 写 books（系列另写私有 series）。
   * @param {string} libraryUuid 书库条目 uuid
   * @param {number} [volumeIndex] 仅系列书：指定加入的分册序号；不传则加入整套
   */
  async onAddToShelf(libraryUuid, volumeIndex) {
    const book = (this._allBooks || []).find((b) => b.uuid === libraryUuid);
    if (!book) return;

    // 1. 拉孩子列表
    let children = [];
    try {
      children = await db.children.listAll();
    } catch (err) {
      console.warn('[library] 拉取孩子列表失败', err);
    }
    if (!children || !children.length) {
      wx.showToast({ title: '请先在「我的」创建孩子档案', icon: 'none' });
      return;
    }

    // 2. 多孩子 → 弹选择器
    let childId;
    if (children.length === 1) {
      childId = children[0].uuid;
    } else {
      childId = await this._pickChild(children);
      if (!childId) return; // 用户取消
    }

    // 3. 设为当前孩子（books/series 写入按 activeChildId 归属）
    app.setActiveChild(childId);

    // 4. 写入
    wx.showLoading({ title: '加入中...', mask: true });
    try {
      const result = book.isSeries
        ? await this._addSeriesToShelf(book, volumeIndex)
        : await this._addSingleToShelf(book);
      wx.hideLoading();
      this.setData({
        showAddPanel: false,
        showSeriesPanel: false,
        activeBook: null,
        seriesPanel: null,
      });
      if (result.added > 0) {
        wx.showToast({ title: '已加入书架 📚', icon: 'none' });
      } else if (result.dup > 0) {
        wx.showToast({ title: '这本已在书架里啦～', icon: 'none' });
      } else {
        wx.showToast({ title: '已加入书架 📚', icon: 'none' });
      }
    } catch (err) {
      wx.hideLoading();
      console.error('[library] 加入书架失败', err);
      wx.showToast({ title: '加入失败，请重试', icon: 'none' });
    }
  },

  // 弹出孩子选择器，返回选中的 childId（取消返回 null）
  _pickChild(children) {
    return new Promise((resolve) => {
      wx.showActionSheet({
        itemList: children.map((c) => c.name || '未命名'),
        success: (res) => {
          const c = children[res.tapIndex];
          resolve(c ? c.uuid : null);
        },
        fail: () => resolve(null),
      });
    });
  },

  // 单本加入：按 libraryUuid 去重（当前孩子书架内已存在则不重复添加）
  async _addSingleToShelf(book) {
    const existing = await db.books.listAll();
    if ((existing || []).some((b) => b.libraryUuid === book.uuid)) {
      return { added: 0, dup: 1 };
    }
    await db.books.create({
      title: book.title,
      author: book.author || null,
      coverExternalUrl: book.coverExternalUrl || null,
      totalPages: book.totalPages || null,
      ageRange: book.ageRange || null,
      type: book.type || null,
      description: book.description || null,
      libraryUuid: book.uuid,
      status: 'want',
    });
    return { added: 1, dup: 0 };
  },

  // 系列加入：先确保私有 series（find or create，回填 libraryUuid），再写分册 books（去重）
  async _addSeriesToShelf(book, volumeIndex) {
    const [existingBooks, existingSeries] = await Promise.all([
      db.books.listAll(),
      db.series.listAll(),
    ]);
    // 私有 series：同一孩子下按 libraryUuid 复用，避免重复建系列
    let series = (existingSeries || []).find((s) => s.libraryUuid === book.uuid);
    let seriesUuid;
    if (series) {
      seriesUuid = series.uuid;
    } else {
      const created = await db.series.create({
        name: book.title,
        totalVolumes: (book.volumes || []).length,
        libraryUuid: book.uuid,
      });
      seriesUuid = created.uuid;
    }

    const targetVols =
      volumeIndex != null
        ? (book.volumes || []).filter((v) => Number(v.index) === Number(volumeIndex))
        : (book.volumes || []).slice();

    let added = 0;
    let dup = 0;
    for (let i = 0; i < targetVols.length; i++) {
      const v = targetVols[i];
      const exists = (existingBooks || []).some(
        (b) => b.seriesUuid === seriesUuid && Number(b.seriesIndex) === Number(v.index)
      );
      if (exists) {
        dup++;
        continue;
      }
      // eslint-disable-next-line no-await-in-loop
      await db.books.create({
        title: v.title,
        author: book.author || null,
        coverExternalUrl: book.coverExternalUrl || null,
        totalPages: v.totalPages || null,
        ageRange: book.ageRange || null,
        type: book.type || null,
        description: book.description || null,
        libraryUuid: book.uuid,
        seriesUuid,
        seriesIndex: v.index,
        status: 'want',
      });
      added++;
    }
    return { added, dup };
  },
});
