# 萌芽成长册 · 微信小程序全局架构 Review 与重设计方案

> 版本：v2.1（全局版，经批判性 review 修订；覆盖 v2.0 / v1.0）
> 范围：`miniprogram/` 全量代码（云环境 `cloud1-d3gh6o81f2ba198c9`）
> 目标：在不推翻现有合理设计的前提下，补齐**服务层 / 组件层**两个缺失分层，规范目录与编码约定，并把当前待办（日历聚合、阅读打卡闭环）纳入统一架构。
>
> **v2.1 修订要点**：① 补上 wx.cloud 硬约束（**小程序端单次查询 20 条上限**）及其对日历聚合/列表的影响与对策；② 课表推算 P0 收敛为「仅 weekly」，biweekly/monthly/once 降级到 P1/P2（现有数据只产 weekly，避免投机实现）；③ 统一伪代码命名为现状的 `db.*`（`collections.js` 拆分为 P2）；④ 新增「风险点与边界 case」章节。
>
> **结论先行（三句话）：**
> 1. 底子好：数据层（同步三件套 + 双归属）、设计令牌（`app.wxss` CSS 变量）、登录链路都规范，**不需要大改**。
> 2. 核心缺陷：**缺"服务层"和"组件层"两层** —— 业务聚合逻辑（日历打点、周报统计）散落在页面里且互相重复，UI 结构（FAB / 弹层 / 卡片）在各页复制粘贴。
> 3. 待办功能（日历三源聚合、阅读打卡）本质是"新业务逻辑该往哪放"的问题，答案就是**先立服务层，再落功能**。

---

## 1. 全局架构 Review

### 1.1 现状分层全景

当前实际是"**三层半**"结构：页面层 + 工具层 + 云函数层，外加一层隐性的样式令牌层（`app.wxss`）。缺服务层与组件层。

```
┌─────────────────────────────────────────────────────────┐
│ 样式令牌层  app.wxss（CSS 变量：色/圆角/阴影 + 通用类）  ✅ 规范  │
├─────────────────────────────────────────────────────────┤
│ 页面层 pages/                                              │
│   index(日历) records(列表) records/add(编辑)             │
│   reading(书架) schedule(课表) mine(我的) report(周报)     │
│   ⚠️ 每个页面自己：取数 + 业务聚合 + 组装VM + setData       │
│   ⚠️ UI 结构（FAB/弹层/卡片/空态/tab）各页复制             │
├─────────────────────────────────────────────────────────┤
│ ❌ 服务层  —— 不存在（业务逻辑无处安放，全塞页面）           │
│ ❌ 组件层  —— 不存在（无 components/ 目录）                 │
├─────────────────────────────────────────────────────────┤
│ 工具层 utils/                                              │
│   db.js（CRUD+归属+媒体，混入了 records/books 业务封装）    │
│   auth.js  date.js  constants.js                          │
├─────────────────────────────────────────────────────────┤
│ 全局层 app.js（globalData + 极简事件总线 on/off/_emit）    │
├─────────────────────────────────────────────────────────┤
│ 云函数层 cloudfunctions/                                   │
│   login（openid→upsert users）✅  bindPhone（手机号）✅     │
└─────────────────────────────────────────────────────────┘
                          │ wx.cloud
                          ▼
        CloudBase：云数据库(8集合) / 云存储 / 云函数
```

**数据流现状（以日历/周报为例，暴露重复问题）：**
- `pages/index`：`db.records.listByRange` → 页面内按天聚合取色 → setData。
- `pages/report`：`db.records.listByRange` + `db.books.listAll` → 页面内算心情分布/分类分布/周总结 → setData。
- 两个页面**各写一套"按时间范围拉记录 + 聚合统计"**，口径可能漂移（例如 report 用 `books.updatedAt` 近似"本周读的书"，而非 `reading_logs`，是个正确性隐患）。

### 1.2 各层问题清单（命名 / 职责边界 / 耦合点）

| 层 | 问题类型 | 具体问题 | 影响 |
| --- | --- | --- | --- |
| 页面层 | 职责越界 | 页面同时承担取数、业务聚合、VM 组装、渲染四职（index 132 行、add 207 行、report 113 行） | 逻辑不可复用、难测试、易漂移 |
| 页面层 | 命名不一致 | Tab 页路径混用：`records/records`、`reading/reading` vs `schedule/index`、`index/index` | 心智负担，新人易迷路 |
| 页面层 | 重复代码 | FAB、底部弹层(sheet+mask)、空态、卡片、tab-bar 在 5+ 页复制 | 改一处要改多处 |
| 页面层 | 硬编码 | `schedule/index.wxml` 内联 `#8FC7F0`/`#FF8C42`，未走 CSS 变量/constants | 破坏令牌统一 |
| 服务层 | **缺失** | 无 `services/`，业务聚合逻辑无家可归 | 本次待办功能无处落地的根因 |
| 组件层 | **缺失** | 无 `components/`，UI 全内联 | 复用性=0 |
| 工具层 | 职责混杂 | `db.js` 既是"纯 CRUD 引擎"又塞了 `records/books/children` 业务封装 | 数据层与业务层边界模糊 |
| 工具层 | 封装不对称 | `records/books/children` 有专属方法，`schedule_items`/`reading_logs` 只能裸调 `db.list(COL)` | 调用方耦合集合常量 |
| 数据层 | 闭环缺失 | `reading_logs`/`series`/`weekly_reports` 三集合已规划但**零写入代码** | 阅读日志无数据，日历第三源是空的 |
| 数据层 | **查询上限（高危）** | 小程序端 `collection.get()` **单次最多返回 20 条**；`db.records.listAll(100)` 的 `limit:100` 在客户端被静默截断为 20，`listByRange` 无 limit 同样只回 20 | **日历月聚合/记录列表会丢数据**，且无报错，隐蔽 |
| 云函数层 | 够用但偏薄 | 仅 login/bindPhone；跨集合聚合（周报）、推送提醒尚无 | 后续周报/通知需补 |
| 全局层 | 约定缺失 | `globalData` 字段无文档约定，事件总线事件名散落字符串 | 易拼错、难维护 |

### 1.3 可维护性评分与核心痛点

| 维度 | 评分（5分制） | 说明 |
| --- | --- | --- |
| 数据模型设计 | ⭐⭐⭐⭐⭐ | 同步三件套 + 双归属 + uuid 主键，前瞻性强 |
| 样式/设计令牌 | ⭐⭐⭐⭐☆ | `app.wxss` CSS 变量规范，扣分在个别页面硬编码色值 |
| 登录/账号体系 | ⭐⭐⭐⭐⭐ | 链路清晰，错误指引友好 |
| 分层清晰度 | ⭐⭐☆☆☆ | 缺服务层/组件层，页面职责过重 |
| 代码复用性 | ⭐⭐☆☆☆ | UI 与聚合逻辑大量重复 |
| 可测试性 | ⭐⭐☆☆☆ | 业务逻辑与页面生命周期耦合，难单测 |
| 可扩展性 | ⭐⭐⭐☆☆ | 数据层可扩展性好，但业务层加功能只能继续堆页面 |
| **综合** | **⭐⭐⭐☆☆（3.3）** | 地基优秀，上层结构待补 |

**三大核心痛点：**
1. **业务逻辑无家可归** → 加功能只能塞页面，页面越来越胖，逻辑无法跨页复用（日历聚合、周报统计天然应共享）。
2. **UI 复制粘贴** → 视觉一致性靠人肉维护，改动成本高。
3. **数据闭环有断点** → `reading_logs` 没有写入入口，导致"阅读日志进日历"这个目标缺上游数据。

---

## 2. 目标架构全景设计（可扩展 + 可维护）

### 2.1 目标分层

```
样式令牌层   app.wxss（保持）
页面层       pages/*         ← 只做 UI 编排 + 交互，取数调 service
组件层       components/*    ← 新增：可复用 UI 单元
服务层       services/*      ← 新增：业务聚合 / 领域逻辑（可复用可测试）
工具层       utils/*         ← 收敛为纯工具（db 纯 CRUD、date、constants、format）
全局层       app.js + store  ← globalData 规范化 + 事件总线约定
云函数层     cloudfunctions/* ← login/bindPhone + 后续聚合/推送
```

**依赖方向（单向，禁止反向）：** `pages → components / services → utils → (wx.cloud)`。services 之间可横向调用，但**禁止 services 依赖 pages**、**禁止 utils 依赖 services**。

### 2.2 目录结构规范

```
miniprogram/
├── app.js / app.json / app.wxss        # 入口 + 全局样式令牌
├── store/
│   └── index.js                        # 【新增】全局状态 + 事件总线（从 app.js 抽出并规范）
├── services/                           # 【新增】业务服务层
│   ├── calendar-service.js             #   日历三源聚合
│   ├── reading-service.js              #   书架状态跃迁 + 打卡 + 进度派生
│   ├── schedule-service.js             #   课表周期规则 → 日期展开
│   └── report-service.js               #   周报聚合统计（复用日历口径）
├── utils/                              # 纯工具（无业务语义）
│   ├── db.js                           #   纯 CRUD 引擎 + 归属过滤 + 媒体（去掉业务封装）
│   ├── collections.js                  # 【新增】集合名常量 + 各集合业务快捷方法（从 db.js 拆出）
│   ├── auth.js                         #   登录 / ownerId
│   ├── date.js                         #   日期派生 + 周期推算辅助
│   ├── constants.js                    #   展示令牌（分类色/心情/事件类型色/书籍状态）
│   └── format.js                       # 【新增】展示格式化（VM 组装：recordVM/bookVM 等）
├── components/                         # 【新增】可复用组件
│   ├── month-calendar/                 #   月历（网格 + 多彩点）
│   ├── event-card/                     #   统一事件卡片（record/schedule/reading 三态）
│   ├── book-card/                      #   书籍卡片
│   ├── bottom-sheet/                   #   底部弹层（mask + sheet 通用壳）
│   ├── empty-state/                    #   空态占位
│   └── fab-button/                     #   悬浮添加按钮
├── pages/                              # 页面（命名统一为 目录/index）
│   ├── index/          (日历)
│   ├── records/        (记录列表)      # 由 records/records → records/index（P2 重命名）
│   ├── records/add/    (记录编辑)
│   ├── reading/        (书架) + reading/book/ (书详情+打卡, 新增)
│   ├── schedule/       (课表)
│   ├── report/         (周报)
│   └── mine/           (我的)
└── cloudfunctions/
    ├── login/          ✅
    ├── bindPhone/      ✅
    └── generateWeeklyReport/  # 【后续 P2】周报云端聚合 + 定时触发
```

**命名约定：**
- **集合**：`snake_case` 复数（`daily_records`）——已一致，保持。
- **页面目录**：统一 `pages/<domain>/index`；二级页 `pages/<domain>/<sub>/`。
- **组件**：`kebab-case` 目录名（`event-card`），组件标签同名。
- **service 文件**：`<domain>-service.js`，导出对象 `xxxService`，方法动词开头（`getMonthView`、`addCheckin`、`expandToMonth`）。
- **工具函数**：动词/名词短语（`startOfDay`、`ymd`），布尔判定 `is/has` 前缀。

### 2.3 数据层：8 集合完整设计

**通用约定（全表）：** `_id`(云自动) + 同步三件套 `uuid`/`updatedAt`/`isDeleted` + `createdAt` + 归属 `ownerId`（业务集合再加 `childId`）。时间统一**毫秒时间戳 Number**。关系引用存被引对象 `uuid`。

#### ① `users`（归属：ownerId）
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| ownerId | String | unionid 优先否则 openid，**全局归属主键** |
| openid / unionid | String / String? | 微信标识 |
| phone | String? | bindPhone 云函数写入 |
| nickname / avatar | String? | 昵称 / 头像 fileID |
| createdAt / updatedAt | Number | |

#### ② `children`（归属：ownerId）
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| uuid | String | 业务主键，被业务集合 childId 引用 |
| ownerId | String | 归属 |
| name | String | 昵称 |
| birthDate | Number? | 生日时间戳（算年龄） |
| avatarFileId | String? | 头像 fileID |
| sortOrder | Number | 切换器排序 |
| updatedAt / isDeleted | Number/Bool | |

#### ③ `daily_records`（归属：ownerId + childId）— 成长记录
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| uuid / ownerId / childId | String | |
| title / note | String / String? | 标题 / 备注 |
| tags | Array\<String\> | 标签 |
| category | String? | 分类（着色用，= 首个标签） |
| mood | String? | happy/calm/excited/tired/upset |
| imageFileIds | Array\<String\> | 图片 fileID 数组 |
| source | String | manual/voice/timer |
| eventDate | Number | **聚合主键**（日历/周报按此） |
| durationMinutes | Number? | 时长 |
| createdAt/updatedAt/isDeleted | | |

#### ④ `schedule_items`（归属：ownerId + childId）— 课表/课外班
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| uuid / ownerId / childId | String | |
| courseName | String | 课程名 |
| type | String | school / extra |
| location / teacher | String? | 地点 / 老师 |
| weekday | Number | 1–7（多选周几拆多行） |
| recurrence | String | weekly / biweekly / monthly / once |
| startTime / endTime | String | "HH:mm" |
| **startDate** | Number? | **周期锚点（建议表单补齐）**：biweekly 起算周 / once 具体日 |
| endDate | Number? | 失效日 |
| **emoji / color** | String? | 可选：稳定头像/取色 |
| updatedAt/isDeleted | | |

#### ⑤ `books`（归属：ownerId + childId）— 书架
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| uuid / ownerId / childId | String | |
| title / author / cover / isbn | String? | cover 存 fileID |
| status | String | want / reading / done（**由打卡派生跃迁，写侧判定**） |
| totalPages / totalChapters | Number? | 总量 |
| seriesUuid / seriesIndex | String? / Number? | 套书引用 |
| updatedAt/isDeleted | | |

#### ⑥ `reading_logs`（归属：ownerId + childId）— 阅读打卡 ⭐待补写入
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| uuid / ownerId / childId | String | |
| bookUuid | String | 关联 books.uuid（删书级联软删） |
| readDate | Number | **日历第三源聚合主键** |
| chapter / chapterIndex | String? / Number? | 章节 |
| pageFrom / pageTo | Number? | 页码（进度 = max(pageTo)） |
| durationMinutes | Number | 时长 |
| mood / note / source | String? / String | |
| updatedAt/isDeleted | | |

#### ⑦ `series`（归属：ownerId + childId）— 套书
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| uuid / ownerId / childId | String | |
| name | String | 套书名 |
| totalVolumes | Number | 总册数（已读册数**不存**，聚合派生） |
| updatedAt/isDeleted | | |

#### ⑧ `weekly_reports`（归属：ownerId + childId）— 周报快照
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| uuid / ownerId / childId | String | |
| weekStart / weekEnd | Number | 周起止（weekStart 唯一去重） |
| summary | Object | 结构化统计快照 |
| aiText / editedText | String? | AI 文案 / 家长编辑版 |
| status | String | draft / published |
| dailyCount/readingCount/readingMinutes/extraClassCount/activeDays | Number | 快照统计 |
| generatedAt/updatedAt/isDeleted | | |

#### 集合关联关系
```
users(ownerId) 1─N children(uuid)
  children.uuid ◄── childId ── daily_records / schedule_items / reading_logs / books / series / weekly_reports
  series(uuid) 1─N books(seriesUuid)
  books(uuid)  1─N reading_logs(bookUuid)
```

#### 所需索引（云控制台配置，均非唯一复合索引）
| 集合 | 索引 | 用途 |
| --- | --- | --- |
| users | `ownerId`(唯一) | 登录 upsert |
| children | `{ownerId, sortOrder}` | 切换器列表 |
| daily_records | `{ownerId, childId, eventDate}` | 日历/周报按天聚合 |
| daily_records | `{ownerId, childId, updatedAt}` | 增量同步 |
| schedule_items | `{ownerId, childId, weekday}` | 课表分组 |
| reading_logs | `{ownerId, childId, readDate}` | 日历第三源 |
| reading_logs | `{ownerId, childId, bookUuid}` | 书详情打卡历史 |
| books | `{ownerId, childId, status}` | 书架分区 |

#### 权限规则
所有集合统一「**仅创建者可读写**」（`auth.openid == doc._openid` 由 CloudBase 自动注入 `_openid` 保障），业务侧再叠加 `ownerId`/`childId` 过滤。云函数走管理员权限做跨用户聚合（周报）。

#### wx.cloud 能力边界（务必遵守，直接影响本方案落地）
| 约束 | 数值 | 对本方案的影响与对策 |
| --- | --- | --- |
| **客户端单次查询上限** | `.get()` 一次**最多 20 条**（云函数端可到 100~1000） | **最关键**：日历月聚合、记录列表、打卡历史都可能 >20 条。对策：数据层新增**分页拉取** `listAllPaged(col, {where}, cap)`（内部 `skip/limit(20)` 循环直到 <20 或达上限 cap，默认 200），日历三源与 `records.listAll` 一律改用它。数据量继续增大再考虑下沉云函数聚合 |
| **临时链接批量上限** | `getTempFileURL` 一次**最多 50 个 fileID** | 记录列表/日历封面水合需**分批 ≤50**；现 `db.getTempUrls` 需加分片 |
| **where + orderBy** | 复合查询建议建索引 | 已在索引表覆盖（含 `eventDate`/`readDate`/`weekday`）；`schedule` 按 `startTime` 排序数据量小可不建 |
| **单次批量写** | 客户端不支持跨文档事务批量写 | 打卡→改书状态是**两次独立写**，按"先写 log 再改 status"顺序，失败各自 toast；无需事务 |
| **主包体积** | 主包 ≤ 2MB，总包 ≤ 20MB | 新增 services/components 均为极小 JS，**远无风险**，本阶段不需要分包 |
| **云函数冷启动** | 首次调用有延迟 | 聚合类逻辑本方案放**客户端 service**（纯读+纯算），不上云函数，规避冷启动；仅周报（定时、跨集合）才上云函数 |

### 2.4 服务层（新增，核心）

| Service | 职责边界 | 关键方法 | 从哪个页面下沉 |
| --- | --- | --- | --- |
| `calendar-service` | 三源聚合成统一 `CalendarEvent`，按天分组 + 多彩点 | `getMonthView(y,m)`、`toRecordEvent`、`toReadingEvent` | pages/index 的 refresh/_loadDay |
| `schedule-service` | 课表周期规则 → 当月具体日期展开 | `expandToMonth(items,y,m)`、`hitOn(item,date)` | pages/schedule 的分组 + 日历所需 |
| `reading-service` | 书架状态跃迁 + 打卡写入 + 进度派生 | `addCheckin(bookUuid,log)`、`deriveProgress(book,logs)`、`nextStatus` | pages/reading 的 cycleStatus + 新打卡 |
| `report-service` | 周报统计（复用 calendar 口径，取代 report 页自算） | `getWeekSummary(offset)` | pages/report 的 loadWeek |

**统一事件模型 `CalendarEvent`（三源归一）：**
```js
{
  type:'record'|'schedule'|'reading', date:'YYYY-MM-DD', ts, time:'09:00'|'',
  title, subtitle, color, icon, refType, refUuid, raw
}
```

### 2.5 工具层收敛

| 文件 | 动作 | 职责 |
| --- | --- | --- |
| `utils/db.js` | 瘦身 | 只留纯 CRUD（list/getByUuid/create/updateByUuid/softDelete）+ 归属 scope + 媒体上传/临时链接。**移出** records/books/children 业务封装 |
| `utils/db.js` | 增强（P0） | **新增 `listAllPaged(col,{where,orderBy},cap=200)`** 破解 20 条上限（skip/limit(20) 循环）；**`getTempUrls` 加 ≤50 分片**；`records.listAll`/日历三源改用分页 |
| `utils/collections.js` | 新增 | 集合名常量 + 各集合业务快捷方法（records/books/children/**scheduleItems/readingLogs**），补齐对称封装 |
| `utils/date.js` | 增强 | 新增 `weekdayOf(ts)`(1~7)、`nthWeekdayOfMonth`、`weekIndexSince(anchor,ts)`（周期推算） |
| `utils/constants.js` | 增强 | 新增 `EVENT_TYPE_COLORS={record,schedule,reading}` + 取色函数 |
| `utils/format.js` | 新增 | VM 组装（`recordVM`/`bookVM`/`eventVM`），页面展示模型统一 |
| `utils/auth.js` | 保持 | 登录 / ownerId |

> 关于是否拆 `collections.js`：`db.js` 当前把"纯引擎"和"业务封装"混在一起。拆分让数据层职责单一，但**属于优化性改动，可放 P1**，本轮先按现状在 db.js 内补齐 scheduleItems/readingLogs 亦可，二选一。

### 2.6 组件层（新增）

| 组件 | 抽取来源 | 复用页 | 优先级 |
| --- | --- | --- | --- |
| `month-calendar` | index.wxml 月历网格 | 日历（未来周报可用） | P1 |
| `event-card` | index 记录卡片，扩展为三态 | 日历/记录 | P1 |
| `book-card` | reading.wxml 书籍卡片 | 书架/书详情 | P2 |
| `bottom-sheet` | reading/schedule 的 mask+sheet | 所有弹层 | P1 |
| `empty-state` | 各页 `.empty` 空态 | 全部 | P2 |
| `fab-button` | 各页 `.fab` | 全部 | P2 |

> 原则：**先抽复用≥2 次且结构稳定的**（bottom-sheet、event-card、month-calendar）；一次性 UI 不强抽，避免过度组件化。

### 2.7 云函数层

| 云函数 | 现状 | 结论 |
| --- | --- | --- |
| `login` | 解析 openid → upsert users | ✅ 够用，保持 |
| `bindPhone` | code/cloudID → 手机号 → 写 users.phone | ✅ 够用，保持 |
| `generateWeeklyReport` | 无 | **P2 新增**：定时触发（周日 20:00）跨集合聚合当周 records/reading_logs/schedule → 写 weekly_reports；空周不生成，weekStart 幂等 |
| `sendReminder`（可选） | 无 | **后续**：订阅消息推送（打卡提醒/周报就绪），需前端申请订阅 |

> 判断依据：**只要是"不可信客户端不该做"或"跨用户/需管理员权限/定时"的逻辑才上云函数**。日历聚合、课表展开是纯读+纯计算，放客户端 service 即可，不必上云函数。

### 2.8 全局状态管理

**`globalData` 规范化（`store/index.js` 集中定义 + 注释约定）：**
```js
globalData = {
  cloudReady: Boolean,        // 云初始化状态
  currentUser: {ownerId,openid,unionid,phone,nickname,avatar}|null,
  activeChildId: String,      // 当前孩子 uuid
  children: Array,            // 孩子列表缓存
  syncStatus: 'idle'|'syncing'|'error',
  themeColor: String,
}
```

**事件总线约定（保留 app.js 的 on/off/_emit，事件名收敛为常量）：**
```js
// store/events.js
const EVENTS = {
  ACTIVE_CHILD_CHANGED: 'activeChildChanged',
  USER_CHANGED: 'userChanged',
  DATA_CHANGED: 'dataChanged', // 新增：写操作后广播，触发相关页刷新
};
```
- **约定**：任何写操作（create/update/softDelete）成功后 `emit(DATA_CHANGED, {collection})`，相关页在 `onShow` 或订阅后按需 `refresh`，替代当前"每个 onShow 无脑全量重拉"。
- **不引入 MobX/Redux**：状态复杂度低，极简事件总线 + globalData 足够，避免过度设计。

---

## 3. 当前待办功能的实现路径（结合架构）

### 3.1 日历聚合展示（成长记录 + 课外班 + 阅读日志）

> 命名说明：以下用现状的 `db.*`（`db.records`/`db.scheduleItems`/`db.readingLogs`）。`collections.js` 拆分是 P2，届时 `db.records` → `collections.records`，接口不变。
> **20 条上限**：所有按范围/全量拉取一律走 `db.listAllPaged`（内部分页），否则月记录 >20 条会被静默截断。

```
pages/index.refresh()
  → calendarService.getMonthView(year, month)
      [start,end] = date.monthRange(y,m)
      Promise.all:
        records  = db.records.listByRange(start,end)      // 内部走 listAllPaged，破 20 条上限
        schedule = db.scheduleItems.listAll()              // 课表量小，分页兜底
        logs     = db.readingLogs.listByRange(start,end)   // 内部走 listAllPaged
      events = [
        ...records.map(toRecordEvent),                     // 源1 直接事件
        ...scheduleService.expandToMonth(schedule, y, m),  // 源2 规则展开（P0 仅 weekly）
        ...toReadingEvent(logs, bookTitleMap),             // 源3 关联书名（批量取书名，非逐条查）
      ]
      byDay = groupBy(events, e=>e.date)
      cells = date.monthGrid(y,m).map(c => ({...c,
        dots: uniqueTypeColors(byDay[c.date]).slice(0,3), count:len }))
      return { cells, byDay }
  → setData({cells, dayEvents: byDay[selectedDate]})
  → 选中某天：直接读内存 byDay[date]（不重查库）
  → 封面延迟水合：仅当天 record 的 imageFileIds，经 getTempUrls（≤50 分片）批量换链接
```

### 3.2 书架 → 阅读打卡闭环（补上游数据）
```
pages/reading/book（新增书详情页）或书架卡片「打卡」入口
  → bottom-sheet 打卡表单（章节/页码/时长/心情/备注）
  → readingService.addCheckin(bookUuid, log):
        db.readingLogs.create({bookUuid, readDate, pageTo, durationMinutes, ...})
        logs = db.readingLogs.listByBook(bookUuid)          // 走分页
        status = readingService.nextStatus(book, logs)  // want→reading→done 写侧判定
        if 变化 → db.books.update(bookUuid,{status})     // 与写 log 是两次独立写，非事务
        emit(DATA_CHANGED,{collection:'reading_logs'})
  → 书架进度环 = readingService.deriveProgress(book, logs) 实时派生，不冗余存
```

### 3.3 阅读日志写入 + 日历展示
- 上游：3.2 打卡产生 `reading_logs`。
- 下游：`calendarService` 源3 拉 `readingLogs.listByRange(readDate)`，join `books` 取书名 → `toReadingEvent`（subtitle=`《书名》 20min`，color=`EVENT_TYPE_COLORS.reading`）→ 落到 `ymd(readDate)`。
- 顺序：**先 3.2 后 3.3**，无数据则日历第三源自然为空，不报错。

### 3.4 课外班日历推算（weekday + recurrence → 具体日期）

> **P0 现实收敛**：现有 `schedule/index.js` 新增课程时**只写 `recurrence` 缺省（等价 weekly）且 `startDate:null`**，数据库里不存在 biweekly/monthly/once 数据。因此 **P0 只实现 weekly**（覆盖 100% 存量数据，逻辑最简、零风险）；biweekly/monthly/once 与"生效起始日"表单一起放到 **P1**，`once` 甚至可用 `daily_records` 替代，未必需要。避免为不存在的数据写复杂且易错的推算。

```
scheduleService.expandToMonth(items, year, month):
  遍历当月每天 d：
    wd = date.weekdayOf(d.ts)   // 1~7
    for item in items:
      if item.weekday !== wd: continue
      // —— P0：只按 weekday 命中（recurrence 缺省=weekly）——
      // —— P1 追加有效期与周期判定 ——
      if item.startDate && d.ts < item.startDate: continue
      if item.endDate && d.ts > item.endDate: continue
      hit = !item.recurrence || item.recurrence==='weekly' ? true
          : item.recurrence==='biweekly' ? date.weekIndexSince(item.startDate, d.ts) % 2 === 0
          : item.recurrence==='once'     ? date.ymd(d.ts) === date.ymd(item.startDate)
          : /* monthly（P2，语义待产品确认）*/ false
      if hit: push CalendarEvent{type:'schedule', time:item.startTime,
                subtitle: [type标签, location, teacher].filter(Boolean).join(' · '), color:schedule色}
```
- 课表是"规则"不是"事件"，**按展示月份动态推算，不落库**。
- **P0 无需 `startDate`**：weekly 每周命中，与起始日无关。仅 P1 引入 biweekly/once 时才需要表单补"生效起始日"，届时缺失则该条降级为 weekly。
- **monthly 语义模糊**（"每月第 N 个周 X" vs "每月某日"）→ 产品确认前不实现，降到 P2。

---

## 4. 迁移 / 改造全量清单

### 4.1 文件级改动列表

| 优先级 | 文件 | 动作 | 说明 |
| --- | --- | --- | --- |
| **P0** | `services/calendar-service.js` | 新增 | 三源聚合核心 |
| **P0** | `services/schedule-service.js` | 新增 | 课表周期展开（**P0 仅 weekly**，逻辑十几行） |
| **P0** | `utils/date.js` | 修改 | 加 `weekdayOf(ts)`（1~7）即可满足 P0；`weekIndexSince`（P1）、`nthWeekdayOfMonth`（P2）随周期扩展再加 |
| **P0** | `utils/db.js` | 修改 | **新增 `listAllPaged` 破 20 条上限** + `getTempUrls` ≤50 分片；补 `scheduleItems`/`readingLogs` 业务方法 |
| **P0** | `utils/constants.js` | 修改 | 加 `EVENT_TYPE_COLORS` + 取色函数 |
| **P0** | `pages/index/index.js` | 修改 | refresh 改调 calendarService；onTapDay 读内存 |
| **P0** | `pages/index/index.wxml` | 修改 | 多彩点 + 三态事件列表 |
| **P1** | `services/reading-service.js` | 新增 | 打卡 + 状态跃迁 + 进度派生 |
| **P1** | `pages/reading/book/`（4 文件） | 新增 | 书详情 + 打卡历史 + 打卡弹层 |
| **P1** | `pages/reading/reading.js/.wxml` | 修改 | 加打卡入口，改调 readingService |
| **P1** | `pages/schedule/index.js/.wxml` | 修改 | 表单补 `startDate`；移除内联色值→走 constants；改调 collections |
| **P1** | `components/month-calendar/` | 新增 | 抽月历组件 |
| **P1** | `components/event-card/` | 新增 | 抽三态事件卡片 |
| **P1** | `components/bottom-sheet/` | 新增 | 抽弹层壳 |
| **P1** | `store/index.js` + `store/events.js` | 新增 | globalData 规范 + 事件常量 |
| **P1** | `services/report-service.js` | 新增 | 周报统计复用 calendar 口径 |
| **P1** | `pages/report/report.js` | 修改 | 改调 report-service（修"本周书籍"用 reading_logs 而非 books.updatedAt） |
| **P2** | `utils/collections.js` | 新增 | db.js 业务封装拆出 |
| **P2** | `utils/format.js` | 新增 | VM 组装统一 |
| **P2** | `components/book-card/`/`empty-state/`/`fab-button/` | 新增 | 二次复用组件 |
| **P2** | `pages/records/records.*` → `records/index.*` | 重命名 | 统一命名（改 app.json + 目录） |
| **P2** | `cloudfunctions/generateWeeklyReport/` | 新增 | 周报云端聚合 + 定时 |

### 4.2 优先级说明
- **P0（本轮必做，最短见效）**：让"课外班 + 成长记录"进日历。先接入源1+源2，第一步即可见课表出现在日历上。
- **P0 可再切两刀（小步快跑）**：
  - **P0-a（半天量）**：先只做 `db.listAllPaged` + `date.weekdayOf` + `calendar-service` 接入"记录+weekly课表"两源，日历 UI **暂沿用现有单点 `dotColor`**（取当天优先级最高事件的类型色），不动多彩点。**先跑通数据聚合正确性**。
  - **P0-b**：再把 `index.wxml` 升级为多彩点 + 三态事件列表。UI 改动与数据聚合解耦，降低一次性改动面。
- **P1（本轮完成）**：阅读打卡闭环 → 补齐日历第三源；抽核心组件与 store 规范；修周报口径；课表 biweekly/once + 生效起始日表单。
- **P2（后续迭代）**：命名统一、工具拆分、二级组件、周报云函数、monthly 周期。

### 4.3 云控制台操作说明
1. **确认集合存在**：数据库 →「+ 新建集合」补建 `reading_logs`、`series`（`weekly_reports` 待 P2）。否则首次查询报"集合不存在"。
2. **配置索引**：按 §2.3 索引表逐集合「索引管理」→「新建索引」，均非唯一复合索引。
3. **权限**：所有集合设「仅创建者可读写」。
4. **存量数据**：`schedule_items.startDate` 为空的走降级逻辑，无需批量刷数据。

---

## 5. 编码规范约定（一页纸）

### 5.1 命名
- **集合**：`snake_case` 复数 —— `daily_records`、`reading_logs`。
- **文件**：工具/服务 `kebab-case.js`；组件目录 `kebab-case/`。
- **变量**：`camelCase`；常量 `UPPER_SNAKE`（`EVENT_TYPE_COLORS`）；布尔 `is/has/should` 前缀。
- **方法**：动词开头 —— 取数 `get/list/load`，写 `create/update/remove/add`，计算 `compute/derive/expand`，判定 `is/has/hit`。
- **事件名**：集中在 `store/events.js`，禁止散落字符串字面量。
- **CalendarEvent.type**：固定枚举 `record`/`schedule`/`reading`。

### 5.2 错误处理
- **读操作**：service/db 层 `try/catch` 兜底返回空集合（`[]`/`null`），保证页面渲染空态，不抛给 UI（沿用现 db.js 风格）。
- **写操作**：`try/catch` 后**必须给用户反馈**（`wx.showToast`），并 `console.error` 打印完整错误（含 `errMsg`）便于定位（沿用 add.js 的分类提示：未登录/上传失败/无权限）。
- **登录态预检**：写操作前先 `auth.ownerId()` 判空，提前拦截并明确指引，不走到写库才报模糊错。
- **云函数缺失**：用 `auth.isCloudFunctionMissing(err)` 识别，给"请部署云函数"的可操作提示。

### 5.3 异步写法
- **统一 `async/await`**，禁止 `.then` 嵌套金字塔（现有 mine.js 的 `.then` 链建议逐步收敛）。
- **并行取数用 `Promise.all`**（日历三源、周报多集合）。
- **串行有依赖**才用 `await` 顺序（如打卡先写 log 再算 status）。
- 循环内 await（如批量上传）标注 `// eslint-disable-line no-await-in-loop` 并说明"串行避免限流"（沿用 db.uploadFiles）。

### 5.4 注释
- **文件头**：一行说明文件职责（沿用现有 `// pages/xxx —— 说明` 风格）。
- **函数**：公共 service/util 方法用 JSDoc 标注参数与返回（沿用 db.js 风格）。
- **业务约定**：关键决策就近注释"为什么"（如"课表规则动态推算不落库"、"进度 max(pageTo) 单一真相源"）。
- **脱敏**：示例/日志不得出现真实手机号等敏感信息（bindPhone 已用 maskPhone，沿用）。

---

## 6. 风险点与边界 case 清单

| 风险 | 等级 | 说明 | 对策 |
| --- | --- | --- | --- |
| **20 条查询上限截断** | 🔴 高 | 客户端 `.get()` 单次 ≤20；`records.listAll(100)` 实际只回 20，月聚合/列表丢数据且无报错 | `db.listAllPaged` 分页拉取；见 §2.3 能力边界 |
| **reading_logs 缺上游写入** | 🔴 高 | 集合已规划但无写入代码，日历第三源为空 | 先做 P1 打卡闭环（§3.2），再接第三源；未做前源3 返回空、不报错 |
| **childId 空值越权聚合** | 🟡 中 | 无孩子时 `create` 写 `childId:''`，`db.list` 遇空 childId **跳过过滤**返回该 owner 全部数据；未来多孩子会串数据 | ① 首启强制"先建孩子"再可记录；② `list` 对 `childId===''` 显式按 `''` 精确匹配而非跳过；③ 切孩子后强制 refresh |
| **课表推算复杂度** | 🟡 中 | biweekly/monthly 语义模糊、易错，且当前无数据 | P0 仅 weekly（覆盖全部存量）；复杂周期延后并先与产品对齐语义（§3.4） |
| **getTempFileURL 50 上限 + 链接时效** | 🟡 中 | 单次 ≤50 fileID；临时链接约 2h 过期 | 分批 ≤50；仅可见项延迟水合；过期重取 |
| **删书未级联日志** | 🟡 中 | 软删 book 后其 reading_logs 仍在，日历/统计出现"孤儿日志" | `readingService` 删书时批量软删关联 logs；聚合侧对 bookUuid 找不到书名做兜底展示 |
| **onShow 全量重拉性能** | 🟢 低 | 各页 `onShow` 无脑 refresh，切 tab 频繁查库 | 引入 `DATA_CHANGED` 事件后按需刷新（§2.8）；日历切天读内存不查库 |
| **date.endOfDay 命名误导** | 🟢 低 | `endOfDay` 实际返回**次日 0 点**（注释写 23:59:59.999），当前靠 `monthRange` 规避未触雷 | 统一"右开区间 `[start,end)`"语义；重命名 `startOfNextDay` 或修正注释，避免误用 |
| **schedule 内联硬编码色** | 🟢 低 | `schedule/index.wxml` 写死 `#8FC7F0/#FF8C42` | 收敛到 `constants.EVENT_TYPE_COLORS` + `app.wxss` 变量 |
| **云函数未部署** | 🟢 低 | login/bindPhone 未部署时静默登录失败 | 已有 `isCloudFunctionMissing` 识别 + 指引，保持 |

---

## 附：本轮落地顺序（一条龙）
1. `date.js`（`weekdayOf`）/`constants.js`（类型色）→ 2. db.js 补 **`listAllPaged`（破 20 条）** + `getTempUrls` 分片 + scheduleItems/readingLogs → 3. `calendar-service` + `schedule-service`（P0 仅 weekly，接入源1+源2，**课表进日历见效**，UI 先复用单点）→ 4. `index.wxml` 升级多彩点/三态列表 → 5. `reading-service` + 书详情打卡（产生 reading_logs）→ 6. calendar 接入源3 → 7. 抽 `bottom-sheet`/`event-card`/`month-calendar` 组件 + store 规范 → 8. report 改调 report-service 修口径。

> 不改动原则（保持不变）：同步三件套 + 双归属数据模型、`app.wxss` CSS 变量令牌、登录/绑手机链路、媒体 fileID + 临时链接方案、`date.monthGrid/monthRange`、极简事件总线（不引入重状态库）、暖橙马卡龙视觉规范。
