import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:jobpilot_mobile/data/db/app_database.dart';
import 'package:jobpilot_mobile/data/models/application_record.dart';
import 'package:jobpilot_mobile/data/models/stage_record.dart';
import 'package:jobpilot_mobile/data/repositories/application_repository.dart';
import 'package:jobpilot_mobile/data/repositories/stage_repository.dart';
import 'package:jobpilot_mobile/shared/state/app_controller.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final db = await AppDatabase.instance.database;
    await db.delete('stages');
    await db.delete('applications');
    await db.delete('import_logs');
  });

  group('AppDatabase.createSnapshot', () {
    test('captures the latest application and stage consistently', () async {
      final appRepo = ApplicationRepository();
      final stageRepo = StageRepository();
      final app = ApplicationRecord.create(
        companyName: '华为',
        jobTitle: 'AI算法工程师',
      );
      await appRepo.upsert(app);
      final stage = StageRecord.create(applicationId: app.id, stageType: '笔试');
      await stageRepo.upsert(stage);

      final snapshot = await AppDatabase.instance.createSnapshot();
      addTearDown(() {
        try {
          snapshot.parent.deleteSync(recursive: true);
        } catch (_) {}
      });

      // The snapshot must be a standalone, readable SQLite database whose
      // contents reflect the latest writes — not a stale or open DB handle.
      final snapDb = await openDatabase(
        snapshot.path,
        readOnly: true,
        singleInstance: false,
      );
      addTearDown(() => snapDb.close());

      final apps = await snapDb.query('applications');
      final stages = await snapDb.query('stages');
      expect(apps, hasLength(1));
      expect(apps.first['company_name'], '华为');
      expect(stages, hasLength(1));
      expect(stages.first['application_id'], app.id);

      final integrity = await snapDb.rawQuery('PRAGMA integrity_check');
      expect(integrity.first.values.first, 'ok');
    });

    test('reopens the active database after snapshotting', () async {
      final app = ApplicationRecord.create(companyName: 'A', jobTitle: 'a');
      await ApplicationRepository().upsert(app);

      final snapshot = await AppDatabase.instance.createSnapshot();
      addTearDown(() {
        try {
          snapshot.parent.deleteSync(recursive: true);
        } catch (_) {}
      });

      // The singleton must be usable again immediately afterwards.
      expect(await ApplicationRepository().list(), hasLength(1));
    });
  });

  group('AppDatabase schema version', () {
    test(
      'declares schemaVersion 2 and applies it to the open database',
      () async {
        expect(AppDatabase.schemaVersion, 2);
        final db = await AppDatabase.instance.database;
        final version = await db.rawQuery('PRAGMA user_version');
        expect(version.first.values.first, 2);
      },
    );
  });

  group('jobpack export', () {
    test('archives a consistent snapshot with the latest records', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final exportDir = await Directory.systemTemp.createTemp(
        'jobpilot_export_e2e_',
      );
      addTearDown(() {
        try {
          exportDir.deleteSync(recursive: true);
        } catch (_) {}
      });
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return exportDir.path;
          }
          return null;
        },
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          pathProviderChannel,
          null,
        ),
      );

      final appRepo = ApplicationRepository();
      final stageRepo = StageRepository();
      final app = ApplicationRecord.create(
        companyName: '字节跳动',
        jobTitle: '后端开发',
      );
      await appRepo.upsert(app);
      final stage = StageRecord.create(applicationId: app.id, stageType: '一面');
      await stageRepo.upsert(stage);

      final controller = AppController();
      final jobpack = await controller.exportJobpack();
      expect(jobpack.existsSync(), isTrue);

      final archive = ZipDecoder().decodeBytes(await jobpack.readAsBytes());
      final sqliteBytes =
          archive.files.singleWhere((f) => f.name == 'data.sqlite').content
              as List<int>;

      // Write the extracted database to a temp file and open it read-only.
      final extractedDir = await Directory.systemTemp.createTemp(
        'jobpilot_extracted_',
      );
      addTearDown(() {
        try {
          extractedDir.deleteSync(recursive: true);
        } catch (_) {}
      });
      final extracted = File(p.join(extractedDir.path, 'data.sqlite'))
        ..writeAsBytesSync(sqliteBytes);
      final snapDb = await openDatabase(
        extracted.path,
        readOnly: true,
        singleInstance: false,
      );
      addTearDown(() => snapDb.close());

      expect(await snapDb.query('applications'), hasLength(1));
      expect(await snapDb.query('stages'), hasLength(1));
      final integrity = await snapDb.rawQuery('PRAGMA integrity_check');
      expect(integrity.first.values.first, 'ok');

      final versionJson =
          jsonDecode(
                utf8.decode(
                  archive.files
                          .singleWhere((f) => f.name == 'version.json')
                          .content
                      as List<int>,
                ),
              )
              as Map<String, dynamic>;
      expect(versionJson['schema_version'], AppDatabase.schemaVersion);
    });
  });
}
