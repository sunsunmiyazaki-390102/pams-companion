import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../models/ai_session.dart';
import '../models/project.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/ai_session_repository.dart';
import '../repositories/project_repository.dart';
import 'ai_conversation_list_screen.dart';
import 'prompt_assist_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    this.initialQuestion,
    this.initialProjectId,
  });

  final String? initialQuestion;
  final String? initialProjectId;

  @override
  State<AiChatScreen> createState() =>
      _AiChatScreenState();
}

class _AiChatScreenState
    extends State<AiChatScreen> {
  final ProjectRepository _projectRepository =
      ProjectRepository();

  final AiSessionRepository _sessionRepository =
      AiSessionRepository();

  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  final Uuid _uuid = const Uuid();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _questionController =
      TextEditingController();

  final TextEditingController _aiResponseController =
      TextEditingController();

  late Future<List<Project>> _projectsFuture;

  String? _selectedProjectId;
  String? _selectedAiProvider;

  bool _isSaving = false;

  static const List<String> _aiProviders = [
    'ChatGPT',
    'Gemini',
    'Claude',
    'Copilot',
    'その他',
  ];

  @override
  void initState() {
    super.initState();

    final initialQuestion =
        widget.initialQuestion?.trim();

    if (initialQuestion != null &&
        initialQuestion.isNotEmpty) {
      _questionController.text =
          initialQuestion;
    }

    _selectedProjectId =
        widget.initialProjectId;

    _projectsFuture =
        _projectRepository.findAll();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _aiResponseController.dispose();

    super.dispose();
  }

  Future<void> _reloadProjects() async {
    setState(() {
      _projectsFuture =
          _projectRepository.findAll();
    });

    await _projectsFuture;
  }

  Future<void> _openConversationHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            const AiConversationListScreen(),
      ),
    );
  } 
 
  Future<void> _openPromptAssist() async {
    final prompt =
        await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) =>
            const PromptAssistScreen(),
      ),
    );

    if (!mounted ||
        prompt == null ||
        prompt.trim().isEmpty) {
      return;
    }

    setState(() {
      _questionController.text =
          prompt.trim();
    });
  }

  Future<void> _pasteAiResponseFromClipboard() async {
    final clipboardData =
        await Clipboard.getData(
      Clipboard.kTextPlain,
    );

    final text =
        clipboardData?.text?.trim();

    if (!mounted) {
      return;
    }

    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'クリップボードに'
            '貼り付けできる文章がありません。',
          ),
        ),
      );

      return;
    }

    setState(() {
      _aiResponseController.text = text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'AIの回答を貼り付けました。',
        ),
      ),
    );
  }

  String _buildSessionTitle(
    String question,
  ) {
    final normalizedQuestion =
        question.replaceAll('\n', ' ').trim();

    if (normalizedQuestion.length <= 40) {
      return normalizedQuestion;
    }

    return '${normalizedQuestion.substring(0, 40)}…';
  }

  Future<void> _saveConversation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid || _isSaving) {
      return;
    }

    final projectId = _selectedProjectId;
    final aiProvider = _selectedAiProvider;

    if (projectId == null ||
        aiProvider == null) {
      return;
    }

    final question =
        _questionController.text.trim();

    final aiResponse =
        _aiResponseController.text.trim();

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final sessionId = _uuid.v4();
    final conversationId = _uuid.v4();

    final session = AiSession(
      sessionId: sessionId,
      projectId: projectId,
      title: _buildSessionTitle(
        question,
      ),
      createdAt: now,
      updatedAt: now,
    );

    final conversation = AiConversation(
      conversationId: conversationId,
      sessionId: sessionId,
      userMessage: question,
      aiResponse: aiResponse,
      summary: '',
      aiProvider: aiProvider,
      responseStatus:
          AiResponseStatus.received,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _sessionRepository.insert(
        session,
      );

      await _conversationRepository.insert(
        conversation,
      );

      final savedConversation =
          await _conversationRepository.findById(
        conversationId,
      );

      if (savedConversation == null) {
        throw StateError(
          '保存したAI相談を確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      _questionController.clear();
      _aiResponseController.clear();

      setState(() {
        _selectedAiProvider = null;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI相談を保存しました。\n'
            '状態：'
            '${AiResponseStatus.displayName(savedConversation.responseStatus)}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI相談を保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AIに相談する',
        ),
        actions: [
          IconButton(
            onPressed: _openConversationHistory,
            tooltip: 'AI相談履歴を見る',
            icon: const Icon(
              Icons.history_outlined,
            ),
          ),
        ],
      ),     
      body: SafeArea(
        child: FutureBuilder<List<Project>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(24),
                  child: Text(
                    'Projectの読み込みに'
                    '失敗しました。\n'
                    '${snapshot.error}',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              );
            }

            final projects =
                snapshot.data ?? [];

            return RefreshIndicator(
              onRefresh: _reloadProjects,
              child: Form(
                key: _formKey,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.all(24),
                  children: [
                    const Row(
                      children: [
                        CircleAvatar(
                          child: Icon(
                            Icons
                                .chat_bubble_outline,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI相談を記録する',
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
                      'AIへの質問と回答を保存し、'
                      'あとから整理できるようにします。',
                    ),
                    const SizedBox(height: 24),
                    if (projects.isEmpty)
                      const Card(
                        child: Padding(
                          padding:
                              EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .folder_off_outlined,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Projectがありません。',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '先にホーム画面の'
                                '「プロジェクト」から'
                                'Projectを作成してください。',
                                textAlign:
                                    TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,
                            children: [
                              const Text(
                                '保存先Project',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              DropdownButtonFormField<
                                  String>(
                                initialValue:
                                    _selectedProjectId,
                                decoration:
                                    const InputDecoration(
                                  border:
                                      OutlineInputBorder(),
                                  labelText:
                                      'Project',
                                ),
                                items: projects
                                    .map(
                                      (project) =>
                                          DropdownMenuItem<
                                              String>(
                                        value: project
                                            .projectId,
                                        child: Text(
                                          project.name,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProjectId =
                                        value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Projectを'
                                        '選択してください。';
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
                              const EdgeInsets.all(
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,
                            children: [
                              const Text(
                                'あなたの質問',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              const Text(
                                'AIへ相談した内容を'
                                '入力してください。',
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _openPromptAssist,
                                  icon: const Icon(
                                    Icons.auto_awesome_outlined,
                                  ),
                                  label: const Text(
                                    '質問作成を手伝ってもらう',
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),
                              TextFormField(
                                controller:
                                    _questionController,
                                minLines: 3,
                                maxLines: 8,
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      '例：PAMSのKnowledgeを'
                                      'どのように整理すれば'
                                      'よいですか。',
                                  border:
                                      OutlineInputBorder(),
                                  alignLabelWithHint:
                                      true,
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value
                                          .trim()
                                          .isEmpty) {
                                    return '質問を'
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
                              const EdgeInsets.all(
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,
                            children: [
                              const Text(
                                'AIからの回答',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              const Text(
                                'AIから受け取った回答を'
                                '貼り付けてください。',
                              ),
                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed:
                                      _pasteAiResponseFromClipboard,
                                  icon: const Icon(
                                    Icons.content_paste_outlined,
                                  ),
                                  label: const Text(
                                    'クリップボードから貼り付ける',
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),
                            
                              TextFormField(
                                controller:
                                    _aiResponseController,
                                minLines: 6,
                                maxLines: 16,
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'ここへAIの回答を'
                                      '貼り付けます。',
                                  border:
                                      OutlineInputBorder(),
                                  alignLabelWithHint:
                                      true,
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value
                                          .trim()
                                          .isEmpty) {
                                    return 'AIの回答を'
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
                              const EdgeInsets.all(
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch,
                            children: [
                              const Text(
                                '利用したAI',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              DropdownButtonFormField<
                                  String>(
                                initialValue:
                                    _selectedAiProvider,
                                decoration:
                                    const InputDecoration(
                                  border:
                                      OutlineInputBorder(),
                                  labelText:
                                      'AIサービス',
                                ),
                                items: _aiProviders
                                    .map(
                                      (provider) =>
                                          DropdownMenuItem<
                                              String>(
                                        value: provider,
                                        child: Text(
                                          provider,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAiProvider =
                                        value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return '利用したAIを'
                                        '選択してください。';
                                  }

                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed:
                            _isSaving
                                ? null
                                : _saveConversation,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.save_outlined,
                              ),
                        label: Text(
                          _isSaving
                              ? '保存しています...'
                              : 'AI相談を保存する',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
