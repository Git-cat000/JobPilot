import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:jobpilot_mobile/data/db/app_database.dart';
import 'package:jobpilot_mobile/data/db/database_restore_exception.dart';
import 'package:jobpilot_mobile/data/models/application_record.dart';
import 'package:jobpilot_mobile/data/repositories/application_repository.dart';
import 'package:jobpilot_mobile/features/settings/services/jobpack_validator.dart';
import 'package:jobpilot_mobile/shared/state/app_controller.dart';

/// 与 `AppDatabase` 一致的全表 DDL，用于在独立临时库中构造测试用 SQLite。
const _schemaDdl = [
  '''
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
''',
  '''
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
''',
  '''
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
''',
  '''
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
''',
  '''
CREATE TABLE app_options (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  value TEXT NOT NULL,
  label TEXT NOT NULL,
  UNIQUE(type, value)
)
''',
  '''
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''',
];

/// 构造一个独立的 SQLite 文件并返回其字节。
/// [omitTable] 指定要省略的表名，用于「缺少必要表」场景。
Future<List<int>> _makeSqliteBytes({
  String? companyName,
  String? omitTable,
  int? userVersion,
}) async {
  final dir = await Directory.systemTemp.createTemp('jobpack_sqlite_');
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });
  final path = p.join(dir.path, 'data.sqlite');
  final db = await openDatabase(
    path,
    version: AppDatabase.schemaVersion,
    onCreate: (db, _) async {
      for (final ddl in _schemaDdl) {
        final tableName = RegExp(
          r'CREATE TABLE (\w+)',
        ).firstMatch(ddl)!.group(1);
        if (omitTable != null && tableName == omitTable) continue;
        await db.execute(ddl);
      }
    },
  );
  if (companyName != null) {
    await db.insert(
      'applications',
      ApplicationRecord.create(
        companyName: companyName,
        jobTitle: '工程师',
      ).toMap(),
    );
  }
  // 默认以 [AppDatabase.schemaVersion] 创建，使 user_version 与活动库一致、
  // 校验器可放行。可选覆盖 user_version：构造一个「version.json 合法但库内
  // user_version 不匹配」的包，校验器以只读方式打开后会因 user_version≠
  // kAppSchemaVersion 直接抛 schemaMismatch，替换前即被拦截。
  if (userVersion != null) {
    await db.execute('PRAGMA user_version = $userVersion');
  }
  await db.close();
  return File(path).readAsBytes();
}

/// 构造一个 `.jobpack`（zip）字节数据。
List<int> _buildJobpack({
  List<int>? dataSqlite,
  Map<String, dynamic>? metadata,
  Map<String, dynamic>? version,
  Map<String, List<int>>? extra,
}) {
  final archive = Archive();
  if (dataSqlite != null) {
    archive.addFile(ArchiveFile('data.sqlite', dataSqlite.length, dataSqlite));
  }
  if (metadata != null) {
    archive.addFile(ArchiveFile.string('metadata.json', jsonEncode(metadata)));
  }
  if (version != null) {
    archive.addFile(ArchiveFile.string('version.json', jsonEncode(version)));
  }
  extra?.forEach((name, bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive)!;
}

const _metadata = <String, dynamic>{
  'app_name': 'JobPilot',
  'export_time': '2026-06-20T00:00:00',
  'application_count': 1,
  'stage_count': 0,
  'version': '1.2.0+3',
};
Map<String, dynamic> _version([int schema = AppDatabase.schemaVersion]) => {
  'schema_version': schema,
  'app_version': '1.2.0+3',
};

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    // 清理上一次测试可能残留的 rollback/staging 文件，避免污染本批断言。
    final dbDir = File(await AppDatabase.instance.databasePath).parent;
    if (dbDir.existsSync()) {
      for (final entity in dbDir.listSync()) {
        final name = p.basename(entity.path);
        if (name.endsWith('.rollback') || name.endsWith('.staging')) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    }
    final db = await AppDatabase.instance.database;
    await db.delete('stages');
    await db.delete('applications');
    await db.delete('import_logs');
  });

  // 在活动库写入一条「原始」记录，用于断言失败恢复后原数据仍在。
  Future<ApplicationRecord> seedOriginal() async {
    final app = ApplicationRecord.create(companyName: '原始公司', jobTitle: '原岗');
    await ApplicationRepository().upsert(app);
    return app;
  }

  Future<void> expectOriginalSurvives(ApplicationRecord original) async {
    final apps = await ApplicationRepository().list();
    expect(apps, hasLength(1));
    expect(apps.first.id, original.id);
    // 活动库仍可正常读写。
    expect(
      await (await AppDatabase.instance.database).query('applications'),
      hasLength(1),
    );
  }

  group('jobpack validation', () {
    test('successful restore replaces the active database', () async {
      final original = await seedOriginal();
      final controller = AppController();

      final bytes = _buildJobpack(
        dataSqlite: await _makeSqliteBytes(companyName: '恢复公司'),
        metadata: _metadata,
        version: _version(),
      );

      await controller.restoreJobpackBytes(bytes);

      final apps = await ApplicationRepository().list();
      expect(apps, hasLength(1));
      expect(apps.first.companyName, '恢复公司');
      expect(apps.first.id, isNot(original.id));
    });

    test(
      'missing data.sqlite is rejected and preserves original data',
      () async {
        final original = await seedOriginal();
        final controller = AppController();

        final bytes = _buildJobpack(metadata: _metadata, version: _version());

        await expectLater(
          controller.restoreJobpackBytes(bytes),
          throwsA(
            isA<JobpackValidationException>().having(
              (e) => e.reason,
              'reason',
              JobpackValidationReason.missingDataSqlite,
            ),
          ),
        );
        await expectOriginalSurvives(original);
      },
    );

    test('missing metadata is rejected and preserves original data', () async {
      final original = await seedOriginal();
      final controller = AppController();

      final bytes = _buildJobpack(
        dataSqlite: await _makeSqliteBytes(),
        version: _version(),
      );

      await expectLater(
        controller.restoreJobpackBytes(bytes),
        throwsA(
          isA<JobpackValidationException>().having(
            (e) => e.reason,
            'reason',
            JobpackValidationReason.missingMetadata,
          ),
        ),
      );
      await expectOriginalSurvives(original);
    });

    test('missing version is rejected and preserves original data', () async {
      final original = await seedOriginal();
      final controller = AppController();

      final bytes = _buildJobpack(
        dataSqlite: await _makeSqliteBytes(),
        metadata: _metadata,
      );

      await expectLater(
        controller.restoreJobpackBytes(bytes),
        throwsA(
          isA<JobpackValidationException>().having(
            (e) => e.reason,
            'reason',
            JobpackValidationReason.missingVersion,
          ),
        ),
      );
      await expectOriginalSurvives(original);
    });

    test('corrupt JSON is rejected and preserves original data', () async {
      final original = await seedOriginal();
      final controller = AppController();

      final archive = Archive()
        ..addFile(ArchiveFile('data.sqlite', 4, [1, 2, 3, 4]))
        ..addFile(ArchiveFile.string('metadata.json', 'not-json{'))
        ..addFile(ArchiveFile.string('version.json', jsonEncode(_version())));
      final bytes = ZipEncoder().encode(archive)!;

      await expectLater(
        controller.restoreJobpackBytes(bytes),
        throwsA(
          isA<JobpackValidationException>().having(
            (e) => e.reason,
            'reason',
            JobpackValidationReason.corruptJson,
          ),
        ),
      );
      await expectOriginalSurvives(original);
    });

    test('schema mismatch is rejected and preserves original data', () async {
      final original = await seedOriginal();
      final controller = AppController();

      final bytes = _buildJobpack(
        dataSqlite: await _makeSqliteBytes(),
        metadata: _metadata,
        version: _version(99),
      );

      await expectLater(
        controller.restoreJobpackBytes(bytes),
        throwsA(
          isA<JobpackValidationException>().having(
            (e) => e.reason,
            'reason',
            JobpackValidationReason.schemaMismatch,
          ),
        ),
      );
      await expectOriginalSurvives(original);
    });

    test('fake SQLite is rejected and preserves original data', () async {
      final original = await seedOriginal();
      final controller = AppController();

      final bytes = _buildJobpack(
        dataSqlite: List<int>.generate(1024, (i) => (i * 7) & 0xFF),
        metadata: _metadata,
        version: _version(),
      );

      await expectLater(
        controller.restoreJobpackBytes(bytes),
        throwsA(
          isA<JobpackValidationException>().having(
            (e) => e.reason,
            'reason',
            JobpackValidationReason.notSqlite,
          ),
        ),
      );
      await expectOriginalSurvives(original);
    });

    test(
      'missing required tables is rejected and preserves original data',
      () async {
        final original = await seedOriginal();
        final controller = AppController();

        final bytes = _buildJobpack(
          dataSqlite: await _makeSqliteBytes(omitTable: 'stages'),
          metadata: _metadata,
          version: _version(),
        );

        await expectLater(
          controller.restoreJobpackBytes(bytes),
          throwsA(
            isA<JobpackValidationException>().having(
              (e) => e.reason,
              'reason',
              JobpackValidationReason.missingTables,
            ),
          ),
        );
        await expectOriginalSurvives(original);
      },
    );

    test(
      'oversized input is rejected without allocating huge memory',
      () async {
        final original = await seedOriginal();

        // 构造一个「压缩后极小、声明解压后巨大」的 zip 炸弹条目：声明
        // data.sqlite 解压后 5GB，但实际只写入几字节。校验器必须仅凭中央目录
        // 中声明的解压大小判定超大，绝不访问 content（解压）。
        final bomb = Uint8List.fromList([1, 2, 3, 4]);
        final archive = Archive()
          ..addFile(ArchiveFile('data.sqlite', 5_000_000_000, bomb))
          ..addFile(ArchiveFile.string('metadata.json', jsonEncode(_metadata)))
          ..addFile(ArchiveFile.string('version.json', jsonEncode(_version())));
        final bytes = ZipEncoder().encode(archive)!;

        // 输入字节本身很小（远低于默认上限），但声明的解压大小超过上限。
        expect(bytes.length, lessThan(1024));

        final validator = const JobpackValidator(maxBytes: 200 * 1024 * 1024);
        await expectLater(
          validator.validate(bytes),
          throwsA(
            isA<JobpackValidationException>().having(
              (e) => e.reason,
              'reason',
              JobpackValidationReason.oversized,
            ),
          ),
        );

        // 原数据完全未受影响。
        final apps = await ApplicationRepository().list();
        expect(apps, hasLength(1));
        expect(apps.first.id, original.id);
      },
    );

    test('oversized raw input is rejected before decoding', () async {
      await seedOriginal();
      // 一段长度超过小上限的无效字节；若先解码会抛 zip 解析错误，这里应抛
      // oversized，证明大小检查先于 zip 解码。
      final bytes = List<int>.generate(300, (i) => i & 0xFF);
      final validator = const JobpackValidator(maxBytes: 100);
      await expectLater(
        validator.validate(bytes),
        throwsA(
          isA<JobpackValidationException>().having(
            (e) => e.reason,
            'reason',
            JobpackValidationReason.oversized,
          ),
        ),
      );
    });
  });

  group('AppDatabase.replaceWith atomic rollback', () {
    test(
      'forced reopen failure rolls back and retains original data',
      () async {
        final original = await seedOriginal();
        final dbDir = File(await AppDatabase.instance.databasePath).parent;

        // 直接用一个非 SQLite 文件触发替换后的 reopen 失败。
        final bad = File(p.join(dbDir.path, 'bad_not_sqlite'))
          ..writeAsBytesSync(List<int>.generate(512, (i) => (i * 13) & 0xFF));

        await expectLater(
          AppDatabase.instance.replaceWith(bad),
          throwsA(isA<DatabaseRestoreException>()),
        );

        // 原数据完整保留，活动库仍可读。
        final apps = await ApplicationRepository().list();
        expect(apps, hasLength(1));
        expect(apps.first.id, original.id);

        // 临时回滚/暂存文件已被清理。
        final leftovers = dbDir.listSync().where((entity) {
          final name = p.basename(entity.path);
          return name.contains('.rollback') || name.contains('.staging');
        });
        expect(leftovers, isEmpty);
      },
    );

    test(
      'schema mismatch in data.sqlite is rejected before replacement',
      () async {
        final original = await seedOriginal();
        final controller = AppController();

        // version.json 声明的 schema_version 合法（=2），但库内实际
        // user_version=99。校验器以只读方式打开后会核对 user_version，发现不
        // 匹配即抛 schemaMismatch，替换前就被拦截，绝不进入 replaceWith。
        final bytes = _buildJobpack(
          dataSqlite: await _makeSqliteBytes(userVersion: 99),
          metadata: _metadata,
          version: _version(),
        );

        await expectLater(
          controller.restoreJobpackBytes(bytes),
          throwsA(
            isA<JobpackValidationException>().having(
              (e) => e.reason,
              'reason',
              JobpackValidationReason.schemaMismatch,
            ),
          ),
        );

        // 原数据完整保留，活动库仍可读（替换从未发生）。
        await expectOriginalSurvives(original);
      },
    );
  });
}
