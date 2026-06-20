<p align="center">
  <a href="#中文">中文</a> | <a href="#english">English</a>
</p>

---

<a id="中文"></a>

# JobPilot 求职航线

JobPilot（求职航线）是一款**离线优先**的 Flutter 应用，用于跟踪求职申请、面试进度、简历投递、笔记记录、数据导入导出和本地备份。无需注册账号，无需后端服务器，无需云同步，默认不上传任何用户数据。

当前 Flutter 版本为 **1.2.0+3**。Flutter package 名称仍为 `jobpilot_mobile`（技术兼容性原因），对外产品名称为 JobPilot。

## v1.2 更新亮点

- 新增「流程终止」投递状态，适用于未收到 rejection 但实际已结束的职位。
- 优化申请筛选功能，支持自适应的状态和方向选择面板。
- 优化 XLSX 导入检测，支持含前导说明、空白工作表、装饰性表头、类型化单元格、重复表头行和尾部格式化行的真实电子表格。
- 扩展英文 UI 覆盖范围：导航、仪表盘、列表、详情页、导入预览、统计、设置、筛选和通用对话框。申请编辑表单暂保留中文。
- 设置页面新增手动检查更新功能，跳转至 GitHub Releases 页面，无后台自动更新。
- 新增本地只读 Web 演示模式，使用内存预置数据，移动端的 SQLite/导入/导出行为保持不变。

### v1.2 发布加固

初始功能完成后，对持久化和导入流程进行了加固：

- **编辑申请不再丢失面试阶段记录。** `upsert` 从 `ConflictAlgorithm.replace`（删除并重新插入行，触发 `stages` 表的 `ON DELETE CASCADE`）改为先更新后插入的模式。
- **批量删除、清空和导入提交改为事务性操作。** `ApplicationRepository.deleteMany` / `clearAll` 和新 `ImportRepository.commit` 在单个事务内执行，中途失败会回滚而非留下部分数据。
- **`.jobpack` 恢复实现原子性 + 校验。** 替换数据库在交换前会校验 schema 版本，原数据库备份为 `.rollback` 文件，任何重开或校验失败都会自动恢复原数据。损坏或 schema 不匹配的包会被拒绝，不会影响现有数据。
- **导入分类不再误标重叠短语。** 状态检测使用最长关键词匹配，例如 `未通过` 正确识别为 `rejected`（而非 `offer`），`谈薪中` / `薪资沟通` 正确识别为 `offer_negotiation`（而非 `hr_interview`）。
- **编辑导入预览行时重新计算重复状态**，不再一律重置为可导入；**重复检测覆盖同一导入文件内的行**，而不仅限于数据库已有记录。

## 支持平台

| 平台 | 状态 |
| --- | --- |
| Android | 主要移动目标平台。使用本地 SQLite 和本地文件导入/导出/备份。 |
| iOS | 共享相同 Dart 应用逻辑和本地行为，使用 Cupertino 风格自适应 UI。在真机安装需要 macOS、Xcode 和标准 Apple 签名设置。 |
| Web | 本地只读演示模式。无持久化、托管、导入导出、备份恢复或编辑功能。 |

iOS 模拟器构建工作流（`.github/workflows/ios-simulator-build.yml`）产出未签名的模拟器 `Runner.app` ZIP 压缩包，非签名 IPA，无需签名密钥。

## 本地 Web 演示

本地运行只读演示：

```bash
flutter run -d chrome
```

构建静态 Web 输出：

```bash
flutter build web
```

Web 限制：

- 仅提供预设的演示数据。
- 编辑、删除、导入、导出、备份和恢复功能被隐藏或禁用。
- 不支持 SQLite 或文件系统持久化。
- 设置页面的更新链接可用，点击后跳转至 GitHub Releases。

## 移动端功能

- 创建、编辑、删除、搜索和筛选投递记录。
- 跟踪状态、求职方向、城市、渠道、优先级、投递日期、跟进日期、JD 链接、简历版本、薪资范围和备注。
- 记录笔试、面试、HR 沟通、问题、复盘总结和下一步计划等阶段。
- 导入 CSV/XLSX：支持表头映射、状态检测、方向检测、重复检查和导入前预览确认。
- 导出 CSV/XLSX：输出可读性强的表格表头。
- 导出和恢复本地 `.jobpack` 备份：包含 SQLite 数据库和版本元信息。
- 删除、清空、备份恢复等危险操作均有确认提示。

## 隐私说明

JobPilot 专为本地优先的私密求职跟踪而设计：

- 无需登录。
- 无需后端服务器。
- 无需云同步。
- 无自动职位抓取。
- 不会自动上传投递记录、简历、笔记、导入数据、导出数据或备份文件。
- `.jobpack` 文件为本地备份存档，请妥善保管。

## 构建与测试

安装依赖：

```bash
flutter pub get
```

静态分析：

```bash
flutter analyze
```

运行测试：

```bash
flutter test --reporter compact
```

运行指定测试：

```bash
flutter test test/services/demo_app_controller_test.dart --reporter compact
flutter test test/services/export_pipeline_test.dart --reporter compact
flutter test test/widget_filter_test.dart --reporter compact
```

构建 Android 调试 APK：

```bash
flutter build apk --debug
```

构建 Android ARM64 发布版 APK：

```bash
flutter build apk --release --target-platform android-arm64
```

输出：`build/app/outputs/flutter-apk/app-release.apk`
发布包文件名：`dist/jobpilot-v1.2.0-arm64-release.apk`

构建 Web：

```bash
flutter build web
```

在 macOS 上构建 iOS：

```bash
flutter pub get
flutter analyze
flutter build ios --debug --no-codesign --simulator
```

真机安装或发布分发，请在 macOS 上用 Xcode 打开 iOS 项目，配置您自己的 Apple 签名团队和 Bundle ID。本仓库不包含签名密钥。

## 仓库

GitHub Releases：

```text
https://github.com/Git-cat000/JobPilot/releases
```

---

<a id="english"></a>

# JobPilot

JobPilot is an offline-first Flutter app for tracking job applications, interview stages, resumes, notes, imports, exports, and local backups. It does not require an account, does not use a server, does not sync to cloud storage, and does not upload user data by default.

The current Flutter version is **1.2.0+3**. The Flutter package remains `jobpilot_mobile` for technical compatibility; user-visible product names are JobPilot.

## v1.2 Highlights

- Added the `process_terminated` application status for roles that end without being rejected or abandoned.
- Improved application filters with adaptive selection sheets for status and direction.
- Improved XLSX import discovery for real spreadsheets with leading notes, empty sheets, decorated headers, typed cells, repeated header rows, and trailing formatted rows.
- Expanded English UI coverage for navigation, dashboards, lists, detail pages, import preview, statistics, settings, filters, and common dialogs. The application edit form intentionally remains Chinese for now.
- Added a user-triggered update action in Settings that opens the JobPilot GitHub Releases page. There is no background update polling.
- Added a local, read-only Web demo that uses seeded in-memory records and keeps mobile SQLite/import/export behavior unchanged.

### v1.2 Release Hardening

After the initial v1.2 feature set, a hardening pass made persistence and import safer:

- **Editing an application no longer loses its interview stages.** `upsert` switched from `ConflictAlgorithm.replace` (which deletes and re-inserts the row, triggering `ON DELETE CASCADE` on `stages`) to an update-then-insert pattern.
- **Batch delete, clear-all, and import commits are transactional.** `ApplicationRepository.deleteMany` / `clearAll` and the new `ImportRepository.commit` run inside a single transaction, so a failure mid-batch rolls back instead of leaving partial data.
- **`.jobpack` restore is atomic and validated.** The replacement database is schema-validated before swap, the original database is backed up to a `.rollback` file, and any reopen/verify failure restores the original. A corrupted or schema-mismatched package is rejected without touching live data.
- **Import classification no longer mis-labels overlapping phrases.** Status detection now matches the longest keyword, so `未通过` is `rejected` (not `offer` via `通过`) and `谈薪中` / `薪资沟通` are `offer_negotiation` (not `hr_interview`).
- **Editing an import preview row recomputes its duplicate status**, instead of always resetting to importable, and **duplicate detection now covers rows within the same import file**, not just existing database rows.

## Platforms

| Platform | Status |
| --- | --- |
| Android | Primary mobile target. Uses local SQLite and local file import/export/backup. |
| iOS | Shares the same Dart app logic and local behavior, with Cupertino-style adaptive UI. Building or installing on a real device requires macOS, Xcode, and normal Apple signing setup. |
| Web | Local read-only demo only. No persistence, hosting, imports, exports, backup restore, or editing. |

The iOS simulator workflow in `.github/workflows/ios-simulator-build.yml` builds an unsigned simulator `Runner.app` ZIP artifact. It is not a signed IPA and does not require signing secrets.

## Local Web Demo

Run the read-only demo locally:

```bash
flutter run -d chrome
```

Build static Web output:

```bash
flutter build web
```

Web limitations:

- Seeded demo data only.
- Editing, deletion, import, export, backup, and restore are hidden or disabled.
- No SQLite or file-system persistence.
- The Settings update link remains available and opens GitHub Releases only when clicked.

## Mobile Features

- Create, edit, delete, search, and filter application records.
- Track status, job direction, city, channel, priority, apply date, follow-up date, JD link, resume version, salary range, and remarks.
- Record stages such as written tests, interviews, HR conversations, questions, review notes, and next actions.
- Import CSV/XLSX with header mapping, status detection, direction detection, duplicate checks, and a required preview step before writing data.
- Export CSV/XLSX with readable spreadsheet headers.
- Export and restore local `.jobpack` backups containing the SQLite database and version metadata.
- Dangerous operations such as delete, clear, and backup restore ask for confirmation.

## Privacy

JobPilot is designed for local-first private job tracking:

- No login.
- No server backend.
- No cloud sync.
- No automatic job scraping.
- No automatic upload of job records, resumes, notes, imports, exports, or backups.
- `.jobpack` files are local backup archives; keep them in a safe place.

## Build And Test

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test --reporter compact
```

Run focused tests:

```bash
flutter test test/services/demo_app_controller_test.dart --reporter compact
flutter test test/services/export_pipeline_test.dart --reporter compact
flutter test test/widget_filter_test.dart --reporter compact
```

Build Android debug APK:

```bash
flutter build apk --debug
```

Build Android ARM64 release APK:

```bash
flutter build apk --release --target-platform android-arm64
```

Output: `build/app/outputs/flutter-apk/app-release.apk`
Delivered release filename: `dist/jobpilot-v1.2.0-arm64-release.apk`

Build Web:

```bash
flutter build web
```

Build iOS on macOS:

```bash
flutter pub get
flutter analyze
flutter build ios --debug --no-codesign --simulator
```

For real iOS device installation or release distribution, open the iOS project on macOS with Xcode and configure your own Apple signing team and bundle identifier as needed. This repository does not include signing secrets.

## Repository

GitHub Releases:

```text
https://github.com/Git-cat000/JobPilot/releases
```
