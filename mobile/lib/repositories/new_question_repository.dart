import '../database/database_helper.dart';
import '../models/new_question.dart';

class NewQuestionRepository {
  NewQuestionRepository();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  Future<void> insert(
    NewQuestion question,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.insert(
      'new_questions',
      question.toMap(),
    );
  }

  Future<void> update(
    NewQuestion question,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.update(
      'new_questions',
      question.toMap(),
      where: 'question_id = ?',
      whereArgs: [
        question.questionId,
      ],
    );
  }

  Future<void> delete(
    String questionId,
  ) async {
    final database =
        await _databaseHelper.database;

    await database.delete(
      'new_questions',
      where: 'question_id = ?',
      whereArgs: [
        questionId,
      ],
    );
  }

  Future<NewQuestion?> findById(
    String questionId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'new_questions',
      where: 'question_id = ?',
      whereArgs: [
        questionId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return NewQuestion.fromMap(
      result.first,
    );
  }

  Future<List<NewQuestion>>
      findByConversationId(
    String conversationId,
  ) async {
    final database =
        await _databaseHelper.database;

    final result = await database.query(
      'new_questions',
      where: 'conversation_id = ?',
      whereArgs: [
        conversationId,
      ],
      orderBy: 'created_at ASC',
    );

    return result
        .map(
          NewQuestion.fromMap,
        )
        .toList();
  }
}
