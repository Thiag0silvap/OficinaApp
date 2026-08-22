import 'package:flutter/material.dart';
import 'package:oficina_app/models/veiculo.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../models/orcamento.dart';
import '../../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_buttons.dart';
import 'cliente_actions.dart';
import 'cliente_form_dialog.dart';
import 'responsive_components.dart';

class ClienteDetailDialog extends StatelessWidget {
  final Cliente cliente;
  const ClienteDetailDialog({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final veiculos = provider.getVeiculosByCliente(cliente.id);
        final orcamentos = provider.getOrcamentosByCliente(cliente.id);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.modal),
                border: Border.all(color: AppColors.line),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(cliente: cliente, provider: provider),
                    const SizedBox(height: AppSpacing.lg),
                    _ContatoCard(cliente: cliente),
                    const SizedBox(height: AppSpacing.lg),
                    _VeiculosCard(cliente: cliente, veiculos: veiculos),
                    const SizedBox(height: AppSpacing.lg),
                    _OrcamentosCard(orcamentos: orcamentos),
                    const SizedBox(height: AppSpacing.xl),
                    _FooterActions(cliente: cliente),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Cliente cliente;
  final AppProvider provider;
  const _Header({required this.cliente, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            cliente.nome,
            style: AppText.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        buildClienteMenu(context, provider, cliente, fecharModalAntes: true),
        const SizedBox(width: AppSpacing.xs),
        GhostIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ContatoCard extends StatelessWidget {
  final Cliente cliente;
  const _ContatoCard({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(Icons.phone, 'Telefone', cliente.telefone),
          if (cliente.endereco != null)
            _kv(Icons.location_on, 'Endereço', cliente.endereco!),
          if (cliente.observacoes != null)
            _kv(Icons.note, 'Observações', cliente.observacoes!),
        ],
      ),
    );
  }

  Widget _kv(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.label),
                Text(value, style: AppText.bodySecondary.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VeiculosCard extends StatelessWidget {
  final Cliente cliente;
  final List<Veiculo> veiculos;
  const _VeiculosCard({required this.cliente, required this.veiculos});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VEÍCULOS (${veiculos.length})', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          if (veiculos.isEmpty)
            Text('Nenhum veículo cadastrado', style: AppText.bodySecondary)
          else
            for (final v in veiculos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => showVeiculoFormDialog(
                      context,
                      cliente: cliente,
                      veiculoEditar: v,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '• ${v.descricaoCompleta}',
                              style: AppText.bodySecondary
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _OrcamentosCard extends StatelessWidget {
  final List<Orcamento> orcamentos;
  const _OrcamentosCard({required this.orcamentos});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORÇAMENTOS (${orcamentos.length})', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          if (orcamentos.isEmpty)
            Text('Nenhum orçamento criado', style: AppText.bodySecondary)
          else
            for (final o in orcamentos)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '• ${o.status.displayName} - ${Formatters.currency(o.valorTotal)}',
                  style: AppText.bodySecondary.copyWith(color: AppColors.textPrimary),
                ),
              ),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  final Cliente cliente;
  const _FooterActions({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GhostButton(
            label: 'Fechar',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PrimaryButton(
            label: 'Editar',
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => ClienteFormDialog(clienteEditar: cliente),
              );
            },
          ),
        ),
      ],
    );
  }
}