import 'dart:io';

import '../../core/infra_ui.dart';

int validate() {
  InfraUI.info('🚀 Flutter Build Integrity Check...');

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    InfraUI.error('❌ No pubspec.yaml found. Not a Flutter/Dart project.');
    return 1;
  }

  // Use dart analyze as the build integrity check — it's fast and catches
  // type errors, missing imports, and compilation issues without building APK.
  InfraUI.log('   Executing: dart analyze lib/\n');

  final result = Process.runSync('dart', ['analyze', 'lib/']);
  final output = '${result.stdout}${result.stderr}'.trim();

  if (result.exitCode != 0) {
    InfraUI.error('\n❌ BUILD FAILED: dart analyze returned errors.');
    if (output.isNotEmpty) InfraUI.log(output);
    return 1;
  }

  // Check for infos/warnings — we only fail on errors
  if (output.contains('error •') || output.contains('error -')) {
    InfraUI.error('\n❌ BUILD FAILED: Analysis errors detected.');
    InfraUI.log(output);
    return 1;
  }

  InfraUI.success('✅ Build integrity confirmed (dart analyze clean).');
  return 0;
}
