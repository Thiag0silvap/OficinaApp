import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attachment.dart';

class AttachmentService {
  final List<Attachment> _attachments = [];

  static const _prefsPrefix = 'attachments_v1';
  static const int _maxImageBytes = 8 * 1024 * 1024; // 8MB
  static const int _maxSignatureBytes = 2 * 1024 * 1024; // 2MB

  static String _key({String? parentId, String? parentType}) {
    if (parentId == null || parentType == null) return _prefsPrefix;
    return '$_prefsPrefix:$parentType:$parentId';
  }

  Future<void> load({String? parentId, String? parentType}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(parentId: parentId, parentType: parentType));
    if (raw == null) {
      _attachments.clear();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _attachments
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((e) => Attachment.fromMap(Map<String, dynamic>.from(e))),
          );
      }
    } catch (_) {
      _attachments.clear();
    }
  }

  Future<void> _persist({String? parentId, String? parentType}) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _attachments.map((a) => a.toMap()).toList();
    await prefs.setString(
      _key(parentId: parentId, parentType: parentType),
      jsonEncode(payload),
    );
  }

  Future<Directory> _attachmentsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final attachDir = Directory('${dir.path}/attachments');
    if (!await attachDir.exists()) await attachDir.create(recursive: true);
    return attachDir;
  }

  Future<Attachment> saveImageFile(
    File file, {
    String? note,
    String? parentId,
    String? parentType,
  }) async {
    final size = await file.length();
    if (size > _maxImageBytes) {
      throw Exception('Imagem muito grande. Limite: 8MB.');
    }
    final dir = await _attachmentsDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = file.path.split('.').last;
    final filename = 'img_$id.$ext';
    final targetPath = '${dir.path}/$filename';

    // try compressing
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
      );
      File savedFile;
      if (result != null) {
        // result can be a File or an XFile depending on platform/package versions;
        // create a File from its path to be safe.
        savedFile = File((result as dynamic).path);
      } else {
        savedFile = await file.copy(targetPath);
      }
      final attachment = Attachment(
        id: id,
        filename: filename,
        path: savedFile.path,
        type: AttachmentType.image,
        note: note,
        parentId: parentId,
        parentType: parentType,
      );
      _attachments.add(attachment);
      await _persist(parentId: parentId, parentType: parentType);
      return attachment;
    } catch (e) {
      final saved = await file.copy(targetPath);
      final attachment = Attachment(
        id: id,
        filename: filename,
        path: saved.path,
        type: AttachmentType.image,
        note: note,
        parentId: parentId,
        parentType: parentType,
      );
      _attachments.add(attachment);
      await _persist(parentId: parentId, parentType: parentType);
      return attachment;
    }
  }

  Future<Attachment> saveSignature(
    Uint8List data, {
    String? note,
    String? parentId,
    String? parentType,
  }) async {
    if (data.length > _maxSignatureBytes) {
      throw Exception('Assinatura muito grande. Limite: 2MB.');
    }
    final dir = await _attachmentsDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final filename = 'sig_$id.png';
    final targetPath = '${dir.path}/$filename';
    final file = File(targetPath);
    await file.writeAsBytes(data);
    final attachment = Attachment(
      id: id,
      filename: filename,
      path: file.path,
      type: AttachmentType.signature,
      note: note,
      parentId: parentId,
      parentType: parentType,
    );
    _attachments.add(attachment);
    await _persist(parentId: parentId, parentType: parentType);
    return attachment;
  }

  List<Attachment> list() => List.unmodifiable(_attachments);

  Future<void> delete(
    Attachment a, {
    String? parentId,
    String? parentType,
  }) async {
    try {
      final f = File(a.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    _attachments.removeWhere((x) => x.id == a.id);
    await _persist(parentId: parentId, parentType: parentType);
  }
}
