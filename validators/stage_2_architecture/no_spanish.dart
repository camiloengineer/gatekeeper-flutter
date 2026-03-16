import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

class _Violation {
  final String file;
  final int line;
  final String type;
  final String detail;
  final String snippet;
  final String? token;

  _Violation({
    required this.file,
    required this.line,
    required this.type,
    required this.detail,
    required this.snippet,
    this.token,
  });
}

int validate() {
  InfraUI.info('Validating English-only policy...');

  final config = loadRegistry('spanish.poison');
  if (config.isEmpty) return 0;

  final forbiddenChars = config['forbidden_chars'] as String? ?? '';
  final charRegex = RegExp('[$forbiddenChars]');
  final suffixes = (config['suffixes'] as List<dynamic>?)
      ?.map((s) => s as Map<String, dynamic>)
      .toList() ?? [];
  final ignoredWords = (config['ignored_words'] as List<dynamic>?)?.cast<String>() ?? [];

  final dartFiles = getDartFiles();
  final violations = <_Violation>[];

  for (final filePath in dartFiles) {
    // Exempt test files and gatekeeper internals
    if (filePath.contains('/test/') || filePath.endsWith('_test.dart')) continue;
    if (filePath.contains('/gatekeeper/')) continue;
    if (filePath.endsWith('.md')) continue;
    if (isPoisonZone(filePath)) continue;

    final file = File(filePath);
    if (!file.existsSync()) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // Check forbidden characters
      final chars = charRegex.allMatches(line).map((m) => m.group(0)!).toSet();
      if (chars.isNotEmpty) {
        violations.add(_Violation(
          file: filePath,
          line: lineNum,
          type: 'CHAR',
          detail: chars.join(', '),
          snippet: line.trim(),
        ));
      }

      // Morphological check — split camelCase and separators
      final tokens = line
          .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
          .split(RegExp(r'[^A-Za-z0-9]'))
          .where((t) => t.isNotEmpty)
          .toList();

      for (final token in tokens) {
        final lower = token.toLowerCase();
        if (ignoredWords.contains(lower)) continue;

        for (final rule in suffixes) {
          final suffix = rule['suffix'] as String;
          final minLen = rule['min'] as int;
          final msg = rule['msg'] as String;

          if (lower.length >= minLen && lower.endsWith(suffix)) {
            violations.add(_Violation(
              file: filePath,
              line: lineNum,
              type: 'MORPH',
              detail: msg,
              snippet: line.trim(),
              token: token,
            ));
            break;
          }
        }
      }
    }
  }

  if (violations.isEmpty) {
    InfraUI.success('PASSED: English-only validated');
    return 0;
  }

  InfraUI.error('\nLANGUAGE POLICY VIOLATIONS:');
  for (final v in violations) {
    InfraUI.error('   ${v.file}:${v.line} [${v.type}]');
    InfraUI.gray('      Violation: ${v.detail}${v.token != null ? ' in "${v.token}"' : ''}');
  }
  return 1;
}
