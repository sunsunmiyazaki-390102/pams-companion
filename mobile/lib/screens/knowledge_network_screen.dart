import 'package:flutter/material.dart';

import '../models/knowledge_link.dart';
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
  final KnowledgeLinkRepository _repository =
      KnowledgeLinkRepository();

  late Future<List<KnowledgeLink>> _linksFuture;

  @override
  void initState() {
    super.initState();

    _linksFuture = _repository.findAll();
  }

  Future<void> _reload() async {
    setState(() {
      _linksFuture = _repository.findAll();
    });

    await _linksFuture;
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
              child: FutureBuilder<List<KnowledgeLink>>(
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
                              '結び付きの詳細一覧は'
                              '次のStepで表示します。',
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
