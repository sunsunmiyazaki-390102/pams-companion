import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/default_theme.dart';
import '../models/project.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/ai_session_repository.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/project_repository.dart';
import 'theme_detail_screen.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({
    super.key,
  });

  @override
  State<ThemeScreen> createState() =>
      _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  final ProjectRepository _projectRepository =
      ProjectRepository();

  final AiSessionRepository _sessionRepository =
      AiSessionRepository();

  final AiConversationRepository _conversationRepository =
      AiConversationRepository();

  final KnowledgeAssetRepository _knowledgeRepository =
      KnowledgeAssetRepository();

  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  bool _isCreatingTheme = false;

  List<_ThemeListItem> _defaultThemes = [];
  List<_ThemeListItem> _customThemes = [];

  @override
  void initState() {
    super.initState();

    _loadThemes();
  }

  Future<void> _loadThemes() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final projects =
          await _projectRepository.findAll();

      final items = <_ThemeListItem>[];

      for (final project in projects) {
        final sessions =
            await _sessionRepository.findByProjectId(
          project.projectId,
        );

        var conversationCount = 0;
        var knowledgeCount = 0;

        for (final session in sessions) {
          final conversations =
              await _conversationRepository.findBySessionId(
            session.sessionId,
          );

          final knowledgeAssets =
              await _knowledgeRepository.findBySessionId(
            session.sessionId,
          );

          conversationCount += conversations.length;
          knowledgeCount += knowledgeAssets.length;
        }

        items.add(
          _ThemeListItem(
            project: project,
            conversationCount: conversationCount,
            knowledgeCount: knowledgeCount,
          ),
        );
      }

      final defaultThemes =
          <_ThemeListItem>[];

      final customThemes =
          <_ThemeListItem>[];

      for (final item in items) {
        if (DefaultTheme.isDefaultTheme(
          item.project.projectId,
        )) {
          defaultThemes.add(item);
        } else {
          customThemes.add(item);
        }
      }

      defaultThemes.sort(
        (a, b) {
          final aIndex =
              DefaultTheme.ids.indexOf(
            a.project.projectId,
          );

          final bIndex =
              DefaultTheme.ids.indexOf(
            b.project.projectId,
          );

          return aIndex.compareTo(bIndex);
        },
      );

      customThemes.sort(
        (a, b) => a.project.name.compareTo(
          b.project.name,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _defaultThemes = defaultThemes;
        _customThemes = customThemes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'テーマを読み込めませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void> _openTheme(
    Project theme,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            ThemeDetailScreen(
          theme: theme,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadThemes();
  }

  Future<void> _createTheme() async {
    if (_isCreatingTheme) {
      return;
    }

    final nameController =
        TextEditingController();

    final descriptionController =
        TextEditingController();

    final result =
        await showDialog<_NewThemeInput>(
      context: context,
      builder: (dialogContext) {
        String? nameError;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'あたらしいテーマ',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    const Text(
                      '自分だけのテーマを'
                      '作ることができます。',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextField(
                      controller:
                          nameController,
                      autofocus: true,
                      decoration:
                          InputDecoration(
                        labelText: 'テーマ名',
                        hintText:
                            '例：俳句、地域活動',
                        border:
                            const OutlineInputBorder(),
                        errorText:
                            nameError,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextField(
                      controller:
                          descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(
                        labelText:
                            '説明（任意）',
                        hintText:
                            'このテーマで'
                            'どんなことを'
                            '整理したいか'
                            '書いておけます。',
                        border:
                            OutlineInputBorder(),
                        alignLabelWithHint:
                            true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'キャンセル',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final name =
                        nameController.text
                            .trim();

                    if (name.isEmpty) {
                      setDialogState(() {
                        nameError =
                            'テーマ名を'
                            '入力してください。';
                      });

                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(
                      _NewThemeInput(
                        name: name,
                        description:
                            descriptionController
                                .text
                                .trim(),
                      ),
                    );
                  },
                  child: const Text(
                    '作成',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null ||
        !mounted) {
      return;
    }

    setState(() {
      _isCreatingTheme = true;
    });

    try {
      final now = DateTime.now();

      final project = Project(
        projectId: _uuid.v4(),
        name: result.name,
        description:
            result.description,
        createdAt: now,
        updatedAt: now,
      );

      await _projectRepository.insert(
        project,
      );

      await _loadThemes();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '「${result.name}」を'
            '作成しました。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'テーマを作成'
            'できませんでした。\n'
            '$error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTheme = false;
        });
      }
    }
  }

  _ThemeListItem? get _unclassifiedTheme {
    for (final item in _defaultThemes) {
      if (item.project.projectId ==
          DefaultTheme.unclassifiedId) {
        return item;
      }
    }

    return null;
  }

  List<_ThemeListItem>
      get _standardThemes {
    return _defaultThemes
        .where(
          (item) =>
              item.project.projectId !=
              DefaultTheme.unclassifiedId,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final unclassified =
        _unclassifiedTheme;

    final standardThemes =
        _standardThemes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'テーマ',
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _loadThemes,
                child: ListView(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          child: Icon(
                            Icons
                                .folder_outlined,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'テーマ',
                            style:
                                TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      '自分の関心や知を、'
                      '自分なりのまとまりで'
                      '整理します。',
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    if (unclassified !=
                        null) ...[
                      _ThemeCard(
                        item:
                            unclassified,
                        icon: Icons
                            .inbox_outlined,
                        emphasize: true,
                        onPressed: () {
                          _openTheme(
                            unclassified
                                .project,
                          );
                        },
                      ),

                      const SizedBox(
                        height: 24,
                      ),
                    ],

                    if (standardThemes
                        .isNotEmpty) ...[
                      const Text(
                        'PAMSのテーマ',
                        style:
                            TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      ...standardThemes.map(
                        (item) => Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          child:
                              _ThemeCard(
                            item: item,
                            icon:
                                _themeIcon(
                              item.project
                                  .projectId,
                            ),
                            onPressed: () {
                              _openTheme(
                                item.project,
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    if (_customThemes
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 16,
                      ),

                      const Text(
                        'あなたのテーマ',
                        style:
                            TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      ..._customThemes.map(
                        (item) => Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          child:
                              _ThemeCard(
                            item: item,
                            icon: Icons
                                .folder_outlined,
                            onPressed: () {
                              _openTheme(
                                item.project,
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 20,
                    ),

                    OutlinedButton.icon(
                      onPressed:
                          _isCreatingTheme
                              ? null
                              : _createTheme,
                      icon: _isCreatingTheme
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.add,
                            ),
                      label: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                        child: Text(
                          _isCreatingTheme
                              ? '作成しています...'
                              : 'あたらしいテーマ',
                          style:
                              const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      '自分だけのテーマを'
                      '作ることができます。',
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 24,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  IconData _themeIcon(
    String projectId,
  ) {
    switch (projectId) {
      case DefaultTheme.lifeId:
        return Icons.home_outlined;

      case DefaultTheme.healthId:
        return Icons.favorite_border;

      case DefaultTheme.familyId:
        return Icons.people_outline;

      case DefaultTheme.learningId:
        return Icons.school_outlined;

      case DefaultTheme.workId:
        return Icons.work_outline;

      case DefaultTheme.futureId:
        return Icons.lightbulb_outline;

      default:
        return Icons.folder_outlined;
    }
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.item,
    required this.icon,
    required this.onPressed,
    this.emphasize = false,
  });

  final _ThemeListItem item;
  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation:
          emphasize ? 2 : null,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              EdgeInsets.all(
            emphasize ? 20 : 16,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Icon(
                  icon,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.project
                                .name,
                            style:
                                TextStyle(
                              fontSize:
                                  emphasize
                                      ? 19
                                      : 17,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),

                        Text(
                          '${item.totalCount}件',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),

                    if (item.project
                        .description
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        item.project
                            .description,
                      ),
                    ],

                    if (item.totalCount >
                        0) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'AIとの対話 '
                        '${item.conversationCount}件'
                        '　'
                        '育てた知 '
                        '${item.knowledgeCount}件',
                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .bodySmall,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              const Padding(
                padding:
                    EdgeInsets.only(
                  top: 2,
                ),
                child: Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeListItem {
  const _ThemeListItem({
    required this.project,
    required this.conversationCount,
    required this.knowledgeCount,
  });

  final Project project;
  final int conversationCount;
  final int knowledgeCount;

  int get totalCount =>
      conversationCount +
      knowledgeCount;
}

class _NewThemeInput {
  const _NewThemeInput({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}
