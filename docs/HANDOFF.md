# HANDOFF.md

## 2026-06-18 20:00 — Codex

### 本次完成

- 按用户反馈优化 UI 为更轻的 iOS 扁平化观感：更柔和的卡片、标签、输入框和导航样式。
- 首页最近投递支持点击直达对应投递详情。
- 投递列表增加多选模式，可批量删除；岗位卡片增加状态、方向、优先级、城市、渠道、日期等彩色信息标签。
- 扩展岗位方向和求职状态选项，并支持在新增/编辑页自定义添加。
- 修复导入识别不全：支持装饰表头、更多表头别名、XLSX 文本单元格读取、显式岗位方向列和下次跟进日期。
- 导入预览页增加单行编辑功能，确认导入前可修正识别错误。
- 设置页增加中文/英文切换，并持久保存语言设置。
- 重新构建 debug APK 到 `dist/jobpilot-v1-debug.apk`。

### 修改文件

- `lib/core/...`
- `lib/data/db/app_database.dart`
- `lib/data/models/app_option.dart`
- `lib/data/repositories/app_option_repository.dart`
- `lib/data/repositories/app_settings_repository.dart`
- `lib/features/applications/...`
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/import_export/...`
- `lib/features/settings/settings_page.dart`
- `lib/shared/state/app_controller.dart`
- `assets/rules/...`
- `test/services/import_pipeline_test.dart`

### 当前状态

- `flutter test test\services\import_pipeline_test.dart --reporter compact`：通过
- `flutter test --reporter compact`：通过
- `flutter analyze`：通过
- `flutter build apk --debug`：通过
- APK：`dist/jobpilot-v1-debug.apk`
- APK SHA-256：`6C7A1C439D8865A45215B24D3C244B3047D977ECD5E7AE270195DD6D55AA5152`

### 已知问题

- 当前仍是 debug APK；release APK 仍依赖 Flutter release artifacts 网络可用性。
- 中英文切换已覆盖主导航、设置页和部分列表文案，深层表单和导入页面仍以中文为主，后续可继续完整本地化。
- 未在 Android 真机上手工安装验证。

### 下一步建议

- 在真机上验证文件选择、导入预览编辑、批量删除和自定义选项持久化。
- 继续补齐所有页面的英文文案。

## 2026-06-18 18:46 — Codex

### 本次完成

- 初始化 Git 仓库并提交第一版源码。
- 创建 GitHub 私有仓库并推送 `main`。
- 创建 `v1.0.0` 标签和 GitHub Release。
- 将 `dist/jobpilot-v1-debug.apk` 作为 Release 附件上传。

### 修改文件

- `.gitignore`
- `docs/HANDOFF.md`
- `.ai/...`

### 当前状态

- GitHub 仓库：`https://github.com/Git-cat000/JobPilot`
- GitHub Release：`https://github.com/Git-cat000/JobPilot/releases/tag/v1.0.0`
- APK 附件：`jobpilot-v1-debug.apk`
- APK SHA-256：`DFCE8561D981C563C20F911DDA62EC5C6DA56362561017C86A0BCEBAA5058F19`

### 已知问题

- 仓库为私有仓库。
- Release 附件是 debug APK；release APK 仍需在 Flutter release artifacts 网络可用后重新构建。

### 下一步建议

- 网络稳定后构建 release APK 并替换 Release 附件。
- 在 Android 真机上安装验证核心流程。

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
