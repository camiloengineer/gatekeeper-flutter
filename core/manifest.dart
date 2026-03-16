/// ARCHITECTURAL INTEGRITY MANIFEST
/// This is the static contract of all mandatory validators.
/// Any mismatch between this list and the physical files results in an INTEGRITY_BREACH.
const List<String> mandatoryValidators = [
  'anti_corruption',
  'authorship',
  'boundaries',
  'build',
  'console_logs',
  'features_architecture',
  'forbidden_files',
  'ghost',
  'hardcoding',
  'linting',
  'mutation',
  'no_spanish',
  'testing',
];
