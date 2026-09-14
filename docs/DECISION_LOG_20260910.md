# Sprout 方案校准决策日志（2026-09-10）

> 决策性质：**方案级 Review 后的一次性对齐定版**。所有未决冲突自本文档签发之时起，以下列决策为 SSOT（单一事实来源），相关文档与代码在本轮内同步更新完毕。
> 签发：李硕
> 下次重新审议触发条件：双端策略切换（路径 A → 路径 B）、用户规模 ≥ 100 家庭、或 V2 立项时。

---

## 0. 核心顶层决策：双端对齐策略 → 路径 A

**最终选择：路径 A（小程序主导，Flutter 副驾驶纯本地）。**

- **小程序端**：全家主入口（含爷爷奶奶等非技术用户），数据 100% 在 CloudBase（云数据库 / 云存储 / 云函数），微信随手可用。
- **Flutter App 端**：仅本人使用的"离线可用 + AI 润色 + 重度分析"高级版，数据完全独立（Local-First SQLite + 系统级备份 iCloud / Auto Backup），不依赖 CloudBase SDK 与网络。
- **双端打通共享**：不作为 V1~V1.5 的范围，列入 V3 远期目标（届时双端 ownerId 体系、同步冲突处理、CloudBase 接入 Flutter 再议）。
- **跨端口径统一**：无论双端是否打通共享数据，**业务规则口径必须 100% 一致**，由 `docs/AGGREGATION_RULES.md` 作为跨端 SSOT 维护。所有双端独立实现的聚合/派生/状态跃迁逻辑，均须以此文档为唯一准绳。

---

## 1. 8 处文档-落地硬冲突定稿

### 冲突 1：多孩子档案 V1 范围
- **冲突点**：PRODUCT_SPEC §5 L168 写「未规划 / V1 单孩子只存一行」，但同文档 §8.2 children 集合表又写「多孩子 + sortOrder」，且小程序端多孩子切换器 + 家长角色 + 多孩子 ActionSheet 已全部落地。
- **定稿**：✅ **多孩子是 V1 P0（已落地小程序端）；Flutter 端列入 V1 P1**。
- **待修订文档**：PRODUCT_SPEC.md §5、技术方案.md §4.2 Child 表（加 sortOrder/gender/gradeOverride 字段，Flutter schemaVersion 升到 3）。

---

### 冲突 2：课程单日停课/调课例外（CourseExceptions）V1 范围
- **冲突点**：技术方案 v1.4 §1.2 写「V1 支持单日停课/调课例外」+ ER 完整 COURSE_EXCEPTIONS 表，但 PRODUCT_SPEC §5 标「待开发」，实际两端 0 实现。
- **定稿**：✅ **V1 范围降为 P1 简化版 excludedDates**（schedule_items 加 `excludedDates[]` 字段存停课日期字符串，MVP 解决 80% 请假/放假场景）；独立 CourseExceptions 集合（cancel/reschedule/改时段）列入 V1.1 / V2。
- **待修订文档**：技术方案.md §1.2（标注「MVP 简化」）、PRODUCT_SPEC.md §5（改为 P1 简化版 excludedDates）。

---

### 冲突 3：扫码录入主/次入口地位
- **冲突点**：技术方案 v1.4 §2.2.6 全量写「扫码降为次要入口，默认主路径搜书名手填」；实际小程序书架 FAB ①扫码 ②手填（且手填不含搜书名入口）、Flutter 端 mobile_scanner 未落地。
- **定稿**：✅ **双端可以不一致**。小程序端：主入口扫码（家人操作，扫家里绘本 ISBN 成本远低于打字）；Flutter 端：次要入口扫码（本人操作，搜书名/手填为主）。
- **待修订文档**：技术方案.md §2.2.6 开头明确「双端策略分离」；小程序端数据源改为实际落地的「探数主源 + Google Books 兜底」，Flutter 端保持原 Open Library 方案 + 手填兜底。

---

### 冲突 4：系列书面板 / 套书聚合 V1 范围
- **冲突点**：技术方案 v1.4 §1.2 L23 写「套书 V1 按独立书处理（整套聚合进度 V2）」，但小程序端 series-service 聚合 + 叠层卡 + volumes[] 系列面板 100% 已落地，BOOK_LIBRARY_BACKLOG 全文围绕「系列书」设计。
- **定稿**：✅ **系列书面板展示 + 分册管理 + 叠层封面是 V1 P1 已落地（小程序端）**；「整套聚合进度条（已读册数÷totalVolumes）」列入 V2。
- **待修订文档**：技术方案.md §1.2 + §4.2 Series 表说明（删掉「按独立书处理」）、PRODUCT_SPEC.md §8.4 待办保持已落地标记。

---

### 冲突 5：周报长图导出 / 分享 V1 范围
- **冲突点**：技术方案 v1.4 §1.2 L25 写「V1 支持导出长图轻分享」，PRODUCT_SPEC §5 写「预留」，两端 0 实现。
- **定稿**：✅ **分享为 V2 范围**。等 AI 周报润色文案 + editedText 编辑版做完后，再 canvas 画长图分享 ROI 最高；V1 仅支持系统级截图，不做代码内导出。
- **待修订文档**：技术方案.md §1.2（降为 V2 标注）、PRODUCT_SPEC.md §5 保持「预留」。

---

### 冲突 6：扫码数据源（Open Library vs 探数+Google Books 兜底）
- **冲突点**：技术方案 v1.4 §2.2.6 仅列「Open Library（境外，英文书为主）」作为唯一扫码数据源；实际小程序 bookLookup 云函数走「探数 TANSHU_KEY（境内中文书目）主源 + Google Books 兜底」。
- **定稿**：✅ **双端数据源独立**。小程序端沿用探数主源 + Google Books 兜底（中文绘本命中率远高于 Open Library）；Flutter 端按原方案 Open Library，失败直跳手填。两端云函数密钥与 API 凭证独立管理。
- **待修订文档**：技术方案.md §2.2.6 按双端策略分开写，删掉原方案的「统一 Open Library」字样。

---

### 冲突 7：书架 BOOK_STATUS 枚举口径（finished vs done）
- **冲突点**：BOOK_LIBRARY_BACKLOG.md 想读清单写 `finished`，小程序 constants.js BOOK_STATUS.DONE = `'done'` → mine.js 统计按 `=== 'finished'` 写 → 触发 P0 Bug「已读完恒为 0」。
- **定稿**：✅ **统一枚举值 `done`**（代码侧大范围使用，改代码成本远高于改文档）。
- **待修订文档**：BOOK_LIBRARY_BACKLOG.md 所有 `finished` → `done`。
- **待修代码 Bug**：小程序 `pages/mine/mine.js` L161 `status === 'finished'` → `status === 'done'`。

---

### 冲突 8：周报 generateWeeklyReport 优先级
- **冲突点**：小程序架构重设计 §2.7 标 generateWeeklyReport 云函数「P2 新增」，PRODUCT_SPEC §8 仅标「后续（云函数聚合）」；但 Flutter 端 ReportGenerator + workmanager 已按 V1 实现；小程序当前 report.js 完全实时聚合无落库。
- **定稿**：✅ **小程序端升为 P1（与 Flutter 对齐）**。理由：①无落库则历史周报无法回溯、成长档案无归档；②空周不生成 + 去重幂等 + 周日 20:00 自动生成，三项规则与 Flutter 端必须口径一致（见 AGGREGATION_RULES.md）。
- **待修订文档**：小程序架构重设计 §2.7 云函数 generateWeeklyReport P2→P1；PRODUCT_SPEC.md §8.4 待办第 6 条追加「generateWeeklyReport 云函数 + 周报复用 service」。
- **待补代码**：db.js 建 `weeklyReports` 快捷 API；services/report-service.js 抽离聚合口径；report 页优先读 weekly_reports 集合兜底实时算；云函数 generateWeeklyReport 新增。

---

## 2. V1 / V1.1 / V2 版本边界冻结

| 版本 | 范围定义 | 小程序状态 | Flutter 状态 |
| --- | --- | --- | --- |
| **V1 MVP（冻结，只修 Bug 和细节，不加新功能）** | 日历三源聚合 + 记录/阅读/课表增删改查 + 书架三分区 + 系列书面板 + 扫码识书（探数+GB）+ 精选书库 P0 + 多孩子档案 + 家长角色 + 实时周报（本周/上周） | ✅ **当前已实现（冻结）** | ⏳ 70%，本轮先不对齐，双端独立 |
| **V1.1（本轮推进，P1）** | ①周报闭环（weekly_reports 落库 + generateWeeklyReport 云函数 + 历史列表）；②调课停课简化版 excludedDates；③课表编辑 + startDate/endDate UI + type chip（校内/课外班）；④书库热度 readFinishCount（bookLibraryInc 云函数）；⑤组件收敛（bottom-sheet/empty-state）；⑥P0/P1 Bug 修复（safe-area、提交锁、细节体验 50 项）；⑦运维文档 + 合规文档 | ⏳ **本轮推进目标** | 与小程序口径同步，但存储层仍用 Local-First SQLite |
| **V2（质变增强，立项后再做）** | AI 周报润色（国内 LLM）+ editedText 编辑版 + 长图导出分享；多端数据同步（CloudBase ↔ Flutter，视路径 A→B 切换决定）；语音记录；扫码冷启动优化；书库共建 P1（投稿/点赞/完读率） | 🔮 未定 | 🔮 未定 |
| **V3（远期）** | 双端数据 100% 打通共享（路径 B）；孩子本人参与记录端；社交化分享与家庭树；儿童专属端独立 App/小程序 | 🔮 未定 | 🔮 未定 |

---

## 3. 运维 / 密钥 / 合规动作签发

1. **密钥管理**：本轮内所有云函数 API Key 硬编码全部迁出，改由 CloudBase 云环境变量注入（`process.env.TANSHU_KEY` 等）；密钥清单与轮换策略见 `docs/OPERATIONS_RUNBOOK.md` §3。
2. **数据导出/备份**：小程序端 V1.1 必做 `exportData` 云函数 + 「删除孩子档案/删除我的全部数据」入口，见 `docs/PRIVACY_COMPLIANCE.md`。
3. **首次使用协议**：小程序 V1.1 提审前必须加「家长授权同意使用协议」弹层（微信审核必查儿童类），见合规文档 §2。
4. **超限告警**：CloudBase 免费额度探测 + 超限 banner 提示，写入运维手册 §2。
