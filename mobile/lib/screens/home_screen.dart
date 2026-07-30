import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              _HomeMenuButton(
                label: 'AIの回答を整理する',
                icon: Icons.fact_check_outlined,
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              _HomeMenuButton(
                label: '今日の記憶',
                icon: Icons.lightbulb_outline,
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              _HomeMenuButton(
                label: 'プロジェクト',
                icon: Icons.folder_outlined,
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              _HomeMenuButton(
                label: '設定',
                icon: Icons.settings_outlined,
                onPressed: () {},
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
