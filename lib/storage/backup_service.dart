import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/child.dart';
import '../models/year_photo.dart';

class BackupService {
  /// Create a JSON backup of all children data
  static Future<File> createBackup(List<Child> children) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final file = File('${backupDir.path}/seeme_grow_backup_$timestamp.json');

    final jsonData = jsonEncode(
      children.map((c) => c.toJson()).toList(),
    );

    await file.writeAsString(jsonData);
    return file;
  }

  /// Restore children data from a backup file
  static Future<List<Child>> restoreBackup(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content) as List<dynamic>;

    return decoded
        .map((e) => Child.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// List all backup files
  static Future<List<File>> listBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');

    if (!await backupDir.exists()) {
      return [];
    }

    return backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
  }
}
