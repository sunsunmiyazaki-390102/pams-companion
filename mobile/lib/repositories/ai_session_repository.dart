import '../database/database_helper.dart';
import '../models/ai_session.dart';

class AiSessionRepository {
  final _databaseHelper = DatabaseHelper.instance;

  Future<List<AiSession>> findByProjectId(String projectId) async {
    final database = await _databaseHelper.database;

    final maps = await database.query(
      'ai_sessions',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'updated_at DESC',
    );

    return maps.map(AiSession.fromMap).toList();
  }

  Future<AiSession?> findById(
    String sessionId,
  ) async {
    final database =
        await _databaseHelper.database;

    final maps = await database.query(
      'ai_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return AiSession.fromMap(
      maps.first,
    );
  }

  Future<void> insert(AiSession session) async {
    final database = await _databaseHelper.database;

    await database.insert(
      'ai_sessions',
      {
        'session_id': session.sessionId,
        'project_id': session.projectId,
        'title': session.title,
        'created_at': session.createdAt.toIso8601String(),
        'updated_at': session.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> update(AiSession session) async {
    final database = await _databaseHelper.database;

    await database.update(
      'ai_sessions',
      {
        'title': session.title,
        'updated_at': session.updatedAt.toIso8601String(),
      },
      where: 'session_id = ?',
      whereArgs: [session.sessionId],
    );
  }

  Future<void> delete(String sessionId) async {
    final database = await _databaseHelper.database;

    await database.delete(
      'ai_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> updateProjectId({
    required String sessionId,
    required String projectId,
  }) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'ai_sessions',
      {
        'project_id': projectId,
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      where: 'session_id = ?',
      whereArgs: [
        sessionId,
      ],
    );
  }
}
