import 'dart:io';

import '../../core/infra_ui.dart';

int validate() {
  InfraUI.info('🧪 Running Flutter tests...');

  final testDir = Directory('test');
  if (!testDir.existsSync()) {
    InfraUI.warn('⚠️  No test/ directory found. Testing skipped.');
    return 2; // omit
  }

  final testFiles = testDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_test.dart'))
      .toList();

  if (testFiles.isEmpty) {
    InfraUI.warn('⚠️  No test files found. Testing skipped.');
    return 2; // omit
  }

  final result = Process.runSync('flutter', ['test', '--no-pub']);
  final output = '${result.stdout}${result.stderr}'.trim();

  if (result.exitCode != 0) {
    InfraUI.error('\n❌ TESTS FAILED:');
    if (output.isNotEmpty) InfraUI.log(output);
    return 1;
  }

  InfraUI.success('✅ All tests passed.');
  return 0;
}
