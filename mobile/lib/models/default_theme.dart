class DefaultTheme {
  const DefaultTheme._();

  static const String unclassifiedId =
      'pams-theme-unclassified';

  static const String lifeId =
      'pams-theme-life';

  static const String healthId =
      'pams-theme-health';

  static const String familyId =
      'pams-theme-family';

  static const String learningId =
      'pams-theme-learning';

  static const String workId =
      'pams-theme-work';

  static const String futureId =
      'pams-theme-future';

  static const List<String> ids = [
    unclassifiedId,
    lifeId,
    healthId,
    familyId,
    learningId,
    workId,
    futureId,
  ];

  static const Map<String, String> names = {
    unclassifiedId: '未分類',
    lifeId: '暮らし',
    healthId: '健康',
    familyId: '家族',
    learningId: '学び',
    workId: '仕事',
    futureId: 'これから考えたいこと',
  };

  static const Map<String, String> descriptions = {
    unclassifiedId:
        '迷ったときは、まずここで大丈夫です。'
        'あとからテーマを変更できます。',
    lifeId:
        '日々の暮らしや生活について考えます。',
    healthId:
        'からだや心、健康について考えます。',
    familyId:
        '家族や身近な人とのことを考えます。',
    learningId:
        '学びたいことや知りたいことを育てます。',
    workId:
        '仕事や活動について考えます。',
    futureId:
        'これから考えていきたいことを残します。',
  };

  static bool isDefaultTheme(
    String projectId,
  ) {
    return ids.contains(projectId);
  }

  static String nameOf(
    String projectId,
  ) {
    return names[projectId] ?? '';
  }

  static String descriptionOf(
    String projectId,
  ) {
    return descriptions[projectId] ?? '';
  }
}
