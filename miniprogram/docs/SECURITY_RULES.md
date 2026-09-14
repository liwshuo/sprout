# CloudBase 数据库安全规则（多家长共享）

> 小程序端权限方案：**自定义安全规则做主鉴权 + 敏感写操作走 `childShare` 云函数兜底**。
> 本文的 JSON 可直接粘贴进「云开发平台 → 文档型数据库 → 集合管理 → 权限管理 → 切换到安全规则」。
> 任何规则/集合变动都应同步更新本文件与 `PRODUCT_SPEC.md`、`CHANGELOG.md`。

---

## 0. 方案与两条硬约束（务必先读）

共享模型以「孩子」为锚点：一个孩子可被多位家长共同读写同一份数据。鉴权判定统一为：

```
auth.openid in doc.members
```

`members` = **有权访问该孩子的原始 openid 数组**，冗余在 `children` 与每条业务文档上。前端查询时必须显式携带 `members: '{openid}'`；`{openid}` 是 CloudBase 安全规则身份占位符，由服务端替换为当前调用者 openid，不能替换成客户端缓存的实际字符串。

选择「纯冗余 members」而非官方推荐的 `get('database.集合.${doc.childId}')` 跨集合查询，是因为本项目 schema 有两条硬约束：

1. **安全规则只有 `auth.openid`，拿不到 unionid。** 但 App 身份是 `ownerId = unionid || openid`。若 `members` 存 `ownerId`，当某家长有 unionid 时规则永远匹配不上。
   → 结论：`members` **必须存原始 openid**（对齐 `auth.openid`），与 App 内部用于归属/过滤的 `ownerId` 是两套 ID，互不替代。
2. **业务文档的 `childId` 存的是自定义 `uuid`，不是文档 `_id`。** 而 `get('database.children.${docId})` 只能按 `_id` 寻址，用 `uuid` 无法命中。
   → 结论：跨集合 get() 方案在本 schema 下不可用；改为把 `members` 直接冗余到业务文档，规则里零 `get()`，天然绕开「单规则最多 3 次 `get()`」的上限。

`members` 的维护全部由 `childShare` 云函数负责（见 §3），前端只在**创建**文档时盖初始 `members`（`utils/db.js` 的 `create()` 已实现）。

---

## 1. 集合分组

| 分组 | 集合 | 前端权限 | 规则要点 |
| --- | --- | --- | --- |
| 孩子档案 | `children` | 安全规则 | `auth.openid in doc.members` |
| 业务数据 | `daily_records` `books` `todos` `schedule_items` `reading_logs` `series` `weekly_reports` | 安全规则 | `auth.openid in doc.members` |
| 成员关系 | `child_members` | 只读自己 + 写全禁 | 读 `doc.openid == auth.openid`；写走云函数 |
| 邀请码 | `child_invites` | 全禁 | 读写全走云函数 |
| 账号 | `users` | 只读写自己 | `doc.openid == auth.openid` |
| 公共书库 | `book_library` | 所有人可读 | `read:true / write:false` |

---

## 2. 各集合规则 JSON

### 2.1 `children`（孩子档案）

```json
{
  "read": "auth.openid in doc.members",
  "create": false,
  "update": "auth.openid in doc.members",
  "delete": false
}
```

- `create`：前端禁用，统一走 `childShare.createChild`，由云函数一次完成孩子档案与创建者成员关系写入，避免产生孤儿档案或伪造 owner 成员。
- `delete`：物理删除一律禁止，删除走软删（`isDeleted=true` 的 `update`），可同步、可追溯。

### 2.2 业务数据集合（7 个，规则完全一致）

适用：`daily_records`、`books`、`todos`、`schedule_items`、`reading_logs`、`series`、`weekly_reports`

```json
{
  "read": "auth.openid in doc.members",
  "create": "auth.openid in doc.members",
  "update": "auth.openid in doc.members",
  "delete": false
}
```

- 同一孩子下的所有家长（openid 都在 `members` 里）均可读写同一份数据，天然满足「多家长协同」。
- `members` 由 `db.create()` 在写入时从所属 `children.members` 复制；新家长加入/退出后由 `childShare` 云函数批量回填（§3）。

### 2.3 `child_members`（孩子↔家长 成员关系）

```json
{
  "read": "doc.openid == auth.openid",
  "write": false
}
```

- 前端若直接查询，只能读到**自己的**成员记录；正式孩子列表统一调用 `childShare.listChildren`，待办列表调用 `childShare.listTodos`，其余共享业务集合列表调用 `childShare.listChildData`。云函数先校验成员身份再返回数据，避免复杂范围查询/排序无法通过前端规则证明而被静默降级为空。
- `listChildren` 同时用 `ownerId` 校验创建者自己的孩子；发现孩子档案存在但 owner 成员关系或 `members` 缺失时自动补齐，用于修复异常中断产生的孤立数据。
- **成员管理列表**（某孩子的全部成员）同样必须调用 `childShare` 的 `listMembers`（云函数以管理员身份读取，规则不拦）。
- 所有写入（加入/移除/退出/删除孩子）一律走 `childShare` 云函数；`deleteChild` 仅允许档案创建者调用，并统一软删除档案、成员关系、邀请及关联业务数据。
- 项目尚未上线，无历史数据迁移：新建孩子由 `childShare.createChild` 直接写入创建者 `openid` 与初始 `members`；受邀成员由 `acceptInvite` 写入。

### 2.4 `child_invites`（邀请码）

```json
{
  "read": false,
  "write": false
}
```

- 邀请码涉及一次性校验与防枚举，前端完全不可直读直写；`createInvite` / `acceptInvite` 全部在 `childShare` 云函数内完成。

### 2.5 `users`（账号）

```json
{
  "read": "doc.openid == auth.openid",
  "write": "doc.openid == auth.openid"
}
```

- 仅能读写自己的账号文档（角色 `role`、昵称、头像等）。
- ⚠️ 「前端查询条件必须是安全规则的子集」：前端查询 `users` 时须使用 CloudBase 身份占位符 `where({ openid: '{openid}' })`，由服务端替换为当前调用者 openid；不要传客户端缓存的实际字符串，也不要用 `where({ ownerId })`。当前登录初始化已完全收口到 `login` 云函数，不再由客户端重复 upsert `users`；手机号绑定继续走 `bindPhone` 云函数。

### 2.6 `book_library`（公共精选书库，只读）

```json
{
  "read": true,
  "write": false
}
```

- 分龄书单等公共只读数据，所有登录/未登录用户可读；写入只由后台/控制台导入完成。

---

## 3. 云函数兜底（`childShare`）

`members(openid)` 的一致性由 `childShare` 统一维护，核心函数 `syncChildMembers(childId)`：

1. 查 `child_members` 拿该孩子全部有效成员的 `ownerId`；
2. 经 `users` 把每个 `ownerId` 解析成原始 `openid`（无 unionid 时 `ownerId===openid`），顺带回填 `child_members.openid`；
3. 去重后写回 `children.members`，并**批量**回填全部业务集合中该 `childId` 下文档的 `members`。

触发时机：

| action | 说明 | 是否触发 syncChildMembers |
| --- | --- | --- |
| `createChild` | 创建孩子档案 + 创建者成员关系 | 否（直接写入初始 members） |
| `createInvite` / `getQrCode` | 生成一次性邀请码 / 小程序码 | 否 |
| `acceptInvite` | 凭码加入，写 `child_members`（含 `openid`） | ✅ 是 |
| `removeMember` | 创建者移除成员（软删） | ✅ 是 |
| `leaveChild` | 非创建者主动退出（软删） | ✅ 是 |
| `listMembers` | 成员管理列表（管理员身份读取） | 否 |

> 云函数以管理员身份运行会**绕过安全规则**，因此每个写入动作内部都各自校验了调用者身份与成员资格（`ctxOwnerId` 取自登录态注入的 `UNIONID/OPENID`，不信任 `event` 传入的 id）。

---

## 4. 首次上线步骤（Rollout）

项目尚未上线、没有存量数据，因此**不需要任何迁移或 backfill**。按以下顺序初始化即可：

1. **部署云函数**：微信开发者工具右键 `cloudfunctions/childShare` →「上传并部署（云端安装依赖）」。
2. **配置集合规则**：按 §2 逐个集合在控制台粘贴规则 JSON 并保存。
3. **创建首个孩子档案**：`db.children.create()` 调用 `childShare.createChild`，云函数直接写入 `members:[当前用户 openid]` 与创建者成员记录，无迁移步骤。
4. **前端适配**：成员管理列表调用 `childShare.listMembers`（不从前端直查其他人的 `child_members`）。
5. **回归验证**（两个测试账号 A=创建者、B=受邀家长）：

| 场景 | 期望 |
| --- | --- |
| A 读/写自己孩子的记录 | 成功 |
| B 未加入前读 A 孩子的记录 | 空结果 / 拒绝 |
| B 扫码 `acceptInvite` 加入后读写同一孩子 | 成功（members 已含 B 的 openid） |
| B 直接 SDK 改 `child_members` 提权 | 失败（write:false） |
| A `removeMember` 移除 B 后，B 再读该孩子数据 | 拒绝（members 已剔除 B） |
| 任意人直读 `child_invites` | 拒绝 |

---

## 5. 已知边界

- **成员变更是「批量回填」而非实时联动**：`syncChildMembers` 在加入/移除时遍历该孩子的业务文档更新 `members`，数据量极大时（单孩子文档数很多）有一次性写放大。当前家庭场景数据量小，可接受；若未来单孩子文档数破万，再评估改为 `get()` + 将 `childId` 对齐为 `_id` 的方案。
- 规则只拦**前端 SDK 调用**，云函数不受约束——敏感逻辑的最后一道防线始终在云函数内部的显式校验。
- 规则语法（`in`、模板串、`get()` 次数等）以 [官方安全规则文档](https://docs.cloudbase.net/database/security-rules) 当前版本为准。
