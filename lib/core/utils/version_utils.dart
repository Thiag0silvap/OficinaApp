class VersionUtils {
  static ({int major, int minor, int patch, int build}) parse(String raw) {
    final trimmed = raw.trim();
    final parts = trimmed.split('+');

    final semver = parts.isNotEmpty ? parts[0] : '0.0.0';
    final buildStr = parts.length > 1 ? parts[1] : '0';

    final semverParts = semver.split('.');

    int readPart(int index) {
      if (index >= semverParts.length) return 0;
      return int.tryParse(semverParts[index]) ?? 0;
    }

    return (
      major: readPart(0),
      minor: readPart(1),
      patch: readPart(2),
      build: int.tryParse(buildStr) ?? 0,
    );
  }

  /// Retorna < 0 se a < b; 0 se igual; > 0 se a > b.
  static int compare(String a, String b) {
    final va = parse(a);
    final vb = parse(b);

    if (va.major != vb.major) return va.major.compareTo(vb.major);
    if (va.minor != vb.minor) return va.minor.compareTo(vb.minor);
    if (va.patch != vb.patch) return va.patch.compareTo(vb.patch);
    return va.build.compareTo(vb.build);
  }
}
