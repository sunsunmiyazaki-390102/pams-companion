import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../models/knowledge_asset.dart';
import '../models/knowledge_candidate.dart';
import '../models/knowledge_type.dart';
import '../models/reflection_queue_status.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/knowledge_asset_repository.dart';
import '../repositories/reflection_queue_repository.dart';

class AiConversationKnowledgeScreen
    extends StatefulWidget {
  const AiConversationKnowledgeScreen({
    super.key,
    required this.conversation,
    this.candidate,
  });

  final AiConversation conversation;

  // Knowledge Candidate経由の場合だけ指定する。
  // nullの場合は従来どおり、
  // AI回答から直接Knowledgeを作る。
  final KnowledgeCandidate? candidate;

  @override
  State<AiConversationKnowledgeScreen>
      createState() =>
          _AiConversationKnowledgeScreenState();
}

class _AiConversationKnowledgeScreenState
    extends State<AiConversationKnowledgeScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final KnowledgeAssetRepository
      _knowledgeRepository =
      KnowledgeAssetRepository();

  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  final ReflectionQueueRepository
      _reflectionQueueRepository =
      ReflectionQueueRepository();

  final Uuid _uuid = const Uuid();

  late final TextEditingController
      _knowledgeContentController;

  late String _selectedKnowledgeType;

  bool _isSaving = false;

  bool get _isCandidateMode =>
      widget.candidate != null;

  @override
  void initState() {
    super.initState();

    final candidate = widget.candidate;

    _knowledgeContentController =
        TextEditingController(
      text: candidate?.content ??
          widget.conversation.aiResponse,
    );

    _selectedKnowledgeType =
        candidate?.suggestedType ??
            KnowledgeType.insight;
  }

  @override
  void dispose() {
    _knowledgeContentController.dispose();

    super.dispose();
  }

  Future<void> _saveKnowledge() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String? insertedKnowledgeId;

    try {
      final candidate = widget.candidate;

      KnowledgeAsset? existingKnowledge;

      if (candidate != null) {
        // Candidate経由では、
        // 同じ候補からKnowledgeが
        // 二重作成されないことを確認する。
        existingKnowledge =
            await _knowledgeRepository
                .findBySourceCandidateId(
          candidate.candidateId,
        );
      } else {
        // 従来経路では、
        // 1 Conversation = 1 Knowledge
        // の旧仕様を維持する。
        existingKnowledge =
            await _knowledgeRepository
                .findByConversationId(
          widget.conversation.conversationId,
        );
      }

      if (existingKnowledge != null) {
        throw StateError(
          _isCandidateMode
              ? 'この知識候補は'
                  'すでに知識として'
                  '保存されています。'
              : 'このAI相談は'
                  'すでに知識として'
                  '保存されています。',
        );
      }

      final now = DateTime.now();
      final knowledgeId = _uuid.v4();

      final knowledge = KnowledgeAsset(
        knowledgeId: knowledgeId,
        sessionId:
            widget.conversation.sessionId,
        conversationId:
            widget.conversation.conversationId,
        sourceCandidateId:
            candidate?.candidateId,
        knowledgeType:
            _selectedKnowledgeType,
        content:
            _knowledgeContentController
                .text
                .trim(),
        createdAt: now,
        updatedAt: now,
      );

      await _knowledgeRepository.insert(
        knowledge,
      );

      insertedKnowledgeId = knowledgeId;

      final savedKnowledge =
          await _knowledgeRepository.findById(
        knowledgeId,
      );

      if (savedKnowledge == null) {
        throw StateError(
          '保存した知識を'
          '確認できませんでした。',
        );
      }

      if (candidate != null &&
          savedKnowledge.sourceCandidateId !=
              candidate.candidateId) {
        throw StateError(
          '知識候補との関連を'
          '確認できませんでした。',
        );
      }

      // 従来経路の場合だけ、
      // Conversation全体をorganizedにする。
      //
      // Candidate経由では複数候補や
      // New Questionが残る可能性があるため、
      // 1件保存しただけでは
      // Conversation全体をorganizedにしない。
      if (!_isCandidateMode) {
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
            'AI相談の整理状態を'
            '更新できませんでした。',
          );
        }
      }

      if (!_isCandidateMode) {
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

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (insertedKnowledgeId != null) {
        try {
          await _knowledgeRepository.delete(
            insertedKnowledgeId,
          );
        } catch (_) {
          // ロールバック失敗時は、
          // source_candidate_idの
          // UNIQUE制約などで重複を防ぐ。
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '知識を保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation =
        widget.conversation;

    final candidate =
        widget.candidate;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '知識として整理',
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
                      Icons.lightbulb_outline,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '知識を育てる',
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

              Text(
                _isCandidateMode
                    ? '選択した知識候補を確認し、'
                        '必要に応じて編集してから'
                        '正式な知識として保存します。'
                    : 'AIとの対話を振り返り、'
                        '自分の知識として'
                        '残したい内容を整理します。',
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
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
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'AIからの回答',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
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

              if (candidate != null) ...[
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
                          '選択した知識候補',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        SelectableText(
                          candidate.content,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          '提案Type：'
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
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      const Text(
                        '知識として残す内容',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _isCandidateMode
                            ? '候補の内容を確認し、'
                                '自分の知識として'
                                '残したい文章へ'
                                '編集してください。'
                            : 'AIの回答をそのまま'
                                '保存する必要はありません。'
                                '自分にとって重要な内容へ'
                                '編集してください。',
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller:
                            _knowledgeContentController,
                        minLines: 8,
                        maxLines: 20,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                          hintText:
                              '自分の知識として'
                              '残したい内容を'
                              '入力してください。',
                          alignLabelWithHint:
                              true,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return '知識として'
                                '残す内容を'
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
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      const Text(
                        '知識の種類',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'この知識が'
                        'どの種類に近いか'
                        '選択してください。',
                      ),

                      const SizedBox(height: 12),

                      RadioGroup<String>(
                        groupValue:
                            _selectedKnowledgeType,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedKnowledgeType =
                                value;
                          });
                        },
                        child: Column(
                          children: [
                            ...KnowledgeType.values
                                .cast<String>()
                                .map(
                              (type) =>
                                  RadioListTile<
                                      String>(
                                value: type,
                                title: Text(
                                  KnowledgeType
                                      .displayName(
                                    type,
                                  ),
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

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _isSaving
                    ? null
                    : _saveKnowledge,
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
                      : '知識として保存する',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
