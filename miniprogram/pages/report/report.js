// pages/report/report.js —— 成长周报
// 渲染优先级：
//   1. 若 weekly_reports 集合已存在 (ownerId, childId, weekStart) 那份 → 直接展示 + 提供「重新计算最新」按钮
//   2. 若无 → 前端本地用 services/report-service 实时聚合 → 展示 + 提供「保存到云端」按钮
// 所有聚合逻辑与云函数 generateWeeklyReport 字节级对齐（共用 services/report-service）
const app = getApp();
const db = require('../../utils/db');
const dateUtil = require('../../utils/date');
const reportSvc = require('../../services/report-service');

const DAY = 24 * 3600 * 1000;

Page({
  data: {
    weekOffset: 0,
    rangeLabel: '',
    weekTitle: '本周',
    // 来源标识：'cloud'=从 weekly_reports 读的；'local'=前端实时算
    dataSource: null,
    // 报告内容（含概览/分布/书单/一句话总结）
    recordCount: 0,
    activeDays: 0,
    readingMinutes: 0,
    moodStats: [],
    topMood: null,
    books: [], // 字符串数组（本地）/ 对象数组（云端含进度）统一展示为 title 行
    categoryStats: [],
    summary: '',
    loading: false,
    regenerating: false,
  },

  onLoad() {
    this._onActiveChild = () => this.loadWeek(this.data.weekOffset);
    app.on && app.on('activeChildChanged', this._onActiveChild);
    this.loadWeek(0);
  },

  onUnload() {
    app.off && app.off('activeChildChanged', this._onActiveChild);
  },

  switchWeek(e) {
    const offset = Number(e.currentTarget.dataset.offset);
    if (offset === this.data.weekOffset) return;
    this.loadWeek(offset);
  },

  _weekRange(offset) {
    const todayStart = dateUtil.startOfDay(new Date());
    const dayIdx = (new Date().getDay() + 6) % 7; // 周一=0
    const weekStart = todayStart - dayIdx * DAY + offset * 7 * DAY;
    const weekEnd = weekStart + 7 * DAY;
    return [weekStart, weekEnd];
  },

  async loadWeek(offset) {
    this.setData({ loading: true, weekOffset: offset, dataSource: null });
    const childId = app.globalData.activeChildId;
    if (!childId) {
      const [start, endExclusive] = this._weekRange(offset);
      const rangeLabel = `${dateUtil.mdCn(start)} - ${dateUtil.mdCn(endExclusive - DAY)}`;
      const weekTitle = offset === 0 ? '本周' : offset === -1 ? '上周' : '';
      wx.setNavigationBarTitle({ title: `${weekTitle}成长周报` });
      this._applyReport({ recordCount: 0, activeDays: 0, readingMinutes: 0, books: [], moodStats: [], categoryStats: [], summary: '' }, 'local', rangeLabel, weekTitle);
      return;
    }
    const [start, endExclusive] = this._weekRange(offset);
    const rangeLabel = `${dateUtil.mdCn(start)} - ${dateUtil.mdCn(endExclusive - DAY)}`;
    const weekTitle = offset === 0 ? '本周' : offset === -1 ? '上周' : '';
    wx.setNavigationBarTitle({ title: `${weekTitle}成长周报` });

    try {
      // 先查云端周报
      const existing = await db.weeklyReports.getByWeek(start);
      if (existing) {
        this._applyReport(existing, 'cloud', rangeLabel, weekTitle);
        return;
      }

      // 无云端数据：前端本地聚合（services/report-service）
      const [records, readingLogs, allBooks] = await Promise.all([
        db.records.listByRange(start, endExclusive),
        db.readingLogs.listByRange(start, endExclusive),
        db.books.listAll(),
      ]);
      const report = reportSvc.aggregateWeekly(start, endExclusive, {
        records, readingLogs, books: allBooks,
      });
      this._applyReport(report, 'local', rangeLabel, weekTitle);
    } catch (err) {
      console.error('[report] 加载失败', err);
      this.setData({ loading: false });
      wx.showToast({ title: '加载失败', icon: 'none' });
    }
  },

  _applyReport(report, source, rangeLabel, weekTitle) {
    // 书单统一转为 字符串数组（便于现有 wxml 复用）
    const books = Array.isArray(report.books)
      ? report.books.map((b) => (typeof b === 'string' ? b : (b && b.title) || '未命名绘本'))
      : [];
    this.setData({
      rangeLabel,
      weekTitle,
      dataSource: source,
      recordCount: report.recordCount || 0,
      activeDays: report.activeDays || 0,
      readingMinutes: report.readingMinutes || 0,
      moodStats: report.moodStats || [],
      topMood: report.topMood || null,
      categoryStats: report.categoryStats || [],
      books,
      summary: report.summary || '',
      loading: false,
    });
  },

  /** 手动触发：云函数重新生成本周报告（保存到云端） */
  async regenerate() {
    if (this.data.regenerating) return;
    const activeChildId = (app && app.globalData && app.globalData.activeChildId) || '';
    if (!activeChildId) {
      wx.showToast({ title: '请先选择孩子', icon: 'none' });
      return;
    }
    this.setData({ regenerating: true });
    wx.showLoading({ title: '生成中...', mask: true });
    try {
      const [start] = this._weekRange(this.data.weekOffset);
      await wx.cloud.callFunction({
        name: 'generateWeeklyReport',
        data: { forceChildId: activeChildId, forceWeekStart: start },
      });
      wx.hideLoading();
      wx.showToast({ title: '已保存最新周报', icon: 'success' });
      this.loadWeek(this.data.weekOffset);
    } catch (err) {
      console.error('[report] regenerate 失败', err);
      wx.hideLoading();
      wx.showToast({ title: '生成失败，请稍后重试', icon: 'none' });
    } finally {
      this.setData({ regenerating: false });
    }
  },

  goRecords() {
    wx.switchTab({ url: '/pages/records/records' });
  },
});
