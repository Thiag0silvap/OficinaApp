import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/components/app_buttons.dart';
import '../core/components/form_styles.dart';
import '../core/components/responsive_components.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_feedback.dart';
import '../core/utils/currency_input_formatter.dart';
import '../models/orcamento.dart';
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
    // Se a transação está vinculada a um orçamento e é o pagamento dele
    // (orçamento atualmente marcado como pago), a confirmação avisa que
    // excluir vai reverter o status de pagamento — em vez da confirmação
    // genérica de exclusão.
    final provider = context.read<AppProvider>();
    Orcamento? orcamentoVinculado;
    if (t.orcamentoId != null) {
      for (final o in provider.orcamentos) {
        if (o.id == t.orcamentoId && o.pago) {
          orcamentoVinculado = o;
          break;
        }
      }
    }

    final WidgetBuilder confirmBuilder = orcamentoVinculado != null
        ? (ctx) => AlertDialog(
            backgroundColor: AppColors.elevated,
            title: const Text('Excluir pagamento de orçamento?'),
            content: Text(
              'Esta transação é o pagamento do orçamento de '
              '${orcamentoVinculado!.clienteNome}. Excluí-la vai marcar '
              'o orçamento como "Concluído, aguardando pagamento" '
              'novamente. Deseja continuar?',
            ),
            actions: [
              GhostButton(
                label: 'Cancelar',
                onPressed: () => Navigator.pop(ctx, false),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Excluir mesmo assim'),
              ),
            ],
          )
        : (ctx) => AlertDialog(
            backgroundColor: AppColors.elevated,
            title: const Text('Excluir transação?'),
            content: Text('“${t.descricao}” será removida permanentemente.'),
            actions: [
              GhostButton(
                label: 'Cancelar',
                onPressed: () => Navigator.pop(ctx, false),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Excluir'),
              ),
            ],
          );

    final ok = await showDialog<bool>(context: context, builder: confirmBuilder);

    if (ok == true && context.mounted) {
      try {
        await context.read<AppProvider>().deleteTransacao(t.id);
        if (!context.mounted) return;
        AppFeedback.showSuccess(context, 'Transação excluída com sucesso.');
      } catch (e) {
        if (!context.mounted) return;
        AppFeedback.showError(context, 'Erro ao excluir transação: $e');
      }
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
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Financeiro',
                style: AppText.display.copyWith(fontSize: 22),
              ),
            ),
            PrimaryButton(
              label: 'Nova',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financeiro', style: AppText.display),
                const SizedBox(height: 4),
                Text(
                  'Controle de entradas e saídas com histórico e filtros.',
                  style: AppText.bodySecondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CountPill(label: countLabel),
          const SizedBox(width: 10),
          PrimaryButton(
            label: 'Nova Transação',
            icon: Icons.add,
            onPressed: onAdd,
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
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.7)),
      ),
      alignment: Alignment.center,
      child: Text(label, style: AppText.body.copyWith(fontWeight: FontWeight.w700)),
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
    final isMobile = ResponsiveUtils.isMobile(context);
    const h = 48.0;
    final r = BorderRadius.circular(14);

    Widget pill({required Widget child}) {
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
        child: child,
      );
    }

    final searchField = SizedBox(
      height: h,
      child: TextField(
        controller: searchCtrl,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: isMobile ? 'Buscar...' : 'Buscar por descrição, categoria ou valor…',
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textPrimary.withValues(alpha: 0.65),
          ),
          filled: true,
          fillColor: AppColors.elevated,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: r,
            borderSide: BorderSide(
              color: AppColors.textTertiary.withValues(alpha: 0.7),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: r,
            borderSide: BorderSide(
              color: AppColors.textTertiary.withValues(alpha: 0.7),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );

    final tipoDropdown = pill(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_TipoFiltro>(
          value: tipoFiltro,
          dropdownColor: AppColors.elevated,
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
    );

    final ordenacaoDropdown = pill(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_Ordenacao>(
          value: ordenacao,
          dropdownColor: AppColors.elevated,
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
    );

    final padding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsets.symmetric(horizontal: 22);

    if (isMobile) {
      return Padding(
        padding: padding,
        child: Column(
          children: [
            searchField,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: tipoDropdown),
                const SizedBox(width: 10),
                Expanded(child: ordenacaoDropdown),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(flex: 12, child: searchField),
          const SizedBox(width: 10),
          tipoDropdown,
          const SizedBox(width: 10),
          ordenacaoDropdown,
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
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsets.symmetric(horizontal: 22);

    final entradasCard = _SummaryCard(
      title: 'Entradas',
      value: entradas,
      icon: Icons.arrow_downward_rounded,
      chipColor: AppColors.success,
    );
    final saidasCard = _SummaryCard(
      title: 'Saídas',
      value: saidas,
      icon: Icons.arrow_upward_rounded,
      chipColor: AppColors.danger,
    );

    // Mobile segue o handoff: sem o card Saldo, só Entradas/Saídas lado a
    // lado (grid 2 colunas). Desktop/tablet mantêm os 3 cards em linha.
    if (isMobile) {
      return Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(child: entradasCard),
            const SizedBox(width: 12),
            Expanded(child: saidasCard),
          ],
        ),
      );
    }

    final saldoCard = _SummaryCard(
      title: 'Saldo',
      value: saldo,
      icon: Icons.account_balance_wallet_outlined,
      chipColor: saldo >= 0 ? AppColors.success : AppColors.danger,
    );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: entradasCard),
          const SizedBox(width: 12),
          Expanded(child: saidasCard),
          const SizedBox(width: 12),
          Expanded(child: saldoCard),
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
    final isMobile = ResponsiveUtils.isMobile(context);
    final br = BorderRadius.circular(16);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: br,
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.7),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: chipColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(icon, color: chipColor, size: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppText.bodySecondary.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  money.format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.money.copyWith(fontSize: 13, color: chipColor),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: chipColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(icon, color: chipColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.bodySecondary),
                      const SizedBox(height: 6),
                      Text(
                        money.format(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.money.copyWith(fontSize: 20),
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
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            'Nenhuma transação encontrada com os filtros atuais.',
            style: AppText.body,
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
    final badgeColor = isEntrada ? AppColors.success : AppColors.danger;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.7)),
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
              style: AppText.caption.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w800,
              ),
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
                  style: AppText.body.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transacao.categoria} • ${dateFmt.format(transacao.data)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySecondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            money.format(transacao.valor),
            style: AppText.money.copyWith(fontSize: 15, color: badgeColor),
          ),
          const SizedBox(width: 10),
          GhostIconButton(
            icon: Icons.delete_outline,
            onPressed: onDelete,
            tooltip: 'Excluir',
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
  static const int _maxDescLen = 120;
  static const int _maxCatLen = 40;
  static const double _maxCurrencyValue = 100000000.0;

  final _formKey = GlobalKey<FormState>();
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
    final dialog = ResponsiveDialog(
      title: 'Nova Transação',
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TipoTransacao>(
                      initialValue: _tipo,
                      dropdownColor: AppColors.elevated,
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
                                  primary: AppColors.primary,
                                  surface: AppColors.elevated,
                                ),
                                dialogTheme: Theme.of(ctx).dialogTheme.copyWith(
                                  backgroundColor: AppColors.elevated,
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
              TextFormField(
                controller: _descCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(_maxDescLen)],
                decoration: formFieldDecoration(
                  label: 'Descrição',
                  prefixIcon: Icons.description_outlined,
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Descrição é obrigatória';
                  if (v.length > _maxDescLen) return 'Descrição muito longa';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valorCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyTextInputFormatter()],
                      decoration: formFieldDecoration(
                        label: 'Valor',
                        prefixText: 'R\$ ',
                        prefixIcon: Icons.payments_outlined,
                      ),
                      validator: (value) {
                        final raw = (value ?? '')
                            .replaceAll('.', '')
                            .replaceAll(',', '.')
                            .trim();
                        final parsed = double.tryParse(raw) ?? 0.0;
                        if (parsed <= 0) return 'Valor inválido';
                        if (parsed > _maxCurrencyValue) return 'Valor muito alto';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _catCtrl,
                      inputFormatters: [LengthLimitingTextInputFormatter(_maxCatLen)],
                      decoration: formFieldDecoration(
                        label: 'Categoria',
                        prefixIcon: Icons.sell_outlined,
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.length > _maxCatLen) return 'Categoria muito longa';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        GhostButton(
          label: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Salvar',
          onPressed: _salvar,
        ),
      ],
    );

    return Focus(autofocus: false, child: dialog);
  }

  Future<void> _salvar() async {
    final desc = _descCtrl.text.trim();
    final cat = _catCtrl.text.trim();

    // valor no formato pt_BR (ex: 1.234,56)
    final raw = _valorCtrl.text.replaceAll('.', '').replaceAll(',', '.').trim();
    final valor = double.tryParse(raw) ?? 0.0;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final t = Transacao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: _tipo,
      descricao: desc,
      valor: valor,
      categoria: cat.isEmpty ? 'Geral' : cat,
      data: _data,
    );

    try {
      await context.read<AppProvider>().addTransacao(t);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Transação salva com sucesso.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erro ao salvar transação: $e');
    }
  }
}
