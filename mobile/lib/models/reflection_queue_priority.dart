class ReflectionQueuePriority {
  const ReflectionQueuePriority._();

  static const int someday = 1;
  static const int important = 2;
  static const int next = 3;

  static const List<int> values = [
    next,
    important,
    someday,
  ];

  static String displayName(
    int priority,
  ) {
    switch (priority) {
      case next:
        return '次に考えたい';

      case important:
        return '大切';

      case someday:
        return 'いつか整理';

      default:
        return '未設定';
    }
  }

  static String stars(
    int priority,
  ) {
    switch (priority) {
      case next:
        return '★★★';

      case important:
        return '★★';

      case someday:
        return '★';

      default:
        return '';
    }
  }

  static String displayLabel(
    int priority,
  ) {
    final starText = stars(priority);
    final name = displayName(priority);

    if (starText.isEmpty) {
      return name;
    }

    return '$starText $name';
  }
}
