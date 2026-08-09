import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_conversation.dart';
import '../models/knowledge_candidate.dart';
import '../models/knowledge_candidate_status.dart';
import '../models/knowledge_type.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/knowledge_candidate_repository.dart';
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

  final KnowledgeCandidateRepository
      _knowledgeCandidateRepository =
      KnowledgeCandidateRepository();

  final KnowledgeAssetRepository
      _knowledgeAssetRepository =
      KnowledgeAssetRepository();

  final Uuid _uuid = const Uuid();

  late final TextEditingController
      _summaryController;

  late final TextEditingController
      _candidateContentController;

  late final TextEditingController
      _candidateReasonController;

  String _selectedSuggestedType =
      KnowledgeType.insight;

  bool _isSavingSummary = false;
  bool _isSavingCandidate = false;
  bool _isLoadingCandidates = true;
  bool _isUpdatingCandidateStatus = false;

  String? _openingCandidateId;

  List<KnowledgeCandidate>
      _knowledgeCandidates = [];

  Set<String> _savedCandidateIds = {};

  @override
  void initState() {
    super.initState();

    _summaryController =
        TextEditingController(
      text: widget.conversation.summary,
    );

    _candidateContentController =
        TextEditingController();

    _candidateReasonController =
        TextEditingController();

    _loadKnowledgeCandidates();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _candidateContentController.dispose();
    _candidateReasonController.dispose();

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
            'Knowledge候補を入力してください。',
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
          '保存したKnowledge候補を'
          '確認できませんでした。',
        );
      }

      _candidateContentController.clear();
      _candidateReasonController.clear();

      await _loadKnowledgeCandidates();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingCandidate = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Knowledge候補を保存しました。',
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
            'Knowledge候補を保存できませんでした。\n'
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
          'Knowledge候補の状態を'
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
              ? '「Knowledgeにする」を選択しました。'
              : 'Knowledge候補を見送りました。';

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
            'Knowledge候補の状態を'
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
              'Knowledgeとして保存しました。',
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

  String _candidateStatusName(
    KnowledgeCandidate candidate,
  ) {
    if (candidate.status ==
            KnowledgeCandidateStatus.accepted &&
        _savedCandidateIds.contains(
          candidate.candidateId,
        )) {
      return 'Knowledge保存済み';
    }

    if (candidate.status ==
        KnowledgeCandidateStatus.accepted) {
      return 'Knowledge化を選択済み';
    }

    return KnowledgeCandidateStatus.displayName(
      candidate.status,
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
              '要約・Knowledge候補・'
              '新しい問いへ整理します。',
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
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'AIからの回答',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          conversation
                                  .aiProvider
                                  .isEmpty
                              ? 'AI：未入力'
                              : 'AI：'
                                  '${conversation.aiProvider}',
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      conversation.aiResponse,
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
                            : '要約を保存する',
                      ),
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
                    const Text(
                      'Knowledge候補',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'この回答から、自分の知識として'
                      '残したい内容を候補として追加します。',
                    ),

                    const SizedBox(height: 12),

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
                            'Knowledge候補を'
                            '入力してください。',
                        alignLabelWithHint:
                            true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '提案Type',
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

                    TextFormField(
                      controller:
                          _candidateReasonController,
                      minLines: 2,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(
                        border:
                            OutlineInputBorder(),
                        labelText:
                            '候補にした理由',
                        hintText:
                            'なぜ残す価値があるか'
                            '入力してください。',
                        alignLabelWithHint:
                            true,
                      ),
                    ),

                    const SizedBox(height: 16),

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
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.add_outlined,
                            ),
                      label: Text(
                        _isSavingCandidate
                            ? '保存しています...'
                            : 'Knowledge候補を追加する',
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_isLoadingCandidates)
                      const Center(
                        child:
                            CircularProgressIndicator(),
                      )
                    else if (_knowledgeCandidates
                        .isEmpty)
                      const Text(
                        '保存されたKnowledge候補は'
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
                                        'Knowledgeにする',
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
                                            : 'Knowledgeを確認・保存する',
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
                                            '正式なKnowledgeとして'
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

            const SizedBox(height: 16),

            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '新しい問い',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '次のStepで、'
                      'この回答から生まれた'
                      '新しい問いを追加できるようにします。',
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
