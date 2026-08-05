class KnowledgeLink {
  const KnowledgeLink({
    required this.linkId,
    required this.fromKnowledgeId,
    required this.toKnowledgeId,
    required this.linkType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String linkId;
  final String fromKnowledgeId;
  final String toKnowledgeId;
  final String linkType;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory KnowledgeLink.fromMap(
    Map<String, Object?> map,
  ) {
    return KnowledgeLink(
      linkId: map['link_id'] as String,
      fromKnowledgeId:
          map['from_knowledge_id'] as String,
      toKnowledgeId:
          map['to_knowledge_id'] as String,
      linkType: map['link_type'] as String,
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
      'link_id': linkId,
      'from_knowledge_id': fromKnowledgeId,
      'to_knowledge_id': toKnowledgeId,
      'link_type': linkType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  KnowledgeLink copyWith({
    String? linkId,
    String? fromKnowledgeId,
    String? toKnowledgeId,
    String? linkType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeLink(
      linkId: linkId ?? this.linkId,
      fromKnowledgeId:
          fromKnowledgeId ?? this.fromKnowledgeId,
      toKnowledgeId:
          toKnowledgeId ?? this.toKnowledgeId,
      linkType: linkType ?? this.linkType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
