import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart' as vr;

const _forbiddenDirs = [
  'services',
  'utils',
  'helpers',
  'constants',
  'guards',
  'interceptors',
  'pipes',
  'directives',
  'interfaces',
  'types',
  'modules',
  'mocks',
  'adapters',
];

const _allowedFeatureDirs = [
  'components',
  'models',
  '+state',
];

class _Violation {
  final String file;
  final String rule;
  final String message;
  final String allowed;
  final String severity;

  _Violation({
    required this.file,
    required this.rule,
    required this.message,
    required this.allowed,
    this.severity = 'HIGH',
  });
}

String _getSuggestedLocation(String forbiddenDir) {
  const mappings = {
    'services': 'lib/core/services/',
    'models': 'lib/core/models/ (Domain) or features/<feat>/models/ (Local UI)',
    'constants': 'lib/core/constants/',
    'utils': 'lib/shared/utils/',
    'mocks': 'test/fixtures/',
    'adapters': 'lib/core/adapters/',
    'helpers': 'lib/shared/utils/',
    'interfaces': 'lib/core/models/',
    'types': 'lib/core/models/',
  };
  return mappings[forbiddenDir] ?? 'lib/core/ or lib/shared/';
}

void _checkEmptyDirs(Directory dir, List<_Violation> violations) {
  if (!dir.existsSync()) return;

  const ignoreDirs = [
    '.git', '.dart_tool', 'build', 'node_modules', '.idea',
    '.vscode', 'android', 'ios', 'windows', 'macos', 'linux', 'web',
  ];

  final entries = dir.listSync();
  if (entries.isEmpty) {
    violations.add(_Violation(
      file: dir.path,
      rule: 'Empty Directory',
      message: 'Directory is empty. Empty directories are dead weight in the architecture.',
      allowed: 'Delete the folder or add architectural content.',
      severity: 'MEDIUM',
    ));
    return;
  }

  for (final entry in entries) {
    if (entry is Directory) {
      final name = vr.basename(entry.path);
      if (!ignoreDirs.contains(name)) {
        _checkEmptyDirs(entry, violations);
      }
    }
  }
}

void _validateFeatureStructure(Directory featureDir, List<_Violation> violations) {
  final entries = featureDir.listSync();

  for (final entry in entries) {
    final name = vr.basename(entry.path);
    final relativePath = entry.path;

    if (entry is Directory) {
      if (_forbiddenDirs.contains(name)) {
        violations.add(_Violation(
          file: relativePath,
          rule: 'Forbidden directory in features/',
          message: 'Forbidden directory "$name" in feature',
          allowed: 'Move to: ${_getSuggestedLocation(name)}',
        ));
      } else if (!_allowedFeatureDirs.contains(name)) {
        violations.add(_Violation(
          file: relativePath,
          rule: 'Non-Standard Directory Structure',
          message: 'Directory "$name" is not a standard architectural layer',
          allowed: 'Use: ${_allowedFeatureDirs.join(", ")}',
        ));
      }
    } else if (entry is File) {
      if (name != 'index.dart' &&
          !name.endsWith('_page.dart') &&
          !name.endsWith('.dart')) {
        violations.add(_Violation(
          file: relativePath,
          rule: 'Strict Feature Root',
          message: 'File "$name" is not allowed in feature root',
          allowed: 'Page files (*_page.dart) or Dart files',
        ));
      }
    }
  }
}

int validate() {
  final violations = <_Violation>[];

  final libDir = Directory('lib');
  if (libDir.existsSync()) {
    _checkEmptyDirs(libDir, violations);
  }

  final featuresDir = Directory('lib/features');
  if (featuresDir.existsSync()) {
    for (final entry in featuresDir.listSync()) {
      if (entry is Directory) {
        _validateFeatureStructure(entry, violations);
      }
    }
  }

  if (violations.isEmpty) {
    return 0;
  }

  InfraUI.error('\nSTRUCTURE & FEATURES ARCHITECTURE VIOLATIONS:');
  InfraUI.warn('\n   Clean Architecture: Dead weight (empty folders) and forbidden nesting detected\n');

  for (final v in violations) {
    InfraUI.error('   ${v.file}');
    InfraUI.gray('      Rule: ${v.rule}');
    InfraUI.warn('      - ${v.message}');
    InfraUI.success('      + ${v.allowed}');
    InfraUI.gray('      Severity: ${v.severity}\n');
  }

  return 1;
}
