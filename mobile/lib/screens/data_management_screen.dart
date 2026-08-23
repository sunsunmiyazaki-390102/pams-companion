import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/data_backup_service.dart';
import '../services/data_restore_service.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({
    super.key,
  });

  Future<void> _createBackup(
    BuildContext context,
  ) async {
    try {
      final backupService =
          DataBackupService();

      final backupFile =
          await backupService.createBackupFile();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              backupFile.path,
            ),
          ],
          subject:
              'PAMS Companion Backup',
        ),
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'バックアップファイルを'
            '作成しました。',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'バックアップファイルを'
            '作成できませんでした。\n'
            '$error',
          ),
        ),
      );
    }
  }

  Future<void> _validateBackup(
    BuildContext context,
  ) async {
    try {
    
      final selectedFile =
          await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'json',
        ],
      );

      if (selectedFile == null) {
        return;
      }

      final path =
          selectedFile.path;    
      if (path == null) {
        throw const FormatException(
          '選択したファイルを'
          '読み込めませんでした。',
        );
      }

      final restoreService =
          DataRestoreService();

      final validationResult =
          await restoreService.validateBackupFile(
        File(path),
      );

      if (!context.mounted) {
        return;
      }

      final confirmed =
          await _confirmRestore(
        context,
        validationResult,
      );

      if (!context.mounted) {
        return;
      }

      if (!confirmed) {
        return;
      }

      await restoreService.restoreBackup(
        validationResult,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'バックアップから'
            'データを復元しました。',
          ),
        ),
      );     

    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'バックアップから'
            'データを復元できませんでした。\n'
            '$error',          
          ),
        ),
      );
    }
  }

  Future<bool> _confirmRestore(
    BuildContext context,
    DataRestoreValidationResult validationResult,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'バックアップから復元',
          ),
          content: Text(
            '現在のPAMS Companionのデータは、'
            '選択したバックアップの内容に'
            '置き換わります。\n\n'
            '復元する前に、現在のデータを'
            'バックアップしておくことを'
            'おすすめします。\n\n'
            'バックアップ作成日時:\n'
            '${validationResult.createdAt}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'キャンセル',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                '復元する',
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'データ管理',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'PAMS Companionのデータを'
              'バックアップ・復元できます。',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(height: 32),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'バックアップを作成',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '現在のAI相談、知識、テーマ、'
                      '今日の記憶などを'
                      '1つのバックアップファイルとして'
                      '保存します。',
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        _createBackup(
                          context,
                        );
                      },                  
                      icon: const Icon(
                        Icons.backup_outlined,
                      ),
                      label: const Text(
                        'バックアップを作成',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'バックアップから復元',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '以前に作成した'
                      'バックアップファイルから'
                      'PAMS Companionのデータを'
                      '復元します。',
                    ),
                    const SizedBox(height: 20),
                   
                    OutlinedButton.icon(
                      onPressed: () {
                        _validateBackup(
                          context,
                        );
                      },                   
                      icon: const Icon(
                        Icons.restore_outlined,
                      ),
                      label: const Text(
                        'バックアップから復元',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '※ バックアップファイルは、'
              '端末やクラウドなど安全な場所に'
              '保管してください。\n'
              '復元機能は現在準備中です。',
            ),           
          ],
        ),
      ),
    );
  }
}
