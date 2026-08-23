import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';

class DataBackupService {
  DataBackupService();

  final DatabaseHelper _databaseHelper =
      DatabaseHelper.instance;

  static const int backupVersion = 1;

  static const List<String> _tableNames = [
    'projects',
    'ai_sessions',
    'ai_conversations',
    'knowledge_candidates',
    'new_questions',
    'knowledge_assets',
    'knowledge_links',
    'reflection_queue',
    'daily_memories',
  ];

  Future<String> createBackupJson() async {
    final database =
        await _databaseHelper.database;

    final Map<String, Object?> data = {};

    for (final tableName in _tableNames) {
      final rows =
          await database.query(
        tableName,
      );

      data[tableName] = rows;
    }

    final backup = <String, Object?>{
      'backup_version': backupVersion,
      'created_at':
          DateTime.now().toIso8601String(),
      'database_version':
          DatabaseHelper.databaseVersion,
      'data': data,
    };

    return const JsonEncoder.withIndent(
      '  ',
    ).convert(
      backup,
    );
  }
 
  Future<File> createBackupFile() async {
    final backupJson =
        await createBackupJson();

    final directory =
        await getTemporaryDirectory();

    final now = DateTime.now();

    final year =
        now.year.toString().padLeft(4, '0');
    final month =
        now.month.toString().padLeft(2, '0');
    final day =
        now.day.toString().padLeft(2, '0');
    final hour =
        now.hour.toString().padLeft(2, '0');
    final minute =
        now.minute.toString().padLeft(2, '0');
    final second =
        now.second.toString().padLeft(2, '0');

    final fileName =
        'pams-companion-backup-'
        '$year$month$day-'
        '$hour$minute$second.json';

    final file = File(
      '${directory.path}/$fileName',
    );

    await file.writeAsString(
      backupJson,
    );

    return file;
  }
}
