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
  // 先取书的 totalPages/totalChapters，做 pageTo/chapterIndex 上限裁剪
  // （失败兜底：查不到书时不裁剪，防止脏数据阻断打卡）
  let bookMeta = null;
  try { bookMeta = await db.books.getByUuid(bookUuid); } catch (e) { bookMeta = null; }
  const totalPages = bookMeta && bookMeta.totalPages ? Number(bookMeta.totalPages) : null;
  const totalChapters = bookMeta && bookMeta.totalChapters ? Number(bookMeta.totalChapters) : null;

  const clamp = (v, max) => {
    if (v == null) return v;
    const n = Number(v);
    if (!Number.isFinite(n)) return v;
    if (n < 0) return 0;
    if (max != null && n > max) return max;
    return n;
  };

  const pageFrom = data.pageFrom != null && data.pageFrom !== '' ? clamp(Number(data.pageFrom), totalPages) : null;
  const pageTo = data.pageTo != null && data.pageTo !== '' ? clamp(Number(data.pageTo), totalPages) : null;
  const chapterIndex = data.chapterIndex != null && data.chapterIndex !== '' ? clamp(Number(data.chapterIndex), totalChapters != null ? totalChapters - 1 : null) : null;

  const rawReadDate =
    data.readDate != null ? data.readDate : dateUtil.startOfDay(new Date());
  const todayEnd = dateUtil.startOfNextDay(new Date());
  const readDate = rawReadDate >= todayEnd ? dateUtil.startOfDay(new Date()) : rawReadDate;
  const log = {
    bookUuid,
    readDate,
    chapter: data.chapter || null,
    chapterIndex,
    pageFrom,
    pageTo,
    durationMinutes:
      data.durationMinutes != null && data.durationMinutes !== ''
        ? Math.max(0, Number(data.durationMinutes) || 0)
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

    const totalPages = book.totalPages ? Number(book.totalPages) : null;
    const totalChapters = book.totalChapters ? Number(book.totalChapters) : null;
    const finalMaxPage = totalPages != null ? Math.min(maxPage, totalPages) : maxPage;
    const finalMaxChapter = totalChapters != null ? Math.min(maxChapter, totalChapters - 1) : maxChapter;

    const prevStatus = book.status || 'want';
    let status = prevStatus !== 'want' ? prevStatus : 'reading';
    if (totalPages && finalMaxPage >= totalPages) status = 'done';
    if (totalChapters && finalMaxChapter >= totalChapters - 1) status = 'done';

    const patch = { status };
    if (lastReadDate) patch.lastReadDate = lastReadDate;
    if (finalMaxPage) patch.currentPage = finalMaxPage;
    if (finalMaxChapter >= 0) patch.currentChapter = finalMaxChapter;

    await db.books.update(bookUuid, patch);

    // V1 P1：status 首次由 非 done 跃迁为 done 时，
    // 同步 book_library.readFinishCount +1（若该书有 libraryUuid）
    // 注意幂等：只有 prevStatus !== 'done' 且 status === 'done' 时才触发。
    if (prevStatus !== 'done' && status === 'done' && book.libraryUuid) {
      try {
        if (wx.cloud && wx.cloud.callFunction) {
          const delta = 1;
          if (Math.abs(delta) <= 10) {
            await wx.cloud.callFunction({
              name: 'bookLibraryInc',
              data: { bookLibraryUuid: book.libraryUuid, delta, field: 'readFinishCount' },
            });
          }
        }
      } catch (err) {
        console.warn('[reading-service] bookLibraryInc(readFinishCount) 失败，跳过', err);
      }
    }
  } catch (err) {
    console.warn('[reading-service] 同步书籍进度失败（不影响打卡）', err);
  }
}

module.exports = {
  addReadingLog,
  getBookLogs,
};
