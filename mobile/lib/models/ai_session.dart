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
}
