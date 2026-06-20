/// 数据层 schema 常量：活动库与 `.jobpack` 备份共享的唯一真实数据源。
///
/// 放置于数据层，避免功能层（`jobpack_validator`）反向依赖 `AppDatabase`
/// 形成循环依赖。`AppDatabase.schemaVersion` 保留为面向历史调用方的兼容
/// 入口，内部同样引用此常量，确保版本声明始终一致。
const int kAppSchemaVersion = 2;

/// 活动库与备份库都必须包含的全部表名，供恢复前结构校验使用。
const Set<String> kAppDatabaseTables = {
  'applications',
  'stages',
  'materials',
  'import_logs',
  'app_options',
  'app_settings',
};
