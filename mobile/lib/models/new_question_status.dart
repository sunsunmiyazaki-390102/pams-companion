class NewQuestionStatus {
  const NewQuestionStatus._();

  static const String candidate = 'candidate';
  static const String adopted = 'adopted';
  static const String dismissed = 'dismissed';

  static const List<String> values = [
    candidate,
    adopted,
    dismissed,
  ];

  static String displayName(
    String status,
  ) {
    switch (status) {
      case candidate:
        return '問い候補';

      case adopted:
        return '次の対話へ';

      case dismissed:
        return '見送る';

      default:
        return status;
    }
  }
}
