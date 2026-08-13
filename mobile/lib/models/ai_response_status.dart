class AiResponseStatus {
  const AiResponseStatus._();

  static const String waiting = 'waiting';
  
  static const String received = 'received';

  static const String deferred = 'deferred';

  static const String organized = 'organized';

  static List<String> get values => [
        waiting,
        received,
        deferred,
        organized,
      ];

  static String displayName(
    String status,
  ) {
    switch (status) {
      case waiting:
        return '回答待ち';
    
      case received:
        return '受け取り済み';

      case deferred:
        return 'あとで整理';

      case organized:
        return '知識として整理済み';

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
