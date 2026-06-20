/// 数据层恢复异常：当 `.jobpack` 替换活动库后重新打开或校验失败时抛出。
///
/// 该类型位于数据层，避免 `AppDatabase` 依赖功能层（`jobpack_validator`）
/// 形成循环依赖。调用方（如 `AppController`）捕获后映射为面向用户的本地化
/// 原因 [JobpackValidationReason.restoreFailed]。
class DatabaseRestoreException implements Exception {
  const DatabaseRestoreException([this.message]);

  final String? message;

  @override
  String toString() => message == null
      ? 'DatabaseRestoreException'
      : 'DatabaseRestoreException: $message';
}
