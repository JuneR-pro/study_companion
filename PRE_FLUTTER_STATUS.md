# Pre-Flutter 状态

本目录是在 Flutter SDK 安装前提前准备的代码草稿。当前没有执行 `flutter analyze`、`flutter test` 或 `flutter run`，因此以下代码均应视为“待 Flutter 安装后验证”。

## 1. 已提前写好的代码

`pre_flutter/lib/` 下包含：

- `models/`：Todo、StudySession、Material、Exam，包含构造函数、`copyWith`、`toMap`、`fromMap` 和 SQLite 所需类型转换。
- `data/app_database.dart`：sqflite 数据库草稿，包含四张表、索引和要求的 CRUD/query 方法。
- `data/demo_data.dart`：待办、学习记录、素材和考试的少量示例数据。
- `services/study_statistics.dart`：今日、指定日期、月度每日、科目汇总、科目占比和连续学习天数。
- `services/todo_filters.dart`：纯 Dart 待办日期筛选。
- `services/pomodoro.dart`：25/45/60 分钟预设、开始、暂停、继续、重置和生成 StudySession 的状态模型。
- `screens/`：HomeScreen、TodoScreen、StatisticsScreen、MaterialScreen，以及四 Tab 的 MainNavigation。
- `widgets/`：PomodoroCard、ExamCountdownCard、TodayStudyCard、RecentTodoCard。
- `app.dart`：最小 MaterialApp 入口草稿。

`pre_flutter/test/` 下包含统计、日期筛选、科目聚合、连续学习天数和番茄钟的测试草稿。

## 2. 可以高度确信的纯 Dart 部分

以下部分不导入 Flutter 或 sqflite，可在安装 Dart/Flutter 后优先验证：

- `lib/utils/date_helpers.dart`
- `lib/models/*.dart`
- `lib/services/study_statistics.dart`
- `lib/services/todo_filters.dart`
- `lib/services/pomodoro.dart`
- `test/` 中除页面外的测试文件

纯 Dart 部分仍需要确认 Dart SDK 版本、时区边界和项目 lint 规则，但不依赖 Flutter UI。

## 3. 必须在 Flutter 安装后验证的部分

- `lib/data/app_database.dart`：需要 `sqflite` 和 `path` 依赖，并需要在 Android 真机/模拟器上验证数据库路径、表创建、升级和读写。
- `lib/screens/`、`lib/widgets/`、`lib/app.dart`：依赖 Flutter Material API，需检查 Material 3 API、表单行为、布局和状态刷新。
- `pre_flutter/test/`：需要 `test` 包；页面测试若后续加入则需要 `flutter_test`。

当前没有安装依赖，也没有假装这些文件已经编译或运行。

## 4. Flutter 安装后需要做什么

在项目根目录执行：

```powershell
.\scripts\check_environment.ps1
flutter create .
flutter pub get
```

然后把 `pre_flutter/lib/` 下的代码复制或按映射移动到正式 `lib/`，再添加依赖：

```powershell
flutter pub add sqflite path provider
flutter pub add --dev test
```

最后依次执行：

```powershell
flutter analyze
flutter test
flutter run
```

## 5. 应复制或移动到正式 `lib/` 的文件

| 预备文件 | 正式位置 |
| --- | --- |
| `pre_flutter/lib/models/*` | `lib/models/` |
| `pre_flutter/lib/utils/*` | `lib/utils/` |
| `pre_flutter/lib/services/*` | `lib/services/` |
| `pre_flutter/lib/data/*` | `lib/data/` |
| `pre_flutter/lib/screens/*` | `lib/screens/` |
| `pre_flutter/lib/widgets/*` | `lib/widgets/` |
| `pre_flutter/lib/app.dart` | `lib/app.dart` |
| `pre_flutter/test/*` | `test/` |

不要把 `pre_flutter/` 当作 Flutter 工程根目录运行 `flutter create`；正式工程根目录仍是项目根目录。

## 6. 第一轮重点检查

1. `pubspec.yaml` 的包名与 import 路径是否一致；若使用包名 import，需要把相对 import 统一为正式包名。
2. `Material` 模型与 Flutter Material API 的命名冲突，页面中已使用别名导入，编译时重点检查相关 import。
3. `sqflite` 的 `Database`、`QueryResult` 和 `Map<String, Object?>` 类型在当前插件版本中的签名。
4. `Material.tags` 的 JSON 编解码，以及 SQLite 中 `bool`/`Duration` 的整数映射。
5. Android Gradle/JDK 版本与 Flutter doctor 的提示。
6. 番茄钟页面的 periodic ticker 生命周期、暂停/继续后的 elapsed 计算，以及结束后只写入一次 StudySession。
7. 待办页面的日期边界、删除确认和状态刷新。
8. 统计页面的本地时区、跨日/跨月记录和连续学习天数边界。

