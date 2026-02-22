import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../../services/attachment_service.dart';
import '../../models/attachment.dart';

class AttachmentPicker extends StatefulWidget {
  final AttachmentService service;
  final String? parentId;
  final String? parentType;
  const AttachmentPicker({
    super.key,
    required this.service,
    this.parentId,
    this.parentType,
  });

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {
  final ImagePicker _picker = ImagePicker();
  List<Attachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _attachments = widget.service.list();
    () async {
      try {
        await widget.service.load(parentId: widget.parentId, parentType: widget.parentType);
        if (!mounted) return;
        setState(() => _attachments = widget.service.list());
      } catch (_) {
        // ignore load errors
      }
    }();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      await widget.service.saveImageFile(
        File(file.path),
        parentId: widget.parentId,
        parentType: widget.parentType,
      );
      if (!mounted) return;
      setState(() => _attachments = widget.service.list());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao anexar imagem: $e')),
      );
    }
  }

  Future<void> _openSignature() async {
    try {
      final result = await showDialog<Uint8List?>(
        context: context,
        builder: (context) => SignatureDialog(),
      );
      if (result == null) return;
      await widget.service.saveSignature(
        result,
        parentId: widget.parentId,
        parentType: widget.parentType,
      );
      if (!mounted) return;
      setState(() => _attachments = widget.service.list());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar assinatura: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Câmera'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeria'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _openSignature,
              icon: const Icon(Icons.edit),
              label: const Text('Assinatura'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _attachments.map((a) => _thumbFor(a)).toList(),
        )
      ],
    );
  }

  Widget _thumbFor(Attachment a) {
    return GestureDetector(
      onTap: () => _showPreview(a),
      child: SizedBox(
        width: 90,
        height: 90,
        child: Card(
          child: a.type == AttachmentType.signature
              ? Center(child: Text('Assinatura'))
              : Image.file(File(a.path), fit: BoxFit.cover),
        ),
      ),
    );
  }

  void _showPreview(Attachment a) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (a.type == AttachmentType.signature) ...[
              Image.file(File(a.path)),
            ] else ...[
              Image.file(File(a.path)),
            ],
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                try {
                  await widget.service.delete(
                    a,
                    parentId: widget.parentId,
                    parentType: widget.parentType,
                  );
                  if (!mounted) return;
                  setState(() => _attachments = widget.service.list());
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir anexo: $e')),
                  );
                }
              },
              child: const Text('Excluir'),
            )
          ],
        ),
      ),
    );
  }
}

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assinatura'),
      content: SizedBox(
        width: 400,
        height: 200,
        child: Signature(
          controller: _controller,
          backgroundColor: Colors.white,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () { _controller.clear(); },
          child: const Text('Limpar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_controller.isNotEmpty) {
              final navigator = Navigator.of(context);
              final data = await _controller.toPngBytes();
              navigator.pop(data);
            } else {
              Navigator.of(context).pop(null);
            }
          },
          child: const Text('Salvar'),
        )
      ],
    );
  }
}
