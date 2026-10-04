import 'package:flutter/material.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';

class SettingsMenuTile extends StatelessWidget {
  const SettingsMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subTitle,
    this.trailing,
    this.onTap,
    this.accentColor = AppColors.primary,
    this.compactText = false,
  });

  final IconData icon;
  final String title, subTitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color accentColor;
  final bool compactText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final trailingIcon = Directionality.of(context) == TextDirection.rtl
        ? AppIcons.arrow_left_2
        : AppIcons.arrow_right_3;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 22, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(title),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontSize: compactText ? 13 : null,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(subTitle),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: mutedColor,
                        fontSize: compactText ? 10.5 : null,
                        height: 1.25,
                      ),
                      maxLines: compactText ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    trailingIcon,
                    size: 18,
                    color: onTap == null
                        ? mutedColor.withValues(alpha: 0.55)
                        : mutedColor,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
