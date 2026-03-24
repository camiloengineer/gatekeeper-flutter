import 'dart:io';

import '../../core/infra_ui.dart';

int validate() {
  final testDir = Directory('test');
  if (!testDir.existsSync()) return 2;

  final testFiles = testDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_test.dart'))
      .toList();

  if (testFiles.isEmpty) return 2;

  final result = Process.runSync('flutter', ['test', '--no-pub', '--reporter', 'expanded']);
  final output = '${result.stdout}${result.stderr}'.trim();

  if (result.exitCode != 0) {
    InfraUI.error('\n❌ TESTING FAILED: flutter test returned errors.');
    if (output.isNotEmpty) InfraUI.log(output);
    return 1;
  }

  return 0;
}
