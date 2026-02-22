// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/stat_card.dart';
import '../providers/app_provider.dart';
import '../models/transacao.dart';

class FinanceiroScreen extends StatelessWidget {
  const FinanceiroScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return ResponsiveContainer(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    Tooltip(
                      message: 'Voltar',
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Financeiro',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.primaryYellow,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// CARDS RESUMO
                ResponsiveStatsGrid(
                  children: [
                    StatCard(
                      title: 'Saldo',
                      value: Formatters.currency(provider.saldo),
                      icon: Icons.account_balance_wallet,
                      iconColor: provider.saldo >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    StatCard(
                      title: 'Entradas',
                      value: Formatters.currency(provider.totalEntradas),
                      icon: Icons.trending_up,
                      iconColor: AppColors.success,
                    ),
                    StatCard(
                      title: 'Saídas',
                      value: Formatters.currency(provider.totalSaidas),
                      icon: Icons.trending_down,
                      iconColor: AppColors.error,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// LISTA
                provider.transacoes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: ResponsiveCard(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long,
                                      color: AppColors.primaryYellow,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nenhuma transação registrada',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Clique em “Nova” para adicionar a primeira entrada ou saída.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.transacoes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final t = provider.transacoes.reversed
                              .toList()[index];
                          final isEntrada = t.tipo == TipoTransacao.entrada;

                          return ResponsiveCard(
                            child: Row(
                              children: [
                                Icon(
                                  isEntrada
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isEntrada
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.descricao,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${t.categoria} • ${_formatDate(t.data)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isEntrada ? '+' : '-'} ${Formatters.currency(t.valor)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isEntrada
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      provider.deleteTransacao(t.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= DIALOG ADD =================

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _NovaTransacaoDialog(),
    );
  }
}

class _NovaTransacaoDialog extends StatefulWidget {
  const _NovaTransacaoDialog();

  @override
  State<_NovaTransacaoDialog> createState() => _NovaTransacaoDialogState();
}

class _NovaTransacaoDialogState extends State<_NovaTransacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _valorFocus = FocusNode();

  TipoTransacao _tipo = TipoTransacao.entrada;
  final String _categoria = 'Serviço';

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _valorFocus.dispose();
    super.dispose();
  }

  double? _parseCurrencyInput(String input) {
    var s = input.trim().replaceAll(' ', '');
    if (s.isEmpty) return null;

    // Handles:
    // - 1.234,56 -> 1234.56
    // - 1234,56  -> 1234.56
    // - 1234.56  -> 1234.56
    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '');
      s = s.replaceAll(',', '.');
    } else if (s.contains(',')) {
      s = s.replaceAll(',', '.');
    }

    return double.tryParse(s);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final parsed = _parseCurrencyInput(_valorController.text);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor inválido.')),
      );
      return;
    }

    final transacao = Transacao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: _tipo,
      descricao: _descricaoController.text,
      valor: parsed,
      categoria: _categoria,
      data: DateTime.now(),
    );

    Provider.of<AppProvider>(
      context,
      listen: false,
    ).addTransacao(transacao);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryGray,
      title: const Text('Nova Transação'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<TipoTransacao>(
                segments: const [
                  ButtonSegment(
                    value: TipoTransacao.entrada,
                    label: Text('Entrada'),
                  ),
                  ButtonSegment(
                    value: TipoTransacao.saida,
                    label: Text('Saída'),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (v) => setState(() => _tipo = v.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _valorFocus.requestFocus(),
                decoration: const InputDecoration(labelText: 'Descrição *'),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                focusNode: _valorFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor *',
                  prefixText: 'R\$ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final parsed = _parseCurrencyInput(v);
                  if (parsed == null || parsed <= 0) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
