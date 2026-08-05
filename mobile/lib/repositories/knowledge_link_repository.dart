import '../database/database_helper.dart';
import '../models/knowledge_link.dart';

class KnowledgeLinkRepository {
  KnowledgeLinkRepository();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<void> insert(
    KnowledgeLink link,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.insert(
      'knowledge_links',
      link.toMap(),
    );
  }

  Future<void> update(
    KnowledgeLink link,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'knowledge_links',
      link.toMap(),
      where: 'link_id = ?',
      whereArgs: [link.linkId],
    );
  }

  Future<void> delete(
    String linkId,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.delete(
      'knowledge_links',
      where: 'link_id = ?',
      whereArgs: [linkId],
    );
  }

  Future<List<KnowledgeLink>> findFromKnowledgeId(
    String knowledgeId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_links',
      where: 'from_knowledge_id = ?',
      whereArgs: [knowledgeId],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          KnowledgeLink.fromMap,
        )
        .toList();
  }

  Future<List<KnowledgeLink>> findToKnowledgeId(
    String knowledgeId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_links',
      where: 'to_knowledge_id = ?',
      whereArgs: [knowledgeId],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          KnowledgeLink.fromMap,
        )
        .toList();
  }

  Future<List<KnowledgeLink>> findByKnowledgeId(
    String knowledgeId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_links',
      where:
          'from_knowledge_id = ? OR to_knowledge_id = ?',
      whereArgs: [
        knowledgeId,
        knowledgeId,
      ],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          KnowledgeLink.fromMap,
        )
        .toList();
  }

  Future<List<KnowledgeLink>> findByLinkType(
    String linkType,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_links',
      where: 'link_type = ?',
      whereArgs: [linkType],
      orderBy: 'created_at DESC',
    );

    return result
        .map(
          KnowledgeLink.fromMap,
        )
        .toList();
  }

  Future<bool> existsBetween({
    required String fromKnowledgeId,
    required String toKnowledgeId,
    required String linkType,
  }) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_links',
      columns: ['link_id'],
      where:
          'from_knowledge_id = ? '
          'AND to_knowledge_id = ? '
          'AND link_type = ?',
      whereArgs: [
        fromKnowledgeId,
        toKnowledgeId,
        linkType,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }
}
