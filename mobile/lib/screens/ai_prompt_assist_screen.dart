import 'package:flutter/material.dart';

import '../models/ai_session.dart';

class AiPromptAssistScreen extends StatefulWidget {
  const AiPromptAssistScreen({
    super.key,
    required this.session,
    required this.purpose,
    required this.theme,
  });

  final AiSession session;
  final String purpose;
  final String theme;

  @override
  State<AiPromptAssistScreen> createState() =>
      _AiPromptAssistScreenState();
}

class _AiPromptAssistScreenState
    extends State<AiPromptAssistScreen> {
  int? _selectedIndex;

  List<String> get _promptCandidates {
    final theme = widget.theme;

    switch (widget.purpose) {
      case '考えを整理したい':
        return [
          '「$theme」について、現在の論点を分かりやすく整理してください。',
          '「$theme」について、分かっていることと、まだ分からないことを分けて整理してください。',
          '「$theme」について、重要な論点、課題、次に考えるべきことを順番に示してください。',
        ];

      case 'アイデアを広げたい':
        return [
          '「$theme」について、可能性を幅広く提案してください。',
          '「$theme」について、現在の考えを発展させる新しい視点を示してください。',
          '「$theme」について、実現できそうな案と将来の案を分けて整理してください。',
        ];

      case 'AIと壁打ちしたい':
        return [
          '「$theme」について、結論を急がず壁打ち相手になってください。',
          '「$theme」について、私の考えを深めるための問いを一つずつ投げかけてください。',
          '「$theme」について、別の視点や不足している論点を示しながら一緒に考えてください。',
        ];

      case '比較して決めたい':
        return [
          '「$theme」について、考えられる選択肢を比較してください。',
          '「$theme」について、メリット、デメリット、判断基準を整理してください。',
          '「$theme」について、短期的な視点と長期的な視点から比較してください。',
        ];

      case '学びたい':
        return [
          '「$theme」について、初心者にも分かるように順序立てて説明してください。',
          '「$theme」について、基本、具体例、注意点に分けて説明してください。',
          '「$theme」について、理解を深めるために次に学ぶべき内容も示してください。',
        ];

      case '自由に相談したい':
      default:
        return [
          '「$theme」について、私の状況を整理しながら相談に乗ってください。',
          '「$theme」について、考えられる見方や対応方法を提案してください。',
          '「$theme」について、必要な確認事項を質問しながら一緒に考えてください。',
        ];
    }
  }

  void _confirmPrompt() {
    final selectedIndex = _selectedIndex;

    if (selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AIへ聞いてみたい質問を選んでください。',
          ),
        ),
      );
      return;
    }

    final selectedPrompt = _promptCandidates[selectedIndex];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '選択した質問：$selectedPrompt',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _promptCandidates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('質問を一緒に作る'),
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
                '「${widget.theme}」について、\n'
                'どのようにAIへ聞いてみますか？',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                '目的：${widget.purpose}',
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
                    candidates.length,
                    (index) {
                      final candidate = candidates[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: RadioListTile<int>(
                            value: index,
                            title: Text(candidate),
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
                  onPressed: _confirmPrompt,
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: const Text(
                    'この質問を使う',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '質問は次の画面で自由に修正できます。',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
