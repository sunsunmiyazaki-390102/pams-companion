import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import '../models/knowledge_type.dart';
import '../repositories/knowledge_asset_repository.dart';

class KnowledgeLinkTargetSelectScreen
    extends StatefulWidget {
  const KnowledgeLinkTargetSelectScreen({
    super.key,
    required this.sourceAsset,
  });

  final KnowledgeAsset sourceAsset;

  @override
  State<KnowledgeLinkTargetSelectScreen> createState() =>
      _KnowledgeLinkTargetSelectScreenState();
}

class _KnowledgeLinkTargetSelectScreenState
    extends State<KnowledgeLinkTargetSelectScreen> {
  final KnowledgeAssetRepository _repository =
      KnowledgeAssetRepository();

  final TextEditingController _searchController =
      TextEditingController();

  late Future<List<KnowledgeAsset>> _knowledgeFuture;

  String _currentKeyword = '';

  @override
  void initState() {
    super.initState();
    _knowledgeFuture = _loadCandidates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<KnowledgeAsset>> _loadCandidates() async {
    final items = _currentKeyword.isEmpty
        ? await _repository.findAll()
        : await _repository.search(_currentKeyword);

    return items.where((asset) {
      return asset.knowledgeId !=
          widget.sourceAsset.knowledgeId;
    }).toList();
  }

  void _search() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _currentKeyword =
          _searchController.text.trim();
      _knowledgeFuture = _loadCandidates();
    });
  }

  void _clearSearch() {
    FocusManager.instance.primaryFocus?.unfocus();

    _searchController.clear();

    setState(() {
      _currentKeyword = '';
      _knowledgeFuture = _loadCandidates();
    });
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
          '結ぶKnowledgeを選ぶ',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                8,
              ),
              child: TextField(
                controller: _searchController,
                textInputAction:
                    TextInputAction.search,
                onSubmitted: (_) {
                  _search();
                },
                decoration: InputDecoration(
                  hintText: 'Knowledgeを検索',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                      _currentKeyword.isEmpty
                          ? null
                          : IconButton(
                              onPressed:
                                  _clearSearch,
                              tooltip:
                                  '検索をクリア',
                              icon: const Icon(
                                Icons.clear,
                              ),
                            ),
                  border:
                      const OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                12,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _search,
                  icon: const Icon(
                    Icons.search,
                  ),
                  label: const Text(
                    '検索する',
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  FutureBuilder<List<KnowledgeAsset>>(
                future: _knowledgeFuture,
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
                      child: Text(
                        '読み込みに失敗しました。\n'
                        '${snapshot.error}',
                        textAlign:
                            TextAlign.center,
                      ),
                    );
                  }

                  final items =
                      snapshot.data ?? [];

                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding:
                            EdgeInsets.all(24),
                        child: Text(
                          '結び付けられるKnowledgeが'
                          'ありません。',
                          textAlign:
                              TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(
                      height: 12,
                    ),
                    itemBuilder:
                        (context, index) {
                      final asset = items[index];

                      return Card(
                        child: ListTile(
                          leading:
                              const CircleAvatar(
                            child: Icon(
                              Icons
                                  .hub_outlined,
                            ),
                          ),
                          title: Text(
                            asset.content,
                            maxLines: 3,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                          subtitle: Text(
                            '${KnowledgeType.displayName(asset.knowledgeType)}'
                            ' ・ '
                            '${_formatDateTime(asset.updatedAt)}',
                          ),
                          trailing:
                              const Icon(
                            Icons
                                .chevron_right,
                          ),
                          onTap: () {
                            Navigator.of(context)
                                .pop(asset);
                          },
                        ),
                      );
                    },
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
