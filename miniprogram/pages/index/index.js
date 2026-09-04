// pages/index/index.js —— 日历首页：月历「三源聚合」打点 + 当天事件卡片列表
// 数据来自 services/calendar-service（成长记录 + 课表周展开 + 阅读打卡），
// 每天最多 3 个彩色圆点，点击某天在下方展示统一事件卡片（record/schedule/reading）。
const app = getApp();
const dateUtil = require('../../utils/date');
const calendarService = require('../../services/calendar-service');

Page({
  data: {
    year: 0,
    month: 0, // 0-based
    monthLabel: '',
    weekHeaders: ['一', '二', '三', '四', '五', '六', '日'],
    cells: [], // 42 格，含 dots:[color,...]（最多 3）
    selectedDate: '', // 'YYYY-MM-DD'
    selectedLabel: '',
    dayEvents: [], // 当天三源事件（CalendarEvent[]）
    loading: false,
    // 图例：橙=成长记录 / 蓝=课外班 / 绿=阅读打卡
    legend: [
      { color: '#FF8C42', label: '成长记录' },
      { color: '#8FC7F0', label: '课外班' },
      { color: '#7ED9C3', label: '阅读打卡' },
    ],
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

  // 拉取当月三源事件 → 多彩打点 + 当天事件列表
  async refresh() {
    const { year, month } = this.data;
    this.setData({ loading: true });
    const childId = app.globalData.activeChildId;
    const events = await calendarService.fetchMonthEvents(childId, year, month);
    this._events = events;
    this._byDay = calendarService.groupByDay(events);

    // 每格最多 3 个彩色圆点（record→schedule→reading 去重）
    const cells = this.data.cells.map((c) => ({
      ...c,
      dots: calendarService.dotsForDay(this._byDay[c.date]),
    }));
    this.setData({ cells, loading: false });

    this._loadDay(this.data.selectedDate || dateUtil.ymd(new Date()));
  },

  // 选中某天：直接取缓存的分组事件（课表 + 成长记录 + 阅读打卡）
  _loadDay(date) {
    const dayEvents = (this._byDay && this._byDay[date]) || [];
    const d = new Date(date.replace(/-/g, '/'));
    this.setData({
      selectedDate: date,
      selectedLabel: dateUtil.mdCn(d),
      dayEvents,
    });
  },

  onTapDay(e) {
    const date = e.currentTarget.dataset.date;
    if (!date) return;
    this._loadDay(date);
  },

  prevMonth() {
    let { year, month } = this.data;
    month -= 1;
    if (month < 0) {
      month = 11;
      year -= 1;
    }
    this._buildMonth(year, month, this.data.selectedDate);
    this.refresh();
  },

  nextMonth() {
    let { year, month } = this.data;
    month += 1;
    if (month > 11) {
      month = 0;
      year += 1;
    }
    this._buildMonth(year, month, this.data.selectedDate);
    this.refresh();
  },

  goAdd() {
    const d = this.data.selectedDate;
    wx.navigateTo({ url: `/pages/records/add/add?date=${d}` });
  },
});
