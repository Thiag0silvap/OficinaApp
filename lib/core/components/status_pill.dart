import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Estados de um orçamento/OS. Mapeados 1:1 para cor + rótulo, para que
/// nenhuma tela precise decidir cor de status manualmente.
enum AppStatus { pendente, aprovado, emAndamento, concluido, cancelado }

extension AppStatusStyle on AppStatus {
  Color get color => switch (this) {
        AppStatus.pendente => AppColors.pending,
        AppStatus.aprovado => AppColors.info,
        AppStatus.emAndamento => AppColors.primary,
        AppStatus.concluido => AppColors.success,
        AppStatus.cancelado => AppColors.danger,
      };

  Color get tint => switch (this) {
        AppStatus.pendente => AppColors.pendingTint,
        AppStatus.aprovado => AppColors.infoTint,
        AppStatus.emAndamento => AppColors.primaryTint,
        AppStatus.concluido => AppColors.successTint,
        AppStatus.cancelado => AppColors.dangerTint,
      };

  String get label => switch (this) {
        AppStatus.pendente => 'Pendente',
        AppStatus.aprovado => 'Aprovado',
        AppStatus.emAndamento => 'Em andamento',
        AppStatus.concluido => 'Concluído',
        AppStatus.cancelado => 'Cancelado',
      };
}

/// Pílula de status. Fundo tint + texto na cor cheia — legível e discreta.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}