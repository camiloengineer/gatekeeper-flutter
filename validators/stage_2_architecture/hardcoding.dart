import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

/// HARDCODING GOVERNANCE SENTRY
/// Prohibits magic strings and magic numbers in business logic.
/// Enforces centralization in core/constants.

final _whitelistedNumbers = <num>{0, 1, 2, 3, 4, 5, 10, 100, 255, 1000};

final _numberPattern = RegExp(r'\b\d+(?:\.\d+)?\b');

bool _isAllowedFile(String filePath) {
  final normalized = filePath.replaceAll('\\', '/');
  return normalized.contains('/constants/') ||
      normalized.contains('/models/') ||
      normalized.contains('/enums/') ||
      normalized.contains('/test/') ||
      normalized.endsWith('_test.dart') ||
      normalized.contains('/gatekeeper/') ||
      normalized.contains('/theme/') ||
      normalized.endsWith('.g.dart') ||
      normalized.endsWith('.freezed.dart');
}

class _Violation {
  final int line;
  final String value;
  final String type;
  final String message;

  _Violation({required this.line, required this.value, required this.type, required this.message});
}

List<_Violation> _checkNumberViolations(String line, int lineNum) {
  final violations = <_Violation>[];
  final matches = _numberPattern.allMatches(line);

  for (final match in matches) {
    final num = double.tryParse(match.group(0)!);
    if (num == null || _whitelistedNumbers.contains(num)) continue;
    if (num == num.toInt() && _whitelistedNumbers.contains(num.toInt())) continue;

    // Skip if adjacent to identifier chars or dots (likely a property access or version)
    final prevIdx = match.start - 1;
    final nextIdx = match.end;
    if (prevIdx >= 0) {
      final prev = line[prevIdx];
      if ('.\'"-_'.contains(prev) || RegExp(r'[a-zA-Z_$]').hasMatch(prev)) continue;
    }
    if (nextIdx < line.length) {
      final next = line[nextIdx];
      if ('.\'"-_'.contains(next) || RegExp(r'[a-zA-Z_$]').hasMatch(next)) continue;
    }

    violations.add(_Violation(
      line: lineNum,
      value: match.group(0)!,
      type: 'NUMBER',
      message: "Magic number ${match.group(0)} detected. Move to 'constants/' directory.",
    ));
  }

  return violations;
}

int validate() {
  InfraUI.info('[Hardcoding Sentry] Auditing business logic for magic numbers...');

  final dartFiles = getDartFiles();
  var hasViolations = false;

  for (final filePath in dartFiles) {
    if (_isAllowedFile(filePath)) continue;

    final file = File(filePath);
    if (!file.existsSync()) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Skip comments
      if (trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) continue;

      final violations = _checkNumberViolations(line, i + 1);
      if (violations.isNotEmpty) {
        hasViolations = true;
        for (final v in violations) {
          InfraUI.error('❌ [$filePath:${v.line}]');
          InfraUI.log('   Value: ${v.value}');
          InfraUI.warn('   Rule: ${v.message}');
          InfraUI.log('');
        }
      }
    }
  }

  if (hasViolations) return 1;

  InfraUI.success('[Hardcoding Sentry] PASSED: No magic values detected in business logic.');
  return 0;
}
