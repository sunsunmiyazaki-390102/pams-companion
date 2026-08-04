import 'package:flutter/material.dart';

import '../models/ai_session.dart';

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

  void _confirmInsights() {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${confirmedInsights.length}件のInsightを確認しました。'
          'SQLite保存は次のStepで実装します。',
        ),
      ),
    );
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
                  onPressed: _confirmInsights,
                  icon: const Icon(
                    Icons.auto_awesome_outlined,
                  ),
                  label: const Text(
                    '知識資産として保存する',
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
