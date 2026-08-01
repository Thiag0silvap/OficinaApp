import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Escala tipográfica. Uma família só (Work Sans, declarada no pubspec com os
/// pesos 400/500/600/700/800). Pesos e tamanhos são intencionais; não invente
/// variações nas telas.
class AppText {
  AppText._();

  static const String _family = 'Work Sans';

  /// Título grande de tela ("Orçamentos", "Clientes").
  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Título de card / seção.
  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Valor monetário em destaque.
  static const TextStyle money = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Corpo padrão.
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Texto secundário (metadados, subtítulos).
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Texto de botão.
  static const TextStyle button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// Rótulo pequeno / caption.
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
  );

  /// Micro-label uppercase (eyebrows de seção).
  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textTertiary,
  );
}