import 'package:flutter/material.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../repositories/ai_conversation_repository.dart';
import 'ai_conversation_knowledge_screen.dart';

class AiConversationDetailScreen
    extends StatefulWidget {
  const AiConversationDetailScreen({
    super.key,
    required this.conversation,
  });

  final AiConversation conversation;

  @override
  State<AiConversationDetailScreen>
      createState() =>
          _AiConversationDetailScreenState();
}

class _AiConversationDetailScreenState
    extends State<AiConversationDetailScreen> {
  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  late AiConversation _conversation;

  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();

    _conversation = widget.conversation;
  }

  String _formatDateTime(
    DateTime dateTime,
  ) {
    final localDateTime =
        dateTime.toLocal();

    final year =
        localDateTime.year.toString();

    final month = localDateTime.month
        .toString()
        .padLeft(2, '0');

    final day = localDateTime.day
        .toString()
        .padLeft(2, '0');

    final hour = localDateTime.hour
        .toString()
        .padLeft(2, '0');

    final minute = localDateTime.minute
        .toString()
        .padLeft(2, '0');

    return '$year/$month/$day '
        '$hour:$minute';
  }

  IconData _statusIcon(
    String status,
  ) {
    switch (status) {
      case AiResponseStatus.deferred:
        return Icons.schedule_outlined;

      case AiResponseStatus.organized:
        return Icons.check_circle_outline;

      case AiResponseStatus.received:
      default:
        return Icons.inbox_outlined;
    }
  }

  Future<void> _openKnowledgeScreen() async {
    final wasOrganized =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            AiConversationKnowledgeScreen(
          conversation: _conversation,
        ),
      ),
    );

    if (!mounted ||
        wasOrganized != true) {
      return;
    }

    final updatedConversation =
        await _conversationRepository.findById(
      _conversation.conversationId,
    );

    if (updatedConversation == null ||
        !mounted) {
      return;
    }

    setState(() {
      _conversation =
          updatedConversation;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Knowledgeとして保存しました。',
        ),
      ),
    );
  }

  Future<void> _deferConversation() async {
    if (_isUpdatingStatus) {
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _conversationRepository
          .updateResponseStatus(
        conversationId:
            _conversation.conversationId,
        responseStatus:
            AiResponseStatus.deferred,
      );

      final updatedConversation =
          await _conversationRepository.findById(
        _conversation.conversationId,
      );

      if (updatedConversation == null) {
        throw StateError(
          '更新したAI相談を確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _conversation =
            updatedConversation;
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '「あとで整理」に変更しました。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '整理状態を変更できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusName =
        AiResponseStatus.displayName(
      _conversation.responseStatus,
    );

    final formattedCreatedAt =
        _formatDateTime(
      _conversation.createdAt,
    );

    final formattedUpdatedAt =
        _formatDateTime(
      _conversation.updatedAt,
    );

    final canDefer =
        _conversation.responseStatus ==
            AiResponseStatus.received;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI相談詳細',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    _statusIcon(
                      _conversation
                          .responseStatus,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '保存したAI相談',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                    _DetailRow(
                      label: '利用したAI',
                      value: _conversation
                              .aiProvider
                              .isEmpty
                          ? '未入力'
                          : _conversation
                              .aiProvider,
                    ),
                    const Divider(
                      height: 28,
                    ),
                    _DetailRow(
                      label: '整理状態',
                      value: statusName,
                    ),
                    const Divider(
                      height: 28,
                    ),
                    _DetailRow(
                      label: '保存日時',
                      value:
                          formattedCreatedAt,
                    ),
                    const Divider(
                      height: 28,
                    ),
                    _DetailRow(
                      label: '更新日時',
                      value:
                          formattedUpdatedAt,
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
                      'あなたの質問',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      _conversation
                          .userMessage,
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
                      'AIからの回答',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      _conversation.aiResponse,
                    ),
                  ],
                ),
              ),
            ),

            if (_conversation.summary
                .isNotEmpty) ...[
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
                        '要約',
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
                        _conversation.summary,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (canDefer)
              FilledButton.tonalIcon(
                onPressed:
                    _isUpdatingStatus
                        ? null
                        : _deferConversation,
                icon: _isUpdatingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.schedule_outlined,
                      ),
                label: Text(
                  _isUpdatingStatus
                      ? '変更しています...'
                      : 'あとで整理する',
                ),
              )
            else if (_conversation
                    .responseStatus ==
                AiResponseStatus.deferred)
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'このAI相談は'
                              '「あとで整理」に'
                              '登録されています。',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FilledButton.icon(
                    onPressed:
                        _openKnowledgeScreen,
                    icon: const Icon(
                      Icons.lightbulb_outline,
                    ),
                    label: const Text(
                      'Knowledgeとして整理する',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
          ),
        ),
      ],
    );
  }
}
