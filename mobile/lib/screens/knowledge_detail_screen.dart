import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import '../models/knowledge_type.dart';
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

  KnowledgeAsset? _selectedLinkTarget;

  bool _wasUpdated = false;

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
      _wasUpdated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Knowledgeを更新しました。',
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

    setState(() {
      _selectedLinkTarget = selectedAsset;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '結ぶKnowledgeを選択しました。',
        ),
      ),
    );
  }

  void _clearSelectedLinkTarget() {
    setState(() {
      _selectedLinkTarget = null;
    });
  }

  void _closeDetailScreen() {
    Navigator.of(context).pop(_wasUpdated);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLinkTarget = _selectedLinkTarget;

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
                  style:
                      Theme.of(context).textTheme.titleMedium,
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
                  'Knowledgeを結ぶ',
                  style:
                      Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'このKnowledgeと関係するKnowledgeを'
                  '選択します。',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        _openLinkTargetSelectScreen,
                    icon: const Icon(
                      Icons.hub_outlined,
                    ),
                    label: const Text(
                      '結ぶKnowledgeを選ぶ',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                if (selectedLinkTarget != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),
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
                                  '選択したKnowledge',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    _clearSelectedLinkTarget,
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
                            'タイプ：'
                            '${KnowledgeType.displayName(selectedLinkTarget.knowledgeType)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '更新日時：'
                            '${_formatDateTime(selectedLinkTarget.updatedAt)}',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '関係の種類と保存処理は、'
                            '次のStepで実装します。',
                            textAlign: TextAlign.center,
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
                      'Knowledgeを編集する',
                      style: TextStyle(fontSize: 18),
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
