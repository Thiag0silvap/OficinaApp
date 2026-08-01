import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../models/orcamento.dart';
import '../models/cliente.dart';
import '../models/veiculo.dart';

class OrcamentosScreen extends StatefulWidget {
  const OrcamentosScreen({super.key});

  @override
  State<OrcamentosScreen> createState() => _OrcamentosScreenState();
}

class _OrcamentosScreenState extends State<OrcamentosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Orçamentos'),
        actions: [
          IconButton(
            onPressed: () => _showCreateOrcamentoDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryYellow,
          unselectedLabelColor: AppColors.white,
          indicatorColor: AppColors.primaryYellow,
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Aprovados'),
            Tab(text: 'Em Andamento'),
            Tab(text: 'Concluídos'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrcamentosList(provider.orcamentosPendentes, 'Pendente'),
              _buildOrcamentosList(provider.orcamentosAprovados, 'Aprovado'),
              _buildOrcamentosList(provider.orcamentosEmAndamento, 'Em andamento'),
              _buildOrcamentosList(provider.orcamentosConcluidos, 'Concluído'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrcamentoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOrcamentosList(List<Orcamento> orcamentos, String status) {
    if (orcamentos.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orcamentos.length,
      itemBuilder: (context, index) {
        final orcamento = orcamentos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orcamento.clienteNome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            orcamento.veiculoDescricao,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(orcamento.status),
                  ],
                ),
                const SizedBox(height: 12),
                ...orcamento.itens.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('${AppConstants.servicosIcones[item.servico] ?? '🔧'}'),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.servico)),
                          Text(
                            'R\$ ${item.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryYellow,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Row(
                  children: [
                    Text(
                      'Data: ${orcamento.dataCriacao.day}/${orcamento.dataCriacao.month}/${orcamento.dataCriacao.year}',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Total: R\$ ${orcamento.valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionButtons(context, orcamento),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum orçamento $status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pendente':
        color = AppColors.warning;
        break;
      case 'Aprovado':
        color = AppColors.info;
        break;
      case 'Em andamento':
        color = AppColors.primaryYellow;
        break;
      case 'Concluído':
        color = AppColors.success;
        break;
      default:
        color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Orcamento orcamento) {
    final provider = context.read<AppProvider>();
    
    switch (orcamento.status) {
      case 'Pendente':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showEditOrcamentoDialog(context, orcamento),
                child: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => provider.aprovarOrcamento(orcamento.id),
                child: const Text('Aprovar'),
              ),
            ),
          ],
        );
      case 'Aprovado':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => provider.cancelarOrcamento(orcamento.id),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => provider.iniciarServico(orcamento.id),
                child: const Text('Iniciar'),
              ),
            ),
          ],
        );
      case 'Em andamento':
        return ElevatedButton(
          onPressed: () => _showConcluirDialog(context, orcamento),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('Concluir Serviço'),
        );
      default:
        return Container();
    }
  }

  void _showCreateOrcamentoDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    
    if (provider.clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário cadastrar clientes primeiro!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Cliente? clienteSelecionado;
    Veiculo? veiculoSelecionado;
    List<ItemOrcamento> itens = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final veiculos = clienteSelecionado != null
              ? provider.getVeiculosByCliente(clienteSelecionado!.id)
              : <Veiculo>[];

          return AlertDialog(
            backgroundColor: AppColors.secondaryGray,
            title: const Text('Novo Orçamento'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cliente:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Cliente>(
                      initialValue: clienteSelecionado,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: provider.clientes
                          .map((cliente) => DropdownMenuItem(
                                value: cliente,
                                child: Text(cliente.nome),
                              ))
                          .toList(),
                      onChanged: (cliente) {
                        setDialogState(() {
                          clienteSelecionado = cliente;
                          veiculoSelecionado = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Veículo:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Veiculo>(
                      initialValue: veiculoSelecionado,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      items: veiculos
                          .map((veiculo) => DropdownMenuItem(
                                value: veiculo,
                                child: Text(veiculo.descricaoCompleta),
                              ))
                          .toList(),
                      onChanged: veiculos.isEmpty
                          ? null
                          : (veiculo) {
                              setDialogState(() {
                                veiculoSelecionado = veiculo;
                              });
                            },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('Serviços:'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showAddItemDialog(context, (item) {
                            setDialogState(() {
                              itens.add(item);
                            });
                          }),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (itens.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.lightGray.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Nenhum serviço adicionado',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...itens.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Card(
                          child: ListTile(
                            leading: Text('${AppConstants.servicosIcones[item.servico] ?? '🔧'}'),
                            title: Text(item.servico),
                            subtitle: Text(item.descricao),
