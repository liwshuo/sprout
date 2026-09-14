# Sprout 小程序端测试

本目录是 Sprout 微信小程序端的**单元测试工程**，只测**纯逻辑与鉴权逻辑**，不参与小程序构建，也不会被「构建 npm」打包（仅 `devDependencies`）。

## 运行

```bash
cd miniprogram
npm install        # 首次：安装 jest（node_modules 已在 .gitignore 忽略）
npm test           # 跑全部单测
npm run test:watch # 监听模式
npm run test:coverage # 覆盖率
```

> `node_modules/` 位于 `miniprogram/`，已被仓库根 `.gitignore` 忽略，不会提交。

## 分层测试策略

微信小程序没有统一测试框架，按投入产出分四层，本工程覆盖**第一层**，其余为后续规划：

| 层级 | 手段 | 覆盖对象 | 状态 |
|---|---|---|---|
| ① 纯逻辑单测 | Jest + wx/wx.cloud/wx-server-sdk mock | `utils/*`、`services/*`、`cloudfunctions/childShare` | ✅ 本工程 |
| ② 组件单测 | `miniprogram-simulate` | 自定义组件（如 `child-switcher`） | 规划中 |
| ③ UI 自动化 | `miniprogram-automator` + 开发者工具 CLI | 登录 / 加孩子 / 待办转记录等核心链路冒烟 | 规划中 |
| ④ 云测 / 质量扫描 | 小程序云测（Monkey / Minium / 性能）、代码质量扫描 | 多机型、随机遍历、性能、发布前门禁 | 规划中 |

## 当前覆盖

- `tests/utils/date.test.js` —— 日期工具：起止日、ISO 周几、月历矩阵、课表周展开（起止/排除日）、年龄/年级推导。
- `tests/utils/todo.test.js` —— 待办：分类元信息回落、`listAll` 登录/孩子守卫与 `childShare.listTodos` 收口。
- `tests/utils/db.test.js` —— 共享数据读取收口：`listChildData` 入参、本地过滤/倒序、登录与孩子上下文守卫、云失败回退空。
- `tests/services/calendar-service.test.js` —— 日历四源聚合：类型/数量、待办 `dueDate` 区间过滤、排序、分组、圆点计算。
- `tests/cloudfunctions/childShare.test.js` —— 云函数鉴权：集合白名单、成员鉴权、分页拉全、删除孩子仅创建者、待办转成长记录（未完成拦截 / 幂等去重 / 确定性 ID）。

## 关键约定

- `tests/setup.js`：注入 `wx` / `getApp` / `App` / `Page` 等小程序宿主全局桩；提供 `__setUser` / `__setActiveChild` 设置登录态与当前孩子；静默预期内的 warn/error。
- `tests/helpers/fake-cloud.js`：内存版 CloudBase，实现 childShare 用到的 `collection/where/orderBy/skip/limit/get/add/doc/update/set/remove`、command（`neq/eq/in`）与 `runTransaction`，用于在 Node 下驱动云函数逻辑。

## 不在范围内

- WXML 渲染、页面生命周期、真机交互（属第 ②③④ 层）。
- 真实 CloudBase 网络调用、云存储上传、微信登录授权。
