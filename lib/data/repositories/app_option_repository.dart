import '../db/app_database.dart';
import '../models/app_option.dart';

class AppOptionRepository {
  AppOptionRepository({AppDatabase? database})
    : database = database ?? AppDatabase.instance;

  final AppDatabase database;

  Future<List<AppOption>> list(String type) async {
    final db = await database.database;
    final rows = await db.query(
      'app_options',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'label ASC',
    );
    return rows.map(AppOption.fromMap).toList();
  }

  Future<void> add(AppOption option) async {
    final db = await database.database;
    await db.insert('app_options', option.toMap());
  }

  Future<void> delete({required String type, required String value}) async {
    final db = await database.database;
    await db.delete(
      'app_options',
      where: 'type = ? AND value = ?',
      whereArgs: [type, value],
    );
  }
}
