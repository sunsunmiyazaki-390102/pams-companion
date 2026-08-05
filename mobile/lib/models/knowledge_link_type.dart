class KnowledgeLinkType {
  const KnowledgeLinkType._();

  static const String related = 'related';
  static const String supports = 'supports';
  static const String derivedFrom = 'derived_from';
  static const String contradicts = 'contradicts';
  static const String example = 'example';
  static const String develops = 'develops';

  static const List<String> values = [
    related,
    supports,
    derivedFrom,
    contradicts,
    example,
    develops,
  ];

  static String displayName(
    String type,
  ) {
    switch (type) {
      case related:
        return '関連';

      case supports:
        return '支える';

      case derivedFrom:
        return '由来';

      case contradicts:
        return '反対・反証';

      case example:
        return '具体例';

      case develops:
        return '発展';

      default:
        return type;
    }
  }
}
