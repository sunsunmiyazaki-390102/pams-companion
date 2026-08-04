import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';

class KnowledgeDetailScreen extends StatelessWidget {
  const KnowledgeDetailScreen({
    super.key,
    required this.asset,
  });

  final KnowledgeAsset asset;

  String _formatDateTime(DateTime value) {
    final localValue = value.toLocal();

    final year = localValue.year.toString().padLeft(4, '0');
    final month = localValue.month.toString().padLeft(2, '0');
    final day = localValue.day.toString().padLeft(2, '0');
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');

    return '$year/$month/$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge詳細'),
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
                    asset.content,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _DetailRow(
                label: '作成日時',
                value: _formatDateTime(asset.createdAt),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: '更新日時',
                value: _formatDateTime(asset.updatedAt),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Session ID',
                value: asset.sessionId,
              ),
              if (asset.conversationId != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Conversation ID',
                  value: asset.conversationId!,
                ),
              ],
              const SizedBox(height: 32),
              const Text(
                '編集と削除は次のStepで追加します。',
                textAlign: TextAlign.center,
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
