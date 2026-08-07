class AiResponseStatus {
  const AiResponseStatus._();

  static const String received = 'received';

  static const String deferred = 'deferred';

  static const String organized = 'organized';

  static List<String> get values => [
        received,
        deferred,
        organized,
      ];

  static String displayName(
    String status,
  ) {
    switch (status) {
      case received:
        return '受け取り済み';

      case deferred:
        return 'あとで整理';

      case organized:
        return 'Knowledge化済み';

      default:
        return status;
    }
  }

  static bool isValid(
    String status,
  ) {
    return values.contains(status);
  }
}
