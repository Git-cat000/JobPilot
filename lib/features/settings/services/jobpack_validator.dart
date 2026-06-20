import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/app_strings.dart';
import '../../../data/db/database_schema.dart';

/// `.jobpack` 校验失败的具体原因。UI 层据此映射为本地化提示。
enum JobpackValidationReason {
  /// 缺少 data.sqlite。
  missingDataSqlite,

  /// 缺少 metadata.json。
  missingMetadata,

  /// 缺少 version.json。
  missingVersion,

  /// JSON 损坏或字段类型不正确。
  corruptJson,

  /// schema 版本不兼容。
  schemaMismatch,

  /// 来源应用名称不匹配。
  appNameMismatch,

  /// data.sqlite 不是有效的 SQLite 数据库。
  notSqlite,

  /// 缺少必要的表。
  missingTables,

  /// 输入或解压后的数据库超过大小上限。
  oversized,

  /// integrity_check 未通过。
  integrityCheckFailed,

  /// 替换后重新打开数据库失败（已自动回滚）。
  restoreFailed,
}

/// 类型化校验异常，供 Settings/AppController 捕获并展示本地化提示。
class JobpackValidationException implements Exception {
  const JobpackValidationException(this.reason);

  final JobpackValidationReason reason;

  @override
  String toString() => 'JobpackValidationException(${reason.name})';
}

/// 将校验原因映射为本地化、不含内部路径的 UI 文案。
extension JobpackValidationMessage on JobpackValidationException {
  String localizedMessage(AppStrings strings) {
    switch (reason) {
      case JobpackValidationReason.missingDataSqlite:
        return strings.jobpackMissingData;
      case JobpackValidationReason.missingMetadata:
        return strings.jobpackMissingMetadata;
      case JobpackValidationReason.missingVersion:
        return strings.jobpackMissingVersion;
      case JobpackValidationReason.corruptJson:
        return strings.jobpackCorrupt;
      case JobpackValidationReason.schemaMismatch:
        return strings.jobpackIncompatible;
      case JobpackValidationReason.appNameMismatch:
        return strings.jobpackAppNameMismatch;
      case JobpackValidationReason.notSqlite:
        return strings.jobpackNotSqlite;
      case JobpackValidationReason.missingTables:
        return strings.jobpackMissingTables;
      case JobpackValidationReason.oversized:
        return strings.jobpackOversized;
      case JobpackValidationReason.integrityCheckFailed:
        return strings.jobpackIntegrityFailed;
      case JobpackValidationReason.restoreFailed:
        return strings.jobpackRestoreFailed;
    }
  }
}

/// 校验通过的 `.jobpack` 抽取结果。调用方负责在用完后 [dispose] 临时目录。
class ValidatedJobpack {
  ValidatedJobpack({required this.tempDir, required this.databaseFile});

  final Directory tempDir;
  final File databaseFile;

  Future<void> dispose() async {
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {
        // 临时目录清理失败不影响主流程。
      }
    }
  }
}

/// `.jobpack` 输入与解压数据库的大小上限（200 MiB）。
const int maxJobpackBytes = 200 * 1024 * 1024;

/// 将 `.jobpack` 视为不可信输入进行严格校验。
///
/// 校验顺序刻意从「廉价」到「昂贵」：先按字节数与中央目录中声明的解压大小
/// 拦截超大输入（避免 zip 炸弹解压占用大量内存），再校验条目齐全性、JSON
/// 类型与 schema 兼容性，最后才以只读方式打开临时库运行 `integrity_check`
/// 与必要表检查。任何失败都会清理临时文件并抛出 [JobpackValidationException]。
class JobpackValidator {
  const JobpackValidator({this.maxBytes = maxJobpackBytes});

  final int maxBytes;

  Future<ValidatedJobpack> validate(List<int> bytes) async {
    // 1. 输入字节大小上限（先于 zip 解码，避免分配巨大内存）。
    if (bytes.length > maxBytes) {
      throw const JobpackValidationException(JobpackValidationReason.oversized);
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const JobpackValidationException(
        JobpackValidationReason.corruptJson,
      );
    }

    // 2. 仅凭中央目录中声明的解压大小拦截 zip 炸弹，不解压 content。
    for (final file in archive.files) {
      if (file.size > maxBytes) {
        throw const JobpackValidationException(
          JobpackValidationReason.oversized,
        );
      }
    }

    // 3. 三个必需条目必须齐全（同名重复时归档库会折叠为一份，故不另查重）。
    final byCount = <String, int>{};
    for (final f in archive.files) {
      byCount[f.name] = (byCount[f.name] ?? 0) + 1;
    }
    int count(String name) => byCount[name] ?? 0;
    if (count('data.sqlite') == 0) {
      throw const JobpackValidationException(
        JobpackValidationReason.missingDataSqlite,
      );
    }
    if (count('metadata.json') == 0) {
      throw const JobpackValidationException(
        JobpackValidationReason.missingMetadata,
      );
    }
    if (count('version.json') == 0) {
      throw const JobpackValidationException(
        JobpackValidationReason.missingVersion,
      );
    }
    // 必需条目已确认齐全，取其内容即可。
    final byName = {for (final f in archive.files) f.name: f};
    final dataSqliteFile = byName['data.sqlite']!;

    // 4. 解析并校验 JSON 类型。
    final metadata = _decodeJson(byName['metadata.json']!);
    final version = _decodeJson(byName['version.json']!);

    if (metadata['app_name'] is! String ||
        metadata['export_time'] is! String ||
        (metadata['application_count'] is! num) ||
        (metadata['stage_count'] is! num) ||
        metadata['version'] is! String) {
      throw const JobpackValidationException(
        JobpackValidationReason.corruptJson,
      );
    }
    if (version['schema_version'] is! int ||
        version['app_version'] is! String) {
      throw const JobpackValidationException(
        JobpackValidationReason.corruptJson,
      );
    }
    if ((metadata['app_name'] as String) != 'JobPilot') {
      throw const JobpackValidationException(
        JobpackValidationReason.appNameMismatch,
      );
    }
    if ((version['schema_version'] as int) != kAppSchemaVersion) {
      throw const JobpackValidationException(
        JobpackValidationReason.schemaMismatch,
      );
    }

    // 5. 抽取 data.sqlite 到临时目录，再次校验解压后大小。
    final tempDir = await Directory.systemTemp.createTemp('jobpilot_validate_');
    final databaseFile = File(p.join(tempDir.path, 'data.sqlite'));
    try {
      final content = dataSqliteFile.content as List<int>;
      if (content.length > maxBytes) {
        throw const JobpackValidationException(
          JobpackValidationReason.oversized,
        );
      }
      databaseFile.writeAsBytesSync(content);

      await _validateSqlite(databaseFile);
    } catch (e) {
      await _safeDelete(tempDir);
      if (e is JobpackValidationException) rethrow;
      throw const JobpackValidationException(JobpackValidationReason.notSqlite);
    }

    return ValidatedJobpack(tempDir: tempDir, databaseFile: databaseFile);
  }

  Map<String, dynamic> _decodeJson(ArchiveFile file) {
    try {
      final raw = utf8.decode(file.content as List<int>);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const JobpackValidationException(
          JobpackValidationReason.corruptJson,
        );
      }
      return decoded;
    } on JobpackValidationException {
      rethrow;
    } catch (_) {
      throw const JobpackValidationException(
        JobpackValidationReason.corruptJson,
      );
    }
  }

  Future<void> _validateSqlite(File databaseFile) async {
    Database? db;
    try {
      db = await openDatabase(
        databaseFile.path,
        readOnly: true,
        singleInstance: false,
      );

      final integrity = await db.rawQuery('PRAGMA integrity_check');
      final integrityResult = integrity.isEmpty
          ? null
          : integrity.first.values.first;
      if (integrityResult != 'ok') {
        throw const JobpackValidationException(
          JobpackValidationReason.integrityCheckFailed,
        );
      }

      // 备份库的实际 schema 版本必须与活动库一致：version.json 可能被伪造，
      // 这里以只读方式打开后核对 SQLite 自身的 user_version。
      final versionRows = await db.rawQuery('PRAGMA user_version');
      final userVersion =
          versionRows.isEmpty ? null : versionRows.first.values.first;
      if (userVersion is! int || userVersion != kAppSchemaVersion) {
        throw const JobpackValidationException(
          JobpackValidationReason.schemaMismatch,
        );
      }

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final tableNames = tables.map((row) => row['name'] as String).toSet();
      if (!kAppDatabaseTables.every(tableNames.contains)) {
        throw const JobpackValidationException(
          JobpackValidationReason.missingTables,
        );
      }
    } finally {
      await db?.close();
    }
  }

  Future<void> _safeDelete(Directory dir) async {
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // 忽略清理失败。
    }
  }
}
