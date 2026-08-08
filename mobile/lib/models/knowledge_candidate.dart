class KnowledgeCandidate {
  const KnowledgeCandidate({
    required this.candidateId,
    required this.conversationId,
    required this.content,
    required this.suggestedType,
    required this.reason,
    required this.sourceExcerpt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String candidateId;
  final String conversationId;
  final String content;
  final String suggestedType;
  final String reason;
  final String? sourceExcerpt;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory KnowledgeCandidate.fromMap(
    Map<String, Object?> map,
  ) {
    return KnowledgeCandidate(
      candidateId:
          map['candidate_id'] as String,
      conversationId:
          map['conversation_id'] as String,
      content:
          map['content'] as String,
      suggestedType:
          map['suggested_type'] as String,
      reason:
          map['reason'] as String? ?? '',
      sourceExcerpt:
          map['source_excerpt'] as String?,
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
      'candidate_id': candidateId,
      'conversation_id': conversationId,
      'content': content,
      'suggested_type': suggestedType,
      'reason': reason,
      'source_excerpt': sourceExcerpt,
      'status': status,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  KnowledgeCandidate copyWith({
    String? candidateId,
    String? conversationId,
    String? content,
    String? suggestedType,
    String? reason,
    String? sourceExcerpt,
    bool clearSourceExcerpt = false,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeCandidate(
      candidateId:
          candidateId ?? this.candidateId,
      conversationId:
          conversationId ??
              this.conversationId,
      content:
          content ?? this.content,
      suggestedType:
          suggestedType ??
              this.suggestedType,
      reason:
          reason ?? this.reason,
      sourceExcerpt:
          clearSourceExcerpt
              ? null
              : sourceExcerpt ??
                  this.sourceExcerpt,
      status:
          status ?? this.status,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}
