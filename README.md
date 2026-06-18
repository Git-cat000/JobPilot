# JobCopilot 求职航线

JobCopilot 是一个**离线优先**的求职记录 App，用于管理公司、岗位、投递状态、流程进展、面试复盘、简历版本、备注、表格导入和本地备份。应用默认只在本机保存数据，不接入服务器，不需要账号，不上传用户数据。

项目使用 Flutter + SQLite 开发，同一套 Dart 代码同时构建 Android 与 iOS。

## 当前功能

- 投递记录：新增、编辑、删除、详情查看、搜索、状态筛选、方向筛选。
- 首页看板：总投递、进行中、面试中、Offer 统计，以及最近投递快捷入口。
- 流程记录：记录笔试、一面、二面、HR 面、电话沟通等过程和复盘。
- 导入预览：支持 CSV / XLSX，自动映射表头、识别状态和岗位方向，导入前可预览和编辑。
- 导出备份：支持 CSV、XLSX、`.jobpack` 本地备份包导出和恢复。
- 自定义选项：可在编辑投递时添加自定义求职状态和岗位方向。
- 批量操作：投递列表支持多选和快速删除。
- 语言设置：设置页支持中文 / 英文切换。
- 自适应 UI：Android 端 Material 3 风格，iOS 端 Cupertino 风格（大标题、Cupertino 导航栏与右滑返回、底部 Tab Bar、确认弹窗、日期滚轮、滑动分段控件），两端共用同一套业务逻辑。
- 本地安全：所有数据默认保存在本机 SQLite 数据库中，危险操作带确认。

## 平台支持

| 平台 | 状态 |
|---|---|
| Android | 已完成，debug APK 已发布到 GitHub Release |
| iOS | 已完成平台配置与 UI 自适应，需在 macOS + Xcode 环境构建 |

iOS 端在 `ios/Runner/Info.plist` 配置了 `UIFileSharingEnabled` 与 `LSSupportsOpeningDocumentsInPlace`，使导出的文件可在 iOS「文件」App 中访问，行为与 Android 端对齐。

## 构建

### Android（可在 Windows / macOS / Linux）

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```

产物：`build/app/outputs/flutter-apk/app-debug.apk`

### iOS（需要 macOS + Xcode）

```bash
flutter pub get
flutter analyze
open ios/Runner.xcworkspace   # 在 Xcode 中配置签名 Team 与 Bundle Identifier
flutter build ipa --release
```

产物：`build/ios/ipa/JobCopilot.ipa`

> iOS 构建必须在 macOS 上进行。首次 `flutter pub get` 会通过 Swift Package Manager 解析插件（本仓库无 Podfile，相关生成文件已被 `.gitignore` 忽略）。

## 本地开发

环境要求：

- Flutter 3.44.x（Dart 3.12.x）
- Android SDK / Xcode（按目标平台）

常用命令：

```bash
flutter pub get
flutter analyze
flutter test --reporter compact
```

## 项目结构

```text
lib/
  core/                 主题、枚举、文案
  data/                 SQLite、模型、Repository
  features/             首页、投递、导入导出、统计、设置等功能页面
  shared/               全局状态、自适应组件（adaptive.dart）、通用组件
assets/rules/           表头映射、状态识别、方向识别规则
ios/                    iOS 工程与原生配置
android/                Android 工程与原生配置
docs/                   产品、数据结构、导入规则和交接文档
test/                   单元测试和 Widget 测试
test_data/              导入测试数据
```

## 数据与隐私

- 不需要登录。
- 不接入云同步。
- 不自动联网抓取招聘信息。
- 不上传求职记录、简历信息或本地备份。
- `.jobpack` 是本地备份包，请自行妥善保存。

## 仓库

```text
https://github.com/Git-cat000/JobPilot
```

## 已知限制

- 当前 Android 发布的是 debug APK；release APK 需在 Flutter release artifacts 网络可用后重新构建。
- iOS 端尚未在真机上完成完整人工验收，且实机签名需自行配置开发者 Team。
- 英文切换已完成基础入口，深层表单和导入页面仍以中文为主，后续可继续补齐完整本地化。
