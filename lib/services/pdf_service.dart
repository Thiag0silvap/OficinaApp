import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/orcamento.dart';
import '../core/constants/app_constants.dart';

class PDFService {
  static Future<Uint8List> generateOrcamentoPdf(Orcamento o) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

    pw.MemoryImage? logoImage;
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final isConcluido = o.status == OrcamentoStatus.concluido;
    final titleText = isConcluido ? 'Nota de Serviço' : 'Orçamento';
    final displayDate = (isConcluido && o.dataConclusao != null)
        ? o.dataConclusao!
        : o.dataCriacao;

    final pagamentoText = o.pago ? 'Pago' : 'Pendente';
    final pagamentoColor = o.pago ? PdfColors.green : PdfColors.orange;

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
                  pw.Container(width: 120, child: pw.Image(logoImage)),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        titleText,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Data: ${dateFormat.format(displayDate)}'),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Pagamento: '),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(10),
                              border: pw.Border.all(color: pagamentoColor),
                            ),
                            child: pw.Text(
                              pagamentoText,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: pagamentoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
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
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            ),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(6),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    child: pw.Text(
                      'Serviço',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    child: pw.Text(
                      'Descrição',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Valor',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              ...o.itens.map((i) {
                String piece = '';
                String details = i.descricao;

                for (final p in AppConstants.pecas) {
                  if (details.toLowerCase().startsWith(p.toLowerCase())) {
                    piece = p;
                    if (details.length > p.length &&
                        details.substring(p.length).trim().startsWith('-')) {
                      details = details
                          .substring(p.length)
                          .replaceFirst('-', '')
                          .trim();
                    } else {
                      details = details.substring(p.length).trim();
                    }
                    break;
                  }
                }

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(i.servico),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: piece.isNotEmpty
                          ? pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  piece,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (details.isNotEmpty) pw.SizedBox(height: 3),
                                if (details.isNotEmpty) pw.Text(details),
                              ],
                            )
                          : pw.Text(details),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(moneyFormat.format(i.valor)),
                      ),
                    ),
                  ],
                );
              }),
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
              child: pw.Text(
                'Total: ${moneyFormat.format(o.valorTotal)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),

          pw.SizedBox(height: 18),

          if ((o.observacoes ?? '').isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Observações:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(o.observacoes ?? ''),
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
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
