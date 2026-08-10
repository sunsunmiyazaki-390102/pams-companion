import 'package:flutter/material.dart';

import '../models/ai_conversation.dart';
import '../models/reflection_queue.dart';
import '../models/reflection_queue_priority.dart';
import '../models/reflection_queue_status.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/reflection_queue_repository.dart';
import 'ai_conversation_detail_screen.dart';

class ReflectionQueueScreen extends StatefulWidget {
  const ReflectionQueueScreen({
    super.key,
  });

  @override
  State<ReflectionQueueScreen> createState() =>
      _ReflectionQueueScreenState();
}

class _ReflectionQueueScreenState
    extends State<ReflectionQueueScreen> {
  final ReflectionQueueRepository
      _reflectionQueueRepository =
      ReflectionQueueRepository();

  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  bool _isLoading = true;

  List<_ReflectionQueueItem> _items = [];

  @override
  void initState() {
    super.initState();

    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final queues =
          await _reflectionQueueRepository
              .findByStatus(
        ReflectionQueueStatus.waiting,
      );

      final items =
          <_ReflectionQueueItem>[];

      for (final queue in queues) {
        final conversation =
            await _conversationRepository
                .findById(
          queue.conversationId,
        );

        if (conversation == null) {
          continue;
        }

        items.add(
          _ReflectionQueueItem(
            queue: queue,
            conversation: conversation,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
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
            '「次に育てる」を'
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

    await _loadItems();
  }

  List<_ReflectionQueueItem>
      _itemsForPriority(
    int priority,
  ) {
    return _items
        .where(
          (item) =>
              item.queue.priority ==
              priority,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final nextItems =
        _itemsForPriority(
      ReflectionQueuePriority.next,
    );

    final importantItems =
        _itemsForPriority(
      ReflectionQueuePriority.important,
    );

    final somedayItems =
        _itemsForPriority(
      ReflectionQueuePriority.someday,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '次に育てる',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadItems,
          child: ListView(
            padding:
                const EdgeInsets.all(24),
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      Icons.eco_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '次に育てる',
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
                '自分で選んだ大切な対話を、'
                '優先度の順に振り返ります。',
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
              else if (_items.isEmpty)
                const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'まだ「次に育てる」に'
                          '選んだ対話はありません。',
                          textAlign:
                              TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _PrioritySection(
                  priority:
                      ReflectionQueuePriority
                          .next,
                  items: nextItems,
                  onOpenConversation:
                      _openConversation,
                ),

                const SizedBox(height: 24),

                _PrioritySection(
                  priority:
                      ReflectionQueuePriority
                          .important,
                  items: importantItems,
                  onOpenConversation:
                      _openConversation,
                ),

                const SizedBox(height: 24),

                _PrioritySection(
                  priority:
                      ReflectionQueuePriority
                          .someday,
                  items: somedayItems,
                  onOpenConversation:
                      _openConversation,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrioritySection extends StatelessWidget {
  const _PrioritySection({
    required this.priority,
    required this.items,
    required this.onOpenConversation,
  });

  final int priority;
  final List<_ReflectionQueueItem> items;
  final Future<void> Function(
    AiConversation conversation,
  ) onOpenConversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ReflectionQueuePriority
                    .displayLabel(
                  priority,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${items.length}件',
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (items.isEmpty)
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(16),
              child: Text(
                '該当する対話はありません。',
              ),
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: _ReflectionQueueCard(
                item: item,
                onPressed: () {
                  onOpenConversation(
                    item.conversation,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ReflectionQueueCard
    extends StatelessWidget {
  const _ReflectionQueueCard({
    required this.item,
    required this.onPressed,
  });

  final _ReflectionQueueItem item;
  final VoidCallback onPressed;

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
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      item.conversation
                          .userMessage,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
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
                      '登録日：'
                      '${_formatDate(
                        item.queue.createdAt,
                      )}',
                      style:
                          Theme.of(context)
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
        ),
      ),
    );
  }
}

class _ReflectionQueueItem {
  const _ReflectionQueueItem({
    required this.queue,
    required this.conversation,
  });

  final ReflectionQueue queue;
  final AiConversation conversation;
}
