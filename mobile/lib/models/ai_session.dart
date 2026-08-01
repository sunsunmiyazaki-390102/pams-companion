class AiSession {
  const AiSession({
    required this.sessionId,
    required this.projectId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String sessionId;
  final String projectId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AiSession.fromMap(Map<String, Object?> map) {
    return AiSession(
      sessionId: map['session_id'] as String,
      projectId: map['project_id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
