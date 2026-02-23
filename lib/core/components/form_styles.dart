import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

InputDecoration formFieldDecoration({
  required String label,
  IconData? prefixIcon,
  // Compat: versões anteriores chamavam este helper com o parâmetro `icon`.
  // Mantemos para não quebrar builds.
  IconData? icon,
  String? prefixText,
  bool filled = true,
  bool dense = false,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: (prefixIcon ?? icon) != null
        ? Icon((prefixIcon ?? icon)!, color: AppColors.primaryYellow)
        : null,
    prefixText: prefixText,
    filled: filled,
    isDense: dense,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
    ),
  );
}
