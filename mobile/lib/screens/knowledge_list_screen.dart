import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import '../repositories/knowledge_asset_repository.dart';
import 'knowledge_detail_screen.dart';

class KnowledgeListScreen extends StatefulWidget {
  const KnowledgeListScreen({super.key});

  @override
  State<KnowledgeListScreen> createState() =>
      _KnowledgeListScreenState();
}

class _KnowledgeListScreenState
    extends State<KnowledgeListScreen> {
  final KnowledgeAssetRepository _repository =
      KnowledgeAssetRepository();

  late Future<List<KnowledgeAsset>> _knowledgeFuture;

  @override
  void initState() {
    super.initState();

    _knowledgeFuture = _repository.findAll();
  }

  Future<void> _reload() async {
    setState(() {
      _knowledgeFuture = _repository.findAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge一覧'),
      ),
      body: FutureBuilder<List<KnowledgeAsset>>(
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
            return const Center(
              child: Text(
                'Knowledgeはまだ保存されていません。',
                textAlign: TextAlign.center,
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
                    title: Text(asset.content),
                    subtitle: Text(
                      asset.createdAt
                          .toLocal()
                          .toString()
                          .substring(0, 16),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => KnowledgeDetailScreen(
                            asset: asset,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
