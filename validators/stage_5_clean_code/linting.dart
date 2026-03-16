import 'dart:io';

import '../../core/infra_ui.dart';

int validate() {
  InfraUI.info('🔍 Running dart analyze (full linting)...');

  final result = Process.runSync('dart', ['analyze', 'lib/']);
  final output = '${result.stdout}${result.stderr}'.trim();

  if (result.exitCode != 0) {
    InfraUI.error('\n❌ LINTING FAILED: dart analyze returned errors.');
    if (output.isNotEmpty) InfraUI.log(output);
    return 1;
  }

  // Also check for warnings
  if (output.contains(' warning ') || output.contains(' info ')) {
    InfraUI.warn('\n⚠️  LINTING WARNINGS/INFOS:');
    InfraUI.log(output);
    // Warnings don't block, only errors do
  }

  InfraUI.success('✅ Linting passed (dart analyze clean).');
  return 0;
}
