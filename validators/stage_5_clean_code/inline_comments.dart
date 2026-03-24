import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

int validate() {
  final dartFiles = getDartFiles();
  final violations = <(String file, int line, String snippet)>[];

  final directivePattern = RegExp(r'(//|/\*+)\s*(!|eslint-disable|eslint-enable|@ts-|@type|nosec|prettier-ignore|sourceMappingURL=|webpack[a-zA-Z]*:|istanbul\s|stylelint-disable|stylelint-enable|SWALLOW_REASON|ignore_for_file:|ignore:)');

  for (final filePath in dartFiles) {
    if (filePath.contains('/test/') || filePath.endsWith('_test.dart')) continue;
    if (filePath.contains('/gatekeeper/')) continue;
    if (isPoisonZone(filePath)) continue;

    final file = File(filePath);
    if (!file.existsSync()) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) continue;
      if (line.contains("'//'") || line.contains('"//"')) continue;
      if (line.contains("'/*'") || line.contains('"/*"')) continue;

      if (trimmed.startsWith('//')) {
        if (directivePattern.hasMatch(trimmed)) continue;
        violations.add((filePath, i + 1, trimmed));
        continue;
      }

      final commentStart = line.indexOf('//');
      if (commentStart != -1) {
        final prefix = line.substring(0, commentStart);
        if (prefix.trim().isNotEmpty) {
          final comment = line.substring(commentStart);
          if (directivePattern.hasMatch(comment)) continue;
          
          final countSingle = prefix.split("'").length - 1;
          final countDouble = prefix.split('"').length - 1;
          if (countSingle % 2 == 0 && countDouble % 2 == 0) {
             violations.add((filePath, i + 1, trimmed));
          }
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    InfraUI.error('\n❌ INLINE COMMENTS VIOLATION: ${violations.length} forbidden comments found.');
    for (final (file, line, snippet) in violations) {
      InfraUI.error('   $file:$line  $snippet');
    }
    InfraUI.warn('\n   Action: Use doc comments (///) or move implementation notes to documentation.');
    return 1;
  }

  return 0;
}
