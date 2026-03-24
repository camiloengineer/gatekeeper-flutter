import 'dart:io';

import '../../core/infra_ui.dart';

int validate() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    return 2;
  }

  final result = Process.runSync('dart', ['analyze', 'lib/']);
  final output = '${result.stdout}${result.stderr}'.trim();

  if (result.exitCode != 0) {
    InfraUI.error('\n❌ BUILD FAILED: dart analyze returned errors.');
    if (output.isNotEmpty) InfraUI.log(output);
    return 1;
  }

  if (output.contains('error •') || output.contains('error -')) {
    InfraUI.error('\n❌ BUILD FAILED: Analysis errors detected.');
    InfraUI.log(output);
    return 1;
  }

  return 0;
}
