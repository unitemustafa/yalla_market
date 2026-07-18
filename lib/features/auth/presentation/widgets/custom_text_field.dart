import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_translations.dart';

class CustomTextField extends StatelessWidget {
  final Key? fieldKey;
  final String labelText;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final Color? suffixIconColor;
  final Widget? suffix;
  final bool obscureText;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final bool compact;

  const CustomTextField({
    super.key,
    this.fieldKey,
    required this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
    this.suffixIconColor,
    this.suffix,
    this.obscureText = false,
    this.onSuffixIconPressed,
    this.keyboardType,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.errorText,
    this.autovalidateMode,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final fillColor = isDarkMode
        ? const Color(0xFF222326)
        : const Color(0xFFF5F6FA);
    final borderColor = isDarkMode
        ? const Color(0xFF3A3B41)
        : const Color(0xFFE4E7F0);
    final iconColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.64)
        : Colors.black.withValues(alpha: 0.48);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF17181C);

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 10 : 16),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autovalidateMode: autovalidateMode,
        validator: validator,
        enabled: enabled,
        onTapOutside: (_) {},
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        cursorColor: theme.colorScheme.primary,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontSize: AppFontSizes.bodyLarge,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: context.tr(labelText),
          errorText: errorText == null ? null : context.tr(errorText!),
          filled: true,
          fillColor: fillColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: compact ? 14 : 18,
          ),
          labelStyle: TextStyle(
            color: iconColor,
            fontSize: AppFontSizes.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(prefixIcon, size: 21, color: iconColor),
          suffixIcon:
              suffix ??
              (suffixIcon != null
                  ? IconButton(
                      icon: Icon(
                        suffixIcon,
                        size: 21,
                        color: suffixIconColor ?? iconColor,
                      ),
                      onPressed: onSuffixIconPressed,
                    )
                  : null),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
          ),
        ),
      ),
    );
  }
}
