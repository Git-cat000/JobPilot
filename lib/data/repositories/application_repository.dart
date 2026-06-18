import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/application_record.dart';

class ApplicationRepository {
  ApplicationRepository({AppDatabase? database})
    : database = database ?? AppDatabase.instance;

  final AppDatabase database;

  Future<List<ApplicationRecord>> list() async {
    final db = await database.database;
    final rows = await db.query(
      'applications',
      orderBy: 'updated_at DESC, created_at DESC',
    );
    return rows.map(ApplicationRecord.fromMap).toList();
  }

  Future<ApplicationRecord?> getById(String id) async {
    final db = await database.database;
    final rows = await db.query(
      'applications',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : ApplicationRecord.fromMap(rows.first);
  }

  Future<void> upsert(ApplicationRecord record) async {
    final db = await database.database;
    await db.insert(
      'applications',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAll(List<ApplicationRecord> records) async {
    final db = await database.database;
    final batch = db.batch();
    for (final record in records) {
      batch.insert(
        'applications',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(String id) async {
    final db = await database.database;
    await db.delete('applications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database.database;
    await db.delete('stages');
    await db.delete('applications');
    await db.delete('import_logs');
  }
}
