import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:jobpilot_mobile/data/db/app_database.dart';
import 'package:jobpilot_mobile/data/models/application_record.dart';
import 'package:jobpilot_mobile/data/models/stage_record.dart';
import 'package:jobpilot_mobile/data/repositories/application_repository.dart';
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

  group('ApplicationRepository', () {
    test('upsert preserves stages when editing an application', () async {
      final appRepo = ApplicationRepository();
      final stageRepo = StageRepository();

      final original = ApplicationRecord.create(
        companyName: '华为',
        jobTitle: 'AI工程师',
      );
      await appRepo.upsert(original);

      final stage = StageRecord.create(
        applicationId: original.id,
        stageType: '笔试',
      );
      await stageRepo.upsert(stage);

      // Edit the application — this should NOT delete linked stages
      await appRepo.upsert(original.copyWith(companyName: '华为技术有限公司'));

      final stages = await stageRepo.listForApplication(original.id);
      expect(stages, hasLength(1));
      expect(stages.first.stageType, '笔试');
    });
  });
}
