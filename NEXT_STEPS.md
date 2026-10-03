# Flutter 安装后的下一步

以下命令在 PowerShell 中执行，工作目录为 `C:\Users\Yvonne\Desktop\study_companion`。

## 1. 先检查环境

```powershell
Set-Location C:\Users\Yvonne\Desktop\study_companion
.\scripts\check_environment.ps1
```

如果 Flutter 尚未加入 PATH，可先用 Flutter SDK 的绝对路径运行同一个脚本，或重新打开终端让 PATH 生效。

## 2. 生成真实 Flutter 工程

确认 Flutter SDK 可用后，在本目录执行官方命令：

```powershell
flutter create .
```

这一步会生成 `lib/`、`android/`、`ios/` 等目录。不要在 Flutter 安装前手工创建这些目录。

## 3. 验证默认工程

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
```

选择一个 Android 模拟器或真机后运行：

```powershell
flutter run
```

## 4. 再开始实现 V0.1

按 [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) 的阶段顺序，先加入最小依赖并实现待办，再实现首页/考试/番茄钟、统计和积累。每个阶段完成后都运行 `flutter analyze`、相关测试和一次真机验证。

## 5. 可选的 Git 初始化

如果希望从现在开始跟踪文档变更，可以执行：

```powershell
git init
git add README.md REQUIREMENTS.md DATA_MODEL.md UI_STRUCTURE.md DEVELOPMENT_PLAN.md NEXT_STEPS.md scripts/check_environment.ps1
git commit -m "docs: prepare study companion project"
```


