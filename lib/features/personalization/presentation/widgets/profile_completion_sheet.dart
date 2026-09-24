part of 'profile_completion_floating_button.dart';

extension _ProfileCompletionSheet on ProfileCompletionFloatingButton {
  void _showCompletionSheet(
    BuildContext context,
    UserProfileController currentProfile,
  ) {
    final isArabic = context.isArabicLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = currentProfile.profileCompletionPercent;
    final missing = currentProfile.missingProfileFields;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardColor : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.of(sheetContext).viewPadding.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top drag indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header with circular progress and text
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.18 : 0.08,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 46,
                                height: 46,
                                child: CircularProgressIndicator(
                                  value: percent / 100,
                                  strokeWidth: 4,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: isDark ? 0.2 : 0.12,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic
                                    ? 'ملفك الشخصي مكتمل بنسبة $percent%'
                                    : 'Your profile is $percent% complete',
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isArabic
                                    ? 'أكمل البيانات المتبقية لتجربة أفضل وتوصيل أسرع'
                                    : 'Complete missing info for faster delivery & better service',
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                      height: 1.3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Divider(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.08,
                      ),
                      height: 1,
                    ),
                    const SizedBox(height: 16),

                    // Title for missing fields
                    Text(
                      isArabic ? 'البيانات المتبقية:' : 'Missing details:',
                      style: Theme.of(sheetContext).textTheme.labelLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),

                    // Missing fields chips/tiles
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: missing.map((field) {
                            final label = _labelFor(field, isArabic: isArabic);
                            final icon = _iconFor(field);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: isDark
                                    ? const Color(0xFF333A44)
                                    : const Color(0xFFF6F8FA),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    if (onOpenField != null) {
                                      onOpenField?.call(field);
                                    } else {
                                      _navigateToField(context, field);
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.12,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            icon,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          isArabic ? 'إضافة' : 'Add',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bottom action button: Complete Now
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          if (onContinue != null) {
                            onContinue?.call();
                          } else {
                            Navigator.pushNamed(context, AppRoutes.profile);
                          }
                        },
                        child: Text(
                          isArabic ? 'كمّل الآن' : 'Complete now',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
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

  void _navigateToField(BuildContext context, String field) {
    final editable = _fieldToEditable(field);
    if (editable != null && editable != EditableProfileField.username) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileFieldView(field: editable),
        ),
      );
    } else if (onContinue != null) {
      onContinue?.call();
    } else {
      Navigator.pushNamed(context, AppRoutes.profile);
    }
  }

  static EditableProfileField? _fieldToEditable(String field) {
    return switch (field) {
      'name' => EditableProfileField.name,
      'username' => EditableProfileField.username,
      'phone' => EditableProfileField.phone,
      'city' => EditableProfileField.city,
      'gender' => EditableProfileField.gender,
      'birth_date' => EditableProfileField.birthDate,
      _ => null,
    };
  }

  static String _labelFor(String field, {required bool isArabic}) {
    return switch (field) {
      'name' => isArabic ? 'الاسم' : 'Name',
      'email' => isArabic ? 'البريد الإلكتروني' : 'Email',
      'username' => isArabic ? 'اسم المستخدم' : 'Username',
      'phone' => isArabic ? 'رقم الهاتف' : 'Phone number',
      'city' => isArabic ? 'المدينة' : 'City',
      'gender' => isArabic ? 'النوع' : 'Gender',
      'birth_date' => isArabic ? 'تاريخ الميلاد' : 'Birth date',
      _ => field,
    };
  }

  static IconData _iconFor(String field) {
    return switch (field) {
      'name' => AppIcons.user_edit,
      'email' => AppIcons.sms,
      'username' => AppIcons.user_tag,
      'phone' => AppIcons.call,
      'city' => AppIcons.location,
      'gender' => AppIcons.user,
      'birth_date' => AppIcons.calendar,
      _ => Icons.edit_note_rounded,
    };
  }
}
