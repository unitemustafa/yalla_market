import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/connectivity/internet_status_controller.dart';
import '../../../../../core/presentation/widgets/images/app_avatar.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../controllers/user_profile_controller.dart';
import '../../widgets/settings_menu_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static const _whatsAppColor = Color(0xFF25D366);
  static const _whatsAppNumber = '201016487371';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'account-whatsapp',
        onPressed: () => _openWhatsApp(context),
        tooltip: context.tr('WhatsApp'),
        backgroundColor: _whatsAppColor,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: const FaIcon(FontAwesomeIcons.whatsapp, size: 29),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileTopBar(
                isDark: isDark,
                onSettingsTap: () {
                  Navigator.pushNamed(context, AppRoutes.appPreferences);
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<UserProfileController>(
                valueListenable: UserProfileController.instance,
                builder: (context, profile, _) {
                  return _AccountHero(
                    isDark: isDark,
                    profile: profile,
                    onEdit: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  );
                },
              ),
              const SizedBox(height: 22),
              _SettingsSection(
                title: 'Account Settings',
                isDark: isDark,
                children: [
                  SettingsMenuTile(
                    icon: AppIcons.shopping_cart,
                    title: 'My Cart',
                    subTitle: 'Add, remove products and move to checkout',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
                  ),
                  SettingsMenuTile(
                    icon: AppIcons.location,
                    title: 'My Addresses',
                    subTitle: 'Choose where orders should arrive',
                    accentColor: AppColors.success,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.addresses),
                  ),
                  SettingsMenuTile(
                    icon: AppIcons.receipt_text,
                    title: 'My Orders',
                    subTitle: 'In-progress and completed orders',
                    accentColor: AppColors.warning,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
                  ),
                  SettingsMenuTile(
                    icon: AppIcons.info_circle,
                    title: 'About the app',
                    subTitle: 'Learn more about Yalla Market',
                    accentColor: AppColors.primary,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.aboutApp),
                  ),
                  SettingsMenuTile(
                    icon: AppIcons.shop,
                    title: 'Register as a partner',
                    subTitle: 'Join Yalla Market as a store or service partner',
                    accentColor: AppColors.success,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.partnerApplication,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _LogoutButton(onPressed: () => _showLogoutDialog(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context, {String? message}) async {
    final uri = Uri.https(
      'wa.me',
      '/$_whatsAppNumber',
      message == null ? null : {'text': message},
    );

    try {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (didLaunch || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }

    CustomSnackBar.showError(
      context: context,
      title: 'Could not open WhatsApp',
      message: 'Please try again.',
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final parentContext = context;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(context.tr('Logout'), textAlign: TextAlign.center),
          content: Text(
            context.tr('Are you sure you want to logout?'),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('Cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await parentContext.read<AuthCubit>().logout();
                      UserProfileController.instance.reset();

                      if (!parentContext.mounted) return;
                      Navigator.of(parentContext).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      context.tr('Confirm'),
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
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.isDark, required this.onSettingsTap});

  final bool isDark;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Profile'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('Account, orders and preferences'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: context.tr('App preferences'),
          child: Material(
            color: isDark ? AppColors.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onSettingsTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: const Icon(AppIcons.setting_2, size: 21),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({
    required this.isDark,
    required this.profile,
    required this.onEdit,
  });

  final bool isDark;
  final UserProfileController profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: AppAvatar(
                size: 64,
                initials: profile.initials,
                imageBytes: profile.avatarBytes,
                imageUrl: profile.avatarUrl,
                gender: profile.gender,
                backgroundColor: Colors.white,
                borderColor: Colors.white.withValues(alpha: 0.7),
                borderWidth: 2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: AppFontSizes.subtitle,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(AppIcons.verify5, color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: SizedBox(
                        height: 34,
                        child: TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(AppIcons.edit, size: 16),
                          label: Text(
                            context.tr('Edit'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _ConnectionStatusBadge(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatusBadge extends StatelessWidget {
  const _ConnectionStatusBadge();

  @override
  Widget build(BuildContext context) {
    final statusController = InternetStatusScope.maybeOf(context);

    if (statusController == null) {
      return _ConnectionStatusBadgeContent(
        label: context.tr('Online'),
        isOffline: false,
      );
    }

    return AnimatedBuilder(
      animation: statusController,
      builder: (context, _) {
        final isOffline = statusController.isOffline;

        return _ConnectionStatusBadgeContent(
          label: context.tr(isOffline ? 'Offline' : 'Online'),
          isOffline: isOffline,
        );
      },
    );
  }
}

class _ConnectionStatusBadgeContent extends StatelessWidget {
  const _ConnectionStatusBadgeContent({
    required this.label,
    required this.isOffline,
  });

  final String label;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isOffline
            ? AppColors.error.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSizes.label,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
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
        Text(
          context.tr(title),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.w900,
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(AppIcons.logout, size: 19),
        label: Text(context.tr('Logout')),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
