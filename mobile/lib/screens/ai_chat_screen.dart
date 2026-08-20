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
import 'ai_conversation_reflection_screen.dart';
import 'prompt_assist_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    this.initialQuestion,
    this.initialProjectId,
    this.initialConversation,
  });

  final String? initialQuestion;
  final String? initialProjectId;

  final AiConversation?
      initialConversation;

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

  AiConversation? _currentConversation;

  bool _isSaving = false;  
  bool _allowPop = false;

  Future<List<Project>>
      _loadProjectsWithDefault() async {
   
    var projects =
        await _projectRepository.findAll();

    final initialConversation =
        widget.initialConversation;

    if (initialConversation != null) {
      final session =
          await _sessionRepository.findById(
        initialConversation.sessionId,
      );

      if (session != null) {
        _selectedProjectId =
            session.projectId;

        return projects;
      }
    }

    if (widget.initialProjectId != null) {
      _selectedProjectId =
          widget.initialProjectId;

      return projects;
    }   
   
    Project? uncategorizedProject;

    for (final project in projects) {
      if (project.name == '未分類') {
        uncategorizedProject = project;
        break;
      }
    }

    if (uncategorizedProject == null) {
      final now = DateTime.now();

      uncategorizedProject = Project(
        projectId: _uuid.v4(),
        name: '未分類',
        description: '',
        createdAt: now,
        updatedAt: now,
      );

      await _projectRepository.insert(
        uncategorizedProject,
      );

      projects =
          await _projectRepository.findAll();
    }

    _selectedProjectId =
        uncategorizedProject.projectId;

    return projects;
  }

  @override
  void initState() {
    super.initState();

    _currentConversation =
        widget.initialConversation;

    final initialConversation =
        widget.initialConversation;

    if (initialConversation != null) {
      _questionController.text =
          initialConversation.aiPrompt;

      _originalQuestion =
          initialConversation.userMessage;

      _aiResponseController.text =
          initialConversation.aiResponse;
    } else {
      final initialQuestion =
          widget.initialQuestion?.trim();

      if (initialQuestion != null &&
          initialQuestion.isNotEmpty) {
        _questionController.text =
            initialQuestion;
      }
    }

    _projectsFuture =
        _loadProjectsWithDefault();
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

  Future<void> _openReflectionScreen() async {
    final currentConversation =
        _currentConversation;

    if (currentConversation == null ||
        currentConversation.responseStatus !=
            AiResponseStatus.received) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            AiConversationReflectionScreen(
          conversation:
              currentConversation,
        ),
      ),
    );

    final updatedConversation =
        await _conversationRepository.findById(
      currentConversation.conversationId,
    );

    if (updatedConversation == null ||
        !mounted) {
      return;
    }

    setState(() {
      _currentConversation =
          updatedConversation;
    });
  }

  Future<void> _saveDraftConversation() async {
    final projectId =
        _selectedProjectId;

    final aiPrompt =
        _questionController.text.trim();

    final originalQuestion =
        _originalQuestion?.trim();

    final userMessage =
        originalQuestion != null &&
                originalQuestion.isNotEmpty
            ? originalQuestion
            : aiPrompt;

    if (projectId == null ||
        aiPrompt.isEmpty) {
      return;
    }

    final currentConversation =
        _currentConversation;

    final now = DateTime.now();

    if (currentConversation == null) {
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
            AiResponseStatus.draft,
        createdAt: now,
        updatedAt: now,
      );

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
          '仮保存した質問を確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _currentConversation =
            savedConversation;
      });

      return;
    }

    if (currentConversation.responseStatus !=
        AiResponseStatus.draft) {
      return;
    }

    final updatedConversation =
        currentConversation.copyWith(
      userMessage: userMessage,
      aiPrompt: aiPrompt,
      updatedAt: now,
    );

    await _conversationRepository.update(
      updatedConversation,
    );

    final session =
        await _sessionRepository.findById(
      currentConversation.sessionId,
    );

    if (session != null) {
      await _sessionRepository.update(
        AiSession(
          sessionId: session.sessionId,
          projectId: session.projectId,
          title: _buildSessionTitle(
            userMessage,
          ),
          createdAt: session.createdAt,
          updatedAt: now,
        ),
      );
    }

    final savedConversation =
        await _conversationRepository.findById(
      currentConversation.conversationId,
    );

    if (savedConversation == null ||
        !mounted) {
      return;
    }

    setState(() {
      _currentConversation =
          savedConversation;
    });
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
 
    try {
      await _saveDraftConversation();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '質問を仮保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    } 
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

    final currentConversation =
        _currentConversation;

    if (currentConversation != null &&
        currentConversation.responseStatus ==
            AiResponseStatus.draft) {
      final updatedConversation =
          currentConversation.copyWith(
        userMessage: userMessage,
        aiPrompt: aiPrompt,
        responseStatus:
            AiResponseStatus.waiting,
        updatedAt: now,
      );

      try {
        await _conversationRepository.update(
          updatedConversation,
        );

        final session =
            await _sessionRepository.findById(
          currentConversation.sessionId,
        );

        if (session != null) {
          if (session.projectId != projectId) {
            await _sessionRepository.updateProjectId(
              sessionId: session.sessionId,
              projectId: projectId,
            );
          }

          await _sessionRepository.update(
            AiSession(
              sessionId: session.sessionId,
              projectId: projectId,
              title: _buildSessionTitle(
                userMessage,
              ),
              createdAt: session.createdAt,
              updatedAt: now,
            ),
          );
        }

        final savedConversation =
            await _conversationRepository.findById(
          currentConversation.conversationId,
        );

        if (savedConversation == null) {
          throw StateError(
            '保存したAI相談を確認できませんでした。',
          );
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _currentConversation =
              savedConversation;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '質問を保存しました。',
            ),
          ),
        );

        return;
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

        return;
      }
    }

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

      setState(() {
        _currentConversation =
            savedConversation;

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

  Future<void> _saveAiResponse() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSaving) {
      return;
    }

    final currentConversation =
        _currentConversation;

    if (currentConversation == null ||
        currentConversation.responseStatus !=
            AiResponseStatus.waiting) {
      return;
    }

    final aiResponse =
        _aiResponseController.text.trim();

    if (aiResponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AIからの回答を貼り付けてください。',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedConversation =
        currentConversation.copyWith(
      aiResponse: aiResponse,
      responseStatus:
          AiResponseStatus.received,
      updatedAt: DateTime.now(),
    );

    try {
      await _conversationRepository.update(
        updatedConversation,
      );

      final savedConversation =
          await _conversationRepository.findById(
        currentConversation.conversationId,
      );

      if (savedConversation == null) {
        throw StateError(
          '更新したAI相談を確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _currentConversation =
            savedConversation;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AIの回答を保存しました。',
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
            'AI回答を保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (didPop) {
          return;
        }

        final navigator =
            Navigator.of(context);

        final messenger =
            ScaffoldMessenger.of(context);

        try {
          await _saveDraftConversation();

          if (!mounted) {
            return;
          }

          setState(() {
            _allowPop = true;
          });

          navigator.pop();
        } catch (error) {
          if (!mounted) {
            return;
          }

          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '質問を仮保存できませんでした。\n'
                '$error',
              ),
            ),
          );
        }
      },
      child: Scaffold(
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
                            'AIに相談する',
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
                      'AIに聞きたいことを準備します。'
                      '質問は自由に入力することも、'
                      '作成アシストを使うこともできます。',                      
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
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: const Text(
                            '質問',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'AIへの質問',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'AIに聞きたい内容を'
                                  '入力してください。',
                                ),
                                const SizedBox(height: 16),

                                if (_currentConversation == null)
                                  SizedBox(
                                    height: 48,
                                    child: FilledButton.icon(
                                      onPressed: _openPromptAssist,
                                      icon: const Icon(
                                        Icons.auto_awesome_outlined,
                                      ),
                                      label: const Text(
                                        '質問を作成する',
                                      ),
                                    ),
                                  ),                               
                               
                                if (_originalQuestion != null &&
                                    _originalQuestion!
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  const Text(
                                    'あなたが考えたいこと',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    _originalQuestion!,
                                  ),
                                ],

                                const SizedBox(height: 20),
                                const Text(
                                  'AIに聞く内容',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '質問作成後の内容を'
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
                                        'AIに聞く内容を'
                                        'ここに入力します。',
                                    border:
                                        OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'AIに聞く内容を'
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
                                      '質問をコピーする',
                                    ),
                                  ),
                                ),

                                if (_currentConversation == null ||
                                    _currentConversation?.responseStatus ==
                                        AiResponseStatus.draft) ...[                              
                                  const SizedBox(height: 16),

                                  SizedBox(
                                    height: 52,
                                    child: FilledButton.icon(
                                      onPressed: _isSaving
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
                                ],                               
                              ],
                            ),
                          ],
                        ),
                      ),                    
                    
                      const SizedBox(height: 12),

                      Card(
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          title: const Text(
                            '回答',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            _currentConversation?.responseStatus ==
                                    AiResponseStatus.received
                                ? '回答保存済み'
                                : _currentConversation?.responseStatus ==
                                        AiResponseStatus.waiting
                                    ? '回答を入力できます'
                                    : 'まだ回答はありません',
                          ),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [
                            if (_currentConversation?.responseStatus ==
                                AiResponseStatus.waiting) ...[
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'AIから回答を受け取ったら、'
                                  'ここへ貼り付けてください。',
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextFormField(
                                controller:
                                    _aiResponseController,
                                minLines: 8,
                                maxLines: 16,
                                decoration:
                                    const InputDecoration(
                                  border:
                                      OutlineInputBorder(),
                                  hintText:
                                      'AIからの回答を'
                                      'ここに貼り付けます。',
                                  alignLabelWithHint: true,
                                ),
                              ),

                              const SizedBox(height: 16),

                              SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : _saveAiResponse,
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
                                          Icons.save_outlined,
                                        ),
                                  label: Text(
                                    _isSaving
                                        ? '保存しています...'
                                        : '回答を保存する',
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (_currentConversation
                                    ?.responseStatus ==
                                AiResponseStatus.received) ...[
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'AIからの回答を'
                                  '保存しました。',
                                ),
                              ),

                              const SizedBox(height: 12),

                              SelectableText(
                                _currentConversation!
                                    .aiResponse,
                              ),
                            ] else ...[
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '質問を保存すると、'
                                  'AIからの回答を'
                                  'ここに入力できるようになります。',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),                    
                      if (_currentConversation?.responseStatus ==
                          AiResponseStatus.received) ...[
                        const SizedBox(height: 16),

                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed:
                                _openReflectionScreen,
                            icon: const Icon(
                              Icons.auto_awesome_outlined,
                            ),
                            label: const Text(
                              '対話を整理する',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],                    
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
}
