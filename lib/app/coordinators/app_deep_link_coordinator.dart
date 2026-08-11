import 'package:flutter/widgets.dart';

import '../routing/app_navigator.dart';
import '../routing/app_route_arguments.dart';
import '../routing/app_route_observer.dart';
import '../routing/app_routes.dart';
import '../routing/shared_content_links.dart';

class AppDeepLinkCoordinator {
  AppDeepLinkCoordinator({required this.canOpen}) {
    routeObserver = AppRouteObserver(schedulePending);
  }

  final bool Function() canOpen;
  late final AppRouteObserver routeObserver;

  SharedContentDeepLink? _pendingDeepLink;
  bool _navigationScheduled = false;

  void handleUri(Uri uri) {
    final target = SharedContentDeepLink.tryParse(uri);
    if (target == null) return;
    _pendingDeepLink = target;
    schedulePending();
  }

  void schedulePending() {
    if (_navigationScheduled || _pendingDeepLink == null) return;
    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;
      _openPending();
    });
  }

  void _openPending() {
    if (_pendingDeepLink == null || !canOpen()) return;
    final currentRoute = routeObserver.currentRouteName;
    if (currentRoute == null || _startupRoutes.contains(currentRoute)) return;
    final navigator = AppNavigator.key.currentState;
    if (navigator == null) return;

    final target = _pendingDeepLink!;
    _pendingDeepLink = null;
    switch (target.type) {
      case SharedContentType.product:
        navigator.pushNamed(
          AppRoutes.productDetail,
          arguments: ProductDetailRouteArgs(
            image: '',
            title: '',
            brand: '',
            price: '',
            productId: target.id,
          ),
        );
        break;
      case SharedContentType.offer:
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.navigationMenu,
          (route) => false,
          arguments: NavigationMenuRouteArgs(
            initialIndex: 0,
            focusOfferId: target.id,
          ),
        );
        break;
      case SharedContentType.market:
        navigator.pushNamed(
          AppRoutes.brandProducts,
          arguments: BrandProductsRouteArgs(
            brand: 'Store',
            logo: '',
            productCount: '',
            marketId: target.id,
          ),
        );
        break;
    }
  }

  static const _startupRoutes = <String>{
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.signup,
    AppRoutes.forgetPassword,
    AppRoutes.resetPassword,
    AppRoutes.passwordResetSent,
    AppRoutes.verifyEmail,
    AppRoutes.successAccount,
    AppRoutes.selectCity,
    AppRoutes.accountDisabled,
  };
}
