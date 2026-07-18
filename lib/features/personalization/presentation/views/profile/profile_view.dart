import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../../core/presentation/widgets/images/app_avatar.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/profile_image_cubit.dart';
import '../../controllers/user_profile_controller.dart';
import '../../widgets/profile_menu_tile.dart';
import 'edit_profile_field_view.dart';
import 'membership_benefits_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isRefreshingProfile = false;
  bool _showInlineRefreshProgress = false;
  bool _isUploadingProfilePhoto = false;
  String? _refreshProfileError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile({bool showInlineProgress = true}) async {
    if (!mounted || _isRefreshingProfile) return;
    setState(() {
      _isRefreshingProfile = true;
      _showInlineRefreshProgress = showInlineProgress;
      _refreshProfileError = null;
    });

    final user = await context.read<AuthCubit>().refreshProfile();
    if (!mounted) return;

    if (user != null) {
      UserProfileController.instance.updateFromAuthUser(user);
    }

    setState(() {
      _isRefreshingProfile = false;
      _showInlineRefreshProgress = false;
      _refreshProfileError = user == null ? 'Could not refresh profile' : null;
    });
  }

  Future<void> _pickProfileImage(BuildContext context) async {
    if (_isUploadingProfilePhoto) return;

    final profileImageCubit = context.read<ProfileImageCubit>();
    final pickedImage = await profileImageCubit.pickProfileImage();
    if (!context.mounted) return;

    if (pickedImage == null) {
      final state = profileImageCubit.state;
      if (state is ProfileImageFailure) {
        CustomSnackBar.showError(
          context: context,
          title: context.tr('Could not open gallery'),
          message: context.tr(state.message),
        );
      }
      return;
    }

    setState(() => _isUploadingProfilePhoto = true);
    final authCubit = context.read<AuthCubit>();
    final updatedUser = await authCubit.updateProfileAvatar(
      bytes: pickedImage.bytes,
      fileName: pickedImage.fileName,
    );
    if (!context.mounted) return;

    setState(() => _isUploadingProfilePhoto = false);
    if (updatedUser == null) {
      CustomSnackBar.showError(
        context: context,
        title: context.tr('Could not update profile photo'),
        message: context.tr(
          authCubit.lastProfileUpdateError ?? 'Could not update profile photo',
        ),
      );
      return;
    }

    UserProfileController.instance.updateFromAuthUser(updatedUser);
    CustomSnackBar.showSuccess(
      context: context,
      title: context.tr('Profile photo updated'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ValueListenableBuilder<UserProfileController>(
          valueListenable: UserProfileController.instance,
          builder: (context, profile, _) {
            return AppRefreshIndicator(
              onRefresh: () => _loadProfile(showInlineProgress: false),
              child: SingleChildScrollView(
                physics: AppRefreshIndicator.scrollPhysics,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  children: [
                    const PageTopBar(
                      title: 'Profile',
                      subtitle: 'Edit personal details',
                    ),
                    if (_isRefreshingProfile && _showInlineRefreshProgress) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (_refreshProfileError != null) ...[
                      const SizedBox(height: 10),
                      _RefreshProfileError(message: _refreshProfileError!),
                    ],
                    const SizedBox(height: 18),
                    _ProfileHeaderCard(
                      isDark: isDark,
                      profile: profile,
                      isUploadingAvatar: _isUploadingProfilePhoto,
                      onAvatarTap: () => _pickProfileImage(context),
                      onMembershipTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MembershipBenefitsView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _ProfileInfoSection(
                      title: context.tr('Profile Information'),
                      isDark: isDark,
                      children: [
                        ProfileMenuTile(
                          leadingIcon: AppIcons.user_edit,
                          title: context.tr('Name'),
                          value: profile.displayName,
                          onTap: () =>
                              _openEditor(context, EditableProfileField.name),
                        ),
                        ProfileMenuTile(
                          leadingIcon: AppIcons.user_tag,
                          title: context.tr('Username'),
                          value: profile.username,
                          onTap: () => _handleUsernameTap(context, profile),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ProfileInfoSection(
                      title: context.tr('Personal Information'),
                      isDark: isDark,
                      children: [
                        ProfileMenuTile(
                          leadingIcon: AppIcons.sms,
                          title: context.tr('E-mail'),
                          value: profile.email,
                          showTrailingIcon: false,
                        ),
                        ProfileMenuTile(
                          leadingIcon: AppIcons.call,
                          title: context.tr('Phone'),
                          value: profile.phone.isEmpty
                              ? context.tr('Not set')
                              : profile.phone,
                          onTap: () =>
                              _openEditor(context, EditableProfileField.phone),
                        ),
                        ProfileMenuTile(
                          leadingIcon: AppIcons.user,
                          title: context.tr('Gender'),
                          value: profile.gender.isEmpty
                              ? context.tr('Not set')
                              : context.tr(_genderLabel(profile.gender)),
                          onTap: () =>
                              _openEditor(context, EditableProfileField.gender),
                        ),
                        ProfileMenuTile(
                          leadingIcon: AppIcons.calendar,
                          title: context.tr('Birth Date'),
                          value: _formatDate(profile.birthDate),
                          onTap: () => _openEditor(
                            context,
                            EditableProfileField.birthDate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, EditableProfileField field) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileFieldView(field: field)),
    );
  }

  String _genderLabel(String value) {
    return switch (value.trim().toLowerCase()) {
      'male' => 'Male',
      'female' => 'Female',
      _ => value,
    };
  }

  void _handleUsernameTap(BuildContext context, UserProfileController profile) {
    if (!profile.canChangeUsername) {
      CustomSnackBar.showWarning(
        context: context,
        title: context.tr('Username locked'),
        message:
            '${context.tr('You can change your username again on')} ${_formatDate(profile.nextUsernameChangeAt)}.',
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            context.tr('Change username?'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            context.tr(
              'After saving a new username, you will not be able to change it again for 7 days.',
            ),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(context.tr('Cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _openEditor(context, EditableProfileField.username);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      context.tr('Continue'),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Not set';
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _RefreshProfileError extends StatelessWidget {
  const _RefreshProfileError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: isDark ? 0.26 : 0.14),
        ),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.warning_2, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr(message),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.isDark,
    required this.profile,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
    required this.onMembershipTap,
  });

  final bool isDark;
  final UserProfileController profile;
  final bool isUploadingAvatar;
  final VoidCallback onAvatarTap;
  final VoidCallback onMembershipTap;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Tooltip(
                message: context.tr(
                  isUploadingAvatar
                      ? 'Uploading profile photo...'
                      : 'Upload profile photo',
                ),
                child: GestureDetector(
                  onTap: isUploadingAvatar ? null : onAvatarTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AppAvatar(
                        size: 88,
                        initials: profile.initials,
                        imageBytes: profile.avatarBytes,
                        imageUrl: profile.avatarUrl,
                        gender: profile.gender,
                        textScale: 0.32,
                      ),
                      if (isUploadingAvatar)
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.42),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Tooltip(
                  message: context.tr(
                    isUploadingAvatar
                        ? 'Uploading profile photo...'
                        : 'Upload profile photo',
                  ),
                  child: GestureDetector(
                    onTap: isUploadingAvatar ? null : onAvatarTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkCardColor
                              : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        AppIcons.camera,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.displayName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProfileBadge(
                  icon: AppIcons.shield_tick,
                  label: context.tr('Verified'),
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileBadge(
                  icon: AppIcons.star,
                  label: context.tr('Gold member'),
                  color: AppColors.warning,
                  isDark: isDark,
                  isActive: false,
                  onTap: onMembershipTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.isActive = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isActive
        ? color
        : (isDark ? Colors.white.withValues(alpha: 0.50) : Colors.black38);

    final badge = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: isDark ? 0.18 : 0.10)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? null
            : Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: effectiveColor, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: AppFontSizes.label,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return badge;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: badge,
      ),
    );
  }
}

class _ProfileInfoSection extends StatelessWidget {
  const _ProfileInfoSection({
    required this.title,
    required this.children,
    required this.isDark,
  });

  final String title;
  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            context.tr(title),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: AppFontSizes.subtitle,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
