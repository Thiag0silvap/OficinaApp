import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/components/form_styles.dart';
import '../core/components/responsive_components.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_input_formatter.dart';
import '../models/transacao.dart';
import '../providers/app_provider.dart';

/// FINANCEIRO (Premium / Desktop-first)
/// - Cards (Entradas, Saídas, Saldo)
/// - Busca + filtros (tipo/ordenação)
/// - Lista de transações
/// - Modal para criar transação
class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

enum _TipoFiltro { todos, entradas, saidas }

enum _Ordenacao { recentes, maiorValor, menorValor }

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  final _searchCtrl = TextEditingController();
  _TipoFiltro _tipoFiltro = _TipoFiltro.todos;
  _Ordenacao _ordenacao = _Ordenacao.recentes;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        final transacoes = _filtrarOrdenar(app.transacoes);

        return Scaffold(
          body: ResponsiveContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    countLabel: '${transacoes.length} transações',
                    onAdd: () => _openAddDialog(context),
                  ),
                  const SizedBox(height: 14),
                  _FiltersRow(
                    searchCtrl: _searchCtrl,
                    tipoFiltro: _tipoFiltro,
                    ordenacao: _ordenacao,
                    onTipoChanged: (v) => setState(() => _tipoFiltro = v),
                    onOrdenacaoChanged: (v) => setState(() => _ordenacao = v),
                    onSearchChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(
                    entradas: app.totalEntradas,
                    saidas: app.totalSaidas,
                    saldo: app.saldo,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _TransacoesList(
                      transacoes: transacoes,
                      onDelete: (t) => _confirmDelete(context, t),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Transacao> _filtrarOrdenar(List<Transacao> src) {
    final q = _searchCtrl.text.trim().toLowerCase();

    Iterable<Transacao> out = src;
    if (_tipoFiltro == _TipoFiltro.entradas) {
      out = out.where((t) => t.tipo == TipoTransacao.entrada);
    } else if (_tipoFiltro == _TipoFiltro.saidas) {
      out = out.where((t) => t.tipo == TipoTransacao.saida);
    }

    if (q.isNotEmpty) {
      out = out.where((t) {
        final d = t.descricao.toLowerCase();
        final c = t.categoria.toLowerCase();
        final v = t.valor.toStringAsFixed(2);
        return d.contains(q) || c.contains(q) || v.contains(q);
      });
    }

    final list = out.toList();
    switch (_ordenacao) {
      case _Ordenacao.recentes:
        list.sort((a, b) => b.data.compareTo(a.data));
        break;
      case _Ordenacao.maiorValor:
        list.sort((a, b) => b.valor.compareTo(a.valor));
        break;
      case _Ordenacao.menorValor:
        list.sort((a, b) => a.valor.compareTo(b.valor));
        break;
    }
    return list;
  }

  Future<void> _confirmDelete(BuildContext context, Transacao t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.secondaryGray,
          title: const Text('Excluir transação?'),
          content: Text('“${t.descricao}” será removida permanentemente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (ok == true && context.mounted) {
      await context.read<AppProvider>().deleteTransacao(t.id);
    }
  }

  Future<void> _openAddDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _NovaTransacaoDialog(),
    );
  }
}

class _Header extends StatelessWidget {
  final String countLabel;
  final VoidCallback onAdd;

  const _Header({required this.countLabel, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financeiro',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Controle de entradas e saídas com histórico e filtros.',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CountPill(label: countLabel),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Nova Transação'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  const _CountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  final TextEditingController searchCtrl;
  final _TipoFiltro tipoFiltro;
  final _Ordenacao ordenacao;
  final ValueChanged<_TipoFiltro> onTipoChanged;
  final ValueChanged<_Ordenacao> onOrdenacaoChanged;
  final ValueChanged<String> onSearchChanged;

  const _FiltersRow({
    required this.searchCtrl,
    required this.tipoFiltro,
    required this.ordenacao,
    required this.onTipoChanged,
    required this.onOrdenacaoChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    const h = 48.0;
    final r = BorderRadius.circular(14);

    Widget pill({required Widget child}) {
      return Container(
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.secondaryGray,
          borderRadius: r,
          border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
        ),
        alignment: Alignment.center,
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            flex: 12,
            child: SizedBox(
              height: h,
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar por descrição, categoria ou valor…',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.white.withValues(alpha: 0.65),
                  ),
                  filled: true,
                  fillColor: AppColors.secondaryGray,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: r,
                    borderSide: BorderSide(
                      color: AppColors.lightGray.withValues(alpha: 0.7),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: r,
                    borderSide: BorderSide(
                      color: AppColors.lightGray.withValues(alpha: 0.7),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(
                      color: AppColors.primaryYellow,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          pill(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_TipoFiltro>(
                value: tipoFiltro,
                dropdownColor: AppColors.secondaryGray,
                borderRadius: BorderRadius.circular(14),
                onChanged: (v) {
                  if (v != null) onTipoChanged(v);
                },
                items: const [
                  DropdownMenuItem(
                    value: _TipoFiltro.todos,
                    child: Text('Todos'),
                  ),
                  DropdownMenuItem(
                    value: _TipoFiltro.entradas,
                    child: Text('Entradas'),
                  ),
                  DropdownMenuItem(
                    value: _TipoFiltro.saidas,
                    child: Text('Saídas'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          pill(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_Ordenacao>(
                value: ordenacao,
                dropdownColor: AppColors.secondaryGray,
                borderRadius: BorderRadius.circular(14),
                onChanged: (v) {
                  if (v != null) onOrdenacaoChanged(v);
                },
                items: const [
                  DropdownMenuItem(
                    value: _Ordenacao.recentes,
                    child: Text('Recentes'),
                  ),
                  DropdownMenuItem(
                    value: _Ordenacao.maiorValor,
                    child: Text('Maior valor'),
                  ),
                  DropdownMenuItem(
                    value: _Ordenacao.menorValor,
                    child: Text('Menor valor'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double entradas;
  final double saidas;
  final double saldo;

  const _SummaryRow({
    required this.entradas,
    required this.saidas,
    required this.saldo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Entradas',
              value: entradas,
              icon: Icons.arrow_downward_rounded,
              chipColor: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Saídas',
              value: saidas,
              icon: Icons.arrow_upward_rounded,
              chipColor: AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Saldo',
              value: saldo,
              icon: Icons.account_balance_wallet_outlined,
              chipColor: saldo >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color chipColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(16);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: br,
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: chipColor.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: chipColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  money.format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransacoesList extends StatelessWidget {
  final List<Transacao> transacoes;
  final ValueChanged<Transacao> onDelete;

  const _TransacoesList({required this.transacoes, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (transacoes.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.secondaryGray,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lightGray.withValues(alpha: 0.7),
            ),
          ),
          child: const Text(
            'Nenhuma transação encontrada com os filtros atuais.',
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      itemCount: transacoes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = transacoes[i];
        return _TransacaoTile(transacao: t, onDelete: () => onDelete(t));
      },
    );
  }
}

class _TransacaoTile extends StatelessWidget {
  final Transacao transacao;
  final VoidCallback onDelete;

  const _TransacaoTile({required this.transacao, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isEntrada = transacao.tipo == TipoTransacao.entrada;
    final badgeColor = isEntrada ? AppColors.success : AppColors.error;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              isEntrada ? 'Entrada' : 'Saída',
              style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transacao.descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transacao.categoria} • ${dateFmt.format(transacao.data)}',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            money.format(transacao.valor),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isEntrada ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Excluir',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _NovaTransacaoDialog extends StatefulWidget {
  const _NovaTransacaoDialog();

  @override
  State<_NovaTransacaoDialog> createState() => _NovaTransacaoDialogState();
}

class _NovaTransacaoDialogState extends State<_NovaTransacaoDialog> {
  TipoTransacao _tipo = TipoTransacao.entrada;
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  DateTime _data = DateTime.now();

  @override
  void dispose() {
    _descCtrl.dispose();
    _valorCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondaryGray,
      title: const Text('Nova Transação'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TipoTransacao>(
                    initialValue: _tipo,
                    dropdownColor: AppColors.secondaryGray,
                    decoration: formFieldDecoration(label: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: TipoTransacao.entrada,
                        child: Text('Entrada'),
                      ),
                      DropdownMenuItem(
                        value: TipoTransacao.saida,
                        child: Text('Saída'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _tipo = v ?? TipoTransacao.entrada),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    decoration: formFieldDecoration(
                      label: 'Data',
                      prefixIcon: Icons.calendar_today_outlined,
                    ),
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(_data),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _data,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) {
                          return Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                                primary: AppColors.primaryYellow,
                                surface: AppColors.secondaryGray,
                              ),
                              dialogTheme: Theme.of(ctx).dialogTheme.copyWith(
                                backgroundColor: AppColors.secondaryGray,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => _data = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: formFieldDecoration(
                label: 'Descrição',
                prefixIcon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valorCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyTextInputFormatter()],
                    decoration: formFieldDecoration(
                      label: 'Valor',
                      prefixText: 'R\$ ',
                      prefixIcon: Icons.payments_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _catCtrl,
                    decoration: formFieldDecoration(
                      label: 'Categoria',
                      prefixIcon: Icons.sell_outlined,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvar,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryYellow,
            foregroundColor: AppColors.primaryDark,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _salvar() async {
    final desc = _descCtrl.text.trim();
    final cat = _catCtrl.text.trim();

    // valor no formato pt_BR (ex: 1.234,56)
    final raw = _valorCtrl.text.replaceAll('.', '').replaceAll(',', '.').trim();
    final valor = double.tryParse(raw) ?? 0.0;

    if (desc.isEmpty || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a descrição e um valor válido.'),
        ),
      );
      return;
    }

    final t = Transacao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: _tipo,
      descricao: desc,
      valor: valor,
      categoria: cat.isEmpty ? 'Geral' : cat,
      data: _data,
    );

    await context.read<AppProvider>().addTransacao(t);

    if (mounted) Navigator.pop(context);
  }
}
