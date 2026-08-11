import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/app_language_controller.dart';
import '../core/localization/app_translations.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/preferences/app_preferences_controller.dart';
import '../core/presentation/widgets/offline_connection_banner.dart';
import '../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/location/presentation/cubit/location_cubit.dart';
import 'coordinators/app_deep_link_coordinator.dart';
import 'coordinators/app_lifecycle_coordinator.dart';
import 'coordinators/app_push_event_coordinator.dart';
import 'coordinators/app_session_coordinator.dart';
import 'di/service_locator.dart';
import 'routing/app_navigator.dart';
import 'routing/app_router.dart';
import 'routing/app_routes.dart';
import 'widgets/auth_notice_dialog.dart';

class AppCoordinator extends StatefulWidget {
  const AppCoordinator({super.key});

  @override
  State<AppCoordinator> createState() => _AppCoordinatorState();
}

class _AppCoordinatorState extends State<AppCoordinator>
    with WidgetsBindingObserver {
  StreamSubscription<PushEvent>? _pushSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  late bool _mobileNotificationsEnabled;
  final AppLifecycleCoordinator _lifecycle = AppLifecycleCoordinator();
  final AppSessionCoordinator _session = AppSessionCoordinator();
  late final AppDeepLinkCoordinator _deepLinks = AppDeepLinkCoordinator(
    canOpen: () =>
        mounted &&
        context.read<AuthCubit>().state is AuthAuthenticated &&
        context.read<LocationCubit>().state.selectedCity != null,
  );
  late final AppPushEventCoordinator _pushEvents = AppPushEventCoordinator(
    context: () => context,
    isMounted: () => mounted,
    showForegroundBanner: _showForegroundBanner,
  );

  @override
  void initState() {
    super.initState();
    _mobileNotificationsEnabled =
        AppPreferencesController.instance.mobileNotificationsEnabled;
    AppPreferencesController.instance.addListener(
      _handleNotificationPreferenceChanged,
    );
    WidgetsBinding.instance.addObserver(this);
    final pushNotificationService = sl<PushNotificationService>();
    _pushSubscription = pushNotificationService.events.listen(
      _pushEvents.handle,
    );
    _deepLinkSubscription = AppLinks().uriLinkStream.listen(
      _deepLinks.handleUri,
      onError: (_) {},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final event
          in pushNotificationService.takePendingInitialOpenedEvents()) {
        unawaited(_pushEvents.handle(event));
      }
      if (mounted && context.read<AuthCubit>().state is AuthAccountDisabled) {
        _session.clearPrivateState(context);
        AppNavigator.goToLogin();
        _showAccountDisabledDialog();
      }
    });
  }

  @override
  void dispose() {
    AppPreferencesController.instance.removeListener(
      _handleNotificationPreferenceChanged,
    );
    WidgetsBinding.instance.removeObserver(this);
    _pushSubscription?.cancel();
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  void _handleNotificationPreferenceChanged() {
    final enabled =
        AppPreferencesController.instance.mobileNotificationsEnabled;
    if (enabled == _mobileNotificationsEnabled) return;
    _mobileNotificationsEnabled = enabled;
    if (context.read<AuthCubit>().state is! AuthAuthenticated) return;

    final service = sl<PushNotificationService>();
    unawaited(
      enabled
          ? service.registerAuthenticatedDevice()
          : service.unregisterCurrentDevice(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle.handleState(state, context: context, isMounted: () => mounted);
  }

  Future<void> _showForegroundBanner(Map<String, dynamic> data) async {
    final title = data['title']?.toString().trim() ?? '';
    final message = data['message']?.toString().trim() ?? '';
    if (title.isEmpty && message.isEmpty) return;
    final currentContext = AppNavigator.key.currentContext;
    final messenger = AppNavigator.scaffoldMessengerKey.currentState;
    if (currentContext == null || messenger == null) return;
    CustomSnackBar.showNotification(
      context: currentContext,
      messenger: messenger,
      title: title.isEmpty ? 'Notifications' : title,
      message: message.isEmpty ? null : message,
    );
    try {
      await HapticFeedback.vibrate();
    } catch (_) {
      // Haptic feedback is optional and must not block notification UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) => _session.handleAuthState(
        context,
        state,
        schedulePendingDeepLink: _deepLinks.schedulePending,
        showAccountDisabledDialog: _showAccountDisabledDialog,
        showSessionExpiredDialog: _showSessionExpiredDialog,
      ),
      child: ValueListenableBuilder<AppLanguage>(
        valueListenable: AppLanguageController.instance,
        builder: (context, language, _) {
          return ValueListenableBuilder<AppPreferences>(
            valueListenable: AppPreferencesController.instance,
            builder: (context, preferences, _) {
              return MaterialApp(
                navigatorKey: AppNavigator.key,
                scaffoldMessengerKey: AppNavigator.scaffoldMessengerKey,
                navigatorObservers: [_deepLinks.routeObserver],
                debugShowCheckedModeBanner: false,
                title: AppConstants.appName,
                onGenerateTitle: (context) =>
                    AppTranslations.of(context).appName,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: preferences.themeMode,
                locale: language.locale,
                supportedLocales: AppTranslations.supportedLocales,
                builder: (context, child) => Directionality(
                  textDirection: language.isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: OfflineConnectionBanner(
                    message: context.tr(
                      'You are offline. Showing saved content; checkout and updates need internet.',
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                initialRoute: AppRoutes.splash,
                onGenerateRoute: AppRouter.generateRoute,
              );
            },
          );
        },
      ),
    );
  }

  void _showSessionExpiredDialog() {
    _showAuthNoticeDialog(
      title: 'Session expired',
      message:
          'Sign in again to continue. Remember Me keeps you signed in after closing the app.',
    );
  }

  void _showAccountDisabledDialog() {
    _showAuthNoticeDialog(
      title: 'Account disabled',
      message: 'Contact support for assistance.',
      actionLabel: 'Technical Support',
      showCloseButton: true,
      onAction: () {
        unawaited(
          launchUrl(
            Uri.parse('https://wa.me/201016487371'),
            mode: LaunchMode.externalApplication,
          ),
        );
      },
    );
  }

  void _showAuthNoticeDialog({
    required String title,
    required String message,
    String actionLabel = 'Sign In',
    bool showCloseButton = false,
    VoidCallback? onAction,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dialogContext = AppNavigator.key.currentContext;
      if (dialogContext == null) return;
      showDialog<void>(
        context: dialogContext,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (context) => AuthNoticeDialog(
          title: context.tr(title),
          message: context.tr(message),
          actionLabel: context.tr(actionLabel),
          showCloseButton: showCloseButton,
          onAction:
              onAction ??
              () {
                Navigator.of(context).pop();
                AppNavigator.goToLogin();
              },
        ),
      );
    });
  }
}
