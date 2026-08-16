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
  String? _originalQuestion;

  bool _isSaving = false;

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
    final result =
        await Navigator.of(context)
            .push<PromptAssistResult>(
      MaterialPageRoute<PromptAssistResult>(
        builder: (context) =>
            const PromptAssistScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _originalQuestion =
          result.originalQuestion.trim();

      _questionController.text =
          result.aiPrompt.trim();
    });
  } 

  Future<void> _copyQuestionToClipboard() async {
    final question =
        _questionController.text.trim();

    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '質問を入力してください。',
          ),
        ),
      );

      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: question,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '質問をコピーしました。',
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

  Future<void> _saveWaitingConversation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSaving) {
      return;
    }

    final projectId = _selectedProjectId;

    final aiPrompt =
        _questionController.text.trim();

    final originalQuestion =
        _originalQuestion?.trim();

    final userMessage =
        originalQuestion != null &&
                originalQuestion.isNotEmpty
            ? originalQuestion
            : aiPrompt;

    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '保存先テーマを選択してください。',
          ),
        ),
      );
      return;
    }

    if (aiPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '質問を入力してください。',
          ),
        ),
      );
      return;
    }

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
        userMessage,
      ),
      createdAt: now,
      updatedAt: now,
    );

    final conversation = AiConversation(
      conversationId: conversationId,
      sessionId: sessionId,
      userMessage: userMessage,
      aiPrompt: aiPrompt,
      aiResponse: '',      
      summary: '',
      aiProvider: '',
      responseStatus:
          AiResponseStatus.waiting,
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

      setState(() {
        _originalQuestion = null;
        _isSaving = false;
      });    
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '質問を保存しました。',
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
                    'テーマの読み込みに'
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
                                'テーマがありません。',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '先に「テーマ」から'
                                'テーマを作成してください。',
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
                                '保存先テーマ',
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
                                      'テーマ',
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
                                    return 'テーマを'
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
                                'AIへの質問をつくる',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'まず、何についてAIと'
                                '考えたいかを整理します。',
                              ),
                              const SizedBox(height: 16),

                              SizedBox(
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed:
                                      _openPromptAssist,
                                  icon: const Icon(
                                    Icons
                                        .auto_awesome_outlined,
                                  ),
                                  label: const Text(
                                    '質問作成を手伝ってもらう',
                                  ),
                                ),
                              ),

                              if (_originalQuestion !=
                                      null &&
                                  _originalQuestion!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Text(
                                  'あなたが考えたいこと',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  _originalQuestion!,
                                ),
                              ],

                              const SizedBox(height: 20),
                              const Text(
                                'AIへ渡す文章',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '質問作成後の文章を'
                                '確認できます。'
                                '自分で直接入力することも'
                                'できます。',
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller:
                                    _questionController,
                                minLines: 5,
                                maxLines: 12,
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'AIへ渡す文章を'
                                      'ここに入力します。',
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
                                    return 'AIへ渡す文章を'
                                        '入力してください。';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              Align(
                                alignment:
                                    Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed:
                                      _copyQuestionToClipboard,
                                  icon: const Icon(
                                    Icons
                                        .content_copy_outlined,
                                  ),
                                  label: const Text(
                                    'AIへ渡す文章をコピーする',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed:
                              _isSaving
                                  ? null
                                  : _saveWaitingConversation,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .hourglass_empty_outlined,
                                ),
                        
                          label: Text(
                            _isSaving
                                ? '保存しています...'
                                : '質問を保存する',
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),                        
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        '質問をAIへ送ったあと、'
                        '回答を受け取ったら'
                        '「これまでの対話」から'
                        '回答を取り込めます。',
                        textAlign: TextAlign.center,
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
                             