import 'dart:io';

import '../../core/infra_ui.dart';

int validate() {
  try {
    final gitDirResult = Process.runSync('git', ['rev-parse', '--git-dir']);
    final gitDir = (gitDirResult.stdout as String).trim();
    final msgFile = File('$gitDir/COMMIT_EDITMSG');

    if (!msgFile.existsSync()) {
      return 0;
    }

    final message = msgFile.readAsStringSync();
    final coAuthorPattern = RegExp(r'^Co-authored-by:', multiLine: true, caseSensitive: false);

    if (coAuthorPattern.hasMatch(message)) {
      final matches = RegExp(r'^Co-authored-by:.+$', multiLine: true, caseSensitive: false)
          .allMatches(message)
          .map((m) => m.group(0)!.trim())
          .toList();

      InfraUI.error('\n⛔ AUTHORSHIP VIOLATION: Co-authored-by is forbidden.');
      InfraUI.warn('   Detected:');
      for (final line in matches) {
        InfraUI.warn('   - $line');
      }
      InfraUI.log('   Reason: Every commit must have a single accountable human author.');
      InfraUI.log('   Action: Remove all Co-authored-by lines from the commit message.\n');
      return 1;
    }

    return 0;
  } catch (e) {
    InfraUI.warn('⚠️  [Authorship] Could not resolve Git commit message. Validation skipped.');
    InfraUI.log('   Technical Reason: $e\n');
    return 0;
  }
}
