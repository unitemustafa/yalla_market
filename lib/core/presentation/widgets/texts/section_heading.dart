import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../icons/app_icons.dart';
import '../../../localization/app_translations.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    this.textColor,
    this.showActionButton = true,
    required this.title,
    this.buttonTitle = 'View all',
    this.titleFontSize,
    this.onPressed,
  });

  final Color? textColor;
  final bool showActionButton;
  final String title, buttonTitle;
  final double? titleFontSize;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            context.tr(title),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: textColor,
              fontSize: titleFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showActionButton) const SizedBox(width: 12),
        if (showActionButton)
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(buttonTitle),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: AppFontSizes.label,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  context.isArabicLanguage
                      ? AppIcons.arrow_left_2
                      : AppIcons.arrow_right_3,
                  color: AppColors.primary,
                  size: 13,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
