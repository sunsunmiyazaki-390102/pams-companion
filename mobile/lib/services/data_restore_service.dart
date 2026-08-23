import 'dart:convert';
import 'dart:io';

import 'data_backup_service.dart';
import '../database/database_helper.dart';

class DataRestoreValidationResult {
  const DataRestoreValidationResult({
    required this.backupVersion,
    required this.createdAt,
    required this.databaseVersion,
    required this.data,
  });

  final int backupVersion;
  final String createdAt;
  final int databaseVersion;
  final Map<String, dynamic> data;
}

class DataRestoreService {
  DataRestoreService();

  final DatabaseHelper _databaseHelper =
    DatabaseHelper.instance; 
 
  static const List<String> _requiredTableNames = [
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

  Future<DataRestoreValidationResult>
      validateBackupFile(
    File file,
  ) async {
    final jsonText =
        await file.readAsString();

    final decoded =
        jsonDecode(jsonText);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'バックアップファイルの形式が正しくありません。',
      );
    }

    final backupVersion =
        decoded['backup_version'];

    final createdAt =
        decoded['created_at'];

    final databaseVersion =
        decoded['database_version'];

    final data =
        decoded['data'];

    if (backupVersion is! int) {
      throw const FormatException(
        'backup_versionを確認できません。',
      );
    }

    if (backupVersion !=
        DataBackupService.backupVersion) {
      throw FormatException(
        '対応していないバックアップ形式です。'
        '\n'
        'backup_version: $backupVersion',
      );
    }

    if (createdAt is! String ||
        DateTime.tryParse(createdAt) == null) {
      throw const FormatException(
        'created_atを確認できません。',
      );
    }

    if (databaseVersion is! int) {
      throw const FormatException(
        'database_versionを確認できません。',
      );
    }

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'バックアップデータを確認できません。',
      );
    }

    for (final tableName
        in _requiredTableNames) {
      final tableData =
          data[tableName];

      if (tableData is! List) {
        throw FormatException(
          '$tableName のデータを確認できません。',
        );
      }

      for (final row in tableData) {
        if (row is! Map<String, dynamic>) {
          throw FormatException(
            '$tableName のレコード形式が'
            '正しくありません。',
          );
        }
      }
    }

    return DataRestoreValidationResult(
      backupVersion: backupVersion,
      createdAt: createdAt,
      databaseVersion: databaseVersion,
      data: data,
    );
  }
  Future<void> restoreBackup(
    DataRestoreValidationResult validationResult,
  ) async {
    final database =
        await _databaseHelper.database;

    final data =
        validationResult.data;

    await database.transaction(
      (transaction) async {
        const deleteOrder = [
          'knowledge_links',
          'reflection_queue',
          'new_questions',
          'knowledge_assets',
          'knowledge_candidates',
          'ai_conversations',
          'ai_sessions',
          'projects',
          'daily_memories',
        ];

        for (final tableName in deleteOrder) {
          await transaction.delete(
            tableName,
          );
        }

        const insertOrder = [
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

        for (final tableName in insertOrder) {
          final rows =
              data[tableName] as List<dynamic>;

          for (final row in rows) {
            await transaction.insert(
              tableName,
              Map<String, Object?>.from(
                row as Map<String, dynamic>,
              ),
            );
          }
        }
      },
    );
  }
}
