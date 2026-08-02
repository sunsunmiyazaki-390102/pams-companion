import 'package:flutter/material.dart';
import '../models/ai_session.dart';
import '../repositories/ai_session_repository.dart';

class AiSessionEditScreen extends StatefulWidget {
  const AiSessionEditScreen({
    super.key,
    required this.projectId,
    this.session,
  });

  final String projectId;
  final AiSession? session;

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
  void initState() {
    super.initState();

    final session = widget.session;

    if (session != null) {
      _titleController.text = session.title;
    }
  }

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
        title: Text(
          widget.session == null ? 'AI Session追加' : 'AI Session編集',
        ),
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

                    final existingSession = widget.session;
                    
                    final now = DateTime.now();

                    final session = AiSession(
                      sessionId: existingSession?.sessionId ??
                          now.microsecondsSinceEpoch.toString(),
                      projectId: widget.projectId,
                      title: title,
                      createdAt: existingSession?.createdAt ?? now,
                      updatedAt: now,
                    );                  
                  
                    if (existingSession == null) {
                      await _aiSessionRepository.insert(session);
                    } else {
                      await _aiSessionRepository.update(session);
                    }                   
                   
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
              if (widget.session != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('確認'),
                            content: const Text(
                              'このAI Sessionを削除しますか？',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text('キャンセル'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text('削除'),
                              ),
                            ],
                          );
                        },
                      );

                      if (result != true) {
                        return;
                      }

                      await _aiSessionRepository.delete(
                        widget.session!.sessionId,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.of(context).pop(true);                     
                  
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      '削除',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],           
            ],
          ),
        ),
      ),
    );
  }
}
