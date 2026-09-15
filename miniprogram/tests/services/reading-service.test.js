// tests/services/reading-service.test.js —— 打卡派生 / 「读完这册·读完整本」单测
// 重点覆盖 v3 需求：
//   - markDone=true（读完整本 / 读完这册 / 章节读到末章）→ 书籍 status 直接置 done；
//   - 幂等：已 done 的书再次 markDone 不会重复触发 book_library.readFinishCount +1。
// db 通过 jest.mock 整体桩化，隔离云调用；wx.cloud.callFunction 由 tests/setup.js 提供全局桩。
jest.mock('../../utils/db');

const db = require('../../utils/db');
const readingService = require('../../services/reading-service');

// 组装 db 桩：给定「书」与「历史打卡」，捕获 books.update 的 patch
function mockDb({ book, logs = [] }) {
  db.readingLogs = {
    create: jest.fn(async (log) => ({ ok: true, uuid: 'log1', ...log })),
    listByBook: jest.fn(async () => logs),
  };
  db.books = {
    getByUuid: jest.fn(async () => book),
    update: jest.fn(async () => ({ ok: true })),
  };
}

describe('reading-service.addReadingLog markDone → 强制读完', () => {
  test('绘本无页/章元信息：markDone=true 仍把 status 置 done', async () => {
    mockDb({ book: { uuid: 'b1', status: 'reading' }, logs: [] });
    await readingService.addReadingLog('c1', 'b1', { markDone: true, note: '读完整本' });
    expect(db.books.update).toHaveBeenCalledTimes(1);
    const [uuid, patch] = db.books.update.mock.calls[0];
    expect(uuid).toBe('b1');
    expect(patch.status).toBe('done');
  });

  test('不传 markDone 时，绘本(无 totalPages)只停留在 reading', async () => {
    mockDb({ book: { uuid: 'b1', status: 'want' }, logs: [] });
    await readingService.addReadingLog('c1', 'b1', { note: '读了一点' });
    const [, patch] = db.books.update.mock.calls[0];
    expect(patch.status).toBe('reading');
  });

  test('首次由非 done → done 且有 libraryUuid：触发 readFinishCount +1', async () => {
    mockDb({ book: { uuid: 'b1', status: 'reading', libraryUuid: 'lib1' }, logs: [] });
    await readingService.addReadingLog('c1', 'b1', { markDone: true });
    const incCalls = wx.cloud.callFunction.mock.calls.filter((c) => c[0] && c[0].name === 'bookLibraryInc');
    expect(incCalls).toHaveLength(1);
    expect(incCalls[0][0].data).toMatchObject({ bookLibraryUuid: 'lib1', delta: 1, field: 'readFinishCount' });
  });

  test('幂等：已 done 的书再次 markDone → 不重复触发 readFinishCount', async () => {
    mockDb({ book: { uuid: 'b1', status: 'done', libraryUuid: 'lib1' }, logs: [] });
    await readingService.addReadingLog('c1', 'b1', { markDone: true });
    // status 仍写 done，但 prevStatus 已是 done → 不再 +1
    const [, patch] = db.books.update.mock.calls[0];
    expect(patch.status).toBe('done');
    const incCalls = wx.cloud.callFunction.mock.calls.filter((c) => c[0] && c[0].name === 'bookLibraryInc');
    expect(incCalls).toHaveLength(0);
  });
});

describe('reading-service.addReadingLog 页码派生（回归）', () => {
  test('读到最后一页自动置 done', async () => {
    mockDb({
      book: { uuid: 'b1', status: 'reading', totalPages: 100 },
      logs: [{ pageTo: 100, readDate: Date.now() }],
    });
    await readingService.addReadingLog('c1', 'b1', { pageFrom: 90, pageTo: 100 });
    const [, patch] = db.books.update.mock.calls[0];
    expect(patch.status).toBe('done');
    expect(patch.currentPage).toBe(100);
  });
});
