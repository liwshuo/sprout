// tests/services/calendar-service.test.js —— 日历四源聚合单测
// 通过 wx.cloud.callFunction mock 驱动底层 db.* 与 todo.listAll，
// 验证聚合、待办 dueDate 过滤、排序、分组与圆点计算。
const calendar = require('../../services/calendar-service');
const { EVENT_TYPE_COLORS } = require('../../utils/constants');

// 按 action / collection 路由的云调用桩
function routeCloud({ records = [], scheduleItems = [], todos = [], readingLogs = [], books = [] }) {
  wx.cloud.callFunction.mockImplementation(async ({ data }) => {
    if (data.action === 'listTodos') return { result: { ok: true, todos } };
    if (data.action === 'listChildData') {
      const map = {
        daily_records: records,
        schedule_items: scheduleItems,
        reading_logs: readingLogs,
        books,
      };
      return { result: { ok: true, items: map[data.collection] || [] } };
    }
    return { result: { ok: true } };
  });
}

describe('calendar.fetchMonthEvents 聚合', () => {
  beforeEach(() => {
    __setUser({ ownerId: 'o1', openid: 'p1' });
    __setActiveChild('c1');
  });

  test('childId 为空直接返回空', async () => {
    const out = await calendar.fetchMonthEvents('', 2026, 8);
    expect(out).toEqual([]);
  });

  test('四源聚合出正确类型与数量（2026 年 9 月）', async () => {
    routeCloud({
      records: [{ uuid: 'r1', eventDate: new Date(2026, 8, 10).getTime(), title: '第一次骑车' }],
      scheduleItems: [{ uuid: 's1', weekday: 1, title: '钢琴', startTime: '16:00', endTime: '17:00' }],
      todos: [
        { uuid: 't1', title: '数学作业', dueDate: '2026-09-14', done: false },
        { uuid: 't2', title: '无截止', dueDate: '', done: false },        // 无 dueDate → 排除
        { uuid: 't3', title: '越界', dueDate: '2026-10-02', done: false }, // 越界 → 排除
      ],
      readingLogs: [{ uuid: 'l1', readDate: new Date(2026, 8, 12).getTime(), bookUuid: 'b1' }],
      books: [{ uuid: 'b1', title: '好饿的毛毛虫' }],
    });

    const events = await calendar.fetchMonthEvents('c1', 2026, 8);
    const byType = events.reduce((acc, e) => {
      acc[e.type] = (acc[e.type] || 0) + 1;
      return acc;
    }, {});

    expect(byType.record).toBe(1);
    expect(byType.reading).toBe(1);
    expect(byType.todo).toBe(1); // 仅 t1 命中
    expect(byType.schedule).toBe(4); // 9 月 4 个周一
    // 只保留命中的待办
    const todoTitles = events.filter((e) => e.type === 'todo').map((e) => e.title);
    expect(todoTitles).toEqual(['数学作业']);
  });

  test('事件按 ts 升序、同日按 类型顺序 排列', async () => {
    routeCloud({
      // 同一天（9/14）既有记录又有待办，记录应排在待办前
      records: [{ uuid: 'r1', eventDate: new Date(2026, 8, 14).getTime(), title: 'R' }],
      todos: [{ uuid: 't1', title: 'T', dueDate: '2026-09-14', done: false }],
    });
    const events = await calendar.fetchMonthEvents('c1', 2026, 8);
    const sameDay = events.filter((e) => e.date === '2026-09-14');
    expect(sameDay.map((e) => e.type)).toEqual(['record', 'todo']);
  });
});

describe('calendar.groupByDay', () => {
  test('按 date 分组', () => {
    const map = calendar.groupByDay([
      { date: '2026-09-14', type: 'record' },
      { date: '2026-09-14', type: 'todo' },
      { date: '2026-09-15', type: 'reading' },
    ]);
    expect(map['2026-09-14']).toHaveLength(2);
    expect(map['2026-09-15']).toHaveLength(1);
  });

  test('空输入返回空对象', () => {
    expect(calendar.groupByDay(null)).toEqual({});
  });
});

describe('calendar.dotsForDay', () => {
  test('按 record→schedule→todo→reading 顺序去重取色', () => {
    const dots = calendar.dotsForDay([
      { type: 'todo' }, { type: 'record' }, { type: 'record' },
    ]);
    expect(dots).toEqual([EVENT_TYPE_COLORS.record, EVENT_TYPE_COLORS.todo]);
  });

  test('最多返回 4 个圆点', () => {
    const dots = calendar.dotsForDay([
      { type: 'record' }, { type: 'schedule' }, { type: 'todo' }, { type: 'reading' },
    ]);
    expect(dots).toHaveLength(4);
  });

  test('空输入返回空数组', () => {
    expect(calendar.dotsForDay(null)).toEqual([]);
  });
});
