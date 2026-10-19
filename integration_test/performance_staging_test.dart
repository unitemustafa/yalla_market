import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yalla_market/app/app_providers.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_router.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/app/routing/auth_guard.dart';
import 'package:yalla_market/core/network/api_endpoints.dart';
import 'package:yalla_market/core/theme/app_theme.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_state.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/cart/presentation/views/cart_view.dart';
import 'package:yalla_market/features/cart/presentation/widgets/cart_summary_widgets.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/address_cubit.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/address_state.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/addresses_view.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/address_region_matcher.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/widgets/single_address.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_state.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';
import 'package:yalla_market/features/store/presentation/views/checkout_view.dart';
import 'package:yalla_market/features/store/presentation/views/checkout/payment_success_view.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards_sliver.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'core/scroll_probe.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
  testWidgets(
    'isolated staging store and checkout application path',
    (tester) async {
      expect(kProfileMode, isTrue);
      expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
      expect(ApiEndpoints.rootBaseUrl, 'http://127.0.0.1:18081');
      const uiOnly = bool.fromEnvironment('PERF_PURCHASE_UI_ONLY');
      final directory = await getExternalStorageDirectory();
      expect(directory, isNotNull);
      final file = File('${directory!.path}/performance.private.json');
      final deadline = DateTime.now().add(const Duration(seconds: 120));
      while (!await file.exists() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      expect(
        await file.exists(),
        isTrue,
        reason: 'Run prepare_mobile.py after the isolated APK is installed',
      );
      final config =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(config['environment'], 'isolated-local-performance');
      final observations = <String, Object?>{};
      binding.reportData = {
        'schema_version': 1,
        'mode': 'profile',
        'refresh_hz': 60,
        'language': 'ar',
        'data_source': 'isolated_local_staging',
        'completed': false,
        'scroll_protocol': 'edge_reversal_with_motion_validation_v2',
        'scope': 'store_ui_checkout_cubit_and_purchase_ui',
        'purchase_ui_only': uiOnly,
        'test_forced_semantics': false,
        'input_route': 'test',
        'limitations': [
          'USB loopback, not shaped WiFi',
          'checkout_* timings end at Cubit; ui_* timings include UI settling',
          'Address selector is opened programmatically; success sound suppressed',
          'Startup excluded',
        ],
        'observations': observations,
      };
      await sl.reset();
      initServiceLocator();
      late BuildContext appContext;
      await tester.pumpWidget(
        AppProviders(
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.lightTheme,
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.paymentSuccess) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => PaymentSuccessView(
                    args: settings.arguments as PaymentSuccessRouteArgs?,
                    feedbackPlayer: () async {},
                  ),
                );
              }
              return AppRouter.generateRoute(settings);
            },
            home: Builder(
              builder: (context) {
                appContext = context;
                return const Scaffold();
              },
            ),
          ),
        ),
      );
      // Navigator may build the initial route on the next live frame.
      await tester.pumpAndSettle();
      addTearDown(() async {
        if (await file.exists()) await file.delete();
        AuthGuard.clearAuthentication();
        await sl.reset();
      });
      if (!appContext.mounted) fail('Application setup context was disposed');
      final auth = appContext.read<AuthCubit>();
      final location = appContext.read<LocationCubit>();
      final cart = appContext.read<CartCubit>();
      final addresses = appContext.read<AddressCubit>();
      final checkout = appContext.read<CheckoutCubit>();
      await auth.login(
        email: config['email'] as String,
        password: config['password'] as String,
      );
      expect(auth.state, isA<AuthAuthenticated>());
      final cities = await location.loadAvailableCities();
      expect(cities, isNotEmpty);
      await addresses.loadAddresses();
      final fixtureAddress = addresses.state.addresses.firstWhere(
        (address) => address.id == '${config['address_id']}',
      );
      final fixtureCity = cities
          .where((city) => isAddressAvailableForCity(fixtureAddress, city))
          .firstOrNull;
      expect(
        fixtureCity,
        isNotNull,
        reason: 'Fixture address requires a matching delivery region',
      );
      location.syncCity(fixtureCity);
      location.consumeGpsSuggestionSlot();
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      if (!uiOnly) {
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => BrandProductsView(
                brand: 'PERF',
                logo: '',
                productCount: '${config['count']}',
                marketId: '${config['market_id']}',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final readyDeadline = DateTime.now().add(const Duration(seconds: 30));
        final cards = find.byType(ProductCardsSliver<ProductData>);
        while (cards.evaluate().isEmpty &&
            DateTime.now().isBefore(readyDeadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(cards, findsOneWidget);
        final products = tester.element(cards).read<StoreProductsCubit>();
        expect(products.state.error, isNull);
        for (var repeat = 1; repeat <= 3; repeat++) {
          await binding.watchPerformance(() async {
            observations['scroll_motion_$repeat'] = await scrollProbe(tester);
          }, reportKey: 'staging_store_scroll_$repeat');
          observations['loaded_$repeat'] = products.state.products.length;
          expect(products.state.moreError, isNull);
          expect(
            products.state.products.map((p) => p.id).toSet().length,
            products.state.products.length,
          );
        }
      }
      await cart.loadCartForUser('performance-staging');
      expect(await cart.clearLocalCart(), isTrue);
      final item = CartItemData(
        id: 'perf-item',
        productId: '${config['product_id']}',
        variantId: '${config['variant_id']}',
        marketId: '${config['market_id']}',
        image: '',
        brand: 'PERF',
        title: 'PERF product',
        price: 10,
        quantity: 1,
      );
      await cart.addItem(item, 1);
      if (!uiOnly) {
        final quantityTimes = <int>[];
        for (var repeat = 0; repeat < 30; repeat++) {
          final watch = Stopwatch()..start();
          if (repeat.isEven) {
            await cart.incrementQuantity(item.id);
          } else {
            await cart.decrementQuantity(item.id);
          }
          watch.stop();
          expect(cart.lastErrorMessage, isNull);
          quantityTimes.add(watch.elapsedMicroseconds);
        }
        observations['cart_quantity_us'] = quantityTimes;
        await addresses.loadAddresses();
        expect(addresses.state.addresses, isNotEmpty);
        final previewTimes = <int>[];
        for (var repeat = 0; repeat < 30; repeat++) {
          final watch = Stopwatch()..start();
          await checkout.loadPreview(
            cartItems: cart.state,
            useRemotePreview: true,
            addressId: '${config['address_id']}',
            paymentMethod: 'cash',
          );
          watch.stop();
          expect(checkout.state.previewErrorMessage, isNull);
          expect(checkout.state.preview, isNotNull);
          previewTimes.add(watch.elapsedMicroseconds);
        }
        observations['checkout_preview_us'] = previewTimes;
        final createTimes = <int>[];
        final ids = <String>{};
        for (var repeat = 0; repeat < 30; repeat++) {
          final watch = Stopwatch()..start();
          await checkout.createOrder(
            shippingAddress: ShippingAddressData(
              id: '${config['address_id']}',
              fullName: 'PERF',
              phone: '',
              line1: '',
              city: '',
              state: '',
              country: '',
              postalCode: '',
            ),
            items: cart.state.map(OrderItemData.fromCartItem).toList(),
            cartItems: cart.state,
            paymentMethod: 'cash',
          );
          watch.stop();
          expect(checkout.state, isA<CheckoutSuccess>());
          expect(
            (checkout.state as CheckoutSuccess).order!.total,
            closeTo(checkout.state.preview!.summary.grandTotal, 0.001),
          );
          ids.add((checkout.state as CheckoutSuccess).order!.id);
          createTimes.add(watch.elapsedMicroseconds);
        }
        expect(
          ids.length,
          30,
          reason: 'Separate checkout operations must create distinct requests',
        );
        observations['checkout_create_us'] = createTimes;
      }
      Future<void> ready(bool Function() predicate) async {
        final deadline = DateTime.now().add(const Duration(seconds: 25));
        do {
          await tester.pump(const Duration(milliseconds: 100));
        } while (!predicate() && DateTime.now().isBefore(deadline));
        expect(
          predicate(),
          isTrue,
          reason: 'Purchase UI did not reach its expected state',
        );
        await tester.pumpAndSettle();
      }

      final uiCart = <int>[];
      final uiQuantity = <int>[];
      final uiAddress = <int>[];
      final uiPreview = <int>[];
      final uiSubmit = <int>[];
      final uiJourney = <int>[];
      final uiOrders = <String>{};
      observations.addAll({
        'ui_cart_open_us': uiCart,
        'ui_cart_quantity_us': uiQuantity,
        'ui_address_select_us': uiAddress,
        'ui_checkout_preview_us': uiPreview,
        'ui_order_submit_us': uiSubmit,
        'ui_purchase_journey_us': uiJourney,
      });
      for (var repeat = 0; repeat < 30; repeat++) {
        await cart.clearLocalCart();
        await cart.addItem(item, 1);
        checkout.reset();
        final journey = Stopwatch()..start();
        final step = Stopwatch()..start();
        unawaited(navigator.pushNamed(AppRoutes.cart));
        await ready(() => find.byType(CartView).evaluate().isNotEmpty);
        uiCart.add(step.elapsedMicroseconds);
        step.reset();
        await tester.tap(
          find.descendant(
            of: find.byType(QuantityStepper),
            matching: find.byIcon(AppIcons.add),
          ),
        );
        await ready(
          () => cart.state.length == 1 && cart.state.single.quantity == 2,
        );
        expect(cart.lastErrorMessage, isNull);
        uiQuantity.add(step.elapsedMicroseconds);
        step.reset();
        await tester.tap(
          find.descendant(
            of: find.byType(CheckoutSummary),
            matching: find.byType(ElevatedButton),
          ),
        );
        await ready(
          () =>
              find.byType(CheckoutView).evaluate().isNotEmpty &&
              checkout.state.preview != null &&
              !checkout.state.isPreviewLoading,
        );
        expect(checkout.state.previewErrorMessage, isNull);
        uiPreview.add(step.elapsedMicroseconds);
        step.reset();
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => const AddressesView(returnAfterSelection: true),
            ),
          ),
        );
        await ready(
          () =>
              addresses.state is AddressReady &&
              find.byType(SingleAddress).evaluate().isNotEmpty,
        );
        await tester.tap(find.byType(SingleAddress).first);
        await ready(
          () =>
              find.byType(AddressesView).evaluate().isEmpty &&
              !checkout.state.isPreviewLoading,
        );
        expect(addresses.state.selectedAddressId, '${config['address_id']}');
        uiAddress.add(step.elapsedMicroseconds);
        step.reset();
        await tester.tap(
          find.widgetWithIcon(ElevatedButton, AppIcons.clipboard_tick),
        );
        await ready(
          () => find.byType(PaymentSuccessView).evaluate().isNotEmpty,
        );
        final success = tester.widget<PaymentSuccessView>(
          find.byType(PaymentSuccessView),
        );
        expect(success.args?.orderId, isNotEmpty);
        uiOrders.add(success.args!.orderId);
        uiSubmit.add(step.elapsedMicroseconds);
        uiJourney.add(journey.elapsedMicroseconds);
        observations['ui_distinct_order_count'] = uiOrders.length;
        navigator.pop();
        await tester.pumpAndSettle();
        navigator.pop();
        await tester.pumpAndSettle();
        debugPrint('PERF_PURCHASE_DONE ${repeat + 1}');
      }
      expect(uiOrders.length, 30);
      binding.reportData!['completed'] = true;
    },
    timeout: const Timeout(Duration(minutes: 10)),
    semanticsEnabled: false,
  );
}
