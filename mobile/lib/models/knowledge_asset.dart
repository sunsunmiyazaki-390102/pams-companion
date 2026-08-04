class KnowledgeAsset {
  const KnowledgeAsset({
    required this.knowledgeId,
    required this.sessionId,
    required this.conversationId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String knowledgeId;
  final String sessionId;
  final String? conversationId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory KnowledgeAsset.fromMap(
    Map<String, Object?> map,
  ) {
    return KnowledgeAsset(
      knowledgeId: map['knowledge_id'] as String,
      sessionId: map['session_id'] as String,
      conversationId: map['conversation_id'] as String?,
      content: map['content'] as String,
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
      'knowledge_id': knowledgeId,
      'session_id': sessionId,
      'conversation_id': conversationId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  KnowledgeAsset copyWith({
    String? knowledgeId,
    String? sessionId,
    String? conversationId,
    bool clearConversationId = false,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeAsset(
      knowledgeId: knowledgeId ?? this.knowledgeId,
      sessionId: sessionId ?? this.sessionId,
      conversationId: clearConversationId
          ? null
          : conversationId ?? this.conversationId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
