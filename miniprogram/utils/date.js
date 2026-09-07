// utils/date.js —— 日期工具（毫秒时间戳 <-> 日历）
// 云端时间统一存毫秒时间戳；这里提供日历所需的派生函数。

/** 某天 0 点的时间戳 */
function startOfDay(d) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x.getTime();
}

/**
 * 某天次日 0 点的时间戳（区间右开端点，用于 [start, startOfNextDay) 半开区间查询）。
 * 语义修正：原 `endOfDay` 命名易被误解为「当天 23:59:59.999」，实际返回的是
 * **次日 0 点**。现统一以「右开区间端点」语义命名，`endOfDay` 保留为兼容别名。
 */
function startOfNextDay(d) {
  return startOfDay(d) + 24 * 3600 * 1000;
}

/** @deprecated 语义为「次日 0 点」（右开端点），请改用 {@link startOfNextDay} */
function endOfDay(d) {
  return startOfNextDay(d);
}

/**
 * 时间戳 → ISO 周几（周一=1 ... 周日=7），对齐 schedule_items.weekday 约定。
 */
function weekdayOf(d) {
  const wd = new Date(d).getDay(); // 周日=0 ... 周六=6
  return wd === 0 ? 7 : wd;
}

/** 'YYYY-MM-DD' */
function ymd(d) {
  const x = new Date(d);
  const m = String(x.getMonth() + 1).padStart(2, '0');
  const day = String(x.getDate()).padStart(2, '0');
  return `${x.getFullYear()}-${m}-${day}`;
}

/** 'HH:mm' */
function hm(d) {
  const x = new Date(d);
  return `${String(x.getHours()).padStart(2, '0')}:${String(x.getMinutes()).padStart(2, '0')}`;
}

/** 'M月D日' */
function mdCn(d) {
  const x = new Date(d);
  return `${x.getMonth() + 1}月${x.getDate()}日`;
}

/**
 * 生成月历矩阵（周一为起始列），返回 6*7 的格子数组。
 * 每格：{ date: 'YYYY-MM-DD', day: n, ts: 当天0点, inMonth: bool, isToday: bool }
 */
function monthGrid(year, month /* 0-based */) {
  const first = new Date(year, month, 1);
  // 周一=0 ... 周日=6
  const firstWeekday = (first.getDay() + 6) % 7;
  const gridStart = startOfDay(new Date(year, month, 1 - firstWeekday));
  const todayTs = startOfDay(new Date());
  const cells = [];
  for (let i = 0; i < 42; i++) {
    const ts = gridStart + i * 24 * 3600 * 1000;
    const dt = new Date(ts);
    cells.push({
      date: ymd(ts),
      day: dt.getDate(),
      ts,
      inMonth: dt.getMonth() === month,
      isToday: ts === todayTs,
    });
  }
  return cells;
}

/** 当月起止时间戳 [start, endExclusive) */
function monthRange(year, month) {
  return [startOfDay(new Date(year, month, 1)), startOfDay(new Date(year, month + 1, 1))];
}

/**
 * 把每周重复的课表项展开为「当月」所有命中日期的事件数组。
 *
 * 仅处理 **weekly**（每周重复）规则 —— 与现状数据一致；biweekly/monthly/once
 * 属 P1/P2，此处不做投机实现（缺 recurrence 视为 weekly 兜底）。
 *
 * 展开时会尊重课表项自身的生效区间：若带 `startDate`/`endDate`（毫秒时间戳），
 * 只在区间内的日期展开，避免把已停课/未开课的课程画进日历。
 *
 * @param {Array} items schedule_items 列表，元素含 { weekday:1-7, recurrence?, startDate?, endDate? }
 * @param {number} year 年，如 2026
 * @param {number} month 月（0-based，0=一月）
 * @returns {Array} 展开事件 [{ ts, date, weekday, item }]，按日期升序
 */
function expandWeeklySchedule(items, year, month) {
  const list = Array.isArray(items) ? items : [];
  if (!list.length) return [];
  const [monthStart, monthEnd] = monthRange(year, month);
  const out = [];
  for (let ts = monthStart; ts < monthEnd; ts += 24 * 3600 * 1000) {
    const wd = weekdayOf(ts);
    const date = ymd(ts);
    list.forEach((item) => {
      const rec = item.recurrence || 'weekly';
      if (rec !== 'weekly') return; // 仅 weekly；其余规则 P1/P2
      if (Number(item.weekday) !== wd) return;
      // 生效区间过滤（按「天」比较，右端含当天）
      if (item.startDate && ts < startOfDay(item.startDate)) return;
      if (item.endDate && ts > startOfDay(item.endDate)) return;
      out.push({ ts, date, weekday: wd, item });
    });
  }
  return out;
}

/**
 * 根据出生时间戳计算年龄文字
 * @param {number} birthDateTs 毫秒时间戳
 * @returns {string} 如 '3岁4个月' / '8个月' / '1岁'，未填返回 ''
 */
function ageText(birthDateTs) {
  if (!birthDateTs) return '';
  const now = new Date();
  const birth = new Date(birthDateTs);
  let years = now.getFullYear() - birth.getFullYear();
  let months = now.getMonth() - birth.getMonth();
  if (now.getDate() < birth.getDate()) months--;
  if (months < 0) { years--; months += 12; }
  if (years < 0) return '';
  if (years === 0) return months > 0 ? `${months}个月` : '不足1个月';
  if (months === 0) return `${years}岁`;
  return `${years}岁${months}个月`;
}

/**
 * 根据出生时间戳返回书库年龄段标签
 * 与 seed_book_library.json 中 ageRange 枚举对齐：'0-2'/'3-4'/'5-6'/'7-9'/'10+'
 * @param {number} birthDateTs 毫秒时间戳
 * @returns {string|null} 年龄段字符串，未填返回 null（展示全量书库）
 */
function ageRangeOf(birthDateTs) {
  if (!birthDateTs) return null;
  const now = new Date();
  const birth = new Date(birthDateTs);
  let years = now.getFullYear() - birth.getFullYear();
  let months = now.getMonth() - birth.getMonth();
  if (now.getDate() < birth.getDate()) months--;
  if (months < 0) { years--; months += 12; }
  if (years < 0) years = 0;
  if (years <= 2) return '0-2';
  if (years <= 4) return '3-4';
  if (years <= 6) return '5-6';
  if (years <= 9) return '7-9';
  return '10+';
}

/**
 * 推导年级文字，gradeOverride 优先
 * 入学规则：8月31日前满6岁当年入学，9月及以后出生次年入学
 * @param {number} birthDateTs 毫秒时间戳
 * @param {string} gradeOverride 手动覆盖字符串，如 '小学3年级'
 * @returns {string|null} 如 '小学2年级'/'初中1年级'，幼儿园/大学阶段返回 null
 */
function gradeOf(birthDateTs, gradeOverride) {
  if (gradeOverride) return gradeOverride;
  if (!birthDateTs) return null;
  const now = new Date();
  const birth = new Date(birthDateTs);
  const birthYear = birth.getFullYear();
  const birthMonth = birth.getMonth() + 1; // 1-12
  const birthDay = birth.getDate();

  // 入学年份：8月31日前满6岁当年入学，否则次年
  const admissionYear = (birthMonth < 9 || (birthMonth === 8 && birthDay <= 31))
    ? birthYear + 6
    : birthYear + 7;

  // 当前学年（9月起算）
  const currentSchoolYear = now.getMonth() + 1 >= 9
    ? now.getFullYear()
    : now.getFullYear() - 1;

  const grade = currentSchoolYear - admissionYear + 1;

  if (grade < 1) return null; // 幼儿园
  if (grade <= 6) return `小学${grade}年级`;
  if (grade <= 9) return `初中${grade - 6}年级`;
  if (grade <= 12) return `高中${grade - 9}年级`;
  return null; // 大学及以上
}

module.exports = {
  startOfDay,
  startOfNextDay,
  endOfDay,
  weekdayOf,
  ymd,
  hm,
  mdCn,
  monthGrid,
  monthRange,
  expandWeeklySchedule,
  ageText,
  ageRangeOf,
  gradeOf,
};
