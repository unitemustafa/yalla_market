import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/localization/app_translations.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/cubit/notification_cubit.dart';
import '../../features/offers/presentation/cubit/offer_catalog_cubit.dart';
import '../../features/personalization/presentation/cubit/address_cubit.dart';
import '../../features/store/presentation/cubit/order_history_cubit.dart';
import '../../features/store/presentation/cubit/product_catalog_cubit.dart';
import '../../features/store/presentation/cubit/product_discovery_cubit.dart';
import '../../features/store/presentation/cubit/store_cubit.dart';
import '../routing/app_navigator.dart';
import '../routing/app_route_arguments.dart';
import '../routing/app_routes.dart';

@visibleForTesting
Future<bool> presentDeliveryAreaCreatedFeedback({
  required PushEvent pushEvent,
  required Future<void> Function(Map<String, dynamic> data) showBanner,
}) async {
  if (pushEvent.opened ||
      pushEvent.data['event']?.toString() != 'delivery_area_created') {
    return false;
  }
  await showBanner(pushEvent.data);
  return true;
}

class AppPushEventCoordinator {
  const AppPushEventCoordinator({
    required this.context,
    required this.isMounted,
    required this.showForegroundBanner,
  });

  final BuildContext Function() context;
  final bool Function() isMounted;
  final Future<void> Function(Map<String, dynamic> data) showForegroundBanner;

  Future<void> handle(PushEvent pushEvent) async {
    if (!isMounted()) return;
    final data = pushEvent.data;
    final event = data['event']?.toString() ?? '';
    if (event.isEmpty || event == 'account_disabled') return;

    if (event == 'account_restored') {
      if (pushEvent.opened) AppNavigator.goToLogin();
      return;
    }

    if (event == 'delivery_area_status_changed') {
      await context().read<AddressCubit>().loadAddresses();
      return;
    }

    final notifications = context().read<NotificationCubit>();
    final homeCubit = context().read<HomeCubit>();
    final offerCatalogCubit = context().read<OfferCatalogCubit>();
    final orderHistoryCubit = context().read<OrderHistoryCubit>();
    final productCatalogCubit = context().read<ProductCatalogCubit>();
    final productDiscoveryCubit = context().read<ProductDiscoveryCubit>();
    final storeCubit = context().read<StoreCubit>();
    await notifications.refreshUnreadCount();
    if (notifications.state.hasLoaded) {
      await notifications.refreshNotifications();
    }

    if (event == 'partner_application_approved') {
      if (pushEvent.opened) {
        AppNavigator.key.currentState?.pushNamed(AppRoutes.notifications);
      } else {
        await showForegroundBanner(data);
      }
      return;
    }

    if (event == 'delivery_area_created') {
      await presentDeliveryAreaCreatedFeedback(
        pushEvent: pushEvent,
        showBanner: showForegroundBanner,
      );
      return;
    }

    if (event == 'offer_created') {
      await Future.wait([
        homeCubit.loadHome(force: true),
        offerCatalogCubit.loadOffers(force: true),
      ]);
      if (!isMounted()) return;
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
        await showForegroundBanner(data);
      }
      return;
    }

    if (event == 'market_created') {
      await Future.wait([
        homeCubit.loadHome(force: true),
        storeCubit.loadStore(force: true),
        productCatalogCubit.loadProducts(force: true),
        productDiscoveryCubit.loadDiscovery(force: true),
      ]);
      if (!isMounted()) return;
      if (pushEvent.opened) {
        final marketId = data['market_id']?.toString().trim() ?? '';
        if (marketId.isNotEmpty) {
          AppNavigator.key.currentState?.pushNamed(
            AppRoutes.brandProducts,
            arguments: BrandProductsRouteArgs(
              brand:
                  data['market_name']?.toString().trim() ??
                  context().tr('Market'),
              logo: data['image']?.toString().trim() ?? '',
              productCount: '',
              marketId: marketId,
              shopId: marketId,
              classificationId: data['classification_id']?.toString(),
            ),
          );
        }
      } else {
        await showForegroundBanner(data);
      }
      return;
    }

    if (event == 'product_created') {
      await Future.wait([
        homeCubit.loadHome(force: true),
        productCatalogCubit.loadProducts(force: true),
        productDiscoveryCubit.loadDiscovery(force: true),
      ]);
      if (!isMounted()) return;
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
        await showForegroundBanner(data);
      }
      return;
    }

    if (_orderEvents.contains(event)) {
      await orderHistoryCubit.loadOrders(force: true);
      if (!isMounted()) return;
      if (pushEvent.opened) {
        final orderId = int.tryParse(data['order_id']?.toString() ?? '');
        if (orderId != null) {
          AppNavigator.key.currentState?.pushNamed(
            AppRoutes.orders,
            arguments: OrderFocusRouteArgs(orderId: orderId),
          );
        }
      } else {
        await showForegroundBanner(data);
      }
    }
  }
}

const _orderEvents = {
  'order_created',
  'order_review_approved',
  'order_review_rejected',
  'order_status_changed',
  'order_cancelled',
  'order_failed_delivery',
  'delivery_quote_sent',
};
