import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('GRAU CAR'),
            Text(
              'O grau que o seu carro precisa',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cards de resumo financeiro
                _buildResumoFinanceiro(context, provider),
                const SizedBox(height: 24),

                // Orçamentos em destaque
                _buildOrcamentosDestaque(context, provider),
                const SizedBox(height: 24),

                // Estatísticas rápidas
                _buildEstatisticasRapidas(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumoFinanceiro(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo Financeiro',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                context,
                'Saldo Total',
                provider.saldo,
                provider.saldo >= 0 ? AppColors.success : AppColors.error,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                context,
                'Mês Atual',
                provider.saldoMesAtual,
                provider.saldoMesAtual >= 0 ? AppColors.success : AppColors.error,
                Icons.calendar_month,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                context,
                'Entradas',
                provider.totalEntradas,
                AppColors.success,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                context,
                'Saídas',
                provider.totalSaidas,
                AppColors.error,
                Icons.trending_down,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinanceCard(
    BuildContext context,
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrcamentosDestaque(BuildContext context, AppProvider provider) {
    final pendentes = provider.orcamentosPendentes.length;
    final aprovados = provider.orcamentosAprovados.length;
    final emAndamento = provider.orcamentosEmAndamento.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Orçamentos',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOrcamentoCard(
                context,
                'Pendentes',
                pendentes,
                AppColors.warning,
                Icons.pending_actions,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOrcamentoCard(
                context,
                'Aprovados',
                aprovados,
                AppColors.info,
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOrcamentoCard(
                context,
                'Em Andamento',
                emAndamento,
                AppColors.primaryYellow,
                Icons.build,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrcamentoCard(
    BuildContext context,
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticasRapidas(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow(
                  'Total de Clientes',
                  provider.clientes.length.toString(),
                  Icons.people,
                ),
                const Divider(),
                _buildStatRow(
                  'Veículos Cadastrados',
                  provider.veiculos.length.toString(),
                  Icons.directions_car,
                ),
                const Divider(),
                _buildStatRow(
                  'Orçamentos Criados',
                  provider.orcamentos.length.toString(),
                  Icons.description,
                ),
                const Divider(),
                _buildStatRow(
                  'Serviços Concluídos',
                  provider.orcamentosConcluidos.length.toString(),
                  Icons.done_all,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryYellow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryYellow,
            ),
          ),
        ],
      ),
    );
  }
}
