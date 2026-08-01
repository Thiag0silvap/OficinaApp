import 'package:flutter/material.dart';

/// Paleta única do OficinaApp. NENHUM widget deve declarar cores soltas —
/// tudo referencia estes tokens. Isso garante consistência entre telas
/// (mobile e desktop) e permite ajuste global em um só lugar.
class AppColors {
  AppColors._();

  // ---------- Superfícies (camadas, do fundo para o topo) ----------
  /// Fundo base da tela.
  static const Color bg = Color(0xFF0A0A0B);

  /// Superfície de cards / campos.
  static const Color surface = Color(0xFF16171A);

  /// Superfície elevada (menus, chips, elementos sobre cards).
  static const Color elevated = Color(0xFF1E2024);

  /// Borda/divisor hairline (1px).
  static const Color line = Color(0xFF2A2C30);

  // ---------- Marca / ação ----------
  static const Color primary = Color(0xFFF5C518);
  static const Color primaryPressed = Color(0xFFD9AD12);

  /// Texto/ícone sobre superfície amarela (contraste alto).
  static const Color onPrimary = Color(0xFF0A0A0B);

  // ---------- Texto ----------
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA1A1A6);
  static const Color textTertiary = Color(0xFF6E6E73);

  // ---------- Semântico (USO EXCLUSIVO em status e valores) ----------
  static const Color success = Color(0xFF34C759); // concluído / entradas
  static const Color pending = Color(0xFFFF9F0A); // pendente
  static const Color info = Color(0xFF0A84FF); // aprovado
  static const Color danger = Color(0xFFFF453A); // excluir / saídas

  // ---------- Versões "tint" (fundo 12–14% para pílulas) ----------
  static const Color primaryTint = Color(0x24F5C518); // ~14%
  static const Color successTint = Color(0x2434C759);
  static const Color pendingTint = Color(0x1FFF9F0A); // ~12%
  static const Color infoTint = Color(0x240A84FF);
  static const Color dangerTint = Color(0x24FF453A);

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