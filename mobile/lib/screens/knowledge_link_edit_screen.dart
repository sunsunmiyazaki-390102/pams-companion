import 'package:flutter/material.dart';

import '../models/knowledge_link.dart';
import '../models/knowledge_link_type.dart';

class KnowledgeLinkEditScreen extends StatefulWidget {
  const KnowledgeLinkEditScreen({
    super.key,
    required this.link,
  });

  final KnowledgeLink link;

  @override
  State<KnowledgeLinkEditScreen> createState() =>
      _KnowledgeLinkEditScreenState();
}

class _KnowledgeLinkEditScreenState
    extends State<KnowledgeLinkEditScreen> {
  late String _selectedLinkType;

  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();

    _selectedLinkType = widget.link.linkType;

    _reasonController = TextEditingController(
      text: widget.link.linkReason,
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _confirmChanges() {
    FocusManager.instance.primaryFocus?.unfocus();

    final reason =
        _reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '結んだ理由を入力してください。',
          ),
        ),
      );
      return;
    }

    final updatedLink = KnowledgeLink(
      linkId: widget.link.linkId,
      fromKnowledgeId:
          widget.link.fromKnowledgeId,
      toKnowledgeId:
          widget.link.toKnowledgeId,
      linkType: _selectedLinkType,
      linkReason: reason,
      createdAt: widget.link.createdAt,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(
      updatedLink,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KnowledgeLink編集',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                '関係タイプ',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: RadioGroup<String>(
                    groupValue:
                        _selectedLinkType,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedLinkType = value;
                      });
                    },
                    child: Column(
                      children:
                          KnowledgeLinkType.values
                              .map(
                        (type) {
                          return RadioListTile<String>(
                            value: type,
                            title: Text(
                              KnowledgeLinkType
                                  .displayName(
                                type,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '結んだ理由',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'この二つのKnowledgeを'
                'なぜ結び付けたのかを'
                '自分の言葉で記録します。',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                minLines: 5,
                maxLines: 10,
                decoration:
                    const InputDecoration(
                  hintText:
                      '例：元の考えを、'
                      'より具体的に発展させた'
                      '内容だから。',
                  border:
                      OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancel,
                      child: const Text(
                        'キャンセル',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _confirmChanges,
                      icon: const Icon(
                        Icons.check,
                      ),
                      label: const Text(
                        '変更内容を確認',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
