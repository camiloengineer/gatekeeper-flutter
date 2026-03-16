import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

/// ARCHITECTURE BOUNDARIES VALIDATOR
/// ----------------------------------
/// Enforces import rules between layers:
/// 1. features/ cannot import from another feature/
/// 2. shared/ cannot import from features/
/// 3. core/ cannot import from features/
/// 4. models/ cannot import from services/
final _rules = <String, bool Function(String import, String file)>{
  'Features cannot import other Features': (imp, file) {
    if (!file.contains('/features/')) return false;
    if (!imp.contains('/features/')) return false;
    final fileFeature = _extractFeatureName(file);
    final importFeature = _extractFeatureName(imp);
    return fileFeature != null && importFeature != null && fileFeature != importFeature;
  },
  'Shared cannot import Features': (imp, file) {
    return file.contains('/shared/') && imp.contains('/features/');
  },
  'Core cannot import Features': (imp, file) {
    return file.contains('/core/') && imp.contains('/features/');
  },
  'Models cannot import Services': (imp, file) {
    return file.contains('/models/') && imp.contains('/services/');
  },
};

String? _extractFeatureName(String path) {
  final match = RegExp(r'/features/([^/]+)').firstMatch(path);
  return match?.group(1);
}

int validate() {
  InfraUI.info('🔍 Architecture Integrity Check (Boundaries Validation)');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) return 2; // omit

  final dartFiles = getDartFiles();
  final violations = <String>[];

  for (final filePath in dartFiles) {
    final file = File(filePath);
    if (!file.existsSync()) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('import ')) continue;

      // Extract import path
      final match = RegExp("import\\s+['\"]([^'\"]+)['\"]").firstMatch(line);
      if (match == null) continue;
      final importPath = match.group(1)!;

      // Only check relative and package imports that reference internal code
      if (importPath.startsWith('dart:')) continue;
      if (!importPath.contains('/features/') &&
          !importPath.contains('/shared/') &&
          !importPath.contains('/core/') &&
          !importPath.contains('/models/') &&
          !importPath.contains('/services/')) continue;

      for (final entry in _rules.entries) {
        if (entry.value(importPath, filePath)) {
          violations.add('   $filePath:${i + 1}\n      Rule: ${entry.key}\n      Import: $importPath');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    InfraUI.error('\n❌ ARCHITECTURE VIOLATION: Forbidden dependencies detected.');
    InfraUI.warn('Please review the errors below and refactor imports to respect the Gravity Map.\n');
    for (final v in violations) {
      InfraUI.error(v);
      InfraUI.log('');
    }
    InfraUI.log('Rules:');
    InfraUI.log('1. Features cannot import other Features.');
    InfraUI.log('2. Shared cannot import Features.');
    InfraUI.log('3. Core cannot import Features.');
    InfraUI.log('4. Models cannot import Services.\n');
    return 1;
  }

  InfraUI.success('PASSED: Architecture boundaries validated.');
  return 0;
}
