import 'package:flutter/material.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../repositories/ai_conversation_repository.dart';
import 'ai_conversation_detail_screen.dart';

class DeferredConversationScreen
    extends StatefulWidget {
  const DeferredConversationScreen({
    super.key,
  });

  @override
  State<DeferredConversationScreen>
      createState() =>
          _DeferredConversationScreenState();
}

class _DeferredConversationScreenState
    extends State<DeferredConversationScreen> {
  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  bool _isLoading = true;

  List<AiConversation> _conversations = [];

  @override
  void initState() {
    super.initState();

    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations =
          await _conversationRepository
              .findByResponseStatus(
        AiResponseStatus.deferred,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '「あとで整理」を'
            '読み込めませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void> _openConversation(
    AiConversation conversation,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            AiConversationDetailScreen(
          conversation: conversation,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadConversations();
  }

  String _formatDate(
    DateTime dateTime,
  ) {
    final localDateTime =
        dateTime.toLocal();

    final year =
        localDateTime.year.toString();

    final month =
        localDateTime.month
            .toString()
            .padLeft(2, '0');

    final day =
        localDateTime.day
            .toString()
            .padLeft(2, '0');

    return '$year/$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'あとで整理',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadConversations,
          child: ListView(
            padding:
                const EdgeInsets.all(24),
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      Icons.schedule_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'あとで整理',
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
                '保存したAIとの対話を'
                '振り返ります。',
              ),

              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 48,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (_conversations.isEmpty)
                const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'まだ「あとで整理」に'
                          '登録された対話はありません。',
                          textAlign:
                              TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._conversations.map(
                  (conversation) =>
                      Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          _openConversation(
                            conversation,
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Icon(
                                Icons
                                    .chat_bubble_outline,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      conversation
                                          .userMessage,
                                      maxLines: 3,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      '保存日：'
                                      '${_formatDate(
                                        conversation
                                            .createdAt,
                                      )}',
                                      style:
                                          Theme.of(
                                        context,
                                      )
                                              .textTheme
                                              .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              const Icon(
                                Icons.chevron_right,
                              ),
                            ],
                          ),
                        ),
                      ),
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
