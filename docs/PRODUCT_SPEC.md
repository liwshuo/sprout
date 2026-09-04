# Sprout 产品需求文档（PRODUCT_SPEC）

> 孩子成长记录 App —— 记录日常、阅读打卡、课表管理与周报生成。
> 本文档记录当前功能全貌，作为后续开发的**唯一真相源**（Single Source of Truth）。任何功能变动都应同步更新本文档与 `CHANGELOG.md`。

---

## 1. 项目简介

Sprout（暖橙小芽）是一款面向家长的**孩子成长记录**移动应用，用轻量、温馨的方式沉淀孩子的日常点滴，并自动汇总为成长周报。核心理念：

- **随手记**：文字 / 照片 / 心情 / 标签，一键记录成长瞬间。
- **阅读陪伴**：书架管理 + 阅读打卡，进度自动派生。
- **课表管理**：学校课表 + 课外班周期规则，一目了然。
- **自动周报**：每周日自动汇总当周成长足迹，空周不生成。
- **单孩子档案**：V1 聚焦单个孩子，围绕其成长构建全部数据。

---

## 2. 技术栈

| 维度 | 选型 |
| --- | --- |
| 框架 | Flutter（Dart SDK `>=3.3.0 <4.0.0`） |
| 状态管理 | flutter_riverpod `^2.5.1` |
| 路由 | go_router `^13.0.0`（StatefulShellRoute 多分支） |
| 本地存储 | drift `^2.18.0` + sqlite3_flutter_libs（SQLite） |
| 轻量偏好 | shared_preferences `^2.2.3` |
| 图片 | image_picker `^1.1.2` |
| 后台任务 | workmanager `^0.10.0`（周报调度） |
| 网络 | dio `^5.4.3+1`（预留 LLM 接入） |
| 日历组件 | table_calendar `^3.1.2` |
| 通知 / 分享 / 权限 | flutter_local_notifications、share_plus、permission_handler |
| 语音 / 扫码 | speech_to_text、mobile_scanner（依赖已引入，功能待落地） |
| 国际化 | intl `^0.20.2` + flutter_localizations（中文 locale） |

**数据架构核心原则**：单一真相源。书籍进度不冗余存储，实时由 `ReadingLogs` 聚合派生；周报以 `weekStart` 唯一去重、幂等生成。

**数据表**（drift，schemaVersion = 2）：`Series`（套书）、`Books`（书单）、`ReadingLogs`（打卡明细）、`DailyRecords`（日常）、`ScheduleItems`（课表）、`WeeklyReports`（周报）、`Child`（孩子档案）。软删除（`isDeleted`）+ 外键级联（打开连接时强制 `PRAGMA foreign_keys = ON`）。

---

## 3. 应用结构与导航

- **入口守卫**：未建孩子档案 → 强制进 Onboarding；已建档 → 进主界面（默认 `/calendar`）。
- **底部导航**：4 个 Tab（日历 / 记录 / 阅读 / 我的），采用 `StatefulShellRoute.indexedStack` 保持各分支独立返回栈。
- **中间 FAB**：底部栏正中悬浮「+」快速记录按钮，仅在 4 个 Tab 根页面展示。
- **二级页面**：全屏路由（如日详情、书详情、课表、周报、设置），进入后隐藏底部 Tab；返回由分支 Navigator 承接，不会误退出 App。

```
/onboarding                     建档引导（顶层，无底部栏）
/calendar                       日历 Tab
  └─ day/:date                  某日成长足迹详情
/records                        记录 Tab
  └─ timer                      活动计时器（入口已移除，路由保留）
/reading                        阅读 Tab（书架）
  └─ book/:id                   书籍详情
/mine                           我的 Tab
  ├─ schedule                   课表管理
  ├─ reports                    成长周报列表
  │   └─ :id                    周报详情
  └─ settings                   设置
```

---

## 4. 功能模块

### 4.1 日历记录（日历 Tab）— 已实现

- **首页问候头部**：`Hi，{昵称}妈妈 👋` + 副标题 + 🐣 头像；右上角「回到今天」快捷键。
- **月历视图**：table_calendar，支持月 / 周切换，周一为每周首日；当天出现的分类去重后以彩色圆点标记（最多 3 个）。
- **图例**：日常 / 阅读 / 课表 / 运动 / 才艺 分类色说明。
- **当日成长足迹**：选中日期下方按创建时间倒序展示当天记录卡片（时间轴样式），点击进入该日详情页。
- **空态兜底**：当天无记录时展示「这一天还没有记录」引导。

### 4.2 日常记录（记录 Tab）— 已实现

- **时间轴列表**：按 `eventDate` 分组倒序（今天 / 昨天 / 具体日期），组内按创建时间倒序。
- **分类筛选**：顶部横向 Chip（全部 / 日常 / 阅读 / 运动 / 才艺 / 出行 / 情绪 / 里程碑）。
- **快速录入**：右下角「记一笔」FAB 打开 `QuickAddSheet`（文字 + 多图 + 心情 + 标签 + 日期）。记录只用标签分类，`category` = 首个选中标签，仅用于日历/周报着色，无独立「类型」维度。
- **图片缩略图**：记录卡片支持展示图片缩略图。
- **空态兜底**：无记录 / 筛选无结果时引导「记一笔」。

### 4.3 阅读书架（阅读 Tab）— 已实现

- **三分区**：在读 / 想读 / 已读，分段切换并显示各区数量。
- **书籍卡片**：书脊渐变封面 + 书名 + 作者 + 状态徽章 + 打卡次数/时长 + 进度环。进度全部由 `BookShelfService` 聚合派生，页面不直接读书籍进度字段。
- **添加书籍**：底部弹层手填书名（必填）+ 作者（选填）；扫码识别为次要入口，V1 默认手填，套书按独立书处理。
- **阅读打卡**：`ReadingCheckinSheet` 记录章节/页码、时长、心情、备注；状态自动跃迁（want → reading → done）在写侧判定。
- **书籍详情**：`/reading/book/:id` 展示单本书打卡历史与进度。
- **空态兜底**：各分区独立空态文案。

### 4.4 课表管理（我的 → 课表）— 已实现

- **学校课表周网格**：上午 / 下午 × 工作日（默认周一~周五，有周末课程则并入）；格子内课程 Chip 按课程名稳定取色。
- **课外班周期卡片**：圆形 emoji 头像（按课程名智能匹配）+ 课程名 + 周期规则（每周/隔周/每月/单次）+ 地点/老师 + ⋯ 删除菜单。
- **添加课程**：全局复用底部弹层（课表页 + 中间 FAB 共用），支持类型（学校/课外班）、多选星期、起止时间、地点、老师；多选周几落库时拆成多行。
- **空态兜底**：无课程时引导添加。

### 4.5 我的 / 周报（我的 Tab）— 已实现

- **孩子档案卡**：头像 + 昵称 + 年龄（按生日计算「X 岁 Y 个月」）；点击进入建档/编辑。
- **功能入口**：课表管理 / 成长周报 / 设置。
- **成长周报**：
  - 列表页展示每周汇总卡片（记录数 / 阅读数 / 阅读分钟 / 课外班数 / 活跃天数）+ 草稿/已发布状态。
  - **自动调度**：每周日 20:00 通过 workmanager 后台聚合当周成长并落库；空周不生成；以 `weekStart` 唯一去重、幂等生成，可补偿。
  - AI 文案预留：`ReportGenerator` 保留 API Key 接入 LLM，无 Key 时走本地模板降级，不阻断生成；`aiText` 存 AI 原文，`editedText` 存家长编辑版。
  - 详情页 `/mine/reports/:id` 展示单份周报。
- **设置**：通知 / 周报时间 / 数据等入口。

### 4.6 快速记录 FAB — 已实现

- 底部栏正中悬浮「+」，弹出快速记录选择：
  - **📝 记一笔日常** → `QuickAddSheet`
  - **📖 记录阅读** → 跳转书架挑书打卡
  - **🏫 添加课程** → 打开添加课程弹层
- 仅在 4 个 Tab 根页面展示，二级页面隐藏。

### 4.7 建档引导（Onboarding）— 已实现

- 首次启动强制建立孩子档案（昵称、生日等），完成后放行主界面。

---

## 5. 暂未实现 / 已移除入口的功能清单

| 功能 | 状态 | 说明 |
| --- | --- | --- |
| 活动计时器（TimerPage） | **入口已移除，路由保留** | `/records/timer` 路由与页面仍在，UI 入口已下线；`DailyRecords`/`ReadingLogs` 保留 `source='timer'` 口径 |
| 语音识别记录 | **待开发** | speech_to_text 依赖已引入，`source='voice'` 口径已预留，功能未落地 |
| 扫码识别书籍 | **待开发（次要入口）** | mobile_scanner + ISBN 工具已备，V1 默认手填书名 |
| 调课 / 停课 | **待开发** | 课表当前仅支持增删整门课，暂无单次调课/停课 |
| AI 周报文案 | **预留接口** | 无 API Key 时走本地模板降级 |
| 通知提醒 | **部分预留** | flutter_local_notifications 已引入，围绕周报/提醒场景待完善 |
| 分享周报 | **预留** | share_plus 已引入 |
| 深色模式 | **降级处理** | V1 仅浅色，深色主题降级为浅色以保持暖橙风格一致 |
| 多孩子档案 | **未规划** | V1 单孩子只存一行 |

---

## 6. App 风格规范（暖橙马卡龙）

设计令牌集中于 `lib/core/theme/`，**页面/组件不得内联硬编码色值或圆角**，统一走 `AppColors` / `AppTheme` / `Theme.of(context)`。

### 6.1 配色

| 语义 | 色值 | 用途 |
| --- | --- | --- |
| 背景 bg | `#FFF9F0` | 全局背景（暖米） |
| 卡片 card | `#FFFFFF` | 卡片/表面 |
| 主色 primary | `#FFB84C` | 暖橙主色 |
| primaryDeep | `#F59E2E` | 深橙（强调/选中） |
| primarySoft | `#FFE7BF` | 浅橙（底色/凹槽） |
| 薄荷 mint | `#7ED9C3` | 辅助（阅读色） |
| 天空 sky | `#8FC7F0` | 辅助（课表色） |
| 粉 pink | `#FF9EB5` | 辅助（运动/情绪） |
| 丁香 lilac | `#B7A5F0` | 辅助（才艺） |
| 文字 ink | `#4A4038` | 主文字（暖棕） |
| inkSoft | `#9A8F82` | 次要文字 |
| 描边 line | `#F0E7D8` | 分隔/描边 |
| 阴影 shadow | `rgba(180,140,70,.15)` | 卡片柔和阴影 |

- **分类色映射**：日常→橙、阅读→薄荷、课表/出行→天空、运动/情绪→粉、才艺→丁香、里程碑→深橙、其他→灰；未知分类降级为暖橙。
- **心情 emoji**：happy 😄 / calm 😊 / excited 🤩 / tired 😪 / upset 😣。

### 6.2 形状与圆角

| Token | 值 | 用途 |
| --- | --- | --- |
| radiusCard | 26 | 卡片 |
| radiusButton | 18 | 按钮 |
| radiusChip | 14 | Chip |
| 输入框 | 16 | InputDecoration |
| BottomSheet | 30（顶部圆角） | 底部弹层 |

### 6.3 字体与组件风格

- 字重偏重：标题 `w800`，正文/标签 `w700`，营造卡通温馨感。
- Material 3，`useMaterial3: true`，AppBar 无阴影、左对齐大标题。
- 底部导航：自定义 `BottomAppBar` + 中间凹槽（CircularNotchedRectangle）承接悬浮 FAB。
- 卡片统一柔和阴影、无 surfaceTint。

---

## 7. 目录结构（lib/）

```
lib/
├── main.dart / app.dart              入口 + App 骨架
├── core/
│   ├── theme/                        AppColors / AppTheme（设计令牌）
│   ├── router/                       app_router（go_router）/ main_shell（底部栏+FAB）
│   ├── providers/                    shared_prefs 等全局 Provider
│   ├── onboarding/                   建档状态控制
│   ├── timer/                        计时会话（持久化）
│   ├── scanner/                      ISBN 工具
│   └── utils/                        date_util / record_display / id_util
├── data/
│   ├── local/                        app_database（drift schema + 迁移）
│   └── repositories/                 daily / reading / schedule / report / series / child
├── domain/
│   ├── bookshelf/                    BookShelfService（进度聚合派生）
│   └── report/                       ReportGenerator + ReportScheduler
├── features/
│   ├── onboarding/  calendar/  records/  reading/
│   ├── schedule/    profile/   report/   settings/  timer/
└── shared/widgets/                   通用组件（SoftCard / EmptyPlaceholder / 输入组件等）
```
