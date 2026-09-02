import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/components/app_buttons.dart';
import '../core/components/app_card.dart';
import '../core/components/form_styles.dart';
import '../core/components/responsive_components.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_feedback.dart';
import '../core/utils/currency_input_formatter.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../providers/app_provider.dart';
import '../core/components/transacao_detail_dialog.dart';
import 'relatorio_financeiro_screen.dart';

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
  DateTime? _diaFiltro;

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
        final mesParaStats = _diaFiltro ?? DateTime.now();

        return Scaffold(
          body: ResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  countLabel: '${transacoes.length} transações',
                  onAdd: () => _openAddDialog(context),
                  onRelatorio: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RelatorioFinanceiroScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _FiltersRow(
                  searchCtrl: _searchCtrl,
                  tipoFiltro: _tipoFiltro,
                  ordenacao: _ordenacao,
                  diaFiltro: _diaFiltro,
                  onTipoChanged: (v) => setState(() => _tipoFiltro = v),
                  onOrdenacaoChanged: (v) => setState(() => _ordenacao = v),
                  onDiaChanged: (v) => setState(() => _diaFiltro = v),
                  onSearchChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SaldoCard(
                  saldo: app.saldo,
                  entradasMes: app.entradasNoMes(mesParaStats),
                  saidasMes: app.saidasNoMes(mesParaStats),
                  mesLabel: _formatMes(mesParaStats),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _TransacoesList(
                    transacoes: transacoes,
                    onDelete: (t) => _confirmDelete(context, t),
                  ),
                ),
              ],
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

    if (_diaFiltro != null) {
      out = out.where(
        (t) =>
            t.data.year == _diaFiltro!.year &&
            t.data.month == _diaFiltro!.month &&
            t.data.day == _diaFiltro!.day,
      );
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

    final ok = await showDialog<bool>(
      context: context,
      builder: confirmBuilder,
    );

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
  final VoidCallback onRelatorio;

  const _Header({
    required this.countLabel,
    required this.onAdd,
    required this.onRelatorio,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Financeiro',
              style: AppText.display.copyWith(fontSize: 22),
            ),
          ),
          GhostIconButton(
            icon: Icons.bar_chart_rounded,
            tooltip: 'Relatório Financeiro',
            onPressed: onRelatorio,
          ),
          const SizedBox(width: 10),
          PrimaryButton(label: 'Nova', icon: Icons.add, onPressed: onAdd),
        ],
      );
    }

    return Row(
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
        GhostIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Relatório Financeiro',
          onPressed: onRelatorio,
        ),
        const SizedBox(width: 10),
        PrimaryButton(
          label: 'Nova Transação',
          icon: Icons.add,
          onPressed: onAdd,
        ),
      ],
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
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.7),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppText.body.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  final TextEditingController searchCtrl;
  final _TipoFiltro tipoFiltro;
  final _Ordenacao ordenacao;
  final DateTime? diaFiltro;
  final ValueChanged<_TipoFiltro> onTipoChanged;
  final ValueChanged<_Ordenacao> onOrdenacaoChanged;
  final ValueChanged<DateTime?> onDiaChanged;
  final ValueChanged<String> onSearchChanged;

  const _FiltersRow({
    required this.searchCtrl,
    required this.tipoFiltro,
    required this.ordenacao,
    required this.diaFiltro,
    required this.onTipoChanged,
    required this.onOrdenacaoChanged,
    required this.onDiaChanged,
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
          hintText: isMobile
              ? 'Buscar...'
              : 'Buscar por descrição, categoria ou valor…',
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
            borderSide: BorderSide(color: AppColors.primary, width: 2),
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
            DropdownMenuItem(value: _TipoFiltro.todos, child: Text('Todos')),
            DropdownMenuItem(
              value: _TipoFiltro.entradas,
              child: Text('Entradas'),
            ),
            DropdownMenuItem(value: _TipoFiltro.saidas, child: Text('Saídas')),
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

    Future<void> abrirDatePicker() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: diaFiltro ?? DateTime.now(),
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
      if (picked != null) onDiaChanged(picked);
    }

    // Compacto: só o ícone quando não há filtro (mesmo estilo de
    // GhostIconButton, usado em outros botões de ação da tela), e um pill
    // pequeno (ícone + data + X de limpar) quando há — nunca largura total,
    // diferente do pill de Tipo/Ordenação.
    final diaPill = diaFiltro == null
        ? GhostIconButton(
            icon: Icons.calendar_today_outlined,
            tooltip: 'Filtrar por data',
            onPressed: abrirDatePicker,
          )
        : Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.button),
              onTap: abrirDatePicker,
              child: Container(
                height: h,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy').format(diaFiltro!),
                      style: AppText.body,
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => onDiaChanged(null),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

    if (isMobile) {
      return Column(
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
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: diaPill),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 12, child: searchField),
        const SizedBox(width: 10),
        tipoDropdown,
        const SizedBox(width: 10),
        ordenacaoDropdown,
        const SizedBox(width: 10),
        diaPill,
      ],
    );
  }
}

/// Card único: Saldo geral (all-time) em destaque + Entradas/Saídas do mês
/// filtrado (padrão: mês atual) lado a lado. Substitui os 3 cards
/// separados que existiam antes.
class _SaldoCard extends StatelessWidget {
  final double saldo;
  final double entradasMes;
  final double saidasMes;
  final String mesLabel;

  const _SaldoCard({
    required this.saldo,
    required this.entradasMes,
    required this.saidasMes,
    required this.mesLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final saldoColor = saldo >= 0 ? AppColors.success : AppColors.danger;

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: isMobile ? 36 : 44,
                width: isMobile ? 36 : 44,
                decoration: BoxDecoration(
                  color: saldoColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: saldoColor.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: saldoColor,
                  size: isMobile ? 18 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo geral', style: AppText.bodySecondary),
                    const SizedBox(height: 2),
                    Text(
                      money.format(saldo),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.money.copyWith(
                        fontSize: isMobile ? 20 : 26,
                        color: saldoColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 18),
          Container(height: 1, color: AppColors.line),
          SizedBox(height: isMobile ? 14 : 18),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: 'Entradas de $mesLabel',
                  value: entradasMes,
                  icon: Icons.arrow_downward_rounded,
                  chipColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  title: 'Saídas de $mesLabel',
                  value: saidasMes,
                  icon: Icons.arrow_upward_rounded,
                  chipColor: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color chipColor;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Row(
      children: [
        Container(
          height: isMobile ? 28 : 32,
          width: isMobile ? 28 : 32,
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: chipColor.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: chipColor, size: isMobile ? 14 : 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodySecondary.copyWith(
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
              Text(
                money.format(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.money.copyWith(
                  fontSize: isMobile ? 13 : 15,
                  color: chipColor,
                ),
              ),
            ],
          ),
        ),
      ],
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

    final grupos = _agruparPorDia(transacoes);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: grupos.length,
      itemBuilder: (context, i) {
        final grupo = grupos[i];
        return Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GroupHeader(dia: grupo.dia, count: grupo.itens.length),
              const SizedBox(height: 10),
              for (final t in grupo.itens) ...[
                _TransacaoTile(transacao: t, onDelete: () => onDelete(t)),
                if (t != grupo.itens.last) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TransacaoGroup {
  final DateTime dia;
  final List<Transacao> itens;
  const _TransacaoGroup(this.dia, this.itens);
}

/// Agrupa por dia do calendário sobre a lista já filtrada/ordenada. Os
/// GRUPOS são sempre ordenados por dia decrescente (mais recente primeiro)
/// — independente da Ordenação (Recentes/Maior valor/Menor valor)
/// selecionada — para os cabeçalhos "Hoje"/"Ontem" nunca aparecerem
/// fragmentados/repetidos quando o filtro ordena por valor em vez de
/// data. Dentro de cada grupo, a ordem dos itens preserva exatamente a
/// ordem que _filtrarOrdenar já produziu.
List<_TransacaoGroup> _agruparPorDia(List<Transacao> transacoes) {
  final porDia = <DateTime, List<Transacao>>{};
  for (final t in transacoes) {
    final dia = DateTime(t.data.year, t.data.month, t.data.day);
    porDia.putIfAbsent(dia, () => []).add(t);
  }
  final dias = porDia.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final d in dias) _TransacaoGroup(d, porDia[d]!)];
}

/// Formato numérico "MM/yyyy" — usado no rótulo do _SaldoCard (mês da
/// data filtrada, ou mês atual sem filtro). Evita depender de
/// DateFormat('MMMM', ...) com nome de mês por extenso, já que
/// initializeDateFormatting() não é chamado em nenhum lugar do app.
String _formatMes(DateTime mes) =>
    '${mes.month.toString().padLeft(2, '0')}/${mes.year}';

String _headerLabel(DateTime dia) {
  final now = DateTime.now();
  final hoje = DateTime(now.year, now.month, now.day);
  final ontem = hoje.subtract(const Duration(days: 1));
  if (dia == hoje) return 'Hoje';
  if (dia == ontem) return 'Ontem';
  return DateFormat('dd/MM/yyyy').format(dia);
}

class _GroupHeader extends StatelessWidget {
  final DateTime dia;
  final int count;

  const _GroupHeader({required this.dia, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(_headerLabel(dia), style: AppText.title.copyWith(fontSize: 15)),
        const SizedBox(width: 8),
        Text(
          '$count ${count == 1 ? 'transação' : 'transações'}',
          style: AppText.bodySecondary,
        ),
      ],
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
    final horaFmt = DateFormat('HH:mm');

    return AppCard(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TransacaoDetailDialog(transacao: transacao),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                child: Text(
                  transacao.descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${transacao.categoria} • ${horaFmt.format(transacao.data)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySecondary,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    money.format(transacao.valor),
                    style: AppText.money.copyWith(
                      fontSize: 15,
                      color: badgeColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GhostIconButton(
                    icon: Icons.delete_outline,
                    onPressed: onDelete,
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ],
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
  bool _isSaving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _valorCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Nova Transação',
            style: AppText.title.copyWith(color: AppColors.primary),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildFields(context),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        label: 'Cancelar',
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Salvar',
                        expanded: true,
                        isLoading: _isSaving,
                        onPressed: _salvar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dialog = ResponsiveDialog(
      title: 'Nova Transação',
      stackedActions: true,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: _buildFields(context),
        ),
      ),
      actions: [
        GhostButton(
          label: 'Cancelar',
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        PrimaryButton(
          label: 'Salvar',
          isLoading: _isSaving,
          onPressed: _salvar,
        ),
      ],
    );

    return Focus(autofocus: false, child: dialog);
  }

  Widget _buildFields(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldPair(
          first: DropdownButtonFormField<TipoTransacao>(
            initialValue: _tipo,
            isExpanded: true,
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
          second: TextFormField(
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
        _FieldPair(
          first: TextFormField(
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
          second: TextFormField(
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
    );
  }

  Future<void> _salvar() async {
    if (_isSaving) return;

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

    setState(() => _isSaving = true);

    try {
      await context.read<AppProvider>().addTransacao(t);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Transação salva com sucesso.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Erro ao salvar transação: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// Lado a lado no desktop/tablet; empilhado em coluna única no mobile —
/// labels como "Categoria" não cabem ao lado de outro campo em telas
/// estreitas mesmo com o diálogo em largura máxima (medição real).
class _FieldPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _FieldPair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return Column(children: [first, const SizedBox(height: 12), second]);
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }
}
