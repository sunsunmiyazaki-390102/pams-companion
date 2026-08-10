class ReflectionQueue {
  const ReflectionQueue({
    required this.queueId,
    required this.conversationId,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String queueId;
  final String conversationId;
  final int priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ReflectionQueue.fromMap(
    Map<String, Object?> map,
  ) {
    return ReflectionQueue(
      queueId:
          map['queue_id'] as String,
      conversationId:
          map['conversation_id'] as String,
      priority:
          map['priority'] as int? ?? 1,
      status:
          map['status'] as String? ??
              'waiting',
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
      'queue_id': queueId,
      'conversation_id': conversationId,
      'priority': priority,
      'status': status,
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  ReflectionQueue copyWith({
    String? queueId,
    String? conversationId,
    int? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReflectionQueue(
      queueId:
          queueId ?? this.queueId,
      conversationId:
          conversationId ??
              this.conversationId,
      priority:
          priority ?? this.priority,
      status:
          status ?? this.status,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}
