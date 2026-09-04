// services/calendar-service.js —— 日历三源聚合服务
// 把「成长记录 daily_records」「课表 schedule_items（周展开）」「阅读打卡 reading_logs」
// 三个上游数据源，聚合为统一的 CalendarEvent[] 结构，供日历首页打点 / 事件卡片消费。
//
// CalendarEvent = {
//   date,       // 'YYYY-MM-DD'（归属日）
//   ts,         // 当天 0 点时间戳（排序/定位用）
//   type,       // 'record' | 'schedule' | 'reading'
//   title,      // 主标题
//   subtitle,   // 副标题（备注 / 地点 / 页码等）
//   time,       // 时间段（课表专用，如 '16:00-17:00'）
//   color,      // 事件主题色（= 类型色，驱动圆点与卡片色条）
//   typeLabel,  // 类型中文名（成长记录 / 课外班 / 阅读打卡）
//   sourceId,   // 上游文档 uuid
//   raw,        // 原始文档
//   ...extras   // record: category/categoryColor/mood；schedule: scheduleType
// }
//
// 数据完整性：内部所有列表读取一律走 db.*（listAllPaged），破解小程序端单次查询 20 条上限。

const db = require('../utils/db');
const dateUtil = require('../utils/date');
const {
  eventTypeColor,
  categoryColor,
  moodEmoji,
  EVENT_TYPE_LABELS,
} = require('../utils/constants');

// 圆点固定顺序：成长记录(橙) → 课外班(蓝) → 阅读打卡(绿)，最多 3 个
const DOT_ORDER = ['record', 'schedule', 'reading'];

/** daily_records → CalendarEvent */
function _toRecordEvent(r) {
  return {
    date: dateUtil.ymd(r.eventDate),
    ts: dateUtil.startOfDay(r.eventDate),
    type: 'record',
    title: r.title || '成长记录',
    subtitle: r.note || '',
    time: '',
    color: eventTypeColor('record'),
    typeLabel: EVENT_TYPE_LABELS.record,
    category: r.category || '',
    categoryColor: categoryColor(r.category),
    mood: moodEmoji(r.mood),
    sourceId: r.uuid,
    raw: r,
  };
}

/** expandWeeklySchedule 展开项 → CalendarEvent */
function _toScheduleEvent(x) {
  const it = x.item || {};
  const time =
    it.startTime && it.endTime
      ? `${it.startTime}-${it.endTime}`
      : it.startTime || '';
  return {
    date: x.date,
    ts: x.ts,
    type: 'schedule',
    title: it.courseName || '课程',
    subtitle: it.location || '',
    time,
    color: eventTypeColor('schedule'),
    typeLabel: it.type === 'school' ? '校内课' : EVENT_TYPE_LABELS.schedule,
    scheduleType: it.type || 'extra',
    sourceId: it.uuid,
    raw: it,
  };
}

/** reading_logs → CalendarEvent（第三源；title 取书名） */
function _toReadingEvent(log, bookTitleMap) {
  const bookTitle = bookTitleMap[log.bookUuid] || '阅读打卡';
  let subtitle = '';
  if (log.pageFrom != null || log.pageTo != null) {
    const from = log.pageFrom != null ? log.pageFrom : '';
    const to = log.pageTo != null ? `-${log.pageTo}` : '';
    subtitle = `第 ${from}${to} 页`;
  } else if (log.chapter) {
    subtitle = log.chapter;
  } else if (log.note) {
    subtitle = log.note;
  }
  return {
    date: dateUtil.ymd(log.readDate),
    ts: dateUtil.startOfDay(log.readDate),
    type: 'reading',
    title: bookTitle,
    subtitle,
    time: '',
    color: eventTypeColor('reading'),
    typeLabel: EVENT_TYPE_LABELS.reading,
    mood: moodEmoji(log.mood),
    sourceId: log.uuid,
    raw: log,
  };
}

/**
 * 拉取「当月」三源事件并聚合为 CalendarEvent[]。
 * 三源并发拉取；课表按 weekly 规则展开到当月每一天。
 *
 * @param {string} childId 目标孩子 uuid（db 层已按当前 activeChild 归属过滤，此处仅作语义标识/预留多孩子扩展）
 * @param {number} year 年，如 2026
 * @param {number} month 月（0-based）
 * @returns {Promise<CalendarEvent[]>} 已按 ts / time 升序排列
 */
async function fetchMonthEvents(childId, year, month) {
  const [start, end] = dateUtil.monthRange(year, month);

  // 三源 + 书名映射并发拉取（均走 listAllPaged 破 20 条上限）
  const [records, scheduleItems, readingLogs, books] = await Promise.all([
    db.records.listByRange(start, end),
    db.scheduleItems.listAll(),
    db.readingLogs.listByRange(start, end),
    db.books.listAll(),
  ]);

  const bookTitleMap = {};
  (books || []).forEach((b) => {
    bookTitleMap[b.uuid] = b.title;
  });

  const events = [];
  // 源①：成长记录
  (records || []).forEach((r) => events.push(_toRecordEvent(r)));
  // 源②：课表（周展开到当月）
  dateUtil
    .expandWeeklySchedule(scheduleItems, year, month)
    .forEach((x) => events.push(_toScheduleEvent(x)));
  // 源③：阅读打卡
  (readingLogs || []).forEach((l) => events.push(_toReadingEvent(l, bookTitleMap)));

  // 同日内：先按类型排序（记录→课表→阅读），课表再按开始时间
  events.sort((a, b) => {
    if (a.ts !== b.ts) return a.ts - b.ts;
    const oa = DOT_ORDER.indexOf(a.type);
    const ob = DOT_ORDER.indexOf(b.type);
    if (oa !== ob) return oa - ob;
    return (a.time || '').localeCompare(b.time || '');
  });

  return events;
}

/**
 * 把 CalendarEvent[] 按 date 分组。
 * @returns {Object} { 'YYYY-MM-DD': CalendarEvent[] }
 */
function groupByDay(events) {
  const map = {};
  (events || []).forEach((e) => {
    (map[e.date] = map[e.date] || []).push(e);
  });
  return map;
}

/**
 * 计算某天日历圆点颜色（最多 3 个，按 record→schedule→reading 去重）。
 * @param {CalendarEvent[]} dayEvents 当天事件列表
 * @returns {string[]} 颜色数组
 */
function dotsForDay(dayEvents) {
  const types = new Set((dayEvents || []).map((e) => e.type));
  return DOT_ORDER.filter((t) => types.has(t))
    .map((t) => eventTypeColor(t))
    .slice(0, 3);
}

module.exports = {
  fetchMonthEvents,
  groupByDay,
  dotsForDay,
};
