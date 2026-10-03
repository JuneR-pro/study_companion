# UI 结构、导航与数据流

## 1. 顶层导航

使用底部导航栏，四个一级入口：

1. 首页
2. 待办
3. 统计
4. 积累

考试管理从首页倒计时卡片进入；番茄钟从首页入口进入全屏计时页。新增和编辑优先使用页面内表单或底部弹层，减少导航层级。

## 2. 页面清单

```text
HomeScreen
  ├─ ExamCountdownCard -> ExamListScreen -> ExamFormScreen
  ├─ TodayStudyCard -> StatisticsScreen
  ├─ FocusTimerEntry -> FocusTimerScreen -> SessionSummarySheet
  └─ RecentTodoList -> TodoListScreen -> TodoFormSheet

TodoListScreen
  ├─ DateSelector
  ├─ TodoRow (toggle / delete)
  └─ TodoFormSheet

StatisticsScreen
  ├─ TodaySummaryCard
  ├─ DailyDurationChart
  ├─ MonthlySummaryCard
  └─ SubjectDurationList

MaterialsScreen
  ├─ FilterBar (category / tag / favorite)
  ├─ MaterialList
  ├─ MaterialFormScreen
  └─ MaterialDetailScreen
```

## 3. 关键数据流

```text
用户操作
  -> Screen / Widget
  -> ChangeNotifier（状态与校验）
  -> Repository（TodoRepository 等）
  -> SQLite Database
  -> Repository 返回实体
  -> Notifier 更新
  -> 相关页面刷新
```

- HomeNotifier 聚合最近考试、今日学习时长和最近待办，不在 Widget 中直接写查询。
- TodoNotifier 持有当前日期和当日待办，完成/删除成功后刷新列表。
- StatisticsNotifier 读取 StudySession repository 的聚合查询，避免在 Dart 端加载全部历史记录。
- MaterialNotifier 持有当前筛选条件，筛选变化时重新查询。
- FocusTimerController 管理计时器状态；只有点击结束并确认后才创建 StudySession。

## 4. 状态与反馈

每个功能页至少有 `initial/loading/ready/error/empty` 这几类可见状态。保存成功后返回上一页并刷新；删除使用确认对话框；数据库错误显示可理解的提示，并保留用户输入以便重试。

## 5. 视觉与交互约定

- Material 3，使用系统主题色，先不做复杂主题定制。
- 首页卡片只展示摘要，详情操作进入对应功能页。
- 时间、日期和持续时长统一使用本地化格式。
- 表单字段保持少而明确；标题和考试名称不能为空。


