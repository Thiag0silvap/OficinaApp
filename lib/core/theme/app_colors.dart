import 'package:flutter/material.dart';

/// Paleta única do OficinaApp ("Confiança Noturna" — Sprint 0). NENHUM widget
/// deve declarar cores soltas — tudo referencia estes tokens. Isso garante
/// consistência entre telas (mobile e desktop) e permite ajuste global em um
/// só lugar.
class AppColors {
  AppColors._();

  // ---------- Superfícies (camadas, do fundo para o topo) ----------
  /// Fundo base do canvas do app.
  static const Color bg = Color(0xFF0B0D11);

  /// Fundo do topbar / sidebar — tom mais escuro que o canvas.
  static const Color bgHeader = Color(0xFF07090C);

  /// Superfície de cards.
  static const Color surface = Color(0xFF15181E);

  /// Superfície elevada (menus, dropdowns, chips, inputs — variante A do
  /// handoff: mais clara que o canvas, mais escura que o card).
  static const Color elevated = Color(0xFF111418);

  /// Superfície de input recessa (variante B do handoff). Coincide com o
  /// canvas por definição do design; mantida como token nomeado à parte
  /// para expressar essa intenção explicitamente. Reservada — ainda não
  /// usada em nenhum widget nesta sprint.
  static const Color inputSurfaceRecessed = bg;

  /// Borda/divisor de cards (1px).
  static const Color line = Color(0xFF25292F);

  /// Borda de campos de input (1px) — tom próprio, distinto da borda de card.
  static const Color inputBorder = Color(0xFF2A2E34);

  // ---------- Marca / ação ----------
  static const Color primary = Color(0xFFD49648);
  static const Color primaryPressed = Color(0xFFB4803D);

  /// Texto/ícone sobre superfície de brand accent (contraste alto).
  static const Color onPrimary = Color(0xFF171008);

  // ---------- Texto ----------
  static const Color textPrimary = Color(0xFFECEFF2);

  /// Texto secundário/muted — tom único (handoff permite uma só variável).
  static const Color textSecondary = Color(0xFF909399);

  /// Não há, nesta paleta, um terceiro tom mais apagado que textSecondary;
  /// mantido igual para não quebrar quem já referencia textTertiary.
  static const Color textTertiary = textSecondary;

  // ---------- Semântico (USO EXCLUSIVO em status e valores) ----------
  static const Color success = Color(0xFF5DC879); // concluído / entradas
  static const Color pending = Color(0xFFFCC270); // pendente (fg da pílula)
  static const Color info = Color(0xFF70CCEE); // aprovado (fg da pílula)
  static const Color danger = Color(0xFFE0645F); // excluir / saídas (tom único)

  // ---------- Versões "tint" (fundo usado pelas pílulas de status) ----------
  // pendente/aprovado/concluído usam o bg exato do par de pílula do handoff
  // (sólido, não alpha-blend). emAndamento/cancelado ainda não têm um par
  // dedicado no widget StatusPill (ver AppColors.pill* abaixo) — continuam
  // como alpha-blend do tom cheio até uma sprint futura reescrever o widget.
  static const Color primaryTint = Color(0x24D49648); // ~14%, usado por "emAndamento"
  static const Color successTint = Color(0xFF0D371A); // bg exato do par "Concluído"
  static const Color pendingTint = Color(0xFF442E09); // bg exato do par "Pendente"
  static const Color infoTint = Color(0xFF072D3D); // bg exato do par "Aprovado"
  static const Color dangerTint = Color(0x24E0645F); // ~14%, usado por "cancelado"

  // ---------- Pares de pílula de status (tabela completa do handoff) ----------
  // Prontos para quando o widget StatusPill for reescrito para usar os pares
  // diretos (fora do escopo desta sprint). "Em andamento" e "Pago" ainda não
  // têm uso no app hoje.
  static const Color pillPendenteBg = Color(0xFF442E09);
  static const Color pillPendenteFg = Color(0xFFFCC270);
  static const Color pillAprovadoBg = Color(0xFF072D3D);
  static const Color pillAprovadoFg = Color(0xFF70CCEE);
  static const Color pillEmAndamentoBg = Color(0xFF33244B);
  static const Color pillEmAndamentoFg = Color(0xFFCEB5FF);
  static const Color pillConcluidoBg = Color(0xFF0D371A);
  static const Color pillConcluidoFg = Color(0xFF7CDD93);
  static const Color pillPagoBg = Color(0xFF033633);
  static const Color pillPagoFg = Color(0xFF6ED9D2);
  static const Color pillCanceladoBg = Color(0xFF292221);
  static const Color pillCanceladoFg = Color(0xFF9B8B88);

  // ---------- Aliases de compatibilidade (telas pré-Sprint 0) ----------
  // As telas antigas ainda referenciam os nomes abaixo. Mantidos aqui para
  // não quebrar compilação; remover conforme cada tela for migrada para os
  // tokens novos acima.
  static const Color primaryYellow = primary;
  static const Color primaryDark = primaryPressed;
  static const Color secondaryGray = elevated;
  static const Color surface2 = elevated;
  static const Color lightGray = textTertiary;
  static const Color white = textPrimary;
  static const Color border = line;
  static const Color warning = pending;
  static const Color error = danger;
}
