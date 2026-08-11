import 'package:flutter/material.dart';

import '../../../../core/localization/app_translations.dart';

InputDecoration checkoutInputDecoration({
  required BuildContext context,
  required bool isDark,
  required IconData icon,
  required String label,
  String? errorText,
}) {
  return InputDecoration(
    prefixIcon: Icon(icon),
    labelText: context.tr(label),
    errorText: errorText,
    filled: true,
    fillColor: isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF7F8FB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
      ),
    ),
  );
}
