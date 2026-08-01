import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  Future<void> info(String message) => _write('INFO', message);
  Future<void> warning(String message) => _write('WARN', message);
  Future<void> error(String message) => _write('ERROR', message);

  Future<void> _write(String level, String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory(join(dir.path, 'OficinaAppLogs'));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName =
          'app_${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.log';
      final file = File(join(logDir.path, fileName));
      final line = '[${now.toIso8601String()}] [$level] $message\n';
      await file.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (_) {
      // best effort only
    }
  }
}
