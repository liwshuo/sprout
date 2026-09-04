# Sprout 孩子成长记录 · 微信小程序版技术方案与数据模型设计

> 版本：v1.0　｜　适用范围：微信小程序端首发，Flutter App 后续接入，两端经 CloudBase 打通
> 基准对照：Flutter 现有 drift 本地库（`lib/data/local/app_database.dart`，schemaVersion=2）

---

## 0. 现状摘要（对照基准）

Flutter 端当前是**纯本地 SQLite（drift）单机应用**，核心特征：

- **单孩子 V1**：`Child` 表实际只存一行，各业务表**未挂 `childId`**，全局默认归属当前唯一孩子。
- **软删除 + 同步友好字段**：所有表均带 `uuid`（业务主键）、`updatedAt`、`isDeleted`。这三件套是做云同步/多端合并的天然基础——小程序端应完整继承。
- **7 张表 / 3 个域**：
  - 阅读域：`Series`（套书）1—N `Books`（书单）1—N `ReadingLogs`（打卡）
  - 日常/课表/周报：`DailyRecords`、`ScheduleItems`、`WeeklyReports`
  - 档案：`Child`
- **单一真相源原则**：进度不冗余存储（如「已读页 = max(pageTo)」聚合派生），周报 `summary` 为结构化 JSON 快照。这一原则在 CloudBase 侧继续沿用。

小程序版的核心增量目标：**引入账号体系 + 云端多设备同步 + 多孩子切换**，同时保持数据模型可与 Flutter 端无损映射。

---

## 1. 技术选型

### 1.1 前端框架：微信原生 vs uni-app

| 维度 | 微信原生小程序 | uni-app |
|------|--------------|---------|
| 首发速度 | 快（无构建层抽象） | 中（需搭脚手架） |
| 多端复用 | 仅微信 | 可一套码出微信/支付宝/H5/App |
| 与 CloudBase 集成 | **一等公民**，`wx.cloud` 原生 SDK 无缝 | 需引入插件，云开发能力有折损 |
| 生态/调试 | 官方工具链最稳 | 依赖社区插件质量 |
| 与后续 Flutter App 的关系 | 各自独立端，靠 CloudBase 打通 | 若想复用会与 Flutter 冲突（两套跨端方案） |

**推荐：微信原生小程序（TypeScript）**。理由：

1. 本项目后续「大端」已明确是 **Flutter App**，跨端复用价值不在小程序框架层，uni-app 的多端优势用不上，反而多一层抽象。
2. CloudBase 与原生小程序是深度绑定的最优组合，`wx.cloud` 调用云数据库/云存储/云函数零胶水。
3. 团队维护成本最低，官方工具链稳定。

> 工程规范建议：使用 **TypeScript + 原生小程序**，可选轻量框架 [Skyline 渲染引擎] 提升列表性能；样式统一用 rpx；目录按 `pages / components / models / services(cloud) / store` 分层。

### 1.2 后端：腾讯云 CloudBase（云开发）

采用 CloudBase 全家桶，**免服务器**：

- **云数据库（文档型，类 MongoDB）**：存业务数据，支持权限规则、索引、聚合。
- **云存储 COS**：存图片、语音等媒体文件，返回 `fileID`（云文件 ID）。
- **云函数（SCF）**：承载「不可信客户端不能直接做」的逻辑——手机号解密绑定、周报生成、批量迁移、跨集合聚合。
- **CloudBase Auth**：微信小程序端使用**微信授权登录**（`wx.cloud` 免鉴权换取 openid），无需自建登录态。

### 1.3 状态管理

小程序原生无 Riverpod。推荐**轻量方案，避免过度设计**：

- 首选 **MobX-miniprogram**（或 `westore` / `Pinia 风格的 tiny store`）做全局状态（当前登录用户、当前选中孩子、同步状态）。
- 页面级状态用 `Component` 的 `data` + `observers`。
- **不引入 Redux 级重方案**，本应用状态复杂度低。

全局 Store 至少维护：`currentUser`（openid/unionid）、`activeChildId`（当前孩子）、`children[]`（孩子列表）、`syncStatus`。

### 1.4 图片/媒体存储方案

- 客户端 `wx.chooseMedia` 选图 → `wx.cloud.uploadFile` 上传到云存储 → 得到 `fileID`。
- **数据库只存 `fileID` 数组**（对应 drift 的 `imagePaths` JSON），不存临时 URL。
- 展示时用 `wx.cloud.getTempFileURL` 批量换临时链接（带缓存，2 小时有效）。
- 语音：`wx.getRecorderManager` 录制 → 上传 COS → 存 `fileID`；语音转文字走云函数调用 ASR，写回 `note`（对应现有 `source='voice'`）。
- 存储路径约定：`{openid}/{childId}/{yyyyMM}/{uuid}.{ext}`，便于按用户/孩子做配额与清理。

---

## 2. 账号体系设计

### 2.1 身份标识分层

| 标识 | 来源 | 作用 |
|------|------|------|
| `openid` | 微信授权（当前小程序内唯一） | 小程序端用户唯一标识、数据归属主键 |
| `unionid` | 同一微信开放平台账号下跨应用唯一 | **打通小程序与未来 App/公众号的关键**，若已绑开放平台优先用它 |
| `phone` | 手机号快速验证组件 | 跨端账号绑定锚点、找回、多设备识别 |

**设计要点**：数据归属统一用 **`ownerId`**（登录后解析：优先 `unionid`，无则 `openid`）。这样 Flutter App 端只要拿到同一 `unionid`/`phone`，即可访问同一份云数据。

### 2.2 登录流程

1. 首次进入：`wx.cloud` 自动携带用户身份，云函数 `login` 解析 openid/unionid，`upsert` 到 `users` 集合。
2. 手机号绑定（可选、引导式）：使用微信「手机号快速验证」按钮 → 云函数解密 `phoneNumber` → 写入 `users.phone`。**手机号是后续 Flutter App 登录打通的锚点**（App 端可走手机号验证码登录，用 phone 关联到同一 `ownerId`）。
3. 登录态：小程序无需维护 token，每次云调用自带身份；App 端用 CloudBase 自定义登录 / 手机号登录换取同一账户。

### 2.3 多孩子切换逻辑（对比 Flutter 单孩子的关键升级）

Flutter V1 是单孩子且业务表无 `childId`。小程序端**从一开始就设计为多孩子**：

- `children` 集合按 `ownerId` 存多条；全局 Store 持有 `activeChildId`。
- **所有业务集合新增 `childId` 字段**（见 §3），查询一律带 `where({ ownerId, childId: activeChildId })`。
- 顶部提供孩子切换器（头像下拉），切换即改 `activeChildId` 并刷新当前页数据。
- 切换是纯前端过滤，不涉及数据迁移。
- 与 Flutter 打通时：Flutter 单孩子数据上传时统一挂到用户的**默认孩子**（首个 child），未来 Flutter 升级多孩子后字段已就位。

---

## 3. CloudBase 云数据库模型设计

### 3.1 通用约定

- 每个文档统一含**同步三件套**：`uuid`(String, 业务唯一键，对齐 drift)、`updatedAt`(Number, 毫秒时间戳)、`isDeleted`(Boolean, 软删)。
- 统一归属字段：`ownerId`(String)；业务集合再加 `childId`(String, 指向 `children.uuid`)。
- **主键策略**：用 drift 的 `uuid` 作为跨端稳定主键；CloudBase 自动 `_id` 仅内部使用。**放弃 drift 的自增 `id`**（自增 id 在多端不唯一，同步会冲突）。
- 时间字段：drift 的 `DateTime` → 云端统一存**毫秒时间戳 Number**（时区无关，比较/排序稳）。
- 关系字段：drift 用外键 `id` 关联，云端改用**被引对象的 `uuid`**（如 `Books.seriesId` → `seriesUuid`）。

### 3.2 集合清单（8 个）

#### `users`（新增，小程序特有）
| 字段 | 类型 | 说明 |
|------|------|------|
| `_id` | String | 云自动 |
| `ownerId` | String | = unionid 优先，否则 openid，全局归属键 |
| `openid` | String | 微信 openid |
| `unionid` | String? | 开放平台唯一，跨端打通 |
| `phone` | String? | 绑定手机号（云函数解密写入） |
| `nickname` | String? | 昵称 |
| `avatar` | String? | 头像 fileID |
| `createdAt` / `updatedAt` | Number | 时间戳 |

> 索引：`ownerId`(唯一)、`unionid`、`phone`。

#### `children`（对照 `Child`）
| 字段 | 类型 | 说明 / drift 对照 |
|------|------|------|
| `uuid` | String | ← `Child.uuid` |
| `ownerId` | String | 归属用户 |
| `name` | String | ← `name` |
| `birthDate` | Number? | ← `birthDate`（时间戳） |
| `avatarFileId` | String? | ← `avatarPath`（改存云 fileID） |
| `sortOrder` | Number | 新增，切换器排序 |
| `updatedAt` / `isDeleted` | Number / Bool | 同步三件套 |

> 索引：`ownerId`、`uuid`(唯一)。

#### `daily_records`（对照 `DailyRecords`）
| 字段 | 类型 | 说明 / drift 对照 |
|------|------|------|
| `uuid` | String | ← `uuid` |
| `ownerId` / `childId` | String | 归属（childId 为新增） |
| `title` | String | ← `title` |
| `note` | String? | ← `note` |
| `tags` | Array\<String\> | ← `tags`（drift 存 JSON 字符串，云端存原生数组） |
| `imageFileIds` | Array\<String\> | ← `imagePaths`（本地路径 → 云 fileID） |
| `category` | String? | ← `category` |
| `mood` | String? | ← `mood` |
| `source` | String | manual/voice/timer ← `source` |
| `eventDate` | Number | ← `eventDate`（聚合主键，日历/周报按此） |
| `durationMinutes` | Number? | ← `durationMinutes` |
| `createdAt` / `updatedAt` / `isDeleted` | | 同步字段 |

> 索引：复合 `{ownerId, childId, eventDate}`（日历按天/周聚合）、`{ownerId, childId, updatedAt}`（增量同步）。

#### `series`（对照 `Series`）
| 字段 | 类型 | 说明 |
|------|------|------|
| `uuid` | String | ← `uuid` |
| `ownerId` / `childId` | String | 归属 |
| `name` | String | ← `name` |
| `totalVolumes` | Number | ← `totalVolumes` |
| `updatedAt` / `isDeleted` | | 同步 |

> 已读完册数**不存**，实时聚合 `count(books where seriesUuid=X and status='done')`（沿用单一真相源）。

#### `books`（对照 `Books`）
| 字段 | 类型 | 说明 / 对照 |
|------|------|------|
| `uuid` | String | ← `uuid` |
| `ownerId` / `childId` | String | 归属 |
| `title` / `author` / `cover` / `isbn` | String? | 同名对照（`cover` 改存 fileID） |
| `status` | String | want/reading/done ← `status` |
| `totalPages` / `totalChapters` | Number? | 同名 |
| `seriesUuid` | String? | ← `seriesId`（改引 uuid；删套书时置空=降级为独立书） |
| `seriesIndex` | Number? | ← `seriesIndex` |
| `updatedAt` / `isDeleted` | | 同步 |

> 索引：`{ownerId, childId, status}`、`seriesUuid`。

#### `reading_logs`（对照 `ReadingLogs`）
| 字段 | 类型 | 说明 / 对照 |
|------|------|------|
| `uuid` | String | ← `uuid` |
| `ownerId` / `childId` | String | 归属 |
| `bookUuid` | String | ← `bookId`（改引 uuid，删书级联软删） |
| `readDate` | Number | ← `readDate` |
| `chapter` / `chapterIndex` | String? / Number? | ← 同名 |
| `pageFrom` / `pageTo` | Number? | ← 同名（进度 = max(pageTo)） |
| `durationMinutes` | Number | ← 同名 |
| `mood` / `note` / `source` | String? / String | ← 同名 |
| `updatedAt` / `isDeleted` | | 同步 |

> 索引：`{ownerId, childId, bookUuid}`、`{ownerId, childId, readDate}`。

#### `schedule_items`（对照 `ScheduleItems`）
| 字段 | 类型 | 说明 / 对照 |
|------|------|------|
| `uuid` | String | ← `uuid` |
| `ownerId` / `childId` | String | 归属 |
| `courseName` | String | ← 同名 |
| `type` | String | school/extra ← 同名 |
| `location` / `teacher` | String? | ← 同名 |
| `weekday` | Number | 1–7 ← 同名（多选周几仍拆多行，沿用现规则） |
| `recurrence` | String | weekly/biweekly/monthly/once ← 同名 |
| `startTime` / `endTime` | String | "HH:mm" ← 同名 |
| `startDate` / `endDate` | Number? | ← 同名（时间戳） |
| `updatedAt` / `isDeleted` | | 同步 |

> 索引：`{ownerId, childId, weekday}`。

#### `weekly_reports`（对照 `WeeklyReports`）
| 字段 | 类型 | 说明 / 对照 |
|------|------|------|
| `uuid` | String | ← `uuid` |
| `ownerId` / `childId` | String | 归属 |
| `weekStart` / `weekEnd` | Number | ← 同名 |
| `summary` | Object | ← `summary`（drift 存 JSON 串，云端存原生对象） |
| `aiText` / `editedText` | String? | ← 同名 |
| `status` | String | draft/published ← 同名 |
| `dailyCount` / `readingCount` / `readingMinutes` / `extraClassCount` / `activeDays` | Number | ← 同名快照统计 |
| `generatedAt` / `updatedAt` / `isDeleted` | | 同步 |

> 索引：`{ownerId, childId, weekStart}`。

### 3.3 与 Flutter App 数据打通的映射关系

| 主题 | Flutter drift | CloudBase | 转换说明 |
|------|--------------|-----------|----------|
| 主键 | 自增 `id` + `uuid` | 以 `uuid` 为跨端主键 | 上传按 `uuid` upsert；自增 id 各端本地自管，不上传 |
| 关系引用 | 外键存被引 `id` | 存被引 `uuid` | 上传时把 `seriesId/bookId` 换成对应 `uuid` |
| 时间 | `DateTime` | `Number`(ms) | `dateTime.millisecondsSinceEpoch` ↔ `DateTime.fromMillis` |
| JSON 列 | `tags/imagePaths` 存字符串 | 原生 Array | 上传解析、下载序列化 |
| 媒体 | 本地文件路径 | 云 `fileID` | 上传文件换 fileID；下载时下拉文件到本地缓存目录 |
| 归属 | 无 childId（单孩子） | `ownerId + childId` | Flutter 上传统一挂默认孩子；下行忽略/透传 |
| 软删 | `isDeleted` | `isDeleted` | 完全一致，直接映射 |
| 增量 | `updatedAt` | `updatedAt` | 用于双端 LWW（后写覆盖）合并 |

> 结论：drift 的字段与 CloudBase 集合**几乎一一对应**，差异集中在「关系引用改 uuid、时间改时间戳、JSON 转原生、媒体转 fileID、新增归属字段」5 类，均可用一层纯函数 mapper 处理，无结构性障碍。

---

## 4. 核心页面与功能模块划分

对照 Flutter 现有路由（底部 4 Tab：`/calendar` `/records` `/reading` `/mine`）：

### 4.1 日历（对照 `CalendarPage` / `DayDetailPage`）
- 小程序页：`pages/calendar/index`（月视图，`vant-weapp` 或自绘日历）+ `pages/calendar/day`（某日详情）。
- 数据：按 `eventDate` 聚合 `daily_records`，日历格子按 `category` 着色（沿用现逻辑）。
- 点某天进详情，列出当日记录，支持编辑/删除（软删）。

### 4.2 记录 + 计时（对照 `RecordsPage` / `QuickAddSheet` / `TimerPage`）
- 页：`pages/records/index`（列表）+ 底部弹层 `quick-add`（文字/图片/语音快速记）+ `pages/timer/index`（计时器）。
- 快速记录写 `daily_records`，`source` 区分 manual/voice/timer。
- 计时结束把 `durationMinutes` 落库；语音走「录音→上传→ASR 云函数→回填 note」。

### 4.3 阅读书架（对照 `BookshelfPage` / `BookDetailPage` / `ReadingCheckinSheet`）
- 页：`pages/reading/shelf`（书架，按 status 分组，套书折叠）+ `pages/reading/book`（书详情+打卡历史）+ `checkin` 弹层。
- `books.status` 自动跃迁（want→reading→done）逻辑放**云函数或客户端写侧**，与 drift 的 `ReadingRepository.addLog` 判定一致。
- 进度实时聚合 `max(pageTo)` / `max(chapterIndex)`，不冗余存。
- 扫码录书：`wx.scanCode` 得 ISBN → 云函数查书源填充 title/author/cover。

### 4.4 我的 / 周报（对照 `ProfilePage` 下挂 `SchedulePage` / `ReportListPage` / `SettingsPage`）
- 页：`pages/mine/index`（含孩子切换器、登录/绑手机入口）。
- 下挂：`pages/schedule/index`（课表，按 weekday 网格；多选周几拆多行落库）、`pages/report/list` + `pages/report/detail`（周报）、`pages/settings/index`。
- **周报生成**：建议放**云函数** `generateWeeklyReport`（定时触发器每周日跑，或用户手动触发），聚合当周 `daily_records`/`reading_logs`/`schedule_items` 生成 `summary` 快照 + 可选 AI 文案，写 `weekly_reports`。与 Flutter 的 `report_generator.dart` / `report_scheduler.dart` 输出结构对齐。

---

## 5. Flutter App 数据迁移方案

场景：用户先用小程序，后续下载 Flutter App；或反向（App 已有本地数据后接入云）。

### 5.1 首次接入云的全量上传（App 本地 → CloudBase）
1. App 登录拿到 `ownerId`（手机号/unionid 关联到同一账户）。
2. 遍历 drift 7 张表，经 mapper 转换（见 §3.3），按 `uuid` **批量 upsert** 到云端对应集合，统一挂默认 `childId`。
3. 媒体文件：本地路径逐个 `uploadFile` 换 fileID 回填。
4. 上传采用**分批 + 断点续传**：记录本地 `lastSyncedAt`，失败可重入（幂等，靠 uuid upsert）。

### 5.2 双向增量同步（稳态）
- **拉取**：`where(updatedAt > lastPullAt)` 增量下行，含软删记录。
- **推送**：本地 `updatedAt > lastPushAt` 的脏记录上行。
- **冲突策略**：LWW（Last-Write-Wins，比较 `updatedAt`，后写覆盖），字段级冲突罕见可整条覆盖；`isDeleted=true` 优先级最高（删除幂等）。
- 媒体：只在 fileID 变化时重传。

### 5.3 反向（云 → App 首装）
- App 首次登录若本地库为空，全量下行云端数据 → 经反向 mapper 写入 drift（时间戳转 DateTime、fileID 下载到本地缓存、uuid 保留、childId 折叠为单孩子或透传）。

### 5.4 关键保障
- **幂等**：一切以 `uuid` 为准，重复同步不产生脏数据。
- **软删一致**：两端都用 `isDeleted`，不做物理删，保证删除能同步。
- **迁移不可逆风险控制**：首次全量上传前本地备份 sqlite 文件。

---

## 6. 开发路径与里程碑

| 阶段 | 目标 | 主要产出 | 预估工作量 |
|------|------|---------|-----------|
| **M0 基建** | CloudBase 环境 + 账号体系 | 环境初始化、`users`/`children` 集合、微信登录云函数、手机号绑定、多孩子切换 Store | ~3–4 人日 |
| **M1 记录闭环** | 日历 + 记录 + 计时 | `daily_records` CRUD、日历聚合、快速记录弹层、图片/语音上传、计时器 | ~5–6 人日 |
| **M2 阅读域** | 书架 + 打卡 | `series`/`books`/`reading_logs`、状态跃迁、进度聚合、ISBN 扫码录书 | ~4–5 人日 |
| **M3 课表 + 周报** | 课表 + 周报 | `schedule_items` 课表网格、周报生成云函数（聚合+AI文案）、周报列表/详情 | ~4–5 人日 |
| **M4 打磨上线** | 体验 + 提审 | 全局 loading/空态、临时链接缓存、性能（Skyline/长列表）、隐私协议、微信提审 | ~3–4 人日 |
| **M5 App 打通** | 同步能力（与 Flutter 端联调） | mapper 层、全量上传、双向增量同步、LWW 合并、迁移工具 | ~5–7 人日 |

> **建议排期**：M0–M4 为小程序独立可上线闭环（约 4 周），M5 待 Flutter App 侧账号打通就绪后并行推进。

### 附：落地优先级建议
1. 先跑通 **M0 + M1**，产出「能记录、能看日历、多孩子切换」的可用 MVP，验证 CloudBase 链路与账号模型。
2. M5 同步能力的**数据模型在 M0 就已就位**（uuid/updatedAt/isDeleted/ownerId/childId 全表预埋），后期只补 mapper 与同步引擎，不改表结构——这是本方案把「打通成本」前置消化的关键设计。

---

*文档基于 Flutter 现有 drift schema（v2）逐表对照生成，字段映射可直接用于后续 mapper 编码。*
