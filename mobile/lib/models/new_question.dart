class NewQuestion {
  const NewQuestion({
    required this.questionId,
    required this.conversationId,
    required this.content,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String questionId;
  final String conversationId;
  final String content;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NewQuestion.fromMap(
    Map<String, Object?> map,
  ) {
    return NewQuestion(
      questionId:
          map['question_id'] as String,
      conversationId:
          map['conversation_id'] as String,
      content:
          map['content'] as String,
      reason:
          map['reason'] as String? ?? '',
      status:
          map['status'] as String? ??
              'candidate',
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'question_id': questionId,
      'conversation_id': conversationId,
      'content': content,
      'reason': reason,
      'status': status,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  NewQuestion copyWith({
    String? questionId,
    String? conversationId,
    String? content,
    String? reason,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewQuestion(
      questionId:
          questionId ?? this.questionId,
      conversationId:
          conversationId ??
              this.conversationId,
      content:
          content ?? this.content,
      reason:
          reason ?? this.reason,
      status:
          status ?? this.status,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}
