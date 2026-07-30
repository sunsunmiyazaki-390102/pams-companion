import 'package:flutter/material.dart';

class AnswerReviewScreen extends StatelessWidget {
  const AnswerReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIの回答を整理する'),
      ),
      body: const Center(
        child: Text(
          'AIの回答を整理する画面\n\n準備中',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
