import 'package:flutter/material.dart';

import 'ai_chat_screen.dart';
import 'ai_conversation_list_screen.dart';

class AiThinkScreen extends StatelessWidget {
  const AiThinkScreen({
    super.key,
  });

  void _openScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AIと考える',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    Icons.chat_bubble_outline,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AIと考える',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'AIとの対話を通して、'
              '考えを深めたり記録したりします。',
            ),
            const SizedBox(height: 24),

            _AiThinkMenuCard(
              icon: Icons.add_comment_outlined,
              title: 'AIと考える',
              description:
                  'AIとの対話を始めます。',
              onPressed: () {
                _openScreen(
                  context,
                  const AiChatScreen(),
                );
              },
            ),

            const SizedBox(height: 16),

            _AiThinkMenuCard(
              icon: Icons.history_outlined,
              title: 'これまでの対話',
              description:
                  '保存したAIとの対話を振り返ります。',
              onPressed: () {
                _openScreen(
                  context,
                  const AiConversationListScreen(),
                );
              },
            ),

            const SizedBox(height: 24),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'AIとの対話は、まず残しておくことができます。\n'
                  '大切な対話は、あとから「知を育てる」で'
                  '振り返り、自分の知へ育てていきます。',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiThinkMenuCard extends StatelessWidget {
  const _AiThinkMenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
