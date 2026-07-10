import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/localization/app_language_controller.dart';
import 'core/localization/app_translations.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/preferences/app_preferences_controller.dart';
import 'core/presentation/widgets/offline_connection_banner.dart';
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

class _AppCoordinator extends StatefulWidget {
  const _AppCoordinator();

  @override
  State<_AppCoordinator> createState() => _AppCoordinatorState();
}

class _AppCoordinatorState extends State<_AppCoordinator>
    with WidgetsBindingObserver {
  StreamSubscription<PushEvent>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pushSubscription = sl<PushNotificationService>().events.listen(
      _handlePushEvent,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthCubit>().state is AuthAccountDisabled) {
        _clearPrivateSessionState(context);
        AppNavigator.goToAccountDisabled();
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
    if (state == AppLifecycleState.resumed) {
      context.read<AuthCubit>().validateSession();
    }
  }

  Future<void> _handlePushEvent(PushEvent pushEvent) async {
    if (!mounted) return;
    final data = pushEvent.data;
    final event = data['event']?.toString() ?? '';
    if (event.isEmpty || event == 'account_disabled') return;

    final notifications = context.read<NotificationCubit>();
    final homeCubit = context.read<HomeCubit>();
    final orderHistoryCubit = context.read<OrderHistoryCubit>();
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
        _showForegroundBanner(data);
      }
    }
  }

  void _showForegroundBanner(Map<String, dynamic> data) {
    final currentContext = AppNavigator.key.currentContext;
    if (currentContext == null) return;
    final title = data['title']?.toString().trim() ?? '';
    final message = data['message']?.toString().trim() ?? '';
    final text = [title, message].where((value) => value.isNotEmpty).join('\n');
    if (text.isEmpty) return;
    ScaffoldMessenger.of(currentContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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
          AppNavigator.goToAccountDisabled();
        } else if (state is AuthInitial) {
          _clearPrivateSessionState(context);
          AppNavigator.goToLogin();
        } else if (state is AuthSessionExpired) {
          _clearPrivateSessionState(context);
          AppNavigator.goToLogin();
          _showSessionExpiredDialog(context);
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

  void _showSessionExpiredDialog(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dialogContext = AppNavigator.key.currentContext;
      if (dialogContext == null) return;
      showDialog<void>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(context.tr('Session expired')),
          content: Text(
            context.tr(
              'Sign in again to continue. Remember Me keeps you signed in after closing the app.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppNavigator.goToLogin();
              },
              child: Text(context.tr('Sign In')),
            ),
          ],
        ),
      );
    });
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
