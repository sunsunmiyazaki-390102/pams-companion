enum ConversationRole {
  user,
  assistant,
  system,
}

class AiConversation {
  const AiConversation({
    required this.conversationId,
    required this.sessionId,
    required this.role,
    required this.message,
    required this.createdAt,
  });

  final String conversationId;

  final String sessionId;

  final ConversationRole role;

  final String message;

  final DateTime createdAt;
}
