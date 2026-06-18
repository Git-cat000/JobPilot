# JobPilot 求职航线

JobPilot 是一个离线优先的 Android 求职记录 App，用于管理公司、岗位、投递状态、流程进展、面试复盘、简历版本、备注、表格导入和本地备份。Android 安装后的应用显示名为 **JobCopilot**。

项目第一版使用 Flutter + SQLite 开发，不接入服务器，不需要账号系统，不上传用户数据。

## 当前功能

- 投递记录：新增、编辑、删除、详情查看、搜索、状态筛选、方向筛选。
- 首页看板：总投递、进行中、面试中、Offer 统计，以及最近投递快捷入口。
- 流程记录：记录笔试、一面、二面、HR 面、电话沟通等过程和复盘。
- 导入预览：支持 CSV / XLSX，自动映射表头、识别状态和岗位方向，导入前可预览和编辑。
- 导出备份：支持 CSV、XLSX、`.jobpack` 本地备份包导出和恢复入口。
- 自定义选项：可在编辑投递时添加自定义求职状态和岗位方向。
- 批量操作：投递列表支持多选和快速删除。
- 语言设置：设置页支持中文 / 英文切换，当前已覆盖主导航、设置页和部分列表文案。
- 本地安全：所有数据默认保存在本机 SQLite 数据库中，危险操作带确认。

## APK

当前已生成 debug APK：

```text
dist/jobpilot-v1-debug.apk
```

该 APK 不提交到 Git 仓库，而是作为 GitHub Release 附件发布。

当前校验值：

```text
SHA-256: 3B86D295F722E56C11F62EAEF8685DE320702DCC607185D0A51FFA89C1787E3A
```

GitHub 仓库：

```text
https://github.com/Git-cat000/JobPilot
```

## 本地开发

环境要求：

- Flutter 3.44.x
- Dart 3.12.x
- Android SDK
- Android Studio JBR 或可用 JDK

常用命令：

```bash
flutter pub get
flutter test --reporter compact
flutter analyze
flutter build apk --debug
```

debug APK 输出位置：

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## 项目结构

```text
lib/
  core/                 主题、枚举、文案
  data/                 SQLite、模型、Repository
  features/             首页、投递、导入导出、统计、设置等功能页面
  shared/               全局状态和通用组件
assets/rules/           表头映射、状态识别、方向识别规则
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

## 已知限制

- 当前发布的是 debug APK；release APK 仍需要在 Flutter release artifacts 网络可用后重新构建。
- 英文切换已完成基础入口，深层表单和导入页面仍以中文为主，后续可继续补齐完整本地化。
- 还未在 Android 真机上完成完整人工验收。
