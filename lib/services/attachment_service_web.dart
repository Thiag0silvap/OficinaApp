import 'dart:typed_data';

import '../models/attachment.dart';

/// Web placeholder. Attachments rely on file-system APIs in the current app.
class AttachmentService {
  final List<Attachment> _attachments = [];

  List<Attachment> list() => List.unmodifiable(_attachments);

  Future<void> load({String? parentId, String? parentType}) async {
    // no-op
  }

  Never _unsupported() => throw UnsupportedError(
        'Anexos não são suportados no Web nesta versão do app.',
      );

  Future<Attachment> saveSignature(Uint8List data, {String? note, String? parentId, String? parentType}) async => _unsupported();

  Future<Attachment> saveImageBytes(Uint8List bytes, {String filename = 'image', String? note, String? parentId, String? parentType}) async => _unsupported();

  Future<void> delete(Attachment a, {String? parentId, String? parentType}) async => _unsupported();
}
