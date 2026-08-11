import 'package:flutter/material.dart';

import '../models/ai_conversation.dart';
import '../models/default_theme.dart';
import '../models/knowledge_asset.dart';
import '../models/knowledge_type.dart';
import '../models/project.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/ai_session_repository.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/project_repository.dart';
import 'ai_conversation_detail_screen.dart';
import 'knowledge_detail_screen.dart';

class ThemeDetailScreen extends StatefulWidget {
  const ThemeDetailScreen({
    super.key,
    required this.theme,
  });

  final Project theme;

  @override
  State<ThemeDetailScreen> createState() =>
      _ThemeDetailScreenState();
}

class _ThemeDetailScreenState
    extends State<ThemeDetailScreen> {
  final AiSessionRepository
      _sessionRepository =
      AiSessionRepository();

  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  final KnowledgeAssetRepository
      _knowledgeRepository =
      KnowledgeAssetRepository();

  final ProjectRepository
      _projectRepository =
      ProjectRepository();

  List<AiConversation> _conversations = [];
  List<KnowledgeAsset> _knowledgeAssets = [];

  bool _isLoading = true;
  bool _isChangingTheme = false;

  String? _expandedItemKey;

  @override
  void initState() {
    super.initState();

    _loadThemeItems();
  }

  Future<void> _loadThemeItems() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sessions =
          await _sessionRepository
              .findByProjectId(
        widget.theme.projectId,
      );

      final conversations =
          <AiConversation>[];

      final knowledgeAssets =
          <KnowledgeAsset>[];

      for (final session in sessions) {
        final sessionConversations =
            await _conversationRepository
                .findBySessionId(
          session.sessionId,
        );

        final sessionKnowledge =
            await _knowledgeRepository
                .findBySessionId(
          session.sessionId,
        );

        conversations.addAll(
          sessionConversations,
        );

        knowledgeAssets.addAll(
          sessionKnowledge,
        );
      }

      conversations.sort(
        (a, b) => b.createdAt.compareTo(
          a.createdAt,
        ),
      );

      knowledgeAssets.sort(
        (a, b) => b.createdAt.compareTo(
          a.createdAt,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = conversations;
        _knowledgeAssets =
            knowledgeAssets;
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
            'テーマの内容を'
            '読み込めませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  String _formatDate(
    DateTime dateTime,
  ) {
    final localDateTime =
        dateTime.toLocal();

    final year =
        localDateTime.year.toString();

    final month =
        localDateTime.month
            .toString()
            .padLeft(2, '0');

    final day =
        localDateTime.day
            .toString()
            .padLeft(2, '0');

    return '$year/$month/$day';
  }

  void _toggleExpanded(
    String itemKey,
  ) {
    setState(() {
      if (_expandedItemKey ==
          itemKey) {
        _expandedItemKey = null;
      } else {
        _expandedItemKey =
            itemKey;
      }
    });
  }

  Future<Project?>
      _selectTheme() async {
    final projects =
        await _projectRepository.findAll();

    if (!mounted) {
      return null;
    }

    final sortedProjects =
        [...projects];

    sortedProjects.sort(
      (a, b) {
        final aDefaultIndex =
            DefaultTheme.ids.indexOf(
          a.projectId,
        );

        final bDefaultIndex =
            DefaultTheme.ids.indexOf(
          b.projectId,
        );

        final aIsDefault =
            aDefaultIndex >= 0;

        final bIsDefault =
            bDefaultIndex >= 0;

        if (aIsDefault &&
            bIsDefault) {
          return aDefaultIndex.compareTo(
            bDefaultIndex,
          );
        }

        if (aIsDefault) {
          return -1;
        }

        if (bIsDefault) {
          return 1;
        }

        return a.name.compareTo(
          b.name,
        );
      },
    );

    return showDialog<Project>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text(
            'テーマを変更',
          ),
          children: [
            const Padding(
              padding:
                  EdgeInsets.fromLTRB(
                24,
                0,
                24,
                12,
              ),
              child: Text(
                '変更すると、この対話と'
                '同じまとまりから育った知も'
                '同じテーマになります。',
              ),
            ),
            const Divider(),
            for (final project
                in sortedProjects)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(
                    project,
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (project.projectId ==
                          widget.theme
                              .projectId)
                        const Icon(
                          Icons.check,
                        ),
                    ],
                  ),
                ),
              ),
            const Divider(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Text(
                  'キャンセル',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeTheme({
    required String sessionId,
  }) async {
    if (_isChangingTheme) {
      return;
    }

    final selectedTheme =
        await _selectTheme();

    if (selectedTheme == null ||
        !mounted) {
      return;
    }

    if (selectedTheme.projectId ==
        widget.theme.projectId) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '現在のテーマは'
            '「${widget.theme.name}」です。',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isChangingTheme = true;
    });

    try {
      await _sessionRepository
          .updateProjectId(
        sessionId: sessionId,
        projectId:
            selectedTheme.projectId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _expandedItemKey = null;
      });

      await _loadThemeItems();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '「${selectedTheme.name}」へ'
            '変更しました。',
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
            'テーマを変更'
            'できませんでした。\n'
            '$error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingTheme = false;
        });
      }
    }
  }

  Future<void> _openConversation(
    AiConversation conversation,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            AiConversationDetailScreen(
          conversation: conversation,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadThemeItems();
  }

  Future<void> _openKnowledge(
    KnowledgeAsset asset,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            KnowledgeDetailScreen(
          asset: asset,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadThemeItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'テーマ詳細',
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh:
                    _loadThemeItems,
                child: ListView(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Icon(
                            _themeIcon(
                              widget.theme
                                  .projectId,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            widget.theme.name,
                            style:
                                const TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (widget
                        .theme
                        .description
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        widget.theme
                            .description,
                      ),
                    ],

                    const SizedBox(
                      height: 24,
                    ),

                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child:
                                  _CountItem(
                                label:
                                    'AIとの対話',
                                count:
                                    _conversations
                                        .length,
                              ),
                            ),
                            const SizedBox(
                              height: 42,
                              child:
                                  VerticalDivider(),
                            ),
                            Expanded(
                              child:
                                  _CountItem(
                                label:
                                    '育てた知',
                                count:
                                    _knowledgeAssets
                                        .length,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    _SectionHeader(
                      icon: Icons
                          .chat_bubble_outline,
                      title: 'AIとの対話',
                      count:
                          _conversations.length,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (_conversations.isEmpty)
                      const _EmptyCard(
                        text:
                            'このテーマに'
                            'AIとの対話は'
                            'まだありません。',
                      )
                    else
                      ..._conversations.map(
                        (conversation) {
                          final itemKey =
                              'conversation:'
                              '${conversation.conversationId}';

                          final isExpanded =
                              _expandedItemKey ==
                                  itemKey;

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child:
                                _ConversationCard(
                              conversation:
                                  conversation,
                              themeName:
                                  widget.theme
                                      .name,
                              isExpanded:
                                  isExpanded,
                              isChangingTheme:
                                  _isChangingTheme,
                              formattedDate:
                                  _formatDate(
                                conversation
                                    .createdAt,
                              ),
                              onToggle: () {
                                _toggleExpanded(
                                  itemKey,
                                );
                              },
                              onChangeTheme:
                                  () {
                                _changeTheme(
                                  sessionId:
                                      conversation
                                          .sessionId,
                                );
                              },
                              onOpenDetail:
                                  () {
                                _openConversation(
                                  conversation,
                                );
                              },
                            ),
                          );
                        },
                      ),

                    const SizedBox(
                      height: 24,
                    ),

                    _SectionHeader(
                      icon:
                          Icons.lightbulb_outline,
                      title: '育てた知',
                      count:
                          _knowledgeAssets.length,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (_knowledgeAssets
                        .isEmpty)
                      const _EmptyCard(
                        text:
                            'このテーマに'
                            '育てた知は'
                            'まだありません。',
                      )
                    else
                      ..._knowledgeAssets.map(
                        (asset) {
                          final itemKey =
                              'knowledge:'
                              '${asset.knowledgeId}';

                          final isExpanded =
                              _expandedItemKey ==
                                  itemKey;

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 12,
                            ),
                            child:
                                _KnowledgeCard(
                              asset: asset,
                              themeName:
                                  widget.theme
                                      .name,
                              isExpanded:
                                  isExpanded,
                              isChangingTheme:
                                  _isChangingTheme,
                              formattedDate:
                                  _formatDate(
                                asset.createdAt,
                              ),
                              onToggle: () {
                                _toggleExpanded(
                                  itemKey,
                                );
                              },
                              onChangeTheme:
                                  () {
                                _changeTheme(
                                  sessionId:
                                      asset.sessionId,
                                );
                              },
                              onOpenDetail:
                                  () {
                                _openKnowledge(
                                  asset,
                                );
                              },
                            ),
                          );
                        },
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
      case DefaultTheme.unclassifiedId:
        return Icons.inbox_outlined;

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

class _CountItem extends StatelessWidget {
  const _CountItem({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count件',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '$count件',
        ),
      ],
    );
  }
}

class _ConversationCard
    extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.themeName,
    required this.isExpanded,
    required this.isChangingTheme,
    required this.formattedDate,
    required this.onToggle,
    required this.onChangeTheme,
    required this.onOpenDetail,
  });

  final AiConversation conversation;
  final String themeName;
  final bool isExpanded;
  final bool isChangingTheme;
  final String formattedDate;
  final VoidCallback onToggle;
  final VoidCallback onChangeTheme;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    isExpanded
                        ? Icons
                            .expand_more
                        : Icons
                            .chevron_right,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conversation
                          .userMessage,
                      maxLines:
                          isExpanded
                              ? null
                              : 2,
                      overflow:
                          isExpanded
                              ? null
                              : TextOverflow
                                  .ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(height: 1),

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  const Text(
                    'あなたの質問',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    conversation
                        .userMessage,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'AIからの回答',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    conversation
                        .aiResponse,
                    maxLines: 8,
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),

                  if (conversation
                      .summary
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      '要約',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      conversation
                          .summary,
                    ),
                  ],

                  const SizedBox(height: 20),

                  Text(
                    '日付：$formattedDate',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '現在のテーマ：'
                    '$themeName',
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed:
                        isChangingTheme
                            ? null
                            : onChangeTheme,
                    icon: const Icon(
                      Icons
                          .drive_file_move_outline,
                    ),
                    label: const Text(
                      'テーマを変更',
                    ),
                  ),

                  const SizedBox(height: 8),

                  FilledButton.icon(
                    onPressed:
                        onOpenDetail,
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: const Text(
                      'AI相談詳細を開く',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KnowledgeCard
    extends StatelessWidget {
  const _KnowledgeCard({
    required this.asset,
    required this.themeName,
    required this.isExpanded,
    required this.isChangingTheme,
    required this.formattedDate,
    required this.onToggle,
    required this.onChangeTheme,
    required this.onOpenDetail,
  });

  final KnowledgeAsset asset;
  final String themeName;
  final bool isExpanded;
  final bool isChangingTheme;
  final String formattedDate;
  final VoidCallback onToggle;
  final VoidCallback onChangeTheme;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    isExpanded
                        ? Icons
                            .expand_more
                        : Icons
                            .chevron_right,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asset.content,
                      maxLines:
                          isExpanded
                              ? null
                              : 2,
                      overflow:
                          isExpanded
                              ? null
                              : TextOverflow
                                  .ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(height: 1),

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  const Text(
                    '育てた知',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    asset.content,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'タイプ：'
                    '${KnowledgeType.displayName(
                      asset.knowledgeType,
                    )}',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '日付：$formattedDate',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '現在のテーマ：'
                    '$themeName',
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed:
                        isChangingTheme
                            ? null
                            : onChangeTheme,
                    icon: const Icon(
                      Icons
                          .drive_file_move_outline,
                    ),
                    label: const Text(
                      'テーマを変更',
                    ),
                  ),

                  const SizedBox(height: 8),

                  FilledButton.icon(
                    onPressed:
                        onOpenDetail,
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: const Text(
                      'Knowledge詳細を開く',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Text(
          text,
        ),
      ),
    );
  }
}
