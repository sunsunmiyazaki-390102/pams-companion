class ReflectionQueueStatus {
  const ReflectionQueueStatus._();

  static const String waiting = 'waiting';
  static const String completed = 'completed';

  static const List<String> values = [
    waiting,
    completed,
  ];

  static String displayName(
    String status,
  ) {
    switch (status) {
      case waiting:
        return '次に育てる';

      case completed:
        return '育て終えた';

      default:
        return status;
    }
  }
}
