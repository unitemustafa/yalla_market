import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../icons/app_icons.dart';
import '../localization/app_translations.dart';
import '../preferences/app_preferences_controller.dart';
import '../presentation/widgets/snackbars/custom_snackbar.dart';
import 'app_theme.dart';

class AppThemeToggle extends StatefulWidget {
  const AppThemeToggle({super.key});

  @override
  State<AppThemeToggle> createState() => _AppThemeToggleState();
}

class _AppThemeToggleState extends State<AppThemeToggle> {
  bool _switching = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ThemeSwitcher(
      builder: (switcherContext) => IconButton(
        tooltip: context.tr(isDark ? 'Light' : 'Dark'),
        onPressed: _switching ? null : () => _toggle(switcherContext, isDark),
        style: IconButton.styleFrom(
          fixedSize: const Size(42, 42),
          backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        icon: Icon(isDark ? AppIcons.sun_1 : AppIcons.moon, size: 21),
      ),
    );
  }

  Future<void> _toggle(BuildContext switcherContext, bool isDark) async {
    if (_switching) return;
    final model = ThemeModelInheritedNotifier.of(switcherContext);
    if (model.controller.isAnimating) return;
    // Lock before screenshot capture too, so rapid taps cannot overlap it.
    setState(() => _switching = true);
    model.controller.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 450);
    ThemeSwitcher.of(switcherContext).changeTheme(
      theme: isDark ? AppTheme.lightTheme : AppTheme.darkTheme,
      onAnimationFinish: () {
        if (mounted) setState(() => _switching = false);
      },
    );
    try {
      await AppPreferencesController.instance.setThemeMode(
        isDark ? ThemeMode.light : ThemeMode.dark,
      );
    } catch (_) {
      if (!mounted) return;
      CustomSnackBar.showError(context: context, title: 'Try again');
    }
  }
}
