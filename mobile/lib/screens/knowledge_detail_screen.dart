import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/knowledge_asset.dart';
import '../models/knowledge_link.dart';
import '../models/knowledge_link_type.dart';
import '../models/knowledge_type.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/knowledge_link_repository.dart';
import 'knowledge_edit_screen.dart';
import 'knowledge_link_target_select_screen.dart';

class KnowledgeDetailScreen extends StatefulWidget {
  const KnowledgeDetailScreen({
    super.key,
    required this.asset,
  });

  final KnowledgeAsset asset;

  @override
  State<KnowledgeDetailScreen> createState() =>
      _KnowledgeDetailScreenState();
}

class _KnowledgeDetailScreenState
    extends State<KnowledgeDetailScreen> {
  late KnowledgeAsset _asset;

  final TextEditingController _linkReasonController =
      TextEditingController();

  final KnowledgeLinkRepository _linkRepository =
      KnowledgeLinkRepository();

  final KnowledgeAssetRepository _knowledgeRepository =
      KnowledgeAssetRepository();

  late Future<List<KnowledgeLink>>
      _knowledgeLinksFuture;

  final Uuid _uuid = const Uuid();

  KnowledgeAsset? _selectedLinkTarget;
  String? _selectedLinkType;

  bool _wasUpdated = false;
  bool _isSavingLink = false;

  @override
  void initState() {
    super.initState();

    _asset = widget.asset;
    _knowledgeLinksFuture = _loadKnowledgeLinks();
  }

  @override
  void dispose() {
    _linkReasonController.dispose();
    super.dispose();
  }

  Future<List<KnowledgeLink>>
      _loadKnowledgeLinks() {
    return _linkRepository.findByKnowledgeId(
      _asset.knowledgeId,
    );
  }

  String _formatDateTime(DateTime value) {
    final localValue = value.toLocal();

    final year =
        localValue.year.toString().padLeft(4, '0');
    final month =
        localValue.month.toString().padLeft(2, '0');
    final day =
        localValue.day.toString().padLeft(2, '0');
    final hour =
        localValue.hour.toString().padLeft(2, '0');
    final minute =
        localValue.minute.toString().padLeft(2, '0');

    return '$year/$month/$day $hour:$minute';
  }

  Future<void> _openEditScreen() async {
    final updatedAsset =
        await Navigator.of(context).push<KnowledgeAsset>(
      MaterialPageRoute<KnowledgeAsset>(
        builder: (context) => KnowledgeEditScreen(
          asset: _asset,
        ),
      ),
    );

    if (updatedAsset == null || !mounted) {
      return;
    }

    setState(() {
      _asset = updatedAsset;
      _wasUpdated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '知識を更新しました。',
        ),
      ),
    );
  }

  Future<void> _archiveKnowledge() async {
    await _knowledgeRepository.updateArchivedStatus(
      knowledgeId: _asset.knowledgeId,
      isArchived: true,
    );

    final updatedAsset =
        await _knowledgeRepository.findById(
      _asset.knowledgeId,
    );

    if (updatedAsset == null || !mounted) {
      return;
    }

    setState(() {
      _asset = updatedAsset;
      _wasUpdated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '知識をアーカイブしました。',
        ),
      ),
    );
  }

  Future<void> _openLinkTargetSelectScreen() async {
    final selectedAsset =
        await Navigator.of(context).push<KnowledgeAsset>(
      MaterialPageRoute<KnowledgeAsset>(
        builder: (context) =>
            KnowledgeLinkTargetSelectScreen(
          sourceAsset: _asset,
        ),
      ),
    );

    if (selectedAsset == null || !mounted) {
      return;
    }

    final selectedType = await _showLinkTypeDialog();

    if (selectedType == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLinkTarget = selectedAsset;
      _selectedLinkType = selectedType;
      _linkReasonController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '知識と関係の種類を選択しました。',
        ),
      ),
    );
  }

  Future<String?> _showLinkTypeDialog() async {
    String temporaryType =
        _selectedLinkType ??
            KnowledgeLinkType.related;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'どのような関係ですか？',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: RadioGroup<String>(
                  groupValue: temporaryType,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setDialogState(() {
                      temporaryType = value;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        KnowledgeLinkType.values.map(
                      (type) {
                        return RadioListTile<String>(
                          value: type,
                          title: Text(
                            KnowledgeLinkType.displayName(
                              type,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'キャンセル',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      temporaryType,
                    );
                  },
                  child: const Text(
                    '選択する',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeLinkType() async {
    if (_selectedLinkTarget == null) {
      return;
    }

    final selectedType = await _showLinkTypeDialog();

    if (selectedType == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLinkType = selectedType;
    });
  }

  Future<void> _saveKnowledgeLink() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final target = _selectedLinkTarget;
    final linkType = _selectedLinkType;
    final linkReason =
        _linkReasonController.text.trim();

    if (target == null || linkType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '結ぶ知識と関係の種類を選んでください。',
          ),
        ),
      );
      return;
    }

    if (linkReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'この知識を結ぶ理由を入力してください。',
          ),
        ),
      );
      return;
    }

    if (_isSavingLink) {
      return;
    }

    setState(() {
      _isSavingLink = true;
    });

    try {
      final alreadyExists =
          await _linkRepository.existsBetween(
        fromKnowledgeId: _asset.knowledgeId,
        toKnowledgeId: target.knowledgeId,
        linkType: linkType,
      );

      if (!mounted) {
        return;
      }

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '同じ知識と関係のリンクは'
              'すでに保存されています。',
            ),
          ),
        );
        return;
      }

      final now = DateTime.now();

      final link = KnowledgeLink(
        linkId: _uuid.v4(),
        fromKnowledgeId: _asset.knowledgeId,
        toKnowledgeId: target.knowledgeId,
        linkType: linkType,
        linkReason: linkReason,
        createdAt: now,
        updatedAt: now,
      );

      await _linkRepository.insert(link);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLinkTarget = null;
        _selectedLinkType = null;
        _linkReasonController.clear();
        _knowledgeLinksFuture =
            _loadKnowledgeLinks();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '知識を結びました。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '知識の保存に失敗しました。\n$error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingLink = false;
        });
      }
    }
  }

  Future<void> _openConnectedKnowledge(
    KnowledgeAsset connectedKnowledge,
  ) async {
    final wasUpdated =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => KnowledgeDetailScreen(
          asset: connectedKnowledge,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (wasUpdated == true) {
      setState(() {
        _knowledgeLinksFuture =
            _loadKnowledgeLinks();
      });
    }
  }

  void _clearSelectedLinkTarget() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _selectedLinkTarget = null;
      _selectedLinkType = null;
      _linkReasonController.clear();
    });
  }

  void _closeDetailScreen() {
    Navigator.of(context).pop(_wasUpdated);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLinkTarget = _selectedLinkTarget;
    final selectedLinkType = _selectedLinkType;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        _closeDetailScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _closeDetailScreen,
            tooltip: '戻る',
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          title: const Text('知識の詳細'),
          actions: [
            IconButton(
              onPressed: _openEditScreen,
              tooltip: '編集',
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      child: Icon(
                        Icons.lightbulb_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '知識資産',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '内容',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      _asset.content,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _DetailRow(
                  label: 'タイプ',
                  value: KnowledgeType.displayName(
                    _asset.knowledgeType,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: '作成日時',
                  value: _formatDateTime(
                    _asset.createdAt,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: '更新日時',
                  value: _formatDateTime(
                    _asset.updatedAt,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Session ID',
                  value: _asset.sessionId,
                ),
                if (_asset.conversationId != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Conversation ID',
                    value: _asset.conversationId!,
                  ),
                ],
                const SizedBox(height: 32),
                Text(
                  '知識のつながり',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 12),

                FutureBuilder<List<KnowledgeLink>>(
                  future: _knowledgeLinksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text(
                        '知識のつながりの読み込みに'
                        '失敗しました。\n${snapshot.error}',
                      );
                    }

                    final links = snapshot.data ?? [];

                    if (links.isEmpty) {
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.account_tree_outlined,
                            ),
                          ),
                          title: const Text(
                            '結び付きはありません。',
                          ),
                          subtitle: const Text(
                            '知識同士を結ぶと'
                            'ここへ表示されます。',
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: links.map((link) {
                        final isOutgoing =
                            link.fromKnowledgeId ==
                                _asset.knowledgeId;

                        final connectedKnowledgeId =
                            isOutgoing
                                ? link.toKnowledgeId
                                : link.fromKnowledgeId;

                        final directionLabel = isOutgoing
                            ? 'この知識から結ばれています'
                            : 'この知識へ結ばれています';

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: FutureBuilder<KnowledgeAsset?>(
                            future: _knowledgeRepository.findById(
                              connectedKnowledgeId,
                            ),
                            builder: (
                              context,
                              knowledgeSnapshot,
                            ) {
                              if (knowledgeSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child:
                                          CircularProgressIndicator(),
                                    ),
                                  ),
                                );
                              }

                              if (knowledgeSnapshot.hasError) {
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'つながっている知識の読み込みに'
                                      '失敗しました。\n'
                                      '${knowledgeSnapshot.error}',
                                    ),
                                  ),
                                );
                              }

                              final connectedKnowledge =
                                  knowledgeSnapshot.data;

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: connectedKnowledge == null
                                      ? null
                                      : () {
                                          _openConnectedKnowledge(
                                            connectedKnowledge,
                                          );
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.link,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                KnowledgeLinkType.displayName(
                                                  link.linkType,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (connectedKnowledge != null)
                                              const Icon(
                                                Icons.chevron_right,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          directionLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const Divider(height: 28),
                                        const Text(
                                          'つながっている知識',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          connectedKnowledge?.content ??
                                              'つながっている知識が'
                                                  '見つかりません。',
                                        ),
                                        if (connectedKnowledge != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'タイプ：'
                                            '${KnowledgeType.displayName(connectedKnowledge.knowledgeType)}',
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        const Text(
                                          '結んだ理由',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          link.linkReason.isEmpty
                                              ? '（未入力）'
                                              : link.linkReason,
                                        ),
                                        if (connectedKnowledge != null) ...[
                                          const SizedBox(height: 16),
                                          const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                'この知識を開く',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              
                const SizedBox(height: 32),
                Text(
                  '知識を結ぶ',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'この知識と関係する知識を'
                  '選択します。',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.tonalIcon(
                    onPressed: _isSavingLink
                        ? null
                        : _openLinkTargetSelectScreen,
                    icon: const Icon(
                      Icons.hub_outlined,
                    ),
                    label: const Text(
                      '結ぶ知識を選ぶ',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                if (selectedLinkTarget != null &&
                    selectedLinkType != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.link_outlined,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '選択した知識',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              IconButton(
                                onPressed: _isSavingLink
                                    ? null
                                    : _clearSelectedLinkTarget,
                                tooltip: '選択を解除',
                                icon: const Icon(
                                  Icons.close,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selectedLinkTarget.content,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '知識の種類：'
                            '${KnowledgeType.displayName(selectedLinkTarget.knowledgeType)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '更新日時：'
                            '${_formatDateTime(selectedLinkTarget.updatedAt)}',
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '関係：'
                                  '${KnowledgeLinkType.displayName(selectedLinkType)}',
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _isSavingLink
                                    ? null
                                    : _changeLinkType,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                ),
                                label: const Text(
                                  '変更',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '結んだ理由',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'この二つの知識を'
                            'なぜ結び付けたのかを、'
                            '自分の言葉で残します。',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller:
                                _linkReasonController,
                            enabled: !_isSavingLink,
                            minLines: 4,
                            maxLines: 8,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  '例：この知識は、'
                                  '元の考えをさらに発展させた'
                                  '内容だから。',
                              border:
                                  OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _isSavingLink
                                  ? null
                                  : _saveKnowledgeLink,
                              icon: _isSavingLink
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .account_tree_outlined,
                                    ),
                              label: Text(
                                _isSavingLink
                                    ? '保存しています...'
                                    : '知識を結ぶ',
                                style: const TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _openEditScreen,
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    label: const Text(
                      '知識を編集する',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed:
                        _archiveKnowledge,
                    icon: const Icon(
                      Icons.archive_outlined,
                    ),
                    label: const Text(
                      'アーカイブする',
                      style:
                          TextStyle(fontSize: 18),
                    ),
                  ),
                ),              
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(value),
        ),
      ],
    );
  }
}
