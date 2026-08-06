import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import '../models/knowledge_link.dart';
import '../models/knowledge_link_type.dart';
import '../models/knowledge_type.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/knowledge_link_repository.dart';

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
                          child: ListTile(
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons.hub_outlined,
                              ),
                            ),
                            title: Text(
                              '保存済みの結び付き：'
                              '${links.length}件',
                            ),
                            subtitle: const Text(
                              'Knowledge同士の関係と'
                              '結んだ理由を表示します。',
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
                                    viewData:
                                        viewData,
                                    formattedDateTime:
                                        _formatDateTime(
                                      viewData
                                          .link
                                          .updatedAt,
                                    ),
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
  });

  final _KnowledgeLinkViewData viewData;
  final String formattedDateTime;

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
