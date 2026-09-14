# Sprout 隐私合规白皮书

> 文档唯一交叉引用：[DECISION_LOG_20260910.md](./DECISION_LOG_20260910.md) §0
> 双端策略：路径 A（小程序 V1~V1.5 与 Flutter Local-First 不打通，V3 远期才打通）
> 适用范围：本文件覆盖 微信小程序端（CloudBase 全家桶）；Flutter 端 Local-First 另有 GDPR 补充（V2 补齐）。

---

## 0. 合规框架

适用法律法规（中国境内发布必须全满足）：

| 法规 | 对应条款要点 |
|---|---|
| 《中华人民共和国个人信息保护法》（PIPL） | 最小必要 / 告知同意 / 删除权 / 儿童特别保护 |
| 《儿童个人信息网络保护规定》 | **不满 14 周岁未成年人信息 = 儿童个人信息**，须监护人同意 |
| 《网络安全法》 | 网络运营者身份核验义务 / 数据分级 |
| 微信小程序平台规范 | 用户隐私保护指引（《小程序用户隐私保护指引》必须勾选） |
| GDPR（若未来海外 Flutter 端上架） | 被遗忘权 / DPIA / 数据可携带权 |

**Sprout 核心立场**：儿童成长记录 = 高敏感数据。默认「最少采集 + 家长完全掌控 + 随时可删」。

---

## 1. 数据采集最小化清单

### 1.1 采集字段一览（严格对齐 [技术方案.md §4 表定义](./技术方案.md)）

| 集合 | 字段 | 是否必录 | 采集目的 |
|---|---|---|---|
| users | openId / ownerId / nickName / avatarUrl | 必录 | 鉴权 + 归属 |
| children | **name** / **birthDate** / avatarFileId / gender / sortOrder / gradeOverride | name+birth 必录 | 派生典型年龄 + 计算年级 + 多孩子排序 |
| daily_records | eventDate / title / note / tags / imageFileIds[] / category / mood / durationMinutes | eventDate+title 必录 | 成长记录本身 |
| books | title / author / cover / isbn / status / totalPages / totalChapters / seriesUuid | title+status 必录 | 绘本记录 |
| reading_logs | bookUuid / readDate / pageFrom→To / chapterIndex / durationMinutes / mood | bookUuid+readDate 必录 | 阅读打卡（派生已读页/章） |
| schedule_items | courseName / weekday / startTime / endTime / type / location / teacher / startDate / endDate / excludedDates[] | courseName+weekday+时间 必录 | 课表 |
| weekly_reports | weekStart / weekEnd / 所有聚合字段 | 由云函数自动生成 | 家长周报（不可手动编辑结构） |
| book_library | 公共集合，无任何用户字段 | — | 精选书库，非 PII |

### 1.2 **明确禁止采集的字段**（SSOT 白）

以下字段**永远不允许**写入任何数据库集合：
- ❌ 儿童真实身份证号
- ❌ 家长身份证号 / 手机号 / 真实家庭住址（除非用户手动记在 daily_records.note 里，那是用户自愿）
- ❌ 儿童面部识别特征 / 生物特征
- ❌ GPS 精确坐标（课表 `location` 只是自由文本，不做坐标解析）
- ❌ 第三方广告 ID / IDFA

### 1.3 CloudBase 侧数据隔离

- 所有业务集合强制 **`ownerId + childId` 双归属过滤**（由 `utils/db.js` `_buildWhere` 强制注入，绕过需改代码）
- `book_library` 公共集合**故意不含** ownerId/childId，防止写入归属 PII
- 软删 `isDeleted=true` 不物理删除，目的是「双端同步时不会复活旧数据」；但用户请求「彻底删除」时，运维会在 30 天内物理删除（见 §4.2）

---

## 2. 用户首次启动流程（合规硬点）

### 2.1 首次启动必须有「协议 + 监护人同意」流程

在 `app.js onLaunch` 里，**必须先展示一张全屏协议页（非弹窗，符合 user_profile.md「严禁弹窗」约束）**，内容包括：

1. **《用户协议》**
2. **《儿童个人信息保护规则》**（独立一章，不是附录）
3. **《隐私政策》**（重点加粗：儿童数据处理的监护人同意条款）
4. **「我是孩子的监护人 / 已获得监护人同意」勾选框** + **同意并开始使用** 按钮

**未同意前**：
- 禁止静默调用 `wx.login`
- 禁止 `wx.getUserProfile`
- 禁止调用 `wx.getLocation` / `wx.chooseLocation`（当前 V1 没用到，但写在这里避免 V2 引入时遗漏）

### 2.2 撤回同意

用户在「我 → 设置 → 撤回协议同意」入口可随时撤回。
撤回后：
- 清除本地 `wx.clearStorageSync()`
- 跳回首次协议页，禁止继续使用
- （可选）给出「是否同时申请删除所有云端数据」的二次确认

---

## 3. 儿童数据特别保护

### 3.1 默认监护人代操作

Sprout 的所有数据写入入口，设计上就是**由家长操作**：
- 创建孩子档案：家长输入 name/birth
- 添加记录/绘本/课表：家长操作
- 孩子本人无独立账号（Flutter 端 V3 才考虑儿童子账号，届时补独立 DPIA）

### 3.2 头像与照片处理

`children.avatarFileId` 和 `daily_records.imageFileIds[]` 均存储于：
```
cloudPath: {ownerId}/{childId}/{yyyyMM}/{uuid}.jpg
```
归属清晰，**其他 ownerId 无法枚举**（ownerId 是 openId 派生，不可猜测）。

禁止事项：
- ❌ 上传的照片不能出现在任何公开页面（当前产品本来也没有「分享到公开广场」设计，分享 V2 是**单对单**分享给另一位家长）
- ❌ 禁止对照片做 AI 人脸识别 / 情绪识别（V3 引入前须专项合规 Review）

### 3.3 典型年龄派生

`children.birthDate` → `派生典型年龄` 逻辑严格在前端/云函数**本地计算**，计算结果**不持久化**到 `children` 表，仅在页面渲染时临时持有。避免「再加工 PII」留下额外足迹。

---

## 4. 数据删除权（PIPL 第 47 条 + 儿童规定第 17 条）

### 4.1 删除入口（必须可见，不允许藏超过 3 层）

小程序端删除入口位置：
- **我 → 孩子管理 → 某个孩子 → ⋯ → 删除孩子档案**（级联删除归属该 childId 的所有 records/books/logs/schedule/reports）
- **我 → 设置 → 删除我的所有数据**（级联删除该 ownerId 下所有 children + 所有业务集合 + 所有云存储文件）
- 记录/绘本/课表详情页：**单条删除**按钮（当前已实现软删）

### 4.2 软删 → 物理删除 SLA

| 操作 | 立即生效（用户感知） | 物理删除（运维兜底） |
|---|---|---|
| 单条软删 | 列表/统计立即不显示 | 30 天内由季度运维任务 `PurgeSoftDeleted` 清除 |
| 删除孩子档案 | 孩子立即消失，所有关联业务不显示 | 同上，30 天内物理清 |
| 删除我的所有数据 | 立即退出登录，下次启动强制重新协议页 | 运维 3 个工作日内物理清 + 给用户回执 |

### 4.3 级联软删策略（与 [AGGREGATION_RULES.md §2 软删级联](./AGGREGATION_RULES.md) 对齐）

```
删除 daily_record → isDeleted=true  （无下游）
删除 book        → reading_logs 不级联（保留历史痕迹，仅在 bookUuid 查不到时前端 fallback "已删除绘本"）
                  → books.seriesId  setNull（防止套书聚合出错）
删除 schedule_item → 不级联（周展开直接过滤 excludedDates）
删除 weekly_report → 不级联（纯派生数据）
删除 child       → 该 childId 下所有业务集合 isDeleted=true（由云函数完成，V1 可在前端循环软删，V1.1 搬云函数）
删除 owner       → 该 ownerId 下所有集合 isDeleted=true + 云存储 {ownerId}/ 前缀全删
```

---

## 5. 数据出境与共享

### 5.1 当前无数据出境

V1/V1.1 所有数据仅在 **腾讯 CloudBase 上海地域**存储与处理。

用到的第三方 API：
| 第三方 | 用途 | 数据传输范围 | 是否出境 |
|---|---|---|---|
| 探数 TANSHU | 扫码查中文书目元数据 | **仅传 ISBN**，不传 openId/childId/姓名 | 不出境（国内服务） |
| Google Books | TANSHU 兜底查外文书目 | **仅传 ISBN**，不传 PII | 可能出境（Google IP 在美国） → 但只传 ISBN，属于公共书目数据，非 PII |

> V3 如果接入 OpenAI 生成周报，必须满足 PIPL 第 38 条数据出境评估；当前 V1/V1.1 generateWeeklyReport 只做纯统计聚合，不含 LLM 生成，不触发此条款。

### 5.2 分享 V2 数据最小化

对齐 [PRODUCT_SPEC.md §5 分享 V2](./PRODUCT_SPEC.md)：
- 分享对象**仅限**另一位家长（通过 `users` 表关联，非公开广场）
- 分享内容仅包含「该 childId 下被勾选的条目」，禁止分享整个 ownerId 数据
- 接收方只有**只读权**，不能写入

---

## 6. 第三方 SDK 清单（保持最小化）

V1 只用：
- 微信官方 `wx-server-sdk`（CloudBase 内置）
- 微信官方 `WxPay` SDK（未来 V3 引入会员时加，目前无）

禁止未经合规 Review 引入任何第三方统计 SDK（友盟 / GrowingIO / 神策等）—— 避免额外埋点 PII 泄露。

---

## 7. 数据安全措施

### 7.1 传输安全

- 小程序端 ↔ CloudBase：所有请求走微信官方通道（TLS 1.2+），由框架保证
- 云函数 → 探数 / Google Books：**必须 HTTPS**，禁止 HTTP

### 7.2 存储安全

- 云存储文件 URL：**一律用 `getTempUrls` 动态生成 2 小时临时链接**，禁止拼 `fileID` 直链
- 数据库敏感字段（children.name / birthDate）：当前 V1 不做字段级加密（CloudBase 全库加密已覆盖）；V3 双端同步时加字段级 ChaCha20-Poly1305 信封加密

### 7.3 运维访问约束

- 只有「微信公众平台 → 云开发」的**超级管理员账号**可登控制台看原始数据
- 禁止运维人员（如果未来有）把生产数据下载到个人电脑，调试用**脱敏导出示例**
- 共享账号严禁 1 人多号；离职 24h 内回收管理员权限

---

## 8. 合规审计 Checklist（发布前必打勾）

| 序号 | 项 | 状态 |
|---|---|---|
| 1 | 「小程序用户隐私保护指引」在微信公众平台后台已配置并通过 | ☐ |
| 2 | 首次启动全屏协议页（用户协议 + 儿童信息保护规则 + 隐私政策 + 监护人同意勾选框）已实现 | ☐ |
| 3 | `app.js onLaunch` 未同意前禁止任何 `wx.login` / `wx.getUserProfile` 调用 | ☐ |
| 4 | 我 → 设置 → 撤回同意 入口存在 | ☐ |
| 5 | 删除孩子档案 + 删除我的所有数据 两个入口存在并可触发软删 | ☐ |
| 6 | TANSHU_KEY 已通过 CloudBase 环境变量注入，未在任何代码中硬编码 | ☐ |
| 7 | `book_library` 集合权限配置为「所有用户可读，仅管理端可写」 | ☐ |
| 8 | 云存储 fileID 对外统一用 `getTempUrls` 临时链接，无任何页面直拼 fileID 渲染 | ☐ |
| 9 | 未引入任何第三方统计/埋点 SDK | ☐ |
| 10 | generateWeeklyReport V1.1 纯统计聚合，不含 LLM 生成（无数据出境风险） | ☐ |

---

## 9. 用户可申诉/可联系渠道

小程序「我 → 设置 → 关于 → 家长反馈」入口，提供：
- 飞书/邮箱：家长可以发邮件到 `privacy@sprout.family`（占位，上线前换成真实）
- 申诉响应 SLA：**7 个工作日内答复**；涉及删除权请求的，**3 个工作日内启动处理**
- 结果通知：通过「服务通知」微信模板消息回执（V2 上线）

---

## 10. Flutter 端合规补充（仅占位，V2 填实）

Flutter 端是 **Local-First SQLite 本地存储**（路径 A 不打通）：
- 数据默认只在手机本地，用户不开启 iCloud/Google Drive 同步时，**不会离开设备**
- 同步开启后（V3）：走 end-to-end 加密，云端无法解密原文
- GDPR 合规点：数据可携带权（导出 JSON/CSV）+ 被遗忘权（一键清空本地 + 同步后端删除）

> 本章节 V2 发布前，须完成 Flutter 端 App Store / Google Play 隐私标签填写与独立 DPIA。
