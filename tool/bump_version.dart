import 'dart:io';

/// Uso:
///   dart run tool/bump_version.dart patch
///   dart run tool/bump_version.dart minor
///   dart run tool/bump_version.dart major
///   dart run tool/bump_version.dart build
///
/// Isso atualiza:
/// - `pubspec.yaml` (linha `version:`)
/// - `lib/core/constants/app_version.dart`
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exitCode = 64;
    return;
  }

  final kind = args.first.trim().toLowerCase();
  final allowed = {'patch', 'minor', 'major', 'build'};
  if (!allowed.contains(kind)) {
    stderr.writeln('Tipo inválido: $kind');
    _printUsage();
    exitCode = 64;
    return;
  }

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('pubspec.yaml não encontrado. Rode na raiz do projeto.');
    exitCode = 66;
    return;
  }

  final pubspecLines = pubspecFile.readAsLinesSync();
  final versionIndex = pubspecLines.indexWhere((l) => l.trimLeft().startsWith('version:'));
  if (versionIndex == -1) {
    stderr.writeln('Linha `version:` não encontrada no pubspec.yaml');
    exitCode = 65;
    return;
  }

  final currentRaw = pubspecLines[versionIndex].split(':').last.trim();
  final current = _parse(currentRaw);

  final next = switch (kind) {
    'major' => (major: current.major + 1, minor: 0, patch: 0, build: current.build + 1),
    'minor' => (major: current.major, minor: current.minor + 1, patch: 0, build: current.build + 1),
    'patch' => (major: current.major, minor: current.minor, patch: current.patch + 1, build: current.build + 1),
    'build' => (major: current.major, minor: current.minor, patch: current.patch, build: current.build + 1),
    _ => current,
  };

  final nextRaw = '${next.major}.${next.minor}.${next.patch}+${next.build}';

  pubspecLines[versionIndex] = 'version: $nextRaw';
  pubspecFile.writeAsStringSync('${pubspecLines.join('\n')}\n');

  final appVersionFile = File('lib/core/constants/app_version.dart');
  if (!appVersionFile.existsSync()) {
    appVersionFile.createSync(recursive: true);
  }

  final appVersionContent = '''/// Atualize este arquivo via `dart run tool/bump_version.dart`.
class AppVersion {
  /// Exemplo: `1.2.3+45`.
  static const String current = '$nextRaw';
}
''';

  appVersionFile.writeAsStringSync(appVersionContent);

  stdout.writeln('Versão atualizada: $currentRaw -> $nextRaw');
}

void _printUsage() {
  stdout.writeln('Uso: dart run tool/bump_version.dart <patch|minor|major|build>');
}

({int major, int minor, int patch, int build}) _parse(String raw) {
  final trimmed = raw.trim();
  final parts = trimmed.split('+');
  final semver = parts.isNotEmpty ? parts[0] : '0.0.0';
  final buildStr = parts.length > 1 ? parts[1] : '0';

  final semParts = semver.split('.');

  int readPart(int index) {
    if (index >= semParts.length) return 0;
    return int.tryParse(semParts[index]) ?? 0;
  }

  return (
    major: readPart(0),
    minor: readPart(1),
    patch: readPart(2),
    build: int.tryParse(buildStr) ?? 0,
  );
}
