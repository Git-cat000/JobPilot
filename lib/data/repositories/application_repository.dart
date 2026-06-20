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
    final count = await db.update(
      'applications',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    if (count == 0) {
      await db.insert(
        'applications',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
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

  Future<void> deleteMany(Iterable<String> ids) async {
    final db = await database.database;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.delete('applications', where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  Future<void> clearAll() async {
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.delete('stages');
      await txn.delete('applications');
      await txn.delete('import_logs');
    });
  }
}
