import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

/// CONSOLE LOGS VALIDATOR
/// ----------------------
/// Detects print() and debugPrint() statements in production code.
/// Exempts test files and the gatekeeper itself.

final _printPattern = RegExp(r'\b(print|debugPrint|log)\s*\(');

const _sanctionedPaths = [
  'gatekeeper/',
];

bool _isSanctioned(String filePath) {
  final normalized = filePath.replaceAll('\\', '/');
  return _sanctionedPaths.any((s) => normalized.contains(s)) ||
      normalized.contains('/test/') ||
      normalized.endsWith('_test.dart');
}

int validate() {
  InfraUI.info('🧹 Clean Console Logs Validator...');

  final dartFiles = getDartFiles();
  final violations = <(String file, int line, String method)>[];

  for (final filePath in dartFiles) {
    if (_isSanctioned(filePath)) continue;

    final file = File(filePath);
    if (!file.existsSync()) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Skip comments
      if (line.startsWith('//') || line.startsWith('/*') || line.startsWith('*')) continue;

      final match = _printPattern.firstMatch(line);
      if (match != null) {
        violations.add((filePath, i + 1, match.group(1)!));
      }
    }
  }

  if (violations.isNotEmpty) {
    InfraUI.error('\n❌ CONSOLE VIOLATION: ${violations.length} print statements found.\n');
    for (final (file, line, method) in violations) {
      InfraUI.error('   $file:$line  $method()');
    }
    InfraUI.warn('\n   Action: Remove or replace print calls with a proper logging solution.\n');
    return 1;
  }

  InfraUI.success('✅ Console Logs Guard: Passed.');
  return 0;
}
