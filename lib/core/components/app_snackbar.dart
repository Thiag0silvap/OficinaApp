import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Feedback padronizado. Substitui os SnackBars verdes full-width por um
/// componente flutuante consistente, com cor apenas na barra lateral/ícone.
enum SnackType { success, error, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
  }) {
    final (color, icon) = switch (type) {
      SnackType.success => (AppColors.success, Icons.check_circle_outline),
      SnackType.error => (AppColors.danger, Icons.error_outline),
      SnackType.info => (AppColors.primary, Icons.info_outline),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message, style: AppText.body)),
            ],
          ),
          backgroundColor: AppColors.elevated,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
        ),
      );
  }
}