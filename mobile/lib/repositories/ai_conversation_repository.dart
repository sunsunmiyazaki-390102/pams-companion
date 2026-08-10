import '../database/database_helper.dart';
import '../models/ai_conversation.dart';

class AiConversationRepository {
  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<List<AiConversation>> findAll() async {
    final database =
        await _databaseHelper.database;

    final maps = await database.query(
      'ai_conversations',
      orderBy: 'updated_at DESC',
    );

    return maps
        .map(
          AiConversation.fromMap,
        )
        .toList();
  }

  Future<List<AiConversation>> findBySessionId(
    String sessionId,
  ) async {
    final database =
        await _databaseHelper.database;

    final maps = await database.query(
      'ai_conversations',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'updated_at DESC',
    );

    return maps
        .map(
          AiConversation.fromMap,
        )
        .toList();
  }

  Future<List<AiConversation>> findByResponseStatus(
    String responseStatus,
  ) async {
    final database =
        await _databaseHelper.database;

    final maps = await database.query(
      'ai_conversations',
      where: 'response_status = ?',
      whereArgs: [responseStatus],
      orderBy: 'updated_at DESC',
    );

    return maps
        .map(
          AiConversation.fromMap,
        )
        .toList();
  }

  Future<AiConversation?> findById(
    String conversationId,
  ) async {
    final database =
        await _databaseHelper.database;

    final maps = await database.query(
      'ai_conversations',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return AiConversation.fromMap(
      maps.first,
    );
  }

  Future<void> insert(
    AiConversation conversation,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.insert(
      'ai_conversations',
      conversation.toMap(),
    );
  }

  Future<void> update(
    AiConversation conversation,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'ai_conversations',
      {
        'user_message':
            conversation.userMessage,
        'ai_response':
            conversation.aiResponse,
        'summary':
            conversation.summary,
        'ai_provider':
            conversation.aiProvider,
        'response_status':
            conversation.responseStatus,
        'updated_at':
            conversation.updatedAt
                .toIso8601String(),
      },
      where: 'conversation_id = ?',
      whereArgs: [
        conversation.conversationId,
      ],
    );
  }

  Future<void> updateSummary({
    required String conversationId,
    required String summary,
  }) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'ai_conversations',
      {
        'summary': summary,
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      where: 'conversation_id = ?',
      whereArgs: [
        conversationId,
      ],
    );
  }

  Future<void> updateResponseStatus({
    required String conversationId,
    required String responseStatus,
  }) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'ai_conversations',
      {
        'response_status':
            responseStatus,
        'updated_at':
            DateTime.now()
                .toIso8601String(),
      },
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> delete(
    String conversationId,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.delete(
      'ai_conversations',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<List<AiConversation>> findByCreatedAtRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'ai_conversations',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          AiConversation.fromMap,
        )
        .toList();
  } 
}
