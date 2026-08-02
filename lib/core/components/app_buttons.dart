import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Ação PRIMÁRIA. Amarelo preenchido, texto preto. Regra: uma por tela/card.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.onPrimary),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(label, style: AppText.button.copyWith(color: AppColors.onPrimary)),
      ],
    );

    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 13,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: onPressed == null ? 0.4 : 1,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Ação SECUNDÁRIA. Transparente + borda hairline. Nunca colorida por status.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onPressed == null ? 0.4 : 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 13,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label, style: AppText.button.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão só-ícone contido (ex.: menu ⋮). Mesma linguagem do ghost.
class GhostIconButton extends StatelessWidget {
  const GhostIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}