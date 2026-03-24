import 'dart:io';

import '../../core/infra_ui.dart';

int validate() {
  final targetDir = Directory('lib').existsSync() ? 'lib/' : '.';
  final result = Process.runSync('dart', ['analyze', targetDir]);
  final output = '${result.stdout}${result.stderr}'.trim();

  if (result.exitCode != 0) {
    InfraUI.error('\n❌ LINTING FAILED: dart analyze returned errors.');
    if (output.isNotEmpty) InfraUI.log(output);
    return 1;
  }

  if (output.contains(' warning ') || output.contains(' info ')) {
    InfraUI.warn('\n⚠️  LINTING WARNINGS/INFOS:');
    InfraUI.log(output);
  }

  return 0;
}
