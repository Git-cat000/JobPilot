# HANDOFF.md

## 2026-06-18 — Claude Code（iOS 化 / Cupertino 特化）

### 本次完成

- 在保持安卓端不变的前提下，对 iOS 端做 Cupertino 风格特化。新增 `lib/shared/widgets/adaptive.dart`，封装 `isIos`（`Platform.isIOS`）开关与一组自适应组件，所有 iOS 分支均以此为条件，安卓端（含测试宿主 Windows/macOS）始终走原 Material 路径。
- iOS 端特化内容：
  - 底部导航改用 `CupertinoTabBar`（主色高亮、毛白白底）。
  - 五个 Tab 页（首页/投递/导入/统计/设置）顶部改为 iOS 大标题头部 `AdaptiveTabHeader`（34pt 粗体左对齐 + 灰色副标题 + 右上操作按钮）。
  - 详情 / 编辑 / 导入预览页改用 `AdaptivePageScaffold` → iOS 为 `CupertinoPageScaffold` + `CupertinoNavigationBar`（自动返回按钮、半透明栏）。
  - 主题 `pageTransitionsTheme` 为 iOS/macOS 配 `CupertinoPageTransitionsBuilder`：横向推进转场 + 右滑返回；安卓保持 `ZoomPageTransitionsBuilder`。
  - 确认弹窗（删除/批量删除/清空/恢复备份/确认导入）改用 `showAdaptiveConfirm` → iOS 为 `CupertinoAlertDialog`，支持红色 destructive 按钮；安卓为原 `AlertDialog`，按钮文案一致。
  - 编辑页日期选择改用 `showAdaptiveDatePicker` → iOS 为底部 `CupertinoDatePicker` 滚轮 + 取消/完成；安卓为原 `showDatePicker`（2020–2100）。
  - 设置页语言切换改用 `AdaptiveSegmentedControl` → iOS 为 `CupertinoSlidingSegmentedControl`；安卓为原 `SegmentedButton`。
- 安卓端 0 改动：所有 iOS 化都在 `isIos` 分支内，安卓分支逐字保留原实现。

### 修改文件

- 新增 `lib/shared/widgets/adaptive.dart`
- `lib/app.dart`（底部导航自适应）
- `lib/core/theme/app_theme.dart`（页面转场 + cupertino import）
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/applications/applications_page.dart`
- `lib/features/applications/application_detail_page.dart`
- `lib/features/applications/application_edit_page.dart`
- `lib/features/import_export/import_page.dart`
- `lib/features/import_export/import_preview_page.dart`
- `lib/features/statistics/statistics_page.dart`
- `lib/features/settings/settings_page.dart`

### 当前状态

- `flutter analyze`：通过（No issues found）
- `flutter test`：**未能运行**——`sqflite_common_ffi` 需从 GitHub 下载 `sqlite3.x64.windows.dll`，本机网络被重置导致 native assets 构建失败（环境问题，非代码问题）。测试跑的是安卓分支（宿主 `Platform.isIOS=false`），该分支行为与改前一致。
- iOS 构建：**未运行**——本机为 Windows，无法 `flutter build ios`。

### 在 Mac 上的验证步骤

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`（Mac 网络可下载 sqlite3 native 库时应能通过）
4. `flutter run -d <iPhone 模拟器/真机>`
5. 重点看 iOS 观感：底部 CupertinoTabBar、大标题、导航栏右滑返回、确认弹窗、日期滚轮、语言滑动分段。确认安卓端（如有安卓机）仍为原样。

### 已知问题

- 以下控件在 iOS 上仍是 Material 风格，未做 Cupertino 化（功能正常，观感可后续迭代）：编辑页/流程弹窗的 `DropdownButtonFormField`（优先级、流程类型、结果）、导入预览行编辑的状态/方向下拉、各处 `showModalBottomSheet` 底部表单、`SnackBar` 提示。
- iOS 实机构建/签名未配（需在 Xcode 设 Team）。

### 下一步建议

- 在 Mac 上构建并真机/模拟器验证 iOS 观感。
- 若要更彻底的 iOS 化，可继续把上述下拉与底部表单改为 `CupertinoPicker` / `CupertinoActionSheet`。

## 2026-06-18 — Claude Code（iOS 端对齐）

### 本次完成

- 完成 iOS 端配置，使行为与安卓端一致，未改动任何安卓端文件或共享 Dart 代码。
- 经核对：Dart 代码完全跨平台，无 `Platform.isAndroid/isIOS` 分支；数据库用标准 `sqflite` + `getDatabasesPath()`（iOS 原生支持）；导入用 `file_picker`（iOS 用 UIDocumentPickerViewController，支持 csv/xlsx/jobpack）；导出用纯 Dart 的 `csv`/`excel`/`archive` 写入 `getApplicationDocumentsDirectory()/exports`。
- 在 `ios/Runner/Info.plist` 增加 `UIFileSharingEnabled` 与 `LSSupportsOpeningDocumentsInPlace`，使导出的 CSV/XLSX/.jobpack 文件出现在 iOS「文件」App 中（对齐安卓端导出文件可被用户访问的行为）。
- 确认 `CFBundleDisplayName` / `CFBundleName` 已为 `JobCopilot`，部署目标 13.0，Swift Package Manager 模板（无 Podfile，插件在 Mac 首次构建时经 SPM 解析）。

### 修改文件

- `ios/Runner/Info.plist`（仅 iOS 平台配置）

### 当前状态

- Dart 代码：未改动，`flutter analyze` 维持通过（同上次记录）。
- iOS 构建：**未运行**——本机为 Windows，无法执行 `flutter build ios`（需 macOS + Xcode）。iOS 平台配置已就绪，待在 Mac 上验证。

### 在 Mac 上的验证步骤

1. `flutter pub get`（重新生成 `ios/Flutter/ephemeral` 与插件 SPM 包）
2. `flutter analyze`
3. `flutter build ios --debug --no-codesign`（模拟器/无签名）或 `flutter run -d <真机>`
4. 如真机安装，需在 Xcode 设置 Development Team；模拟器无需签名。
5. 重点验证：导入 CSV/XLSX、导出 CSV/XLSX/.jobpack（文件应出现在「文件」App → JobCopilot 文件夹）、.jobpack 恢复、自定义状态/方向、中英文切换。

### 已知问题

- iOS 端无法在 Windows 上构建验证；首次 Mac 构建时若插件 SPM 解析失败，运行 `flutter clean && flutter pub get`。
- 导出文件 iOS 路径为沙盒路径，snackbar 显示的路径需用户到「文件」App 查找（与安卓端「显示路径」行为一致）；如需更友好的分享面板，可后续评估 `share_plus`（会改动共享 pubspec）。

### 下一步建议

- 在 Mac 上完成 iOS 构建与真机/模拟器验证，确认与安卓端功能一致。

## 2026-06-18 21:02 — Codex

### 本次完成

- 再次优化填写岗位信息时的自定义状态 / 方向添加界面。
- 自定义添加区改为独立白色圆角面板，增加说明文案、示例占位和全宽“添加并选中”按钮。
- 选项列表改为同风格圆角容器，内置 / 自定义选项增加克制图标区分，整体更贴合 App 现有简约卡片式 UI。
- 应用版本更新为 `1.1.0+2`，准备发布 `v1.1.0`。
- README 更新为公开项目描述、v1.1 APK 路径和 SHA-256。

### 修改文件

- `lib/features/applications/application_edit_page.dart`
- `pubspec.yaml`
- `README.md`
- `docs/HANDOFF.md`

### 当前状态

- `flutter pub get`：通过
- `flutter analyze`：通过
- `flutter test --reporter compact`：通过
- `flutter build apk --debug`：通过
- APK：`dist/jobcopilot-v1.1-debug.apk`
- APK SHA-256：`8F666AE37EEE6DDBAB66863F5EACE2C699A1825EB78400075E948E8AD3FAE206`

### 已知问题

- 当前 v1.1 仍发布 debug APK；release APK 仍待 release artifacts 网络可用后构建。

### 下一步建议

- 发布 GitHub `v1.1.0` Release 后，在真机上验证自定义添加区和安装显示名。

## 2026-06-18 20:36 — Codex

### 本次完成

- 将导入预览页的行编辑界面从普通弹窗优化为底部抽屉式编辑面板。
- 编辑面板增加标题说明、分组表单、图标输入框、状态 / 方向选择和底部固定操作按钮。
- 将 Android 安装后的应用显示名从 `jobpilot_mobile` 改为 `JobCopilot`，包名保持不变以便覆盖升级。
- 重新构建 debug APK 并刷新 README 校验值。

### 修改文件

- `android/app/src/main/AndroidManifest.xml`
- `lib/features/import_export/import_preview_page.dart`
- `README.md`
- `docs/HANDOFF.md`

### 当前状态

- `flutter analyze`：通过
- `flutter test --reporter compact`：通过
- `flutter build apk --debug`：通过
- APK：`dist/jobpilot-v1-debug.apk`
- APK SHA-256：`3B86D295F722E56C11F62EAEF8685DE320702DCC607185D0A51FFA89C1787E3A`

### 已知问题

- 当前仍是 debug APK。

### 下一步建议

- 在 Android 真机上确认安装后桌面显示名为 `JobCopilot`，并验证导入预览编辑面板在小屏幕和键盘弹出时不遮挡保存按钮。

## 2026-06-18 20:25 — Codex

### 本次完成

- 优化投递页顶部多选按钮，改为和新增按钮同规格的 Material 3 圆角按钮。
- 多选模式增加全选 / 取消全选能力，并保留批量删除确认。
- 将编辑投递页的状态 / 方向选择改为底部选择面板，避免原下拉框添加自定义项后出现异常界面。
- 自定义状态 / 方向支持在选择面板中左滑删除；内置选项不可删除。
- 本地保留 `.ai/` 和 `Agents.md`，但已从 Git 跟踪中移除并写入 `.gitignore`，后续不会推送到 GitHub。
- 重新构建 debug APK 并刷新 README 校验值。

### 修改文件

- `.gitignore`
- `README.md`
- `docs/HANDOFF.md`
- `lib/data/repositories/app_option_repository.dart`
- `lib/shared/state/app_controller.dart`
- `lib/features/applications/applications_page.dart`
- `lib/features/applications/application_edit_page.dart`

### 当前状态

- `flutter analyze`：通过
- `flutter test --reporter compact`：通过
- `flutter build apk --debug`：通过
- APK：`dist/jobpilot-v1-debug.apk`
- APK SHA-256：`3B86D295F722E56C11F62EAEF8685DE320702DCC607185D0A51FFA89C1787E3A`

### 已知问题

- CodeGraph 未初始化：当前项目目录没有 `.codegraph/`。
- 当前仍是 debug APK。

### 下一步建议

- 在真机上重点验证自定义选项添加、左滑删除、删除当前选中项后的回退值，以及投递页全选/批量删除。

## 2026-06-18 20:10 — Codex

### 本次完成

- 将 Flutter 模板 README 替换为 JobPilot 项目说明，覆盖功能、APK、开发命令、目录结构、数据隐私和已知限制。
- 加固 `.gitignore`，继续排除 APK/AAB/ZIP/jobpack、本地导出、截图和临时目录。
- 检查 Git 跟踪文件，当前入库内容为项目源码、Android 配置、规则、文档、测试数据和项目记忆；构建缓存、IDE 文件、本机配置和 APK 均未入库。

### 修改文件

- `README.md`
- `.gitignore`
- `docs/HANDOFF.md`
- `.ai/task-log.md`

### 当前状态

- `git status --short --branch`：已检查
- 测试：本次只改文档和忽略规则，未重新运行 Flutter 测试

### 已知问题

- 暂无新增问题。

### 下一步建议

- 后续每次推送前先检查 README 是否仍反映当前 APK 和功能状态。

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
