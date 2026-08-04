import 'package:flutter/material.dart';

import '../models/ai_session.dart';
import 'ai_insight_select_screen.dart';

class AiResponseImportScreen extends StatefulWidget {
  const AiResponseImportScreen({
    super.key,
    required this.session,
    required this.completedPrompt,
  });

  final AiSession session;
  final String completedPrompt;

  @override
  State<AiResponseImportScreen> createState() =>
      _AiResponseImportScreenState();
}

class _AiResponseImportScreenState
    extends State<AiResponseImportScreen> {
  static const List<String> _aiProviders = [
    'ChatGPT',
    'Gemini',
    'Claude',
    'その他',
  ];

  final TextEditingController _responseController =
      TextEditingController();

  String _selectedProvider = 'ChatGPT';

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _confirmResponse() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final response = _responseController.text.trim();

    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AIからの回答を貼り付けてください。',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AiInsightSelectScreen(
          session: widget.session,
          aiResponse: response,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI回答を取り込む'),
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
                'AIから返ってきた回答を\n'
                'PAMSへ迎え入れます。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'AI画面で回答をコピーし、'
                '下の欄へ貼り付けてください。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                '利用したAI',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedProvider,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _aiProviders.map((provider) {
                  return DropdownMenuItem<String>(
                    value: provider,
                    child: Text(provider),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedProvider = value;
                  });
                },
              ),
              const SizedBox(height: 28),
              Text(
                'AIからの回答',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _responseController,
                minLines: 12,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText:
                      'ここを長押しして「貼り付け」を選びます。',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '回答は原文のまま保存します。'
                'Insight候補の確認は次の工程で行います。',
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _confirmResponse,
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    '回答を確認する',
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
