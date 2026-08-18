import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PromptAssistResult {
  const PromptAssistResult({
    required this.originalQuestion,
    required this.aiPrompt,
  });

  final String originalQuestion;
  final String aiPrompt;
}

class PromptAssistScreen
    extends StatefulWidget {
  const PromptAssistScreen({
    super.key,
  });

  @override
  State<PromptAssistScreen> createState() =>
      _PromptAssistScreenState();
}

class _PromptAssistScreenState
    extends State<PromptAssistScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController
      _topicController =
      TextEditingController();

  final TextEditingController
      _conditionsController =
      TextEditingController();

  final TextEditingController
      _generatedPromptController =
      TextEditingController();

  String _selectedPurpose =
      '説明してほしい';

  String _selectedDetail =
      '普通';

  static const List<String> _purposes = [
    '説明してほしい',
    '手順を教えてほしい',
    '比較してほしい',
    'アイデアがほしい',
    '問題点を見つけてほしい',
    '一緒に考えてほしい',
  ];

  static const List<String> _details = [
    '簡潔に',
    '普通',
    '詳しく',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _conditionsController.dispose();
    _generatedPromptController.dispose();

    super.dispose();
  }

  void _generatePrompt() {
    FocusManager.instance.primaryFocus?.unfocus();

    final isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid) {
      return;
    }

    final topic =
        _topicController.text.trim();

    final conditions =
        _conditionsController.text.trim();

    String purposeText;

    switch (_selectedPurpose) {
      case '手順を教えてほしい':
        purposeText =
            '具体的な手順を順番に'
            '教えてください。';
        break;

      case '比較してほしい':
        purposeText =
            '主な選択肢を比較し、'
            'それぞれの長所と短所を'
            '示してください。';
        break;

      case 'アイデアがほしい':
        purposeText =
            '実行可能なアイデアを'
            '複数提案してください。';
        break;

      case '問題点を見つけてほしい':
        purposeText =
            '考えられる問題点や'
            '注意点を整理してください。';
        break;

      case '一緒に考えてほしい':
        purposeText =
            '一つの結論を急がず、'
            '考えるべき視点や問いを'
            '示しながら一緒に'
            '検討してください。';
        break;

      case '説明してほしい':
      default:
        purposeText =
            '分かりやすく'
            '説明してください。';
        break;
    }

    String detailText;

    switch (_selectedDetail) {
      case '簡潔に':
        detailText =
            '要点を絞って簡潔に'
            '回答してください。';
        break;

      case '詳しく':
        detailText =
            '背景や理由、具体例も含めて'
            '詳しく回答してください。';
        break;

      case '普通':
      default:
        detailText =
            '必要なポイントを整理して'
            '回答してください。';
        break;
    }

    final buffer = StringBuffer();

    buffer.writeln(
      '$topicについて相談します。',
    );

    buffer.writeln();
    buffer.writeln(purposeText);
    buffer.writeln(detailText);

    if (conditions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        '次の条件や希望も考慮してください。',
      );
      buffer.writeln(conditions);
    }

    buffer.writeln();
    buffer.writeln('次のMarkdown形式で回答してください。');
    buffer.writeln();
    buffer.writeln('## 回答');
    buffer.writeln();
    buffer.writeln(
      '質問に対する回答を記載してください。',
    );

    buffer.writeln();
    buffer.writeln('## 要約');
    buffer.writeln();
    buffer.writeln(
      '回答全体の重要な内容を'
      '簡潔にまとめてください。',
    );

    buffer.writeln();
    buffer.writeln('## 知識候補');
    buffer.writeln();
    buffer.writeln(
      'この対話から、今後の判断、行動、'
      '学習又は新しい思考に役立つ知識を、'
      '1件から3件提案してください。',
    );
    buffer.writeln();
    buffer.writeln(
      '各知識候補は、'
      '次の形式で記載してください。',
    );
    buffer.writeln();
    buffer.writeln('### 知識候補 1');
    buffer.writeln('内容:');
    buffer.writeln(
      'ここに知識候補の内容を'
      '記載してください。',
    );
    buffer.writeln();
    buffer.writeln('理由:');
    buffer.writeln(
      'この知識候補を残す理由を'
      '記載してください。',
    );
    buffer.writeln();
    buffer.writeln(
      '必要な件数だけ、'
      '「### 知識候補 2」'
      '「### 知識候補 3」'
      'として続けてください。',
    );
    buffer.writeln();
    buffer.writeln(
      '該当する知識候補がない場合は、'
      '「なし」と記載してください。',
    );

    buffer.writeln();
    buffer.writeln('## 次に考える問い');
    buffer.writeln();
    buffer.writeln(
      'このテーマをさらに深めたり、'
      '次の行動につなげたりするための問いを、'
      '1件から3件提案してください。',
    );
    buffer.writeln();
    buffer.writeln(
      '各問いは、'
      '次の形式で記載してください。',
    );
    buffer.writeln();
    buffer.writeln('### 問い 1');
    buffer.writeln('内容:');
    buffer.writeln(
      'ここに次に考える問いを'
      '記載してください。',
    );
    buffer.writeln();
    buffer.writeln('理由:');
    buffer.writeln(
      'この問いを次に考える理由を'
      '記載してください。',
    );
    buffer.writeln();
    buffer.writeln(
      '必要な件数だけ、'
      '「### 問い 2」'
      '「### 問い 3」'
      'として続けてください。',
    );
    buffer.writeln();
    buffer.writeln(
      '該当する問いがない場合は、'
      '「なし」と記載してください。',
    );

    buffer.writeln();
    buffer.writeln(
      '見出し名と「内容:」「理由:」の'
      'ラベルは変更しないでください。',
    );  
  
    setState(() {
      _generatedPromptController.text =
          buffer.toString().trim();
    });
  }

  Future<void> _copyGeneratedPrompt() async {
    final prompt =
        _generatedPromptController.text.trim();

    if (prompt.isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: prompt,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '質問文をコピーしました。',
        ),
      ),
    );
  }

  void _useGeneratedPrompt() {
    final originalQuestion =
        _topicController.text.trim();

    final aiPrompt =
        _generatedPromptController.text.trim();

    if (originalQuestion.isEmpty ||
        aiPrompt.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      PromptAssistResult(
        originalQuestion:
            originalQuestion,
        aiPrompt: aiPrompt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '質問作成アシスト',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.all(24),
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      Icons.auto_awesome_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AIへの質問を一緒に作る',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                '考えていることを順番に整理し、'
                'AIへ伝わりやすい質問文を'
                '作るための準備をします。',
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '1. 何について相談しますか？',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '相談したいテーマや'
                        '知りたいことを入力してください。',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller:
                            _topicController,
                        minLines: 2,
                        maxLines: 5,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                          hintText:
                              '例：PAMSの知識を'
                              '整理する方法',
                          alignLabelWithHint:
                              true,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return '相談したい内容を'
                                '入力してください。';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '2. AIに何をしてほしいですか？',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      RadioGroup<String>(
                        groupValue:
                            _selectedPurpose,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedPurpose =
                                value;
                          });
                        },
                        child: Column(
                          children: [
                            ..._purposes.map(
                              (purpose) =>
                                  RadioListTile<
                                      String>(
                                value: purpose,
                                title: Text(
                                  purpose,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '3. どのくらい詳しく？',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      RadioGroup<String>(
                        groupValue:
                            _selectedDetail,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedDetail =
                                value;
                          });
                        },
                        child: Column(
                          children: [
                            ..._details.map(
                              (detail) =>
                                  RadioListTile<
                                      String>(
                                value: detail,
                                title: Text(
                                  detail,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '4. 条件や希望',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '回答するときに'
                        '考慮してほしいことがあれば'
                        '入力してください。',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller:
                            _conditionsController,
                        minLines: 3,
                        maxLines: 8,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                          hintText:
                              '例：初心者にも'
                              '分かるように、'
                              '具体例を入れてください。',
                          alignLabelWithHint:
                              true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _generatePrompt,
                icon: const Icon(
                  Icons.auto_awesome_outlined,
                ),
                label: const Text(
                  '質問文を作成する',
                ),
              ),

              const SizedBox(height: 24),

              if (_generatedPromptController
                  .text
                  .isNotEmpty)
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.edit_note_outlined,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '作成した質問文',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'このまま使うことも、'
                          '自分の言葉へ直すことも'
                          'できます。',
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller:
                              _generatedPromptController,
                          minLines: 8,
                          maxLines: 18,
                          decoration:
                              const InputDecoration(
                            border:
                                OutlineInputBorder(),
                            alignLabelWithHint:
                                true,
                          ),
                        ),

                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed:
                              _copyGeneratedPrompt,
                          icon: const Icon(
                            Icons.copy_outlined,
                          ),
                          label: const Text(
                            '質問文をコピーする',
                          ),
                        ),

                        const SizedBox(height: 12),

                        FilledButton.icon(
                          onPressed:
                              _useGeneratedPrompt,
                          icon: const Icon(
                            Icons.arrow_back,
                          ),
                          label: const Text(
                            'この質問文を使う',
                          ),
                        ),
                      ],
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
