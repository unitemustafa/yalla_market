import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/localization/app_language_controller.dart';
import 'core/localization/app_translations.dart';
import 'core/preferences/app_preferences_controller.dart';
import 'core/presentation/widgets/offline_connection_banner.dart';
import 'core/routing/app_navigator.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/location/presentation/cubit/location_cubit.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/personalization/presentation/controllers/user_profile_controller.dart';
import 'features/personalization/presentation/cubit/address_cubit.dart';
import 'features/personalization/presentation/cubit/profile_image_cubit.dart';
import 'features/store/presentation/cubit/checkout_cubit.dart';
import 'features/store/presentation/cubit/order_history_cubit.dart';
import 'features/store/presentation/cubit/product_catalog_cubit.dart';
import 'features/store/presentation/cubit/product_discovery_cubit.dart';
import 'features/store/presentation/cubit/store_cubit.dart';
import 'features/wishlist/presentation/cubit/wishlist_cubit.dart';

import 'features/splash/presentation/cubit/splash_cubit.dart';

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
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            UserProfileController.instance.updateFromAuthUser(
              state.session.user,
            );
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
          } else if (state is AuthInitial) {
            UserProfileController.instance.reset();
            context.read<LocationCubit>().clearSession();
            context.read<WishlistCubit>().clearSession();
            context.read<CartCubit>().clearSession();
            context.read<OrderHistoryCubit>().clearSession();
            AppNavigator.goToLogin();
          } else if (state is AuthSessionExpired) {
            UserProfileController.instance.reset();
            context.read<LocationCubit>().clearSession();
            context.read<WishlistCubit>().clearSession();
            context.read<CartCubit>().clearSession();
            context.read<OrderHistoryCubit>().clearSession();
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
                  builder: (context, child) {
                    return Directionality(
                      textDirection: language.isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: OfflineConnectionBanner(
                        message: language.isArabic
                            ? 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة لإكمال التحديثات.'
                            : 'No internet connection. Check your network to continue updates.',
                        child: child ?? const SizedBox.shrink(),
                      ),
                    );
                  },
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
      ),
    );
  }

  String? _wishlistUserKey({required String id, required String email}) {
    final trimmedId = id.trim();
    if (trimmedId.isNotEmpty) return trimmedId;

    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty) return trimmedEmail;

    return null;
  }

  void _showSessionExpiredDialog(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigatorContext = AppNavigator.key.currentContext;
      if (navigatorContext == null) return;

      showDialog<void>(
        context: navigatorContext,
        barrierDismissible: false,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final isDark = theme.brightness == Brightness.dark;
          final surfaceColor = isDark ? const Color(0xFF242426) : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black87;
          final mutedColor = isDark
              ? Colors.white.withValues(alpha: 0.66)
              : Colors.black.withValues(alpha: 0.58);

          return AlertDialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            icon: const Icon(
              Icons.lock_clock_rounded,
              color: Color(0xFF4F60F6),
              size: 34,
            ),
            title: Text(
              dialogContext.tr('Session expired'),
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
            ),
            content: Text(
              dialogContext.tr(
                'Sign in again to continue. Remember Me keeps you signed in for 30 days after closing the app. Without it, your session lasts up to 8 hours and ends when the app closes.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    AppNavigator.goToLogin();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F60F6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(dialogContext.tr('Sign In')),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}
