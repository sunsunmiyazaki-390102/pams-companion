import 'package:flutter/material.dart';

import '../models/ai_conversation.dart';
import '../models/ai_session.dart';
import '../repositories/ai_conversation_repository.dart';
import 'ai_conversation_start_screen.dart';

class AiConversationScreen extends StatefulWidget {
  const AiConversationScreen({
    super.key,
    required this.session,
  });

  final AiSession session;

  @override
  State<AiConversationScreen> createState() =>
      _AiConversationScreenState();
}

class _AiConversationScreenState
    extends State<AiConversationScreen> {
  final AiConversationRepository _conversationRepository =
      AiConversationRepository();

  List<AiConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversations =
        await _conversationRepository.findBySessionId(
      widget.session.sessionId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _conversations = conversations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Conversation'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => AiConversationStartScreen(
                session: widget.session,
              ),
            ),
          );
        },
        tooltip: 'AIとの対話を始める',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.forum_outlined,
                size: 72,
              ),
              const SizedBox(height: 24),
              Text(
                widget.session.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'まだAIとの対話は保存されていません。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '右下の＋ボタンから最初の対話を追加します。',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final conversation = _conversations[index];

          final title = conversation.summary.trim().isNotEmpty
              ? conversation.summary
              : conversation.userMessage;

          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.chat_bubble_outline,
              ),
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: conversation.aiProvider.trim().isEmpty
                  ? null
                  : Text(conversation.aiProvider),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Conversation編集画面は後のStepで作成します。',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
