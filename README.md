# Study Companion

Study Companion 是一个只供个人使用的、本地优先的学习管理 App。后续使用 Flutter 开发，V0.1 先聚焦于任务、学习时长、考试倒计时和学习素材积累。

## 当前状态

当前仓库已经由官方 `flutter create .` 生成真实 Flutter 工程，并完成 V0.1 核心逻辑、SQLite 和基础 UI 的分阶段迁移。`pre_flutter/` 仍保留为原始草稿参考，不作为正式源码运行。

已整理的内容：

- V0.1 范围、验收条件和非目标：见 [REQUIREMENTS.md](REQUIREMENTS.md)
- 本地数据模型和 SQLite 规划：见 [DATA_MODEL.md](DATA_MODEL.md)
- 页面、导航和数据流：见 [UI_STRUCTURE.md](UI_STRUCTURE.md)
- 分阶段开发计划：见 [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md)
- Flutter 安装后的操作顺序：见 [NEXT_STEPS.md](NEXT_STEPS.md)
- Flutter 安装前的可复用代码草稿：见 [PRE_FLUTTER_STATUS.md](PRE_FLUTTER_STATUS.md)

当前迁移状态：

- 第一阶段模型、统计和番茄钟已通过 `flutter analyze` 与 `flutter test`。
- 第二阶段 `sqflite`、`path` 和数据库层已通过 `flutter analyze` 与 `flutter test`。
- 第三阶段页面和组件已通过 `flutter analyze` 与 `flutter test`。
- 第四阶段已在 Android 真机 `3B1F6HE5Z1WJJ8Z1` 启动，并通过 adb 切换到统计 Tab 验证交互。
- 首页、每日待办和统计已接入 SQLite 自动保存；积累页仍保留原来的 demo 页面，下一轮再重做。

## Flutter 安装前代码

`pre_flutter/` 保存可以提前编写的模型、统计、番茄钟、SQLite 接入草稿、页面草稿和测试草稿。它不是 Flutter 工程，不能在当前目录下直接运行 `flutter run`；安装 Flutter 后按 [PRE_FLUTTER_STATUS.md](PRE_FLUTTER_STATUS.md) 的映射复制到正式工程。

## 产品原则

- 单用户、本地优先、离线可用。
- 先做可用的 V0.1，再按需要增加能力。
- 数据访问通过简单的 repository 隔离，便于后续把本地存储替换为 SQLite。   


- 暂不引入后端、登录、同步、OCR、ASR、LLM、支付、推送或社交功能。

## 预计技术方案

- Flutter + Dart。
- 轻量状态管理：`provider` 与 `ChangeNotifier`。
- 本地持久化：首个可运行版本接入 SQLite（预计使用 `sqflite` 和 `path_provider`）。
- 时间统一保存为 ISO 8601 UTC 字符串，展示时转换为本地时区。
- 页面按功能分组，避免 Clean Architecture、DDD 或微服务等过度设计。

## 目录约定（Flutter 工程生成后）

```text
lib/
  app/                 # MaterialApp、路由、主题、依赖注入
  core/                # 日期、格式化、通用组件和错误类型
  data/                # SQLite 数据库、表定义、repository 实现
  features/
    home/              # 首页
    todos/             # 待办
    statistics/        # 统计
    materials/         # 积累
    exams/             # 考试设置
    focus_timer/       # 番茄钟
```

正式 Flutter 工程已经存在；`pre_flutter/` 下的同名文件只作为迁移前参考。


