import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_session.dart';
import '../models/knowledge_asset.dart';
import '../repositories/knowledge_asset_repository.dart';

class AiInsightConfirmScreen extends StatefulWidget {
  const AiInsightConfirmScreen({
    super.key,
    required this.session,
    required this.selectedInsights,
    required this.aiResponse,
  });

  final AiSession session;
  final List<String> selectedInsights;
  final String aiResponse;

  @override
  State<AiInsightConfirmScreen> createState() =>
      _AiInsightConfirmScreenState();
}

class _AiInsightConfirmScreenState
    extends State<AiInsightConfirmScreen> {
  late final List<TextEditingController> _controllers;

  final KnowledgeAssetRepository _knowledgeAssetRepository =
      KnowledgeAssetRepository();

  final Uuid _uuid = const Uuid();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _controllers = widget.selectedInsights.map((insight) {
      return TextEditingController(text: insight);
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _saveKnowledgeAssets() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final confirmedInsights = _controllers
        .map((controller) => controller.text.trim())
        .where((insight) => insight.isNotEmpty)
        .toList();

    if (confirmedInsights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '保存するInsightを1件以上入力してください。',
          ),
        ),
      );
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();

      for (final insight in confirmedInsights) {
        final asset = KnowledgeAsset(
          knowledgeId: _uuid.v4(),
          sessionId: widget.session.sessionId,
          conversationId: null,
          content: insight,
          createdAt: now,
          updatedAt: now,
        );

        await _knowledgeAssetRepository.insert(asset);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${confirmedInsights.length}件の知識資産を保存しました。',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '知識資産を保存できませんでした。',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insightを確認する'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.session.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                '残したい気づきを、\n'
                '自分の言葉で確認します。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'AIの表現をそのまま使う必要はありません。'
                '自分にとって意味のある言葉へ修正できます。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...List.generate(
                _controllers.length,
                (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: TextField(
                      controller: _controllers[index],
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Insight ${index + 1}',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  );
                },
              ),
              ExpansionTile(
                title: const Text(
                  '元のAI回答を確認する',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16,
                ),
                children: [
                  SelectableText(
                    widget.aiResponse,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _isSaving ? null : _saveKnowledgeAssets,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome_outlined,
                        ),
                  label: Text(
                    _isSaving
                        ? '保存しています…'
                        : '知識資産として保存する',
                    style: const TextStyle(fontSize: 18),
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
