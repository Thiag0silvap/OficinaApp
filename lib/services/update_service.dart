import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/constants/app_constants.dart';
import '../core/constants/app_version.dart';
import '../core/utils/version_utils.dart';

class UpdateInfo {
  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    this.notes,
  });

  final String latestVersion;
  final String downloadUrl;
  final String? notes;
}

class UpdateService {
  static Future<UpdateInfo?> checkForUpdate() async {
    final url = AppConstants.updateManifestUrl.trim();
    if (url.isEmpty) return null;

    try {
      final jsonMap = await _fetchJson(url);

      final latestVersion = (jsonMap['latestVersion'] as String?)?.trim();
      final downloadUrl = (jsonMap['downloadUrl'] as String?)?.trim();
      final notes = (jsonMap['notes'] as String?)?.trim();

      if (latestVersion == null || latestVersion.isEmpty) return null;
      if (downloadUrl == null || downloadUrl.isEmpty) return null;

      final current = AppVersion.current;
      final isNewer = VersionUtils.compare(latestVersion, current) > 0;
      if (!isNewer) return null;

      return UpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        notes: notes,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> openDownloadUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (Platform.isLinux) {
      await Process.run('xdg-open', [uri.toString()]);
      return;
    }

    if (Platform.isMacOS) {
      await Process.run('open', [uri.toString()]);
      return;
    }

    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', uri.toString()]);
      return;
    }
  }

  static Future<Map<String, dynamic>> _fetchJson(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);

    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Manifest inválido');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}
