# 变更日志（CHANGELOG）

本项目所有值得记录的功能变动都记于此。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，遵循语义化版本。
> 约定：每次功能改动都应同步更新本文件与 `docs/PRODUCT_SPEC.md`。最新变更置于顶部。

## [Unreleased]

### 2026-09-04 · 书架：扫码录入 + 系列书面板

#### 新增
- **扫码录入书籍**：阅读书架「＋」改为「添加方式」选择弹层（手动录入 / 扫码添加 / 新建系列）。扫码走 `wx.scanCode`（仅相机、条码模式），校验 13 位 + 978/979 前缀后调用新增云函数 `cloudfunctions/bookLookup`（探数 tanshu 主源 + Google Books 兜底，`axios` 请求，字段归一 `{ found, title, author, cover, totalPages, isbn }`，封面 `http→https`），命中后弹「扫码确认弹层」预填并可编辑书名/作者/总页数，保存时封面以外链 `coverExternalUrl` 落库（不占云存储）。非法条码或查询失败自动转手填。
- **系列书面板（套书）**：新增 `services/series-service.js`（`groupBySeries` / `buildPanelVM` / `deriveProgress` / `nextSeriesIndex`）把书籍按 `seriesUuid` 聚合为「系列卡片 + 单本书」。书架系列卡片含三层叠层封面伪装、右上「系列」橙色徽标、底部「已读 x/y」暖橙进度条；点开系列面板按 `seriesIndex` 升序列出各分册（册序 · 书名 · 状态角标 · 打卡），面板内可直接打卡（打卡后保持面板打开并刷新）与「＋ 添加分册」。
- **`db.series` 业务方法**：`utils/db.js` 新增 `series`（`listAll` / `getByUuid` / `create` / `update` / `remove`），与 `books` 风格一致，均走 `listAllPaged` + 权限/软删/ownerId 三件套。
- **新建系列**：书架「新建系列」弹层填写系列名 + 总册数，写入 `series` 集合。

#### 变更
- **`books.create` 透传新字段**：`isbn` / `seriesUuid` / `seriesIndex` / `coverExternalUrl` 随书籍整体写入。
- **书架取数与渲染**：`reading.refresh()` 同时拉 `db.books.listAll` + `db.series.listAll`，先水合封面（`coverExternalUrl` 优先，否则 fileID 换临时链接）再分组渲染 `renderList`（系列卡片在前、单本在后）。
- **弹层层级规范**：打卡 sheet（z-index 51）> 系列面板（41）> 普通/系列 mask（50/40），保证系列面板内打卡时层级正确。
- **文档同步**：更新 `docs/PRODUCT_SPEC.md` §4.3（书架功能）、§5（扫码状态）、§8.2（`books`/`series` 集合）、§8.4（迭代待办勾销）。

#### 说明
- **需手动部署**：`cloudfunctions/bookLookup` 为新增云函数，须在「微信开发者工具」右键该目录「上传并部署（云端安装依赖）」后扫码查书才可用；未部署时扫码会提示「bookLookup 云函数未部署」并可转手填。
- **可选环境变量**：`bookLookup` 支持 `TANSHU_KEY`（探数 appKey），未配置时自动跳过主源直接走 Google Books 兜底。
- **需新建集合**：首次使用系列功能需在云开发控制台新建集合 `series`（权限「仅创建者可读写」）。

### 新增
- **小程序服务层落地**：新增 `services/calendar-service.js`（日历三源聚合：成长记录 + 课表周展开 + 阅读打卡，归一为统一 `CalendarEvent`）与 `services/reading-service.js`（阅读打卡写入 + 书籍状态跃迁 + 进度派生）。
- **日历三源聚合 + 多彩点**：首页月历接入 `calendar-service`，每天最多 3 个彩色圆点（橙=成长记录、蓝=课外班、绿=阅读打卡）并补充图例；点击某天在下方以统一事件卡片展示当天全部安排（成长记录 + 课外班 + 阅读打卡）。
- **可复用事件卡片组件**：新增 `components/event-card/`，支持 record/schedule/reading 三种类型样式，按类型分色。
- **阅读打卡闭环**：阅读书架书籍卡片新增「打卡」按钮，弹层录入页数/章节/心得（日期默认今天）；打卡自动派生书籍状态（想读→在读、读完）与进度快照。
- **分页能力（破 20 条上限）**：`utils/db.js` 新增 `listAllPaged(collection, opts, cap)`，以 `skip/limit(20)` 循环拉全，破除小程序端单次查询 20 条硬上限；新增 `scheduleItems` / `readingLogs` 集合的增删改查方法。
- **日期工具**：`utils/date.js` 新增 `expandWeeklySchedule(items, year, month)`（weekly 课表按月展开为具体日期，支持 startDate/endDate 生效区间）与 `weekdayOf`。
- **事件类型令牌**：`utils/constants.js` 新增 `EVENT_TYPE_COLORS` / `EVENT_TYPE_LABELS` / `eventTypeColor`。

### 变更
- **列表查询统一走分页**：`db.records` / `db.books` / `db.children` 的列表方法改用 `listAllPaged`，保证记录/书籍等 >20 条时数据完整。
- **`getTempUrls` 自动分批**：`getTempFileURL` 单次上限 50，超出时自动去重分批请求后合并。
- **`date.endOfDay` 语义修正**：明确其返回「次日 0 点」（右开区间端点），新增语义清晰的 `startOfNextDay`，`endOfDay` 保留为兼容别名。
- **文档同步**：更新 `docs/PRODUCT_SPEC.md` §8（三源聚合口径、20 条上限对策、迭代待办勾销）。

### 说明
- 首次上线阅读打卡需在云开发控制台新建集合 `reading_logs`（权限「仅创建者可读写」），否则打卡写入会失败。

---

## [1.0.0-mvp-docs] - 2026-09-04

### 新增
- 初始化产品需求文档 `docs/PRODUCT_SPEC.md`（唯一真相源）与本变更日志 `CHANGELOG.md`。

---

## [1.0.0] - 2026-09-04

首个 MVP 版本，落地「日历记录 + 阅读书架 + 课表管理 + 自动周报」核心闭环。

### 新增
- **项目脚手架**：初始化 Flutter 工程结构，引入 Riverpod / go_router / drift 技术栈，补充技术方案文档。（`0d3c61f`、`ebc413a`）
- **MVP 核心架构**：落地阅读域重构（Series/Books/ReadingLogs 单一真相源，进度聚合派生）、底部 4 Tab 路由骨架、活动计时器、周报后台调度。（`dc302ca`）
- **日历记录**：首页问候头部、月历视图（分类彩色圆点）、当日成长足迹时间轴、图例与空态兜底。
- **日常记录**：时间轴按日期分组、分类筛选 Chip、快速录入弹层（文字/多图/心情/标签/日期）、图片缩略图。
- **阅读书架**：在读/想读/已读三分区、书籍卡片进度环、添加书籍、阅读打卡与状态自动跃迁。
- **课表管理**：学校课表周网格、课外班周期卡片、全局复用「添加课程」弹层（多选星期拆行落库）。
- **我的 / 周报**：孩子档案卡（年龄计算）、课表/周报/设置入口、周报列表与详情、每周日 20:00 自动汇总（空周不生成、幂等去重）。
- **快速记录 FAB**：底部栏正中悬浮「+」，支持记日常/记阅读/加课程三入口。
- **建档引导**：首次启动强制建立孩子档案。

### 变更
- **UI 对齐设计 Demo**：统一暖橙马卡龙设计令牌（配色/圆角/字重），课表模块重做，修正 FAB 展示逻辑。（`b1e8294`）
- **二级页面全屏化**：日详情/书详情/课表/周报/设置等二级页面改为全屏路由，进入后隐藏底部 Tab。（`7007cfb`）
- **构建工具链**：Android 侧切换阿里云 Maven 镜像并升级工具链，修复本地构建；补充平台目录与生成代码。（`2263163`、`70931d5`）

### 修复
- 修复二级页面返回时直接退出 App 的问题（返回改由分支 Navigator 承接）。（`5335e07`）
- 修复启动/交互相关 crash（随 UI 对齐一并处理）。（`b1e8294`）

### 已知限制 / 待开发
- 活动计时器（TimerPage）UI 入口已移除，路由 `/records/timer` 与页面保留。
- 语音识别、扫码识书、调课/停课、AI 周报文案、通知提醒、分享、深色模式、多孩子档案等尚未落地或仅预留接口。
