import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import '../repositories/knowledge_asset_repository.dart';
import 'knowledge_detail_screen.dart';

class KnowledgeListScreen extends StatefulWidget {
  const KnowledgeListScreen({
    super.key,
    this.showArchived = false,
  });

  final bool showArchived;

  @override
  State<KnowledgeListScreen> createState() =>
      _KnowledgeListScreenState();
}

class _KnowledgeListScreenState
    extends State<KnowledgeListScreen> {
  final KnowledgeAssetRepository _repository =
      KnowledgeAssetRepository();

  final TextEditingController _searchController =
      TextEditingController();

  late Future<List<KnowledgeAsset>> _knowledgeFuture;

  String _currentKeyword = '';

  Future<List<KnowledgeAsset>> _loadKnowledge(
    String keyword,
  ) {
    if (widget.showArchived) {
      return keyword.isEmpty
          ? _repository.findArchived()
          : _repository.searchArchived(keyword);
    }

    return keyword.isEmpty
        ? _repository.findAll()
        : _repository.search(keyword);
  }

  @override
  void initState() {
    super.initState();

    _knowledgeFuture = _loadKnowledge('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _knowledgeFuture = _loadKnowledge(
        _currentKeyword,
      );
    });
  }

  void _search() {
    FocusManager.instance.primaryFocus?.unfocus();

    final keyword = _searchController.text.trim();

    setState(() {
      _currentKeyword = keyword;
      _knowledgeFuture =
          _loadKnowledge(keyword);   
    });
  }

  void _clearSearch() {
    FocusManager.instance.primaryFocus?.unfocus();

    _searchController.clear();

    setState(() {
      _currentKeyword = '';
      _knowledgeFuture = _loadKnowledge('');
    });
  }

  Future<void> _openArchivedKnowledge() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            const KnowledgeListScreen(
          showArchived: true,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showArchived
              ? 'アーカイブ済み知識'
              : '知識一覧',
        ),
        actions: widget.showArchived
            ? null
            : [
                IconButton(
                  onPressed:
                      _openArchivedKnowledge,
                  tooltip:
                      'アーカイブ済み知識',
                  icon: const Icon(
                    Icons.archive_outlined,
                  ),
                ),
              ],
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
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _search();
                },
                decoration: InputDecoration(
                  hintText: '知識を検索',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  suffixIcon: _currentKeyword.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clearSearch,
                          tooltip: '検索をクリア',
                          icon: const Icon(
                            Icons.clear,
                          ),
                        ),
                  border: const OutlineInputBorder(),
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
              child: FutureBuilder<List<KnowledgeAsset>>(
                future: _knowledgeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '読み込みに失敗しました。\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    final message =
                        _currentKeyword.isEmpty
                            ? widget.showArchived
                                ? 'アーカイブ済みの知識はありません。'
                                : '知識はまだ保存されていません。'
                            : widget.showArchived
                                ? '「$_currentKeyword」に一致する'
                                    'アーカイブ済み知識はありません。'
                                : '「$_currentKeyword」に一致する'
                                    '知識はありません。';
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final asset = items[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.lightbulb_outline,
                              ),
                            ),
                            title: Text(
                              asset.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              asset.updatedAt
                                  .toLocal()
                                  .toString()
                                  .substring(0, 16),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () async {
                              final wasUpdated =
                                  await Navigator.of(context)
                                      .push<bool>(
                                MaterialPageRoute<bool>(
                                  builder: (context) =>
                                      KnowledgeDetailScreen(
                                    asset: asset,
                                  ),
                                ),
                              );

                              if (wasUpdated == true) {
                                await _reload();
                              }
                            },
                          ),
                        );
                      },
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
