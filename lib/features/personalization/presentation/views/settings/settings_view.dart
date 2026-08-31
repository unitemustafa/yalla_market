import 'package:flutter/material.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../../app/routing/app_routes.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../controllers/user_profile_controller.dart';
import '../../widgets/settings_menu_tile.dart';
import '../../widgets/settings_page_widgets.dart';

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
              SettingsProfileTopBar(
                isDark: isDark,
                onSettingsTap: () {
                  Navigator.pushNamed(context, AppRoutes.appPreferences);
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<UserProfileController>(
                valueListenable: UserProfileController.instance,
                builder: (context, profile, _) {
                  return SettingsAccountHero(
                    isDark: isDark,
                    profile: profile,
                    onEdit: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  );
                },
              ),
              const SizedBox(height: 22),
              SettingsSection(
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
                  SettingsMenuTile(
                    icon: AppIcons.trash,
                    title: 'Delete Account',
                    subTitle:
                        'Permanently remove your profile and personal data',
                    accentColor: AppColors.error,
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SettingsLogoutButton(onPressed: () => _showLogoutDialog(context)),
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

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final parentContext = context;
    final passwordController = TextEditingController();
    final hasPassword = UserProfileController.instance.hasPassword;
    var obscurePassword = true;
    var isDeleting = false;
    String? errorMessage;

    try {
      final deleted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(
                  context.tr('Delete account permanently?'),
                  textAlign: TextAlign.center,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr(
                          hasPassword
                              ? 'This cannot be undone. Enter your account password to confirm permanent deletion.'
                              : 'This cannot be undone. You will be asked to confirm with your social account.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (hasPassword)
                        TextField(
                          key: const Key('delete-account-password'),
                          controller: passwordController,
                          enabled: !isDeleting,
                          obscureText: obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: context.tr('Password'),
                            errorText: errorMessage == null
                                ? null
                                : context.tr(errorMessage!),
                            suffixIcon: IconButton(
                              onPressed: isDeleting
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          onSubmitted: isDeleting
                              ? null
                              : (_) => _confirmAccountDeletion(
                                  parentContext: parentContext,
                                  dialogContext: dialogContext,
                                  passwordController: passwordController,
                                  setDialogState: setDialogState,
                                  setDeleting: (value) => isDeleting = value,
                                  setError: (value) => errorMessage = value,
                                  requiresPassword: hasPassword,
                                ),
                        ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isDeleting
                              ? null
                              : () => Navigator.pop(dialogContext, false),
                          child: Text(context.tr('Cancel')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isDeleting
                              ? null
                              : () => _confirmAccountDeletion(
                                  parentContext: parentContext,
                                  dialogContext: dialogContext,
                                  passwordController: passwordController,
                                  setDialogState: setDialogState,
                                  setDeleting: (value) => isDeleting = value,
                                  setError: (value) => errorMessage = value,
                                  requiresPassword: hasPassword,
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          child: isDeleting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(context.tr('Delete')),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );

      if (deleted != true || !parentContext.mounted) return;
      UserProfileController.instance.reset();
      Navigator.of(
        parentContext,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _confirmAccountDeletion({
    required BuildContext parentContext,
    required BuildContext dialogContext,
    required TextEditingController passwordController,
    required StateSetter setDialogState,
    required ValueChanged<bool> setDeleting,
    required ValueChanged<String?> setError,
    required bool requiresPassword,
  }) async {
    final password = passwordController.text;
    if (requiresPassword && password.isEmpty) {
      setDialogState(() => setError('Password is required.'));
      return;
    }

    setDialogState(() {
      setError(null);
      setDeleting(true);
    });
    final authCubit = parentContext.read<AuthCubit>();
    final deleted = await authCubit.deleteAccount(password);
    if (!dialogContext.mounted) return;
    if (deleted) {
      Navigator.pop(dialogContext, true);
      return;
    }

    final failure =
        authCubit.lastAccountDeletionError ?? 'Could not delete your account.';
    final localizedFailure = failure.toLowerCase().contains('active order')
        ? 'Finish or cancel any active orders first.'
        : failure;
    setDialogState(() {
      setDeleting(false);
      setError(localizedFailure);
    });
  }
}
