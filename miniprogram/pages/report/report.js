// pages/report/report.js —— 成长周报：按周聚合记录，展示统计与总结
const db = require('../../utils/db');
const dateUtil = require('../../utils/date');
const { MOODS, categoryColor } = require('../../utils/constants');

const DAY = 24 * 3600 * 1000;

Page({
  data: {
    weekOffset: 0, // 0=本周，-1=上周
    rangeLabel: '',
    weekTitle: '本周',
    recordCount: 0,
    moodStats: [], // [{ key, emoji, label, count, percent }]
    topMood: null,
    books: [], // 本周涉及的书籍标题
    categoryStats: [], // [{ name, count, color }]
    summary: '',
    loading: false,
  },

  onLoad() {
    this.loadWeek(0);
  },

  switchWeek(e) {
    const offset = Number(e.currentTarget.dataset.offset);
    if (offset === this.data.weekOffset) return;
    this.loadWeek(offset);
  },

  // 计算某周（offset：0 本周 / -1 上周）的起止时间戳
  _weekRange(offset) {
    const todayStart = dateUtil.startOfDay(new Date());
    const dayIdx = (new Date().getDay() + 6) % 7; // 周一=0
    const weekStart = todayStart - dayIdx * DAY + offset * 7 * DAY;
    const weekEnd = weekStart + 7 * DAY; // 不含
    return [weekStart, weekEnd];
  },

  async loadWeek(offset) {
    this.setData({ loading: true, weekOffset: offset });
    const [start, end] = this._weekRange(offset);
    const rangeLabel = `${dateUtil.mdCn(start)} - ${dateUtil.mdCn(end - DAY)}`;
    const weekTitle = offset === 0 ? '本周' : offset === -1 ? '上周' : '';
    wx.setNavigationBarTitle({ title: `${weekTitle}成长周报` });

    try {
      const records = await db.records.listByRange(start, end);

      // 心情分布
      const moodCount = {};
      records.forEach((r) => {
        if (r.mood) moodCount[r.mood] = (moodCount[r.mood] || 0) + 1;
      });
      const total = records.length || 1;
      const moodStats = MOODS
        .map((m) => ({
          key: m.key,
          emoji: m.emoji,
          label: m.label,
          count: moodCount[m.key] || 0,
          percent: Math.round(((moodCount[m.key] || 0) / total) * 100),
        }))
        .filter((m) => m.count > 0)
        .sort((a, b) => b.count - a.count);
      const topMood = moodStats[0] || null;

      // 分类分布
      const catCount = {};
      records.forEach((r) => {
        const c = r.category || '其他';
        catCount[c] = (catCount[c] || 0) + 1;
      });
      const categoryStats = Object.keys(catCount)
        .map((name) => ({ name, count: catCount[name], color: categoryColor(name) }))
        .sort((a, b) => b.count - a.count);

      // 本周书籍：按 updatedAt 落在本周范围内
      const allBooks = await db.books.listAll();
      const books = allBooks
        .filter((b) => b.updatedAt >= start && b.updatedAt < end)
        .map((b) => b.title)
        .filter(Boolean);

      // 一句话总结
      let summary;
      if (records.length === 0) {
        summary = `${weekTitle}还没有记录，随手记下宝贝的一个小瞬间吧～`;
      } else {
        const moodPart = topMood ? `，出现最多的心情是${topMood.emoji}${topMood.label}` : '';
        const bookPart = books.length ? `，共读了 ${books.length} 本绘本` : '';
        summary = `${weekTitle}一共记录了 ${records.length} 个成长瞬间${moodPart}${bookPart}。`;
      }

      this.setData({
        rangeLabel,
        weekTitle,
        recordCount: records.length,
        moodStats,
        topMood,
        books,
        categoryStats,
        summary,
        loading: false,
      });
    } catch (err) {
      console.error('[report] 加载失败', err);
      this.setData({ loading: false });
      wx.showToast({ title: '加载失败', icon: 'none' });
    }
  },
});
