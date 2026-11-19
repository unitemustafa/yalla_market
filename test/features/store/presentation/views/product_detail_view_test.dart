import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/core/presentation/widgets/products/cart_counter_icon.dart';
import 'package:yalla_market/core/theme/app_theme.dart';
import 'package:yalla_market/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/brand_data.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/repositories/product_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_product_usecase.dart';
import 'package:yalla_market/features/store/presentation/views/product_detail_view.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_state.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
  testWidgets(
    'favorite updates leave the product detail scroll subtree untouched',
    (tester) async {
      final product = _productWith(variants: const []);
      await _pumpProduct(tester, product: product);
      final scroll = find.byKey(const ValueKey('product_detail_scroll'));
      final originalScroll = tester.widget(scroll);
      final wishlist = tester.element(scroll).read<WishlistCubit>();
      const other = WishlistItem(
        productId: 'another-product',
        title: 'Another product',
        image: '',
        brand: '',
        price: '10',
      );
      wishlist.emit(WishlistState(const [other]));
      await tester.pump();
      expect(tester.widget(scroll), same(originalScroll));

      wishlist.emit(
        WishlistState(
          const [other],
          favoriteIds: {other.productId, product.id},
        ),
      );
      await tester.pump();
      expect(find.byIcon(AppIcons.heart5), findsOneWidget);
      expect(tester.widget(scroll), same(originalScroll));
    },
  );

  for (final viewport in [
    (
      size: const Size(375, 812),
      insets: const EdgeInsets.only(top: 44, bottom: 34),
    ),
    (
      size: const Size(812, 375),
      insets: const EdgeInsets.fromLTRB(44, 0, 44, 21),
    ),
  ]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'iPhone product controls respect safe areas (${viewport.size}, $direction)',
        (tester) async {
          await tester.binding.setSurfaceSize(viewport.size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await _pumpProduct(
            tester,
            textDirection: direction,
            safeInsets: viewport.insets,
            textScale: 1.5,
            product: _productWith(
              title: 'A long product title for the iPhone safe area',
              variants: const [
                {'id': 'base', 'price': '10'},
              ],
            ),
          );
          await tester.drag(
            find.byKey(const ValueKey('product_detail_scroll')),
            const Offset(0, -700),
          );
          await tester.pumpAndSettle();

          final safeBounds = viewport.insets.deflateRect(
            Offset.zero & viewport.size,
          );
          final cart = tester.getRect(find.byType(CartCounterIcon));
          final title = tester.getRect(
            find.byKey(const ValueKey('product_detail_title')),
          );
          final share = tester.getRect(find.byIcon(AppIcons.send_1));
          for (final rect in [cart, title, share]) {
            expect(rect.left, greaterThanOrEqualTo(safeBounds.left));
            expect(rect.right, lessThanOrEqualTo(safeBounds.right));
            expect(rect.top, greaterThanOrEqualTo(safeBounds.top));
          }
          final addButton = tester.getRect(find.byType(ElevatedButton));
          expect(addButton.bottom, lessThanOrEqualTo(safeBounds.bottom));
          expect(title.overlaps(cart), isFalse);
          expect(title.overlaps(share), isFalse);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  }

  testWidgets('shrinks gallery and moves title into a pinned toolbar', (
    tester,
  ) async {
    await _pumpProduct(
      tester,
      product: _productWith(
        variants: const [
          {'id': 'base', 'price': '10'},
        ],
        description: List.filled(40, 'Long description.').join('\n'),
      ),
    );
    final scroll = find.byKey(const ValueKey('product_detail_scroll'));
    final image = find.byKey(const ValueKey('product_detail_main_image'));
    final title = find.byKey(const ValueKey('product_detail_title'));
    final imageSize = tester.getSize(image);
    final expandedTitle = tester.getRect(title);
    final cartRect = tester.getRect(find.byType(CartCounterIcon));
    final gesture = await tester.startGesture(tester.getCenter(scroll));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(tester.getSize(image).height, lessThan(imageSize.height));
    expect(tester.getSize(image).width, lessThan(imageSize.width));
    expect(tester.getRect(title).top, lessThan(expandedTitle.top));
    await gesture.moveBy(const Offset(0, -500));
    await gesture.up();
    await tester.pumpAndSettle();
    final pinnedTitle = tester.getRect(title);
    expect(pinnedTitle.center.dy, closeTo(cartRect.center.dy, 1));
    expect(tester.widget<Text>(title).maxLines, 1);
    expect(tester.getRect(find.byType(CartCounterIcon)), cartRect);
    await tester.drag(scroll, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getRect(title), pinnedTitle);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stretches image during pull and restores it on release', (
    tester,
  ) async {
    await _pumpProduct(
      tester,
      product: _productWith(
        variants: const [
          {'id': 'base', 'price': '10'},
        ],
      ),
    );
    final scroll = find.byKey(const ValueKey('product_detail_scroll'));
    final image = find.byKey(const ValueKey('product_detail_main_image'));
    final originalSize = tester.getSize(image);
    final gesture = await tester.startGesture(tester.getCenter(scroll));
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(tester.getSize(image).height, greaterThan(originalSize.height));
    expect(tester.getSize(image).width, greaterThan(originalSize.width));
    expect(tester.widget<AppImage>(image).fit, BoxFit.contain);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(image), originalSize);
    expect(tester.takeException(), isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('collapses short page with long large title ($direction)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpProduct(
        tester,
        textDirection: direction,
        textScale: 2,
        isDark: direction == TextDirection.rtl,
        product: _productWith(
          title: direction == TextDirection.rtl
              ? 'اسم منتج طويل جدًا لاختبار العنوان أثناء الحركة والطي'
              : 'A very long product name to check the moving collapsed title',
          variants: const [
            {'id': 'base', 'price': '10'},
          ],
        ),
      );
      final title = find.byKey(const ValueKey('product_detail_title'));
      expect(tester.widget<Text>(title).maxLines, 2);
      await tester.drag(
        find.byKey(const ValueKey('product_detail_scroll')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
      final titleRect = tester.getRect(title);
      final cartRect = tester.getRect(find.byType(CartCounterIcon));
      final shareRect = tester.getRect(find.byIcon(AppIcons.send_1));
      expect(tester.widget<Text>(title).maxLines, 1);
      expect(titleRect.center.dy, closeTo(cartRect.center.dy, 1));
      expect(titleRect.overlaps(cartRect), isFalse);
      expect(titleRect.overlaps(shareRect), isFalse);
      expect(find.byIcon(AppIcons.send_1).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('pins cart in place of back button ($direction)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      RouteSettings? openedRoute;
      await _pumpProduct(
        tester,
        textDirection: direction,
        isDark: direction == TextDirection.rtl,
        textScale: 2,
        product: _productWith(
          variants: const [
            {'id': 'base', 'price': '10'},
          ],
          description: List.filled(30, 'Product description.').join('\n'),
        ),
        onGenerateRoute: (settings) {
          openedRoute = settings;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Cart page')),
          );
        },
      );
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(AppIcons.arrow_left_2), findsNothing);
      expect(find.byIcon(AppIcons.arrow_right_3), findsNothing);
      final cart = find.byType(CartCounterIcon);
      final cartRect = tester.getRect(cart);
      final share = tester.getCenter(find.byIcon(AppIcons.send_1));
      expect(
        cartRect.center.dx,
        direction == TextDirection.rtl
            ? greaterThan(share.dx)
            : lessThan(share.dx),
      );

      await tester.drag(
        find.byKey(const ValueKey('product_detail_scroll')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(cart), cartRect);
      expect(find.byIcon(AppIcons.send_1).hitTestable(), findsOneWidget);
      await tester.tap(cart);
      await tester.pumpAndSettle();
      expect(openedRoute?.name, AppRoutes.cart);
      expect(find.text('Cart page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('flies selected image on a curved path then pulses the cart', (
    tester,
  ) async {
    final cart = makeCartCubit();
    await _pumpProduct(
      tester,
      cartCubit: cart,
      product: _productWith(
        variants: const [
          {'id': 'base', 'price': '10'},
        ],
        images: const [AppAssets.defaultProduct, AppAssets.defaultAddon],
      ),
    );
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AppImage && widget.source == AppAssets.defaultAddon,
      ),
    );
    await tester.pumpAndSettle();
    final start = tester.getCenter(
      find.byKey(const ValueKey('product_detail_main_image')),
    );
    final end = tester.getCenter(find.byType(CartCounterIcon));
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    await tester.pump();

    final flying = find.byKey(const ValueKey('product_detail_flying_image'));
    expect(flying, findsOneWidget);
    expect((tester.getCenter(flying) - start).distance, lessThan(1));
    expect(
      tester
          .widget<AppImage>(
            find.descendant(of: flying, matching: find.byType(AppImage)),
          )
          .source,
      AppAssets.defaultAddon,
    );
    expect(cart.state.single.quantity, 2);
    expect(
      find.descendant(
        of: find.byType(CartCounterIcon),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 350));
    final middle = tester.getRect(flying);
    expect(
      (middle.center - Offset.lerp(start, end, 0.5)!).distance,
      greaterThan(10),
    );
    expect(middle.width, lessThan(56));
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect((tester.getCenter(flying) - end).distance, lessThan(5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(flying, findsNothing);
    final pulse = tester.widget<Transform>(
      find.byKey(const ValueKey('product_detail_cart_scale')),
    );
    expect(pulse.transform.getMaxScaleOnAxis(), greaterThan(1));
    await tester.pumpAndSettle();
    expect(find.text('Add to Bag'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flies from add button when product image is scrolled away', (
    tester,
  ) async {
    await _pumpProduct(
      tester,
      product: _productWith(
        variants: const [
          {'id': 'base', 'price': '10'},
        ],
        description: List.filled(40, 'Long description.').join('\n'),
      ),
    );
    await tester.drag(
      find.byKey(const ValueKey('product_detail_scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final scrollOffset = scroll.pixels;
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pumpAndSettle();
    final buttonCenter = tester.getCenter(find.byType(ElevatedButton).last);
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    await tester.pump();
    final flying = find.byKey(const ValueKey('product_detail_flying_image'));
    expect(flying, findsOneWidget);
    expect((tester.getCenter(flying) - buttonCenter).distance, lessThan(1));
    expect(scroll.pixels, scrollOffset);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('waits for save and prevents duplicate adds and quantity edits', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = _ControlledCartRepository(addGate: gate);
    final cart = makeCartCubit(repository: repository);
    await _pumpProduct(
      tester,
      cartCubit: cart,
      product: _productWith(
        variants: const [
          {'id': 'base', 'price': '10'},
        ],
      ),
    );
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    final button = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton).last,
    );
    button.onPressed!();
    button.onPressed!();
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    expect(repository.addCalls, 1);
    expect(cart.state, isEmpty);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.byKey(const ValueKey('product_detail_flying_image')),
      findsNothing,
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(cart.state.single.quantity, 1);
    expect(
      find.byKey(const ValueKey('product_detail_flying_image')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  for (final invalidateSession in [false, true]) {
    testWidgets(
      'keeps quantity without flight on failed add (session: $invalidateSession)',
      (tester) async {
        final gate = Completer<void>();
        final repository = _ControlledCartRepository(
          addGate: gate,
          failure: invalidateSession
              ? null
              : const ServerFailure('Cart save failed'),
        );
        final cart = makeCartCubit(repository: repository);
        await _pumpProduct(
          tester,
          cartCubit: cart,
          product: _productWith(
            variants: const [
              {'id': 'base', 'price': '10'},
            ],
          ),
        );
        await tester.tap(find.byIcon(AppIcons.add).last);
        await tester.pump();
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pump();
        if (invalidateSession) cart.clearSession();
        gate.complete();
        await tester.pump();
        await tester.pump();
        expect(
          find.byKey(const ValueKey('product_detail_flying_image')),
          findsNothing,
        );
        expect(cart.state, isEmpty);
        expect(find.text('1'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          tester
              .widget<ElevatedButton>(find.byType(ElevatedButton).last)
              .onPressed,
          isNotNull,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final cancel in [
    'open cart',
    'open another route',
    'dispose',
    'reduce motion',
  ]) {
    testWidgets('cleans up flying image on $cancel', (tester) async {
      await _pumpProduct(
        tester,
        product: _productWith(
          variants: const [
            {'id': 'base', 'price': '10'},
          ],
        ),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cart page')),
        ),
      );
      await tester.tap(find.byIcon(AppIcons.add).last);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final flying = find.byKey(const ValueKey('product_detail_flying_image'));
      expect(flying, findsOneWidget);
      switch (cancel) {
        case 'open cart':
          await tester.tap(find.byType(CartCounterIcon));
        case 'open another route':
          Navigator.of(tester.element(find.byType(ProductDetailView))).push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Another page')),
            ),
          );
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
        case 'reduce motion':
          tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(
            tester
                .binding
                .platformDispatcher
                .clearAccessibilityFeaturesTestValue,
          );
      }
      await tester.pumpAndSettle();
      expect(flying, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final leave in ['open cart', 'dispose']) {
    testWidgets('does not start feedback after leaving during save ($leave)', (
      tester,
    ) async {
      final gate = Completer<void>();
      final cart = makeCartCubit(
        repository: _ControlledCartRepository(addGate: gate),
      );
      await _pumpProduct(
        tester,
        cartCubit: cart,
        product: _productWith(
          variants: const [
            {'id': 'base', 'price': '10'},
          ],
        ),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cart page')),
        ),
      );
      await tester.tap(find.byIcon(AppIcons.add).last);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pump();
      if (leave == 'open cart') {
        await tester.tap(find.byType(CartCounterIcon));
        await tester.pumpAndSettle();
      } else {
        await tester.pumpWidget(const SizedBox.shrink());
      }
      gate.complete();
      await tester.pumpAndSettle();
      expect(cart.state.single.quantity, 1);
      expect(
        find.byKey(const ValueKey('product_detail_flying_image')),
        findsNothing,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('updates cart without flight when reduced motion is enabled', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final cart = makeCartCubit();
    await _pumpProduct(
      tester,
      cartCubit: cart,
      product: _productWith(
        variants: const [
          {'id': 'base', 'price': '10'},
        ],
      ),
    );
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    await tester.pump();
    expect(cart.state.single.quantity, 1);
    expect(
      find.byKey(const ValueKey('product_detail_flying_image')),
      findsNothing,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final isDark in [false, true]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'retry label has space on both sides in RTL (dark: $isDark, scale: $textScale)',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              ),
              home: const ProductDetailView(
                productId: '',
                image: AppAssets.defaultProduct,
                title: 'Product',
                brand: 'Store',
                price: '1.00',
              ),
            ),
          );
          await tester.pumpAndSettle();

          final buttonRect = tester.getRect(find.byType(ElevatedButton));
          final labelRect = tester.getRect(find.text('إعادة المحاولة'));
          expect(labelRect.left - buttonRect.left, greaterThanOrEqualTo(24));
          expect(buttonRect.right - labelRect.right, greaterThanOrEqualTo(24));
          expect(buttonRect.height, greaterThanOrEqualTo(48));
          expect(buttonRect.left, greaterThanOrEqualTo(24));
          expect(buttonRect.right, lessThanOrEqualTo(336));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final marketId in ['market_1', '  market_1  ']) {
    testWidgets('opens the product storefront by market ID ($marketId)', (
      tester,
    ) async {
      RouteSettings? openedRoute;
      await _pumpProduct(
        tester,
        product: ProductData.fromJson({
          'id': 'variant-product',
          'name': 'Product',
          'brand': 'Store name',
          'market_id': marketId,
          'image': AppAssets.defaultProduct,
          'variants': [
            {'id': 'variant_1', 'price': '50.00'},
          ],
        }),
        onGenerateRoute: (settings) {
          openedRoute = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Storefront')),
          );
        },
      );

      await tester.ensureVisible(find.text('Store name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Store name'));
      await tester.pumpAndSettle();

      expect(openedRoute?.name, AppRoutes.brandProducts);
      final args = openedRoute!.arguments! as BrandProductsRouteArgs;
      expect(args.marketId, 'market_1');
      expect(args.brand, 'Store name');
      expect(args.shopId, isNull);
      expect(find.text('Storefront'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows product share actions and copies its unique link', (
    tester,
  ) async {
    String? copiedText;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    await cartCubit.loadCartForUser('user-share');
    if (sl.isRegistered<GetProductUseCase>()) {
      await sl.unregister<GetProductUseCase>();
    }
    sl.registerLazySingleton<GetProductUseCase>(
      () => GetProductUseCase(_FakeProductRepository()),
    );
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);
    addTearDown(() async {
      if (sl.isRegistered<GetProductUseCase>()) {
        await sl.unregister<GetProductUseCase>();
      }
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: const MaterialApp(
          home: ProductDetailView(
            productId: 'product_1',
            image: AppAssets.temporaryMarketPlaceholder,
            title: 'Share fallback title',
            brand: 'Yalla',
            price: '420.00',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AppImage>(
            find.byKey(const ValueKey('product_detail_main_image')),
          )
          .fit,
      BoxFit.contain,
    );

    await tester.tap(find.byIcon(AppIcons.send_1));
    await tester.pumpAndSettle();

    expect(find.text('Share product'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();

    expect(copiedText, 'yallamarket://products/product_1');
    expect(find.text('Product link copied'), findsOneWidget);
  });

  testWidgets('renders backend variants and adds selected variant to cart', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    await cartCubit.loadCartForUser('user-a');
    if (sl.isRegistered<GetProductUseCase>()) {
      await sl.unregister<GetProductUseCase>();
    }
    sl.registerLazySingleton<GetProductUseCase>(
      () => GetProductUseCase(_FakeProductRepository()),
    );
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);
    addTearDown(() async {
      if (sl.isRegistered<GetProductUseCase>()) {
        await sl.unregister<GetProductUseCase>();
      }
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: const MaterialApp(
          home: ProductDetailView(
            productId: 'product_1',
            image: AppAssets.temporaryMarketPlaceholder,
            title: 'شوربة خضار',
            brand: 'Yalla',
            price: '420.00 - 735.00',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('شوربة خضار'), findsWidgets);
    expect(find.text('منتج تجريبي: شوربة خضار.'), findsOneWidget);
    expect(find.text('الحصة'), findsOneWidget);
    expect(find.text('عادية'), findsOneWidget);
    expect(find.text('عائلية'), findsOneWidget);
    expect(find.text('Options'), findsNothing);
    expect(find.textContaining('SEED-07-1'), findsNothing);
    expect(find.textContaining('SEED-07-2'), findsNothing);
    expect(find.text('Electronic devices'), findsNothing);
    expect(find.text('Mobile'), findsNothing);
    expect(find.text('Accessories'), findsNothing);
    expect(find.text('Spare parts'), findsNothing);
    expect(find.text('X-Large'), findsNothing);
    expect(find.text('Reviews & Ratings'), findsNothing);
    expect(find.text('Add to Bag'), findsOneWidget);

    await tester.ensureVisible(find.text('عائلية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عائلية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose additions'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('addition-image-addition_9')),
      findsOneWidget,
    );
    await tester.tap(find.text('Extra cheese').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    final cartItem = cartCubit.state.singleWhere(
      (item) => item.title == 'شوربة خضار',
    );
    expect(cartItem.id, 'variant_2:additions:addition_9');
    expect(cartItem.productId, 'product_1');
    expect(cartItem.variantId, 'variant_2');
    expect(cartItem.marketId, 'market_1');
    expect(cartItem.price, 745);
    expect(cartItem.quantity, 2);
    expect(cartItem.additionIds, ['addition_9']);
    expect(cartItem.attributes, hasLength(2));
    expect(cartItem.attributes.first.label, 'الحصة');
    expect(cartItem.attributes.first.value, 'عائلية');
  });

  testWidgets('shows a retry state and replaces it with API details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    await cartCubit.loadCartForUser('user-retry');
    if (sl.isRegistered<GetProductUseCase>()) {
      await sl.unregister<GetProductUseCase>();
    }
    sl.registerLazySingleton<GetProductUseCase>(
      () => GetProductUseCase(_RetryProductRepository()),
    );
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);
    addTearDown(() async {
      if (sl.isRegistered<GetProductUseCase>()) {
        await sl.unregister<GetProductUseCase>();
      }
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: const MaterialApp(
          home: ProductDetailView(
            productId: 'product_retry',
            image: AppAssets.defaultProduct,
            title: 'Card title must not be shown as success',
            brand: 'Card brand',
            price: '1.00',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('تحقق من اتصال الإنترنت ثم حاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.text('Card title must not be shown as success'), findsNothing);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('Loaded from API'), findsOneWidget);
    expect(find.text('API description'), findsOneWidget);
  });

  testWidgets('disables ordering when product details have no variants', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final cartCubit = makeCartCubit();
    final wishlistCubit = makeWishlistCubit();
    await cartCubit.loadCartForUser('user-no-variant');
    if (sl.isRegistered<GetProductUseCase>()) {
      await sl.unregister<GetProductUseCase>();
    }
    sl.registerLazySingleton<GetProductUseCase>(
      () => GetProductUseCase(_NoVariantProductRepository()),
    );
    addTearDown(cartCubit.close);
    addTearDown(wishlistCubit.close);
    addTearDown(() async {
      if (sl.isRegistered<GetProductUseCase>()) {
        await sl.unregister<GetProductUseCase>();
      }
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<WishlistCubit>.value(value: wishlistCubit),
        ],
        child: const MaterialApp(
          home: ProductDetailView(
            productId: 'product_no_variant',
            image: AppAssets.defaultProduct,
            title: 'Loading',
            brand: 'Loading',
            price: '',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('هذا المنتج غير متاح للطلب حاليًا.'), findsOneWidget);
    final addButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton).last,
    );
    expect(addButton.onPressed, isNull);
  });

  testWidgets('hides specifications for one base variant without attributes', (
    tester,
  ) async {
    await _pumpProduct(
      tester,
      product: _productWith(
        variants: const [
          {'id': 'base', 'price': '10.00', 'attribute_values': []},
        ],
      ),
    );

    expect(find.text('المواصفات'), findsNothing);
  });

  testWidgets('shows three read-only specifications for one variant', (
    tester,
  ) async {
    await _pumpProduct(
      tester,
      product: _productWith(
        variants: [
          {
            'id': 'only',
            'price': '15.00',
            'attribute_values': _attributeValues(
              color: 'أبيض',
              size: 'كبير',
              material: 'قطن',
            ),
          },
        ],
      ),
    );

    expect(find.text('المواصفات'), findsOneWidget);
    expect(find.text('اللون: أبيض'), findsOneWidget);
    expect(find.text('الحجم: كبير'), findsOneWidget);
    expect(find.text('الخامة: قطن'), findsOneWidget);
    expect(find.widgetWithText(InkWell, 'أبيض'), findsNothing);
  });

  testWidgets(
    'multiple variants use only their values as interactive choices',
    (tester) async {
      await _pumpProduct(
        tester,
        product: _productWith(
          attributes: const [
            {
              'id': 1,
              'name': 'اللون',
              'options': [
                {'id': 1, 'value': 'أبيض'},
                {'id': 2, 'value': 'أسود'},
                {'id': 3, 'value': 'أزرق غير مستخدم'},
              ],
            },
          ],
          variants: [
            {
              'id': 'white',
              'price': '10.00',
              'attribute_values': _attributeValues(color: 'أبيض', size: 'صغير'),
            },
            {
              'id': 'black',
              'price': '20.00',
              'attribute_values': _attributeValues(color: 'أسود', size: 'كبير'),
            },
          ],
        ),
      );

      expect(find.text('اللون'), findsOneWidget);
      expect(find.text('الحجم'), findsOneWidget);
      expect(find.text('أبيض'), findsOneWidget);
      expect(find.text('أسود'), findsOneWidget);
      expect(find.text('أزرق غير مستخدم'), findsNothing);
      expect(find.widgetWithText(InkWell, 'أسود'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('الحجم')).dy,
        greaterThan(tester.getTopLeft(find.text('اللون')).dy),
      );
      expect(
        tester.getTopLeft(find.text('أبيض')).dy,
        tester.getTopLeft(find.text('أسود')).dy,
      );
      expect(
        tester.getSize(find.widgetWithText(InkWell, 'أبيض')).width,
        tester.getSize(find.widgetWithText(InkWell, 'أسود')).width,
      );
      expect(find.text('Selected variation'), findsNothing);
    },
  );

  testWidgets('three values share the full attribute row equally', (
    tester,
  ) async {
    await _pumpProduct(
      tester,
      product: _productWith(
        variants: [
          {
            'id': 'green',
            'price': '10.00',
            'attribute_values': _attributeValues(color: 'أخضر'),
          },
          {
            'id': 'black',
            'price': '20.00',
            'attribute_values': _attributeValues(color: 'أسود'),
          },
          {
            'id': 'white',
            'price': '30.00',
            'attribute_values': _attributeValues(color: 'أبيض'),
          },
        ],
      ),
    );

    final green = find.widgetWithText(InkWell, 'أخضر');
    final black = find.widgetWithText(InkWell, 'أسود');
    final white = find.widgetWithText(InkWell, 'أبيض');
    expect(tester.getTopLeft(green).dy, tester.getTopLeft(black).dy);
    expect(tester.getTopLeft(black).dy, tester.getTopLeft(white).dy);
    expect(tester.getSize(green).width, tester.getSize(black).width);
    expect(tester.getSize(black).width, tester.getSize(white).width);
  });

  testWidgets('selection changes variant id and price', (tester) async {
    final cartCubit = makeCartCubit();
    await _pumpProduct(
      tester,
      cartCubit: cartCubit,
      product: _productWith(
        variants: [
          {
            'id': 'white',
            'price': '10.00',
            'attribute_values': _attributeValues(color: 'أبيض'),
          },
          {
            'id': 'black',
            'price': '20.00',
            'attribute_values': _attributeValues(color: 'أسود'),
          },
        ],
      ),
    );

    await tester.ensureVisible(find.text('أسود'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أسود'));
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    expect(cartCubit.state.single.variantId, 'black');
    expect(cartCubit.state.single.price, 20);
  });

  testWidgets('a linked variant keeps its selection, price and shared link', (
    tester,
  ) async {
    String? copiedLink;
    String? sharedText;
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedLink = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      sharedText = (call.arguments as Map)['text'] as String;
      return '';
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      messenger.setMockMethodCallHandler(shareChannel, null);
    });
    await _pumpProduct(
      tester,
      initialVariantId: '202',
      product: _productWith(
        variants: [
          {
            'id': '101',
            'price': '10.00',
            'attribute_values': _attributeValues(size: 'صغير'),
          },
          {
            'id': '202',
            'price': '20.00',
            'attribute_values': _attributeValues(size: 'كبير'),
          },
        ],
      ),
    );
    await tester.tap(find.byIcon(AppIcons.send_1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(Uri.parse(copiedLink!).queryParameters['variant'], '202');

    await tester.tap(find.byIcon(AppIcons.send_1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(sharedText, contains('الحجم: كبير'));
    expect(sharedText, contains('20'));
    expect(sharedText, contains('variant=202'));
    expect(sharedText, isNot(contains('10 - 20')));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a removed linked variant falls back to current product choices',
    (tester) async {
      await _pumpProduct(
        tester,
        initialVariantId: '999',
        product: _productWith(
          variants: [
            {
              'id': '101',
              'price': '10.00',
              'attribute_values': _attributeValues(size: 'صغير'),
            },
            {
              'id': '202',
              'price': '20.00',
              'attribute_values': _attributeValues(size: 'كبير'),
            },
          ],
        ),
      );
      expect(find.byIcon(Icons.check), findsNothing);
      final priceTexts = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text.toPlainText());
      expect(priceTexts.any((text) => text.contains('10 - 20')), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows discounted price range before selecting a variant', (
    tester,
  ) async {
    await _pumpProduct(
      tester,
      product: _productWith(
        discount: '50.00',
        variants: [
          {
            'id': 'small',
            'price': '100.00',
            'attribute_values': _attributeValues(size: 'صغير'),
          },
          {
            'id': 'medium',
            'price': '200.00',
            'attribute_values': _attributeValues(size: 'متوسط'),
          },
        ],
      ),
    );

    expect(find.text('50% OFF'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('Selected variation'), findsNothing);
    final priceTexts = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((widget) => widget.text.toPlainText());
    expect(priceTexts.any((text) => text.contains('50 - 100')), isTrue);
  });

  testWidgets('missing combination disables add to cart', (tester) async {
    final cartCubit = makeCartCubit();
    await _pumpProduct(
      tester,
      cartCubit: cartCubit,
      product: _productWith(
        variants: [
          {
            'id': 'white-small',
            'price': '10.00',
            'attribute_values': _attributeValues(color: 'أبيض', size: 'صغير'),
          },
          {
            'id': 'black-large',
            'price': '20.00',
            'attribute_values': _attributeValues(color: 'أسود', size: 'كبير'),
          },
        ],
      ),
    );

    await tester.ensureVisible(find.text('صغير'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صغير'));
    await tester.pump();
    await tester.ensureVisible(find.text('أسود'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أسود'));
    await tester.pump();

    expect(find.text('هذا الاختيار غير متاح حاليًا.'), findsOneWidget);
    final addButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton).last,
    );
    expect(addButton.onPressed, isNull);
    expect(cartCubit.state, isEmpty);
  });
}

Future<void> _pumpProduct(
  WidgetTester tester, {
  required ProductData product,
  CartCubit? cartCubit,
  RouteFactory? onGenerateRoute,
  String? initialVariantId,
  TextDirection textDirection = TextDirection.ltr,
  bool isDark = false,
  double textScale = 1,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) async {
  SharedPreferences.setMockInitialValues({});
  final cart = cartCubit ?? makeCartCubit();
  final wishlist = makeWishlistCubit();
  await cart.loadCartForUser('variant-test-user');
  if (sl.isRegistered<GetProductUseCase>()) {
    await sl.unregister<GetProductUseCase>();
  }
  sl.registerLazySingleton<GetProductUseCase>(
    () => GetProductUseCase(_StaticProductRepository(product)),
  );
  addTearDown(cart.close);
  addTearDown(wishlist.close);
  addTearDown(() async {
    if (sl.isRegistered<GetProductUseCase>()) {
      await sl.unregister<GetProductUseCase>();
    }
  });

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>.value(value: cart),
        BlocProvider<WishlistCubit>.value(value: wishlist),
      ],
      child: MaterialApp(
        onGenerateRoute: onGenerateRoute,
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: safeInsets,
            viewPadding: safeInsets,
          ),
          child: Directionality(textDirection: textDirection, child: child!),
        ),
        home: ProductDetailView(
          productId: 'variant-product',
          image: AppAssets.defaultProduct,
          title: 'Product',
          brand: 'Yalla',
          price: '0.00',
          initialVariantId: initialVariantId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProductData _productWith({
  required List<Map<String, Object?>> variants,
  List<Map<String, Object?>> attributes = const [],
  String discount = '0.00',
  String description = '',
  List<String> images = const [],
  String title = 'Variant product',
}) => ProductData.fromJson({
  'id': 'variant-product',
  'name': title,
  'image': AppAssets.defaultProduct,
  'variants': variants,
  'attributes': attributes,
  'discount': discount,
  'description': description,
  'images': images,
});

class _ControlledCartRepository extends CartRepositoryImpl {
  _ControlledCartRepository({this.addGate, this.failure});

  final Completer<void>? addGate;
  final Failure? failure;
  int addCalls = 0;

  @override
  Future<ApiResult<List<CartItemData>>> addItem(
    String userKey,
    CartItemData item,
    int quantityToAdd,
  ) async {
    addCalls++;
    await addGate?.future;
    if (failure case final failure?) return ApiResult.failure(failure);
    return super.addItem(userKey, item, quantityToAdd);
  }
}

List<Map<String, Object?>> _attributeValues({
  String? color,
  String? size,
  String? material,
}) => [
  if (color != null) {'attribute_name': 'اللون', 'option_value': color},
  if (size != null) {'attribute_name': 'الحجم', 'option_value': size},
  if (material != null) {'attribute_name': 'الخامة', 'option_value': material},
];

abstract class _EmptyProductRepository implements ProductRepository {
  @override
  Future<ApiResult<List<ProductData>>> getProducts({
    String? citySlug,
    bool forceRefresh = false,
  }) async => const ApiResult.success([]);

  @override
  Future<ApiResult<List<ProductData>>> searchProducts(
    String query, {
    String? citySlug,
  }) async => const ApiResult.success([]);

  @override
  Future<ApiResult<List<CategoryData>>> getCategories({
    bool forceRefresh = false,
  }) async => const ApiResult.success([]);

  @override
  Future<ApiResult<List<BrandData>>> getBrands({
    bool forceRefresh = false,
  }) async => const ApiResult.success([]);
}

class _StaticProductRepository extends _EmptyProductRepository {
  _StaticProductRepository(this.product);

  final ProductData product;

  @override
  Future<ApiResult<ProductData>> getProduct(
    String idOrSlug, {
    bool forceRefresh = false,
  }) async => ApiResult.success(product);
}

class _RetryProductRepository extends _EmptyProductRepository {
  var attempts = 0;

  @override
  Future<ApiResult<ProductData>> getProduct(
    String idOrSlug, {
    bool forceRefresh = false,
  }) async {
    attempts++;
    if (attempts == 1) {
      return const ApiResult.failure(NetworkFailure('Offline'));
    }
    return ApiResult.success(
      ProductData.fromJson({
        'id': idOrSlug,
        'name': 'Loaded from API',
        'description': 'API description',
        'image': AppAssets.defaultProduct,
        'variants': [
          {'id': 'variant_retry', 'price': '50.00'},
        ],
      }),
    );
  }
}

class _NoVariantProductRepository extends _EmptyProductRepository {
  @override
  Future<ApiResult<ProductData>> getProduct(
    String idOrSlug, {
    bool forceRefresh = false,
  }) async {
    return ApiResult.success(
      ProductData.fromJson({
        'id': idOrSlug,
        'name': 'Unavailable product',
        'description': 'No variant',
        'image': AppAssets.defaultProduct,
        'variants': const [],
      }),
    );
  }
}

class _FakeProductRepository extends _EmptyProductRepository {
  @override
  Future<ApiResult<ProductData>> getProduct(
    String idOrSlug, {
    bool forceRefresh = false,
  }) async {
    return ApiResult.success(
      ProductData.fromJson({
        'id': 'product_1',
        'image': AppAssets.temporaryMarketPlaceholder,
        'name': 'شوربة خضار',
        'brand': 'Yalla',
        'description': 'منتج تجريبي: شوربة خضار.',
        'market_id': 'market_1',
        'additions': [
          {
            'id': 'addition_9',
            'name_en': 'Extra cheese',
            'price': '10.00',
            'is_active': true,
          },
        ],
        'variants': [
          {
            'id': 'variant_1',
            'price': '420.00',
            'sku': 'SEED-07-1',
            'attribute_values': [
              {
                'id': 1,
                'attribute_id': 4,
                'attribute_name': 'الحصة',
                'option_id': 7,
                'option_value': 'عادية',
              },
            ],
          },
          {
            'id': 'variant_2',
            'price': '735.00',
            'sku': 'SEED-07-2',
            'attribute_values': [
              {
                'id': 2,
                'attribute_id': 4,
                'attribute_name': 'الحصة',
                'option_id': 8,
                'option_value': 'عائلية',
              },
            ],
          },
        ],
      }),
    );
  }
}
