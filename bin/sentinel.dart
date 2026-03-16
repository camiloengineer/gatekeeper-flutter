// ignore_for_file: avoid_print
import 'dart:io';

import '../core/infra_ui.dart';
import '../core/manifest.dart';

import '../validators/stage_1_integrity/authorship.dart' as authorship;
import '../validators/stage_1_integrity/forbidden_files.dart' as forbidden_files;
import '../validators/stage_1_integrity/mutation.dart' as mutation;
import '../validators/stage_1_integrity/build.dart' as build_validator;
import '../validators/stage_2_architecture/boundaries.dart' as boundaries;
import '../validators/stage_2_architecture/features_architecture.dart' as features_arch;
import '../validators/stage_2_architecture/anti_corruption.dart' as anti_corruption;
import '../validators/stage_2_architecture/no_spanish.dart' as no_spanish;
import '../validators/stage_2_architecture/hardcoding.dart' as hardcoding;
import '../validators/stage_3_ghost/ghost.dart' as ghost;
import '../validators/stage_4_testing/testing.dart' as testing;
import '../validators/stage_5_clean_code/linting.dart' as linting;
import '../validators/stage_5_clean_code/console_logs.dart' as console_logs;

typedef ValidatorFn = int Function();

class _Stage {
  final String name;
  final String emoji;
  final List<(String name, ValidatorFn fn)> validators;

  const _Stage({required this.name, required this.emoji, required this.validators});
}

const int _labelMaxWidth = 30;
const int _minDots = 3;
const int _reportWidth = 60;

final List<_Stage> _stages = [
  _Stage(name: 'Integrity', emoji: '🛡️', validators: [
    ('authorship', authorship.validate),
    ('forbidden_files', forbidden_files.validate),
    ('mutation', mutation.validate),
    ('build', build_validator.validate),
  ]),
  _Stage(name: 'Architecture', emoji: '🏛️', validators: [
    ('boundaries', boundaries.validate),
    ('features_architecture', features_arch.validate),
    ('anti_corruption', anti_corruption.validate),
    ('no_spanish', no_spanish.validate),
    ('hardcoding', hardcoding.validate),
  ]),
  _Stage(name: 'Ghost', emoji: '✂️', validators: [
    ('ghost', ghost.validate),
  ]),
  _Stage(name: 'Testing', emoji: '🧪', validators: [
    ('testing', testing.validate),
  ]),
  _Stage(name: 'Clean Code', emoji: '✨', validators: [
    ('linting', linting.validate),
    ('console_logs', console_logs.validate),
  ]),
];

String get _gatekeeperRoot {
  final scriptPath = Platform.script.toFilePath();
  final normalized = scriptPath.replaceAll('\\', '/');
  final binIndex = normalized.lastIndexOf('/bin/');
  if (binIndex != -1) return normalized.substring(0, binIndex);
  if (Directory('.gatekeeper').existsSync()) return '.gatekeeper';
  return 'gatekeeper';
}

void _checkIntegrity() {
  final validatorFiles = Directory('$_gatekeeperRoot/validators')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) {
        final name = f.uri.pathSegments.last.replaceAll('.dart', '');
        return name;
      })
      .toSet();

  final missing = mandatoryValidators.where((v) => !validatorFiles.contains(v)).toList();

  if (missing.isNotEmpty) {
    InfraUI.error('\n${'=' * _reportWidth}');
    InfraUI.error('CRITICAL SECURITY BREACH: INTEGRITY GUARD FAILED');
    InfraUI.error('=' * _reportWidth);
    InfraUI.warn('The following mandatory validators have been disconnected or deleted:');
    for (final hook in missing) {
      InfraUI.log('  - $hook');
    }
    InfraUI.error('\nACTION: Restore the missing validators.');
    InfraUI.error('Execution blocked to prevent unvalidated commits.\n');
    exit(1);
  }
}

bool _runStage(_Stage stage) {
  final label = '${stage.emoji}  ${stage.name}';
  final visualWidth = stage.name.length + 4;
  final dotsCount = (_labelMaxWidth - visualWidth).clamp(_minDots, _labelMaxWidth);
  final dots = '.' * dotsCount;

  var allOmitted = true;

  for (final (name, fn) in stage.validators) {
    final exitCode = fn();

    if (exitCode == 2) continue; // omitted

    allOmitted = false;

    if (exitCode != 0) {
      InfraUI.error('$label$dots\x1b[31mFAILED\x1b[0m');
      InfraUI.gray('─' * _reportWidth);
      final prettyName = name.split('_').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
      InfraUI.error('   ↳ Failed at: $prettyName');
      return false;
    }
  }

  if (allOmitted) {
    InfraUI.gray('$label$dots[Omitted]');
  } else {
    InfraUI.success('$label$dots\x1b[32mPassed\x1b[0m');
  }

  return true;
}

void main(List<String> args) {
  final command = args.isEmpty ? 'check' : args[0];

  switch (command) {
    case 'check':
      _checkIntegrity();

      InfraUI.info('\nProject: gemini-cli-mobile | Technical debt detector\n');

      var allPassed = true;
      for (final stage in _stages) {
        if (!_runStage(stage)) {
          allPassed = false;
          break;
        }
      }

      if (!allPassed) exit(1);

      InfraUI.success('\nAll architectural laws satisfied. Alpha status confirmed.');
    default:
      InfraUI.warn('Unknown sentinel command: $command');
      exit(1);
  }
}
