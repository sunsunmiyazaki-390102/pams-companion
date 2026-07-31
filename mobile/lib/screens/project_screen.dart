import 'package:flutter/material.dart';

import '../models/project.dart';
import '../repositories/project_repository.dart';
import 'project_edit_screen.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final ProjectRepository _projectRepository = ProjectRepository();

  late Future<List<Project>> _projects;

  @override
  void initState() {
    super.initState();
    _projects = _projectRepository.findAll();
  }

  void _reloadProjects() {
    setState(() {
      _projects = _projectRepository.findAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロジェクト'),
      ),
      body: FutureBuilder<List<Project>>(
        future: _projects,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('プロジェクトを読み込めませんでした。'),
            );
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return const Center(
              child: Text(
                'プロジェクトはありません。',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(project.name),
                subtitle: project.description.isEmpty
                    ? null
                    : Text(project.description),
                onTap: () async {
                  final wasSaved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (context) => ProjectEditScreen(
                        project: project,
                      ),
                    ),
                  );

                  if (wasSaved == true) {
                    _reloadProjects();
                  }
                },
              );            
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final wasSaved = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (context) => const ProjectEditScreen(),
            ),
          );

          if (wasSaved == true) {
            _reloadProjects();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
