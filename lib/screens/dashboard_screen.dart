import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/utils/formatters.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import 'financeiro_screen.dart';

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
