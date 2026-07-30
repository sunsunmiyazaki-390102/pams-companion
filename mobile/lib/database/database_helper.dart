import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String databaseName = 'pams_companion.db';
  static const int databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    final currentDatabase = _database;

    if (currentDatabase != null) {
      return currentDatabase;
    }

    final openedDatabase = await _openDatabase();
    _database = openedDatabase;

    return openedDatabase;
  }

  Future<Database> _openDatabase() async {
    final databaseDirectory = await getDatabasesPath();
    final databasePath = path.join(
      databaseDirectory,
      databaseName,
    );

    return openDatabase(
      databasePath,
      version: databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(
    Database database,
    int version,
  ) async {
    // テーブル作成処理は次回以降に追加する。
  }

  Future<void> close() async {
    final currentDatabase = _database;

    if (currentDatabase == null) {
      return;
    }

    await currentDatabase.close();
    _database = null;
  }
}
