import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<String> get databasePath async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'jobpilot.sqlite');
  }

  Future<Database> _open() async {
    return openDatabase(
      await databasePath,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE applications (
  id TEXT PRIMARY KEY,
  company_name TEXT NOT NULL,
  job_title TEXT NOT NULL,
  job_direction TEXT NOT NULL,
  city TEXT NOT NULL,
  channel TEXT NOT NULL,
  status TEXT NOT NULL,
  priority TEXT NOT NULL,
  apply_date TEXT NOT NULL,
  next_follow_date TEXT NOT NULL,
  jd_link TEXT NOT NULL,
  resume_version TEXT NOT NULL,
  salary_range TEXT NOT NULL,
  remark TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE stages (
  id TEXT PRIMARY KEY,
  application_id TEXT NOT NULL,
  stage_type TEXT NOT NULL,
  stage_time TEXT NOT NULL,
  result TEXT NOT NULL,
  questions TEXT NOT NULL,
  review TEXT NOT NULL,
  next_action TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(application_id) REFERENCES applications(id) ON DELETE CASCADE
)
''');
        await db.execute('''
CREATE TABLE materials (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  direction TEXT NOT NULL,
  version TEXT NOT NULL,
  file_path TEXT NOT NULL,
  remark TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE import_logs (
  id TEXT PRIMARY KEY,
  file_name TEXT NOT NULL,
  import_time TEXT NOT NULL,
  total_rows INTEGER NOT NULL,
  success_rows INTEGER NOT NULL,
  duplicate_rows INTEGER NOT NULL,
  failed_rows INTEGER NOT NULL,
  mapping_json TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
        await _createOptionTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createOptionTables(db);
        }
      },
    );
  }

  Future<void> _createOptionTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS app_options (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  value TEXT NOT NULL,
  label TEXT NOT NULL,
  UNIQUE(type, value)
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> replaceWith(File sqliteFile) async {
    await close();
    final target = File(await databasePath);
    if (target.existsSync()) {
      final backup = File('${target.path}.before_restore');
      target.copySync(backup.path);
    }
    sqliteFile.copySync(target.path);
    _database = await _open();
  }
}
