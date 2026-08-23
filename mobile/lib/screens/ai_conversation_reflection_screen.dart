import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../models/knowledge_candidate.dart';
import '../models/knowledge_candidate_status.dart';
import '../models/knowledge_type.dart';
import '../models/new_question.dart';
import '../models/new_question_status.dart';
import '../models/reflection_queue_status.dart';
import '../repositories/reflection_queue_repository.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/ai_session_repository.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/knowledge_candidate_repository.dart';
import '../repositories/new_question_repository.dart';
import 'ai_chat_screen.dart';
import 'ai_conversation_knowledge_screen.dart';

class AiConversationReflectionScreen
    extends StatefulWidget {
  const AiConversationReflectionScreen({
    super.key,
    required this.conversation,
  });

  final AiConversation conversation;

  @override
  State<AiConversationReflectionScreen>
      createState() =>
          _AiConversationReflectionScreenState();
}

class _AiConversationReflectionScreenState
    extends State<AiConversationReflectionScreen> {
  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  final AiSessionRepository
      _sessionRepository =
      AiSessionRepository();

  final KnowledgeCandidateRepository
      _knowledgeCandidateRepository =
      KnowledgeCandidateRepository();

  final KnowledgeAssetRepository
      _knowledgeAssetRepository =
      KnowledgeAssetRepository();

  final NewQuestionRepository
      _newQuestionRepository =
      NewQuestionRepository();

  final ReflectionQueueRepository
      _reflectionQueueRepository =
      ReflectionQueueRepository();

  final Uuid _uuid = const Uuid();

  late final TextEditingController
      _summaryController;

  late final TextEditingController
      _candidateContentController;

  late final TextEditingController
      _candidateReasonController;

  late final TextEditingController
      _newQuestionContentController;

  late final TextEditingController
      _newQuestionReasonController;

  String _selectedSuggestedType =
      KnowledgeType.insight;

  bool _isSavingSummary = false;
  bool _isSavingCandidate = false;
  bool _isLoadingCandidates = true;
  bool _isUpdatingCandidateStatus = false;

  bool _isSavingNewQuestion = false;
  bool _isLoadingNewQuestions = true;
  bool _isUpdatingNewQuestionStatus = false;

  String? _openingCandidateId;
  String? _openingQuestionId;

  List<KnowledgeCandidate>
      _knowledgeCandidates = [];

  List<NewQuestion> _newQuestions = [];

  List<_ParsedNewQuestion>
      _parsedNewQuestions = [];

  int _currentNewQuestionIndex = 0;

  bool _isNewQuestionReviewCompleted = false;

  List<_ParsedKnowledgeCandidate>
      _parsedKnowledgeCandidates = [];

  int _currentKnowledgeCandidateIndex = 0;

  bool _isKnowledgeCandidateReviewCompleted = false;
 
  Set<String> _savedCandidateIds = {};

  String _extractMarkdownSection({
    required String source,
    required String startHeading,
    String? endHeading,
  }) {
    String normalizeHeading(String line) {
      var value = line.trim();

      value = value.replaceFirst(
        RegExp(r'^#+\s*'),
        '',
      );

      if (value.startsWith('**') &&
          value.endsWith('**') &&
          value.length >= 4) {
        value = value.substring(
          2,
          value.length - 2,
        );
      }

      value = value.trim();

      if (value.endsWith('：') ||
          value.endsWith(':')) {
        value = value.substring(
          0,
          value.length - 1,
        );
      }

      return value.trim();
    }

    final lines = source.split('\n');

    var startLine = -1;
    var endLine = lines.length;

    for (var i = 0; i < lines.length; i++) {
      final normalized =
          normalizeHeading(lines[i]);

      if (startLine == -1 &&
          normalized == startHeading) {
        startLine = i + 1;
        continue;
      }

      if (startLine != -1 &&
          endHeading != null &&
          normalized == endHeading) {
        endLine = i;
        break;
      }
    }

    if (startLine == -1) {
      return '';
    }

    return lines
        .sublist(
          startLine,
          endLine,
        )
        .join('\n')
        .trim();
  }

  List<_ParsedKnowledgeCandidate>
      _parseKnowledgeCandidates(
    String source,
  ) {
    final section =
        _extractMarkdownSection(
      source: source,
      startHeading: '知識候補',
      endHeading: '次に考える問い',
    );

    if (section.isEmpty ||
        section.trim() == 'なし') {
      return [];
    }

    String normalizeLine(String line) {
      var value = line.trim();

      value = value.replaceFirst(
        RegExp(r'^#+\s*'),
        '',
      );

      if (value.startsWith('**') &&
          value.endsWith('**') &&
          value.length >= 4) {
        value = value.substring(
          2,
          value.length - 2,
        );
      }

      return value.trim();
    }

    final lines = section.split('\n');

    final candidates =
        <_ParsedKnowledgeCandidate>[];

    var candidateStarted = false;
    var readingContent = false;
    var readingReason = false;

    final contentBuffer = StringBuffer();
    final reasonBuffer = StringBuffer();

    void saveCurrentCandidate() {
      if (!candidateStarted) {
        return;
      }

      final content =
          contentBuffer.toString().trim();

      final reason =
          reasonBuffer.toString().trim();

      if (content.isNotEmpty) {
        candidates.add(
          _ParsedKnowledgeCandidate(
            content: content,
            reason: reason,
          ),
        );
      }

      contentBuffer.clear();
      reasonBuffer.clear();

      readingContent = false;
      readingReason = false;
    }

    for (final rawLine in lines) {
      final line = normalizeLine(rawLine);

      if (RegExp(
        r'^知識候補\s*\d+$',
      ).hasMatch(line)) {
        saveCurrentCandidate();

        candidateStarted = true;
        readingContent = false;
        readingReason = false;

        continue;
      }

      if (!candidateStarted) {
        continue;
      }

      if (line == '内容:' ||
          line == '内容：') {
        readingContent = true;
        readingReason = false;
        continue;
      }

      if (line == '理由:' ||
          line == '理由：') {
        readingContent = false;
        readingReason = true;
        continue;
      }

      if (readingContent) {
        if (contentBuffer.isNotEmpty) {
          contentBuffer.writeln();
        }

        contentBuffer.write(line);
      } else if (readingReason) {
        if (reasonBuffer.isNotEmpty) {
          reasonBuffer.writeln();
        }

        reasonBuffer.write(line);
      }
    }

    saveCurrentCandidate();

    return candidates;
  }

  List<_ParsedNewQuestion>
      _parseNewQuestions(
    String source,
  ) {
    final section =
        _extractMarkdownSection(
      source: source,
      startHeading: '次に考える問い',
    );

    if (section.isEmpty ||
        section.trim() == 'なし') {
      return [];
    }

    String normalizeLine(String line) {
      var value = line.trim();

      value = value.replaceFirst(
        RegExp(r'^#+\s*'),
        '',
      );

      if (value.startsWith('**') &&
          value.endsWith('**') &&
          value.length >= 4) {
        value = value.substring(
          2,
          value.length - 2,
        );
      }

      return value.trim();
    }

    final lines = section.split('\n');

    final questions =
        <_ParsedNewQuestion>[];

    var readingContent = false;
    var readingReason = false;

    final contentBuffer = StringBuffer();
    final reasonBuffer = StringBuffer();

    void saveCurrentQuestion() {
      final content =
          contentBuffer.toString().trim();

      final reason =
          reasonBuffer.toString().trim();

      if (content.isNotEmpty) {
        questions.add(
          _ParsedNewQuestion(
            content: content,
            reason: reason,
          ),
        );
      }

      contentBuffer.clear();
      reasonBuffer.clear();

      readingContent = false;
      readingReason = false;
    }

    for (final rawLine in lines) {
      final line = normalizeLine(rawLine);

      if (RegExp(
        r'^問い\s*\d+$',
      ).hasMatch(line)) {
        saveCurrentQuestion();
        continue;
      }

      if (line == '内容:' ||
          line == '内容：') {
        readingContent = true;
        readingReason = false;
        continue;
      }

      if (line == '理由:' ||
          line == '理由：') {
        readingContent = false;
        readingReason = true;
        continue;
      }

      if (readingContent) {
        if (contentBuffer.isNotEmpty) {
          contentBuffer.writeln();
        }

        contentBuffer.write(line);
      } else if (readingReason) {
        if (reasonBuffer.isNotEmpty) {
          reasonBuffer.writeln();
        }

        reasonBuffer.write(line);
      }
    }

    saveCurrentQuestion();

    return questions;
  }

  @override
  void initState() {
    super.initState();

    final aiResponse =
        widget.conversation.aiResponse;

    final savedSummary =
        widget.conversation.summary.trim();

    final extractedSummary =
        savedSummary.isNotEmpty
            ? savedSummary
            : _extractMarkdownSection(
                source: aiResponse,
                startHeading: '要約',
                endHeading: '知識候補',
              );

    _parsedKnowledgeCandidates =
        _parseKnowledgeCandidates(
      aiResponse,
    );

    _isKnowledgeCandidateReviewCompleted =
        _parsedKnowledgeCandidates.isEmpty;

    _currentKnowledgeCandidateIndex = 0;

    final firstCandidate =
        _parsedKnowledgeCandidates.isNotEmpty
            ? _parsedKnowledgeCandidates[
                _currentKnowledgeCandidateIndex
              ]
            : null;   

    _parsedNewQuestions =
        _parseNewQuestions(
      aiResponse,
    );

    _isNewQuestionReviewCompleted =
        _parsedNewQuestions.isEmpty;

    _currentNewQuestionIndex = 0;

    final firstNewQuestion =
        _parsedNewQuestions.isNotEmpty
            ? _parsedNewQuestions[
                _currentNewQuestionIndex
              ]
            : null;   
   
    _summaryController =
        TextEditingController(
      text: extractedSummary,
    );

    _candidateContentController =
        TextEditingController(
      text: firstCandidate?.content ?? '',
    );

    _candidateReasonController =
        TextEditingController(
      text: firstCandidate?.reason ?? '',
    );

    _newQuestionContentController =
        TextEditingController(
      text: firstNewQuestion?.content ?? '',
    );

    _newQuestionReasonController =
        TextEditingController(
      text: firstNewQuestion?.reason ?? '',
    );

    _loadKnowledgeCandidates();
    _loadNewQuestions();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _candidateContentController.dispose();
    _candidateReasonController.dispose();
    _newQuestionContentController.dispose();
    _newQuestionReasonController.dispose();

    super.dispose();
  }

  Future<void> _loadKnowledgeCandidates() async {
    try {
      final candidates =
          await _knowledgeCandidateRepository
              .findByConversationId(
        widget.conversation.conversationId,
      );

      final savedCandidateIds = <String>{};

      for (final candidate in candidates) {
        if (candidate.status !=
            KnowledgeCandidateStatus.accepted) {
          continue;
        }

        final knowledge =
            await _knowledgeAssetRepository
                .findBySourceCandidateId(
          candidate.candidateId,
        );

        if (knowledge != null) {
          savedCandidateIds.add(
            candidate.candidateId,
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _knowledgeCandidates = candidates;
        _savedCandidateIds =
            savedCandidateIds;
        _isLoadingCandidates = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingCandidates = false;
      });
    }
  }

  Future<void> _loadNewQuestions() async {
    try {
      final questions =
          await _newQuestionRepository
              .findByConversationId(
        widget.conversation.conversationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _newQuestions = questions;
        _isLoadingNewQuestions = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingNewQuestions = false;
      });
    }
  }

  Future<void> _completeReflectionIfReady() async {
    if (!_isKnowledgeCandidateReviewCompleted ||
        !_isNewQuestionReviewCompleted) {
      return;
    }

    await _conversationRepository
        .updateResponseStatus(
      conversationId:
          widget.conversation.conversationId,
      responseStatus:
          AiResponseStatus.organized,
    );

    final updatedConversation =
        await _conversationRepository.findById(
      widget.conversation.conversationId,
    );

    if (updatedConversation == null ||
        updatedConversation.responseStatus !=
            AiResponseStatus.organized) {
      throw StateError(
        'AI相談の整理状態を更新できませんでした。',
      );
    }

    final reflectionQueue =
        await _reflectionQueueRepository
            .findByConversationId(
      widget.conversation.conversationId,
    );

    if (reflectionQueue != null) {
      await _reflectionQueueRepository
          .updateStatus(
        queueId: reflectionQueue.queueId,
        status:
            ReflectionQueueStatus.completed,
      );
    }
  }

  Future<void> _saveSummary() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSavingSummary) {
      return;
    }

    final summary =
        _summaryController.text.trim();

    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '要約を入力してください。',
          ),
        ),
      );

      return;
    }

  
  
  
  
    setState(() {
      _isSavingSummary = true;
    });

    try {
      await _conversationRepository.updateSummary(
        conversationId:
            widget.conversation.conversationId,
        summary: summary,
      );

      final savedConversation =
          await _conversationRepository.findById(
        widget.conversation.conversationId,
      );

      if (savedConversation == null ||
          savedConversation.summary != summary) {
        throw StateError(
          '保存した要約を確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      await _completeReflectionIfReady();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingSummary = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '要約を保存しました。',
          ),
        ),
      );     
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingSummary = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '要約を保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  void _moveToNextKnowledgeCandidate() {
    if (_parsedKnowledgeCandidates.isEmpty) {
      return;
    }

    final nextIndex =
        _currentKnowledgeCandidateIndex + 1;

    if (nextIndex >=
        _parsedKnowledgeCandidates.length) {
     
      setState(() {
        _isKnowledgeCandidateReviewCompleted =
            true;

        _candidateContentController.clear();
        _candidateReasonController.clear();
      });

      _completeReflectionIfReady();

      return;     
    }

    final nextCandidate =
        _parsedKnowledgeCandidates[nextIndex];

    setState(() {
      _currentKnowledgeCandidateIndex =
          nextIndex;

      _selectedSuggestedType =
          KnowledgeType.insight;

      _candidateContentController.text =
          nextCandidate.content;

      _candidateReasonController.text =
          nextCandidate.reason;
    });
  } 
 
  Future<void> _saveKnowledgeCandidate() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSavingCandidate) {
      return;
    }

    final content =
        _candidateContentController.text.trim();

    final reason =
        _candidateReasonController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '知識候補を入力してください。',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSavingCandidate = true;
    });

    try {
      final now = DateTime.now();

      final candidate =
          KnowledgeCandidate(
        candidateId: _uuid.v4(),
        conversationId:
            widget.conversation.conversationId,
        content: content,
        suggestedType:
            _selectedSuggestedType,
        reason: reason,
        sourceExcerpt: null,
        status:
            KnowledgeCandidateStatus.candidate,
        createdAt: now,
        updatedAt: now,
      );

      await _knowledgeCandidateRepository.insert(
        candidate,
      );

      final savedCandidate =
          await _knowledgeCandidateRepository
              .findById(
        candidate.candidateId,
      );

      if (savedCandidate == null) {
        throw StateError(
          '保存した知識候補を'
          '確認できませんでした。',
        );
      }

      await _loadKnowledgeCandidates();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingCandidate = false;
      });

      _moveToNextKnowledgeCandidate();     
     
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '知識候補を保存しました。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingCandidate = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '知識候補を保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  void _moveToNextNewQuestion() {
    if (_parsedNewQuestions.isEmpty) {
      return;
    }

    final nextIndex =
        _currentNewQuestionIndex + 1;

    if (nextIndex >=
        _parsedNewQuestions.length) {
    
      setState(() {
        _isNewQuestionReviewCompleted =
            true;

        _newQuestionContentController.clear();
        _newQuestionReasonController.clear();
      });

      _completeReflectionIfReady();

      return;    
    }

    final nextQuestion =
        _parsedNewQuestions[nextIndex];

    setState(() {
      _currentNewQuestionIndex =
          nextIndex;

      _newQuestionContentController.text =
          nextQuestion.content;

      _newQuestionReasonController.text =
          nextQuestion.reason;
    });
  }

  Future<void> _saveNewQuestion() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSavingNewQuestion) {
      return;
    }

    final content =
        _newQuestionContentController.text.trim();

    final reason =
        _newQuestionReasonController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '次に考える問いを入力してください。',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSavingNewQuestion = true;
    });

    try {
      final now = DateTime.now();

      final question = NewQuestion(
        questionId: _uuid.v4(),
        conversationId:
            widget.conversation.conversationId,
        content: content,
        reason: reason,
        status:
            NewQuestionStatus.candidate,
        createdAt: now,
        updatedAt: now,
      );

      await _newQuestionRepository.insert(
        question,
      );

      final savedQuestion =
          await _newQuestionRepository.findById(
        question.questionId,
      );

      if (savedQuestion == null) {
        throw StateError(
          '保存した次に考える問いを'
          '確認できませんでした。',
        );
      }

      await _loadNewQuestions();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingNewQuestion = false;
      });

      _moveToNextNewQuestion();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '次に考える問いを保存しました。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingNewQuestion = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '次に考える問いを保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void> _updateKnowledgeCandidateStatus({
    required KnowledgeCandidate candidate,
    required String status,
  }) async {
    if (_isUpdatingCandidateStatus) {
      return;
    }

    setState(() {
      _isUpdatingCandidateStatus = true;
    });

    try {
      await _knowledgeCandidateRepository
          .updateStatus(
        candidateId: candidate.candidateId,
        status: status,
      );

      final updatedCandidate =
          await _knowledgeCandidateRepository
              .findById(
        candidate.candidateId,
      );

      if (updatedCandidate == null ||
          updatedCandidate.status != status) {
        throw StateError(
          '知識候補の状態を'
          '更新できませんでした。',
        );
      }

      await _loadKnowledgeCandidates();

      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingCandidateStatus = false;
      });

      final message =
          status ==
                  KnowledgeCandidateStatus
                      .accepted
              ? '「知識にする」を選択しました。'
              : '知識候補を見送りました。';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingCandidateStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '知識候補の状態を'
            '変更できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void> _updateNewQuestionStatus({
    required NewQuestion question,
    required String status,
  }) async {
    if (_isUpdatingNewQuestionStatus) {
      return;
    }

    setState(() {
      _isUpdatingNewQuestionStatus = true;
    });

    try {
      await _newQuestionRepository.updateStatus(
        questionId: question.questionId,
        status: status,
      );

      final updatedQuestion =
          await _newQuestionRepository.findById(
        question.questionId,
      );

      if (updatedQuestion == null ||
          updatedQuestion.status != status) {
        throw StateError(
          '次に考える問いの状態を'
          '更新できませんでした。',
        );
      }

      await _loadNewQuestions();

      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingNewQuestionStatus = false;
      });

      final message =
          status == NewQuestionStatus.adopted
              ? '「この問いを次に考える」を選択しました。'
              : '次に考える問いを見送りました。';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingNewQuestionStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '次に考える問いの状態を'
            '変更できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void> _openKnowledgeScreen(
    KnowledgeCandidate candidate,
  ) async {
    if (_openingCandidateId != null) {
      return;
    }

    setState(() {
      _openingCandidateId =
          candidate.candidateId;
    });

    try {
      final wasSaved =
          await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) =>
              AiConversationKnowledgeScreen(
            conversation:
                widget.conversation,
            candidate: candidate,
          ),
        ),
      );

      await _loadKnowledgeCandidates();

      if (!mounted) {
        return;
      }

      if (wasSaved == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              '知識として保存しました。',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingCandidateId = null;
        });
      }
    }
  }

  Future<void> _openNewQuestionInAiChat(
    NewQuestion question,
  ) async {
    if (_openingQuestionId != null) {
      return;
    }

    setState(() {
      _openingQuestionId =
          question.questionId;
    });

    try {
      final session =
          await _sessionRepository.findById(
        widget.conversation.sessionId,
      );

      if (session == null) {
        throw StateError(
          '元のAI相談のSessionを'
          '確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => AiChatScreen(
            initialQuestion:
                question.content,
            initialProjectId:
                session.projectId,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '次のAI相談を'
            '開けませんでした。\n'
            '$error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingQuestionId = null;
        });
      }
    }
  }

  String _candidateStatusName(
    KnowledgeCandidate candidate,
  ) {
    if (candidate.status ==
            KnowledgeCandidateStatus.accepted &&
        _savedCandidateIds.contains(
          candidate.candidateId,
        )) {
      return '知識として保存済み';
    }

    if (candidate.status ==
        KnowledgeCandidateStatus.accepted) {
      return '知識化を選択済み';
    }

    return KnowledgeCandidateStatus.displayName(
      candidate.status,
    );
  }

  String _newQuestionStatusName(
    NewQuestion question,
  ) {
    if (question.status ==
        NewQuestionStatus.adopted) {
      return '次に考えることを選択済み';
    }

    return NewQuestionStatus.displayName(
      question.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation =
        widget.conversation;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI回答を整理する',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(24),
          children: [
            const Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.psychology_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '回答から次の知識を見つける',
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
              'AIから受け取った回答を振り返り、'
              '要約・知識候補・'
              '次に考える問いへ整理します。',
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
                      '元の質問',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      conversation.userMessage,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: ExpansionTile(
                title: const Text(
                  'AIからの回答',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  conversation.aiProvider.isEmpty
                      ? 'AI：未入力'
                      : 'AI：${conversation.aiProvider}',
                ),
                childrenPadding:
                    const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      conversation.aiResponse,
                    ),
                  ),
                ],
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
                      '要約',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'この回答の重要な内容を'
                      '短く整理します。',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller:
                          _summaryController,
                      minLines: 4,
                      maxLines: 10,
                      decoration:
                          const InputDecoration(
                        border:
                            OutlineInputBorder(),
                        hintText:
                            'AI回答の要点を'
                            '入力してください。',
                        alignLabelWithHint:
                            true,
                      ),
                    ),
                    const SizedBox(height: 16),
                  
                    FilledButton.icon(
                      onPressed:
                          _isSavingSummary
                              ? null
                              : _saveSummary,
                      icon: _isSavingSummary
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
                        _isSavingSummary
                            ? '保存しています...'
                            : 'この要約を保存する',
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
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
                  
                    if (_isKnowledgeCandidateReviewCompleted) ...[
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '知識候補の整理が終わりました',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'AIが提案した知識候補について、'
                        '残すか残さないかの判断が'
                        '終わりました。',
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'あなたが「残す」と判断した'
                        '知識は保存されています。',
                      ),

                      const SizedBox(height: 20),

                      const Divider(),

                      const SizedBox(height: 20),

                      const Text(
                        '次は、この対話から生まれた'
                        '「次に考える問い」を'
                        '整理します。',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ] else ...[
                      const Text(
                        '知識候補',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _parsedKnowledgeCandidates.isEmpty
                            ? '知識候補はありません。'
                            : '知識候補 '
                                '${_currentKnowledgeCandidateIndex + 1}'
                                ' / '
                                '${_parsedKnowledgeCandidates.length}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'AIが回答から見つけた候補です。'
                        '内容と理由を確認してください。',
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '内容',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller:
                            _candidateContentController,
                        minLines: 3,
                        maxLines: 8,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                          hintText:
                              '知識候補の内容',
                          alignLabelWithHint:
                              true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '残す理由',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller:
                            _candidateReasonController,
                        minLines: 2,
                        maxLines: 5,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                          hintText:
                              'この候補を残す理由',
                          alignLabelWithHint:
                              true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '種類',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        initialValue:
                            _selectedSuggestedType,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                        ),
                        items: KnowledgeType.values
                            .cast<String>()
                            .map(
                              (type) =>
                                  DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  KnowledgeType
                                      .displayName(
                                    type,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedSuggestedType =
                                value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'この知識を残しますか？',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child:
                                FilledButton.icon(
                              onPressed:
                                  _isSavingCandidate
                                      ? null
                                      : _saveKnowledgeCandidate,
                              icon: _isSavingCandidate
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .check_outlined,
                                    ),
                              label: Text(
                                _isSavingCandidate
                                    ? '保存しています...'
                                    : '残す',
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  _isSavingCandidate
                                      ? null
                                      : _moveToNextKnowledgeCandidate,
                              icon: const Icon(
                                Icons.close_outlined,
                              ),
                              label: const Text(
                                '残さない',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],                  

                    if (_isLoadingCandidates)
                      const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    else if (_knowledgeCandidates
                        .isEmpty)
                      const Text(
                        '保存された知識候補は'
                        'まだありません。',
                      )
                    else
                      ..._knowledgeCandidates.map(
                        (candidate) {
                          final isCandidate =
                              candidate.status ==
                                  KnowledgeCandidateStatus
                                      .candidate;

                          final isAccepted =
                              candidate.status ==
                                  KnowledgeCandidateStatus
                                      .accepted;

                          final isSavedAsKnowledge =
                              _savedCandidateIds.contains(
                            candidate.candidateId,
                          );

                          final isOpening =
                              _openingCandidateId ==
                                  candidate.candidateId;

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch,
                                children: [
                                  Text(
                                    candidate.content,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Type：'
                                    '${KnowledgeType.displayName(candidate.suggestedType)}',
                                  ),
                                  if (candidate
                                      .reason
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      '理由：'
                                      '${candidate.reason}',
                                    ),
                                  ],
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    '状態：'
                                    '${_candidateStatusName(candidate)}',
                                    style:
                                        Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                  ),
                                  if (isCandidate) ...[
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    FilledButton.icon(
                                      onPressed:
                                          _isUpdatingCandidateStatus
                                              ? null
                                              : () {
                                                  _updateKnowledgeCandidateStatus(
                                                    candidate:
                                                        candidate,
                                                    status:
                                                        KnowledgeCandidateStatus.accepted,
                                                  );
                                                },
                                      icon: const Icon(
                                        Icons
                                            .check_circle_outline,
                                      ),
                                      label:
                                          const Text(
                                        '知識にする',
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    OutlinedButton.icon(
                                      onPressed:
                                          _isUpdatingCandidateStatus
                                              ? null
                                              : () {
                                                  _updateKnowledgeCandidateStatus(
                                                    candidate:
                                                        candidate,
                                                    status:
                                                        KnowledgeCandidateStatus.rejected,
                                                  );
                                                },
                                      icon: const Icon(
                                        Icons
                                            .do_not_disturb_alt_outlined,
                                      ),
                                      label:
                                          const Text(
                                        '見送る',
                                      ),
                                    ),
                                  ],
                                  if (isAccepted &&
                                      !isSavedAsKnowledge) ...[
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    FilledButton.icon(
                                      onPressed:
                                          isOpening
                                              ? null
                                              : () {
                                                  _openKnowledgeScreen(
                                                    candidate,
                                                  );
                                                },
                                      icon: isOpening
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .lightbulb_outline,
                                            ),
                                      label: Text(
                                        isOpening
                                            ? '開いています...'
                                            : '知識を確認・保存する',
                                      ),
                                    ),
                                  ],
                                  if (isAccepted &&
                                      isSavedAsKnowledge) ...[
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .check_circle_outline,
                                        ),
                                        SizedBox(
                                          width: 8,
                                        ),
                                        Expanded(
                                          child: Text(
                                            '正式な知識として'
                                            '保存されています。',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
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
                  
                    if (_isNewQuestionReviewCompleted) ...[
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '次に考える問いの整理が終わりました',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'AIが提案した問いについて、'
                        '残すか残さないかの判断が'
                        '終わりました。',
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'あなたが「残す」と判断した'
                        '問いは保存されています。',
                      ),

                      const SizedBox(height: 20),
                    ] else ...[
                      const Text(
                        '次に考える問い',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _parsedNewQuestions.isEmpty
                            ? '次に考える問いはありません。'
                            : '次に考える問い '
                                '${_currentNewQuestionIndex + 1}'
                                ' / '
                                '${_parsedNewQuestions.length}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'AIがこの対話から見つけた問いです。'
                        '内容と理由を確認してください。',
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '内容',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller:
                            _newQuestionContentController,
                        minLines: 3,
                        maxLines: 8,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                          hintText:
                              '次に考える問いの内容',
                          alignLabelWithHint:
                              true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '残す理由',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller:
                            _newQuestionReasonController,
                        minLines: 2,
                        maxLines: 5,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                          hintText:
                              'この問いを次に考える理由',
                          alignLabelWithHint:
                              true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'この問いを残しますか？',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child:
                                FilledButton.icon(
                              onPressed:
                                  _isSavingNewQuestion
                                      ? null
                                      : _saveNewQuestion,
                              icon: _isSavingNewQuestion
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .check_outlined,
                                    ),
                              label: Text(
                                _isSavingNewQuestion
                                    ? '保存しています...'
                                    : '残す',
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  _isSavingNewQuestion
                                      ? null
                                      : _moveToNextNewQuestion,
                              icon: const Icon(
                                Icons.close_outlined,
                              ),
                              label: const Text(
                                '残さない',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],                 
                   
                    if (_isLoadingNewQuestions)
                      const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    else if (_newQuestions.isEmpty)
                      const Text(
                        '保存された次に考える問いは'
                        'まだありません。',
                      )
                    else
                      ..._newQuestions.map(
                        (question) {
                          final isCandidate =
                              question.status ==
                                  NewQuestionStatus
                                      .candidate;

                          final isAdopted =
                              question.status ==
                                  NewQuestionStatus
                                      .adopted;

                          final isOpeningQuestion =
                              _openingQuestionId ==
                                  question.questionId;

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch,
                                children: [
                                  Text(
                                    question.content,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  if (question
                                      .reason
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      '理由：'
                                      '${question.reason}',
                                    ),
                                  ],
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    '状態：'
                                    '${_newQuestionStatusName(question)}',
                                    style:
                                        Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                  ),
                                  if (isCandidate) ...[
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    FilledButton.icon(
                                      onPressed:
                                          _isUpdatingNewQuestionStatus
                                              ? null
                                              : () {
                                                  _updateNewQuestionStatus(
                                                    question:
                                                        question,
                                                    status:
                                                        NewQuestionStatus.adopted,
                                                  );
                                                },
                                      icon: const Icon(
                                        Icons
                                            .arrow_forward_outlined,
                                      ),
                                      label:
                                          const Text(
                                        'この問いを次に考える',
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    OutlinedButton.icon(
                                      onPressed:
                                          _isUpdatingNewQuestionStatus
                                              ? null
                                              : () {
                                                  _updateNewQuestionStatus(
                                                    question:
                                                        question,
                                                    status:
                                                        NewQuestionStatus.dismissed,
                                                  );
                                                },
                                      icon: const Icon(
                                        Icons
                                            .do_not_disturb_alt_outlined,
                                      ),
                                      label:
                                          const Text(
                                        '見送る',
                                      ),
                                    ),
                                  ],
                                  if (isAdopted) ...[
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    FilledButton.icon(
                                      onPressed:
                                          isOpeningQuestion
                                              ? null
                                              : () {
                                                  _openNewQuestionInAiChat(
                                                    question,
                                                  );
                                                },
                                      icon: isOpeningQuestion
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .chat_bubble_outline,
                                            ),
                                      label: Text(
                                        isOpeningQuestion
                                            ? '開いています...'
                                            : 'この問いでAIと考える',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
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
class _ParsedKnowledgeCandidate {
  const _ParsedKnowledgeCandidate({
    required this.content,
    required this.reason,
  });

  final String content;
  final String reason;
}

class _ParsedNewQuestion {
  const _ParsedNewQuestion({
    required this.content,
    required this.reason,
  });

  final String content;
  final String reason;
}

