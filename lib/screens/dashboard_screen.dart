import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/status_pill.dart';
import '../core/utils/formatters.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import 'clientes_screen.dart';
import 'financeiro_screen.dart';
import 'orcamentos_screen.dart';

/// Mapeia o status de domínio para o status visual do design system. Espelha
/// a mesma função privada de orcamentos_screen.dart (não pode ser
/// reaproveitada por ser private daquele arquivo).
AppStatus _toAppStatus(OrcamentoStatus s) {
  switch (s) {
    case OrcamentoStatus.pendente:
      return AppStatus.pendente;
    case OrcamentoStatus.aprovado:
      return AppStatus.aprovado;
    case OrcamentoStatus.emAndamento:
      return AppStatus.emAndamento;
    case OrcamentoStatus.concluido:
      return AppStatus.concluido;
    case OrcamentoStatus.cancelado:
      return AppStatus.cancelado;
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final faturamento = provider.entradasMesAtual;
        final faturamentoAnterior = provider.entradasMesAnterior;
        final faturamentoVar = provider.percentageChange(
          faturamento,
          faturamentoAnterior,
        );

        final ordensAtivas = provider.orcamentosEmAndamento.length;
        final concluidosHoje = provider.orcamentosConcluidos.where((o) {
          if (o.dataConclusao == null) return false;
          final now = DateTime.now();
          return o.dataConclusao!.day == now.day &&
              o.dataConclusao!.month == now.month &&
              o.dataConclusao!.year == now.year;
        }).length;

        final pendentes = provider.orcamentosPendentes.length;

        return ResponsiveContainer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final spacing = ResponsiveUtils.getCardSpacing(context);
              final isMobile = ResponsiveUtils.isMobile(context);

              // Limita a largura máxima dos cards para evitar ficar “gigante”
              // quando o app estiver em uma largura intermediária.
              final maxCardWidth =
                  isMobile ? (constraints.maxWidth / 2) - 8 : 290.0;

              // Altura estável dos stat cards (evita RenderFlex overflow).
              const statCardHeight = 112.0;

              final statCards = <Widget>[
                _buildStatCard(
                  context,
                  title: 'Faturamento do mês',
                  value: Formatters.currency(faturamento),
                  icon: Icons.monetization_on,
                  trend: faturamentoVar['label'],
                  trendUp: faturamentoVar['up'] ?? true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.surface,
                          automaticallyImplyLeading: true,
                          title: const Text('Financeiro'),
                        ),
                        body: const FinanceiroScreen(),
                      ),
                    ),
                  ),
                ),
                _buildStatCard(
                  context,
                  title: 'Ordens ativas',
                  value: ordensAtivas.toString(),
                  icon: Icons.build_circle,
                ),
                _buildStatCard(
                  context,
                  title: 'Concluídos hoje',
                  value: concluidosHoje.toString(),
                  icon: Icons.check_circle,
                  valueColor: AppColors.success,
                ),
                _buildStatCard(
                  context,
                  title: 'Pendentes',
                  value: pendentes.toString(),
                  icon: Icons.pending_actions,
                  valueColor: AppColors.pending,
                ),
              ];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      context,
                      ordensAtivas: ordensAtivas,
                      pendentes: pendentes,
                      concluidosHoje: concluidosHoje,
                    ),

                    SizedBox(height: spacing),

                    /// ======= CARDS (GRID ALINHADO) =======
                    GridView.builder(
                      itemCount: statCards.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxCardWidth,
                        mainAxisExtent: statCardHeight,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemBuilder: (context, index) => statCards[index],
                    ),

                    SizedBox(height: spacing * 1.5),

                    /// ======= INSIGHTS (CHART + RESUMO) =======
                    _buildInsights(context, provider, spacing: spacing),

                    SizedBox(height: spacing * 2),

                    /// ======= ORDENS + AGENDA =======
                    isMobile
                        ? Column(
                            children: [
                              _buildRecentOrders(context, provider),
                              SizedBox(height: spacing),
                              _buildSchedule(context, provider),
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildRecentOrders(context, provider),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: _buildSchedule(context, provider),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// ================= INSIGHTS =================
  Widget _buildInsights(
    BuildContext context,
    AppProvider provider, {
    required double spacing,
  }) {
    final isMobile = ResponsiveUtils.isMobile(context);

    final months = _lastMonths(6);
    final entradas = months
        .map((m) => _sumTransacoesMes(provider, m, TipoTransacao.entrada))
        .toList();
    final saidas = months
        .map((m) => _sumTransacoesMes(provider, m, TipoTransacao.saida))
        .toList();

    final now = DateTime.now();
    final entradasHoje = provider.transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.entrada &&
              t.data.day == now.day &&
              t.data.month == now.month &&
              t.data.year == now.year,
        )
        .fold<double>(0, (s, t) => s + t.valor);
    final saidasHoje = provider.transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.saida &&
              t.data.day == now.day &&
              t.data.month == now.month &&
              t.data.year == now.year,
        )
        .fold<double>(0, (s, t) => s + t.valor);

    final saldoHoje = entradasHoje - saidasHoje;

    final chart = _sectionContainer(
      title: 'Entradas × Saídas (6 meses)',
      child: SizedBox(
        height: isMobile ? 180 : 260,
        child: _buildLineChart(
          context,
          months: months,
          entradas: entradas,
          saidas: saidas,
        ),
      ),
    );

    final resumo = _sectionContainer(
      title: 'Resumo Diário',
      child: Column(
        children: [
          _buildMiniMetricRow(
            context,
            label: 'Entradas hoje',
            value: Formatters.currency(entradasHoje),
            icon: Icons.trending_up,
            iconColor: AppColors.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMiniMetricRow(
            context,
            label: 'Saídas hoje',
            value: Formatters.currency(saidasHoje),
            icon: Icons.trending_down,
            iconColor: AppColors.danger,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildMiniMetricRow(
            context,
            label: 'Saldo do dia',
            value: Formatters.currency(saldoHoje),
            icon: Icons.account_balance_wallet,
            iconColor: saldoHoje >= 0 ? AppColors.success : AppColors.danger,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Botão principal amarelo + atalhos embaixo.
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.surface,
                          automaticallyImplyLeading: true,
                          title: const Text('Orçamentos'),
                        ),
                        body: const OrcamentosScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Orçamento'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.surface,
                          automaticallyImplyLeading: true,
                          title: const Text('Clientes'),
                        ),
                        body: const ClientesScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.people_alt),
                  label: const Text('Clientes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.surface,
                          automaticallyImplyLeading: true,
                          title: const Text('Financeiro'),
                        ),
                        body: const FinanceiroScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Financeiro'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          chart,
          SizedBox(height: spacing),
          resumo,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: chart),
        SizedBox(width: spacing),
        Expanded(child: resumo),
      ],
    );
  }

  Widget _buildMiniMetricRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(value, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(
    BuildContext context, {
    required List<DateTime> months,
    required List<double> entradas,
    required List<double> saidas,
  }) {
    final maxY = <double>[
      ...entradas,
      ...saidas,
    ].fold<double>(0, (m, v) => v > m ? v : m);
    final double safeMaxY = maxY <= 0 ? 100.0 : (maxY * 1.2);

    List<FlSpot> spotsFrom(List<double> values) {
      return List.generate(
        values.length,
        (i) => FlSpot(i.toDouble(), values[i]),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months.length - 1).toDouble(),
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
              // Rótulo curto e de linha única: sem prefixo "R$" (o título do
              // card já dá o contexto) e compactado. Corrige a quebra de linha.
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
                if (i < 0 || i >= months.length) {
                  return const SizedBox.shrink();
                }
                final d = months[i];
                final label =
                    '${_monthShort(d.month)}/${(d.year % 100).toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
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

  /// Formata o rótulo do eixo Y de forma curta e em linha única.
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

  List<DateTime> _lastMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - (count - 1 - i), 1);
      return d;
    });
  }

  double _sumTransacoesMes(
    AppProvider provider,
    DateTime month,
    TipoTransacao tipo,
  ) {
    return provider.transacoes
        .where(
          (t) =>
              t.tipo == tipo &&
              t.data.month == month.month &&
              t.data.year == month.year,
        )
        .fold<double>(0, (s, t) => s + t.valor);
  }

  String _monthShort(int month) {
    const m = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    if (month < 1 || month > 12) return '';
    return m[month - 1];
  }

  /// ================= HEADER =================
  Widget _buildHeader(
    BuildContext context, {
    required int ordensAtivas,
    required int pendentes,
    required int concluidosHoje,
  }) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.name.trim() ?? '';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: AppText.display.copyWith(fontSize: 26)),
                const SizedBox(height: 2),
                Text(
                  'Visão geral da sua oficina hoje',
                  style: AppText.bodySecondary,
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 18,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: AppText.display),
              const SizedBox(height: 6),
              Text(
                'Visão geral da sua oficina hoje',
                style: AppText.bodySecondary,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 44,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.04),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 14,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name.isNotEmpty ? name.split(' ').first : 'Admin',
                    style: AppText.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ================= CARD ESTATÍSTICA =================
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    String? trend,
    bool trendUp = true,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    bool hover = false;

    return StatefulBuilder(
      builder: (ctx, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => hover = true),
          onExit: (_) => setState(() => hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.identity()
              ..scaleByDouble(
                hover ? 1.02 : 1.0,
                hover ? 1.02 : 1.0,
                1.0,
                1.0,
              ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Ink(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.line, width: 1),
                    boxShadow: hover
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Ícone monocromático em caixa neutra (sem arco-íris).
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.elevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                          if (trend != null) ...[
                            const Spacer(),
                            _TrendPill(label: trend, up: trendUp),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySecondary.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.money.copyWith(
                          fontSize: 20,
                          color: valueColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ================= ORDENS RECENTES =================
  Widget _buildRecentOrders(BuildContext context, AppProvider provider) {
    final orders = provider.orcamentos.take(5).toList();

    return _sectionContainer(
      title: 'Ordens Recentes',
      child: orders.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Nenhuma ordem recente',
                style: AppText.bodySecondary,
              ),
            )
          : Column(
              children: orders
                  .map(
                    (o) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: ListTile(
                        title: Text(
                          o.clienteNome,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          o.veiculoDescricao,
                          style: AppText.bodySecondary,
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusPill(_toAppStatus(o.status)),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.currency(o.valorTotal),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// ================= AGENDA =================
  Widget _buildSchedule(BuildContext context, AppProvider provider) {
    final pendentes = provider.orcamentosPendentes.take(3).toList();

    return _sectionContainer(
      title: 'Próximos Agendamentos',
      child: pendentes.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Sem agendamentos', style: AppText.bodySecondary),
            )
          : Column(
              children: pendentes
                  .map(
                    (o) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.elevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_today,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        title: Text(
                          o.clienteNome,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          o.veiculoDescricao,
                          style: AppText.bodySecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// ================= CONTAINER PADRÃO =================
  Widget _sectionContainer({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppText.title)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Pílula de tendência (variação % vs. mês anterior). Único ponto de cor
/// semântica dos stat cards — é um indicador de valor, uso permitido.
class _TrendPill extends StatelessWidget {
  final String label;
  final bool up;
  const _TrendPill({required this.label, required this.up});

  @override
  Widget build(BuildContext context) {
    final color = up ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}