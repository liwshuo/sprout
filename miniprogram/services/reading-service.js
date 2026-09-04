// services/reading-service.js —— 阅读打卡业务服务
// 承载「打卡写入 + 书籍状态跃迁 + 进度派生」的聚合逻辑，页面只管收集表单。
// 设计对齐架构方案：ReadingLogs 为单一真相源，书籍进度/状态由打卡派生。

const db = require('../utils/db');
const dateUtil = require('../utils/date');

/**
 * 新增一条阅读打卡，并同步派生书籍状态/进度。
 * @param {string} childId 目标孩子 uuid（db 层已按 activeChild 归属过滤，此处作语义标识）
 * @param {string} bookUuid 书籍 uuid
 * @param {object} data { readDate?, chapter?, chapterIndex?, pageFrom?, pageTo?, durationMinutes?, mood?, note? }
 * @returns {Promise} 创建结果
 */
async function addReadingLog(childId, bookUuid, data = {}) {
  if (!bookUuid) throw new Error('缺少 bookUuid');
  const readDate =
    data.readDate != null ? data.readDate : dateUtil.startOfDay(new Date());
  const log = {
    bookUuid,
    readDate,
    chapter: data.chapter || null,
    chapterIndex: data.chapterIndex != null ? Number(data.chapterIndex) : null,
    pageFrom: data.pageFrom != null && data.pageFrom !== '' ? Number(data.pageFrom) : null,
    pageTo: data.pageTo != null && data.pageTo !== '' ? Number(data.pageTo) : null,
    durationMinutes:
      data.durationMinutes != null && data.durationMinutes !== ''
        ? Number(data.durationMinutes)
        : null,
    mood: data.mood || null,
    note: data.note || null,
    source: 'manual',
  };
  const res = await db.readingLogs.create(log);
  // 派生更新书籍状态与进度快照（失败不阻断打卡本身）
  await _syncBookProgress(bookUuid);
  return res;
}

/**
 * 查询某本书的全部打卡历史（按 readDate 倒序）。
 * @param {string} bookUuid 书籍 uuid
 * @returns {Promise<Array>}
 */
function getBookLogs(bookUuid) {
  return db.readingLogs.listByBook(bookUuid);
}

/**
 * 由打卡历史派生书籍状态与进度：
 *  - 有任意打卡 → 至少「在读(reading)」（want 自动跃迁）
 *  - 读到最后一页/最后一章 → 「读完(done)」
 *  - 回写 currentPage / currentChapter / lastReadDate 进度快照
 */
async function _syncBookProgress(bookUuid) {
  try {
    const [book, logs] = await Promise.all([
      db.books.getByUuid(bookUuid),
      db.readingLogs.listByBook(bookUuid),
    ]);
    if (!book) return;

    const nums = (arr) => arr.map((n) => Number(n) || 0);
    const maxPage = Math.max(0, ...nums((logs || []).map((l) => l.pageTo)));
    const maxChapter = Math.max(0, ...nums((logs || []).map((l) => l.chapterIndex)));
    const lastReadDate = Math.max(0, ...nums((logs || []).map((l) => l.readDate)));

    let status = book.status && book.status !== 'want' ? book.status : 'reading';
    if (book.totalPages && maxPage >= book.totalPages) status = 'done';
    if (book.totalChapters && maxChapter >= book.totalChapters) status = 'done';

    const patch = { status };
    if (lastReadDate) patch.lastReadDate = lastReadDate;
    if (maxPage) patch.currentPage = maxPage;
    if (maxChapter) patch.currentChapter = maxChapter;

    await db.books.update(bookUuid, patch);
  } catch (err) {
    console.warn('[reading-service] 同步书籍进度失败（不影响打卡）', err);
  }
}

module.exports = {
  addReadingLog,
  getBookLogs,
};
