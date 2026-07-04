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
          padding: const EdgeInsets.only(bottom: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 390) {
                return Row(
                  children: [
                    for (final requirement in requirements)
                      Expanded(
                        child: Center(
                          child: _PasswordRequirementRow(
                            label: requirement.label,
                            isMet: requirement.isMet,
                            isDark: isDark,
                            maxLabelWidth: 108,
                          ),
                        ),
                      ),
                  ],
                );
              }

              return Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 8,
                children: [
                  for (final requirement in requirements)
                    _PasswordRequirementRow(
                      label: requirement.label,
                      isMet: requirement.isMet,
                      isDark: isDark,
                      maxLabelWidth: 128,
                    ),
                ],
              );
            },
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
    required this.maxLabelWidth,
  });

  final String label;
  final bool isMet;
  final bool isDark;
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.42)
        : Colors.black.withValues(alpha: 0.44);
    final color = isMet ? AppColors.success : inactiveColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Icon(
            isMet ? AppIcons.tick_circle : AppIcons.record_circle,
            key: ValueKey('${label}_$isMet'),
            size: 15,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxLabelWidth),
          child: Text(
            label,
            softWrap: true,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10.5,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
