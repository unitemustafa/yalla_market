import 'package:flutter/material.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../controllers/user_profile_controller.dart';
import '../views/profile/edit_profile_field_view.dart';

part 'profile_completion_sheet.dart';

/// A modern floating circular progress button that displays profile completion progress
/// and allows the user to view missing fields and complete them.
class ProfileCompletionFloatingButton extends StatelessWidget {
  const ProfileCompletionFloatingButton({
    super.key,
    this.profile,
    this.size = 62.0,
    this.onContinue,
    this.onOpenField,
  });

  final UserProfileController? profile;
  final double size;
  final VoidCallback? onContinue;
  final void Function(String field)? onOpenField;

  @override
  Widget build(BuildContext context) {
    final controller = profile ?? UserProfileController.instance;

    return ValueListenableBuilder<UserProfileController>(
      valueListenable: controller,
      builder: (context, currentProfile, _) {
        if (currentProfile.isProfileComplete) return const SizedBox.shrink();

        final percent = currentProfile.profileCompletionPercent;
        final isArabic = context.isArabicLanguage;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final tooltipMsg = isArabic
            ? 'ملفك الشخصي مكتمل بنسبة $percent% (اضغط للإكمال)'
            : 'Your profile is $percent% complete (tap to complete)';

        final progressSize = (size - 14).clamp(32.0, 56.0);
        final strokeWidth = size >= 60 ? 3.8 : 3.2;
        final textSize = size >= 60 ? 12.5 : 10.5;
        final badgeSize = size >= 60 ? 18.0 : 15.0;
        final badgeIconSize = size >= 60 ? 11.0 : 9.5;

        return Tooltip(
          message: tooltipMsg,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _showCompletionSheet(context, currentProfile),
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF222831) : Colors.white,
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.35 : 0.22,
                    ),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.45 : 0.28,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.08,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Circular progress indicator ring
                    SizedBox(
                      width: progressSize,
                      height: progressSize,
                      child: CircularProgressIndicator(
                        value: percent / 100,
                        strokeWidth: strokeWidth,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: isDark ? 0.2 : 0.12,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),

                    // Percent text in the center
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),

                    // Floating alert badge on the top right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: badgeSize,
                        height: badgeSize,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF222831)
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.priority_high_rounded,
                          size: badgeIconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
