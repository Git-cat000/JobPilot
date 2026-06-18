import '../db/app_database.dart';
import '../models/import_log.dart';

class ImportLogRepository {
  ImportLogRepository({AppDatabase? database})
    : database = database ?? AppDatabase.instance;

  final AppDatabase database;

  Future<void> insert(ImportLog log) async {
    final db = await database.database;
    await db.insert('import_logs', log.toMap());
  }
}
