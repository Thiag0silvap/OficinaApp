import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> showPdfPreviewDialog(
  BuildContext context, {
  required String title,
  required String fileName,
  required Future<Uint8List> Function(PdfPageFormat format) buildPdf,
}) async {
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final maxWidth = MediaQuery.of(ctx).size.width;
      final maxHeight = MediaQuery.of(ctx).size.height;
      final dialogWidth = maxWidth.clamp(520.0, 1100.0);
      final dialogHeight = maxHeight.clamp(520.0, 900.0);

      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(ctx).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: PdfPreview(
                  pdfFileName: fileName,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  allowPrinting: true,
                  allowSharing: true,
                  build: buildPdf,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
