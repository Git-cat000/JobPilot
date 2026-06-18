import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/stage_record.dart';

class StageRepository {
  StageRepository({AppDatabase? database})
    : database = database ?? AppDatabase.instance;

  final AppDatabase database;

  Future<List<StageRecord>> listForApplication(String applicationId) async {
    final db = await database.database;
    final rows = await db.query(
      'stages',
      where: 'application_id = ?',
      whereArgs: [applicationId],
      orderBy: 'stage_time DESC, created_at DESC',
    );
    return rows.map(StageRecord.fromMap).toList();
  }

  Future<List<StageRecord>> listAll() async {
    final db = await database.database;
    final rows = await db.query('stages', orderBy: 'stage_time DESC');
    return rows.map(StageRecord.fromMap).toList();
  }

  Future<void> upsert(StageRecord record) async {
    final db = await database.database;
    await db.insert(
      'stages',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await database.database;
    await db.delete('stages', where: 'id = ?', whereArgs: [id]);
  }
}
