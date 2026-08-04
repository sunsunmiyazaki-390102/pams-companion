class KnowledgeType {
  const KnowledgeType._();

  static const String insight = 'insight';
  static const String question = 'question';
  static const String hypothesis = 'hypothesis';
  static const String fact = 'fact';
  static const String criterion = 'criterion';
  static const String principle = 'principle';
  static const String idea = 'idea';
  static const String experience = 'experience';

  static const List<String> values = [
    insight,
    question,
    hypothesis,
    fact,
    criterion,
    principle,
    idea,
    experience,
  ];

  static String displayName(
    String type,
  ) {
    switch (type) {
      case insight:
        return 'Insight';

      case question:
        return '問い';

      case hypothesis:
        return '仮説';

      case fact:
        return '事実';

      case criterion:
        return '判断基準';

      case principle:
        return '行動原則';

      case idea:
        return 'アイデア';

      case experience:
        return '経験知';

      default:
        return type;
    }
  }
}
