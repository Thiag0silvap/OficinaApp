import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfFileService {
  /// Salva o PDF na pasta:
  /// Documentos/OficinaApp/PDFs
  static Future<String> savePdfToUserFolder({
    required Uint8List bytes,
    required String filename,
  }) async {
    final baseDir = await _resolveBaseDir();

    final pdfDir = Directory(
      p.join(baseDir.path, 'OficinaApp', 'PDFs'),
    );

    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final filePath = p.join(pdfDir.path, filename);

    final file = File(filePath);

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return filePath;
  }

  /// Detecta automaticamente a pasta Documentos do usuário
  static Future<Directory> _resolveBaseDir() async {
    try {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];

        if (userProfile != null &&
            userProfile.trim().isNotEmpty) {
          final docsDir = Directory(
            p.join(userProfile, 'Documents'),
          );

          if (await docsDir.exists()) {
            return docsDir;
          }
        }
      }

      if (Platform.isLinux || Platform.isMacOS) {
        return getApplicationDocumentsDirectory();
      }
    } catch (_) {}

    return getApplicationDocumentsDirectory();
  }

  /// Abre a pasta onde o PDF foi salvo
  static Future<void> openFileFolder(
    String filePath,
  ) async {
    final dirPath = File(filePath).parent.path;

    final uri = Uri.file(dirPath);

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success) {
      throw Exception(
        'Não foi possível abrir a pasta do PDF.',
      );
    }
  }
}