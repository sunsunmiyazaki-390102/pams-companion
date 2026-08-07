import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../models/knowledge_asset.dart';
import '../models/knowledge_type.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/knowledge_asset_repository.dart';

class AiConversationKnowledgeScreen
    extends StatefulWidget {
  const AiConversationKnowledgeScreen({
    super.key,
    required this.conversation,
  });

  final AiConversation conversation;

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

  final Uuid _uuid = const Uuid();

  late final TextEditingController
      _knowledgeContentController;

  String _selectedKnowledgeType =
      KnowledgeType.insight;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _knowledgeContentController =
        TextEditingController(
      text: widget.conversation.aiResponse,
    );
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
      final existingKnowledge =
          await _knowledgeRepository
              .findByConversationId(
        widget.conversation.conversationId,
      );

      if (existingKnowledge == null) {
        final now = DateTime.now();
        final knowledgeId = _uuid.v4();

        final knowledge = KnowledgeAsset(
          knowledgeId: knowledgeId,
          sessionId:
              widget.conversation.sessionId,
          conversationId:
              widget.conversation.conversationId,
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
            '保存したKnowledgeを'
            '確認できませんでした。',
          );
        }
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
          'AI相談の整理状態を'
          '更新できませんでした。',
        );
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
          // 次回の重複確認で復旧する。
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
            'Knowledgeを保存できませんでした。\n'
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Knowledgeとして整理',
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
                      'Knowledgeを育てる',
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
                'AIとの対話を振り返り、'
                '自分のKnowledgeとして'
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
                        'Knowledgeとして残す内容',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AIの回答をそのまま'
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
                              '自分のKnowledgeとして'
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
                            return 'Knowledgeとして'
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
                        'Knowledge Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'このKnowledgeが'
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
                      : 'Knowledgeとして保存する',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
