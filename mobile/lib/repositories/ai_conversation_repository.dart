import '../database/database_helper.dart';
import '../models/ai_conversation.dart';

class AiConversationRepository {
  final _databaseHelper = DatabaseHelper.instance;

  Future<List<AiConversation>> findBySessionId(
    String sessionId,
  ) async {
    final database = await _databaseHelper.database;

    final maps = await database.query(
      'ai_conversations',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'updated_at DESC',
    );

    return maps.map(AiConversation.fromMap).toList();
  }

  Future<void> insert(AiConversation conversation) async {
    final database = await _databaseHelper.database;

    await database.insert(
      'ai_conversations',
      conversation.toMap(),
    );
  }

  Future<void> update(AiConversation conversation) async {
    final database = await _databaseHelper.database;

    await database.update(
      'ai_conversations',
      {
        'user_message': conversation.userMessage,
        'ai_response': conversation.aiResponse,
        'summary': conversation.summary,
        'ai_provider': conversation.aiProvider,
        'updated_at': conversation.updatedAt.toIso8601String(),
      },
      where: 'conversation_id = ?',
      whereArgs: [conversation.conversationId],
    );
  }

  Future<void> delete(String conversationId) async {
    final database = await _databaseHelper.database;

    await database.delete(
      'ai_conversations',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }
}
