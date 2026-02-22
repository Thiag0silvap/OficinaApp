import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'responsive_components.dart';
// Reuse responsive helpers and widgets consolidated in responsive_components.dart

class HeaderWithAction extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final String addLabelShort;
  final String addLabelLong;

  const HeaderWithAction({
    super.key,
    required this.title,
    required this.onAdd,
    this.addLabelShort = 'Novo',
    this.addLabelLong = 'Novo',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ResponsiveText(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.bold,
              ),
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: ResponsiveUtils.isDesktop(context)
              ? Text(addLabelLong)
              : Text(addLabelShort),
        ),
      ],
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.isDesktop(context) ? 120 : 80,
            color: AppColors.white.withValues(alpha: 0.3),
          ),
          SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
          ResponsiveText(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.isDesktop(context) ? 24 : 18,
              color: AppColors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            subtitle,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.4),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getCardSpacing(context) * 2),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
