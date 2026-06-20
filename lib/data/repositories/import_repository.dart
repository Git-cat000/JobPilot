import '../db/app_database.dart';
import '../models/application_record.dart';
import '../models/import_log.dart';

class ImportRepository {
  ImportRepository({AppDatabase? database})
    : database = database ?? AppDatabase.instance;

  final AppDatabase database;

  Future<void> commit(List<ApplicationRecord> records, ImportLog log) async {
    final db = await database.database;
    await db.transaction((txn) async {
      for (final record in records) {
        await txn.insert('applications', record.toMap());
      }
      await txn.insert('import_logs', log.toMap());
    });
  }
}
