// services/report-service.js —— 周报聚合纯函数（小程序端 + 云函数共享同一份逻辑）
//
// 设计原则：
//   ✅ 纯函数：输入全部是参数，输出是对象，不依赖任何外部模块（wx.* / cloud / 本地存储）
//   ✅ 无副作用：不做 IO/写库/Toast
//   ✅ 小程序端 / generateWeeklyReport 云函数 逻辑 100% 对齐（复制粘贴等价）
//   —— 未来如果需要真正一份代码三处用，再考虑抽 npm 包或软链；V1 保持复制的稳定性。
//
// SSOT：docs/AGGREGATION_RULES.md §3 周报聚合算法
const { MOODS } = require('../utils/constants');
const dateUtil = require('../utils/date');

const CATEGORY_NAMES = ['日常', '阅读', '课表', '运动', '才艺', '出行', '家务', '情绪', '里程碑', '其他'];
const CATEGORY_COLORS = {
  日常: '#FF8C42', 阅读: '#7ED9C3', 课表: '#8FC7F0', 运动: '#FF9EB5',
  才艺: '#B7A5F0', 出行: '#8FC7F0', 家务: '#7ED9C3', 情绪: '#FF9EB5',
  里程碑: '#E5702A', 其他: '#9A8F82',
};

/**
 * 聚合单周报告。
 * @param {number} start 本周一 0 点毫秒
 * @param {number} endExclusive 下周一 0 点毫秒（半开区间右端不包含）
 * @param {object} data { records, readingLogs, books } — 原始数组（已按 childId + 区间过滤好）
 * @returns {object} { rangeLabel, weekStart, weekEnd, activeDays, recordCount,
 *                    readingLogCount, readingMinutes, moodStats, topMoodKey, moodTotal,
 *                    categoryStats, books, bookCount, summary }
 */
function aggregateWeekly(start, endExclusive, data = {}) {
  const records = Array.isArray(data.records) ? data.records : [];
  const readingLogs = Array.isArray(data.readingLogs) ? data.readingLogs : [];
  const books = Array.isArray(data.books) ? data.books : [];

  const bookMap = {};
  books.forEach((b) => { if (b && b.uuid) bookMap[b.uuid] = b; });

  // §3.2 活跃天数 = 有记录 OR 有阅读打卡的不同日期数
  const activeDaysSet = new Set();
  records.forEach((r) => { if (r && r.eventDate != null) activeDaysSet.add(dateUtil.startOfDay(r.eventDate)); });
  readingLogs.forEach((l) => { if (l && l.readDate != null) activeDaysSet.add(dateUtil.startOfDay(l.readDate)); });
  const activeDays = activeDaysSet.size;

  // §4.2 心情分布：records.mood + readingLogs.mood 合并
  const moodCount = {};
  records.forEach((r) => { if (r && r.mood) moodCount[r.mood] = (moodCount[r.mood] || 0) + 1; });
  readingLogs.forEach((l) => { if (l && l.mood) moodCount[l.mood] = (moodCount[l.mood] || 0) + 1; });
  const moodTotal = Object.values(moodCount).reduce((s, v) => s + v, 0);
  const moodStats = MOODS
    .map((m) => ({
      key: m.key,
      emoji: m.emoji,
      label: m.label,
      count: moodCount[m.key] || 0,
      percent: moodTotal ? Math.round(((moodCount[m.key] || 0) / moodTotal) * 100) : 0,
    }))
    .filter((m) => m.count > 0)
    .sort((a, b) => b.count - a.count);
  const topMood = moodStats[0] || null;
  const topMoodKey = topMood ? topMood.key : null;

  // §3.4 分类分布（仅 daily_records，阅读打卡不参与 daily 分类）
  const catCount = {};
  records.forEach((r) => {
    const c = (r && r.category) || '其他';
    catCount[c] = (catCount[c] || 0) + 1;
  });
  const categoryStats = CATEGORY_NAMES
    .map((name) => ({ name, count: catCount[name] || 0, color: CATEGORY_COLORS[name] || '#FF8C42' }))
    .filter((c) => c.count > 0)
    .sort((a, b) => b.count - a.count);

  // §3.3 本周读过的绘本：reading_logs 在区间内的 bookUuid 去重 → 查 books 拿 title + 页/章进度
  const bookUuidSet = new Set();
  readingLogs.forEach((l) => { if (l && l.bookUuid) bookUuidSet.add(l.bookUuid); });
  const safeNum = (n) => Number.isFinite(Number(n)) ? Number(n) : 0;
  const booksThisWeek = Array.from(bookUuidSet).map((uuid) => {
    const b = bookMap[uuid];
    const logsOfBook = readingLogs.filter((l) => l && l.bookUuid === uuid);
    let pagesRead = 0;
    let chaptersRead = 0;
    let totalMinutes = 0;
    const totalPages = b && b.totalPages ? safeNum(b.totalPages) : null;
    const totalChapters = b && b.totalChapters ? safeNum(b.totalChapters) : null;
    logsOfBook.forEach((l) => {
      if (l.pageFrom != null && l.pageTo != null) {
        const seg = Math.max(0, safeNum(l.pageTo) - safeNum(l.pageFrom));
        pagesRead += totalPages != null ? Math.min(seg, totalPages) : seg;
      } else if (l.pageTo != null) {
        const v = safeNum(l.pageTo);
        pagesRead += totalPages != null ? Math.min(v, totalPages) : v;
      }
      if (l.chapterIndex != null) chaptersRead = Math.max(chaptersRead, safeNum(l.chapterIndex) + 1);
      if (l.durationMinutes != null) totalMinutes += Math.max(0, safeNum(l.durationMinutes));
    });
    if (totalPages != null) pagesRead = Math.min(pagesRead, totalPages);
    if (totalChapters != null) chaptersRead = Math.min(chaptersRead, totalChapters);
    const progressPercent = totalPages
      ? Math.min(100, Math.round((pagesRead / totalPages) * 100))
      : totalChapters
        ? Math.min(100, Math.round((chaptersRead / totalChapters) * 100))
        : null;
    return {
      bookUuid: uuid,
      title: (b && b.title) || '未命名绘本',
      author: (b && b.author) || null,
      pagesRead,
      chaptersRead,
      totalPages,
      totalChapters,
      progressPercent,
      durationMinutes: totalMinutes,
    };
  });

  // §3.7 阅读总时长
  let readingMinutes = 0;
  readingLogs.forEach((l) => { if (l && l.durationMinutes) readingMinutes += Math.max(0, safeNum(l.durationMinutes)); });
  records.forEach((r) => {
    if (r && r.durationMinutes && r.category === '阅读') readingMinutes += Math.max(0, safeNum(r.durationMinutes));
  });

  const recordCount = records.length;
  const readingLogCount = readingLogs.length;

  const DAY = 24 * 3600 * 1000;
  const rangeLabel = `${dateUtil.mdCn(start)} - ${dateUtil.mdCn(endExclusive - DAY)}`;

  // §3.8 一句话总结（模板式，V1 无 LLM）
  let summary;
  if (recordCount === 0 && readingLogCount === 0) {
    summary = '这一周还没有记录或阅读打卡，随手记下宝贝的一个小瞬间吧～';
  } else {
    const activePart = activeDays ? `有 ${activeDays} 天有记录或打卡` : '本周有记录和打卡';
    const moodPart = topMood ? `，出现最多的心情是${topMood.emoji}${topMood.label}` : '';
    const bookPart = booksThisWeek.length ? `，共读了 ${booksThisWeek.length} 本绘本` : '';
    const readingMinPart = readingMinutes ? `，累计阅读 ${readingMinutes} 分钟` : '';
    summary = `${rangeLabel}：${activePart}${moodPart}${bookPart}${readingMinPart}。`;
  }

  return {
    rangeLabel,
    weekStart: start,
    weekEnd: endExclusive,
    activeDays,
    recordCount,
    readingLogCount,
    readingMinutes,
    moodStats,
    topMood,
    topMoodKey,
    moodTotal,
    categoryStats,
    books: booksThisWeek,
    bookCount: booksThisWeek.length,
    summary,
  };
}

module.exports = {
  aggregateWeekly,
};
