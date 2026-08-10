import 'package:flutter/material.dart';

import 'deferred_conversation_screen.dart';
import 'knowledge_list_screen.dart';
import 'reflection_queue_screen.dart';

class KnowledgeGrowScreen extends StatelessWidget {
  const KnowledgeGrowScreen({
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
          '知を育てる',
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
                    Icons.eco_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '知を育てる',
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
              '残した対話を振り返り、'
              '大切なものを自分の知へ育てます。',
            ),

            const SizedBox(height: 24),

            _KnowledgeGrowMenuCard(
              icon: Icons.schedule_outlined,
              title: 'あとで整理',
              description:
                  '保存したAIとの対話を'
                  '振り返ります。',
              onPressed: () {
                _openScreen(
                  context,
                  const DeferredConversationScreen(),
                );
              },
            ),

            const SizedBox(height: 16),

            _KnowledgeGrowMenuCard(
              icon: Icons.eco_outlined,
              title: '次に育てる',
              description:
                  '自分で選んだ大切な対話を、'
                  '優先度の順に整理します。',
              onPressed: () {
                _openScreen(
                  context,
                  const ReflectionQueueScreen(),
                );
              },
            ),

            const SizedBox(height: 16),

            _KnowledgeGrowMenuCard(
              icon: Icons.lightbulb_outline,
              title: '育てた知',
              description:
                  'これまで自分の知として'
                  '残したものを見ます。',
              onPressed: () {
                _openScreen(
                  context,
                  const KnowledgeListScreen(),
                );
              },
            ),

            const SizedBox(height: 24),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'まず残し、あとから振り返り、'
                  '自分にとって大切なものを'
                  '少しずつ知へ育てていきます。',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeGrowMenuCard
    extends StatelessWidget {
  const _KnowledgeGrowMenuCard({
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
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(20),
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
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

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
