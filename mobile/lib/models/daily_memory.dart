class DailyMemory {
  const DailyMemory({
    required this.memoryId,
    required this.memoryDate,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String memoryId;
  final String memoryDate;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DailyMemory.fromMap(
    Map<String, Object?> map,
  ) {
    return DailyMemory(
      memoryId:
          map['memory_id'] as String,
      memoryDate:
          map['memory_date'] as String,
      content:
          map['content'] as String? ?? '',
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
      'memory_id': memoryId,
      'memory_date': memoryDate,
      'content': content,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  DailyMemory copyWith({
    String? memoryId,
    String? memoryDate,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyMemory(
      memoryId:
          memoryId ?? this.memoryId,
      memoryDate:
          memoryDate ?? this.memoryDate,
      content:
          content ?? this.content,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}
