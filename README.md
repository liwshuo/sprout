# Sprout 🌱

> 孩子成长记录 App —— 用心记录每一天的点滴成长。

Sprout 是一款帮助家长记录孩子日常成长的移动应用，涵盖日常事项记录、阅读打卡、课表管理以及自动周报生成，让孩子的每一步成长都清晰可见、值得回味。

## 📦 Monorepo 结构

本仓库采用 Monorepo 组织多端代码：

```
sprout/
├── app/            # Flutter App（iOS + Android 双端，原有全部代码）
├── miniprogram/    # 微信小程序「萌芽成长册」脚手架
├── docs/           # 产品文档
├── CHANGELOG.md    # 变更记录
└── README.md       # 本文件
```

- **`app/`** → Flutter App。所有 Flutter 命令（`flutter pub get`、`flutter run` 等）均需在 `app/` 子目录下执行。
- **`miniprogram/`** → 微信小程序。使用「微信开发者工具」导入时，请打开 `miniprogram/` 子目录作为项目根目录。云开发环境 ID 已在 `app.js` 的 `CLOUD_ENV`（`cloud1-d3gh6o81f2ba198c9`）中配置；首次使用需按下文「小程序云开发部署」章节上传部署 `login` / `bindPhone` 云函数。
- **`docs/`** → 产品文档与技术设计。

## ✨ 功能列表

- **首页日历视图**：以日历为核心，快速回顾每日记录与功能入口。
- **日常事项记录**：随手记录孩子的日常点滴，支持文字、备注与图片。
- **阅读记录打卡**：记录每次阅读的书目、时长与心得，养成阅读习惯。
- **课表管理**：管理每周课程安排，按星期查看课程时间与地点。
- **周报生成与查看**：自动汇总一周的日常与阅读数据，生成成长周报。

## 🛠 技术栈

| 分类 | 选型 |
| --- | --- |
| 框架 | Flutter + Dart |
| 状态管理 | [Riverpod](https://pub.dev/packages/flutter_riverpod) |
| 路由 | [go_router](https://pub.dev/packages/go_router) |
| 本地数据库 | [drift](https://pub.dev/packages/drift) + sqlite3 |
| 网络请求 | [dio](https://pub.dev/packages/dio) |
| 后台任务 | [workmanager](https://pub.dev/packages/workmanager) |
| 其他 | path_provider、shared_preferences、image_picker、intl |
| 平台 | iOS + Android 双端 |

## 📂 Flutter 项目结构（`app/`）

```
app/
  lib/
    main.dart              # 应用入口
  app.dart               # MaterialApp 配置
  core/
    router/              # go_router 路由配置
    theme/               # 主题
    utils/               # 通用工具
  data/
    models/              # 数据实体：记录、书目、课表、周报
    repositories/        # 仓库层
    local/               # drift 数据库相关
  features/
    home/                # 首页日历视图
    daily/               # 日常事项记录
    reading/             # 阅读记录打卡
    schedule/            # 课表管理
    report/              # 周报生成与查看
  shared/
    widgets/             # 通用组件
```

## 🚀 快速开始

前置要求：已安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)（3.3.0 及以上）。

```bash
# 1. 克隆仓库
git clone https://github.com/liwshuo/sprout.git
cd sprout/app

# 2. 获取依赖
flutter pub get

# 3. 生成 drift 数据库代码（首次或修改表结构后执行）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行
flutter run
```

> 说明：`app/lib/data/local/app_database.g.dart` 为 drift 生成文件，需执行第 3 步 build_runner 后生成，未生成前 IDE 会提示缺失该 part 文件，属正常现象。

## ☁️ 小程序云开发部署（重要）

> ⚠️ **登录失败 / 添加记录失败，绝大多数是因为云函数还没部署到云端。**
> `login`、`bindPhone` 云函数只是本地代码，必须在「微信开发者工具」中手动上传部署后才能被 `wx.cloud.callFunction` 调用，否则会报 `FunctionName Not Found`（errCode `-501000`），进而导致 `ownerId` 为空、记录无法写入。

**部署步骤（每次修改云函数后都要重做）：**

1. 用「微信开发者工具」打开 `miniprogram/` 目录作为项目根目录。
2. 顶部工具栏点击「云开发」，确认已开通并选中云环境 `cloud1-d3gh6o81f2ba198c9`（已在 `app.js` 的 `CLOUD_ENV` 中写死）。
3. 在左侧资源管理器展开 `cloudfunctions/`，分别右键：
   - `cloudfunctions/login` →「**上传并部署：云端安装依赖（不上传 node_modules）**」
   - `cloudfunctions/bindPhone` →「**上传并部署：云端安装依赖（不上传 node_modules）**」
4. 等待右下角提示「上传成功」。
5. 在「云开发控制台 → 数据库」中创建以下集合（若不存在），并将权限设为「仅创建者可读写」：
   `users`、`children`、`daily_records`、`series`、`books`、`reading_logs`、`schedule_items`、`weekly_reports`。
6. 重新编译小程序，进入「我的」页点击登录；登录成功后即可正常添加记录。

**自检：** 若「我的」页 toast 提示「请先在开发者工具部署 login 云函数」，或添加记录提示「请先到我的登录」，说明云函数仍未部署或登录未成功。

## 📄 License

本项目仅用于个人成长记录用途。
