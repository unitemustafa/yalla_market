import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/localization/app_language_controller.dart';
import 'core/localization/app_translations.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/preferences/app_preferences_controller.dart';
import 'core/presentation/widgets/offline_connection_banner.dart';
import 'core/presentation/widgets/snackbars/custom_snackbar.dart';
import 'core/routing/app_navigator.dart';
import 'core/routing/app_route_arguments.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/home/presentation/cubit/notification_cubit.dart';
import 'features/location/presentation/cubit/location_cubit.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/personalization/presentation/controllers/user_profile_controller.dart';
import 'features/personalization/presentation/cubit/address_cubit.dart';
import 'features/personalization/presentation/cubit/profile_image_cubit.dart';
import 'features/splash/presentation/cubit/splash_cubit.dart';
import 'features/store/presentation/cubit/checkout_cubit.dart';
import 'features/store/presentation/cubit/order_history_cubit.dart';
import 'features/store/presentation/cubit/product_catalog_cubit.dart';
import 'features/store/presentation/cubit/product_discovery_cubit.dart';
import 'features/store/presentation/cubit/store_cubit.dart';
import 'features/wishlist/presentation/cubit/wishlist_cubit.dart';

class YallaMarketApp extends StatelessWidget {
  const YallaMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()),
        BlocProvider(create: (_) => sl<OnboardingCubit>()),
        BlocProvider(create: (_) => sl<LocationCubit>()),
        BlocProvider(create: (_) => sl<SplashCubit>()),
        BlocProvider(create: (_) => sl<HomeCubit>()),
        BlocProvider(create: (_) => sl<NotificationCubit>()),
        BlocProvider(create: (_) => sl<ProductCatalogCubit>()),
        BlocProvider(create: (_) => sl<ProductDiscoveryCubit>()),
        BlocProvider(create: (_) => sl<StoreCubit>()),
        BlocProvider(create: (_) => sl<CheckoutCubit>()),
        BlocProvider(create: (_) => sl<OrderHistoryCubit>()),
        BlocProvider(create: (_) => sl<CartCubit>()),
        BlocProvider(create: (_) => sl<WishlistCubit>()),
        BlocProvider(create: (_) => sl<AddressCubit>()),
        BlocProvider(create: (_) => sl<ProfileImageCubit>()),
      ],
      child: const _AppCoordinator(),
    );
  }
}

class ResumeRefreshGuard {
  bool _inFlight = false;

  Future<void> run({
    required Future<bool> Function() validateSession,
    required Future<void> Function() refreshHome,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      if (await validateSession()) {
        await refreshHome();
      }
    } finally {
      _inFlight = false;
    }
  }
}

class _AppCoordinator extends StatefulWidget {
  const _AppCoordinator();

  @override
  State<_AppCoordinator> createState() => _AppCoordinatorState();
}

class _AppCoordinatorState extends State<_AppCoordinator>
    with WidgetsBindingObserver {
  StreamSubscription<PushEvent>? _pushSubscription;
  bool _wasBackgrounded = false;
  final ResumeRefreshGuard _resumeRefreshGuard = ResumeRefreshGuard();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final pushNotificationService = sl<PushNotificationService>();
    _pushSubscription = pushNotificationService.events.listen(_handlePushEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final event
          in pushNotificationService.takePendingInitialOpenedEvents()) {
        unawaited(_handlePushEvent(event));
      }
      if (mounted && context.read<AuthCubit>().state is AuthAccountDisabled) {
        _clearPrivateSessionState(context);
        AppNavigator.goToLogin();
        _showAccountDisabledDialog();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pushSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      unawaited(_refreshAfterResume());
    }
  }

  Future<void> _refreshAfterResume() async {
    if (!mounted) return;
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is! AuthAuthenticated) return;
    try {
      await _resumeRefreshGuard.run(
        validateSession: () async {
          final sessionIsValid = await authCubit.validateSession();
          return mounted &&
              sessionIsValid &&
              authCubit.state is AuthAuthenticated;
        },
        refreshHome: () => context.read<HomeCubit>().loadHome(force: true),
      );
    } catch (_) {
      // A background refresh failure must not invalidate an otherwise valid session.
    }
  }

  Future<void> _handlePushEvent(PushEvent pushEvent) async {
    if (!mounted) return;
    final data = pushEvent.data;
    final event = data['event']?.toString() ?? '';
    if (event.isEmpty || event == 'account_disabled') return;

    if (event == 'account_restored') {
      if (pushEvent.opened) {
        AppNavigator.goToLogin();
      }
      return;
    }

    if (event == 'delivery_area_status_changed') {
      await context.read<AddressCubit>().loadAddresses();
      return;
    }

    final notifications = context.read<NotificationCubit>();
    final homeCubit = context.read<HomeCubit>();
    final orderHistoryCubit = context.read<OrderHistoryCubit>();
    final productCatalogCubit = context.read<ProductCatalogCubit>();
    final productDiscoveryCubit = context.read<ProductDiscoveryCubit>();
    await notifications.refreshUnreadCount();
    if (notifications.state.hasLoaded) {
      await notifications.refreshNotifications();
    }

    if (event == 'offer_created') {
      await homeCubit.loadHome(force: true);
      if (!mounted) return;
      if (pushEvent.opened) {
        final offerId = data['offer_id']?.toString();
        AppNavigator.key.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.navigationMenu,
          (route) => false,
          arguments: NavigationMenuRouteArgs(
            initialIndex: 0,
            focusOfferId: offerId,
          ),
        );
      } else {
        await _showForegroundBanner(data);
      }
      return;
    }

    if (event == 'product_created') {
      await Future.wait([
        homeCubit.loadHome(force: true),
        productCatalogCubit.loadProducts(force: true),
        productDiscoveryCubit.loadDiscovery(force: true),
      ]);
      if (!mounted) return;
      if (pushEvent.opened) {
        final productId = data['product_id']?.toString().trim() ?? '';
        if (productId.isNotEmpty) {
          AppNavigator.key.currentState?.pushNamed(
            AppRoutes.productDetail,
            arguments: ProductDetailRouteArgs.fromNotificationData(
              data,
              productId: productId,
            ),
          );
        }
      } else {
        _showForegroundBanner(data);
      }
      return;
    }

    if (_orderEvents.contains(event)) {
      await orderHistoryCubit.loadOrders(force: true);
      if (!mounted) return;
      if (pushEvent.opened) {
        final orderId = int.tryParse(data['order_id']?.toString() ?? '');
        if (orderId != null) {
          AppNavigator.key.currentState?.pushNamed(
            AppRoutes.orders,
            arguments: OrderFocusRouteArgs(orderId: orderId),
          );
        }
      } else {
        await _showForegroundBanner(data);
      }
    }
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
      // Haptic feedback is optional and must not block the notification UI.
    }
  }

  void _clearPrivateSessionState(BuildContext context) {
    UserProfileController.instance.reset();
    context.read<LocationCubit>().clearSession();
    context.read<WishlistCubit>().clearSession();
    context.read<CartCubit>().clearSession();
    context.read<CheckoutCubit>().reset();
    context.read<OrderHistoryCubit>().clearSession();
    context.read<NotificationCubit>().clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          UserProfileController.instance.updateFromAuthUser(state.session.user);
          context.read<NotificationCubit>().refreshUnreadCount();
          sl<PushNotificationService>().registerAuthenticatedDevice();
          final userKey = _wishlistUserKey(
            id: state.session.user.id,
            email: state.session.user.email,
          );
          if (userKey == null) {
            context.read<WishlistCubit>().clearSession();
            context.read<CartCubit>().clearSession();
          } else {
            context.read<WishlistCubit>().loadWishlistForUser(userKey);
            context.read<CartCubit>().loadCartForUser(userKey);
          }
        } else if (state is AuthAccountDisabled) {
          _clearPrivateSessionState(context);
          AppNavigator.goToLogin();
          _showAccountDisabledDialog();
        } else if (state is AuthInitial) {
          _clearPrivateSessionState(context);
          AppNavigator.goToLogin();
        } else if (state is AuthSessionExpired) {
          _clearPrivateSessionState(context);
          AppNavigator.goToLogin();
          _showSessionExpiredDialog();
        }
      },
      child: ValueListenableBuilder<AppLanguage>(
        valueListenable: AppLanguageController.instance,
        builder: (context, language, _) {
          return ValueListenableBuilder<AppPreferences>(
            valueListenable: AppPreferencesController.instance,
            builder: (context, preferences, _) {
              return MaterialApp(
                navigatorKey: AppNavigator.key,
                scaffoldMessengerKey: AppNavigator.scaffoldMessengerKey,
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
                      'No internet connection. Check your network to continue updates.',
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

  String? _wishlistUserKey({required String id, required String email}) {
    if (id.trim().isNotEmpty) return id.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return null;
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
        builder: (context) => _AuthNoticeDialog(
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

class _AuthNoticeDialog extends StatelessWidget {
  const _AuthNoticeDialog({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.showCloseButton,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white70 : Colors.black54);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: colorScheme.primary,
                  size: 29,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: showCloseButton ? 2 : 1,
                    child: SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  if (showCloseButton) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 96,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          context.tr('Cancel'),
                          maxLines: 1,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _orderEvents = {
  'order_created',
  'order_review_approved',
  'order_review_rejected',
  'order_status_changed',
  'order_cancelled',
  'order_failed_delivery',
};
