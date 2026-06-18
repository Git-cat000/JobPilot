import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';

class AppSettingsRepository {
  AppSettingsRepository({AppDatabase? database})
    : database = database ?? AppDatabase.instance;

  final AppDatabase database;

  Future<String> get(String key, {required String fallback}) async {
    final db = await database.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? fallback : rows.first['value'] as String? ?? fallback;
  }

  Future<void> set(String key, String value) async {
    final db = await database.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
