import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/ai_session.dart';
import 'ai_response_import_screen.dart';

class AiPromptPreviewScreen extends StatefulWidget {
  const AiPromptPreviewScreen({
    super.key,
    required this.session,
    required this.purpose,
    required this.theme,
    required this.selectedPrompt,
    required this.responseStyleTitle,
    required this.responseInstruction,
  });

  final AiSession session;
  final String purpose;
  final String theme;
  final String selectedPrompt;
  final String responseStyleTitle;
  final String responseInstruction;

  @override
  State<AiPromptPreviewScreen> createState() =>
      _AiPromptPreviewScreenState();
}

class _AiPromptPreviewScreenState
    extends State<AiPromptPreviewScreen> {
  final TextEditingController _reasonController =
      TextEditingController();

  final TextEditingController _promptController =
      TextEditingController();

  bool _includeReasonInPrompt = true;

  @override
  void initState() {
    super.initState();
    _promptController.text = _completedPrompt;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  String get _completedPrompt {
    final reason = _reasonController.text.trim();

    final sections = <String>[
      '【今回の目的】',
      widget.purpose,
      '',
      '【考えたいテーマ】',
      widget.theme,
      '',
      '【質問】',
      widget.selectedPrompt,
      '',
      '【期待する回答】',
      widget.responseInstruction,
    ];

    if (_includeReasonInPrompt && reason.isNotEmpty) {
      sections.addAll([
        '',
        '【この質問をする理由】',
        reason,
      ]);
    }

    sections.addAll([
      '',
      '【回答形式】',
      '次の順番で回答してください。',
      '',
      '1. 質問への回答',
      '2. 重要な要点',
      '3. Insight候補',
      '4. 次に考える問い',
      '',
      'Insight候補は、単なる要約ではなく、'
          '今後の判断、行動、学習または新しい問いに'
          '生かせる短い考え方として3～5件示してください。',
    ]);

    return sections.join('\n');
  }

  void _refreshPreview() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _promptController.text = _completedPrompt;
    });
  }

  Future<void> _copyPrompt() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'コピーするプロンプトがありません。',
          ),
        ),
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: prompt),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'プロンプトをコピーしました。',
        ),
      ),
    );
  }

  Future<void> _openResponseImportScreen() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final completedPrompt = _promptController.text.trim();

    if (completedPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '先に完成プロンプトを確認してください。',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AiResponseImportScreen(
          session: widget.session,
          completedPrompt: completedPrompt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロンプトを確認する'),
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
                '問いと想いを、\n'
                '一つのプロンプトにまとめます。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                '内容を確認してからAIへ渡します。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'なぜ、このことを考えたいと思いましたか？',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '一言でも構いません。入力しなくても先へ進めます。',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      '例：将来、高齢者の孤独を減らす仕組みを'
                      '考えたいから',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _includeReasonInPrompt,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'この理由もAIへ伝える',
                ),
                subtitle: const Text(
                  'オフにすると、理由は完成プロンプトへ含めません。',
                ),
                controlAffinity:
                    ListTileControlAffinity.leading,
                onChanged: (value) {
                  setState(() {
                    _includeReasonInPrompt = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _refreshPreview,
                icon: const Icon(Icons.refresh),
                label: const Text('入力内容を反映する'),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Icon(Icons.description_outlined),
                  const SizedBox(width: 8),
                  Text(
                    '完成プロンプト',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                minLines: 12,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  helperText:
                      '内容を確認し、必要に応じて自由に修正できます。',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '回答スタイル：${widget.responseStyleTitle}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _copyPrompt,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text(
                    'プロンプトをコピーする',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _openResponseImportScreen,
                  icon: const Icon(
                    Icons.download_outlined,
                  ),
                  label: const Text(
                    'AI回答を取り込む',
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
