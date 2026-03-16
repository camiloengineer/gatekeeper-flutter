import 'dart:io';

import '../../core/infra_ui.dart';

final _forbiddenPatterns = [
  RegExp(r'GEMINI\.md', caseSensitive: false),
  RegExp(r'CLAUDE\.md', caseSensitive: false),
  RegExp(r'COPILOT\.md', caseSensitive: false),
  RegExp(r'\.claudex?$', caseSensitive: false),
  RegExp(r'\.geminiignore$', caseSensitive: false),
  RegExp(r'\.copilot-instructions', caseSensitive: false),
];

int validate() {
  List<String> allTrackedFiles;
  try {
    final result = Process.runSync('git', ['ls-files']);
    allTrackedFiles = (result.stdout as String)
        .split('\n')
        .where((l) => l.isNotEmpty)
        .toList();
  } catch (_) {
    return 0;
  }

  final violations = allTrackedFiles.where((file) {
    return _forbiddenPatterns.any((pattern) => pattern.hasMatch(file));
  }).toList();

  if (violations.isNotEmpty) {
    InfraUI.error('\n❌ FORBIDDEN FILES DETECTED IN REPOSITORY');
    InfraUI.warn('   The following prohibited files were found in the current state:');
    for (final v in violations) {
      InfraUI.error('      - $v');
    }
    InfraUI.log('\n   Reason: AI instruction files and local-only manifests are strictly FORBIDDEN.');
    InfraUI.success('   Action: Use "git rm <file>" to remove them from the repository history.\n');
    return 1;
  }

  return 0;
}
