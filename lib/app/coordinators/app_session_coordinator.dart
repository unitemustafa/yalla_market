import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/notifications/push_notification_service.dart';
import '../../core/preferences/app_preferences_controller.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/cubit/notification_cubit.dart';
import '../../features/location/presentation/cubit/location_cubit.dart';
import '../../features/offers/presentation/cubit/offer_catalog_cubit.dart';
import '../../features/personalization/presentation/controllers/user_profile_controller.dart';
import '../../features/personalization/presentation/cubit/address_cubit.dart';
import '../../features/store/presentation/cubit/checkout_cubit.dart';
import '../../features/store/presentation/cubit/order_history_cubit.dart';
import '../../features/store/presentation/cubit/product_catalog_cubit.dart';
import '../../features/store/presentation/cubit/product_discovery_cubit.dart';
import '../../features/store/presentation/cubit/store_cubit.dart';
import '../../features/wishlist/presentation/cubit/market_wishlist_cubit.dart';
import '../../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import '../di/service_locator.dart';
import '../routing/app_navigator.dart';

class AppSessionCoordinator {
  void handleAuthState(
    BuildContext context,
    AuthState state, {
    required VoidCallback schedulePendingDeepLink,
    required VoidCallback showAccountDisabledDialog,
    required VoidCallback showSessionExpiredDialog,
  }) {
    if (state is AuthAuthenticated) {
      _activateSession(context, state, schedulePendingDeepLink);
    } else if (state is AuthAccountDisabled) {
      clearPrivateState(context);
      AppNavigator.goToLogin();
      showAccountDisabledDialog();
    } else if (state is AuthInitial) {
      clearPrivateState(context);
      AppNavigator.goToLogin();
    } else if (state is AuthSessionExpired) {
      clearPrivateState(context);
      AppNavigator.goToLogin();
      showSessionExpiredDialog();
    }
  }

  void _activateSession(
    BuildContext context,
    AuthAuthenticated state,
    VoidCallback schedulePendingDeepLink,
  ) {
    UserProfileController.instance.updateFromAuthUser(state.session.user);
    context.read<NotificationCubit>().refreshUnreadCount();
    final pushService = sl<PushNotificationService>();
    unawaited(
      AppPreferencesController.instance.mobileNotificationsEnabled
          ? pushService.registerAuthenticatedDevice()
          : pushService.unregisterCurrentDevice(),
    );
    final userKey = userSessionStorageKey(
      id: state.session.user.id,
      email: state.session.user.email,
    );
    if (userKey == null) {
      context.read<WishlistCubit>().clearSession();
      context.read<MarketWishlistCubit>().clearSession();
      context.read<CartCubit>().clearSession();
    } else {
      context.read<WishlistCubit>().loadWishlistForUser(userKey);
      context.read<MarketWishlistCubit>().loadForUser(userKey);
      context.read<CartCubit>().loadCartForUser(userKey);
    }
    schedulePendingDeepLink();
  }

  void clearPrivateState(BuildContext context) {
    UserProfileController.instance.reset();
    context.read<LocationCubit>().clearSession();
    context.read<WishlistCubit>().clearSession();
    context.read<MarketWishlistCubit>().clearSession();
    context.read<CartCubit>().clearSession();
    context.read<AddressCubit>().clearSession();
    context.read<CheckoutCubit>().reset();
    context.read<OrderHistoryCubit>().clearSession();
    context.read<NotificationCubit>().clear();
    context.read<HomeCubit>().clearSession();
    context.read<OfferCatalogCubit>().clearSession();
    context.read<ProductCatalogCubit>().clearSession();
    context.read<ProductDiscoveryCubit>().clearSession();
    context.read<StoreCubit>().clearSession();
  }
}

String? userSessionStorageKey({required String id, required String email}) {
  if (id.trim().isNotEmpty) return id.trim();
  if (email.trim().isNotEmpty) return email.trim();
  return null;
}
