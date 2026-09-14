// tests/utils/date.test.js —— 日期工具纯函数单测
const d = require('../../utils/date');

describe('date.startOfDay / startOfNextDay / endOfDay', () => {
  test('startOfDay 归零到当天 0 点', () => {
    const ts = d.startOfDay(new Date(2026, 8, 14, 21, 30, 45, 123));
    const back = new Date(ts);
    expect(back.getHours()).toBe(0);
    expect(back.getMinutes()).toBe(0);
    expect(back.getSeconds()).toBe(0);
    expect(back.getMilliseconds()).toBe(0);
  });

  test('startOfNextDay 恰好比 startOfDay 晚 24 小时', () => {
    const base = new Date(2026, 8, 14, 10, 0, 0);
    expect(d.startOfNextDay(base) - d.startOfDay(base)).toBe(24 * 3600 * 1000);
  });

  test('endOfDay 是 startOfNextDay 的兼容别名', () => {
    const base = new Date(2026, 8, 14, 10, 0, 0);
    expect(d.endOfDay(base)).toBe(d.startOfNextDay(base));
  });
});

describe('date.weekdayOf（ISO 周一=1..周日=7）', () => {
  test('周日返回 7 而非 0', () => {
    // 2026-09-13 是周日
    expect(d.weekdayOf(new Date(2026, 8, 13, 12, 0, 0))).toBe(7);
  });
  test('周一返回 1', () => {
    // 2026-09-14 是周一
    expect(d.weekdayOf(new Date(2026, 8, 14, 12, 0, 0))).toBe(1);
  });
});

describe('date.ymd / hm / mdCn 格式化', () => {
  test('ymd 补零', () => {
    expect(d.ymd(new Date(2026, 0, 5))).toBe('2026-01-05');
  });
  test('hm 补零', () => {
    expect(d.hm(new Date(2026, 0, 5, 9, 3))).toBe('09:03');
  });
  test('mdCn 中文月日', () => {
    expect(d.mdCn(new Date(2026, 8, 14))).toBe('9月14日');
  });
});

describe('date.monthGrid', () => {
  test('固定输出 42 格，周一起始', () => {
    const cells = d.monthGrid(2026, 8); // 2026 年 9 月
    expect(cells).toHaveLength(42);
    // 2026-09-01 是周二 → 首格应为 8 月 31 日（周一）
    expect(cells[0].date).toBe('2026-08-31');
    expect(cells[0].inMonth).toBe(false);
    // 当月 1 号在第 2 格
    expect(cells[1].date).toBe('2026-09-01');
    expect(cells[1].inMonth).toBe(true);
  });
});

describe('date.monthRange', () => {
  test('返回 [当月0点, 次月0点) 半开区间', () => {
    const [start, end] = d.monthRange(2026, 8);
    expect(d.ymd(start)).toBe('2026-09-01');
    expect(d.ymd(end)).toBe('2026-10-01');
    expect(end).toBeGreaterThan(start);
  });
});

describe('date.expandWeeklySchedule', () => {
  test('每周重复课程展开到当月所有命中周几', () => {
    const items = [{ uuid: 'c1', weekday: 1, title: '钢琴' }]; // 每周一
    const events = d.expandWeeklySchedule(items, 2026, 8); // 9 月
    // 2026 年 9 月的周一：7/14/21/28 共 4 天
    expect(events).toHaveLength(4);
    expect(events.map((e) => e.date)).toEqual([
      '2026-09-07', '2026-09-14', '2026-09-21', '2026-09-28',
    ]);
    expect(events.every((e) => e.weekday === 1)).toBe(true);
  });

  test('尊重 startDate / endDate 生效区间', () => {
    const items = [{
      uuid: 'c1', weekday: 1,
      startDate: new Date(2026, 8, 14).getTime(),
      endDate: new Date(2026, 8, 21).getTime(),
    }];
    const events = d.expandWeeklySchedule(items, 2026, 8);
    expect(events.map((e) => e.date)).toEqual(['2026-09-14', '2026-09-21']);
  });

  test('excludedDates 命中当天则跳过', () => {
    const items = [{ uuid: 'c1', weekday: 1, excludedDates: ['2026-09-14'] }];
    const events = d.expandWeeklySchedule(items, 2026, 8);
    expect(events.map((e) => e.date)).not.toContain('2026-09-14');
    expect(events).toHaveLength(3);
  });

  test('非 weekly 规则不展开', () => {
    const items = [{ uuid: 'c1', weekday: 1, recurrence: 'monthly' }];
    expect(d.expandWeeklySchedule(items, 2026, 8)).toHaveLength(0);
  });

  test('空输入返回空数组', () => {
    expect(d.expandWeeklySchedule(null, 2026, 8)).toEqual([]);
    expect(d.expandWeeklySchedule([], 2026, 8)).toEqual([]);
  });
});

describe('date.markExcludedUuidsForDate', () => {
  test('返回当天命中 excludedDates 的 uuid 集合', () => {
    const items = [
      { uuid: 'a', excludedDates: ['2026-09-14'] },
      { uuid: 'b', excludedDates: ['2026-09-15'] },
      { uuid: 'c' },
    ];
    const set = d.markExcludedUuidsForDate(items, new Date(2026, 8, 14));
    expect(set.has('a')).toBe(true);
    expect(set.has('b')).toBe(false);
    expect(set.has('c')).toBe(false);
  });
});

describe('date.ageText / ageRangeOf / gradeOf（固定系统时间 2026-09-14）', () => {
  beforeAll(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date(2026, 8, 14));
  });
  afterAll(() => {
    jest.useRealTimers();
  });

  test('ageText 未填返回空串', () => {
    expect(d.ageText(0)).toBe('');
    expect(d.ageText(null)).toBe('');
  });

  test('ageText 整岁', () => {
    // 出生 2020-09-14 → 恰好 6 岁
    expect(d.ageText(new Date(2020, 8, 14).getTime())).toBe('6岁');
  });

  test('ageText 岁+月', () => {
    // 出生 2023-05-14 → 3 岁 4 个月
    expect(d.ageText(new Date(2023, 4, 14).getTime())).toBe('3岁4个月');
  });

  test('ageText 不足一岁按月', () => {
    // 出生 2026-01-14 → 8 个月
    expect(d.ageText(new Date(2026, 0, 14).getTime())).toBe('8个月');
  });

  test('ageRangeOf 与书库枚举对齐', () => {
    expect(d.ageRangeOf(new Date(2025, 8, 14).getTime())).toBe('0-2'); // 1 岁
    expect(d.ageRangeOf(new Date(2022, 8, 14).getTime())).toBe('3-4'); // 4 岁
    expect(d.ageRangeOf(new Date(2020, 8, 14).getTime())).toBe('5-6'); // 6 岁
    expect(d.ageRangeOf(new Date(2018, 8, 14).getTime())).toBe('7-9'); // 8 岁
    expect(d.ageRangeOf(new Date(2010, 8, 14).getTime())).toBe('10+'); // 16 岁
    expect(d.ageRangeOf(0)).toBeNull();
  });

  test('gradeOf 覆盖值优先', () => {
    expect(d.gradeOf(new Date(2019, 0, 1).getTime(), '小学3年级')).toBe('小学3年级');
  });

  test('gradeOf 小学阶段推导', () => {
    // 2019-05-01 出生：8 月前 → 2025 年入学；当前学年 2025（2026-09 前尚未跨学年，
    // 2026-09-14 已过 9 月 → 学年 2026）→ grade = 2026-2025+1 = 2
    expect(d.gradeOf(new Date(2019, 4, 1).getTime())).toBe('小学2年级');
  });

  test('gradeOf 学龄前返回 null', () => {
    expect(d.gradeOf(new Date(2024, 0, 1).getTime())).toBeNull();
  });
});
