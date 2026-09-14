// tests/utils/db.test.js —— 共享数据读取收口后的本地过滤/排序逻辑单测
// 重点验证：listSharedData 走 childShare.listChildData，前端只做本地过滤/排序；
// 未登录 / 无当前孩子时不发起云调用直接返回空。
const db = require('../../utils/db');

function mockItems(items) {
  wx.cloud.callFunction.mockImplementation(async ({ data }) => {
    if (data.action === 'listChildData') return { result: { ok: true, items } };
    return { result: { ok: true } };
  });
}

describe('db 共享数据读取：登录/孩子上下文守卫', () => {
  test('未登录时 records.listByRange 直接返回空且不发起云调用', async () => {
    __setActiveChild('c1'); // 有孩子但未登录
    const out = await db.records.listByRange(0, Date.now());
    expect(out).toEqual([]);
    expect(wx.cloud.callFunction).not.toHaveBeenCalled();
  });

  test('无当前孩子时 books.listAll 直接返回空且不发起云调用', async () => {
    __setUser({ ownerId: 'o1', openid: 'p1' }); // 已登录但没有选中孩子
    const out = await db.books.listAll();
    expect(out).toEqual([]);
    expect(wx.cloud.callFunction).not.toHaveBeenCalled();
  });
});

describe('db.records.listByRange 本地过滤 + 倒序', () => {
  beforeEach(() => {
    __setUser({ ownerId: 'o1', openid: 'p1' });
    __setActiveChild('c1');
  });

  test('按 [start, end) 半开区间过滤并按 eventDate 倒序', async () => {
    mockItems([
      { uuid: 'r1', eventDate: 100 },
      { uuid: 'r2', eventDate: 200 },
      { uuid: 'r3', eventDate: 300 }, // 恰好等于 end，应被排除
      { uuid: 'r4', eventDate: 50 },  // 小于 start，应被排除
    ]);
    const out = await db.records.listByRange(100, 300);
    expect(out.map((r) => r.uuid)).toEqual(['r2', 'r1']); // 倒序，300 被排除
  });

  test('通过 listChildData 且带正确 collection/childId 入参', async () => {
    mockItems([]);
    await db.records.listByRange(0, 999);
    expect(wx.cloud.callFunction).toHaveBeenCalledWith({
      name: 'childShare',
      data: { action: 'listChildData', collection: 'daily_records', childId: 'c1' },
    });
  });

  test('云函数返回 ok:false 时回退空数组', async () => {
    wx.cloud.callFunction.mockImplementation(async () => ({ result: { ok: false, error: 'x' } }));
    const out = await db.records.listByRange(0, 999);
    expect(out).toEqual([]);
  });
});

describe('db.records.listAll cap 截断', () => {
  test('按 eventDate 倒序并截断到 cap 条', async () => {
    __setUser({ ownerId: 'o1', openid: 'p1' });
    __setActiveChild('c1');
    mockItems([
      { uuid: 'a', eventDate: 1 },
      { uuid: 'b', eventDate: 5 },
      { uuid: 'c', eventDate: 3 },
    ]);
    const out = await db.records.listAll(2);
    expect(out.map((r) => r.uuid)).toEqual(['b', 'c']); // 倒序取前 2
  });
});

describe('db.books.listByStatus 过滤 + updatedAt 倒序', () => {
  test('只保留匹配状态并倒序', async () => {
    __setUser({ ownerId: 'o1', openid: 'p1' });
    __setActiveChild('c1');
    mockItems([
      { uuid: 'b1', status: 'reading', updatedAt: 10 },
      { uuid: 'b2', status: 'done', updatedAt: 20 },
      { uuid: 'b3', status: 'reading', updatedAt: 30 },
    ]);
    const out = await db.books.listByStatus('reading');
    expect(out.map((b) => b.uuid)).toEqual(['b3', 'b1']);
  });
});
