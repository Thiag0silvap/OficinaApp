import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

InputDecoration formFieldDecoration({
  required String label,
  IconData? prefixIcon,
  String? prefixText,
  bool filled = true,
  bool dense = false,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primaryYellow) : null,
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
