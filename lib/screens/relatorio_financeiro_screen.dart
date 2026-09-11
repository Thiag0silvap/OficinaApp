import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/components/app_buttons.dart';
import '../core/components/app_card.dart';
import '../core/components/responsive_components.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_feedback.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/pdf_preview_dialog.dart';
import '../models/relatorio_financeiro.dart';
import '../providers/app_provider.dart';
import '../services/pdf_service.dart';

/// Relatório Financeiro: gráfico + tabelas (mensal/categoria) de um período
/// selecionável, com exportação para PDF. Acessado a partir da Financeiro.
class RelatorioFinanceiroScreen extends StatefulWidget {
  const RelatorioFinanceiroScreen({super.key});

  @override
  State<RelatorioFinanceiroScreen> createState() =>
      _RelatorioFinanceiroScreenState();
}

class _RelatorioFinanceiroScreenState
    extends State<RelatorioFinanceiroScreen> {
  PeriodoRelatorio _periodo = PeriodoRelatorio.seisMeses;
  bool _exportando = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final (inicio, fim) = _periodo.intervalo();
        final resumoMensal = app.resumoPorPeriodo(inicio, fim);
        final resumoCategoria = app.resumoPorCategoria(inicio, fim);

        return Scaffold(
          appBar: AppBar(title: const Text('Relatório Financeiro')),
          body: ResponsiveContainer(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlsRow(context, resumoMensal, resumoCategoria),
                  const SizedBox(height: AppSpacing.lg),
                  _buildChartCard(context, resumoMensal),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMensalCard(resumoMensal),
                  const SizedBox(height: AppSpacing.lg),
                  _buildCategoriaCard(resumoCategoria),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlsRow(
    BuildContext context,
    List<ResumoMensal> resumoMensal,
    List<ResumoCategoria> resumoCategoria,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);

    final dropdown = _periodoDropdown();
    final exportButton = PrimaryButton(
      label: 'Exportar PDF',
      icon: Icons.picture_as_pdf_outlined,
      isLoading: _exportando,
      expanded: isMobile,
      onPressed: () => _exportarPdf(resumoMensal, resumoCategoria),
    );

    // Empilhado no mobile: as duas peças juntas numa linha só (dropdown de
    // período com labels longas, ex. "Últimos 12 meses" + botão com ícone)
    // arriscam overflow em telas 360dp — mesmo cuidado já aplicado no filtro
    // de data da Financeiro.
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dropdown,
          const SizedBox(height: AppSpacing.md),
          exportButton,
        ],
      );
    }

    return Row(
      children: [
        dropdown,
        const Spacer(),
        exportButton,
      ],
    );
  }

  Widget _periodoDropdown() {
    const h = 48.0;
    final r = BorderRadius.circular(14);
    return Container(
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: r,
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.7),
        ),
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PeriodoRelatorio>(
          value: _periodo,
          dropdownColor: AppColors.elevated,
          borderRadius: BorderRadius.circular(14),
          onChanged: (v) {
            if (v != null) setState(() => _periodo = v);
          },
          items: PeriodoRelatorio.values
              .map(
                (p) => DropdownMenuItem(value: p, child: Text(p.label)),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _exportarPdf(
    List<ResumoMensal> resumoMensal,
    List<ResumoCategoria> resumoCategoria,
  ) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final periodo = _periodo;
      final filename = PDFService.buildRelatorioFinanceiroFilename(periodo);
      final empresa = await context.read<AppProvider>().getEmpresa();
      if (!mounted) return;
      await showPdfPreviewDialog(
        context,
        title: 'Relatório Financeiro',
        fileName: filename,
        buildPdf: (_) => PDFService.generateRelatorioFinanceiroPdf(
          periodo: periodo,
          resumoPorMes: resumoMensal,
          resumoPorCategoria: resumoCategoria,
          empresa: empresa,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erro ao gerar PDF: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Widget _buildChartCard(BuildContext context, List<ResumoMensal> resumo) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Entradas × Saídas — ${_periodo.label}', style: AppText.title),
          const SizedBox(height: 14),
          SizedBox(
            height: isMobile ? 180 : 260,
            child: _buildLineChart(resumo),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<ResumoMensal> resumo) {
    final entradas = resumo.map((r) => r.entradas).toList();
    final saidas = resumo.map((r) => r.saidas).toList();
    final maxY = <double>[
      ...entradas,
      ...saidas,
    ].fold<double>(0, (m, v) => v > m ? v : m);
    final safeMaxY = maxY <= 0 ? 100.0 : (maxY * 1.2);

    // Com 12 meses no período, um rótulo por mês no eixo X lota a largura
    // disponível no mobile — mostra só ~6 rótulos, espaçados uniformemente.
    final labelStep = (resumo.length / 6).ceil().clamp(1, resumo.length);

    List<FlSpot> spotsFrom(List<double> values) {
      return List.generate(
        values.length,
        (i) => FlSpot(i.toDouble(), values[i]),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (resumo.length - 1).toDouble(),
        minY: 0,
        maxY: safeMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: safeMaxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.line, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: safeMaxY / 4,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _compactAxis(value),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= resumo.length || i % labelStep != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _monthShortLabel(resumo[i].mes),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spotsFrom(entradas),
            isCurved: true,
            barWidth: 3,
            color: AppColors.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          LineChartBarData(
            spots: spotsFrom(saidas),
            isCurved: true,
            barWidth: 2,
            color: AppColors.textSecondary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.textSecondary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  String _compactAxis(double v) {
    if (v <= 0) return '0';
    if (v >= 1000000) {
      final n = v / 1000000;
      return '${n.toStringAsFixed(n % 1 == 0 ? 0 : 1).replaceAll('.', ',')}M';
    }
    if (v >= 1000) {
      final n = v / 1000;
      return '${n.toStringAsFixed(n % 1 == 0 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return v.toStringAsFixed(0);
  }

  String _monthShortLabel(DateTime d) {
    final mes = DateFormat('MMM', 'pt_BR').format(d);
    final ano = (d.year % 100).toString().padLeft(2, '0');
    return '$mes/$ano';
  }

  String _monthFullLabel(DateTime d) {
    final label = DateFormat('MMMM/yyyy', 'pt_BR').format(d);
    if (label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1);
  }

  Widget _buildMensalCard(List<ResumoMensal> resumo) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumo Mensal', style: AppText.title),
          const SizedBox(height: 6),
          for (int i = 0; i < resumo.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _ResumoRow(
              label: _monthFullLabel(resumo[i].mes),
              entradas: resumo[i].entradas,
              saidas: resumo[i].saidas,
              destaque: resumo[i].saldo,
              destaqueColor: resumo[i].saldo >= 0
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(List<ResumoCategoria> resumo) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Por Categoria', style: AppText.title),
          const SizedBox(height: 6),
          if (resumo.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nenhuma transação no período.',
                style: AppText.bodySecondary,
              ),
            ),
          for (int i = 0; i < resumo.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _ResumoRow(
              label: resumo[i].categoria,
              entradas: resumo[i].entradas,
              saidas: resumo[i].saidas,
              destaque: resumo[i].total,
            ),
          ],
        ],
      ),
    );
  }
}

/// Linha compacta de resumo (mês ou categoria): rótulo + valor em destaque
/// numa linha, entradas/saídas numa segunda linha. Sem colunas fixas —
/// `Expanded` + `ellipsis` em todo texto evita overflow em telas estreitas
/// mesmo com valores grandes.
class _ResumoRow extends StatelessWidget {
  final String label;
  final double entradas;
  final double saidas;
  final double destaque;
  final Color? destaqueColor;

  const _ResumoRow({
    required this.label,
    required this.entradas,
    required this.saidas,
    required this.destaque,
    this.destaqueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.currency(destaque),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: destaqueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Entradas: ${Formatters.currency(entradas)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySecondary.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saídas: ${Formatters.currency(saidas)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppText.bodySecondary.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
