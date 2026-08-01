import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Container padrão de conteúdo: superfície + borda hairline + raio de card.
/// Sem sombra — profundidade vem da camada de cor, não de blur.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: content,
      ),
    );
  }
}

/// Cabeçalho de seção com micro-label opcional.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.eyebrow, this.trailing});

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!.toUpperCase(), style: AppText.label),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(title, style: AppText.title),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Placa em fonte mono, uppercase — trata a placa como dado, não texto solto.
class PlateChip extends StatelessWidget {
  const PlateChip(this.plate, {super.key});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        plate.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}