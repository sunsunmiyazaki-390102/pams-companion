import 'package:flutter/material.dart';

class ProjectEditScreen extends StatelessWidget {
  const ProjectEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロジェクト追加'),
      ),
      body: const Center(
        child: Text(
          'プロジェクト追加画面\n（準備中）',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
