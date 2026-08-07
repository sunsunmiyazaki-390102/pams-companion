class AiConversation {
  const AiConversation({
    required this.conversationId,
    required this.sessionId,
    required this.userMessage,
    required this.aiResponse,
    required this.summary,
    required this.aiProvider,
    required this.responseStatus,
    required this.createdAt,
    required this.updatedAt,
  }); 

  final String conversationId;
  final String sessionId;
  final String userMessage;
  final String aiResponse;
  final String summary;
  final String aiProvider;
  final String responseStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiConversation copyWith({
    String? conversationId,
    String? sessionId,
    String? userMessage,
    String? aiResponse,
    String? summary,
    String? aiProvider,
    String? responseStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiConversation(
      conversationId: conversationId ?? this.conversationId,
      sessionId: sessionId ?? this.sessionId,
      userMessage: userMessage ?? this.userMessage,
      aiResponse: aiResponse ?? this.aiResponse,
      summary: summary ?? this.summary,
      aiProvider: aiProvider ?? this.aiProvider,
      responseStatus:
          responseStatus ??
          this.responseStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'conversation_id': conversationId,
      'session_id': sessionId,
      'user_message': userMessage,
      'ai_response': aiResponse,
      'summary': summary,
      'ai_provider': aiProvider,
      'response_status': responseStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AiConversation.fromMap(
    Map<String, Object?> map,
  ) {
    return AiConversation(
      conversationId: map['conversation_id'] as String,
      sessionId: map['session_id'] as String,
      userMessage: map['user_message'] as String,
      aiResponse: map['ai_response'] as String,
      summary: map['summary'] as String? ?? '',
      aiProvider: map['ai_provider'] as String? ?? '',
      responseStatus:
          map['response_status']
              as String? ??
          'received',     
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
    );
  }
}
