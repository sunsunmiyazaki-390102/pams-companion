import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../models/reflection_queue.dart';
import '../models/reflection_queue_priority.dart';
import '../models/reflection_queue_status.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/reflection_queue_repository.dart';
import 'ai_conversation_reflection_screen.dart';
import 'waiting_ai_response_screen.dart';

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

  final ReflectionQueueRepository
      _reflectionQueueRepository =
      ReflectionQueueRepository();

  final Uuid _uuid = const Uuid();

  late AiConversation _conversation;

  ReflectionQueue? _reflectionQueue;

  bool _isUpdatingStatus = false;
  bool _isLoadingReflectionQueue = true;
  bool _isUpdatingReflectionQueue = false;

  @override
  void initState() {
    super.initState();

    _conversation = widget.conversation;

    _loadReflectionQueue();
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

  Future<void> _openWaitingAiResponseScreen() async {
    final updatedConversation =
        await Navigator.of(context).push<AiConversation>(
      MaterialPageRoute<AiConversation>(
        builder: (context) =>
            WaitingAiResponseScreen(
          conversation: _conversation,
        ),
      ),
    );

    if (!mounted ||
        updatedConversation == null) {
      return;
    }

    setState(() {
      _conversation = updatedConversation;
    });
  } 
 
  Future<void> _loadReflectionQueue() async {
    try {
      final queue =
          await _reflectionQueueRepository
              .findByConversationId(
        _conversation.conversationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reflectionQueue = queue;
        _isLoadingReflectionQueue = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingReflectionQueue = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '「次に育てる」の状態を'
            '確認できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<int?> _selectReflectionPriority({
    int? currentPriority,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            '次に育てる優先度',
          ),
          children: [
            for (final priority
                in ReflectionQueuePriority.values)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop(
                    priority,
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ReflectionQueuePriority
                              .displayLabel(
                            priority,
                          ),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                currentPriority ==
                                        priority
                                    ? FontWeight.bold
                                    : FontWeight
                                        .normal,
                          ),
                        ),
                      ),
                      if (currentPriority ==
                          priority)
                        const Icon(
                          Icons.check,
                        ),
                    ],
                  ),
                ),
              ),
            const Divider(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Text(
                  'キャンセル',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToReflectionQueue() async {
    if (_isUpdatingReflectionQueue) {
      return;
    }

    final selectedPriority =
        await _selectReflectionPriority();

    if (selectedPriority == null ||
        !mounted) {
      return;
    }

    setState(() {
      _isUpdatingReflectionQueue = true;
    });

    try {
      final now = DateTime.now();

      final queue = ReflectionQueue(
        queueId: _uuid.v4(),
        conversationId:
            _conversation.conversationId,
        priority: selectedPriority,
        status:
            ReflectionQueueStatus.waiting,
        createdAt: now,
        updatedAt: now,
      );

      await _reflectionQueueRepository.insert(
        queue,
      );

      final savedQueue =
          await _reflectionQueueRepository
              .findByConversationId(
        _conversation.conversationId,
      );

      if (savedQueue == null) {
        throw StateError(
          '保存した「次に育てる」を'
          '確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _reflectionQueue = savedQueue;
        _isUpdatingReflectionQueue = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '「次に育てる」に追加しました。\n'
            '${ReflectionQueuePriority.displayLabel(
              savedQueue.priority,
            )}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingReflectionQueue = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '「次に育てる」に'
            '追加できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void>
      _changeReflectionQueuePriority() async {
    final currentQueue = _reflectionQueue;

    if (currentQueue == null ||
        _isUpdatingReflectionQueue) {
      return;
    }

    final selectedPriority =
        await _selectReflectionPriority(
      currentPriority:
          currentQueue.priority,
    );

    if (selectedPriority == null ||
        selectedPriority ==
            currentQueue.priority ||
        !mounted) {
      return;
    }

    setState(() {
      _isUpdatingReflectionQueue = true;
    });

    try {
      await _reflectionQueueRepository
          .updatePriority(
        queueId: currentQueue.queueId,
        priority: selectedPriority,
      );

      final updatedQueue =
          await _reflectionQueueRepository
              .findByConversationId(
        _conversation.conversationId,
      );

      if (updatedQueue == null) {
        throw StateError(
          '更新した「次に育てる」を'
          '確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _reflectionQueue = updatedQueue;
        _isUpdatingReflectionQueue = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '優先度を変更しました。\n'
            '${ReflectionQueuePriority.displayLabel(
              updatedQueue.priority,
            )}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingReflectionQueue = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '優先度を変更できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void> _openReflectionScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            AiConversationReflectionScreen(
          conversation: _conversation,
        ),
      ),
    );

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

    await _loadReflectionQueue();
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

    final isWaiting =
        _conversation.responseStatus ==
            AiResponseStatus.waiting;  
  
    final canDefer =
        _conversation.responseStatus ==
            AiResponseStatus.received;

    final isDeferred =
        _conversation.responseStatus ==
            AiResponseStatus.deferred;

    final reflectionQueue =
        _reflectionQueue;

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
                      _conversation.userMessage,
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
                      'AIへ渡した文章',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      _conversation.aiPrompt.isEmpty
                          ? 'この対話では保存されていません。'
                          : _conversation.aiPrompt,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),           
           
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
                      _conversation.aiResponse.isEmpty
                          ? 'まだAIからの回答を受け取っていません。'
                          : _conversation.aiResponse,
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

            if (isWaiting) ...[
              FilledButton.icon(
                onPressed:
                    _openWaitingAiResponseScreen,
                icon: const Icon(
                  Icons.download_outlined,
                ),
                label: const Text(
                  'AI回答を取り込む',
                ),
              ),
              const SizedBox(height: 12),
            ],

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
            else if (isDeferred)
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

                  if (_isLoadingReflectionQueue)
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(16),
                        child: Center(
                          child:
                              CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (reflectionQueue == null)
                    FilledButton.tonalIcon(
                      onPressed:
                          _isUpdatingReflectionQueue
                              ? null
                              : _addToReflectionQueue,
                      icon:
                          _isUpdatingReflectionQueue
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
                                      .eco_outlined,
                                ),
                      label: Text(
                        _isUpdatingReflectionQueue
                            ? '追加しています...'
                            : '次に育てるへ追加',
                      ),
                    )
                  else
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.eco_outlined,
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                const Expanded(
                                  child: Text(
                                    '次に育てる',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          18,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Text(
                              ReflectionQueuePriority
                                  .displayLabel(
                                reflectionQueue
                                    .priority,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              ReflectionQueueStatus
                                  .displayName(
                                reflectionQueue
                                    .status,
                              ),
                            ),
                            if (reflectionQueue
                                    .status ==
                                ReflectionQueueStatus
                                    .waiting) ...[
                              const SizedBox(
                                height: 16,
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    _isUpdatingReflectionQueue
                                        ? null
                                        : _changeReflectionQueuePriority,
                                icon: const Icon(
                                  Icons
                                      .swap_vert_outlined,
                                ),
                                label:
                                    const Text(
                                  '優先度を変更する',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  FilledButton.icon(
                    onPressed:
                        _openReflectionScreen,
                    icon: const Icon(
                      Icons.psychology_outlined,
                    ),
                    label: const Text(
                      'AI回答を整理する',
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
