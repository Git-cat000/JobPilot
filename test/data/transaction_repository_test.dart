import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:jobpilot_mobile/data/db/app_database.dart';
import 'package:jobpilot_mobile/data/models/application_record.dart';
import 'package:jobpilot_mobile/data/models/import_log.dart';
import 'package:jobpilot_mobile/data/models/stage_record.dart';
import 'package:jobpilot_mobile/data/repositories/application_repository.dart';
import 'package:jobpilot_mobile/data/repositories/import_repository.dart';
import 'package:jobpilot_mobile/data/repositories/stage_repository.dart';

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

  group('ApplicationRepository deleteMany', () {
    test('deletes all specified applications', () async {
      final appRepo = ApplicationRepository();
      final app1 = ApplicationRecord.create(companyName: 'A', jobTitle: 'a');
      final app2 = ApplicationRecord.create(companyName: 'B', jobTitle: 'b');
      final app3 = ApplicationRecord.create(companyName: 'C', jobTitle: 'c');
      await appRepo.upsert(app1);
      await appRepo.upsert(app2);
      await appRepo.upsert(app3);

      await appRepo.deleteMany([app1.id, app2.id]);

      final remaining = await appRepo.list();
      expect(remaining, hasLength(1));
      expect(remaining.first.id, app3.id);
    });

    test('rolls back on error and preserves all data', () async {
      final db = await AppDatabase.instance.database;
      final appRepo = ApplicationRepository();

      final app1 = ApplicationRecord.create(companyName: 'A', jobTitle: 'a');
      final app2 = ApplicationRecord.create(companyName: 'B', jobTitle: 'b');
      await appRepo.upsert(app1);
      await appRepo.upsert(app2);

      // Set up a trigger that counts deletes and aborts on the second one
      await db.execute(
        'CREATE TEMP TABLE IF NOT EXISTS app_delete_counter (n INTEGER)',
      );
      await db.execute('DELETE FROM app_delete_counter');
      await db.execute('INSERT INTO app_delete_counter VALUES (0)');
      await db.execute('''
        CREATE TEMP TRIGGER IF NOT EXISTS count_and_block
        BEFORE DELETE ON applications
        BEGIN
          UPDATE app_delete_counter SET n = n + 1;
          SELECT RAISE(ABORT, 'too many deletes')
          FROM app_delete_counter
          WHERE n > 1;
        END
      ''');

      await expectLater(
        appRepo.deleteMany([app1.id, app2.id]),
        throwsA(isA<DatabaseException>()),
      );

      // Both applications should survive the rollback
      expect(await appRepo.list(), hasLength(2));
    });
  });

  group('ApplicationRepository clearAll', () {
    test('clears stages, applications and import_logs', () async {
      final db = await AppDatabase.instance.database;
      final appRepo = ApplicationRepository();
      final stageRepo = StageRepository();

      final app = ApplicationRecord.create(companyName: 'A', jobTitle: 'a');
      await appRepo.upsert(app);
      final stage = StageRecord.create(applicationId: app.id, stageType: '笔试');
      await stageRepo.upsert(stage);
      await db.insert(
        'import_logs',
        ImportLog.create(
          fileName: 't.csv',
          totalRows: 1,
          successRows: 1,
          duplicateRows: 0,
          failedRows: 0,
          mappingJson: '{}',
        ).toMap(),
      );

      await appRepo.clearAll();

      expect(await appRepo.list(), hasLength(0));
      expect(await stageRepo.listAll(), hasLength(0));
      expect(await db.query('import_logs'), hasLength(0));
    });

    test('rolls back on error and preserves all data', () async {
      final db = await AppDatabase.instance.database;
      final appRepo = ApplicationRepository();
      final stageRepo = StageRepository();

      final app = ApplicationRecord.create(companyName: 'A', jobTitle: 'a');
      await appRepo.upsert(app);
      final stage = StageRecord.create(applicationId: app.id, stageType: '笔试');
      await stageRepo.upsert(stage);
      await db.insert(
        'import_logs',
        ImportLog.create(
          fileName: 't.csv',
          totalRows: 1,
          successRows: 1,
          duplicateRows: 0,
          failedRows: 0,
          mappingJson: '{}',
        ).toMap(),
      );

      // Block deletion on the applications table
      await db.execute('''
        CREATE TEMP TRIGGER IF NOT EXISTS block_app_deletion
        BEFORE DELETE ON applications
        BEGIN
          SELECT RAISE(ABORT, 'delete blocked');
        END
      ''');

      await expectLater(appRepo.clearAll(), throwsA(isA<DatabaseException>()));

      // All data survives the rollback: stages were deleted first
      // but the transaction rolled back when applications delete failed
      expect(await appRepo.list(), hasLength(1));
      expect(await stageRepo.listAll(), hasLength(1));
      expect(await db.query('import_logs'), hasLength(1));
    });
  });

  group('ImportRepository', () {
    test('commit inserts records and import_log atomically', () async {
      final appRepo = ApplicationRepository();
      final importRepo = ImportRepository();

      final app1 = ApplicationRecord.create(companyName: 'A', jobTitle: 'a');
      final app2 = ApplicationRecord.create(companyName: 'B', jobTitle: 'b');
      final log = ImportLog.create(
        fileName: 't.csv',
        totalRows: 2,
        successRows: 2,
        duplicateRows: 0,
        failedRows: 0,
        mappingJson: '{}',
      );

      await importRepo.commit([app1, app2], log);

      expect(await appRepo.list(), hasLength(2));
      final db = await AppDatabase.instance.database;
      final logs = await db.query('import_logs');
      expect(logs, hasLength(1));
      expect(logs.first['file_name'], 't.csv');
    });

    test('rolls back all inserts on duplicate key conflict', () async {
      final appRepo = ApplicationRepository();
      final importRepo = ImportRepository();

      final app1 = ApplicationRecord.create(companyName: 'A', jobTitle: 'a');
      // app2 shares the same id → primary key conflict
      final app2 = app1.copyWith(companyName: 'B');
      final log = ImportLog.create(
        fileName: 'dup.csv',
        totalRows: 2,
        successRows: 2,
        duplicateRows: 0,
        failedRows: 0,
        mappingJson: '{}',
      );

      await expectLater(
        importRepo.commit([app1, app2], log),
        throwsA(isA<DatabaseException>()),
      );

      // No applications or logs should exist after the rollback
      expect(await appRepo.list(), hasLength(0));
      final db = await AppDatabase.instance.database;
      final logs = await db.query('import_logs');
      expect(logs, hasLength(0));
    });
  });
}
