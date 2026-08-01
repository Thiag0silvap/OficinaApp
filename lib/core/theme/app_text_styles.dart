import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Escala tipográfica ("Confiança Noturna" — Sprint 0). Duas famílias:
/// Sora (600/700/800) para headings/títulos/valores monetários, Inter
/// (400/500/600/700) para corpo/UI/labels/botões — ambas declaradas no
/// pubspec. Pesos e tamanhos são intencionais; não invente variações nas
/// telas.
class AppText {
  AppText._();

  static const String _display = 'Sora';
  static const String _body = 'Inter';

  /// Título grande de tela ("Orçamentos", "Clientes").
  static const TextStyle display = TextStyle(
    fontFamily: _display,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Título de card / seção.
  static const TextStyle title = TextStyle(
    fontFamily: _display,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Valor monetário em destaque.
  static const TextStyle money = TextStyle(
    fontFamily: _display,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Corpo padrão.
  static const TextStyle body = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Texto secundário (metadados, subtítulos).
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Texto de botão.
  static const TextStyle button = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// Rótulo pequeno / caption.
  static const TextStyle caption = TextStyle(
    fontFamily: _body,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
  );

  /// Micro-label uppercase (eyebrows de seção).
  static const TextStyle label = TextStyle(
    fontFamily: _body,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textTertiary,
  );
}