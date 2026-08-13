import 'package:flutter/material.dart';

import '../models/ai_conversation.dart';
import '../models/ai_response_status.dart';
import '../repositories/ai_conversation_repository.dart';

class WaitingAiResponseScreen extends StatefulWidget {
  const WaitingAiResponseScreen({
    super.key,
    required this.conversation,
  });

  final AiConversation conversation;

  @override
  State<WaitingAiResponseScreen> createState() =>
      _WaitingAiResponseScreenState();
}

class _WaitingAiResponseScreenState
    extends State<WaitingAiResponseScreen> {
  static const List<String> _aiProviders = [
    'ChatGPT',
    'Gemini',
    'Claude',
    'その他',
  ];

  final AiConversationRepository
      _conversationRepository =
      AiConversationRepository();

  final TextEditingController
      _responseController =
      TextEditingController();

  String? _selectedAiProvider;
  bool _isSaving = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _saveResponse() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSaving) {
      return;
    }

    final aiProvider = _selectedAiProvider;
    final aiResponse =
        _responseController.text.trim();

    if (aiProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '利用したAIを選択してください。',
          ),
        ),
      );
      return;
    }

    if (aiResponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AIからの回答を貼り付けてください。',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedConversation =
        widget.conversation.copyWith(
      aiResponse: aiResponse,
      aiProvider: aiProvider,
      responseStatus:
          AiResponseStatus.received,
      updatedAt: DateTime.now(),
    );

    try {
      await _conversationRepository.update(
        updatedConversation,
      );

      final savedConversation =
          await _conversationRepository.findById(
        widget.conversation.conversationId,
      );

      if (savedConversation == null) {
        throw StateError(
          '更新したAI相談を確認できませんでした。',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        savedConversation,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI回答を保存できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI回答を取り込む',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Text(
                '回答待ちのAI相談',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'あなたの質問',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        widget
                            .conversation
                            .userMessage,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '利用したAI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue:
                    _selectedAiProvider,
                decoration:
                    const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'AIサービス',
                ),
                items: _aiProviders
                    .map(
                      (provider) =>
                          DropdownMenuItem<String>(
                        value: provider,
                        child: Text(provider),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAiProvider = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'AIからの回答',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller:
                    _responseController,
                minLines: 10,
                maxLines: null,
                decoration:
                    const InputDecoration(
                  hintText:
                      'AIから受け取った回答を'
                      'ここへ貼り付けてください。',
                  border:
                      OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '回答は原文のまま保存します。',
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed:
                    _isSaving
                        ? null
                        : _saveResponse,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                      ),
                label: Text(
                  _isSaving
                      ? '保存しています...'
                      : 'AI回答を保存する',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
