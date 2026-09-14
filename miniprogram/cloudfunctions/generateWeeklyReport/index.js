// cloudfunctions/generateWeeklyReport/index.js —— 生成周度周报（纯统计聚合，V1 无 LLM）
//
// 触发方式：
//   1. 定时触发器：每周日 20:00 CST（见 config.json "0 0 20 * * 0"）
//      —— Cron 触发时，该函数会遍历当前环境**所有用户**（无 ownerId 过滤），
//         取每个用户 ownerId 下的每个 childId，分别生成本周周报
//   2. 手动触发（前端/测试事件）：传 { forceChildId, forceWeekStart?, forceOwnerId? }
//      —— 只对指定 (ownerId, childId) 生成本周/指定周报告，返回生成了几份
//
// 幂等保证：
//   按 (ownerId, childId, weekStart) 先查 weekly_reports
//   → 存在则 update（刷新所有统计字段 + updatedAt）
//   → 不存在则 create
//   因此 Cron 或手动重复跑不会生成双份。
//
// 业务口径 SSOT：docs/AGGREGATION_RULES.md §3 周报聚合
const cloud = require('wx-server-sdk');

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const db = cloud.database();
const _ = db.command;

const DAY = 24 * 3600 * 1000;
const MOOD_KEYS = ['happy', 'calm', 'excited', 'tired', 'upset'];
const CATEGORY_NAMES = ['日常', '阅读', '课表', '运动', '才艺', '出行', '家务', '情绪', '里程碑', '其他'];

function startOfDay(d) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x.getTime();
}
function mdCn(d) {
  const x = new Date(d);
  return `${x.getMonth() + 1}月${x.getDate()}日`;
}

/** 本周周一 0 点（weekStart），对齐小程序端 report.js _weekRange */
function thisWeekStart(refDate = new Date()) {
  const today = startOfDay(refDate);
  const dayIdx = (new Date(today).getDay() + 6) % 7; // 周一=0
  return today - dayIdx * DAY;
}

/**
 * 计算某周起止（半开区间 [start, endExclusive)）
 * @param {number} weekStartMs 本周一 0 点
 * @returns [start, endExclusive]
 */
function weekRange(weekStartMs) {
  return [weekStartMs, weekStartMs + 7 * DAY];
}

/** 分页全量拉，破除 CloudBase 单次 20 条上限（小程序端 20，云函数端 100，统一用循环兜底） */
async function listAll(col, where, orderBy = null, cap = 500) {
  const PAGE = 100;
  const out = [];
  let skip = 0;
  while (skip < cap) {
    let q = db.collection(col).where(where);
    if (orderBy) q = q.orderBy(orderBy[0], orderBy[1] || 'asc');
    // eslint-disable-next-line no-await-in-loop
    const { data } = await q.skip(skip).limit(PAGE).get();
    const batch = data || [];
    out.push(...batch);
    if (batch.length < PAGE) break;
    skip += PAGE;
  }
  if (out.length >= cap) {
    console.warn(`[generateWeeklyReport] ${col} 达到 cap=${cap}，可能有更多数据未拉取`);
  }
  return out;
}

/** 分页遍历所有用户（Cron 触发时），支持 _nextCursor 做 100/批 chunk */
async function listAllOwners(skip = 0, limit = 100) {
  const { data } = await db
    .collection('users')
    .where({ isDeleted: _.neq(true) })
    .orderBy('createdAt', 'asc')
    .skip(skip)
    .limit(limit)
    .get();
  return data || [];
}

/** 某 ownerId 下的全部孩子 */
async function listChildrenOf(ownerId) {
  return listAll(
    'children',
    { ownerId, isDeleted: _.neq(true) },
    ['sortOrder', 'asc'],
    20
  );
}

/** 生成 uuid（与 utils/db.js genUuid 对齐） */
function genUuid() {
  const s = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).slice(1);
  return `${s()}${s()}-${s()}-${s()}-${s()}-${s()}${s()}${s()}`;
}

/**
 * 纯函数：聚合一周报告。
 * 与小程序端 services/report-service.js 保持**字节级一致**（两端代码逻辑同步维护）。
 * SSOT：AGGREGATION_RULES.md §3.1 ~ §3.6
 * @param {number} start 周一起点毫秒
 * @param {number} endExclusive 下周一 0 点毫秒（半开区间右端不包含）
 * @param {Array} records daily_records 该 childId 下 start~endExclusive 的记录
 * @param {Array} readingLogs reading_logs 该 childId 下 start~endExclusive 的打卡
 * @param {Array} books 该 childId 下**全部**书籍（用于 readingLog.bookUuid 查 title）
 * @returns {object} 可直接写入 weekly_reports 的 payload（不含 ownerId/childId/weekStart/uuid 等通用字段）
 */
function aggregateWeekly(start, endExclusive, records, readingLogs, books) {
  const bookMap = {};
  (books || []).forEach((b) => { if (b && b.uuid) bookMap[b.uuid] = b; });

  // §3.2 活跃天数 = 有记录 OR 有阅读打卡的不同日期数
  const activeDaysSet = new Set();
  (records || []).forEach((r) => activeDaysSet.add(startOfDay(r.eventDate)));
  (readingLogs || []).forEach((l) => activeDaysSet.add(startOfDay(l.readDate)));
  const activeDays = activeDaysSet.size;

  // §4.2 心情分布：records.mood + readingLogs.mood 合并
  const moodCount = {};
  (records || []).forEach((r) => { if (r && r.mood) moodCount[r.mood] = (moodCount[r.mood] || 0) + 1; });
  (readingLogs || []).forEach((l) => { if (l && l.mood) moodCount[l.mood] = (moodCount[l.mood] || 0) + 1; });
  const moodTotal = Object.values(moodCount).reduce((s, v) => s + v, 0);
  const moodStats = MOOD_KEYS
    .map((k) => ({ key: k, count: moodCount[k] || 0 }))
    .filter((m) => m.count > 0)
    .sort((a, b) => b.count - a.count);
  const topMoodKey = moodStats[0] ? moodStats[0].key : null;

  // §3.4 分类分布（仅 daily_records，阅读打卡不参与 daily 分类）
  const catCount = {};
  (records || []).forEach((r) => {
    const c = (r && r.category) || '其他';
    catCount[c] = (catCount[c] || 0) + 1;
  });
  const categoryStats = CATEGORY_NAMES
    .map((name) => ({ name, count: catCount[name] || 0 }))
    .filter((c) => c.count > 0)
    .sort((a, b) => b.count - a.count);

  // §3.3 本周读过的绘本：reading_logs 在区间内的 bookUuid 去重 → 查 books 拿 title + 总页/章进度
  const bookUuidSet = new Set();
  (readingLogs || []).forEach((l) => { if (l && l.bookUuid) bookUuidSet.add(l.bookUuid); });
  const safeNum = (n) => Number.isFinite(Number(n)) ? Number(n) : 0;
  const booksThisWeek = Array.from(bookUuidSet).map((uuid) => {
    const b = bookMap[uuid];
    // 本周内对这本书的所有 log → 累计页/章
    const logsOfBook = (readingLogs || []).filter((l) => l && l.bookUuid === uuid);
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

  // §3.7 阅读总时长（打卡 + 记录内 durationMinutes）
  let readingMinutes = 0;
  (readingLogs || []).forEach((l) => { if (l && l.durationMinutes) readingMinutes += Math.max(0, safeNum(l.durationMinutes)); });
  (records || []).forEach((r) => {
    if (r && r.durationMinutes && r.category === '阅读') readingMinutes += Math.max(0, safeNum(r.durationMinutes));
  });

  // §3.5 周总览：活跃天 / 记录数 / 打卡数
  const recordCount = (records || []).length;
  const readingLogCount = (readingLogs || []).length;

  // §3.8 一句话总结（模板式，无 LLM）
  const weekStartLabel = mdCn(start);
  const weekEndLabel = mdCn(endExclusive - DAY);
  const activePart = activeDays ? `有 ${activeDays} 天有记录或打卡` : '没有任何记录或阅读打卡';
  const moodPart = topMoodKey ? `，出现最多的心情是「${topMoodKey}」` : '';
  const bookPart = booksThisWeek.length ? `，共读了 ${booksThisWeek.length} 本绘本` : '';
  const readingMinPart = readingMinutes ? `，累计阅读 ${readingMinutes} 分钟` : '';
  const summary = `${weekStartLabel} - ${weekEndLabel}：${activePart}${moodPart}${bookPart}${readingMinPart}。`;

  const rangeLabel = `${weekStartLabel} - ${weekEndLabel}`;

  return {
    rangeLabel,
    weekStart: start,
    weekEnd: endExclusive,
    activeDays,
    recordCount,
    readingLogCount,
    readingMinutes,
    moodStats,
    topMoodKey,
    moodTotal,
    categoryStats,
    books: booksThisWeek,
    bookCount: booksThisWeek.length,
    summary,
  };
}

/**
 * 给某个 (ownerId, childId, weekStart) 生/刷新一份周报。
 * 执行：查询数据 → aggregateWeekly → 按 (ownerId, childId, weekStart) UPSERT。
 * @returns {boolean} true=created, false=updated
 */
async function upsertFor(ownerId, childId, weekStartMs) {
  if (!ownerId || !childId) throw new Error('missing ownerId or childId');
  const [start, endExclusive] = weekRange(weekStartMs);

  // 并发查 3 个集合
  const [records, readingLogs, books, existing] = await Promise.all([
    listAll('daily_records', {
      ownerId, childId,
      isDeleted: _.neq(true),
      eventDate: _.gte(start).and(_.lt(endExclusive)),
    }, ['eventDate', 'desc'], 500),
    listAll('reading_logs', {
      ownerId, childId,
      isDeleted: _.neq(true),
      readDate: _.gte(start).and(_.lt(endExclusive)),
    }, ['readDate', 'desc'], 500),
    listAll('books', { ownerId, childId, isDeleted: _.neq(true) }, ['updatedAt', 'desc'], 500),
    // 查是否已有周报（按 unique 三元组）
    (async () => {
      const { data } = await db.collection('weekly_reports')
        .where({ ownerId, childId, weekStart: start, isDeleted: _.neq(true) })
        .limit(1)
        .get();
      return data && data[0];
    })(),
  ]);

  const aggregated = aggregateWeekly(start, endExclusive, records, readingLogs, books);
  const now = Date.now();

  if (existing) {
    await db.collection('weekly_reports').doc(existing._id).update({
      data: Object.assign({}, aggregated, { updatedAt: now }),
    });
    return { action: 'updated', uuid: existing.uuid, weekStart: start, childId };
  }
  const doc = Object.assign({}, aggregated, {
    uuid: genUuid(),
    ownerId,
    childId,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  });
  await db.collection('weekly_reports').add({ data: doc });
  return { action: 'created', uuid: doc.uuid, weekStart: start, childId };
}

exports.main = async (event = {}) => {
  const { forceOwnerId, forceChildId, forceWeekStart, _nextCursor = 0, _chunkSize = 100 } = event;
  const results = [];
  let owners = [];

  // 手动模式：只处理指定 (ownerId, childId)
  if (forceChildId) {
    const resolvedOwnerId = forceOwnerId || (() => {
      const { OPENID, UNIONID } = cloud.getWXContext && cloud.getWXContext() || {};
      return UNIONID || OPENID || null;
    })();
    if (!resolvedOwnerId) {
      return { ok: false, error: '手动触发必须传 forceOwnerId，或由登录态触发' };
    }
    const ws = forceWeekStart || thisWeekStart();
    const r = await upsertFor(resolvedOwnerId, forceChildId, ws);
    results.push(r);
    return { ok: true, mode: 'manual', results };
  }

  // Cron 模式：按 chunk（默认 100）分批，最后一批通过 callFunction 自调用处理剩余用户
  owners = await listAllOwners(_nextCursor, _chunkSize);
  if (!owners.length && _nextCursor === 0) {
    return { ok: true, mode: 'cron', ownersProcessed: 0, reports: 0, results: [] };
  }

  const ws = forceWeekStart || thisWeekStart();
  for (let i = 0; i < owners.length; i++) {
    const owner = owners[i];
    const ownerId = owner.ownerId;
    if (!ownerId) continue;
    // eslint-disable-next-line no-await-in-loop
    const children = await listChildrenOf(ownerId);
    for (let j = 0; j < children.length; j++) {
      const ch = children[j];
      if (!ch || !ch.uuid) continue;
      // eslint-disable-next-line no-await-in-loop
      const r = await upsertFor(ownerId, ch.uuid, ws);
      results.push(r);
    }
  }

  const nextCursor = _nextCursor + owners.length;
  const hasMore = owners.length >= _chunkSize;
  if (hasMore) {
    try {
      await cloud.callFunction({
        name: 'generateWeeklyReport',
        data: { _nextCursor: nextCursor, _chunkSize, forceWeekStart: ws },
      });
    } catch (err) {
      console.warn('[generateWeeklyReport] 自调用下一批失败，需手动补跑', err);
    }
  }

  return {
    ok: true,
    mode: 'cron',
    ownersProcessedFromThisChunk: owners.length,
    ownersProcessedCumulative: nextCursor,
    hasMore,
    nextCursor: hasMore ? nextCursor : null,
    reportsInThisChunk: results.length,
    results,
  };
};
