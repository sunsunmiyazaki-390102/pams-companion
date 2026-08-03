import 'package:flutter/material.dart';

import '../models/ai_session.dart';

class AiResponseStyleScreen extends StatefulWidget {
  const AiResponseStyleScreen({
    super.key,
    required this.session,
    required this.purpose,
    required this.theme,
    required this.selectedPrompt,
  });

  final AiSession session;
  final String purpose;
  final String theme;
  final String selectedPrompt;

  @override
  State<AiResponseStyleScreen> createState() =>
      _AiResponseStyleScreenState();
}

class _AiResponseStyleScreenState
    extends State<AiResponseStyleScreen> {
  static const List<Map<String, String>> _responseStyles = [
    {
      'title': 'わかりやすく理解したい',
      'description': '初心者にも分かる言葉で、具体例を交えて説明します。',
      'instruction':
          '初心者にも分かるように、専門用語をできるだけ避け、'
          '具体例を交えて説明してください。',
    },
    {
      'title': 'アイデアを広げたい',
      'description': 'さまざまな視点から、幅広い案を提案します。',
      'instruction':
          '固定観念にとらわれず、異なる視点から幅広いアイデアを'
          '提案してください。',
    },
    {
      'title': '比較して整理したい',
      'description': '選択肢、長所、短所、判断基準を整理します。',
      'instruction':
          '考えられる選択肢を挙げ、メリット、デメリット、'
          '判断基準を分かりやすく整理してください。',
    },
    {
      'title': '実行できる形にしたい',
      'description': '具体的な手順と、最初の一歩を示します。',
      'instruction':
          '実行できる具体的な手順、優先順位、注意点、'
          '最初に行う一歩を示してください。',
    },
    {
      'title': '一緒に考えてほしい',
      'description': '結論を急がず、問いかけながら考えを深めます。',
      'instruction':
          'すぐに結論を出さず、必要な問いを返しながら、'
          '私の考えを深める壁打ち相手になってください。',
    },
  ];

  int? _selectedIndex;

  void _confirmResponseStyle() {
    final selectedIndex = _selectedIndex;

    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '期待する回答の形を選んでください。',
          ),
        ),
      );
      return;
    }

    final selectedStyle = _responseStyles[selectedIndex];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '「${selectedStyle['title']}」を選択しました。',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回答の形を選ぶ'),
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
                'この質問で、\n'
                'どのような回答を期待しますか？',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                widget.selectedPrompt,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              RadioGroup<int>(
                groupValue: _selectedIndex,
                onChanged: (value) {
                  setState(() {
                    _selectedIndex = value;
                  });
                },
                child: Column(
                  children: List.generate(
                    _responseStyles.length,
                    (index) {
                      final style = _responseStyles[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: RadioListTile<int>(
                            value: index,
                            title: Text(
                              style['title']!,
                            ),
                            subtitle: Text(
                              style['description']!,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _confirmResponseStyle,
                  icon: const Icon(
                    Icons.arrow_forward_outlined,
                  ),
                  label: const Text(
                    'プロンプトを確認する',
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
