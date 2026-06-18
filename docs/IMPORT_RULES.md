# IMPORT_RULES.md

导入流程必须是：

1. 选择 CSV / XLSX。
2. 读取表头。
3. 按 `assets/rules/field_aliases.json` 自动映射字段。
4. 读取数据行。
5. 自动识别状态和岗位方向。
6. 检查必填字段。
7. 检测疑似重复。
8. 进入导入预览页。
9. 用户确认后写入数据库。
10. 生成导入日志。

缺少 `company_name` 或 `job_title` 的行不能直接导入。
