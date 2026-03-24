import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

int validate() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return 2;

  final dartFiles = getDartFiles();
  if (dartFiles.isEmpty) return 0;

  final allFiles = getAllFiles();
  final contentBuffer = StringBuffer();
  for (final filePath in allFiles) {
    if (!filePath.endsWith('.dart') && !filePath.endsWith('.yaml')) continue;
    final file = File(filePath);
    if (file.existsSync()) {
      contentBuffer.write(file.readAsStringSync());
    }
  }

  final totalContent = contentBuffer.toString();
  final orphans = <String>[];

  for (final file in dartFiles) {
    if (file.endsWith('main.dart')) continue;
    final fileName = basename(file);
    if (!totalContent.contains(fileName)) {
      orphans.add(file);
    }
  }

  if (orphans.isNotEmpty) {
    InfraUI.error('\n👻 GHOST CODE DETECTED: ${orphans.length} orphan files found.');
    for (final orphan in orphans) {
      InfraUI.error('   $orphan (Not imported anywhere)');
    }
    InfraUI.warn('\n   Action: Delete orphan files if they are not needed.');
    return 1;
  }

  return 0;
}
