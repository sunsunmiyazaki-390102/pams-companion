class KnowledgeAsset {
  const KnowledgeAsset({
    required this.knowledgeId,
    required this.sessionId,
    required this.conversationId,
    required this.sourceCandidateId,
    required this.knowledgeType,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String knowledgeId;
  final String sessionId;
  final String? conversationId;

  // このKnowledgeがKnowledge Candidateから
  // 作られた場合、その候補IDを保持する。
  final String? sourceCandidateId;

  final String knowledgeType;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory KnowledgeAsset.fromMap(
    Map<String, Object?> map,
  ) {
    return KnowledgeAsset(
      knowledgeId:
          map['knowledge_id'] as String,
      sessionId:
          map['session_id'] as String,
      conversationId:
          map['conversation_id'] as String?,
      sourceCandidateId:
          map['source_candidate_id'] as String?,
      knowledgeType:
          map['knowledge_type'] as String? ??
              'insight',
      content:
          map['content'] as String,
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
      'source_candidate_id':
          sourceCandidateId,
      'knowledge_type': knowledgeType,
      'content': content,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  KnowledgeAsset copyWith({
    String? knowledgeId,
    String? sessionId,
    String? conversationId,
    bool clearConversationId = false,
    String? sourceCandidateId,
    bool clearSourceCandidateId = false,
    String? knowledgeType,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeAsset(
      knowledgeId:
          knowledgeId ?? this.knowledgeId,
      sessionId:
          sessionId ?? this.sessionId,
      conversationId:
          clearConversationId
              ? null
              : conversationId ??
                  this.conversationId,
      sourceCandidateId:
          clearSourceCandidateId
              ? null
              : sourceCandidateId ??
                  this.sourceCandidateId,
      knowledgeType:
          knowledgeType ??
              this.knowledgeType,
      content:
          content ?? this.content,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}
