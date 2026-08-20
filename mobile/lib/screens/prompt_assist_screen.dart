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

  String? _selectedTopicCategory;

  String? _selectedTopicExample;

  bool _isSelectingTopicCategory = true;

  static const Map<String, List<String>>
      _topicExamples = {
    '仕事・働き方': [
      '［自分の経験や得意なこと］を活かせる新しい仕事を考えたい',
      '［自分が関心のある分野］で、AIを活用した仕事や副業を考えたい',
      '［現在の仕事や働き方］についての悩みを整理したい',
      '［これから大切にしたいこと］を踏まえて、今後の働き方を考えたい',
    ],
    '暮らし・将来': [
      '［今の生活で気になっていること］を改善して、これからの生活をより良くしたい',
      '［これから大切にしたいこと］を整理して、今後の生活について考えたい',
      '［将来心配していること］に備えて、今から準備できることを考えたい',
      '［これからやってみたいこと］を実現する方法を考えたい',
    ],
    '困りごと・問題解決': [
      '［今困っていること］を解決する方法を考えたい',
      '［起きている問題］の原因を整理したい',
      '［解決したい問題］について、いくつかの解決方法を考えたい',
      '［取り組みたい問題］について、まず何から始めればよいか考えたい',
    ],
    '選択・判断': [
      '［迷っている選択肢］を比較して、自分に合うものを考えたい',
      '［検討していること］について、それぞれのメリットとデメリットを知りたい',
      '［決めようとしていること］について、自分に合った選択肢を考えたい',
      '［判断したいこと］について、決める前に確認すべきことを整理したい',
    ],
    '学び・調べもの': [
      '［知りたいテーマ］について、基礎から学びたい',
      '［理解したい内容］について、初心者にも分かるように教えてほしい',
      '［学びたいテーマ］について、何から学べばよいか順番を知りたい',
      '［調べたいテーマ］について、もっと詳しく調べるためのポイントを知りたい',
    ],
    '健康・生活習慣': [
      '［見直したい生活習慣］について、改善できることを考えたい',
      '［健康について気になっていること］について、日常生活でできることを知りたい',
      '［改善したい生活習慣］について、無理なく続けられる方法を考えたい',
      '［医療機関などに相談したいこと］について、相談するときに確認することを整理したい',
    ],
    '人間関係・コミュニケーション': [
      '［伝えたい相手と内容］について、うまく伝える方法を考えたい',
      '［人間関係で困っていること］について、状況を整理したい',
      '［話し合いたい相手やテーマ］について、何を伝えればよいか考えたい',
      '［相手との間で解決したいこと］について、相手の立場も考えながら解決方法を探したい',
    ],
    'アイデア・創作': [
      '［取り組みたいテーマ］について、新しいアイデアを一緒に考えたい',
      '［思いついているアイデア］を、実現できる形に具体化したい',
      '［企画したいこと］について、いくつかの案を考えたい',
      '［趣味や活動の内容］を、もっと楽しむ方法を考えたい',
    ],
  }; 
 
  String _selectedPurpose =
      '分かりやすく教えてほしい';

  String _selectedDetail =
      '標準';  
 
  static const List<String> _purposes = [
    '分かりやすく教えてほしい',
    'アイデアを提案してほしい',
    '整理してほしい',
    '比較してほしい',
    '一緒に考えてほしい',
    '手順を教えてほしい',
    '改善案を出してほしい',
    '判断材料を整理してほしい',
  ]; 
 
  static const List<String> _details = [
    '短く',
    '標準',
    '詳しく',
  ];

  final Set<String>
      _selectedConditionOptions = {};

  static const Map<String, String>
      _conditionOptionInstructions = {
    '分かりやすい言葉で':
        '専門用語をできるだけ避け、'
        '分かりやすい言葉で説明してください。',

    '具体例を入れて':
        '内容を理解しやすくするため、'
        '具体例があれば示してください。',

    '箇条書きで':
        '要点は、必要に応じて'
        '箇条書きも使って整理してください。',

    '注意点も含めて':
        '注意点や考えられるリスクがあれば、'
        'あわせて示してください。',
  };

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
      case 'アイデアを提案してほしい':
        purposeText =
            '考えられるアイデアを'
            'いくつか提案してください。';
        break;

      case '整理してほしい':
        purposeText =
            '重要なポイントを'
            '整理してください。';
        break;

      case '比較してほしい':
        purposeText =
            '主な選択肢を比較し、'
            'それぞれの違いを'
            '分かりやすく示してください。';
        break;

      case '一緒に考えてほしい':
        purposeText =
            '一つの結論を急がず、'
            '考えられる選択肢や視点を'
            '示しながら一緒に'
            '考えてください。';
        break;

      case '手順を教えてほしい':
        purposeText =
            '何から始めればよいか、'
            '順番に説明してください。';
        break;

      case '改善案を出してほしい':
        purposeText =
            '改善できる点と'
            '具体的な方法を'
            '提案してください。';
        break;

      case '判断材料を整理してほしい':
        purposeText =
            '自分で判断するために'
            '必要なポイントを'
            '整理してください。';
        break;

      case '分かりやすく教えてほしい':
      default:
        purposeText =
            '分かりやすく'
            '説明してください。';
        break;
    }   
   
    String detailText;

    switch (_selectedDetail) {
      case '短く':
        detailText =
            '要点を絞って簡潔に'
            '回答してください。';
        break;

      case '詳しく':
        detailText =
            '背景や理由、具体例も含めて'
            '詳しく回答してください。';
        break;

      case '標準':
      default:
        detailText =
            '必要なポイントを整理して'
            '分かりやすく回答してください。';
        break;   
    }

    final buffer = StringBuffer();

    buffer.writeln('## 質問');
    buffer.writeln();
    buffer.writeln(topic);

    buffer.writeln();
    buffer.writeln(purposeText);
    buffer.writeln(detailText);   
   
    final selectedConditionInstructions =
        _selectedConditionOptions
            .map(
              (option) =>
                  _conditionOptionInstructions[
                    option
                  ],
            )
            .whereType<String>()
            .toList();

    final hasConditionOptions =
        selectedConditionInstructions.isNotEmpty;

    final hasCustomConditions =
        conditions.isNotEmpty;

    if (hasConditionOptions ||
        hasCustomConditions) {
      buffer.writeln();
      buffer.writeln(
        '次の条件や希望も考慮してください。',
      );

      if (hasConditionOptions) {
        buffer.writeln();

        for (final instruction
            in selectedConditionInstructions) {
          buffer.writeln(
            '・$instruction',
          );
        }
      }

      if (hasCustomConditions) {
        buffer.writeln();

        buffer.writeln(
          'また、次の事情や希望も'
          '考慮してください。',
        );

        buffer.writeln(conditions);
      }
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
                        '相談したい内容に近いものを'
                        '選んでください。'
                        '例文を選んだあと、'
                        '［　］の部分をあなたの内容に'
                        '書き換えられます。',
                      ),                    
                    
                      const SizedBox(height: 12),

                      if (_isSelectingTopicCategory) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _topicExamples.keys
                                  .map(
                            (category) {
                              return ChoiceChip(
                                label: Text(
                                  category,
                                ),
                                selected:
                                    _selectedTopicCategory ==
                                        category,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedTopicCategory =
                                        category;

                                    _selectedTopicExample =
                                        null;

                                    _isSelectingTopicCategory =
                                        false;
                                  });
                                },
                              );
                            },
                          ).toList(),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedTopicCategory =
                                  null;

                              _selectedTopicExample =
                                  null;

                              _isSelectingTopicCategory =
                                  false;
                            });
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                          label: const Text(
                            '自分で入力する',
                          ),
                        ),
                     
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedTopicCategory ==
                                        null
                                    ? '自分で入力'
                                    : '選択中：'
                                        '$_selectedTopicCategory',
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSelectingTopicCategory =
                                      true;
                                });
                              },
                              child: const Text(
                                '変更',
                              ),
                            ),
                          ],
                        ),

                        if (_selectedTopicCategory !=
                            null) ...[
                          const SizedBox(height: 12),

                          const Text(
                            '相談したい内容に近い例文を'
                            '選んでください。',
                          ),

                          const SizedBox(height: 8),

                          RadioGroup<String>(
                            groupValue:
                                _selectedTopicExample,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _selectedTopicExample =
                                    value;

                                _topicController.text =
                                    value;
                              });
                            },
                            child: Column(
                              children: (
                                _topicExamples[
                                        _selectedTopicCategory] ??
                                    const <String>[]
                              )
                                  .map(
                                (example) {
                                  return Card(
                                    margin:
                                        const EdgeInsets.only(
                                      bottom: 8,
                                    ),
                                    child:
                                        RadioListTile<String>(
                                      value: example,
                                      title: Text(
                                        example,
                                      ),
                                      contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ],
                      ],                     
                     
                      const SizedBox(height: 12),

                      const Text(
                        'あなたの内容に'
                        '書き換えてください。',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        '［　］の部分を'
                        '自分の内容に置き換えると、'
                        'よりあなたに合った'
                        '質問になります。',
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
                        '必要なものがあれば'
                        '選んでください。'
                        '複数選べます。',
                      ),

                      const SizedBox(height: 12),

                      ..._conditionOptionInstructions.keys.map(
                        (option) {
                          return CheckboxListTile(
                            value:
                                _selectedConditionOptions
                                    .contains(
                              option,
                            ),
                            title: Text(
                              option,
                            ),
                            contentPadding:
                                EdgeInsets.zero,
                            controlAffinity:
                                ListTileControlAffinity
                                    .leading,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedConditionOptions
                                      .add(
                                    option,
                                  );
                                } else {
                                  _selectedConditionOptions
                                      .remove(
                                    option,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'その他の条件や希望',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        '自分の事情や希望があれば'
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
