import 'package:flutter/material.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';

class ProjectEditScreen extends StatefulWidget {
  const ProjectEditScreen({
    super.key,
    this.project,
  });

  final Project? project;

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();

  final ProjectRepository _projectRepository = ProjectRepository();

  @override
  void initState() {
    super.initState();

    final project = widget.project;

    if (project != null) {
      _nameController.text = project.name;
      _descriptionController.text = project.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project == null ? 'プロジェクト追加' : 'プロジェクト編集',
        ),
      ),     
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'プロジェクト名',
                  hintText: '例：PAMS Companion',
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
                  hintText: 'プロジェクトの目的や概要を入力してください。',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    final description = _descriptionController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('プロジェクト名を入力してください。'),
                        ),
                      );
                      return;
                    }

                    final existingProject = widget.project;
                    final now = DateTime.now();

                    final project = Project(
                      projectId: existingProject?.projectId ??
                          now.microsecondsSinceEpoch.toString(),
                      name: name,
                      description: description,
                      createdAt: existingProject?.createdAt ?? now,
                      updatedAt: now,
                    );

                    if (existingProject == null) {
                      await _projectRepository.insert(project);
                    } else {
                      await _projectRepository.update(project);
                    }

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).pop(true);                  
                  
                  },                 
                  icon: const Icon(Icons.save_outlined),
                  label: const Text(
                    '保存',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            
              if (widget.project != null) ...[
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
                              'このプロジェクトを削除しますか？',
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

                      await _projectRepository.delete(widget.project!.projectId);

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
