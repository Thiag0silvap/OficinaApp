import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfFileService {
  /// Salva o PDF na pasta interna do app (funciona em desktop e Android)
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
    await File(filePath).writeAsBytes(bytes, flush: true);

    return filePath;
  }

  /// No Android compartilha o PDF via share_plus (WhatsApp, Drive, etc)
  /// No desktop abre a pasta onde o PDF foi salvo
  static Future<void> openFileFolder(String filePath) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Orçamento OficinaApp',
      );
      return;
    }

    // Desktop: abre a pasta
    final dirPath = File(filePath).parent.path;
    final uri = Uri.file(dirPath);
    // url_launcher só no desktop — import condicional não necessário
    // pois o código mobile nunca chega aqui
    throw UnimplementedError(
      'Abertura de pasta não suportada nesta plataforma.',
    );
  }

  static Future<Directory> _resolveBaseDir() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        final docsDir = Directory(p.join(userProfile, 'Documents'));
        if (await docsDir.exists()) return docsDir;
      }
    }
    return getApplicationDocumentsDirectory();
  }
}