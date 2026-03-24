import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

final _whitelistedNumbers = <num>{0, 1, 2, 3, 4, 5, 10, 100, 255, 1000};
final _numberPattern = RegExp(r'\b\d+(?:\.\d+)?\b');

final _selfDocumentingPatterns = [
  RegExp(r'alpha:\s*$'),
  RegExp(r'Duration\(\s*\w+:\s*$'),
  RegExp(r'stops:\s*(?:const\s*)?\['),
  RegExp(r'Offset\(\s*$'),
];

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

bool _isSelfDocumenting(String line, int matchStart) {
  final prefix = line.substring(0, matchStart);
  return _selfDocumentingPatterns.any((p) => p.hasMatch(prefix));
}

List<_Violation> _checkNumberViolations(String line, int lineNum) {
  final violations = <_Violation>[];
  final matches = _numberPattern.allMatches(line);

  for (final match in matches) {
    final numStr = match.group(0)!;
    final parsed = double.tryParse(numStr);
    if (parsed == null || _whitelistedNumbers.contains(parsed)) continue;

    final intVal = parsed.toInt();
    if (parsed == intVal.toDouble() && _whitelistedNumbers.contains(intVal)) continue;

    if (_isSelfDocumenting(line, match.start)) continue;

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
      value: numStr,
      type: 'NUMBER',
      message: "Magic number $numStr detected. Move to 'constants/' directory.",
    ));
  }

  return violations;
}

int validate() {
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

  return 0;
}
