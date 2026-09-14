# Sprout 产品需求文档（PRODUCT_SPEC）

> 孩子成长记录 App —— 记录日常、阅读打卡、课表管理与周报生成。
> 本文档记录当前功能全貌，作为后续开发的**唯一真相源**（Single Source of Truth）。任何功能变动都应同步更新本文档与 `CHANGELOG.md`。
>
> **端说明**：本项目含两端实现 —— ①「大端」Flutter App（下文 §2~§7 的技术栈/结构/目录均指 Flutter 端）；②微信小程序端（`miniprogram/`，与 App 经 CloudBase 打通）。**小程序端的分层架构、集合设计、服务/组件规范见 §8 及独立文档 [`miniprogram_architecture_design.md`](./miniprogram_architecture_design.md)**（架构唯一真相源）。

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
- **月历视图**：table_calendar，支持月 / 周切换，周一为每周首日；当天出现的分类去重后以彩色圆点标记（最多 4 个）。
- **四源综合视图**：日历同时聚合展示 **课程 / 待办 / 成长记录 / 阅读打卡** 四类事项（每天最多 4 个圆点：橙=成长记录、蓝=课程、紫=待办、绿=阅读打卡），点击某天在下方以统一事件卡片展开当天各类详情。
- **图例**：成长记录（橙）/ 课程（蓝）/ 待办（紫）/ 阅读打卡（绿）分类色说明。
- **当日综合安排**：选中日期下方按「记录→课表→待办→阅读」顺序展示当天事件卡片（时间轴样式）；待办已完成时标题划线置灰并显示 ✅。
- **空态兜底**：当天无安排时展示「这一天还没有安排」引导。

### 4.2 日常记录（记录 Tab）— 已实现

- **时间轴列表**：按 `eventDate` 分组倒序（今天 / 昨天 / 具体日期），组内按创建时间倒序。
- **分类筛选**：顶部横向 Chip（全部 / 日常 / 阅读 / 运动 / 才艺 / 出行 / 情绪 / 里程碑）。
- **快速录入**：右下角「记一笔」FAB 打开 `QuickAddSheet`（文字 + 多图 + 心情 + 标签 + 日期）。记录只用标签分类，`category` = 首个选中标签，仅用于日历/周报着色，无独立「类型」维度。
- **图片缩略图**：记录卡片支持展示图片缩略图。
- **空态兜底**：无记录 / 筛选无结果时引导「记一笔」。

### 4.3 阅读书架（阅读 Tab）— 已实现

- **三分区**：在读 / 想读 / 已读，分段切换并显示各区数量。
- **书籍卡片**：书脊渐变封面 + 书名 + 作者 + 状态徽章 + 打卡次数/时长 + 进度环。进度全部由 `BookShelfService` 聚合派生，页面不直接读书籍进度字段。
- **添加书籍**：右下角「＋」弹出**添加方式选择**（精选书库 / 手动录入 / 扫码添加 / 新建系列）。
  - **精选书库**（已落地）：点「📚 精选书库」进入书库浏览页，分龄挑书一键加入书架，详见 §4.8。
  - **手动录入**：底部弹层手填书名（必填）+ 作者（选填）。
  - **扫码录入**（小程序端已落地）：`wx.scanCode` 扫图书条码 → 校验 13 位 + 978/979 前缀 → 调云函数 `bookLookup`（探数 tanshu 主源 + Google Books 兜底）→ 弹出「扫码确认弹层」预填书名/作者/封面/总页数，可编辑后保存；封面走外链 `coverExternalUrl`（不落云存储）。非法条码或查询失败自动转手填。
- **系列书面板**（套书，已落地）：书架把同一 `seriesUuid` 的书聚合为**系列卡片**（三层叠层封面 + 右上「系列」徽标 + 底部「已读 x/y」进度条）；点开进入系列面板，按 `seriesIndex` 升序列出各分册（册序 · 书名 · 状态角标 · 打卡），面板内可直接打卡（打卡后面板保持打开并刷新）与「＋ 添加分册」。
- **阅读打卡**：`ReadingCheckinSheet` 记录章节/页码、时长、心情、备注；状态自动跃迁（want → reading → done）在写侧判定。
- **书籍详情**：`/reading/book/:id` 展示单本书打卡历史与进度。
- **空态兜底**：各分区独立空态文案。

### 4.4 课表管理（我的 → 课表）— 已实现

- **学校课表周网格**：上午 / 下午 × 工作日（默认周一~周五，有周末课程则并入）；格子内课程 Chip 按课程名稳定取色。
- **课外班周期卡片**：圆形 emoji 头像（按课程名智能匹配）+ 课程名 + 周期规则（每周/隔周/每月/单次）+ 地点/老师 + ⋯ 删除菜单。
- **添加课程**：全局复用底部弹层（课表页 + 中间 FAB 共用），支持类型（学校/课外班）、多选星期、起止时间、地点、老师；多选周几落库时拆成多行。
- **空态兜底**：无课程时引导添加。

### 4.5 我的 / 周报（我的 Tab）— 已实现

- **mine 页信息架构**：从上到下为 ①顶部一体主卡（孩子主区 + 分割线 + 家长副区，合并为一张卡）→ ②统计双列卡 → ③功能菜单（iOS 风格纯列表）→ ④页脚。统计数字**只在统计卡展示**，主卡内不再重复展示「已读 N 本 · 打卡 N 次」，避免与统计卡数字重复。整页背景 `#FFF8F3`、卡片白底大圆角 `16px`（32rpx）+ 柔和阴影 `0 2px 12px rgba(255,140,66,.08)`，左右边距统一 28rpx 对齐。
- **① 一体主卡（`child-main-card`）**：
  - **孩子主区**：以当前 `activeChild` 档案呈现 —— 左侧圆形头像（有 `avatarFileId` 换取临时链接展示，无则按性别 emoji 兜底）、右侧名字（`_displayName`）+ 年龄/年级（「X 岁 Y 个月 · 小学N年级」，由生日与 `gradeOverride` 派生）。右上角提供「✏️ 编辑」（`onEditChild`，编辑当前孩子）与「+ 添加」（`openAddChild`）两个胶囊按钮。多孩子（`children.length > 1`）时右下角显示「切换孩子 ▼」按钮（`onSwitchChild`）。无孩子（`children.length === 0`）时孩子主区显示「还没有孩子档案，点这里添加 +」引导态。孩子列表由 `childShare.listChildren` 受信端统一返回，避免前端安全规则或索引异常导致已存在档案被展示为空；创建成功后立即将返回档案写入页面及全局孩子列表、切换为当前孩子并刷新统计。
  - **家长副区（主卡下区，分割线分隔）**：左侧展示由 `users.role` 与当前孩子名派生的家长称谓（如「小云朵的爸爸」），未选择角色时显示「我是 Ta 的... 选一下 →」；整行点击进入角色选择。右侧仅在已绑定手机号时展示手机号末四位，手机号绑定由 `button open-type="getPhoneNumber"` 触发。
  - **登录态展示约束**：只有本次会话的 `login` 云函数成功后才视为已登录，本地缓存不能单独触发已登录 UI。未登录时主卡展示「登录后开始记录成长」及「微信登录」按钮，功能列表展示「登录账号」，隐藏「退出登录」与孩子添加入口；日历、待办、阅读、课表及成长记录页点击右下角「＋」时，若未登录则统一切换到「我的」登录引导页；点击其他需要身份的操作时先登录，成功后继续原操作。用户主动退出后写入 `manualLoggedOut` 标记并暂停静默登录，直到再次明确点击登录。
  - **切换孩子**：`onSwitchChild` 弹 `wx.showActionSheet` 列出所有孩子（每项 `名字 · 年龄`）并追加「+ 添加新孩子」项；选中孩子走 `app.setActiveChild(uuid)` 切换（触发 `activeChildChanged` 全局事件，主卡、统计与家长称谓随即刷新），选「+ 添加新孩子」打开建档弹层。
  - **全局孩子上下文**：日历、阅读、课表、成长记录、成长周报与精选书库页面顶部统一展示「当前孩子」卡片；多孩子时可直接弹出列表切换，切换后各页面通过 `activeChildChanged` 重新加载数据。待办页沿用已有孩子 chip，始终高亮当前孩子。
  - **删除孩子**：仅档案创建者可在编辑弹层执行删除。前端必须展示包含关联数据范围的二次确认；`childShare.deleteChild` 负责软删除孩子档案、全部成员关系、未失效邀请以及 `daily_records`、`books`、`todos`、`schedule_items`、`reading_logs`、`series`、`weekly_reports`，完成后自动切换到剩余孩子。
- **② 统计双列卡（`stats-card`）**：左列大数字 `stats.records` +「成长记录」，竖分割线，右列大数字 `stats.books` +「共读绘本」。`records`/`books` 均在 db 层经 `scope().childId`（读取 `app.globalData.activeChildId`）自动按当前孩子过滤。
- **③ 功能菜单（`list-section`，iOS 风格纯列表）**：每项为「左圆形彩色图标 + 菜单文字 + 右灰色箭头 ›」——📁 成长档案（蓝）/ 📊 本周成长周报（橙）/ ☁️ 云同步（绿）/ ⚙️ 设置（灰，前置更明显分割线）。
  - **孩子头像**：在编辑/添加弹层内点击头像从相册上传自定义头像（`wx.chooseMedia` 选图 → `db.uploadFile` 存云存储 → 回填 `avatarFileId`）；展示时按 `avatarFileId` 换取临时链接（`db.getTempUrls`）渲染，无则回落性别 emoji。
  - **孩子信息编辑**：点主卡「✏️ 编辑」进入编辑模式（复用建档弹层，`editingChildUuid` 区分新增/编辑，编辑走 `db.children.update`），可修改名字 / 性别 / 生日；打开弹层时 `childForm` 正确回填 `name` / `birthDate` / `gender` / `gradeOverride`。
  - **年级确认**：保存孩子信息后（新增或编辑），若已填生日则按 `gradeOverride` 优先、否则由生日自动推导年级并弹「年级确认」框；用户可确认或点「修改」打开年级 picker 手动选择（幼儿园小班～高中3年级），选定后写入 `gradeOverride`。已有 `gradeOverride` 或推导结果为空（幼儿园/大学阶段）时不弹。
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

### 4.8 精选书库（阅读 → 精选书库）— 已实现（P0）

- **定位**：官方/共建的公共分龄书单，降低「不知道给孩子读什么」的选书成本，一键加入孩子书架。
- **数据源**：公共只读集合 `book_library`（无 `ownerId`/`childId` 归属），前端 `db.bookLibrary.listAll()` 走 `listAllPublic` 分页拉全，**不做归属过滤**；种子数据见 `miniprogram/scripts/seed_book_library.json`（100 本，`0-3`/`3-6`/`6-9`/`9-12` 各 25 本，覆盖绘本/桥梁书/章节书/科普）。
- **浏览页 `pages/library/`**：
  - **搜索栏**：按书名 / 作者实时前缀过滤。
  - **年龄段 Tab**：全部 / 0-3岁 / 3-6岁 / 6-9岁 / 9-12岁 / 官方精选（横向滚动）。
  - **两列书卡**：封面（无图走「色块 + 书名首字」兜底，按年龄段变色）、书名、作者、年龄段徽标（0-3 粉 / 3-6 橙 / 6-9 绿 / 9-12 蓝）+ 类型徽标；系列书右上角「系列 · N册」角标。含 loading 骨架屏与搜索空态。
- **加入书架**：
  - **单本**：点书卡弹「加入书架」面板 → 沿用页面顶部当前孩子 → 写入用户私有 `books`（回填 `libraryUuid` + 书库快照字段），按 `libraryUuid` 去重；仅当前孩子失效时重新弹出孩子选择器。
  - **系列书**（归属**方案 A**）：点书卡弹分册列表面板，可「加入某一分册」或「加入整套」；加入时在用户私有 `series` 新建一条并回填 `libraryUuid`（同孩子按 `libraryUuid` 复用，不重复建系列），分册以 `seriesUuid` + `seriesIndex` 落 `books`，天然复用书架 `series-service` 分组与系列面板。
  - `books.status` 沿用现有 `want/reading/done` 枚举，加入默认 `want`。
- **书架 join 水合**：书架 `refresh()` 在 `groupBySeries` 之前调用 `_hydrateFromLibrary(books)`——对带 `libraryUuid` 的书一次性从 `book_library` 回填 `title/author/coverExternalUrl/ageRange/type/description`（**书自身已有手动值则保留、不覆盖**），书库改动可反哺书架展示。
- **热度计数（P1 预留）**：`book_library` 含 `addCount/likeCount/readFinishCount` 字段（当前恒为 0）；打卡完成同步 `readFinishCount +1` 已在 `reading-service._syncBookProgress` 留 `TODO P1`，其余见 `docs/BOOK_LIBRARY_BACKLOG.md`。

### 4.9 待办清单（底部 Tab「待办」）— 已实现

- **入口（小程序端）**：底部导航「待办」Tab 直达 `pages/todo/todo`（原「记录」Tab 降级为次级页面 `pages/records/records`，仍可经日历「+ 记一笔」/ 相关入口访问）；mine 页功能菜单亦保留「待办」入口。
- **日历联动**：带 `dueDate` 的待办会同步落到日历对应日期，与课程、成长记录、阅读打卡共同构成日历四源综合视图（详见 §4.1 / §8.3）。
- **孩子维度待办**：待办强制关联当前孩子（`childId`），复用全局 `activeChild` 归属；多孩子时顶部提供孩子过滤 chip，切换即切库。
- **分类体系**：作业 / 生活 / 兴趣 / 其他四类，各带 emoji 与马卡龙分类色；顶部「全部 + 四分类」筛选 tab。
- **勾选完成**：圆形勾选圈一键切换完成 / 未完成（乐观更新，先本地翻转再落库）；顶部完成进度条展示 `已完成 / 总数`。首次勾选为完成后弹出「记录成长」确认，确认则进入已预填标题、备注、分类与完成日期的成长记录页，用户可补充图片/心情后保存；取消只保留待办完成态。成长记录通过 `sourceType='todo'` + `sourceTodoId` 关联来源，待办通过 `convertedRecordId` 反向关联；保存由 `childShare.convertTodoToRecord` 在服务端事务内完成待办校验、确定性记录写入及关联回写，保证并发场景只产生一条记录。删除关联成长记录会清理待办侧关联，以便后续重新记录；仅取消待办完成状态不会删除已生成记录。
- **增删改**：右下角 FAB 触发底部弹层新增；点击卡片进入编辑；卡片右侧「删除」走二次确认软删。字段含标题、分类、截止日期（选填）、备注（选填）。
- **截止日期与提示**：`dueDate`（`YYYY-MM-DD`），支持「今天」高亮与逾期红色提醒；页面顶部汇总展示「N 项今天截止 / N 项已逾期」，进入待办页即可看到，不依赖系统通知授权。列表排序「未完成在前 → 按截止日期升序 → 按创建时间倒序，已完成沉底」。当前版本不提供离线或微信订阅消息推送。
- **空态兜底**：无孩子档案时引导先去「我的」建档；无待办时引导点 FAB 添加。
- **数据封装**：`utils/todo.js` 基于 `utils/db.js` 通用 CRUD 二次封装（`listAll`/`listByCategory`/`create`/`update`/`toggleDone`/`remove`），并导出 `TODO_CATEGORIES`/`categoryMeta` 展示令牌。

---

## 5. 暂未实现 / 已移除入口的功能清单

| 功能 | 状态 | 说明 |
| --- | --- | --- |
| 活动计时器（TimerPage） | **入口已移除，路由保留** | `/records/timer` 路由与页面仍在，UI 入口已下线；`DailyRecords`/`ReadingLogs` 保留 `source='timer'` 口径 |
| 语音识别记录 | **待开发** | speech_to_text 依赖已引入，`source='voice'` 口径已预留，功能未落地 |
| 扫码识别书籍 | **小程序端已落地** | `wx.scanCode` + 云函数 `bookLookup`（探数 + Google Books）；Flutter 端 mobile_scanner 待落地 |
| 调课 / 停课 | **P1 简化版（excludedDates[]）** | V1 支持单日停课（schedule_items.excludedDates[] 存停课日期）；独立 CourseExceptions 集合（调课改签/改时段）列入 V2 |
| AI 周报文案 | **V2** | 无 API Key 时走本地模板降级；国内 LLM API Key 配置入口列入 V2 |
| 通知提醒 | **部分预留** | flutter_local_notifications 已引入，围绕周报/提醒场景待完善；小程序端走服务通知/订阅消息 |
| 分享周报 | **V2** | 等 AI 润色文案 + editedText 编辑版落地后，再做 canvas 长图导出分享；V1 支持系统级截图 |
| 深色模式 | **降级处理** | V1 仅浅色，深色主题降级为浅色以保持暖橙风格一致 |
| 多孩子档案 | **✅ 小程序端已落地（V1 P0）；Flutter 端 V1 P1** | 小程序端支持多孩子切换 + 家长角色 + 多孩子 ActionSheet；Flutter 端 schema 需扩展 sortOrder/gender/gradeOverride，schemaVersion→3 |

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


---

## 8. 微信小程序端架构（分层规范）

> **双端策略（路径 A，见 docs/DECISION_LOG_20260910.md §0）**：小程序端为全家主入口（家人/非技术用户），数据 100% 在 CloudBase；Flutter App 端为本人使用的「离线可用 + AI 润色」高级版，数据完全独立（Local-First SQLite + 系统级备份 iCloud / Android Auto Backup），不引入 CloudBase SDK。双端打通共享列为 V3 远期目标。无论双端是否打通，**业务口径必须 100% 一致**，跨端统一规则见 [`AGGREGATION_RULES.md`](./AGGREGATION_RULES.md)。
>
> 完整小程序架构详见 [`miniprogram_architecture_design.md`](./miniprogram_architecture_design.md)，本节为摘要索引。

### 8.1 分层模型

```
样式令牌层  app.wxss（CSS 变量：色/圆角/阴影）
页面层      pages/*         只做 UI 编排 + 交互，取数调 service
组件层      components/*    可复用 UI（month-calendar / event-card / bottom-sheet ...）
服务层      services/*      业务聚合/领域逻辑（calendar / reading / schedule / report）
工具层      utils/*         纯工具（db 纯 CRUD / date / constants / format）
全局层      app.js + store  globalData 规范 + 事件总线
云函数层    cloudfunctions/* login / bindPhone（+ 后续 generateWeeklyReport）
```

依赖方向单向：`pages → components / services → utils → wx.cloud`。禁止 services 依赖 pages、utils 依赖 services。

### 8.2 云数据库集合（10 个，CloudBase 文档型）

- 归属体系：`ownerId`（unionid 优先否则 openid）+ 业务集合加 `childId`（指向 `children.uuid`）。
- 同步三件套：`uuid`（跨端业务主键）/ `updatedAt`（毫秒时间戳）/ `isDeleted`（软删）。
- 关系引用存被引 `uuid`（`books.seriesUuid`、`reading_logs.bookUuid`、`books.libraryUuid`/`series.libraryUuid` → `book_library.uuid`）。

| 集合 | 归属 | 用途 | 状态 |
| --- | --- | --- | --- |
| `users` | ownerId | 账号（新增 `role` 家长角色字段，枚举 `dad`/`mom`/`grandpa`/`grandma`/`grandpa_m`/`grandma_m`/`other`；首次进入引导选角色，选后点击家长行可修改） | ✅ 已实现 |
| `children` | ownerId | 孩子档案（多孩子；字段 `name`〔大名或小名均可〕/`birthDate`/`avatarFileId`/`sortOrder`，P0 扩展新增 `gender`〔`boy`/`girl`/`unknown`〕/`gradeOverride`〔手动覆盖年级〕；年龄文字/年级/年龄段由 `utils/date.js` 的 `ageText`/`gradeOf`/`ageRangeOf` 派生） | ✅ 已实现 |
| `daily_records` | ownerId+childId | 成长记录（日历/周报聚合主键 `eventDate`） | ✅ 已实现 |
| `schedule_items` | ownerId+childId | 课表/课外班（weekday + recurrence 规则；weekly 周展开已落地，支持 startDate/endDate 生效区间） | ✅ 已实现 |
| `todos` | ownerId+childId | 孩子待办（字段 `title`/`category`〔作业/生活/兴趣/其他〕/`done`/`dueDate`〔YYYY-MM-DD 选填〕/`remark`；`utils/todo.js` 封装 CRUD + 勾选完成） | ✅ 已实现 |
| `books` | ownerId+childId | 书架（status 由打卡派生跃迁；新增 `isbn`/`seriesUuid`/`seriesIndex`/`coverExternalUrl`/`libraryUuid` 字段） | ✅ 已实现 |
| `reading_logs` | ownerId+childId | 阅读打卡（日历第三源 `readDate`） | ✅ 已实现（打卡写入闭环 + 状态跃迁 + 进度派生） |
| `series` | ownerId+childId | 套书元信息（`name`/`totalVolumes`/`libraryUuid`；已读册数由 books 聚合派生，不冗余存储） | ✅ 已实现（`series-service` 分组聚合 + 系列面板） |
| `book_library` | **公共（无归属）** | 精选书库公共只读集合（分龄书单，含 `volumes[]`/`ageRange`/`type`/`isOfficial`/热度计数）；走 `db.listAllPublic` **不过滤归属** | ✅ 已实现（P0，`pages/library` + 加入书架 + 书架 join 水合） |
| `weekly_reports` | ownerId+childId | 周报快照（自动生成+历史归档，含 editedText 编辑版） | ⏳ **P1（与 Flutter 对齐）**：generateWeeklyReport 云函数周日 20:00 自动生成；空周不生成；幂等键 childId+weekStart |

字段与索引明细见架构文档 §2.3。

**权限（自定义安全规则，见 [`miniprogram/docs/SECURITY_RULES.md`](../miniprogram/docs/SECURITY_RULES.md)）**：多家长共享以「孩子」为锚点，`children` 与 7 个业务集合统一走安全规则 `auth.openid in doc.members`（`members` = 有权访问该孩子的 **openid** 数组，冗余在每条文档上；孩子及 owner 成员关系由 `childShare.createChild` 创建，业务文档由 `db.create()` 盖初值，成员变更由 `childShare` 同步维护）。选用纯冗余而非跨集合 `get()`，因安全规则只有 `auth.openid`（拿不到 unionid）、且 `childId` 存 `uuid`≠`_id` 无法按 `_id` 寻址。`child_members` 只读自己（`doc.openid==auth.openid`）、`child_invites` 前端全禁、`users` 只读写自己、成员写操作与邀请全部走 `childShare` 云函数兜底；`book_library` 为「所有人可读」的公共只读集合（写入由后台/控制台导入完成，见 `miniprogram/scripts/README.md`）。项目尚未上线，不保留历史数据迁移或 backfill 逻辑。

### 8.3 日历聚合口径（核心业务）

日历（`pages/index`）通过 `calendar-service` 把四类数据归一为统一 `CalendarEvent`（`{ date, type, title, color, sourceId, raw }`，`type: record/schedule/todo/reading`）后按天分组、多彩点展示（每天最多 4 个圆点：橙=成长记录、蓝=课外班、紫=待办、绿=阅读打卡）：
- **成长记录**：`daily_records` 按 `eventDate` 直接落点。
- **课外班/课程**：`schedule_items` 的周期规则（当前落地 weekly；biweekly/monthly/once 属 P1/P2）按展示月份**动态推算成具体日期，不落库**（`date.expandWeeklySchedule`）。
- **待办**：`todos` 中带 `dueDate` 的待办按截止日落点（无 `dueDate` 的待办不进日历，仅在待办 Tab 展示）；完成态在事件卡片上以划线 + ✅ 呈现。
- **阅读日志**：`reading_logs` 按 `readDate` 落点，join `books` 取书名。

> **wx.cloud 硬约束**：小程序端 `collection.get()` 单次最多返回 20 条。日历四源聚合、记录/书籍/打卡等列表一律走 `db.listAllPaged`（`skip/limit(20)` 循环，默认 cap 200）破除该上限，保证数据完整；`getTempFileURL` 单次上限 50，`db.getTempUrls` 已自动分批。

周报（`pages/report`）统计口径与 service 共用聚合方法，避免重复实现与口径漂移。

### 8.4 当前迭代待办

1. ~~**日历聚合展示**（成长记录 + 课外班 + 阅读日志）— P0~~ ✅ 已落地；**四源综合视图「成长记录 + 课程 + 待办 + 阅读打卡」**（待办由 `todos` 按 `dueDate` 落点，阅读打卡由 `reading_logs` 落点，见 §8.3）
2. ~~**书架 → 阅读打卡闭环**（补 `reading_logs` 写入 + 状态跃迁 + 进度派生）— P1~~ ✅ 已落地（`reading-service.addReadingLog` + 书架打卡弹层）
3. ~~**课外班日历推算**（weekday + recurrence 展开日期）— P0~~ ✅ 已落地（`date.expandWeeklySchedule`，weekly）
4. ~~**书架扫码录入**（`wx.scanCode` + `bookLookup` 云函数 ISBN 查书）+ **系列书面板**（`series` 集合 + `series-service` 聚合 + 叠层卡片/面板）— P1~~ ✅ 已落地
5. ~~**精选书库 P0**（`book_library` 公共集合 + `pages/library` 分龄浏览 + 加入书架单本/系列 + 书架 join 水合）~~ ✅ 已落地（P1 热度计数/共建投稿见 `docs/BOOK_LIBRARY_BACKLOG.md`）
6. 组件抽取（month-calendar / bottom-sheet / empty-state 进一步收敛）/ store 规范 / **周报口径迁移到 report-service 复用** / **generateWeeklyReport 云函数（周日 20:00 自动生成，空周不生成，幂等）** — P1
7. 课外班 biweekly/monthly/once 推算、`reading_logs` 详情页、多孩子聚合视图 — P1/P2

### 8.5 编码规范要点

- 命名：集合 `snake_case` 复数；页面统一 `pages/<domain>/index`；service 方法动词开头。
- 错误处理：读操作兜底空集合保证空态渲染；写操作必给 `wx.showToast` 反馈 + `console.error` 详情；写前预检 `auth.ownerId()`。
- 异步：统一 `async/await`；并行取数用 `Promise.all`。
- 状态：`globalData` 集中约定；事件名收敛为常量；不引入 MobX/Redux 等重方案。
- 视觉：一律走 `app.wxss` CSS 变量与 `constants.js` 令牌，禁止内联硬编码色值。
