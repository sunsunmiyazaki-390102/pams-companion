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

}
