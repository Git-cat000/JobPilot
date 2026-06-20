import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_restore_exception.dart';
import 'database_schema.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  /// 当前数据库 schema 版本，作为「活动数据库」与「.jobpack 备份」共享的唯一
  /// 真实数据源。`openDatabase` 的版本、`onUpgrade` 的判断以及导出
  /// `version.json` 的 `schema_version` 都引用此常量，避免版本声明不一致。
  ///
  /// 真实值集中维护在数据层的 [kAppSchemaVersion]；此处保留为兼容入口，供
  /// 历史调用方与测试引用，且不引入对功能层的依赖。
  static const int schemaVersion = kAppSchemaVersion;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<String> get databasePath async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'jobpilot.sqlite');
  }

  Future<Database> _open() async {
    return openDatabase(
      await databasePath,
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE applications (
  id TEXT PRIMARY KEY,
  company_name TEXT NOT NULL,
  job_title TEXT NOT NULL,
  job_direction TEXT NOT NULL,
  city TEXT NOT NULL,
  channel TEXT NOT NULL,
  status TEXT NOT NULL,
  priority TEXT NOT NULL,
  apply_date TEXT NOT NULL,
  next_follow_date TEXT NOT NULL,
  jd_link TEXT NOT NULL,
  resume_version TEXT NOT NULL,
  salary_range TEXT NOT NULL,
  remark TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE stages (
  id TEXT PRIMARY KEY,
  application_id TEXT NOT NULL,
  stage_type TEXT NOT NULL,
  stage_time TEXT NOT NULL,
  result TEXT NOT NULL,
  questions TEXT NOT NULL,
  review TEXT NOT NULL,
  next_action TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(application_id) REFERENCES applications(id) ON DELETE CASCADE
)
''');
        await db.execute('''
CREATE TABLE materials (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  direction TEXT NOT NULL,
  version TEXT NOT NULL,
  file_path TEXT NOT NULL,
  remark TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE import_logs (
  id TEXT PRIMARY KEY,
  file_name TEXT NOT NULL,
  import_time TEXT NOT NULL,
  total_rows INTEGER NOT NULL,
  success_rows INTEGER NOT NULL,
  duplicate_rows INTEGER NOT NULL,
  failed_rows INTEGER NOT NULL,
  mapping_json TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
        await _createOptionTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < schemaVersion) {
          await _createOptionTables(db);
        }
      },
    );
  }

  Future<void> _createOptionTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS app_options (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  value TEXT NOT NULL,
  label TEXT NOT NULL,
  UNIQUE(type, value)
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
  }

  /// 在刚（重新）打开的句柄上执行最小验证：`PRAGMA user_version` 必须等于
  /// [schemaVersion]，且 `applications` 表可读。用于 `.jobpack` 替换或回滚
  /// 重新打开后确认库可用且 schema 一致；任一检查失败都会抛出异常，由调用
  /// 方据此触发回滚。
  Future<void> _verifyOpened(Database db) async {
    final versionRows = await db.rawQuery('PRAGMA user_version');
    final userVersion =
        versionRows.isEmpty ? null : versionRows.first.values.first;
    if (userVersion is! int || userVersion != schemaVersion) {
      throw StateError('schema version mismatch: $userVersion');
    }
    await db.query('applications', limit: 1);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// 关闭可能已打开的数据库句柄并清空缓存，忽略关闭本身的异常。
  Future<void> _closeQuietly() async {
    try {
      await _database?.close();
    } catch (_) {
      // 关闭损坏句柄失败不应阻塞回滚流程。
    }
    _database = null;
  }

  /// 生成一份与活动数据库一致的快照文件，供导出 `.jobpack` 使用。
  ///
  /// 绝不直接归档正在打开的活动数据库文件：先做 WAL checkpoint 把未提交
  /// 日志写回主库，关闭连接后复制到独立临时目录，并在复制成功后重新打开
  /// 活动库。无论复制还是重新打开失败，都会先清理临时目录再向上抛出，
  /// 绝不泄漏临时快照、也绝不把活动库留在关闭状态。
  Future<File> createSnapshot() async {
    final db = await database;
    try {
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {
      // 非 WAL 模式下该 PRAGMA 无意义，忽略即可。
    }
    await close();
    Directory? tempDir;
    File? snapshot;
    try {
      final source = File(await databasePath);
      tempDir = await Directory.systemTemp.createTemp('jobpilot_snapshot_');
      snapshot = File(p.join(tempDir.path, 'data.sqlite'));
      source.copySync(snapshot.path);
    } catch (e) {
      // 复制失败：清理已创建的临时目录，并确保活动库被重新打开后再抛出。
      _safeDeleteDir(tempDir);
      _database = await _open();
      rethrow;
    }
    try {
      _database = await _open();
    } catch (e) {
      // 重新打开失败：清理临时目录后再抛出，避免泄漏快照文件。
      _safeDeleteDir(tempDir);
      rethrow;
    }
    return snapshot;
  }

  /// 以原子方式用已校验的 SQLite 文件替换活动数据库。
  ///
  /// 顺序固定为：关闭活动库 → 创建唯一 rollback 文件 → 将已校验数据库复制到
  /// 同目录暂存文件 → 原子 rename 覆盖目标 → 重新打开并执行最小查询。若重新
  /// 打开/查询失败，先关闭损坏句柄，再用 rollback 恢复原库并重新打开验证；
  /// 若替换过程本身失败，同样回滚。rollback 文件仅在「替换成功」或「回滚已
  /// 确认成功」后删除；若回滚自身失败则保留 rollback 文件并抛出
  /// [DatabaseRestoreException]，绝不静默删除唯一备份。
  Future<void> replaceWith(File validatedSqlite) async {
    final target = File(await databasePath);
    await close();
    File? rollback;
    File? staging;
    bool replaced = false;
    bool rolledBack = false;
    Object? failure;

    try {
      if (target.existsSync()) {
        rollback = File('${target.path}.${_uniqueSuffix()}.rollback');
        target.copySync(rollback.path);
      }
      staging = File('${target.path}.${_uniqueSuffix()}.staging');
      validatedSqlite.copySync(staging.path);
      if (target.existsSync()) {
        target.deleteSync();
      }
      staging.renameSync(target.path);
      staging = null; // 已被 rename 消费。

      // 重新打开并验证替换后的库可正常读取、schema 一致。
      try {
        _database = await _open();
        await _verifyOpened(_database!);
      } catch (e) {
        // 替换后的库无法打开/查询：先关闭可能已打开的损坏句柄，再回滚。
        await _closeQuietly();
        rolledBack = await _restoreRollback(target, rollback);
        failure = const DatabaseRestoreException(
          'reopen failed after replace',
        );
      }
      if (failure == null) {
        replaced = true;
      }
    } catch (e) {
      // 替换过程本身（复制/删除/rename）失败：尝试回滚到原库。
      failure = e is DatabaseRestoreException
          ? e
          : const DatabaseRestoreException('replace failed');
      await _closeQuietly();
      rolledBack = await _restoreRollback(target, rollback);
    } finally {
      // 暂存文件总是可以清理；rollback 仅在替换或回滚成功后删除，
      // 否则保留以供人工恢复。
      _safeDeleteFile(staging);
      if (replaced || rolledBack) {
        _safeDeleteFile(rollback);
      }
    }

    if (failure != null) {
      throw failure;
    }
  }

  /// 将 [rollback] 文件复制回 [target] 并重新打开、验证原库。
  ///
  /// 成功返回 `true`。任何步骤失败都返回 `false` 且**不删除** rollback 文件，
  /// 以便调用方保留唯一备份并抛出 [DatabaseRestoreException]。即便重新打开
  /// 失败，[target] 也已恢复为原库内容（仅句柄不可用）。
  Future<bool> _restoreRollback(File target, File? rollback) async {
    if (rollback == null || !rollback.existsSync()) {
      return false;
    }
    try {
      if (target.existsSync()) {
        target.deleteSync();
      }
    } catch (_) {
      // 删除损坏目标失败：仍尝试用 rollback 覆盖。
    }
    try {
      rollback.copySync(target.path);
    } catch (_) {
      return false; // 保留 rollback 文件。
    }
    try {
      _database = await _open();
      await _verifyOpened(_database!);
      return true;
    } catch (_) {
      await _closeQuietly();
      return false; // rollback 文件保留，供人工恢复。
    }
  }

  void _safeDeleteFile(File? file) {
    if (file == null) return;
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {
      // 清理失败不影响主流程。
    }
  }

  void _safeDeleteDir(Directory? dir) {
    if (dir == null) return;
    try {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {
      // 清理失败不影响主流程。
    }
  }

  String _uniqueSuffix() => DateTime.now().microsecondsSinceEpoch.toString();
}
