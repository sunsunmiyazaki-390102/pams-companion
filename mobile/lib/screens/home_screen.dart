import 'package:flutter/material.dart';

import 'about_pams_screen.dart';
import 'ai_think_screen.dart';
import 'data_management_screen.dart';
import 'knowledge_grow_screen.dart';
import 'memory_screen.dart';
import 'theme_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
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
          'PAMS Companion',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              '今日は何をしますか？',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'AIとの対話や、そこから生まれた知を'
              '自分の人生に利かしていきます。',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            _HomeMenuCard(
              label: '今日の記憶',
              description:
                  '今日のメモやAIとの対話、'
                  '育てた知を振り返ります。',
              icon: Icons.today_outlined,
              onPressed: () {
                _openScreen(
                  context,
                  const MemoryScreen(),
                );
              },
            ),

            const SizedBox(height: 16),

            _HomeMenuCard(
              label: 'AIと考える',
              description:
                  'まずはAIと話してみましょう。新しい対話を始めたり、'
                  'これまでの対話を振り返ることができます。',
              icon: Icons.chat_bubble_outline,
              onPressed: () {
                _openScreen(
                  context,
                  const AiThinkScreen(),
                );
              },
            ),

            const SizedBox(height: 16),

            _HomeMenuCard(
              label: '知を育てる',
              description:
                  '残した対話を振り返り、'
                  '大切なものを自分の知へ育てます。',
              icon: Icons.eco_outlined,
              onPressed: () {
                _openScreen(
                  context,
                  const KnowledgeGrowScreen(),
                );
              },
            ),

            const SizedBox(height: 16),

            _HomeMenuCard(
              label: 'テーマ',
              description:
                  '対話や知を、自分の関心ごとに'
                  'まとめて振り返ります。',
              icon: Icons.folder_outlined,
              onPressed: () {
                _openScreen(
                  context,
                  const ThemeScreen(),
                );
              },
            ),

            const SizedBox(height: 16),

            _HomeMenuCard(
              label: 'データ管理',
              description:
                  'データのバックアップや'
                  '復元を行います。',
              icon: Icons.storage_outlined,
              onPressed: () {
                _openScreen(
                  context,
                  const DataManagementScreen(),
                );
              },
            ),

            const SizedBox(height: 16),

            _HomeMenuCard(
              label: 'PAMSについて',
              description:
                  'PAMSの考え方や'
                  '使い方を確認します。',
              icon: Icons.info_outline,
              onPressed: () {
                _openScreen(
                  context,
                  const AboutPamsScreen(),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HomeMenuCard extends StatelessWidget {
  const _HomeMenuCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String description;
  final IconData icon;
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
              CircleAvatar(
                child: Icon(
                  icon,
                  size: 26,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
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
