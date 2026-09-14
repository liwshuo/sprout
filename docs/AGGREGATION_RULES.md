# Sprout 跨端统一口径（AGGREGATION_RULES）

> **文档定位**：本文件是 Sprout 项目**跨端 SSOT（单一事实来源）**。无论小程序端（CloudBase）还是 Flutter App 端（Local-First SQLite），所有业务聚合、派生逻辑、状态跃迁、时间区间计算必须严格遵守本文件定义。任何端如果要改规则，必须先修改本文件并提交评审，再同步改两端代码，禁止直接在端内私自修改口径。
>
> 生效日期：2026-09-10
> 下次触发复审：V2 立项或双端路径 A→B（数据打通）时。
> 交叉引用：`docs/DECISION_LOG_20260910.md` §0（双端策略路径 A）、`docs/PRODUCT_SPEC.md` §8.3（日历聚合）

---

## 0. 枚举值统一

> 所有枚举值**禁止在代码中写字符串字面量**，统一走 constants.js / app_constants.dart 枚举。如要新增/修改值，先改本文件再改两端。

| 枚举名 | 取值 | 说明 |
| --- | --- | --- |
| **BOOK_STATUS** | `want` / `reading` / **`done`** | 书架三分区状态。**禁止使用 `finished`**（历史遗留错误，已修正代码 bug，见决策日志冲突 7）。 |
| **PROGRESS_MODE** | `twoState` / `page` / `chapter` | Books 进度模式。绘本（无页无章）= twoState；有总页数 = page；无页有章 = chapter。 |
| **MOOD** | `happy` 😄 / `calm` 😊 / `excited` 🤩 / `tired` 😪 / `upset` 😣 | 共 5 种心情，顺序固定（展示排序用）。MOOD 的语义是「**家长观察到的孩子心情**」，不是「记录人（家长）自己的心情」。 |
| **RECORDS_CATEGORY**（DailyRecords.category，首标签着色用） | `daily` / `reading` / `schedule` / `sports` / `travel` / `talent` / `chore` / `emotion` / `milestone` / `other` | 与 Tag 预置字典一致。category 是多选 tags 中的「首要标签」；取色映射见 §1.3。 |
| **SCHEDULE_TYPE** | `school`（校内）/ `extra`（课外班） | 课表类型，影响展示颜色（school 天空蓝 #8FC7F0，extra 薄荷绿？不对，和 PRODUCT_SPEC §6.1 不一致 → 统一：school=天空蓝，extra=丁香紫，见 §1.3）。 |
| **RECURRENCE** | `weekly` / `biweekly` / `monthly` / `once` | 课表周期。V1 P0 仅落地 `weekly` 并尊重 startDate/endDate；`biweekly/monthly/once` P1/P2。 |
| **RECORD_SOURCE** / **LOG_SOURCE** | `manual` / `voice` / `timer` | V1 仅产生 `manual`。`voice`/`timer` 口径保留，落地前不得修改。 |
| **COURSE_EXCEPTION_TYPE**（V2） | `cancel` / `reschedule` | 独立 CourseExceptions 集合用。V1 简化版 excludedDates 等价于 `cancel` 型。 |

---

## 1. 时间与日期口径

### 1.1 时区、时间戳、日期字符串
- **所有写入的时间戳 `updatedAt/createdAt/readDate/eventDate/startDate/endDate` 必须是客户端本地时区毫秒**，不是 UTC，不是秒。跨端同步时以本地时区的毫秒整数为准，不做时区换算。
- **所有日期存储字符串统一格式 `YYYY-MM-DD`**（2026-09-10，补零，4-2-2），禁止存 `2026/9/10`、`2026-9-10`、`Sep 10 2026` 等格式。
- **时间段 `startTime/endTime/newStartTime/newEndTime` 统一 `HH:mm`**（24 小时制，补零），禁止 `9:0`、`上午 9 点`。

### 1.2 周区间（周报、weekStart、weekEnd）
- **一周的起始日 = 周一**，周日是一周结束。（不是周日起，不是可配置 —— 目前版本中国场景硬编码，V2 再加地区配置）
- **周区间计算函数 `weekRange(offset)` 定义**：
  - `offset = 0` → 本周：`[本周一 00:00:00 毫秒, 下周一 00:00:00 毫秒)`（**半开区间，右端不包含**）
  - `offset = -1` → 上周，`offset = 1` → 下周。
  - 幂等规则：同一 `weekStart`（即区间左端值）作为周的唯一标识，用做周报幂等键、去重比较。
- **「空周不生成」定义**：本周内 `daily_records.length === 0 && reading_logs.length === 0 && schedule_items 实际开课数=0` 时，不写 weekly_reports 记录；如果前一周已生成，空周跳过不生成。
- **手动生成规则**：即使是空周，用户在 UI 上点「手动生成本周周报」按钮后仍允许生成；`status=draft` 标记为手动，与自动生成区分。

### 1.3 颜色/着色映射
- **分类颜色（映射 RECORDS_CATEGORY）**：
  | 值 | 色值 | 语义 |
  | --- | --- | --- |
  | daily / milestone / other | `#FFB84C`（暖橙 primary）| 默认降级色 |
  | reading | `#7ED9C3`（薄荷 mint）| 阅读打卡 / 绘本相关 |
  | schedule / travel | `#8FC7F0`（天空 sky）| 课表 / 出行 |
  | sports / emotion | `#FF9EB5`（粉 pink）| 运动 / 情绪 |
  | talent | `#B7A5F0`（丁香 lilac）| 才艺 |
  | chore | `#9A8F82`（inkSoft 灰棕）| 家务 |
- **心情颜色（MOOD）**：happy/excited 暖色 `#FFB84C`；calm 中性 `#7ED9C3`；tired/upset 冷灰 `#9A8F82`。
- **SCHEDULE_TYPE 颜色**：school 校内 `#8FC7F0`（天空蓝）；extra 课外班 `#B7A5F0`（丁香紫）。
- **日历圆点配色（三源聚合后每天最多 3 个圆点，优先级固定）**：
  1. 橙点（daily_records）→ 只要有记录就显示
  2. 蓝点（schedule_items 校内+课外班）→ 只要有课就显示
  3. 绿点（reading_logs 打卡）→ 只要有打卡就显示
  - 如果同一天只有一种源，就只显示一个圆点；全部三种就显示三个圆点；圆点排序左→右固定橙蓝绿。

---

## 2. 书架与阅读进度口径（Books + ReadingLogs + Series）

### 2.1 BOOK_STATUS 自动跃迁规则（唯一写入口 = ReadingLogs 追加 + 用户手动 override）
- **新建书籍默认状态** = `want`。
- **want → reading**：首次追加 ReadingLog（任何 pageTo/isFinished）时自动跃迁；跃迁动作写 Books.updatedAt。
- **reading → done**：满足以下任一条件时自动：
  1. ReadingLog 写了 `isFinished = true`；
  2. progress_mode = `page`，且 `max(pageTo of all logs) >= Books.totalPages`；
  3. progress_mode = `chapter`，且 `max(chapterIndex of all logs) >= Books.totalChapters`；
  4. progress_mode = `twoState` 时，只看 `isFinished = true`。
- **done → reading 不允许自动退**：家长手动把书切回 reading 优先级最高，打卡不会把手动 done 的书退回去；仅允许 UI 上用户手动退回。
- **系列书（套书）聚合进度条**：V1 不展示，V2 才做，计算口径是：`count(books where seriesId = X and status='done') / Series.totalVolumes * 100%`；totalVolumes 为 0 或 null 时不展示进度，只显示「N/M 册」字面量数字。

### 2.2 当前阅读进度派生（Books 不冗余存 progress，全部实时聚合 ReadingLogs）
| progress_mode | 当前进度计算 | 展示格式 |
| --- | --- | --- |
| `twoState`（绘本）| `count(logs where isFinished=true)` 遍数 + 是否有 unfinished 打卡 | 读完 N 遍 |
| `page`（页数环）| `已读页 = max(pageTo of all logs, 0)`；总页数 Books.totalPages | 「已读 X / 总 Y 页」+ 进度环 X/Y*100%，totalPages 为 null/0 时只显示「已读 X 页」 |
| `chapter`（章节环）| `已读章 = max(chapterIndex of all logs, 0)` | 同上改成「已读 X / 总 Y 章」 |

- **注意 pageFrom/pageTo 的合法性**：写 ReadingLog 时前置校验 `if (pageTo != null && pageFrom != null && Number(pageTo) < Number(pageFrom)) → 拒绝写`；`totalPages`/`totalChapters` 必须是正整数，非正或 null → 不展示分母。
- **重复次数（twoState）**：同一个 bookUuid 下的 ReadingLog `isFinished = true` 的数量就是"读过 N 遍"的 N；用户手动把书从 done 切回 reading 再打卡一遍 → N 会再+1，这是允许的（重复读绘本场景）。

### 2.3 系列书面板叠层封面显示
- seriesUuid 下分册按 seriesIndex ASC 排序；seriesIndex 相同/为 null 时按 createdAt 排序。
- 叠层卡片 3 张叠放：最上一张（seriesIndex 最小或 createdAt 最早）取真实 cover；下面两张（stack-2、stack-3）必须也是真实 cover 而不是纯色块；错位视觉由 CSS 层 `translateY(+4rpx)` + `scale(.96)` 模拟厚度。
- 空分册时，系列卡叠层退化为单张封面并显示「+ 添加分册」占位。

---

## 3. 日历聚合（三源归一 CalendarEvent）

### 3.1 三个来源的归一化字段
三源聚合后输出统一 `CalendarEvent` 结构，UI 只消费这个结构，禁止直接消费原始文档：

```ts
interface CalendarEvent {
  // 三源归一，必填
  type: 'record' | 'schedule' | 'reading';
  date: 'YYYY-MM-DD';              // 落点日期，聚合分组用
  ts: number;                      // 当日内排序用的毫秒时间
  timeLabel: string;               // 展示用时间：如 15:30-17:00、全天、空串''
  title: string;                   // 展示主标题（截断）
  subtitle?: string;               // 副标题：如『绘本/第 20 页-第 40 页』、『地点：少年宫 204』
  color: string;                   // §1.3 对应 category 或 schedule_type 着色
  icon?: string;                   // emoji 图标备选，实际 UI 可能不用
  sourceId: string;                // 被引 uuid：records.uuid / schedule_items.uuid / reading_logs.uuid，点击跳转用
  raw: any;                        // 原始文档，VM 扩展用
}
```

### 3.2 三源的字段映射（各自如何生成 CalendarEvent）
| 源 | date 取哪列 | title 生成规则 | timeLabel/color/subtitle |
| --- | --- | --- | --- |
| `daily_records` | `eventDate`（不是 createdAt）| title 优先 `record.title`；空则降级为「{categoryLabel} · 笔记」（如 「才艺 · 笔记」）| color 取 RECORDS_CATEGORY 映射；timeLabel 空串''；subtitle 取 `record.note` 前 30 字，无 note 则显示 mood emoji。 |
| `schedule_items`（周期展开）| 周期规则推算出的具体日期 `YYYY-MM-DD`；同时命中 excludedDates 或 (V2) CourseExceptions.cancel → 不生成事件 | title = `courseName` + (V2 `type=reschedule` 时追加「(调课)」)；school 类型追加「🏫」前缀，extra 类型追加「🎨」或按学科 | color = schedule_type 映射；timeLabel = `{startTime}-{endTime}`；subtitle 非空 location/teacher 合并成「{teacher} · {location}」。|
| `reading_logs` | `readDate` | title = `Books.title`（join books by bookUuid 拿；bookUuid 指向的书被软删 → fallback「阅读打卡」，且颜色降为灰 primary）| color = reading（薄荷绿）；timeLabel 空串'' 或 `durationMinutes + ' 分钟'` 若有；subtitle 根据 progress_mode 格式化：page → 「第 pageFrom - pageTo 页」；chapter → 「第 chapterIndex 章」；twoState + isFinished → 「读完一遍 ✨」。 |

### 3.3 周期规则展开（schedule_items → 日期列表）
- **`recurrence=weekly`（V1 唯一落地）**：`weekday=item.weekday`，如果 item.startDate 非空且日期 < startDate → 不生成；同理 item.endDate 非空且日期 > endDate → 不生成。最后再过滤命中 `excludedDates.includes(dateStr)` 的日期。
- **`recurrence=biweekly`（P1）**：以 startDate 所在周为第 0 周，`(targetWeekIndex - startWeekIndex) % 2 === 0` 的奇数周或偶数周展开；无 startDate 退化为 weekly。
- **`recurrence=monthly`（P1）**：每月第 N 个周 X（N 取 startDate 是第几周 X），1st/2nd/3rd/4th/Last；
- **`recurrence=once`（P1）**：只在 `item.startDate`（或 eventDate 字段）当天生成 1 条；weekday 从该日期推出，忽略 item.weekday 列。

### 3.4 同日圆点去重
三源聚合成 CalendarEvent[] 后，每个 `date` 的圆点（橙/蓝/绿）是按"该日是否存在该类型的至少一条 CalendarEvent"做布尔去重，不是按数量显示圆点数量。例如一天有 5 条记录，橙点还是只有一个。
- 展示顺序固定：橙 → 蓝 → 绿（见 §1.3）。
- 当日事件列表排序：按 `ts`（即 schedule.startTime → 记录 created/reading 自定义 time → 全天无时间置尾），不要按类型排序。

---

## 4. 周报统计（WeeklyReports）

### 4.1 周报聚合区间
严格按 §1.2 的「周区间半开区间」`[weekStart, weekEnd)`，两端 `where('eventDate/readDate', '>=', weekStartTs)` + `where(..., '<', weekEndTs)`。**禁止用自然语言「周日是本周」这种模糊定义。**
- 注意：schedule_items 的开课实例是「根据周期在 [weekStart, weekEnd) 这个时间区间内展开命中的课程实例数量」，不是 schedule_items 文档数。V1 简化：展开后 count 过滤 excludedDates，命中计入 extra_class_count / school_count。

### 4.2 各字段聚合方法（双端必须同算法，即使存储是冗余字段也要保证一致）
| 字段名 | 算法 |
| --- | --- |
| `daily_count` | `daily_records` 在区间内未软删的记录数 |
| `reading_count` | `reading_logs` 在区间内未软删的打卡次数 |
| `reading_minutes` | `sum(reading_logs.durationMinutes where not null)`；全为 null 时字段 = 0，展示显示「未统计」不显示 0 分钟 |
| `extra_class_count` | 展开课程实例（§3.3）中 type=extra 且命中区间、未被 excludedDates 取消的数量 |
| `active_days` | `[weekStart, weekEnd) 七天中每日至少有一条 daily_record OR reading_log OR schedule 开课实例` 的天数；整数 0~7 |
| `mood_stats[]` | 只从 `daily_records.mood` + `reading_logs.mood` 合并统计（reading_logs 也有心情），只统计 mood 非 null 非空的记录作为总分母；topMood 按出现频率最高的取；多个同分按 MOOD 枚举顺序（§0）前面那个先取。 |
| `category_stats[]` | 只从 `daily_records.category` 统计，category 为空降级为 `other`；Top Category 同上按频率。 |
| `books[]`（本周读过的绘本列表）| **必须是 reading_logs.bookUuid 去重**（join books 拿 title/cover），绝对不能按 books.updatedAt 过滤；否则添加新书没读也会被统计，见 Bug（决策日志 7.1）。 |
| `summary` 字符串 | 由以上各字段按本地模板拼装，格式：「本周记录了 {daily_count} 条日常点滴，阅读打卡 {reading_count} 次共 {reading_minutes} 分钟，去了 {extra_class_count} 节课，活跃 {active_days} 天。topMood 是{mood}，最常做的事是 {topCategory}。本周读了 books[] 的 {bookTitlesList}。」没有的维度自然省略，不显示 0。 |
| `ai_text`（V2）| LLM 润色原文，V1 空字符串；V2 生成后展示优先级：editedText > ai_text > summary。 |
| `edited_text` | 家长手改内容，有就优先展示，V1 提供编辑入口（P1）。 |

### 4.3 空周不生成 + 幂等
- **空周定义**：daily_count=0 且 reading_count=0 且 extra_class_count=0 且 active_days=0。
- **自动生成策略**：空周 → 不写 weekly_reports 文档；**非空周 → 必须写**；自动生成触发时间是周日 20:00（定时触发器）+ App/小程序前台 onShow 时做「补偿生成」（iOS 后台任务不保证精准，前台补偿兜底）。
- **幂等键**：按 `{childId, weekStart}` 联合唯一；若该键已有文档存在 → 跳过不重复生成；但用户手动点「重新生成」可覆盖原文档（保留 editedText 不丢，其它非 edited 字段重算）。
- **状态 status**：自动生成 → `published`；手动点「生成」且是空周 → `draft`；用户改过 editedText → 保留原值（published/draft 不变，改 isEdited=true 标记，或在 updatedAt 比较 editedAt 字段）。

---

## 5. 派生字典型（年龄/年级/年龄段）

### 5.1 ageText 派生（children.birthDate → 显示文字）
- birthDate 缺失 → `宝宝` 不显示岁数；
- age < 1 岁 → `{months} 个月`（计算整月）；
- 1 ≤ age < 10 → `{age} 岁 {months} 个月`（不满岁的月数超过 0 就显示，满 0 个月只显示 `{age} 岁`）；
- age ≥ 10 → `{age} 岁`（月数忽略）。

### 5.2 gradeOf 派生（birthDate + 可选 gradeOverride）→ 年级字符串
- **gradeOverride 优先级最高**：非空字符串直接返回，不看 birthDate；空时按 birthDate 推算。
- 推算规则（中国学制，硬编码 V1）：以当前年 9 月 1 日为升学年分界。例如 `2026-09-01 升学年`，生日在 2019-09-01 ~ 2020-08-31 → 一年级；2018 级二年级；以此类推；< 上学年龄 → `学前·小班/中班/大班`（按出生日期推断具体班）。
- grade 字符串枚举值：`学前·小班 / 学前·中班 / 学前·大班 / 小学一年级 ~ 六年级 / 初中一年级 ~ 三年级 / 高中一年级 ~ 三年级`。

### 5.3 ageRangeOf 派生（birthDate + gradeOverride）→ 书库分龄 Tab
书库 5 个分龄 Tab 与上述 grade 对应：
- `0-3` → 小班/以下
- `3-4` → 中班
- `5-6` → 大班
- `1-2` → 小学 1~2 年级
- `3-6` → 小学 3~6 年级以上

如果 gradeOverride 或 birthDate 都拿不到，默认展示「官方精选」Tab。

---

## 6. 版本与修改记录

| 版本 | 日期 | 修订内容 | 影响端 |
| --- | --- | --- | --- |
| 1.0 | 2026-09-10 | 初版：覆盖 BOOK_STATUS 统一 done、心情枚举、阅读进度派生、日历聚合三源映射、周报区间、派生年龄年级 | 小程序端 + Flutter 端 |
