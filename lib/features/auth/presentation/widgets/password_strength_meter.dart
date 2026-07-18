import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final password = value.text;
        final requirements = _requirementsFor(context, password);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              for (final requirement in requirements)
                Expanded(
                  child: Center(
                    child: _PasswordRequirementRow(
                      label: requirement.label,
                      isMet: requirement.isMet,
                      isDark: isDark,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<_PasswordRequirement> _requirementsFor(
    BuildContext context,
    String password,
  ) {
    return [
      _PasswordRequirement(
        label: context.tr('8+ characters'),
        isMet: password.length >= 8,
      ),
      _PasswordRequirement(
        label: context.tr('Upper & lowercase'),
        isMet:
            RegExp(r'[A-Z]').hasMatch(password) &&
            RegExp(r'[a-z]').hasMatch(password),
      ),
      _PasswordRequirement(
        label: context.tr('Number & symbol'),
        isMet:
            RegExp(r'\d').hasMatch(password) &&
            RegExp(r'[^A-Za-z0-9]').hasMatch(password),
      ),
    ];
  }
}

class _PasswordRequirement {
  const _PasswordRequirement({required this.label, required this.isMet});

  final String label;
  final bool isMet;
}

class _PasswordRequirementRow extends StatelessWidget {
  const _PasswordRequirementRow({
    required this.label,
    required this.isMet,
    required this.isDark,
  });

  final String label;
  final bool isMet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.42)
        : Colors.black.withValues(alpha: 0.44);
    final color = isMet ? AppColors.success : inactiveColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(
                isMet ? AppIcons.tick_circle : AppIcons.record_circle,
                key: ValueKey('${label}_$isMet'),
                size: 13,
                color: color,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: AppFontSizes.caption,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
