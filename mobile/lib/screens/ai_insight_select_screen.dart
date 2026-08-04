import 'package:flutter/material.dart';

import '../models/ai_session.dart';
import 'ai_insight_confirm_screen.dart';

class AiInsightSelectScreen extends StatefulWidget {
  const AiInsightSelectScreen({
    super.key,
    required this.session,
    required this.aiResponse,
  });

  final AiSession session;
  final String aiResponse;

  @override
  State<AiInsightSelectScreen> createState() =>
      _AiInsightSelectScreenState();
}

class _AiInsightSelectScreenState
    extends State<AiInsightSelectScreen> {
  static const List<String> _insightCandidates = [
    'AIは記憶を代替するのではなく、人の思考を支援する。',
    '個人の記憶は、利用者自身が管理できることが重要である。',
    '問いを育てる過程そのものが、人の成長につながる。',
    'AIとの対話から得た気づきは、将来の判断材料になる。',
  ];

  final Set<int> _selectedIndexes = {};

  void _toggleInsight(
    int index,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        _selectedIndexes.add(index);
      } else {
        _selectedIndexes.remove(index);
      }
    });
  }

  void _confirmInsights() {
    if (_selectedIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '残したいInsightを1件以上選んでください。',
          ),
        ),
      );
      return;
    }

    final selectedInsights = _selectedIndexes
        .map((index) => _insightCandidates[index])
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiInsightConfirmScreen(
          session: widget.session,
          selectedInsights: selectedInsights,
          aiResponse: widget.aiResponse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIndexes.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insight候補を選ぶ'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.session.title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'AI回答から、\n'
                      '残したい気づきを選んでください。',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AIが示した候補をそのまま採用する必要はありません。'
                      '自分にとって意味のあるものだけを選びます。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ...List.generate(
                      _insightCandidates.length,
                      (index) {
                        final candidate =
                            _insightCandidates[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: CheckboxListTile(
                              value:
                                  _selectedIndexes.contains(index),
                              title: Text(candidate),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              onChanged: (value) {
                                _toggleInsight(
                                  index,
                                  value ?? false,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: const Text(
                        '取り込んだAI回答を確認する',
                      ),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(
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
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  24,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$selectedCount件選択中',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _confirmInsights,
                        icon: const Icon(
                          Icons.lightbulb_outline,
                        ),
                        label: const Text(
                          '選択したInsightを確認する',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
