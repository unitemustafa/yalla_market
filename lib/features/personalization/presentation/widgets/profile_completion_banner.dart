import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../controllers/user_profile_controller.dart';

class ProfileCompletionBanner extends StatelessWidget {
  const ProfileCompletionBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfileController>(
      valueListenable: UserProfileController.instance,
      builder: (context, profile, _) {
        if (profile.isProfileComplete) return const SizedBox.shrink();

        final percent = profile.profileCompletionPercent;
        final isArabic = context.isArabicLanguage;
        final title = isArabic
            ? 'ملفك الشخصي مكتمل بنسبة $percent%'
            : 'Your profile is $percent% complete';
        final action = isArabic ? 'كمّل الآن' : 'Complete now';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              color: AppColors.primary.withValues(alpha: 0.09),
              padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 4,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.16,
                            ),
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    action,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
