import '../database/database_helper.dart';
import '../models/reflection_queue.dart';

class ReflectionQueueRepository {
  ReflectionQueueRepository();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<void> insert(
    ReflectionQueue queue,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.insert(
      'reflection_queue',
      queue.toMap(),
    );
  }

  Future<void> update(
    ReflectionQueue queue,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'reflection_queue',
      queue.toMap(),
      where: 'queue_id = ?',
      whereArgs: [
        queue.queueId,
      ],
    );
  }

  Future<void> delete(
    String queueId,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.delete(
      'reflection_queue',
      where: 'queue_id = ?',
      whereArgs: [
        queueId,
      ],
    );
  }

  Future<ReflectionQueue?> findById(
    String queueId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'reflection_queue',
      where: 'queue_id = ?',
      whereArgs: [
        queueId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ReflectionQueue.fromMap(
      result.first,
    );
  }

  Future<ReflectionQueue?>
      findByConversationId(
    String conversationId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'reflection_queue',
      where: 'conversation_id = ?',
      whereArgs: [
        conversationId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ReflectionQueue.fromMap(
      result.first,
    );
  }

  Future<List<ReflectionQueue>>
      findByStatus(
    String status,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'reflection_queue',
      where: 'status = ?',
      whereArgs: [
        status,
      ],
      orderBy:
          'priority DESC, updated_at ASC',
    );

    return result
        .map(
          ReflectionQueue.fromMap,
        )
        .toList();
  }

  Future<void> updatePriority({
    required String queueId,
    required int priority,
  }) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'reflection_queue',
      {
        'priority': priority,
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      where: 'queue_id = ?',
      whereArgs: [
        queueId,
      ],
    );
  }

  Future<void> updateStatus({
    required String queueId,
    required String status,
  }) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'reflection_queue',
      {
        'status': status,
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      where: 'queue_id = ?',
      whereArgs: [
        queueId,
      ],
    );
  }
}
