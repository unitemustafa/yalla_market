import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/navigation/presentation/views/navigation_menu_view.dart';
import 'package:yalla_market/features/store/domain/entities/order_preview.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_state.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/order_history_state.dart';
import 'package:yalla_market/features/store/presentation/views/checkout_view.dart';
import 'package:yalla_market/features/store/presentation/views/orders/orders_view.dart';

import '../test/performance/stress_app.dart';
import '../test/performance/stress_fixtures.dart';
import 'core/scroll_probe.dart';

/// Compare the same scenarios and fixtures in an isolated Android profile app.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  testWidgets('customer screen rebuild profile', (tester) async {
    expect(kProfileMode, isTrue);
    expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
    final fixtures = StressFixtures(productCount: 300, listCount: 1000);
    final motion = <String, Object?>{};
    binding.reportData = {
      'completed': false,
      'data_source': 'synthetic_repositories_and_bundled_images',
      'scroll_motion': motion,
    };

    Future<void> mount(Widget page) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await configureStressApp(fixtures);
      await tester.pumpWidget(StressApp(home: page));
      await tester.pumpAndSettle();
    }

    Future<void> measure(String name, Future<void> Function() action) async {
      for (var run = 1; run <= 3; run++) {
        await binding.watchPerformance(action, reportKey: '${name}_$run');
      }
    }

    await measure('home_open', () => mount(const NavigationMenuView()));
    await measure('home_scroll', () async {
      motion['home_${motion.length + 1}'] = await scrollProbe(tester);
    });

    await mount(const OrdersView());
    final orders = tester
        .element(find.byType(OrdersView))
        .read<OrderHistoryCubit>();
    OrderHistoryReady paginationState({required bool loadingMore}) =>
        OrderHistoryReady(
          fixtures.orders,
          totalCount: fixtures.orders.length + 1,
          deliveredCount: 0,
          hasMore: true,
          loadingMore: loadingMore,
        );
    orders.emit(paginationState(loadingMore: false));
    await tester.pumpAndSettle();
    // Mount the footer so the optimized screen still produces frames when
    // pagination changes. A footer outside the viewport needs no rebuild.
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final footer = find.text('Load more');
    for (
      var attempt = 0;
      attempt < 12 && footer.evaluate().isEmpty;
      attempt++
    ) {
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    expect(footer, findsOneWidget);
    await measure('orders_pagination_status', () async {
      for (var change = 0; change < 20; change++) {
        orders.emit(paginationState(loadingMore: change.isEven));
        await tester.pump(const Duration(milliseconds: 16));
      }
    });

    await mount(const CheckoutView(useDemoRepositories: true));
    final checkoutContext = tester.element(find.byType(CheckoutView));
    checkoutContext.read<CartCubit>().emit(
      List.unmodifiable(
        fixtures.products.map(
          (product) => CartItemData(
            id: product.id,
            variantId: product.defaultVariantId,
            image: product.image,
            title: product.title,
            brand: product.brand,
            price: product.priceValue,
            quantity: 1,
          ),
        ),
      ),
    );
    final checkout = checkoutContext.read<CheckoutCubit>();
    final preview = OrderPreviewData.fromJson({
      'summary': {'subtotal': 6000, 'grand_total': 6000},
      'market_groups': [
        {
          'delivery_available': true,
          'selected_products': [
            for (final product in fixtures.products)
              {
                'variant_id': product.defaultVariantId,
                'product_name': product.title,
                'unit_price': product.priceValue,
              },
          ],
        },
      ],
    });
    checkout.emit(CheckoutInitial(preview: preview));
    await tester.pumpAndSettle();
    await measure('checkout_status', () async {
      for (var change = 0; change < 20; change++) {
        checkout.emit(
          change.isEven
              ? CheckoutLoading(preview: preview)
              : CheckoutInitial(preview: preview),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
    });

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    AuthGuard.clearAuthentication();
    await sl.reset();
    binding.reportData!['completed'] = true;
  });
}
