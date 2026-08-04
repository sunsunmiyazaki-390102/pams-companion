import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import 'knowledge_edit_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
  }

  String _formatDateTime(DateTime value) {
    final localValue = value.toLocal();

    final year = localValue.year.toString().padLeft(4, '0');
    final month = localValue.month.toString().padLeft(2, '0');
    final day = localValue.day.toString().padLeft(2, '0');
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');

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
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Knowledgeを更新しました。',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge詳細'),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      style:
                          Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '内容',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    _asset.content,
                    style:
                        Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _DetailRow(
                label: '作成日時',
                value: _formatDateTime(_asset.createdAt),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: '更新日時',
                value: _formatDateTime(_asset.updatedAt),
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
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _openEditScreen,
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Knowledgeを編集する',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
