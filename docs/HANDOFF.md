# HANDOFF.md

## 2026-06-18 18:15 — Codex

### 本次完成

- 完善第一版离线 MVP：SQLite 本地库、投递 CRUD、流程记录、搜索筛选、CSV/XLSX 导入预览、规则分类、CSV/XLSX 导出、`.jobpack` 备份恢复入口。
- 新增数据模型、数据库初始化、Repository、导入解析服务、导出备份服务和应用状态控制器。
- 添加导入/导出服务测试，并保留基础 widget 测试。
- 构建 debug APK，并复制到 `dist/jobpilot-v1-debug.apk`。

### 修改文件

- `lib/data/...`
- `lib/features/...`
- `lib/shared/state/app_controller.dart`
- `lib/core/enums/job_enums.dart`
- `android/app/build.gradle.kts`
- `android/build.gradle.kts`
- `pubspec.yaml`
- `pubspec.lock`
- `test/...`
- `dist/jobpilot-v1-debug.apk`

### 当前状态

- `flutter pub get`：通过
- `flutter analyze`：通过
- `flutter test`：通过
- `flutter build apk --debug`：通过，输出 `dist/jobpilot-v1-debug.apk`
- `flutter build apk --release`：失败，网络下载 Flutter release artifacts 时 connection reset
- `git status`：失败，当前目录不是 Git 仓库

### 已知问题

- 当前生成的是 debug APK，不是 release APK。release 构建失败原因是访问 `https://storage.googleapis.com/download.flutter.io/...` 下载 Flutter release artifacts 时连接被 reset。
- 本机 `codegraph` CLI 不在 PATH，无法初始化 CodeGraph 索引。
- 未在 Android 真机上手工安装验证。

### 下一步建议

- 网络稳定后重新运行 `flutter build apk --release --target-platform android-arm64` 生成 release APK。
- 在 Android 真机上验证文件选择、SQLite 持久化、导出路径和 `.jobpack` 恢复。

## 2026-06-18 17:50 — Codex

### 本次完成

- 按新版 `Agents.md` 执行阶段 1：项目初始化与基础 UI。
- 创建 Flutter 项目骨架、Material 3 主题、底部导航和主要页面空壳。
- 新增规则资产、测试 CSV 和基础项目文档。
- 清理 Flutter 模板生成的非 Android 平台目录，保持第一版 Android-only 边界。

### 修改文件

- `lib/main.dart`
- `lib/app.dart`
- `lib/core/theme/app_theme.dart`
- `lib/features/...`
- `lib/shared/widgets/app_card.dart`
- `pubspec.yaml`
- `test/widget_test.dart`
- `docs/...`
- `assets/rules/...`
- `test_data/...`

### 当前状态

- `flutter pub get`：通过
- `flutter analyze`：通过
- `flutter test`：通过
- `flutter run`：未运行

### 已知问题

- 本机 `codegraph` CLI 不在 PATH，无法初始化 CodeGraph 索引。
- 当前目录不是 Git 仓库，`git status` 无法运行。

### 下一步建议

完成阶段 1 验证后，下一步进入阶段 2：数据模型与 SQLite。
