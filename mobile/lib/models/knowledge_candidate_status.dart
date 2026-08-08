class KnowledgeCandidateStatus {
  const KnowledgeCandidateStatus._();

  static const String candidate = 'candidate';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';

  static const List<String> values = [
    candidate,
    accepted,
    rejected,
  ];

  static String displayName(
    String status,
  ) {
    switch (status) {
      case candidate:
        return '候補';

      case accepted:
        return 'Knowledge化';

      case rejected:
        return '見送る';

      default:
        return status;
    }
  }
}
