// pages/index/index.js —— 日历首页：月历「四源聚合」打点 + 当天事件卡片列表
// 数据来自 services/calendar-service（成长记录 + 课表周展开 + 待办 + 阅读打卡），
// 每天最多 4 个彩色圆点，点击某天在下方展示统一事件卡片（record/schedule/todo/reading）。
// 注意：课表源仅展示兴趣班；学校常规课不在日历（详见 calendar-service）。
// 待办在日历上只读：点击待办卡片仅查看详情，勾选完成/编辑/删除统一回到「待办」tab。
const app = getApp();
const dateUtil = require('../../utils/date');
const auth = require('../../utils/auth');
const calendarService = require('../../services/calendar-service');

Page({
  data: {
    year: 0,
    month: 0, // 0-based
    monthLabel: '',
    weekHeaders: ['一', '二', '三', '四', '五', '六', '日'],
    cells: [], // 42 格，含 dots:[color,...]（最多 4）
    selectedDate: '', // 'YYYY-MM-DD'
    selectedLabel: '',
    dayEvents: [], // 当天四源事件（CalendarEvent[]）
    loading: false,
    // 图例：橙=成长记录 / 蓝=兴趣班 / 紫=待办 / 绿=阅读打卡（校内常规课不展示）
    legend: [
      { color: '#FF8C42', label: '成长记录' },
      { color: '#8FC7F0', label: '兴趣班' },
      { color: '#B7A5F0', label: '待办' },
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
    this.refresh()
      .then(() => wx.stopPullDownRefresh())
      .catch(() => wx.stopPullDownRefresh());
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
    if (!childId) {
      const cells = this.data.cells.map((c) => ({ ...c, dots: [] }));
      this._events = [];
      this._byDay = {};
      this.setData({ cells, loading: false });
      this._loadDay(this.data.selectedDate || dateUtil.ymd(new Date()));
      return;
    }
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

  // 点击事件卡片：待办在日历上「只读」——仅弹只读详情，勾选完成/编辑/删除统一回到「待办」Tab。
  // record/schedule/reading 保持纯展示，不做额外交互。
  onEventTap(e) {
    const idx = e.currentTarget.dataset.index;
    const ev = (this.data.dayEvents || [])[idx];
    if (!ev || ev.type !== 'todo') return;
    const t = ev.raw || {};
    const lines = [];
    if (t.category) lines.push(`分类：${t.category}`);
    lines.push(`截止：${t.dueDate || '不限'}`);
    lines.push(`状态：${t.done ? '已完成 ✅' : '未完成'}`);
    if (t.remark) lines.push(`备注：${t.remark}`);
    wx.showModal({
      title: ev.title || '待办',
      content: lines.join('\n'),
      confirmText: '去待办处理',
      cancelText: '关闭',
      confirmColor: '#FF8C42',
      success: (res) => {
        if (res.confirm) wx.switchTab({ url: '/pages/todo/todo' });
      },
    });
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
    if (auth.openLoginPage()) return;
    const d = this.data.selectedDate;
    wx.navigateTo({ url: `/pages/records/add/add?date=${d}` });
  },
});
