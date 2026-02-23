import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/utils/formatters.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transacao.dart';
import 'clientes_screen.dart';
import 'financeiro_screen.dart';
import 'orcamentos_screen.dart';

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

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),

                    SizedBox(height: spacing),

                    /// ======= CARDS RESPONSIVOS =======
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _buildStatCard(
                          context,
                          title: 'Faturamento Mensal',
                          value: Formatters.currency(faturamento),
                          icon: Icons.monetization_on,
                          iconColor: AppColors.primaryYellow,
                          trend: faturamentoVar['label'],
                          trendUp: faturamentoVar['up'] ?? true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FinanceiroScreen(),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          context,
                          title: 'Ordens Ativas',
                          value: ordensAtivas.toString(),
                          icon: Icons.build_circle,
                          iconColor: AppColors.info,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Concluídos Hoje',
                          value: concluidosHoje.toString(),
                          icon: Icons.check_circle,
                          iconColor: AppColors.success,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Pendentes',
                          value: pendentes.toString(),
                          icon: Icons.pending_actions,
                          iconColor: AppColors.warning,
                        ),
                      ],
                    ),

                    SizedBox(height: spacing * 1.5),

                    /// ======= INSIGHTS (DESKTOP-FIRST) =======
                    _buildInsights(context, provider, spacing: spacing),

                    SizedBox(height: spacing * 2),

                    /// ======= ORDENS + AGENDA =======
                    ResponsiveUtils.isMobile(context)
                        ? Column(
                            children: [
                              _buildRecentOrders(provider),
                              SizedBox(height: spacing),
                              _buildSchedule(provider),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildRecentOrders(provider),
                              ),
                              SizedBox(width: spacing),
                              Expanded(child: _buildSchedule(provider)),
                            ],
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
  /// Bloco que dá “cara SaaS premium”: gráfico + resumo/atalhos.
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
      title: 'Evolução (últimos 6 meses)',
      child: SizedBox(
        height: 220,
        child: _buildLineChart(
          context,
          months: months,
          entradas: entradas,
          saidas: saidas,
        ),
      ),
    );

    final resumo = _sectionContainer(
      title: 'Resumo rápido',
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
            iconColor: AppColors.error,
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
            iconColor: saldoHoje >= 0 ? AppColors.success : AppColors.error,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          /// Atalhos (desktop-friendly)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _quickAction(
                context,
                icon: Icons.receipt_long,
                label: 'Orçamentos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrcamentosScreen()),
                ),
              ),
              _quickAction(
                context,
                icon: Icons.people_alt,
                label: 'Clientes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientesScreen()),
                ),
              ),
              _quickAction(
                context,
                icon: Icons.attach_money,
                label: 'Financeiro',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FinanceiroScreen()),
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

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 140,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
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
    final textColor = Colors.white.withValues(alpha: 0.65);
    final gridColor = Colors.white.withValues(alpha: 0.06);

    final maxY = <double>[
      ...entradas,
      ...saidas,
    ].fold<double>(0, (m, v) => v > m ? v : m);
    // fl_chart espera double? em maxY; usar double evita erro de tipo (num).
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
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: safeMaxY / 4,
              getTitlesWidget: (value, meta) {
                final label = value == 0
                    ? '0'
                    : Formatters.compactCurrency(value);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, color: textColor),
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
                    style: TextStyle(fontSize: 11, color: textColor),
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
            color: AppColors.primaryYellow,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryYellow.withValues(alpha: 0.12),
            ),
          ),
          LineChartBarData(
            spots: spotsFrom(saidas),
            isCurved: true,
            barWidth: 2,
            color: AppColors.error.withValues(alpha: 0.85),
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.error.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
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
  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.name.trim() ?? '';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Row(
      children: [
        Expanded(
          child: Text(
            'Visão Geral',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        CircleAvatar(
          backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.2),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    required Color iconColor,
    String? trend,
    bool trendUp = true,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: ResponsiveUtils.isMobile(context) ? double.infinity : 260,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: iconColor, size: 26),
                    if (trend != null)
                      Text(
                        trend,
                        style: TextStyle(
                          color: trendUp ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= ORDENS RECENTES =================
  Widget _buildRecentOrders(AppProvider provider) {
    final orders = provider.orcamentos.take(5).toList();

    return _sectionContainer(
      title: 'Ordens Recentes',
      child: orders.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nenhuma ordem recente'),
            )
          : Column(
              children: orders
                  .map(
                    (o) => ListTile(
                      title: Text(o.clienteNome),
                      subtitle: Text(o.veiculoDescricao),
                      trailing: Text(Formatters.currency(o.valorTotal)),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// ================= AGENDA =================
  Widget _buildSchedule(AppProvider provider) {
    final pendentes = provider.orcamentosPendentes.take(3).toList();

    return _sectionContainer(
      title: 'Próximos Agendamentos',
      child: pendentes.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Sem agendamentos'),
            )
          : Column(
              children: pendentes
                  .map(
                    (o) => ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(o.clienteNome),
                      subtitle: Text(o.veiculoDescricao),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  /// ================= CONTAINER PADRÃO =================
  Widget _sectionContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
