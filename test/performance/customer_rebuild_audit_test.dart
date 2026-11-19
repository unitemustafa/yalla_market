import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/repositories/product_repository.dart';
import 'package:yalla_market/features/store/presentation/views/orders/widgets/order_list_item.dart';
import 'package:yalla_market/features/store/presentation/views/product_detail_view.dart';

import 'customer_audit_scenarios.dart';
import 'stress_app.dart';
import 'stress_fixtures.dart';
import 'stress_repositories.dart';

const _tracked = {
  'NavigationMenuView',
  'HomeView',
  'HomeCatalogSections',
  '_HomeStoreHighlights',
  'StoreHighlightsSections',
  'HomeProductsSlider',
  'StoreView',
  'AppSearchActionButton',
  'CartCounterIcon',
  'SearchView',
  '_SearchInput',
  '_FilterBar',
  '_SearchSummary',
  'BrandProductsView',
  'MarketStorefrontHero',
  'StoreSubcategoryRail',
  'StoreProductsSliver',
  'StoreProductsFooter',
  'MarketListingSliver',
  'ProductCardsSliver',
  'StoreMarketCard',
  'ProductDetailView',
  '_ProductGallery',
  '_BottomAddToCartBar',
  'ProductCardVertical',
  'CartView',
  'CartItemCard',
  'CheckoutSummary',
  'WishlistView',
  '_WishlistTopBar',
  'OrdersView',
  'OrderListItem',
  '_OrdersPaginationFooter',
  'CheckoutView',
  '_ReviewItemsSection',
  '_CheckoutItemCard',
  'AppImage',
  'AppImageSkeleton',
};

void main() {
  for (final large in [false, true]) {
    testWidgets('customer rebuild audit (${large ? 'large' : 'standard'})', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final report = <String, Object?>{};
      Future<void> measure(
        String name,
        AuditAction action, {
        AuditAction? prepare,
      }) async {
        await prepare?.call(0);
        if (name == 'cart_increment_first_row') {
          expect(
            find.byType(CartItemCard),
            findsAtLeastNWidgets(2),
            reason: 'The fixture must keep several cart rows mounted.',
          );
        }
        if (name == 'wishlist_toggle_market') {
          expect(
            find.byKey(const ValueKey('wishlist_products_grid')),
            findsOneWidget,
            reason: 'Product favorites must be mounted for the wishlist audit.',
          );
        }
        if (name == 'wishlist_toggle_product') {
          final verticalScroll = find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first;
          expect(
            verticalScroll,
            findsOneWidget,
            reason: 'The wishlist must expose its vertical content scroller.',
          );
          final position = tester
              .state<ScrollableState>(verticalScroll)
              .position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('wishlist_store_2')),
            findsAtLeastNWidgets(1),
            reason: 'Store favorites must be mounted for the wishlist audit.',
          );
        }
        final seen = tester.allElements.toSet();
        final counts = <String, List<int>>{};
        final previous = debugOnRebuildDirtyWidget;
        var first = 0;
        var repeat = 0;
        debugOnRebuildDirtyWidget = (element, builtOnce) {
          previous?.call(element, builtOnce);
          // Flutter only updates builtOnce when rebuild printing is enabled.
          // Use element identity so output stays quiet and remounts stay distinct.
          final rebuilding = !seen.add(element);
          if (rebuilding) {
            repeat++;
          } else {
            first++;
          }
          final widget = element.widget;
          final type = widget.runtimeType.toString().split('<').first;
          if (!_tracked.contains(type)) return;
          final id = switch (widget) {
            CartItemCard(:final item) => item.id,
            ProductCardVertical(:final productId) => productId,
            OrderListItem(:final orderId) => orderId,
            _ =>
              widget.key is ValueKey
                  ? (widget.key! as ValueKey).value.toString()
                  : null,
          };
          final key = id == null ? type : '$type#$id';
          counts.putIfAbsent(key, () => [0, 0])[rebuilding ? 1 : 0]++;
        };
        try {
          await action(0);
        } finally {
          debugOnRebuildDirtyWidget = previous;
        }
        report[name] = {'first': first, 'repeat': repeat, 'by_widget': counts};
      }

      await CustomerAuditScenarios(tester, measure, large: large).run();
      if (!large) await _auditVariant(tester, measure);
      _expectRebuildIsolation(report);
      // Machine-readable markers, one JSON record per fixture size.
      debugPrintSynchronously(
        'REBUILD_AUDIT ${jsonEncode({'large': large, 'scenarios': report})}',
      );
    });
  }
}

void _expectRebuildIsolation(Map<String, Object?> report) {
  Map<String, List<int>> rebuilds(String scenario) {
    final scenarioReport = report[scenario]! as Map<String, Object?>;
    final raw = scenarioReport['by_widget']! as Map<String, List<int>>;
    return raw;
  }

  final cart = rebuilds('cart_increment_first_row');
  final cartRows = <String, int>{
    for (final entry in cart.entries)
      if (entry.key.startsWith('CartItemCard#')) entry.key: entry.value[1],
  };
  expect(
    cartRows['CartItemCard#1'],
    greaterThan(0),
    reason: 'The incremented cart row must redraw its new quantity.',
  );
  expect(
    cartRows.keys.where((key) => key != 'CartItemCard#1'),
    isEmpty,
    reason: 'Unchanged cart rows must not rebuild for another row quantity.',
  );

  final marketToggle = rebuilds('wishlist_toggle_market');
  expect(
    marketToggle['ProductCardsSliver#wishlist_products_grid']?[1] ?? 0,
    0,
    reason: 'Changing a store favorite must not rebuild the product grid.',
  );

  final productToggle = rebuilds('wishlist_toggle_product');
  final storeCards = <String, int>{
    for (final entry in productToggle.entries)
      if (entry.key.startsWith('StoreMarketCard#wishlist_store_'))
        entry.key: entry.value[1],
  };
  expect(
    storeCards.values,
    everyElement(0),
    reason:
        'Changing a product favorite must not rebuild store favorite cards.',
  );

  for (final scenario
      in report.containsKey('product_variant')
          ? ['product_quantity', 'product_add_to_cart', 'product_variant']
          : ['product_quantity', 'product_add_to_cart']) {
    final product = rebuilds(scenario);
    expect(
      product['_ProductGallery']?[1] ?? 0,
      0,
      reason: '$scenario must not rebuild the static product gallery.',
    );
    expect(
      product['AppImage#product_detail_main_image']?[1] ?? 0,
      0,
      reason: '$scenario must not rebuild the main product image.',
    );
  }

  final category = rebuilds('market_category');
  expect(
    category['MarketStorefrontHero']?[1] ?? 0,
    0,
    reason: 'Changing a category must not rebuild the fixed storefront hero.',
  );
}

Future<void> _auditVariant(WidgetTester tester, AuditMeasure measure) async {
  final fixtures = StressFixtures(productCount: 2, listCount: 2);
  await configureStressApp(fixtures);
  await sl.unregister<ProductRepository>();
  sl.registerSingleton<ProductRepository>(_VariantRepository(fixtures));
  try {
    await tester.pumpWidget(
      const StressApp(
        home: ProductDetailView(
          productId: '1',
          image: '',
          title: 'Variant product',
          brand: 'Store',
          price: '10',
          initialVariantId: 'small',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final option = find.text('Large');
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await measure('product_variant', (_) async {
      await tester.tap(option);
      await tester.pumpAndSettle();
    });

    // Verify the selected variant through the resulting cart line without
    // counting the add-to-cart work in the variant scenario.
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ProductDetailView));
    expect(context.read<CartCubit>().state.single.variantId, 'large');
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    AuthGuard.clearAuthentication();
    await sl.reset();
  }
}

class _VariantRepository extends StressProductRepository {
  _VariantRepository(super.fixtures);

  @override
  Future<ApiResult<ProductData>> getProduct(
    String idOrSlug, {
    bool forceRefresh = false,
  }) async => ApiResult.success(
    ProductData.fromJson({
      ...fixtures.products.first.toJson(),
      'variants': [
        const ProductVariantData(
          id: 'small',
          price: '10',
          attributeValues: {'Size': 'Small'},
        ).toJson(),
        const ProductVariantData(
          id: 'large',
          price: '15',
          attributeValues: {'Size': 'Large'},
        ).toJson(),
      ],
    }),
  );
}
