import '../database/database_helper.dart';
import '../models/knowledge_candidate.dart';

class KnowledgeCandidateRepository {
  KnowledgeCandidateRepository();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<void> insert(
    KnowledgeCandidate candidate,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.insert(
      'knowledge_candidates',
      candidate.toMap(),
    );
  }

  Future<void> update(
    KnowledgeCandidate candidate,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'knowledge_candidates',
      candidate.toMap(),
      where: 'candidate_id = ?',
      whereArgs: [
        candidate.candidateId,
      ],
    );
  }

  Future<void> delete(
    String candidateId,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.delete(
      'knowledge_candidates',
      where: 'candidate_id = ?',
      whereArgs: [
        candidateId,
      ],
    );
  }

  Future<KnowledgeCandidate?> findById(
    String candidateId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_candidates',
      where: 'candidate_id = ?',
      whereArgs: [
        candidateId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return KnowledgeCandidate.fromMap(
      result.first,
    );
  }

  Future<List<KnowledgeCandidate>>
      findByConversationId(
    String conversationId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'knowledge_candidates',
      where: 'conversation_id = ?',
      whereArgs: [
        conversationId,
      ],
      orderBy: 'created_at ASC',
    );

    return result
        .map(
          KnowledgeCandidate.fromMap,
        )
        .toList();
  }
}
