import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/orcamento.dart';
import '../services/db_service.dart';

class PDFService {
  /// Gera um nome de arquivo amigável e seguro (Windows/macOS/Linux) para PDFs.
  /// Ex.: `orcamento_Thiago_89857.pdf`
  static String buildPdfFilename(Orcamento o) {
    final isConcluido = o.status == OrcamentoStatus.concluido;
    final prefix = isConcluido ? 'nota_servico' : 'orcamento';

    var client = _sanitizeFilenamePart(o.clienteNome);
    if (client.isEmpty) client = 'cliente';

    if (client.length > 24) {
      client = client.substring(0, 24).trim();
    }

    final idShort = _shortId(o.id.toString());
    return '${prefix}_${client}_$idShort.pdf';
  }

  static String _shortId(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    if (cleaned.isEmpty) return 'id';
    if (cleaned.length <= 6) return cleaned;
    return cleaned.substring(cleaned.length - 6);
  }

  static String _sanitizeFilenamePart(String input) {
    var s = input.trim();
    if (s.isEmpty) return '';

    s = s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    s = s.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
    s = s.replaceAll(RegExp(r'\s+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_');
    s = s.replaceAll(RegExp(r'^[._\-]+|[._\-]+$'), '');
    return s;
  }

  static Future<Uint8List> generateOrcamentoPdf(Orcamento o) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final moneyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    );

    final empresa = await DBService.instance.getEmpresa();

    pw.MemoryImage? logoImage;
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final isConcluido = o.status == OrcamentoStatus.concluido;
    final titleText = isConcluido ? 'Nota de Serviço' : 'Orçamento';
    final displayDate =
        (isConcluido && o.dataConclusao != null) ? o.dataConclusao! : o.dataCriacao;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 120,
                    child: pw.Image(logoImage),
                  ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (empresa != null) ...[
                        pw.Text(
                          empresa.nome,
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (empresa.telefone.trim().isNotEmpty)
                          pw.Text(
                            empresa.telefone,
                            textAlign: pw.TextAlign.right,
                          ),
                        if (empresa.endereco.trim().isNotEmpty)
                          pw.Text(
                            empresa.endereco,
                            textAlign: pw.TextAlign.right,
                          ),
                        if ((empresa.cnpj ?? '').trim().isNotEmpty)
                          pw.Text(
                            'CNPJ: ${empresa.cnpj!.trim()}',
                            textAlign: pw.TextAlign.right,
                          ),
                        pw.SizedBox(height: 10),
                      ],
                      pw.Text(
                        titleText,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Data: ${dateFormat.format(displayDate)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.Divider(),
          pw.SizedBox(height: 8),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Cliente: ${o.clienteNome}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Veículo: ${o.veiculoDescricao}'),
                if (o.dataPrevistaEntrega != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Previsão de entrega: ${dateFormat.format(o.dataPrevistaEntrega!)}',
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          pw.Text(
            'Itens',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            ),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(3.0),
              2: const pw.FlexColumnWidth(4.8),
              3: const pw.FlexColumnWidth(2.0),
            },
            children: [
              pw.TableRow(
                children: [
                  _tableHeaderCell('Serviço'),
                  _tableHeaderCell('Peça'),
                  _tableHeaderCell('Descrição'),
                  _tableHeaderCell('Valor', alignRight: true),
                ],
              ),
              ...o.itens.map(
                (i) => pw.TableRow(
                  children: [
                    _tableBodyCell(i.servico),
                    _tableBodyCell(
                      (i.peca ?? '').trim().isEmpty ? '-' : i.peca!.trim(),
                    ),
                    _tableBodyCell(i.descricao),
                    _tableBodyCell(
                      moneyFormat.format(i.valor),
                      alignRight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: () {
                final subtotal = o.itens.fold<double>(
                  0,
                  (sum, i) => sum + i.valor,
                );
                final desconto = (subtotal - o.valorTotal).clamp(0.0, subtotal);
                final hasDesconto = desconto > 0.005;

                if (!hasDesconto) {
                  return pw.Text(
                    'Total: ${moneyFormat.format(o.valorTotal)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  );
                }

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${moneyFormat.format(subtotal)}'),
                    pw.SizedBox(height: 3),
                    pw.Text('Desconto: - ${moneyFormat.format(desconto)}'),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Total: ${moneyFormat.format(o.valorTotal)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }(),
            ),
          ),

          pw.SizedBox(height: 18),

          if ((o.observacoes ?? '').trim().isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Observações:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(o.observacoes!.trim()),
              ],
            ),

          pw.SizedBox(height: 18),

          if (!isConcluido)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey200,
              child: pw.Text(
                'Este orçamento é válido por 30 dias.',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Text(
            'Documento gerado pelo sistema',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableHeaderCell(
    String text, {
    bool alignRight = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(color: PdfColors.grey300),
      child: alignRight
          ? pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                text,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            )
          : pw.Text(
              text,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
    );
  }

  static pw.Widget _tableBodyCell(
    String text, {
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: alignRight
          ? pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(text),
            )
          : pw.Text(text),
    );
  }
}