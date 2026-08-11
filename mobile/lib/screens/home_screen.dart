import 'package:flutter/material.dart';

import 'ai_chat_screen.dart';
import 'knowledge_list_screen.dart';
import 'knowledge_network_screen.dart';
import 'memory_screen.dart';
import 'theme_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openScreen(BuildContext context, Widget screen) {
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
        title: const Text('PAMS Companion'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '今日は何をしますか？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _HomeMenuButton(
                label: 'AIに相談する',
                icon: Icons.chat_bubble_outline,
                onPressed: () {
                  _openScreen(context, const AiChatScreen());
                },
              ),
              const SizedBox(height: 16),
              _HomeMenuButton(
                label: 'AIの回答を整理する',
                icon: Icons.fact_check_outlined,
                onPressed: () {
                  _openScreen(
                    context,
                    const KnowledgeListScreen(),
                  );
                },              
              ),
              const SizedBox(height: 16),
              _HomeMenuButton(
                label: '知識のつながりを見る',
                icon: Icons.account_tree_outlined,
                onPressed: () {
                  _openScreen(
                    context,
                    const KnowledgeNetworkScreen(),
                  );
                },
              ),
              const SizedBox(height: 16),            
              _HomeMenuButton(
                label: '今日の記憶',
                icon: Icons.lightbulb_outline,
                onPressed: () {
                  _openScreen(context, const MemoryScreen());
                },
              ),
              const SizedBox(height: 16),
              _HomeMenuButton(
                label: 'テーマ',
                icon: Icons.folder_outlined,
                onPressed: () {
                  _openScreen(
                    context,
                    const ThemeScreen(),
                  );
                },
              ),             
              const SizedBox(height: 16),
              _HomeMenuButton(
                label: '設定',
                icon: Icons.settings_outlined,
                onPressed: () {
                  _openScreen(context, const SettingsScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMenuButton extends StatelessWidget {
  const _HomeMenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
