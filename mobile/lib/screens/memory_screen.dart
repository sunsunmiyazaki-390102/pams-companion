import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_conversation.dart';
import '../models/daily_memory.dart';
import '../models/knowledge_asset.dart';
import '../repositories/ai_conversation_repository.dart';
import '../repositories/daily_memory_repository.dart';
import '../repositories/knowledge_asset_repository.dart';
import 'ai_conversation_detail_screen.dart';
import 'knowledge_detail_screen.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({
    super.key,
  });

  @override
  State<MemoryScreen> createState() =>
      _MemoryScreenState();
}

class _MemoryScreenState
    extends State<MemoryScreen> {
  final DailyMemoryRepository
      _dailyMemoryRepository =
      DailyMemoryRepository();

  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  final KnowledgeAssetRepository
      _knowledgeRepository =
      KnowledgeAssetRepository();

  final TextEditingController
      _memoryController =
      TextEditingController();

  final Uuid _uuid = const Uuid();

  late DateTime _selectedDate;

  DailyMemory? _dailyMemory;

  List<AiConversation> _conversations = [];
  List<KnowledgeAsset> _knowledgeAssets = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    _loadSelectedDate();
  }

  @override
  void dispose() {
    _memoryController.dispose();
    super.dispose();
  }

  String _dateKey(
    DateTime date,
  ) {
    final year =
        date.year.toString().padLeft(4, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _displayDate(
    DateTime date,
  ) {
    return '${date.year}年'
        '${date.month}月'
        '${date.day}日';
  }

  String _formatTime(
    DateTime dateTime,
  ) {
    final localDateTime =
        dateTime.toLocal();

    final hour =
        localDateTime.hour
            .toString()
            .padLeft(2, '0');

    final minute =
        localDateTime.minute
            .toString()
            .padLeft(2, '0');

    return '$hour:$minute';
  }

  bool _isToday(
    DateTime date,
  ) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _loadSelectedDate() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;

      _memoryController.clear();
      _dailyMemory = null;
      _conversations = [];
      _knowledgeAssets = [];
    });

    final dateKey =
        _dateKey(_selectedDate);

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    DailyMemory? memory;

    List<AiConversation> conversations = [];

    List<KnowledgeAsset> knowledgeAssets = [];

    String? memoryError;
    String? conversationError;
    String? knowledgeError;

    // 1. DailyMemory
    try {
      memory =
          await _dailyMemoryRepository
              .findByDate(
        dateKey,
      );
    } catch (error) {
      memoryError = error.toString();
    }

    // 2. AIとの対話
    try {
      conversations =
          await _conversationRepository
              .findByCreatedAtRange(
        start: start,
        end: end,
      );
    } catch (error) {
      conversationError =
          error.toString();
    }

    // 3. 育てた知
    try {
      knowledgeAssets =
          await _knowledgeRepository
              .findByCreatedAtRange(
        start: start,
        end: end,
      );
    } catch (error) {
      knowledgeError =
          error.toString();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyMemory = memory;

      _memoryController.text =
          memory?.content ?? '';

      _conversations =
          conversations;

      _knowledgeAssets =
          knowledgeAssets;

      _isLoading = false;
    });

    if (memoryError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'この日のメモを'
            '読み込めませんでした。\n'
            '$memoryError',
          ),
        ),
      );
    }

    if (conversationError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'この日のAIとの対話を'
            '読み込めませんでした。\n'
            '$conversationError',
          ),
        ),
      );
    }

    if (knowledgeError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'この日の育てた知を'
            '読み込めませんでした。\n'
            '$knowledgeError',
          ),
        ),
      );
    }
  }

  Future<void> _saveMemory() async {
    if (_isSaving) {
      return;
    }

    final content =
        _memoryController.text.trim();

    final currentMemory =
        _dailyMemory;

    if (currentMemory == null &&
        content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '保存する内容を入力してください。',
          ),
        ),
      );

      return;
    }

    if (currentMemory != null &&
        currentMemory.content == content) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '変更はありません。',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();

      if (currentMemory == null) {
        final memory = DailyMemory(
          memoryId: _uuid.v4(),
          memoryDate:
              _dateKey(_selectedDate),
          content: content,
          createdAt: now,
          updatedAt: now,
        );

        await _dailyMemoryRepository
            .insert(
          memory,
        );
      } else {
        final updatedMemory =
            currentMemory.copyWith(
          content: content,
          updatedAt: now,
        );

        await _dailyMemoryRepository
            .update(
          updatedMemory,
        );
      }

      final savedMemory =
          await _dailyMemoryRepository
              .findByDate(
        _dateKey(_selectedDate),
      );

      if (savedMemory == null) {
        throw StateError(
          '保存した記憶を確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _dailyMemory = savedMemory;

        _memoryController.text =
            savedMemory.content;

        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '記憶を保存しました。',
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '記憶を保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void> _changeDate(
    int days,
  ) async {
    if (_isLoading ||
        _isSaving) {
      return;
    }

    final newDate =
        _selectedDate.add(
      Duration(days: days),
    );

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    if (newDate.isAfter(today)) {
      return;
    }

    setState(() {
      _selectedDate = newDate;
    });

    await _loadSelectedDate();
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

    await _loadSelectedDate();
  }

  Future<void> _openKnowledge(
    KnowledgeAsset asset,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            KnowledgeDetailScreen(
          asset: asset,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadSelectedDate();
  }

  @override
  Widget build(BuildContext context) {
    final isToday =
        _isToday(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '今日の記憶',
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : ListView(
                padding:
                    const EdgeInsets.all(24),
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        child: Icon(
                          Icons.today_outlined,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '今日の記憶',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed:
                                _isSaving
                                    ? null
                                    : () {
                                        _changeDate(
                                          -1,
                                        );
                                      },
                            tooltip: '前の日',
                            icon: const Icon(
                              Icons.chevron_left,
                            ),
                          ),

                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _displayDate(
                                    _selectedDate,
                                  ),
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                if (isToday)
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(
                                      top: 4,
                                    ),
                                    child: Text(
                                      '今日',
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          IconButton(
                            onPressed:
                                isToday ||
                                        _isSaving
                                    ? null
                                    : () {
                                        _changeDate(
                                          1,
                                        );
                                      },
                            tooltip: '次の日',
                            icon: const Icon(
                              Icons.chevron_right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          Text(
                            isToday
                                ? '今日のメモ'
                                : 'この日のメモ',
                            style:
                                const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            'その日の出来事や、'
                            '気づいたこと、考えたことを'
                            '自由に残せます。',
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          TextField(
                            controller:
                                _memoryController,
                            minLines: 5,
                            maxLines: 12,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  'ここに記憶を残します',
                              border:
                                  OutlineInputBorder(),
                              alignLabelWithHint:
                                  true,
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          FilledButton.icon(
                            onPressed:
                                _isSaving
                                    ? null
                                    : _saveMemory,
                            icon: _isSaving
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
                                    Icons.save_outlined,
                                  ),
                            label: Text(
                              _isSaving
                                  ? '保存しています...'
                                  : '保存',
                            ),
                          ),

                          if (_dailyMemory !=
                              null) ...[
                            const SizedBox(
                              height: 12,
                            ),
                            Text(
                              '最終更新：'
                              '${_formatTime(
                                _dailyMemory!
                                    .updatedAt,
                              )}',
                              textAlign:
                                  TextAlign.right,
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'この日にPAMSへ残したもの',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _SectionHeader(
                    icon:
                        Icons.chat_bubble_outline,
                    title: 'AIとの対話',
                    count:
                        _conversations.length,
                  ),

                  const SizedBox(height: 10),

                  if (_conversations.isEmpty)
                    const _EmptyCard(
                      text:
                          'この日に保存した'
                          'AIとの対話はありません。',
                    )
                  else
                    ..._conversations.map(
                      (conversation) =>
                          Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
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
                                          height: 6,
                                        ),
                                        Text(
                                          _formatTime(
                                            conversation
                                                .createdAt,
                                          ),
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
                                  const Icon(
                                    Icons
                                        .chevron_right,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  _SectionHeader(
                    icon:
                        Icons.lightbulb_outline,
                    title: '育てた知',
                    count:
                        _knowledgeAssets.length,
                  ),

                  const SizedBox(height: 10),

                  if (_knowledgeAssets.isEmpty)
                    const _EmptyCard(
                      text:
                          'この日に育てた知は'
                          'ありません。',
                    )
                  else
                    ..._knowledgeAssets.map(
                      (asset) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: Card(
                          child: InkWell(
                            onTap: () {
                              _openKnowledge(
                                asset,
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
                                        .lightbulb_outline,
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
                                          asset.content,
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
                                          height: 6,
                                        ),
                                        Text(
                                          _formatTime(
                                            asset.createdAt,
                                          ),
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
                                  const Icon(
                                    Icons
                                        .chevron_right,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        Text(
          '$count件',
          style:
              Theme.of(context)
                  .textTheme
                  .bodyMedium,
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Text(
          text,
        ),
      ),
    );
  }
}
