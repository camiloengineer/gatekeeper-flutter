import 'dart:io';

import '../../core/infra_ui.dart';
import '../../core/validator_runner.dart';

int validate() {
  final result = checkArchitectureMutation();

  if (!result.hasMutation) return 0;

  if (!result.isAuthorized) {
    final isCommitContext = Platform.environment.containsKey('GIT_INDEX_FILE');

    if (isCommitContext) {
      InfraUI.error('❌ MUTATION=true is required for this commit.');
      InfraUI.warn('   Infrastructure files modified:');
      for (final f in result.files) {
        InfraUI.log('      - $f');
      }
      InfraUI.log('   Action: Run commit with MUTATION=true prefix.\n');
      return 1;
    }

    InfraUI.warn('⚠️  Architecture Mutation detected (MUTATION=true required for commit)');
    return 0;
  }

  return 0;
}
