# 变更日志（CHANGELOG）

本项目所有值得记录的功能变动都记于此。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，遵循语义化版本。
> 约定：每次功能改动都应同步更新本文件与 `docs/PRODUCT_SPEC.md`。最新变更置于顶部。

## [Unreleased]
### Added
- **阅读书架全面升级：书型化打卡 + 系列进度可视化（阅读 Tab 重点优化）**：围绕「书架交互与 UI」重构，新增书型驱动的差异化打卡与系列册数进度：
  - 书籍新增 `bookType`（`picture` 绘本 / `chapter` 章节书 / `free` 自由阅读，`utils/constants.js` 新增 `BOOK_TYPES` + `PICTURE_MAX_PAGES`）；历史书无 `bookType` 时按「有 `totalChapters` → 章节书，否则自由阅读」推断，向后兼容
  - **分书型打卡**（`pages/reading` 打卡弹层按 `checkinMode` 分支）：绘本默认「读完整本」一键打卡（可切「只读了一部分」填页码，总页数 ≤ 80 也走一键）；章节书以 chips 选「读到第几章」（标注已读、默认选下一章，选到末章视为读完）；自由阅读起始页自动带上次进度（`currentPage + 1`），只填结束页
  - **手动加书表单扩展**：书型 segmented；绘本/自由阅读填总页数，章节书填「共几章」或逐行章节名（`chapters` 数组，填了以此为准）；**方案 B「归入系列」**——可勾选属于某系列，选已有系列或「＋ 新建系列」（系列名 + 总册数），指定册序（留空自动排序）
  - **系列进度可视化**：系列卡片 / 面板显示「已读 x / 共 x 册」文字 + 百分比 + 进度条；打卡弹层为系列分册提供「读完这册」勾选，勾选后该册标记读完、系列已读册数 +1
  - 新增 `tests/services/series-service.test.js`、`tests/services/reading-service.test.js` 共 10 个单测（进度口径、`markDone` 强制读完、读完这册幂等、页码派生回归）

### Changed
- **系列进度口径改为「totalVolumes 分母 + 派生已读」**：`services/series-service.js` `deriveProgress(seriesUuid, books, seriesMeta)` 的 `total` 优先取 `series.totalVolumes`（运营声明「共 x 册」），未设置时回退已归属分册数；`done` 仍由分册 `status==='done'` **派生**，`groupBySeries`/`buildPanelVM` 输出 `progressPct`。**已读册数不冗余存储**，故「读完这册」重复勾选不会重复计数（幂等）
- **`services/reading-service.js` 打卡支持显式完成**：`addReadingLog(childId, bookUuid, { markDone })` 新增 `markDone` → `_syncBookProgress(bookUuid, { forceDone })`，把「读完整本 / 读完这册 / 章节读到末章」强制置 `done`；复用既有幂等护栏（仅 `prevStatus !== 'done' && status === 'done'` 时才触发 `book_library.readFinishCount +1`），重复完成不重复计数
- **精选书库加入书架携带书型**：`pages/library/library.js` 新增 `type → bookType` 映射（绘本→picture、桥梁书/章节书→chapter、科普/其他→free），单本与系列分册加入时写入 `bookType`
- **`utils/db.js`**：`books.create` 注释补充 `bookType`/`chapters` 等透传字段说明（字段随 generic create 整体写入，进度快照 `currentPage`/`currentChapter`/`lastReadDate` 由 reading-service 派生回写）

### Added
- **独立「课程库」页面 + 拖拽排课（课表页最终方案）**：新增 `pages/schedule/course-library`（js/wxml/wxss/json，已注册 `app.json`），把课程分类管理从课表页收敛为独立入口：
  - 新增云数据库集合 `course_templates`（课程模板：`name`/`type`〔`school` 校内 / `extra` 兴趣班〕/`color`/`isPreset`），纳入 `childShare` 业务集合白名单与安全规则 `auth.openid in doc.members`，多家长共享
  - 首次进入课程库页自动 `ensureSeed()` 写入一批预置课程（语文/数学/英语/体育/科学/音乐/钢琴/游泳/美术/编程/篮球/舞蹈）；支持新增、编辑（名称 + 分类 + 颜色）、删除（含长按卡片快捷删除）自定义课程
  - 课表页底部「课程库」面板 chips 改为读取 `course_templates`，面板顶部「管理 ›」跳转独立课程库页；拖拽 chip 落到网格即按分类默认时长（校内 40min / 兴趣班 60min）建课，`schedule_items` 新增 `templateId`（引用 `course_templates.uuid`）与 `color` 快照
  - 触摸手势用 `touchstart/move/end` + `catchtouchmove` 实现（小程序无 HTML5 拖放），落点命中用 `selectorQuery` 取 `.daycol` 视口坐标反算星期与时间；手指停留在周视图左右边缘触发横向自动滚动

### Changed
- **课表页改为「周网格总览 + 日视图」**：`pages/schedule/index`（js/wxml/wxss）从纵向按星期分组的列表重构为可视化时间表：
  - 周视图横轴为周一~周日、纵轴为时间轴，课程按真实起止时间比例渲染为色块（颜色取自课程模板），今天列高亮，进入时自动把当天列滚动到视口居中
  - 新增「周 / 日」切换 segment；日视图顶部星期 tab 默认选中今天
  - 时间轴范围按当前课程数据在默认 8:00–19:00 基础上动态外扩
- **课表交互全面改为拖拽驱动，移除课表内加号与编辑弹层**：
  - 去掉课表左下角「＋」FAB 与新增/编辑课程 `bottom-sheet`，加课统一走「课程库拖拽」；点空白格不再弹出添加
  - 课程色块：**拖动**调整星期/开始时间（吸附到 10 分钟格，带时间冲突校验）、**长按**（~500ms）弹出删除确认、**点击不再进入编辑页**

### Fixed
- **课表课程块「拖拽调时间」与「长按删除」均失败（-502003 DATABASE_PERMISSION_DENIED）**：根因是共享业务集合的写操作仍走前端 `doc().update()`，受 `update` 安全规则 `auth.openid in doc.members` 限制——历史数据 / 其他家长创建的 `schedule_items` 若 `members` 不含当前 openid 即被拒（调时间的 `scheduleItems.update`、删除的 `softDelete → remove` 都命中）。改为与读取同源、统一收口 `childShare` 受信端：
  - 云函数新增 `updateChildData` action（白名单校验 + `child_members` 成员身份校验 + 按 `uuid`/`childId` 定位后以管理员权限更新；保护 `uuid`/`ownerId`/`childId`/`members`/`_id` 不被篡改）
  - `utils/db.js` 新增 `SHARED_BIZ_COLLECTIONS`，`updateByUuid()` 对共享业务集合改走 `childShare.updateChildData`；`children`/`users` 等非共享集合保持原前端按 `_id` 更新
  - 新增 6 个 `updateChildData` 单测（非白名单/非成员拦截、成员按 uuid 改时间、软删、保护字段、记录不存在）
- **课程库页「+ 新增」点击无反应**：`openAdd` 入口先调 `auth.openLoginPage()`，在 `navigateTo` 子页面上 `app.globalData.loginVerified` 未就绪（如 devtools 重新编译后）会误触发 `wx.switchTab` 跳「我的」，表现为「点了没反应」。已移除该 switchTab 拦截，改为仅校验是否已选中孩子（写入时安全规则仍校验登录态）
- **课程库「校内 / 兴趣班」预置课程不显示**：DB 化后预置课程改由首次进入 `ensureSeed()` 写入 `course_templates`，依赖 `childShare` 云函数重新部署 + 集合安全规则；补充读取/写入失败的 `console.error` 明确提示（多为云函数未重新部署或规则未配置），便于定位
- **「我的」页家长角色选择弹窗点击无反应**：`ROLE_OPTIONS` 有 7 项，超过 `wx.showActionSheet` 最多 6 项限制且原 `fail` 回调静默吞错，表现为「点了没弹窗」。改用自定义 `bottom-sheet` 角色网格承载 7 个角色选项，选中即保存
- **共享数据前端直读被 `DATABASE_PERMISSION_DENIED` 拦截**：`where members` 数组查询前端安全规则无法证明，导致课表 `refresh`、`db.getByUuid`、成长记录去重查询等直读被拒（列表空/保存后不刷新，且新数据的 `members` 只盖到创建者、其他家长看不到）。改为统一收口 `childShare` 云函数：
  - `pages/schedule/index.js` 课表列表改用 `db.scheduleItems.listAll()`（走 `listChildData`）
  - `utils/db.js` `getByUuid()` 改为复用 `listChildData` 拉取当前孩子该集合后按 `uuid` 命中；`pages/records/add` 的成长记录去重查询改用 `db.records.listAll()` 本地筛
  - `utils/db.js` `create()` 写入前改用新云函数 `childShare.getChildMembers` 取权威 members(openid) 盖章，确保同孩子其他家长立即可读写新数据
  - 新增 `childShare.getChildMembers` action（校验调用者成员资格后返回 `children.members`），并补 3 个云函数单测（共 61 例通过）

### Added
- **小程序端单元测试工程（第一层：纯逻辑 + 鉴权）**：新增 `miniprogram/` Jest 测试工程（`npm test`），仅 `devDependencies`、不参与「构建 npm」；覆盖 58 个用例
  - `tests/utils/date.test.js`：日期工具（起止日、ISO 周几、月历矩阵、课表周展开的起止/排除日、年龄/年级推导）
  - `tests/utils/todo.test.js`：待办分类回落、`listAll` 登录/孩子守卫与 `childShare.listTodos` 收口
  - `tests/utils/db.test.js`：共享数据读取收口后的 `listChildData` 入参、本地过滤/倒序、上下文守卫与云失败回退空
  - `tests/services/calendar-service.test.js`：日历四源聚合（类型/数量、待办 `dueDate` 区间过滤、排序、分组、圆点计算）
  - `tests/cloudfunctions/childShare.test.js`：云函数鉴权（集合白名单、成员鉴权、分页拉全、删除孩子仅创建者、待办转成长记录的未完成拦截/幂等去重/确定性 ID）
  - 配套 `tests/setup.js`（wx/getApp 宿主桩 + `__setUser`/`__setActiveChild`）、`tests/helpers/fake-cloud.js`（内存版 CloudBase：`where/orderBy/skip/limit/get/add/doc/update/set/remove` + `neq/eq/in` + `runTransaction`）与 `tests/README.md`（四层测试策略与运行说明）
- **多孩子全局上下文**：新增 `child-switcher` 组件，在日历、阅读、课表、成长记录、成长周报与精选书库页面持续展示当前孩子；多孩子时可直接切换，切换后页面自动刷新对应孩子的数据
- **删除孩子档案**：创建者可在「我的 → 编辑宝宝信息」中删除孩子；二次确认后由 `childShare.deleteChild` 统一软删除孩子档案、成员关系、邀请及其全部业务数据，并自动切换到剩余孩子
- **待办完成后可选记录成长**：勾选完成后弹出确认，选择「记录成长」进入预填表单；成长记录与来源待办双向关联，`childShare.convertTodoToRecord` 使用服务端事务原子完成待办校验、确定性记录写入及关联回写，避免并发重复与覆盖；删除关联记录会清理待办侧关联，取消完成不会删除已生成记录
- **未登录 FAB 登录引导**：日历、成长记录、待办、阅读、课表页点击右下角「＋」时，未登录统一切换到「我的」登录引导页
- **数据库自定义安全规则（多家长共享鉴权收口）**：业务集合从「仅创建者可读写」升级为自定义安全规则，判定式 `auth.openid in doc.members`，实现「同一孩子的多位家长共享读写、非成员一律拒绝」
  - 新增权限方案文档 [`miniprogram/docs/SECURITY_RULES.md`](miniprogram/docs/SECURITY_RULES.md)：各集合规则 JSON（可直接粘贴控制台）、两条 schema 硬约束说明、上线步骤与回归用例
  - `members` = 有权访问该孩子的 **openid** 数组，冗余在 `children` 与 7 个业务集合每条文档上（规则里零 `get()`，绕开单规则 3 次 `get()` 上限）
    - ⚠️ 存 openid 而非 ownerId：安全规则只有 `auth.openid`，拿不到 unionid；且 `childId` 存 `uuid`≠`_id`，跨集合 `get('database.children.${doc.childId}')` 按 `_id` 寻址无法命中，故只能纯冗余
  - `childShare` 云函数新增 `members(openid)` 一致性维护：
    - 新增 `createChild` action：受信端一次创建孩子档案与 owner 成员关系；`children`/`child_members` 前端创建权限关闭，避免伪造 owner 或孤儿档案
    - 新增 `syncChildMembers(childId)`：重算成员 openid 集合 → 回写 `children.members` + 批量回填全部业务集合 → 顺带补齐 `child_members.openid`
    - `acceptInvite`（加入）/ `removeMember`（移除）/ `leaveChild`（退出）后自动触发同步，成员变更即时反映到共享数据访问权
  - `utils/db.js` 的业务查询统一显式携带 `members: '{openid}'`（CloudBase 服务端身份占位符），满足「查询条件必须是安全规则子集」约束；孩子创建改走 `childShare.createChild`，移除未上线项目不需要的历史回填分支
  - `generateWeeklyReport` 创建/更新周报时同步写入所属孩子的 `members`，保证生成数据可被同孩子家长读取
  - `child_members` 新增 `openid` 冗余字段（安全规则 `doc.openid == auth.openid` 读取自身成员记录所需）
- **家庭共享（多家长共享同一孩子）**：以孩子为中心、`childId` 作为共享锚点，支持一个孩子被多位家长共同记录、读写同一份数据
  - 新增 `child_members` 集合（孩子↔家长 多对多成员关系，`isOwner=true` 为创建者，可邀请/移除）
  - 新增 `child_invites` 集合（6 位一次性邀请码，24h 过期，`usedBy` 单次使用）
  - 新增 `childShare` 云函数，`action` 路由：`createInvite` / `acceptInvite` / `listMembers` / `removeMember` / `leaveChild` / `getQrCode`（小程序码 `wxacode.getUnlimited`）
  - mine 页新增「家庭共享」入口与成员管理弹层：成员列表（创建者/我标签）、分享给家人（转发一次性邀请链接）、生成邀请二维码（可保存相册）、创建者移除成员、非创建者退出共享
  - 支持两种加入方式：分享链接（`?invite=CODE`）与扫描小程序码（`scene=CODE`）；进入 mine 页自动识别并调用 `acceptInvite` 加入
### Fixed
- 收口共享业务集合列表读取：`daily_records`、`books`、`schedule_items`、`reading_logs`、`series`、`weekly_reports` 统一通过 `childShare.listChildData` 校验成员后读取，消除日历等页面持续出现的 `DATABASE_PERMISSION_DENIED`
- 修复待办新增成功后列表仍为空的问题：`todo.listAll()` 改走 `childShare.listTodos` 受信端查询并校验孩子成员身份，避免前端安全规则拒绝后被静默降级为空；待办页新增「今天截止 / 已逾期」前台提醒条
- 修复“我的”页新增孩子后刷新仍展示空状态、从而可重复添加的问题：孩子列表改走 `childShare.listChildren` 受信端查询，绕开前端安全规则/索引查询失败被静默降级为空；创建者自己的异常孤立档案会自动补齐 `child_members` 与 `members`，创建成功后仍即时更新页面状态
- 修正“我的”页登录态展示：仅云端 `login` 成功后显示「退出登录」；未登录展示登录引导与「登录账号」，添加孩子时先登录并在成功后继续；用户主动退出后暂停自动静默登录
- 修复开发者工具热重载后可能遗留原生 `showLoading(mask:true)`、导致页面点击被遮罩拦截而原生 Tab 仍可切换的问题：应用 `onShow` 兜底调用 `wx.hideLoading()`
- 修复课表页 `dateUtil.todayStr is not a function`：在日期工具中补齐并导出 `todayStr()`，统一返回本地时区 `YYYY-MM-DD`
- 优化共享数据查询的软删条件：新数据统一使用 `isDeleted:false`，避免 `neq(true)` 无法高效使用索引的开发者工具告警
- 修复启用自定义安全规则后的 `DATABASE_PERMISSION_DENIED`：业务查询改用 CloudBase `'{openid}'` 身份占位符；登录用户 upsert 完全收口到 `login` 云函数，移除客户端重复访问 `users`
- 修复开发者工具 `app.json` 无效字段警告：移除误放在 `app.json` 的 `cloudfunctionRoot` 与 `window.libVersion`（两者已在项目配置中维护）
### Changed
- `utils/db.js` 共享模型改造：
  - `_buildWhere` 业务数据集合归属过滤由 `ownerId` 改为仅 `childId`（`ownerId` 仅作登录闸门；仍写入每条数据做「谁创建」溯源，但不参与过滤）
  - `getByUuid` / `updateByUuid` 改为按全局唯一 `uuid` 定位（不再按 `ownerId`），加入该孩子的家长均可读写/编辑同一条数据
  - `children.listAll` 改为成员表驱动：按 `child_members.openid='{openid}'` 反查可见孩子，不保留未上线项目不需要的历史回填分支
  - `children.create` 改走 `childShare.createChild`，由受信端一次写入孩子档案和创建者成员关系
- `generateWeeklyReport` 云函数改为按 `childId` 聚合（不再按 `ownerId`），确保多位家长录入的数据都纳入周报统计；Cron 触发改为直接遍历 `children` 集合逐个孩子生成；`weekly_reports` 幂等键由 `(ownerId, childId, weekStart)` 改为 `(childId, weekStart)`

### Changed
- 底部导航「记录」Tab 替换为「待办」Tab（`pages/records/records` → `pages/todo/todo`）；原记录页降级为次级页面，仍可经日历「+ 记一笔」入口访问
- 日历页（`pages/index`）升级为**课程 + 待办 + 成长记录 + 阅读打卡**四源综合视图：
  - 带 `dueDate` 的待办按截止日落到日历对应日期，与课程、成长记录、阅读打卡共同打点（每天最多 4 个圆点：橙=成长记录、蓝=课程、紫=待办、绿=阅读打卡）
  - `event-card` 支持待办完成态：标题划线置灰 + 右侧 ✅
  - 图例更新为 成长记录 / 课程 / 待办 / 阅读打卡
- `constants.js` 日历事件类型令牌新增 `todo`（丁香紫 `#B7A5F0`）；`calendar-service` 由三源扩展为四源聚合（`daily_records` + `schedule_items` + `todos` + `reading_logs`），圆点上限由 3 提升至 4

### Added
- 新增「孩子待办（Todo）」功能：`pages/todo` 待办清单页 + `utils/todo.js` 云数据库封装 + `todos` 云集合
  - 待办与孩子关联（`childId`），支持按孩子过滤（多孩子顶部 chip 切换，复用全局 `activeChild` 归属）
  - 支持勾选完成/未完成（乐观更新）、新增/编辑/删除（底部弹层）、完成进度条
  - 分类标签：作业 / 生活 / 兴趣 / 其他（含 emoji + 马卡龙分类色），支持分类筛选 tab
  - 支持截止日期（`dueDate`），逾期高亮提醒
  - mine 页功能菜单新增「待办」入口，跳转 `pages/todo/todo`
### Changed
- mine 页顶部重构：合并「家长卡」与「孩子主卡」为一体双区主卡
- 新增家长角色选择功能（爸爸/妈妈/爷爷/奶奶/姥爷/姥姥/其他），存储于 users.role 字段
- 功能菜单改为 iOS 风格纯列表，去掉卡片包裹
- 家长副区去掉 emoji，点击整行弹二级菜单（选角色 / 绑手机号）
### Added
- auth.js：新增 updateUserRole(role) 方法
### Fixed
- 修复编辑孩子弹层 name input 未绑定 value 导致编辑时名字空白
- 修复家长副区 button open-type 吃掉 bindtap 事件导致点击无效
- 修复主卡与统计卡统计数字重复展示问题
- 修复左右边距不对齐问题

## [v1.1.0] - 2026-09-07

### Changed
- mine 页顶部重构：以「当前孩子主卡」替换低价值「家长卡」，展示头像、名字、年龄/年级、阅读统计
- 移除横排孩子 chip 列表，切换孩子通过主卡「切换 ▼」ActionSheet 入口操作

### Fixed
- 编辑孩子弹层打开时 name 字段为空白的问题
- 切换孩子后统计数字未刷新的问题
- reading 页书库缓存未命中导致每次重复拉取的问题

## [unreleased] — 2026-09-07

### Fixed
- 孩子建档 Toast 文案「请填写昵称」修正为「请填写宝宝名字」
- mine 页订阅 activeChildChanged，切换孩子后页面自动刷新
- switchChild 切换孩子时重新派生年龄/年级/头像派生字段
- 统计数据按当前孩子过滤，多孩子场景数据准确

### Added
- 孩子档案支持编辑（点击 chip 上 ✏️ 可修改名字/性别/生日）
- 保存孩子信息后自动推导年级并弹确认框，支持手动修改
- 孩子头像支持点击上传（从相册选择，存云存储）
- 书架页书库水合接入全局缓存，避免每次 refresh 重复拉全量书库

## [unreleased] — 2026-09-07

### feat
- 孩子档案字段扩展 P0：新增 `gender`（性别）、`nickname`（小名）、`gradeOverride`（手动覆盖年级）字段
- 新增 `utils/date.js` 工具函数：`ageText()`、`ageRangeOf()`、`gradeOf()`
- 孩子卡片展示优化：小名优先展示、自动计算年龄文字和年级、性别联动头像 emoji
- 建档弹层新增小名输入框和性别 chip 选择器

### fix
- 修复 reading.js 书库水合每次 refresh 重复拉取全量数据的问题，改为 globalData 缓存复用

### refactor
- 孩子建档去掉独立小名字段，name 语义扩展为大名/小名均可，建档更简洁


### 2026-09-06 · 精选书库 P0（书库浏览 + 加入书架 + 书架 join 水合）

#### 新增
- **精选书库浏览页 `pages/library/`**：分龄挑好书一键加入书架。顶部搜索栏（书名/作者实时前缀过滤）+ 年龄段 Tab（全部 / 0-3岁 / 3-6岁 / 6-9岁 / 9-12岁 / 官方精选，横向滚动）+ 两列书卡网格（封面无图走「色块 + 书名首字」兜底并按年龄段变色、书名、作者、年龄段徽标〔0-3 粉 / 3-6 橙 / 6-9 绿 / 9-12 蓝〕、类型徽标，系列书右上「系列 · N册」角标），含 loading 骨架屏与搜索空态；已注册路由 `pages/library/library`。
- **加入书架**：单本弹「加入书架」面板；系列书弹分册列表面板，支持「加入某一分册」或「加入整套」。写入前拉孩子列表，多孩子弹 `showActionSheet` 选择器，选定后 `app.setActiveChild` 归属该孩子再落库。单本按 `libraryUuid` 去重；系列按「方案 A」在用户私有 `series` 新建一条并回填 `libraryUuid`（同孩子按 `libraryUuid` 复用不重复建系列），分册以 `seriesUuid` + `seriesIndex` 落 `books`，天然复用现有 `series-service` 分组与系列面板。`books.status` 沿用 `want/reading/done`，加入默认 `want`。
- **书架入口**：阅读书架「＋」添加方式弹层新增「📚 精选书库」入口（`wx.navigateTo` 跳转），置于首位。
- **`db.bookLibrary` 命名空间**：`utils/db.js` 新增 `bookLibrary`（`listAll({ ageRange?, isOfficial? })` / `getByUuid`），走新增的 `listAllPublic`（**公共集合分页拉全，不做 ownerId/childId 归属过滤**）；新增集合常量 `book_library`。
- **官方精选种子数据**：`miniprogram/scripts/seed_book_library.json`（100 本，`0-3`/`3-6`/`6-9`/`9-12` 各 25 本，覆盖绘本/桥梁书/章节书/科普，含 12 套系列书 `volumes[]`）+ `miniprogram/scripts/README.md`（云开发控制台建集合〔所有人可读〕并导入的操作说明）。

#### 变更
- **书架 join 水合**：`pages/reading/reading.js` 的 `refresh()` 在 `groupBySeries` 之前新增 `_hydrateFromLibrary(books)`——对带 `libraryUuid` 的书一次性从 `book_library` 回填 `title/author/coverExternalUrl/ageRange/type/description`，**书自身已有手动值则保留、不覆盖**；置于封面水合之前以复用 `coverExternalUrl`。
- `reading-service._syncBookProgress` 打卡完成判定处新增 `TODO P1`：读完（status→done）时同步 `book_library.readFinishCount +1`（需幂等）。

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
