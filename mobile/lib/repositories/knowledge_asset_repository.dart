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

  Future<void> updateArchivedStatus({
    required String knowledgeId,
    required bool isArchived,
  }) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'knowledge_assets',
      {
        'is_archived':
            isArchived ? 1 : 0,
        'updated_at':
            DateTime.now()
                .toIso8601String(),
      },
      where: 'knowledge_id = ?',
      whereArgs: [knowledgeId],
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
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          KnowledgeAsset.fromMap,
        )
        .toList();
  }

  Future<List<KnowledgeAsset>>
      findArchived() async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_assets',
      where: 'is_archived = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );

    return result
        .map(
          KnowledgeAsset.fromMap,
        )
        .toList();
  }

  Future<List<KnowledgeAsset>> findByCreatedAtRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_assets',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
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
      where:
          'is_archived = ? AND content LIKE ?',
      whereArgs: [
        0,
        '%$normalizedKeyword%',
      ],
      orderBy: 'updated_at DESC',
    );

    return result
        .map(
          KnowledgeAsset.fromMap,
        )
        .toList();
  }

}
