import 'package:flutter/material.dart';

import '../models/knowledge_asset.dart';
import '../models/knowledge_type.dart';
import '../repositories/knowledge_asset_repository.dart';


class KnowledgeEditScreen extends StatefulWidget {
  const KnowledgeEditScreen({
    super.key,
    required this.asset,
  });

  final KnowledgeAsset asset;

  @override
  State<KnowledgeEditScreen> createState() =>
      _KnowledgeEditScreenState();
}

class _KnowledgeEditScreenState
    extends State<KnowledgeEditScreen> {
  final KnowledgeAssetRepository _repository =
      KnowledgeAssetRepository();

  late final TextEditingController _contentController;

  late String _selectedKnowledgeType;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _contentController = TextEditingController(
      text: widget.asset.content,
    );
    _selectedKnowledgeType =
        widget.asset.knowledgeType;  
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '知識の内容を入力してください。',
          ),
        ),
      );
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
    
      final updatedAsset = widget.asset.copyWith(
        content: content,
        knowledgeType:
            _selectedKnowledgeType,
        updatedAt: DateTime.now(),
      );

      await _repository.update(updatedAsset);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(updatedAsset);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '知識を更新できませんでした。',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知識編集'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '知識資産を育てる',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                '考えが深まった内容を、自分の言葉で書き加えられます。',
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),

              Text(
                '分類',
                style:
                    Theme.of(context)
                        .textTheme
                        .titleMedium,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue:
                    _selectedKnowledgeType,
                decoration:
                    const InputDecoration(
                  border:
                      OutlineInputBorder(),
                ),
                items:
                    KnowledgeType.values
                        .map(
                  (type) =>
                      DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      KnowledgeType
                          .displayName(
                        type,
                      ),
                    ),
                  ),
                )
                        .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedKnowledgeType =
                        value;
                  });
                },
              ),

              const SizedBox(height: 32),
              Text(
                '内容',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                minLines: 10,
                maxLines: null,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: '知識の内容を入力してください。',
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                        ),
                  label: Text(
                    _isSaving
                        ? '保存しています…'
                        : '変更を保存する',
                    style: const TextStyle(fontSize: 18),
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
