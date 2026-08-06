import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import '../models/knowledge_link.dart';
import '../models/knowledge_link_type.dart';
import '../models/knowledge_type.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/knowledge_link_repository.dart';
import 'knowledge_detail_screen.dart';
import 'knowledge_link_edit_screen.dart';

class KnowledgeNetworkScreen extends StatefulWidget {
  const KnowledgeNetworkScreen({
    super.key,
  });

  @override
  State<KnowledgeNetworkScreen> createState() =>
      _KnowledgeNetworkScreenState();
}

class _KnowledgeNetworkScreenState
    extends State<KnowledgeNetworkScreen> {
  final KnowledgeLinkRepository _linkRepository =
      KnowledgeLinkRepository();

  final KnowledgeAssetRepository _knowledgeRepository =
      KnowledgeAssetRepository();

  late Future<List<KnowledgeLink>> _linksFuture;

  @override
  void initState() {
    super.initState();

    _linksFuture = _linkRepository.findAll();
  }

  Future<void> _reload() async {
    setState(() {
      _linksFuture = _linkRepository.findAll();
    });

    await _linksFuture;
  }

  Future<_KnowledgeLinkViewData> _loadLinkViewData(
    KnowledgeLink link,
  ) async {
    final knowledgeAssets =
        await Future.wait<KnowledgeAsset?>([
      _knowledgeRepository.findById(
        link.fromKnowledgeId,
      ),
      _knowledgeRepository.findById(
        link.toKnowledgeId,
      ),
    ]);

    return _KnowledgeLinkViewData(
      link: link,
      fromKnowledge: knowledgeAssets[0],
      toKnowledge: knowledgeAssets[1],
    );
  }

  Future<void> _openKnowledge(
    KnowledgeAsset knowledge,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => KnowledgeDetailScreen(
          asset: knowledge,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _reload();
  }

  Future<void> _openLinkEditScreen(
    KnowledgeLink link,
  ) async {
    final updatedLink =
        await Navigator.of(context).push<KnowledgeLink>(
      MaterialPageRoute<KnowledgeLink>(
        builder: (context) =>
            KnowledgeLinkEditScreen(
          link: link,
        ),
      ),
    );

    if (updatedLink == null || !mounted) {
      return;
    }

    try {
      await _linkRepository.update(
        updatedLink,
      );

      if (!mounted) {
        return;
      }

      await _reload();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Knowledgeの関係を更新しました。\n'
            '関係：'
            '${KnowledgeLinkType.displayName(updatedLink.linkType)}',
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
            'Knowledgeの関係を'
            '更新できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Map<String, int> _countLinksByType(
    List<KnowledgeLink> links,
  ) {
    final counts = <String, int>{
      for (final type in KnowledgeLinkType.values)
        type: 0,
    };

    for (final link in links) {
      counts.update(
        link.linkType,
        (currentCount) => currentCount + 1,
        ifAbsent: () => 1,
      );
    }

    return counts;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Knowledge Network',
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                12,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Icon(
                          Icons.account_tree_outlined,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '知識のつながり',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    '保存されているKnowledge同士の'
                    '結び付きを一覧で確認します。',
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  FutureBuilder<List<KnowledgeLink>>(
                future: _linksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(24),
                        child: Text(
                          'Knowledge Networkの'
                          '読み込みに失敗しました。\n'
                          '${snapshot.error}',
                          textAlign:
                              TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final links =
                      snapshot.data ?? [];

                  final linkTypeCounts =
                      _countLinksByType(links);

                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        24,
                        12,
                        24,
                        24,
                      ),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    CircleAvatar(
                                      child: Icon(
                                        Icons.insights_outlined,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Network統計',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _NetworkStatisticRow(
                                  label: 'すべての結び付き',
                                  count: links.length,
                                ),
                                const Divider(height: 24),
                                ...KnowledgeLinkType.values.map(
                                  (type) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10,
                                    ),
                                    child: _NetworkStatisticRow(
                                      label:
                                          KnowledgeLinkType.displayName(
                                        type,
                                      ),
                                      count:
                                          linkTypeCounts[type] ?? 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (links.isEmpty) ...[
                          const SizedBox(height: 16),
                          const Card(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(24),
                              child: Text(
                                'Knowledge同士を結ぶと、'
                                'ここへNetworkが'
                                '表示されます。',
                                textAlign:
                                    TextAlign.center,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          ...links.map(
                            (link) => Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: FutureBuilder<
                                  _KnowledgeLinkViewData>(
                                future:
                                    _loadLinkViewData(
                                  link,
                                ),
                                builder: (
                                  context,
                                  linkSnapshot,
                                ) {
                                  if (linkSnapshot
                                          .connectionState ==
                                      ConnectionState
                                          .waiting) {
                                    return const Card(
                                      child: Padding(
                                        padding:
                                            EdgeInsets
                                                .all(
                                          24,
                                        ),
                                        child: Center(
                                          child:
                                              CircularProgressIndicator(),
                                        ),
                                      ),
                                    );
                                  }

                                  if (linkSnapshot
                                      .hasError) {
                                    return Card(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets
                                                .all(
                                          16,
                                        ),
                                        child: Text(
                                          '結び付きの読み込みに'
                                          '失敗しました。\n'
                                          '${linkSnapshot.error}',
                                        ),
                                      ),
                                    );
                                  }

                                  final viewData =
                                      linkSnapshot.data;

                                  if (viewData ==
                                      null) {
                                    return const Card(
                                      child: Padding(
                                        padding:
                                            EdgeInsets
                                                .all(
                                          16,
                                        ),
                                        child: Text(
                                          '結び付きの情報が'
                                          '見つかりません。',
                                        ),
                                      ),
                                    );
                                  }
                           
                                  return _KnowledgeNetworkCard(
                                    viewData: viewData,
                                    formattedDateTime: _formatDateTime(
                                      viewData.link.updatedAt,
                                    ),
                                    onOpenFrom:
                                        viewData.fromKnowledge == null
                                            ? null
                                            : () async {
                                                await _openKnowledge(
                                                  viewData.fromKnowledge!,
                                                );
                                              },
                                    onOpenTo:
                                        viewData.toKnowledge == null
                                            ? null
                                            : () async {
                                                await _openKnowledge(
                                                  viewData.toKnowledge!,
                                                );
                                              },
                                    onEdit: () async {
                                      await _openLinkEditScreen(
                                        viewData.link,
                                      );
                                    },
                                  );                           
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeLinkViewData {
  const _KnowledgeLinkViewData({
    required this.link,
    required this.fromKnowledge,
    required this.toKnowledge,
  });

  final KnowledgeLink link;
  final KnowledgeAsset? fromKnowledge;
  final KnowledgeAsset? toKnowledge;
}

class _KnowledgeNetworkCard
    extends StatelessWidget {
  const _KnowledgeNetworkCard({
    required this.viewData,
    required this.formattedDateTime,
    required this.onOpenFrom,
    required this.onOpenTo,
    required this.onEdit,
  });

  final _KnowledgeLinkViewData viewData;
  final String formattedDateTime;
  final VoidCallback? onOpenFrom;
  final VoidCallback? onOpenTo;
  final VoidCallback onEdit; 
 
  @override
  Widget build(BuildContext context) {
    final link = viewData.link;
    final fromKnowledge =
        viewData.fromKnowledge;
    final toKnowledge =
        viewData.toKnowledge;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.link,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    KnowledgeLinkType.displayName(
                      link.linkType,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '接続元Knowledge',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fromKnowledge?.content ??
                  '接続元Knowledgeが'
                      '見つかりません。',
            ),
            if (fromKnowledge != null) ...[
              const SizedBox(height: 8),
              Text(
                'タイプ：'
                '${KnowledgeType.displayName(fromKnowledge.knowledgeType)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Divider(),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Column(
                    children: [
                      Text(
                        KnowledgeLinkType
                            .displayName(
                          link.linkType,
                        ),
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_downward,
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Divider(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '接続先Knowledge',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              toKnowledge?.content ??
                  '接続先Knowledgeが'
                      '見つかりません。',
            ),
            if (toKnowledge != null) ...[
              const SizedBox(height: 8),
              Text(
                'タイプ：'
                '${KnowledgeType.displayName(toKnowledge.knowledgeType)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
            const Divider(height: 32),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenFrom,
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: const Text(
                      '接続元を開く',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenTo,
                    icon: const Icon(
                      Icons.open_in_new,
                    ),
                    label: const Text(
                      '接続先を開く',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  '関係を編集する',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '更新日時：$formattedDateTime',          
              textAlign: TextAlign.right,
              style:
                  Theme.of(context)
                      .textTheme
                      .bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkStatisticRow
    extends StatelessWidget {
  const _NetworkStatisticRow({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
          ),
        ),
        Text(
          '$count件',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
