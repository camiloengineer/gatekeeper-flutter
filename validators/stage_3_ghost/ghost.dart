import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

/// GHOST CODE DETECTION
/// --------------------
/// Detects:
/// 1. Unused imports (via dart analyze)
/// 2. Unused dependencies in pubspec.yaml
/// 3. Dart files in lib/ not imported anywhere

int validate() {
  InfraUI.info('👻 Ghost Code Detection...');

  var hasGhosts = false;

  // 1. Check for unused imports via dart analyze output
  final analyzeResult = Process.runSync('dart', ['analyze', '--no-fatal-warnings', 'lib/']);
  final output = '${analyzeResult.stdout}'.trim();

  final unusedImportLines = output
      .split('\n')
      .where((l) => l.contains('unused_import'))
      .toList();

  if (unusedImportLines.isNotEmpty) {
    hasGhosts = true;
    InfraUI.error('\n❌ UNUSED IMPORTS DETECTED:');
    for (final line in unusedImportLines) {
      InfraUI.warn('   $line');
    }
  }

  // 2. Check for Dart files not referenced by any other file
  final dartFiles = getDartFiles();
  final allContents = <String, String>{};
  for (final f in dartFiles) {
    final file = File(f);
    if (file.existsSync()) {
      allContents[f] = file.readAsStringSync();
    }
  }

  final orphanFiles = <String>[];
  for (final filePath in dartFiles) {
    if (filePath.endsWith('main.dart')) continue;
    if (filePath.contains('/gatekeeper/')) continue;

    final filename = filePath.split('/').last;
    final isReferenced = allContents.entries.any((entry) {
      if (entry.key == filePath) return false;
      return entry.value.contains(filename);
    });

    if (!isReferenced) {
      orphanFiles.add(filePath);
    }
  }

  if (orphanFiles.isNotEmpty) {
    hasGhosts = true;
    InfraUI.error('\n❌ ORPHAN FILES (not imported anywhere):');
    for (final f in orphanFiles) {
      InfraUI.warn('   $f');
    }
  }

  // 3. Check for unused dependencies in pubspec.yaml
  final pubspec = File('pubspec.yaml');
  if (pubspec.existsSync()) {
    final content = pubspec.readAsStringSync();
    final depSection = RegExp(r'dependencies:\s*\n((?:  .+\n)*)').firstMatch(content);
    if (depSection != null) {
      final deps = RegExp(r'^\s{2}(\w[\w_]*):', multiLine: true)
          .allMatches(depSection.group(1)!)
          .map((m) => m.group(1)!)
          .where((d) => d != 'flutter')
          .toList();

      final allCode = allContents.values.join('\n');
      final unusedDeps = deps.where((dep) {
        // Convert snake_case package to import format
        final packageImport = "package:$dep/";
        return !allCode.contains(packageImport);
      }).toList();

      if (unusedDeps.isNotEmpty) {
        hasGhosts = true;
        InfraUI.error('\n❌ UNUSED DEPENDENCIES in pubspec.yaml:');
        for (final dep in unusedDeps) {
          InfraUI.warn('   $dep');
        }
      }
    }
  }

  if (hasGhosts) {
    InfraUI.error('\n❌ GHOST CODE DETECTED: Unused code or dependencies found.');
    return 1;
  }

  InfraUI.success('✅ No ghost code detected.');
  return 0;
}
