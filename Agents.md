# AGENTS.md — JobPilot 求职航线项目构建指南

## 0. 项目简介

本项目名称为 **JobPilot 求职航线**。

目标是开发一个 **离线优先的 Android 求职记录 App**，用于记录和管理个人求职过程中的公司、岗位、投递状态、流程进展、面试复盘、简历版本、备注等信息。

第一版只做 Android 手机端，使用 Flutter 开发。

核心原则：

```text
离线优先
本地存储
数据安全
操作简单
UI 简约好看
支持表格导入
支持本地备份恢复
```

本项目不依赖服务器，不需要账号系统，不上传用户数据。

---

## 1. 第一版目标

第一版目标是完成一个可实际使用的 Android App，具备以下能力：

1. 手动新增、编辑、删除求职记录。
2. 查看所有投递记录。
3. 按状态、方向、公司、岗位进行搜索和筛选。
4. 记录笔试、面试、HR 沟通等流程。
5. 记录面试问题和复盘内容。
6. 导入 CSV / XLSX 表格。
7. 自动识别表头并映射到标准字段。
8. 自动识别求职状态。
9. 自动识别岗位方向。
10. 导入前提供预览，不直接写入数据库。
11. 导出 CSV / XLSX。
12. 导出和导入 `.jobpack` 本地备份包。
13. 所有数据默认保存在本地 SQLite 数据库中。
14. UI 简约、干净、现代、好看。

---

## 2. 第一版不做的内容

第一版禁止实现以下内容：

1. 云同步。
2. 账号登录。
3. 微信小程序。
4. iOS 适配。
5. 电脑端。
6. 多用户协作。
7. 在线 AI 分析。
8. 服务器后端。
9. 自动联网抓取招聘信息。
10. 未经用户确认的自动数据上传。

如果后续需要这些功能，应在第一版稳定完成后再单独规划。

---

## 3. 技术路线

第一版使用以下技术栈：

```text
Flutter
Dart
Android
SQLite
本地文件系统
CSV / XLSX 解析
本地规则分类
本地备份包
```

推荐依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter

  sqflite: ^2.3.0
  path: ^1.9.0
  path_provider: ^2.1.0
  file_picker: ^8.0.0
  excel: ^4.0.0
  csv: ^6.0.0
  archive: ^3.6.0
  intl: ^0.19.0
  uuid: ^4.4.0
```

如果依赖版本冲突，可以使用兼容版本，但必须保持功能目标不变。

---

## 4. 项目整体架构

项目应采用清晰的分层结构。

推荐结构：

```text
jobpilot_mobile/
├─ lib/
│  ├─ main.dart
│  ├─ app.dart
│  │
│  ├─ core/
│  │  ├─ constants/
│  │  ├─ enums/
│  │  ├─ theme/
│  │  ├─ utils/
│  │  └─ errors/
│  │
│  ├─ data/
│  │  ├─ db/
│  │  │  ├─ app_database.dart
│  │  │  └─ migrations.dart
│  │  ├─ models/
│  │  │  ├─ application.dart
│  │  │  ├─ stage.dart
│  │  │  ├─ material_item.dart
│  │  │  └─ import_log.dart
│  │  └─ repositories/
│  │     ├─ application_repository.dart
│  │     ├─ stage_repository.dart
│  │     ├─ material_repository.dart
│  │     └─ import_log_repository.dart
│  │
│  ├─ features/
│  │  ├─ dashboard/
│  │  ├─ applications/
│  │  ├─ stages/
│  │  ├─ import_export/
│  │  ├─ classification/
│  │  ├─ statistics/
│  │  └─ settings/
│  │
│  └─ shared/
│     ├─ components/
│     ├─ widgets/
│     └─ layout/
│
├─ assets/
│  └─ rules/
│     ├─ field_aliases.json
│     ├─ status_rules.json
│     └─ direction_rules.json
│
├─ docs/
│  ├─ PRD.md
│  ├─ DATA_SCHEMA.md
│  ├─ IMPORT_RULES.md
│  ├─ UI_PAGES.md
│  ├─ DEVELOPMENT_PLAN.md
│  └─ HANDOFF.md
│
├─ test_data/
│  ├─ test_jobs_1.csv
│  └─ test_jobs_2.csv
│
├─ test/
├─ pubspec.yaml
└─ AGENTS.md
```

如果项目已经有部分结构，不要强行推翻全部重构，应在现有结构基础上逐步整理。

---

## 5. 代码组织原则

必须遵守以下原则：

1. 不要把所有代码写在 `main.dart`。
2. 页面、模型、数据库、Repository、工具函数要分层。
3. 页面代码只负责 UI 和交互，不直接写复杂数据库逻辑。
4. 数据库操作统一放在 Repository 层。
5. 枚举值、状态值、方向值应集中管理。
6. 导入解析逻辑应独立成模块，不要写死在页面里。
7. 备份恢复逻辑应独立成模块。
8. 所有危险操作必须二次确认。
9. 所有导入操作必须先预览再确认。
10. 不要为了快速实现牺牲数据安全。

---

## 6. UI 设计要求

本项目 UI 必须简约、干净、现代、好看。

不要做成传统后台管理系统，也不要做成颜色杂乱的 Demo。

### 6.1 设计风格

参考风格：

```text
Notion
Linear
飞书多维表格移动端
Material 3
轻量卡片式设计
```

关键词：

```text
简约
清爽
现代
高留白
信息层级清晰
卡片式
状态标签克制
适合长期使用
```

### 6.2 推荐颜色

```text
页面背景：#F6F7F9
卡片背景：#FFFFFF
主色：#2563EB
成功色：#16A34A
警告色：#F59E0B
危险色：#DC2626
正文色：#111827
次级文字：#6B7280
弱文字：#9CA3AF
分割线：#E5E7EB
```

### 6.3 间距与圆角

```text
页面左右 padding：16
卡片内 padding：16
模块间距：16 或 24
列表项间距：12
卡片圆角：16
按钮圆角：12
输入框圆角：12
底部弹窗圆角：24
```

### 6.4 UI 必须避免

1. 大面积高饱和背景色。
2. 过多阴影。
3. 过度拟物。
4. 按钮颜色混乱。
5. 列表太拥挤。
6. 表单字段堆叠无分组。
7. 状态标签过度刺眼。
8. 默认 Flutter Demo 风格残留。

---

## 7. 核心页面设计

### 7.1 DashboardPage 首页

首页用于快速了解求职整体状态。

应包含：

1. 顶部问候区域。
2. 今日或本周待办提醒。
3. 关键统计卡片：

   * 总投递
   * 进行中
   * 面试中
   * Offer
4. 最近需要跟进的岗位。
5. 快速新增按钮。
6. 快速导入入口。

UI 要求：

* 不要只是普通列表。
* 统计卡片要简洁。
* 信息层级要清楚。
* 页面顶部应有明确的产品感。

---

### 7.2 ApplicationsPage 投递列表页

用于查看所有求职记录。

每条记录应显示：

1. 公司名称。
2. 岗位名称。
3. 当前状态标签。
4. 岗位方向标签。
5. 城市。
6. 投递日期。
7. 下次跟进日期。

功能要求：

1. 搜索公司和岗位。
2. 按状态筛选。
3. 按岗位方向筛选。
4. 点击进入详情页。
5. 提供新增按钮。

UI 要求：

* 使用卡片式列表。
* 状态标签颜色克制。
* 空状态页面要好看，不要只显示空白。

---

### 7.3 ApplicationDetailPage 投递详情页

用于查看单个岗位的完整信息。

应分区显示：

1. 基本信息。
2. 求职状态。
3. 投递信息。
4. 流程记录。
5. JD 链接。
6. 简历版本。
7. 备注。
8. 操作按钮：编辑、删除、添加流程。

不要把所有字段堆成一张长表。

---

### 7.4 ApplicationEditPage 新增 / 编辑页

用于新增或编辑求职记录。

表单应分组：

1. 基本信息：

   * 公司名称
   * 岗位名称
   * 城市
   * 岗位方向
2. 求职状态：

   * 当前状态
   * 优先级
3. 投递信息：

   * 投递渠道
   * 投递日期
   * JD 链接
4. 跟进信息：

   * 下次跟进日期
   * 简历版本
   * 薪资范围
5. 备注：

   * 自由文本

要求：

* 公司名称和岗位名称为必填。
* 保存按钮清晰。
* 表单输入体验要简洁。
* 日期选择应使用日期选择器。

---

### 7.5 Stages 流程记录模块

流程记录用于记录某个岗位的笔试、面试、HR 沟通等过程。

每条流程记录包含：

1. 流程类型。
2. 时间。
3. 结果。
4. 面试问题。
5. 复盘。
6. 下一步行动。

流程类型包括：

```text
笔试
一面
二面
HR 面
电话沟通
其他
```

流程结果包括：

```text
待反馈
通过
未通过
取消
其他
```

---

### 7.6 ImportPage 导入页

导入页负责选择和解析文件。

支持：

1. 选择 CSV 文件。
2. 选择 XLSX 文件。
3. 读取表头。
4. 展示字段映射结果。
5. 进入导入预览页。

禁止选择文件后直接写入数据库。

---

### 7.7 ImportPreviewPage 导入预览页

导入预览页是导入系统的关键页面。

必须显示：

1. 总行数。
2. 可导入数量。
3. 错误数量。
4. 疑似重复数量。
5. 字段映射结果。
6. 每条记录的导入状态。
7. 确认导入按钮。
8. 取消导入按钮。

记录状态包括：

```text
可导入
缺少必填字段
疑似重复
可能重复
字段异常
```

错误行和重复行必须清晰提示，但视觉不要刺眼。

---

### 7.8 StatisticsPage 统计页

第一版只做基础统计。

包含：

1. 按状态统计。
2. 按岗位方向统计。
3. 按投递渠道统计。
4. 本月新增投递数量。
5. Offer 数量。
6. 面试中数量。

图表可以先简单实现，也可以先用卡片和列表展示。

---

### 7.9 SettingsPage 设置 / 备份页

设置页包含：

1. 导出 CSV。
2. 导出 XLSX。
3. 导出 `.jobpack`。
4. 导入 `.jobpack`。
5. 清空所有数据。
6. 查看应用版本。
7. 查看本地数据说明。

要求：

* 清空数据必须二次确认。
* 导入备份必须二次确认。
* 导入备份前要提示可能覆盖现有数据。

---

## 8. 数据库设计

第一版至少包含以下表：

```text
applications
stages
materials
import_logs
```

---

### 8.1 applications 投递记录表

字段：

```text
id
company_name
job_title
job_direction
city
channel
status
priority
apply_date
next_follow_date
jd_link
resume_version
salary_range
remark
created_at
updated_at
```

说明：

* `id` 使用 UUID。
* `company_name` 必填。
* `job_title` 必填。
* `status` 保存英文标准值。
* `job_direction` 保存英文标准值。
* 日期建议保存 ISO 8601 字符串。
* UI 显示时转换为中文。

---

### 8.2 stages 流程记录表

字段：

```text
id
application_id
stage_type
stage_time
result
questions
review
next_action
created_at
updated_at
```

说明：

* `application_id` 关联 `applications.id`。
* 一个投递记录可以有多个流程记录。
* 删除投递记录时，应考虑级联删除对应流程记录，或者在删除前提示用户。

---

### 8.3 materials 材料表

字段：

```text
id
name
type
direction
version
file_path
remark
created_at
updated_at
```

说明：

* 第一版可以只做基础结构，实际页面可以放到后续。
* 用于记录不同版本简历、项目介绍、自我介绍等材料。

---

### 8.4 import_logs 导入记录表

字段：

```text
id
file_name
import_time
total_rows
success_rows
duplicate_rows
failed_rows
mapping_json
created_at
```

说明：

* 用于记录每次导入结果。
* `mapping_json` 记录字段映射关系，方便排查问题。

---

## 9. 枚举设计

### 9.1 求职状态

数据库保存英文值，UI 显示中文。

```text
not_applied       未投递
applied           已投递
written_test      笔试
first_interview   一面
second_interview  二面
hr_interview      HR 面
offer             Offer
rejected          拒绝
abandoned         放弃
```

### 9.2 岗位方向

```text
semiconductor     半导体
ai_algorithm      AI / 算法
quant             量化
internet_dev      互联网开发
other             其他
```

### 9.3 优先级

```text
S   最高优先级
A   高优先级
B   普通
C   低优先级
```

---

## 10. 表格导入系统

表格导入是本项目的核心功能之一。

第一版支持：

```text
.csv
.xlsx
```

---

### 10.1 导入流程

必须严格按照以下流程：

```text
选择文件
读取表头
自动字段映射
读取数据行
自动识别状态
自动识别岗位方向
检查必填字段
检测疑似重复
进入导入预览页
用户确认
写入数据库
生成导入日志
```

禁止跳过导入预览直接写入数据库。

---

### 10.2 字段映射

字段映射规则来自：

```text
assets/rules/field_aliases.json
```

建议内容：

```json
{
  "company_name": ["公司", "公司名称", "企业", "单位", "投递公司", "目标公司"],
  "job_title": ["岗位", "职位", "职位名称", "申请岗位", "Job Title"],
  "status": ["状态", "流程", "进度", "求职状态", "面试状态", "投递状态"],
  "apply_date": ["日期", "投递日期", "投递时间", "申请时间", "提交时间"],
  "city": ["城市", "地点", "工作地点", "base", "Base"],
  "channel": ["渠道", "投递渠道", "来源", "平台"],
  "jd_link": ["链接", "岗位链接", "招聘链接", "URL", "url"],
  "remark": ["备注", "说明", "记录", "补充信息"],
  "priority": ["优先级", "重要程度"],
  "resume_version": ["简历版本", "使用简历", "投递简历"],
  "salary_range": ["薪资", "薪资范围", "待遇"]
}
```

---

### 10.3 状态识别

状态识别规则来自：

```text
assets/rules/status_rules.json
```

建议内容：

```json
{
  "written_test": ["笔试", "测评", "在线测试", "机试", "性格测试"],
  "first_interview": ["一面", "初面", "技术一面", "第一轮"],
  "second_interview": ["二面", "复面", "主管面", "第二轮"],
  "hr_interview": ["HR", "hr", "谈薪", "薪资", "人事"],
  "offer": ["offer", "Offer", "录用", "意向书", "通过"],
  "rejected": ["拒", "挂", "不合适", "感谢关注", "未通过"],
  "applied": ["已投", "投递完成", "等待反馈", "简历筛选"],
  "abandoned": ["放弃", "不投", "取消", "终止"]
}
```

如果无法识别状态，默认使用：

```text
applied
```

---

### 10.4 岗位方向识别

岗位方向识别规则来自：

```text
assets/rules/direction_rules.json
```

建议内容：

```json
{
  "semiconductor": ["半导体", "工艺", "器件", "良率", "EDA", "TCAD", "CST", "VNA", "存储器", "DRAM", "NAND", "HZO", "芯片"],
  "ai_algorithm": ["算法", "机器学习", "深度学习", "推荐", "NLP", "CV", "LLM", "RAG", "Agent", "大模型"],
  "quant": ["量化", "策略", "因子", "回测", "alpha", "Alpha", "交易", "金融工程"],
  "internet_dev": ["后端", "前端", "客户端", "服务端", "数据库", "分布式", "Java", "Go", "Python"]
}
```

识别逻辑建议：

1. 优先从岗位名称识别。
2. 再从备注、JD 链接文本、渠道等字段辅助识别。
3. 如果命中多个方向，第一版选择命中次数最多的方向。
4. 如果无法识别，标记为 `other`。

---

### 10.5 必填字段检查

每条投递记录至少需要：

```text
company_name
job_title
```

缺少任一字段时，该行不能直接导入，必须在预览页标记为错误。

---

### 10.6 重复检测

第一版使用简单重复规则：

```text
company_name + job_title + apply_date 完全一致：疑似重复
company_name + job_title 一致但 apply_date 不同：可能重复
```

疑似重复记录不能静默写入数据库，应提示用户确认。

---

## 11. 导出与备份系统

### 11.1 CSV / XLSX 导出

导出内容应包含 `applications` 主表核心字段。

导出字段建议：

```text
公司名称
岗位名称
岗位方向
城市
投递渠道
当前状态
优先级
投递日期
下次跟进日期
JD链接
简历版本
薪资范围
备注
创建时间
更新时间
```

要求：

1. 导出的 CSV / XLSX 可以被 Excel 或 WPS 打开。
2. 中文字段名要清晰。
3. 日期格式要可读。
4. 状态和岗位方向导出时建议使用中文显示值。

---

### 11.2 jobpack 备份包

`.jobpack` 是本项目的完整本地备份包。

本质是 zip 压缩包。

建议结构：

```text
jobpilot_export_YYYYMMDD_HHMM.jobpack
├─ data.sqlite
├─ metadata.json
└─ version.json
```

`metadata.json` 建议包含：

```json
{
  "app_name": "JobPilot",
  "export_time": "2026-06-18T12:00:00",
  "application_count": 20,
  "stage_count": 8,
  "version": "1.0.0"
}
```

`version.json` 建议包含：

```json
{
  "schema_version": 1,
  "app_version": "1.0.0"
}
```

---

### 11.3 jobpack 导出流程

导出流程：

1. 获取当前 SQLite 数据库文件。
2. 复制数据库文件。
3. 生成 metadata。
4. 生成 version。
5. 打包为 `.jobpack`。
6. 允许用户保存或分享。

---

### 11.4 jobpack 导入流程

导入流程：

1. 用户选择 `.jobpack` 文件。
2. 解压到临时目录。
3. 检查是否包含 `data.sqlite`、`metadata.json`、`version.json`。
4. 展示备份信息。
5. 提示用户导入可能覆盖当前数据。
6. 二次确认。
7. 替换当前数据库。
8. 重新加载数据。
9. 显示恢复结果。

---

## 12. 本地数据安全要求

必须遵守：

1. 默认不联网。
2. 默认不上传数据。
3. 数据存在本地 SQLite。
4. 导入前必须预览。
5. 删除前必须确认。
6. 清空数据前必须二次确认。
7. 导入备份前必须二次确认。
8. 导出备份应提示用户妥善保存。
9. 解析文件失败时不能破坏原数据库。
10. 备份恢复失败时应保留原数据库。

---

## 13. 开发阶段规划

项目必须小步推进，不要一次性生成完整项目。

---

### 阶段 1：项目初始化与基础 UI

目标：

1. 初始化 Flutter 项目。
2. 建立推荐目录结构。
3. 配置 Material 3 主题。
4. 创建底部导航。
5. 创建主要页面空壳。
6. 实现初步简约 UI 风格。

页面：

```text
DashboardPage
ApplicationsPage
ApplicationDetailPage
ApplicationEditPage
ImportPage
ImportPreviewPage
StatisticsPage
SettingsPage
```

验收标准：

1. 项目可以运行。
2. 页面可以正常切换。
3. UI 简约干净。
4. 没有默认 Counter Demo 残留。
5. `flutter analyze` 无错误。

---

### 阶段 2：数据模型与 SQLite

目标：

1. 添加 SQLite 相关依赖。
2. 创建数据模型：

   * Application
   * Stage
   * MaterialItem
   * ImportLog
3. 创建数据库初始化逻辑。
4. 创建数据库迁移结构。
5. 创建 Repository 层。

验收标准：

1. applications 表可以创建。
2. stages 表可以创建。
3. materials 表可以创建。
4. import_logs 表可以创建。
5. 可以完成基础 CRUD。
6. 数据重启后仍然存在。
7. `flutter analyze` 无错误。

---

### 阶段 3：投递记录模块

目标：

1. 实现投递记录列表。
2. 实现新增投递记录。
3. 实现编辑投递记录。
4. 实现删除投递记录。
5. 实现投递详情页。
6. 实现搜索。
7. 实现状态筛选。
8. 实现方向筛选。

验收标准：

1. 用户可以完整新增一条记录。
2. 记录可以显示在列表中。
3. 记录可以进入详情页。
4. 记录可以编辑。
5. 记录可以删除。
6. 应用重启后数据仍存在。
7. UI 简约好看。

---

### 阶段 4：流程记录模块

目标：

1. 实现流程记录数据操作。
2. 在详情页展示流程时间线。
3. 支持新增流程记录。
4. 支持编辑流程记录。
5. 支持删除流程记录。
6. 支持记录面试问题和复盘。

验收标准：

1. 一个投递记录可以关联多个流程记录。
2. 流程记录按时间显示。
3. 流程记录可以编辑和删除。
4. 详情页结构清晰。

---

### 阶段 5：CSV / XLSX 导入解析

目标：

1. 支持用户选择 CSV 文件。
2. 支持用户选择 XLSX 文件。
3. 读取表头。
4. 根据 `field_aliases.json` 映射字段。
5. 解析数据行。
6. 生成导入预览数据。

验收标准：

1. 能读取测试 CSV。
2. 能读取测试 XLSX。
3. 能识别公司、岗位、状态、日期等字段。
4. 不直接写入数据库。
5. 解析失败时有错误提示。

---

### 阶段 6：自动分类系统

目标：

1. 根据 `status_rules.json` 自动识别状态。
2. 根据 `direction_rules.json` 自动识别岗位方向。
3. 处理无法识别的数据。
4. 给出默认值。

验收标准：

1. “一面”“初面”“技术一面”可以识别为 `first_interview`。
2. “半导体算法工程师”可以识别为 `semiconductor` 或 `ai_algorithm`。
3. “量化研究员”可以识别为 `quant`。
4. 无法识别时标记为 `other`。
5. 分类逻辑应独立成模块，方便后续维护。

---

### 阶段 7：导入预览与确认写入

目标：

1. 实现导入预览页。
2. 显示字段映射结果。
3. 标记正常记录。
4. 标记错误记录。
5. 标记疑似重复记录。
6. 用户确认后写入数据库。
7. 写入后生成 import_log。

验收标准：

1. 缺少公司或岗位的记录不能导入。
2. 疑似重复记录有提示。
3. 用户可以确认导入。
4. 用户可以取消导入。
5. 导入后列表中能看到新记录。
6. 导入记录写入 import_logs。

---

### 阶段 8：导出与备份恢复

目标：

1. 导出 CSV。
2. 导出 XLSX。
3. 导出 `.jobpack`。
4. 导入 `.jobpack`。
5. 恢复数据库。
6. 完成危险操作确认。

验收标准：

1. 导出的 CSV 可以打开。
2. 导出的 XLSX 可以打开。
3. `.jobpack` 文件结构正确。
4. `.jobpack` 可以恢复数据。
5. 导入备份前有二次确认。
6. 恢复失败不破坏原数据。

---

### 阶段 9：UI 与体验打磨

目标：

1. 统一所有页面视觉风格。
2. 优化首页。
3. 优化列表卡片。
4. 优化详情页分区。
5. 优化表单分组。
6. 优化导入预览页面。
7. 优化空状态。
8. 优化加载状态。
9. 优化错误提示。
10. 适配常见 Android 屏幕。

验收标准：

1. UI 简约好看。
2. 页面风格统一。
3. 没有明显默认样式残留。
4. 核心操作路径自然。
5. 用户可以长期使用而不觉得混乱。

---

## 14. 测试数据

建议创建目录：

```text
test_data/
```

并放入以下测试文件。

### 14.1 test_jobs_1.csv

```csv
公司,岗位,城市,投递状态,投递时间,渠道,备注
长鑫存储,半导体算法工程师,合肥,已投,2026-06-18,官网,突出CST和Python数据分析
华为,AI算法工程师,深圳,一面,2026-06-15,内推,准备项目介绍
字节跳动,后端开发工程师,上海,笔试,2026-06-12,Boss,复习数据库和算法
```

### 14.2 test_jobs_2.csv

```csv
企业,职位名称,base,流程,申请时间,来源,说明
长江存储,NAND器件工程师,武汉,等待反馈,2026-06-10,官网,补充半导体器件知识
某量化私募,量化研究员,上海,二面,2026-06-08,猎头,准备概率统计和回测项目
```

---

## 15. pubspec.yaml 要求

必须注册规则文件：

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/rules/
```

规则文件包括：

```text
assets/rules/field_aliases.json
assets/rules/status_rules.json
assets/rules/direction_rules.json
```

---

## 16. 常用开发命令

常用命令：

```bash
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
flutter run -d chrome
flutter build apk
```

说明：

1. UI 开发阶段可以先用 `flutter run -d chrome` 预览。
2. SQLite、文件导入导出、Android 权限相关功能最终必须在 Android 模拟器或真机测试。
3. 每个阶段完成后都应运行 `flutter analyze`。
4. 构建 APK 前应确保没有明显错误。

---

## 17. 质量要求

每个阶段完成后，应尽量满足：

1. `flutter analyze` 无错误。
2. 不留下明显未完成的破碎页面。
3. 不出现无法运行的代码。
4. 不出现严重 UI 违和。
5. 不破坏已有功能。
6. 不引入无关依赖。
7. 不接入云服务。
8. 不上传数据。
9. 不跳过用户确认。
10. 不牺牲数据安全。

---

## 18. 交接记录要求

本项目可能会使用 Codex、Claude Code、Cloud Code、Cursor、Konnect 等不同 AI 编程工具接力开发。

交接不是重点，但每次工具完成一个阶段后，应简单更新：

```text
docs/HANDOFF.md
```

记录即可，不需要写得过于复杂。

建议格式：

```markdown
# HANDOFF.md

## YYYY-MM-DD HH:mm — 工具名称

### 本次完成

- 完成内容 1
- 完成内容 2

### 修改文件

- `lib/...`
- `pubspec.yaml`

### 当前状态

- `flutter pub get`：通过 / 未运行 / 失败
- `flutter analyze`：通过 / 未运行 / 失败
- `flutter run`：通过 / 未运行 / 失败

### 已知问题

- 暂无
- 或列出具体问题

### 下一步建议

下一步建议继续完成：阶段 X / 某个模块。
```

---

## 19. 首次开发任务建议

第一次交给 AI 编程工具时，可以使用以下任务：

```text
请阅读 AGENTS.md，并严格按照其中的项目构建要求开始工作。

当前任务只做阶段 1：项目初始化与基础 UI。

要求：
1. 不接入任何云服务。
2. 不实现账号系统。
3. 不实现 SQLite，数据库放到阶段 2。
4. 建立清晰的 Flutter 项目目录结构。
5. 创建 Material 3 主题。
6. 创建以下页面：
   - DashboardPage
   - ApplicationsPage
   - ApplicationDetailPage
   - ApplicationEditPage
   - ImportPage
   - ImportPreviewPage
   - StatisticsPage
   - SettingsPage
7. 创建底部导航，包含：首页、投递、导入、统计、设置。
8. UI 必须简约、干净、现代、好看。
9. 不要保留 Flutter Counter Demo。
10. 不要把所有代码写在 main.dart。
11. 完成后运行 flutter analyze。
12. 完成后简单更新 docs/HANDOFF.md。
13. 不要越界实现后续阶段。
```

---

## 20. 后续阶段任务模板

每次继续开发时，使用：

```text
请先阅读 AGENTS.md 和 docs/HANDOFF.md。

当前任务只做：[填写阶段名称或具体模块]。

要求：
1. 保持项目离线优先。
2. 不接入云服务。
3. 不破坏已有功能。
4. 保持 UI 简约好看。
5. 本阶段完成后运行 flutter analyze。
6. 本阶段完成后简单更新 docs/HANDOFF.md。
7. 不要越界实现大量后续功能。
```

---

## 21. 最终完成标准

第一版完成时，应满足：

1. Android App 可以运行。
2. 可以新增求职记录。
3. 可以编辑求职记录。
4. 可以删除求职记录。
5. 可以查看投递详情。
6. 可以记录流程和复盘。
7. 可以搜索和筛选记录。
8. 可以导入 CSV。
9. 可以导入 XLSX。
10. 可以自动识别字段。
11. 可以自动识别状态。
12. 可以自动识别岗位方向。
13. 可以导入前预览。
14. 可以确认导入。
15. 可以导出 CSV。
16. 可以导出 XLSX。
17. 可以导出 `.jobpack`。
18. 可以导入 `.jobpack`。
19. 数据默认只保存在本地。
20. UI 简约、统一、好看。
21. 没有明显无法运行的错误。
22. 核心数据操作有用户确认和错误处理。

---

## 22. 最重要的提醒

本项目不是一次性生成代码的 Demo，而是一个要逐步构建、长期使用的离线求职管理 App。

开发时始终遵守：

```text
数据安全第一
离线可用优先
功能小步实现
UI 简约好看
导入必须预览
危险操作必须确认
```

每次只完成一个清晰阶段，保证项目始终处于可运行、可继续开发的状态。
