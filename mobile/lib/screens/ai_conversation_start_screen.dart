import 'package:flutter/material.dart';

import '../models/ai_session.dart';
import 'ai_prompt_assist_screen.dart';

class AiConversationStartScreen extends StatefulWidget {
  const AiConversationStartScreen({
    super.key,
    required this.session,
  });

  final AiSession session;

  @override
  State<AiConversationStartScreen> createState() =>
      _AiConversationStartScreenState();
}

class _AiConversationStartScreenState
    extends State<AiConversationStartScreen> {
  static const List<String> _purposes = [
    '考えを整理したい',
    'アイデアを広げたい',
    'AIと壁打ちしたい',
    '比較して決めたい',
    '学びたい',
    '自由に相談したい',
  ];

  final TextEditingController _themeController =
      TextEditingController();

  String? _selectedPurpose;

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _goToNextStep() async {
    // 入力欄のフォーカスを外し、キーボードを閉じる
    FocusManager.instance.primaryFocus?.unfocus();

    final purpose = _selectedPurpose;
    final theme = _themeController.text.trim();

    if (purpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '今日はどのように考えたいかを選んでください。',
          ),
        ),
      );
      return;
    }

    if (theme.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '今、気になっていることを入力してください。',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AiPromptAssistScreen(
          session: widget.session,
          purpose: purpose,
          theme: theme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIとの対話を始める'),
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
              const SizedBox(height: 32),
              Text(
                '今日は、どんなことを'
                '一緒に考えましょうか。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'まだ考えがまとまっていなくても大丈夫です。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              Text(
                '今日は、どのように考えたいですか？',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _purposes.map((purpose) {
                  return ChoiceChip(
                    label: Text(purpose),
                    selected: _selectedPurpose == purpose,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPurpose =
                            selected ? purpose : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),
              Text(
                '今、気になっていることは何ですか？',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _themeController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      '一言でも大丈夫です。\n'
                      '例：AIアバターの役割について考えたい',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _goToNextStep,
                  icon: const Icon(
                    Icons.auto_awesome_outlined,
                  ),
                  label: const Text(
                    '一緒に考える',
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
