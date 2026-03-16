import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

int validate() {
  InfraUI.info('Validating anti-corruption layer...');

  final dictionary = loadRegistry('corruption.poison');
  if (dictionary.isEmpty) return 0;

  final filenameCriminals = (dictionary['filename_criminals'] as List<dynamic>?)?.cast<String>() ?? [];
  final codeCriminals = (dictionary['code_criminals'] as List<dynamic>?)?.cast<String>() ?? [];
  final patterns = (dictionary['patterns'] as List<dynamic>?)?.cast<String>() ?? [];

  // Build filename patterns
  final filenamePatterns = <(RegExp, String)>[];
  for (final kw in filenameCriminals) {
    filenamePatterns.add((
      RegExp('(^|[_.-])$kw([_.-]|\$)', caseSensitive: false),
      "Criminal signature '$kw' detected with separators",
    ));
    final capitalized = kw[0].toUpperCase() + kw.substring(1);
    filenamePatterns.add((
      RegExp('[a-z]$capitalized|^$capitalized'),
      "Criminal signature '$capitalized' detected in camel/Pascal case",
    ));
  }

  // Build code patterns
  final codePatterns = <(RegExp, String)>[];
  for (final td in codeCriminals) {
    codePatterns.add((
      RegExp('\\b${RegExp.escape(td)}\\b', caseSensitive: false),
      "Criminal signature '$td' detected in code content",
    ));
  }
  for (final pat in patterns) {
    codePatterns.add((
      RegExp(pat, caseSensitive: false),
      'Forbidden pattern detected in code content',
    ));
  }

  final allFiles = getAllFiles();
  var totalViolations = 0;

  for (final filePath in allFiles) {
    if (isPoisonZone(filePath)) continue;

    // Filename check
    final filename = basename(filePath);
    for (final (regex, msg) in filenamePatterns) {
      if (regex.hasMatch(filename)) {
        totalViolations++;
        InfraUI.error('\n❌ NON-COMPLIANT FILENAME in $filePath:');
        InfraUI.warn('   Violation: $msg');
        InfraUI.log('   Action: Rename the file to reflect its current purpose.');
      }
    }

    // Content check — only Dart files in lib/
    if (!filePath.endsWith('.dart')) continue;
    if (filePath.contains('/test/') || filePath.endsWith('_test.dart')) continue;
    if (filePath.contains('/gatekeeper/')) continue;
    if (filePath.contains('/constants/')) continue;
    if (filePath.contains('/enums/')) continue;

    final file = File(filePath);
    if (!file.existsSync()) continue;

    final lines = file.readAsLinesSync();
    var inBlockComment = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('/*')) inBlockComment = true;

      final isSafeZone = inBlockComment || trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.endsWith('*/');

      if (!isSafeZone) {
        for (final (regex, msg) in codePatterns) {
          if (regex.hasMatch(line)) {
            totalViolations++;
            InfraUI.error('\n❌ ANTI-CORRUPTION VIOLATION in $filePath:');
            InfraUI.warn('   Line ${i + 1}: $msg');
            InfraUI.gray('      > ${trimmed}');
          }
        }
      }

      if (trimmed.endsWith('*/')) inBlockComment = false;
    }
  }

  if (totalViolations > 0) {
    InfraUI.warn('\n   If you believe this is a false positive, report it immediately.');
    return 1;
  }

  InfraUI.success('PASSED: Anti-Corruption audit completed. No criminal signatures detected.');
  return 0;
}
