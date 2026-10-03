# 数据模型与本地存储规划

V0.1 使用简单的实体模型。Flutter 工程生成后，先实现 repository 接口，再接入 SQLite；页面不直接操作数据库。

## 1. 实体

### Todo

| 字段 | 类型 | 规则 |
| --- | --- | --- |
| `id` | TEXT | UUID，主键 |
| `title` | TEXT | 必填，去除首尾空格后长度大于 0 |
| `date` | TEXT | 本地日历日期，格式 `YYYY-MM-DD` |
| `completed` | INTEGER | SQLite 中用 `0/1` 表示布尔值 |
| `createdAt` | TEXT | ISO 8601 UTC 时间 |

索引：`date`、`(date, completed)`。

### StudySession

| 字段 | 类型 | 规则 |
| --- | --- | --- |
| `id` | TEXT | UUID，主键 |
| `subject` | TEXT | 必填；允许使用“未分类”作为默认值 |
| `startTime` | TEXT | ISO 8601 UTC 时间 |
| `endTime` | TEXT | ISO 8601 UTC 时间，可为空（进行中记录不落库或结束后再落库） |
| `duration` | INTEGER | 学习秒数，必须大于等于 0 |
| `source` | TEXT | `pomodoro`、`manual` 等有限值 |
| `note` | TEXT | 可为空 |

索引：`startTime`、`subject`、`(startTime, subject)`。

### Material

| 字段 | 类型 | 规则 |
| --- | --- | --- |
| `id` | TEXT | UUID，主键 |
| `title` | TEXT | 必填 |
| `content` | TEXT | 可为空，保存纯文本或 Markdown 文本 |
| `category` | TEXT | 可为空；V0.1 先使用自由文本 |
| `tags` | TEXT | JSON 字符串数组，例如 `["代数","错题"]` |
| `favorite` | INTEGER | SQLite 中用 `0/1` 表示布尔值 |
| `createdAt` | TEXT | ISO 8601 UTC 时间 |

索引：`createdAt`、`favorite`、`category`。V0.1 不单独建标签表，避免过早引入多对多关系。

### Exam

| 字段 | 类型 | 规则 |
| --- | --- | --- |
| `id` | TEXT | UUID，主键 |
| `name` | TEXT | 必填 |
| `examDate` | TEXT | ISO 8601 时间；展示时按本地时区显示 |

索引：`examDate`。

## 2. 关系和业务规则

- V0.1 实体之间没有强制外键关系。`StudySession.subject` 是统计维度，不引用单独的 Subject 表。
- 首页倒计时选择 `examDate` 大于等于当前时间的最近一场考试。
- 今日学习时长按设备本地日期过滤 `StudySession.startTime` 后求 `duration` 之和。
- 删除 Todo、Material、Exam 时不影响其他实体；删除 Material 不需要删除标签，因为标签存储在记录内部。
- 结束番茄钟时一次性写入完整的 `StudySession`，避免保存半成品记录。

## 3. SQLite 规划

数据库文件名暂定为 `study_companion.db`，初始 schema 版本为 `1`。建表和升级集中在 `data/database/database.dart`，repository 负责查询和映射，页面只依赖 repository 或 notifier。

建议的表名为 `todos`、`study_sessions`、`materials`、`exams`。所有查询都使用参数绑定，不拼接用户输入。

## 4. 时间与统计约定

- 写入数据库的时间用 UTC；读取后转换为本地时区用于界面和日期筛选。
- `Todo.date` 是纯日期，不带时区。
- `duration` 使用秒作为内部单位，界面按小时和分钟格式化。
- 月度统计按本地日历月计算，跨月记录按 `startTime` 所在本地日期归属。


