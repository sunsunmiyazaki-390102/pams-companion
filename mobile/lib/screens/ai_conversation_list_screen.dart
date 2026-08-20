import 'package:flutter/material.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../repositories/ai_conversation_repository.dart';

import 'ai_conversation_detail_screen.dart';
import 'ai_chat_screen.dart';

class AiConversationListScreen
    extends StatefulWidget {
  const AiConversationListScreen({
    super.key,
  });

  @override
  State<AiConversationListScreen> createState() =>
      _AiConversationListScreenState();
}

class _AiConversationListScreenState
    extends State<AiConversationListScreen> {
  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  late Future<List<AiConversation>>
      _conversationsFuture;

  @override
  void initState() {
    super.initState();

    _conversationsFuture =
        _conversationRepository.findAll();
  }

  Future<void> _reload() async {
    setState(() {
      _conversationsFuture =
          _conversationRepository.findAll();
    });

    await _conversationsFuture;
  }

  Future<void> _openConversationDetail(
    AiConversation conversation,
  ) async {
    final shouldOpenAiChat =
        conversation.responseStatus ==
                AiResponseStatus.draft ||
            conversation.responseStatus ==
                AiResponseStatus.waiting ||
            conversation.responseStatus ==
                AiResponseStatus.received;   

    if (shouldOpenAiChat) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) =>
              AiChatScreen(
            initialConversation:
                conversation,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) =>
              AiConversationDetailScreen(
            conversation: conversation,
          ),
        ),
      );
    }

    if (!mounted) {
      return;
    }

    await _reload();
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
      case AiResponseStatus.waiting:
        return Icons.hourglass_empty_outlined;
      
      case AiResponseStatus.deferred:
        return Icons.schedule_outlined;

      case AiResponseStatus.organized:
        return Icons.check_circle_outline;

      case AiResponseStatus.received:
      default:
        return Icons.inbox_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI相談履歴',
        ),
      ),
      body: SafeArea(
        child:
            FutureBuilder<List<AiConversation>>(
          future: _conversationsFuture,
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
                    'AI相談履歴の読み込みに'
                    '失敗しました。\n'
                    '${snapshot.error}',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              );
            }

            final conversations =
                snapshot.data ?? [];

            return RefreshIndicator(
              onRefresh: _reload,
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
                          Icons.history_outlined,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
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
                  const SizedBox(height: 16),
                  const Text(
                    'AIから受け取った回答を確認し、'
                    'あとから整理できます。',
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons
                              .chat_bubble_outline,
                        ),
                      ),
                      title: Text(
                        '保存済みの相談：'
                        '${conversations.length}件',
                      ),
                      subtitle: const Text(
                        '新しい相談から順に'
                        '表示しています。',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (conversations.isEmpty)
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .chat_bubble_outline,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '保存済みの'
                              'AI相談はありません。',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                              textAlign:
                                  TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '「AIに相談する」画面から'
                              '質問と回答を保存すると、'
                              'ここへ表示されます。',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...conversations.map(
                      (conversation) =>
                          Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 16,
                        ),
                        child:
                        _AiConversationCard(
                          conversation:
                              conversation,
                          formattedDateTime:
                              _formatDateTime(
                            conversation.updatedAt,
                          ),
                          statusIcon:
                              _statusIcon(
                            conversation.responseStatus,
                          ),
                          onTap: () {
                            _openConversationDetail(
                              conversation,
                            );
                          },
                        ),                        
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AiConversationCard
    extends StatelessWidget {
  const _AiConversationCard({
    required this.conversation,
    required this.formattedDateTime,
    required this.statusIcon,
    required this.onTap,
  });

  final AiConversation conversation;
  final String formattedDateTime;
  final IconData statusIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      statusIcon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.aiProvider.isEmpty
                              ? '利用したAI：未入力'
                              : '利用したAI：'
                                  '${conversation.aiProvider}',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AiResponseStatus.displayName(
                            conversation.responseStatus,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text(
                'あなたの質問',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                conversation.userMessage,
                maxLines: 5,
                overflow:
                    TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              const Text(
                'AIからの回答',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                conversation.aiResponse,
                maxLines: 8,
                overflow:
                    TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Text(
                '保存日時：$formattedDateTime',
                textAlign: TextAlign.right,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
