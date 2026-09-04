// pages/index/index.js —— 日历首页：月历视图 + 有记录日期打点 + 今日记录列表
const app = getApp();
const db = require('../../utils/db');
const dateUtil = require('../../utils/date');
const { categoryColor, moodEmoji } = require('../../utils/constants');

Page({
  data: {
    year: 0,
    month: 0, // 0-based
    monthLabel: '',
    weekHeaders: ['一', '二', '三', '四', '五', '六', '日'],
    cells: [], // 42 格，含 dotColor
    selectedDate: '', // 'YYYY-MM-DD'
    selectedLabel: '',
    dayRecords: [],
    loading: false,
  },

  onLoad() {
    const now = new Date();
    this._buildMonth(now.getFullYear(), now.getMonth(), dateUtil.ymd(now));
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

  // 构建当月网格骨架
  _buildMonth(year, month, selectedDate) {
    const cells = dateUtil.monthGrid(year, month);
    this.setData({
      year,
      month,
      monthLabel: `${year}年${month + 1}月`,
      cells,
      selectedDate: selectedDate || this.data.selectedDate,
    });
  },

  // 拉取当月记录 → 打点 + 今日列表
  async refresh() {
    const { year, month } = this.data;
    this.setData({ loading: true });
    const [start, end] = dateUtil.monthRange(year, month);
    const monthRecords = await db.records.listByRange(start, end);

    // 按天聚合首个分类色做打点
    const dotMap = {};
    monthRecords.forEach((r) => {
      const key = dateUtil.ymd(r.eventDate);
      if (!dotMap[key]) dotMap[key] = categoryColor(r.category);
    });
    const cells = this.data.cells.map((c) => ({
      ...c,
      dotColor: dotMap[c.date] || '',
    }));

    this.setData({ cells, loading: false });
    this._loadDay(this.data.selectedDate || dateUtil.ymd(new Date()), monthRecords);
  },

  // 选中某天的记录列表
  _loadDay(date, monthRecords) {
    const items = (monthRecords || [])
      .filter((r) => dateUtil.ymd(r.eventDate) === date)
      .map((r) => ({
        ...r,
        color: categoryColor(r.category),
        moodIcon: moodEmoji(r.mood),
        cover: (r.imageFileIds && r.imageFileIds[0]) || '',
      }));
    const d = new Date(date.replace(/-/g, '/'));
    this.setData({
      selectedDate: date,
      selectedLabel: dateUtil.mdCn(d),
      dayRecords: items,
    });
    this._hydrateCovers(items);
  },

  // 首图 fileID → 临时链接
  async _hydrateCovers(items) {
    const ids = items.map((i) => i.cover).filter(Boolean);
    if (!ids.length) return;
    const map = await db.getTempUrls(ids);
    const dayRecords = this.data.dayRecords.map((i) => ({
      ...i,
      coverUrl: map[i.cover] || '',
    }));
    this.setData({ dayRecords });
  },

  onTapDay(e) {
    const date = e.currentTarget.dataset.date;
    if (!date) return;
    const { year, month } = this.data;
    const [start, end] = dateUtil.monthRange(year, month);
    db.records.listByRange(start, end).then((recs) => this._loadDay(date, recs));
  },

  prevMonth() {
    let { year, month } = this.data;
    month -= 1;
    if (month < 0) { month = 11; year -= 1; }
    this._buildMonth(year, month, this.data.selectedDate);
    this.refresh();
  },

  nextMonth() {
    let { year, month } = this.data;
    month += 1;
    if (month > 11) { month = 0; year += 1; }
    this._buildMonth(year, month, this.data.selectedDate);
    this.refresh();
  },

  goAdd() {
    const d = this.data.selectedDate;
    wx.navigateTo({ url: `/pages/records/add/add?date=${d}` });
  },
});
