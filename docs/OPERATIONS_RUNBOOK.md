# Sprout 运维与发布 Runbook

> 文档唯一交叉引用：[DECISION_LOG_20260910.md](./DECISION_LOG_20260910.md) §0
> 双端策略：路径 A（小程序 V1~V1.5 与 Flutter Local-First 不打通，V3 远期才打通）

---

## 0. 环境与账号

### 0.1 微信云开发环境

| 项 | 值 |
|---|---|
| 环境 ID | `cloud1-d3gh6o81f2ba198c` |
| 地域 | 上海（默认） |
| 计费方式 | 按量付费（默认免费额度起步） |
| 登录方式 | 微信开放平台 → 云开发控制台 |

### 0.2 集合与权限（CloudBase 控制台手工建表清单）

小程序端所有集合必须在「云开发控制台 → 数据库」**先建好**，并配置「权限设置」。
建表顺序与 SSOT 口径对齐 [技术方案.md §4](./技术方案.md)。

| 集合名 | 权限建议 | 备注 |
|---|---|---|
| `users` | 仅创建者可读写 | 每用户 1 条 |
| `children` | 仅创建者可读写 | 多孩子：ownerId 过滤 |
| `daily_records` | 仅创建者可读写 | 量最大，注意索引 |
| `books` | 仅创建者可读写 | seriesId 可 null（独立绘本） |
| `series` | 仅创建者可读写 | 软删 books 不级联，由业务 setNull |
| `reading_logs` | 仅创建者可读写 | 第三源，量可能大 |
| `schedule_items` | 仅创建者可读写 | 含 excludedDates[] |
| `weekly_reports` | 仅创建者可读写 | 云函数写，前端读 |
| `book_library` | **所有用户可读，仅管理端可写** | 公共集合，无 ownerId/childId |

> ⚠️ **`book_library` 必须单独配置「所有用户可读」**，否则精选书库首页空白。写入走控制台 CSV 导入或后台管理员账号，小程序端一律禁止直接 write。

### 0.3 索引建议（按量付费性能基石）

在云开发控制台 → 数据库 → 对应集合 → 索引管理 手工创建：

```
daily_records:   (ownerId, childId, eventDate)   DESC
books:           (ownerId, childId, updatedAt)   DESC
reading_logs:    (ownerId, childId, readDate)    DESC
reading_logs:    (ownerId, childId, bookUuid)    DESC  （某本书的进度）
weekly_reports:  (ownerId, childId, weekStart)   DESC  （UNIQUE 语义，云函数幂等）
schedule_items:  (ownerId, childId, weekday)     ASC   （按周几分组）
```

**未建索引后果**：>1000 条后 listAllPaged 会出现 1~5s 延迟甚至触发 CloudBase 超时回退空数组。

---

## 1. 密钥管理（硬约束：禁止明文入库）

### 1.1 当前密钥清单

| 密钥名 | 注入方式 | 使用位置 | 说明 |
|---|---|---|---|
| `TANSHU_KEY` | CloudBase **云环境变量** → `process.env.TANSHU_KEY` | 云函数 `scanBookMetadata` / 未来 `generateWeeklyReport` | 探数中文书目查询主源 |
| 微信 AppID / AppSecret | CloudBase 托管（无需用户注入） | `wx.cloud.callFunction` 内部鉴权 | — |

### 1.2 TANSHU_KEY 注入步骤（必做）

1. 打开云开发控制台 → `cloud1-d3gh6o81f2ba198c`
2. 进入「云函数」→ 左侧「环境变量」Tab（或逐个函数 → 配置 → 环境变量）
3. 对需要请求第三方 API 的云函数（如 `scanBookMetadata`、未来 `generateWeeklyReport`）逐个添加：
   ```
   变量名：TANSHU_KEY
   变量值：<探数平台申请到的 Bearer Token / API Key>
   ```
4. 保存后**重新部署**云函数（修改 env 不会自动热加载）

### 1.3 密钥轮换 Runbook

当 TANSHU_KEY 泄露或到期时：
1. 探数后台生成新 Key
2. 云开发控制台 → 批量/逐个更新云函数 env
3. **逐个重新部署** 受影响函数
4. 用微信开发者工具 → 云函数 → 本地触发一次 `scanBookMetadata` 做回归，确认 200 OK

> ⚠️ 禁止在任何 `.js` / `.json` / `project.config.json` / `app.js` 里硬编码 TANSHU_KEY。
> 本地开发调试时可用开发者工具「云函数本地调试 → 环境变量面板」临时注入，**不要存进 git**。

---

## 2. 云函数部署流程

### 2.1 目录结构
```
miniprogram/cloudfunctions/
  ├── login/                     # 静默登录（getOpenId + 建 users 文档）
  ├── scanBookMetadata/          # 扫码查书名（TANSHU + Google Books 兜底）
  ├── generateWeeklyReport/      # V1 P1：周日 20:00 生成周报（幂等）
  ├── bookLibraryInc/            # V1 P1：书库热度字段安全自增
  └── exportData/                # V2：数据导出 ZIP
```

### 2.2 部署操作（微信开发者工具）

1. 右键 `cloudfunctions/<函数名>` → **上传并部署：云端安装依赖（不上传 node_modules）**
2. 控制台 → 云函数 → 函数名 → 版本 → 发布新版本（生产建议用版本别用别名）
3. 触发测试：
   - `login`：冷启动小程序，看控制台是否 getOpenId 成功
   - `scanBookMetadata`：扫一本真实 ISBN，看是否返回 title/author
   - `generateWeeklyReport`：用「测试事件」传 `{ forceChildId: "..." }` 手动跑一次

### 2.3 定时触发器（V1.1 启用 generateWeeklyReport）

在 `generateWeeklyReport/config.json` 写入：
```json
{
  "triggers": [
    {
      "name": "SundayEvening",
      "type": "timer",
      "config": "0 0 20 * * 0"
    }
  ]
}
```
Cron 语义：**每周日 20:00 CST** 跑一次。
云函数内按 `(ownerId, childId, weekStart)` 做 upsert 幂等，重跑不会生成双份。

---

## 3. 免费额度与成本估算

> CloudBase 按量付费默认免费额度（2025 口径，以控制台公示为准）

| 资源项 | 免费额度（月） | Sprout 预估消耗（V1 单家庭 5 用户） | 超出后单价 |
|---|---|---|---|
| 数据库读 | 5 万次 | ~1 万次（记录列表/详情/书籍/课表） | ￥0.015 / 千次 |
| 数据库写 | 3 万次 | ~3 千次（打卡/记录 CRUD） | ￥0.05 / 千次 |
| 云函数调用 | 40 万次 GBs | ~2 万次（扫码/登录/生成周报） | ￥0.00011 / GBs |
| 云存储容量 | 5 GB | ~500 MB（照片/封面） | ￥0.0043 / GB·天 |
| 云存储下行流量 | 5 GB | ~2 GB/月 | ￥0.5 / GB |

### 3.1 月度成本估算（免费额度内）

- **0 ~ 2 个活跃家庭**：￥0（完全在免费额度里）
- **10 个活跃家庭**：云存储下行 → 估计 ￥8 ~ ￥15 / 月
- **50+ 活跃家庭**：建议升级「基础版 199/月」或主动在前端 banner 做**超限提示**

### 3.2 超限防御（前端兜底逻辑）

小程序端对 wx.cloud 返回的错误码做了统一兜底（返回空数组而非 crash）。
当检测到「连续 3 次 db 失败」时，应在首页顶部展示红色非阻塞 banner：
```
"服务暂时繁忙，CloudBase 可能超出免费额度，请稍后再试或联系家长升级套餐"
```
> 这个 banner 是**非阻塞**的（不打断用户操作），符合 [user_profile.md] 「默认极简，交互禁止弹窗」约定。

---

## 4. 云函数日志与告警

### 4.1 日常巡检 Runbook（每周 1 次）

| 项 | 操作路径 | 阈值 |
|---|---|---|
| 慢函数 | 云函数 → 监控 → `scanBookMetadata` 耗时 P95 | > 3s 需排查 |
| 错误率 | 云函数 → 监控 → 全部函数 错误率 | > 1% 告警 |
| 存储增长 | 云存储 → 容量 | > 4GB 做图片压缩策略 |
| 数据库读 | 监控 → 读次数 | 单周 > 1.5 万 → 检查是否有 listAllPaged 漏加条件 |

### 4.2 报警接入（V1.1）

推荐使用「微信云开发告警」→ 绑定飞书/钉钉 Webhook：
- 错误率 > 5%：立即告警
- 单月读次数触达 80%（4 万次）：预警 banner
- 存储容量触达 80%（4GB）：预警 banner

---

## 5. 备份与数据导出

### 5.1 手工备份（每季度 1 次）

1. 云开发控制台 → 数据库 → 每个集合 → 「导出」→ 选择 JSON/CSV
2. 下载加密压缩保存至家庭 NAS / 个人云盘
3. 云存储 → 文件管理器 → 选择按 `ownerId` 前缀 → 打包下载

### 5.2 exportData 云函数（V2 自动化）

V2 提供「我 → 设置 → 导出我的所有数据」入口：
- 走云函数 `exportData`：按 ownerId 汇总所有集合 + 该 owner 下所有云存储文件
- 生成 ZIP → 上传到临时存储目录 → 返回 24h 临时下载链接
- 下载链接一次性失效

---

## 6. 故障处理 SOP

### 6.1 用户反馈「绘本扫码查不到书名」

1. 打开云函数日志 → `scanBookMetadata` → 搜最近 1 小时
2. 如果日志报 `401 Unauthorized` → 重新检查 TANSHU_KEY env 注入 + 重部署
3. 如果日志报 `TANSHU 5xx` → 走 Google Books 兜底分支（已内置，应看到降级日志）
4. 如果 Google Books 也失败 → 前端进入「手动输入书名」模式（已实现 fallback）

### 6.2 用户反馈「本周绘本统计为 0，但实际读了」

（对应 P0 Bug 已修）
1. 打开小程序调试器 → Storage → 看 activeChildId 是否切对孩子
2. 用云开发控制台 → `reading_logs` 集合 → 查对应 childId + readDate 在本周区间
3. 若无数据：检查阅读打卡是否走了 `readingLogs.create`
4. 若有数据但前端 0 → 打开 report.js 看本周是否按 `reading_logs.readDate` 过滤（非 `books.updatedAt`）

### 6.3 小程序白屏 crash

1. 微信开发者工具 → 真机调试 → 抓完整 stacktrace
2. 如果 stacktrace 指向 `db.js listAllPaged` 异常 → 先确认 wx.cloud 是否可用（基础库版本 ≥ 2.14）
3. 如果 stacktrace 指向某个 Page `onLoad` → 检查空态 `[]/''` 保护是否没加（当前所有 list 都兜底 `[]`，白屏大概率是新页面没加空态）

---

## 7. 小程序版本发布流程

### 7.1 三阶段

1. **本地测试**：开发者工具「真机调试」→ 覆盖核心 5 条 Happy Path
   - 建孩子档案
   - 添加绘本 + 一次阅读打卡
   - 添加一节课 + 一次今天不上
   - 生成一条记录 + 上传 1 张图
   - 切到周报页看统计是否非 0
2. **体验版**：开发者工具 → 上传 → 版本管理 → 设为「体验版」→ 扫二维码给至少 1 名真实家庭使用 24h
3. **正式发布**：微信公众平台 → 版本管理 → 提交审核 → 审核通过后发布

### 7.2 版本号约定

对齐 [PRODUCT_SPEC.md §8 双端策略](./PRODUCT_SPEC.md)：

| 版本 | 目标 | 上线门槛 |
|---|---|---|
| V1.0 MVP | 孩子+记录+绘本+课表 4 模块闭环 | Happy Path 通过率 100% |
| V1.1 | weeklyReports 云函数自动生成 + bookLibraryInc + 底部组件收敛 + 告警 | 体验版 24h 无 P0 反馈 |
| V2.0 | 分享 V2 + exportData + 系列书面板 V2 + 预警 banner | 体验版 3 天无 P1 反馈 |
| V3.0 | 双端打通（Flutter ↔ CloudBase 双向同步） | 全量压测通过 + 合规审计通过 |
