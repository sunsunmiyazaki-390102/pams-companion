import '../database/database_helper.dart';
import '../models/daily_memory.dart';

class DailyMemoryRepository {
  DailyMemoryRepository();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<void> insert(
    DailyMemory memory,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.insert(
      'daily_memories',
      memory.toMap(),
    );
  }

  Future<void> update(
    DailyMemory memory,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'daily_memories',
      memory.toMap(),
      where: 'memory_id = ?',
      whereArgs: [
        memory.memoryId,
      ],
    );
  }

  Future<void> delete(
    String memoryId,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.delete(
      'daily_memories',
      where: 'memory_id = ?',
      whereArgs: [
        memoryId,
      ],
    );
  }

  Future<DailyMemory?> findById(
    String memoryId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'daily_memories',
      where: 'memory_id = ?',
      whereArgs: [
        memoryId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return DailyMemory.fromMap(
      result.first,
    );
  }

  Future<DailyMemory?> findByDate(
    String memoryDate,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'daily_memories',
      where: 'memory_date = ?',
      whereArgs: [
        memoryDate,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return DailyMemory.fromMap(
      result.first,
    );
  }
}
