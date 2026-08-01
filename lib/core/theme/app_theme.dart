import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// Tema único do app. Aplicado via `MaterialApp(theme: AppTheme.dark)`.
///
/// IMPORTANTE (desktop-first): isto substitui APENAS a aparência. Nenhuma
/// regra de negócio muda. Desktop e mobile compartilham o mesmo tema, então
/// aplicar aqui já unifica as duas plataformas sem regressão de lógica.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.primary,
        error: AppColors.danger,
        onSurface: AppColors.textPrimary,
      ),

      // ---------- AppBar ----------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgHeader,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // ---------- Cards ----------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),

      // ---------- Campos ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.elevated,
        // Um rótulo só: usamos label flutuante e NÃO hint ao mesmo tempo,
        // evitando a sobreposição de textos vista no formulário de orçamento.
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppText.body.copyWith(color: AppColors.textTertiary),
        labelStyle: AppText.bodySecondary,
        floatingLabelStyle: AppText.caption.copyWith(color: AppColors.primary),
        border: _fieldBorder(AppColors.inputBorder),
        enabledBorder: _fieldBorder(AppColors.inputBorder),
        focusedBorder: _fieldBorder(AppColors.primary, width: 1.5),
        errorBorder: _fieldBorder(AppColors.danger),
        focusedErrorBorder: _fieldBorder(AppColors.danger, width: 1.5),
        errorStyle: AppText.caption.copyWith(color: AppColors.danger),
      ),

      // ---------- Bottom navigation ----------
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgHeader,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
      ),

      // ---------- Divisores ----------
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),

      // ---------- SnackBar (padrão neutro; cor por tipo vem via helper) ----------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.elevated,
        contentTextStyle: AppText.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          side: const BorderSide(color: AppColors.line),
        ),
      ),

      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}