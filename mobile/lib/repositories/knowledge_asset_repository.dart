import '../database/database_helper.dart';
import '../models/knowledge_asset.dart';

class KnowledgeAssetRepository {
  KnowledgeAssetRepository();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<void> insert(
    KnowledgeAsset asset,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.insert(
      'knowledge_assets',
      asset.toMap(),
    );
  }

  Future<void> update(
    KnowledgeAsset asset,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'knowledge_assets',
      asset.toMap(),
      where: 'knowledge_id = ?',
      whereArgs: [asset.knowledgeId],
    );
  }

  Future<void> delete(
    String knowledgeId,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.delete(
      'knowledge_assets',
      where: 'knowledge_id = ?',
      whereArgs: [knowledgeId],
    );
  }

  Future<KnowledgeAsset?> findByConversationId(
    String conversationId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_assets',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return KnowledgeAsset.fromMap(
      result.first,
    );
  }

  Future<KnowledgeAsset?> findBySourceCandidateId(
    String sourceCandidateId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_assets',
      where: 'source_candidate_id = ?',
      whereArgs: [
        sourceCandidateId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return KnowledgeAsset.fromMap(
      result.first,
    );
  }

  Future<List<KnowledgeAsset>>
      findBySessionId(
    String sessionId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_assets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          KnowledgeAsset.fromMap,
        )
        .toList();
  }

  Future<KnowledgeAsset?> findById(
    String knowledgeId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_assets',
      where: 'knowledge_id = ?',
      whereArgs: [knowledgeId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return KnowledgeAsset.fromMap(
      result.first,
    );
  }

  Future<List<KnowledgeAsset>> findAll() async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_assets',
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          KnowledgeAsset.fromMap,
        )
        .toList();
  }

  Future<List<KnowledgeAsset>> search(
    String keyword,
  ) async {
    final database =
        await _databaseHelper.database;

    final normalizedKeyword = keyword.trim();

    if (normalizedKeyword.isEmpty) {
      return findAll();
    }

    final result = await database.query(
      'knowledge_assets',
      where: 'content LIKE ?',
      whereArgs: ['%$normalizedKeyword%'],
      orderBy: 'updated_at DESC',
    );

    return result
        .map(
          KnowledgeAsset.fromMap,
        )
        .toList();
  }

}
