import 'dart:io';
import 'dart:convert';

String get _gatekeeperRoot {
  final scriptPath = Platform.script.toFilePath();
  final normalized = scriptPath.replaceAll('\\', '/');
  final binIndex = normalized.lastIndexOf('/bin/');
  if (binIndex != -1) {
    return normalized.substring(0, binIndex);
  }
  if (Directory('.gatekeeper').existsSync()) return '.gatekeeper';
  return 'gatekeeper';
}

String _normalizePath(String path) {
  return path.replaceAll('\\', '/').replaceAll('//', '/');
}

String _basename(String path) {
  final normalized = _normalizePath(path);
  final lastSlash = normalized.lastIndexOf('/');
  return lastSlash == -1 ? normalized : normalized.substring(lastSlash + 1);
}

List<String> getDartFiles({String root = 'lib'}) {
  final roots = [
    root,
    'bin',
    'core',
    'validators',
  ];

  final allFiles = <String>[];

  for (final r in roots) {
    final dir = Directory(r);
    if (!dir.existsSync()) continue;

    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.freezed.dart'))
        .map((f) => _normalizePath(f.path));
    allFiles.addAll(files);
  }

  return allFiles.toSet().toList();
}

List<String> getAllFiles() {
  final ignorePatterns = [
    '.git',
    '.dart_tool',
    'build',
    '.flutter-plugins',
    'node_modules',
    '.idea',
    '.vscode',
    'android/.gradle',
    'ios/Pods',
    'windows',
    'macos',
    'linux',
    'web',
  ];

  final dir = Directory('.');
  if (!dir.existsSync()) return [];

  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) {
        final normalized = _normalizePath(f.path);
        return !ignorePatterns.any((p) =>
            normalized.contains('/$p/') ||
            normalized.startsWith('$p/') ||
            normalized.startsWith('./$p/'));
      })
      .map((f) => _normalizePath(f.path))
      .toList();
}

String basename(String path) => _basename(path);

Map<String, dynamic> loadRegistry(String registryName) {
  final registryPath = '$_gatekeeperRoot/poison/$registryName.json';
  final file = File(registryPath);
  if (!file.existsSync()) {
    stderr.writeln(
        '\x1b[31mRegistry "$registryName" not found at $registryPath\x1b[0m');
    return {};
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

bool isPoisonZone(String filePath) {
  final normalized = _normalizePath(filePath);
  return normalized.contains('/poison/') || normalized.endsWith('.poison.json');
}

({bool hasMutation, List<String> files, bool isAuthorized})
    checkArchitectureMutation() {
  const infrastructurePatterns = [
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'lefthook.yml',
    'build.yaml',
    '.metadata',
    'gatekeeper/',
    '.github/',
    'android/build.gradle',
    'android/app/build.gradle',
    'ios/Podfile',
  ];

  List<String> filesToCheck;
  try {
    final result = Process.runSync('git', ['diff', '--cached', '--name-only']);
    final output = (result.stdout as String).trim();
    filesToCheck = output.isEmpty ? [] : output.split('\n');
  } catch (_) {
    return (hasMutation: false, files: <String>[], isAuthorized: false);
  }

  final mutationFiles = filesToCheck.where((file) {
    return infrastructurePatterns.any(
      (pattern) => file.startsWith(pattern) || file.contains(pattern),
    );
  }).toList();

  return (
    hasMutation: mutationFiles.isNotEmpty,
    files: mutationFiles,
    isAuthorized: Platform.environment['MUTATION'] == 'true',
  );
}
