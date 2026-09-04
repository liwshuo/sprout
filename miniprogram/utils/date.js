// utils/date.js —— 日期工具（毫秒时间戳 <-> 日历）
// 云端时间统一存毫秒时间戳；这里提供日历所需的派生函数。

/** 某天 0 点的时间戳 */
function startOfDay(d) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x.getTime();
}

/** 某天 23:59:59.999 的时间戳（不含次日） */
function endOfDay(d) {
  return startOfDay(d) + 24 * 3600 * 1000;
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

module.exports = {
  startOfDay,
  endOfDay,
  ymd,
  hm,
  mdCn,
  monthGrid,
  monthRange,
};
