import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../models/transacao.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            onPressed: _showRelatoriosDialog,
            icon: const Icon(Icons.analytics),
          ),
          IconButton(
            onPressed: () => _showAddTransacaoDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryYellow,
          unselectedLabelColor: AppColors.white,
          indicatorColor: AppColors.primaryYellow,
          tabs: const [
            Tab(text: 'Resumo'),
            Tab(text: 'Transações'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildResumoTab(provider),
              _buildTransacoesTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransacaoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildResumoTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de resumo geral
          _buildResumoGeral(provider),
          const SizedBox(height: 24),

          // Resumo do mês atual
          _buildResumoMensal(provider),
          const SizedBox(height: 24),

          // Gráfico de categorias de despesas
          _buildDespesasPorCategoria(provider),
          const SizedBox(height: 24),

          // Transações recentes
          _buildTransacoesRecentes(provider),
        ],
      ),
    );
  }

  Widget _buildResumoGeral(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo Geral',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                'Total Entradas',
                provider.totalEntradas,
                AppColors.success,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                'Total Saídas',
                provider.totalSaidas,
                AppColors.error,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFinanceCard(
          'Saldo Total',
          provider.saldo,
          provider.saldo >= 0 ? AppColors.success : AppColors.error,
          Icons.account_balance_wallet,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildResumoMensal(AppProvider provider) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Resumo do Mês',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            Text(
              '${_getMonthName(now.month)}/${now.year}',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                'Entradas',
                provider.entradasMesAtual,
                AppColors.success,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                'Saídas',
                provider.saidasMesAtual,
                AppColors.error,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFinanceCard(
          'Saldo do Mês',
          provider.saldoMesAtual,
          provider.saldoMesAtual >= 0 ? AppColors.success : AppColors.error,
          Icons.account_balance,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildDespesasPorCategoria(AppProvider provider) {
    final now = DateTime.now();
    final despesas = provider.getDespesasPorCategoria(now.year, now.month);

    if (despesas.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Despesas por Categoria',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: despesas.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.key)),
                            Text(
                              'R\$ ${entry.value.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransacoesRecentes(AppProvider provider) {
    final transacoesRecentes = provider.transacoes
        .where((t) => DateTime.now().difference(t.data).inDays <= 7)
        .take(5)
        .toList();

    if (transacoesRecentes.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transações Recentes',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: transacoesRecentes
                .map((transacao) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transacao.tipo == TipoTransacao.entrada
                            ? AppColors.success
                            : AppColors.error,
                        child: Icon(
                          transacao.tipo == TipoTransacao.entrada
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: AppColors.white,
                        ),
                      ),
                      title: Text(transacao.descricao),
                      subtitle: Text(
                        '${transacao.data.day}/${transacao.data.month}/${transacao.data.year} • ${transacao.categoria}',
                      ),
                      trailing: Text(
                        '${transacao.tipo == TipoTransacao.entrada ? '+' : '-'} R\$ ${transacao.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transacao.tipo == TipoTransacao.entrada
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

... (truncated in file for brevity)
