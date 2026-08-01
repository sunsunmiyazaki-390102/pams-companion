import 'package:flutter/material.dart';
import '../models/ai_session.dart';
import '../repositories/ai_session_repository.dart';

class AiSessionEditScreen extends StatefulWidget {
  const AiSessionEditScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  State<AiSessionEditScreen> createState() =>
      _AiSessionEditScreenState();
}

class _AiSessionEditScreenState
    extends State<AiSessionEditScreen> {

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final AiSessionRepository _aiSessionRepository =
      AiSessionRepository();
 
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Session追加'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'セッション名',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: '説明',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () async {
                    final title = _titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('セッション名を入力してください。'),
                        ),
                      );
                      return;
                    }

                    final now = DateTime.now();

                    final session = AiSession(
                      sessionId: now.microsecondsSinceEpoch.toString(),
                      projectId: widget.projectId,
                      title: title,
                      createdAt: now,
                      updatedAt: now,
                    );

                    await _aiSessionRepository.insert(session);

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).pop(true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '「${session.title}」のデータを作成しました。保存は次回実装します。',
                        ),
                      ),
                    );
                  },                
                  icon: const Icon(Icons.save_outlined),
                  label: const Text(
                    '保存',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
