import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Chip informativo (ícone + rótulo curto) sobre superfície de card —
/// usado tanto em listas de resumo (ex.: contagem de veículos/orçamentos
/// no card de cliente) quanto em stepper headers (ex.: passo do form de
/// cliente). Consolidado a partir de duas implementações idênticas em
/// clientes_screen.dart e cliente_form_dialog.dart.
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
