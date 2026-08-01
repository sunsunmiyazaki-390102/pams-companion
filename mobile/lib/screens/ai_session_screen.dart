import 'package:flutter/material.dart';

import '../models/ai_session.dart';
import '../models/project.dart';
import '../repositories/ai_session_repository.dart';
import 'ai_session_edit_screen.dart';

class AiSessionScreen extends StatefulWidget {
  const AiSessionScreen({
    super.key,
    required this.project,
  });

  final Project project;

  @override
  State<AiSessionScreen> createState() => _AiSessionScreenState();
}

class _AiSessionScreenState extends State<AiSessionScreen> {
  final AiSessionRepository _aiSessionRepository =
      AiSessionRepository();

  late Future<List<AiSession>> _sessions;

  @override
  void initState() {
    super.initState();

    _sessions = _aiSessionRepository.findByProjectId(
      widget.project.projectId,
    );
  }

  void _reloadSessions() {
    setState(() {
      _sessions = _aiSessionRepository.findByProjectId(
        widget.project.projectId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
      ),
      body: FutureBuilder<List<AiSession>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'AI Sessionを読み込めませんでした。',
              ),
            );
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                'AI Sessionはありません。',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemBuilder: (context, index) {
              final session = sessions[index];

              return ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                ),
                title: Text(session.title),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final wasSaved = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (context) => AiSessionEditScreen(
                projectId: widget.project.projectId,
              ),
            ),
          );

          if (wasSaved == true) {
            _reloadSessions();
          }
        },
        child: const Icon(Icons.add),
      ), 
    );
  }
}
