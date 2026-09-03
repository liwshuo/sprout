# Sprout 🌱

> 孩子成长记录 App —— 用心记录每一天的点滴成长。

Sprout 是一款帮助家长记录孩子日常成长的移动应用，涵盖日常事项记录、阅读打卡、课表管理以及自动周报生成，让孩子的每一步成长都清晰可见、值得回味。

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

## 📂 项目结构

```
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
cd sprout

# 2. 获取依赖
flutter pub get

# 3. 生成 drift 数据库代码（首次或修改表结构后执行）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行
flutter run
```

> 说明：`lib/data/local/app_database.g.dart` 为 drift 生成文件，需执行第 3 步 build_runner 后生成，未生成前 IDE 会提示缺失该 part 文件，属正常现象。

## 📄 License

本项目仅用于个人成长记录用途。
