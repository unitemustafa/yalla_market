import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/di/service_locator.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/brand_data.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/repositories/product_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_product_usecase.dart';
import 'package:yalla_market/features/store/presentation/views/product_detail_view.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../../../helpers/cubit_factories.dart';

void main() {
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
    await tester.tap(find.text('عائلية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose additions'));
    await tester.pumpAndSettle();
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
      expect(find.text('أبيض'), findsOneWidget);
      expect(find.text('أسود'), findsOneWidget);
      expect(find.text('أزرق غير مستخدم'), findsNothing);
      expect(find.widgetWithText(InkWell, 'أسود'), findsOneWidget);
    },
  );

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
    await tester.tap(find.text('أسود'));
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    expect(cartCubit.state.single.variantId, 'black');
    expect(cartCubit.state.single.price, 20);
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

    await tester.ensureVisible(find.text('أسود'));
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
      child: const MaterialApp(
        home: ProductDetailView(
          productId: 'variant-product',
          image: AppAssets.defaultProduct,
          title: 'Product',
          brand: 'Yalla',
          price: '0.00',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProductData _productWith({
  required List<Map<String, Object?>> variants,
  List<Map<String, Object?>> attributes = const [],
}) => ProductData.fromJson({
  'id': 'variant-product',
  'name': 'Variant product',
  'image': AppAssets.defaultProduct,
  'variants': variants,
  'attributes': attributes,
});

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
  Future<ApiResult<List<ProductData>>> getProducts({String? citySlug}) async =>
      const ApiResult.success([]);

  @override
  Future<ApiResult<List<ProductData>>> searchProducts(
    String query, {
    String? citySlug,
  }) async => const ApiResult.success([]);

  @override
  Future<ApiResult<List<CategoryData>>> getCategories() async =>
      const ApiResult.success([]);

  @override
  Future<ApiResult<List<BrandData>>> getBrands() async =>
      const ApiResult.success([]);
}

class _StaticProductRepository extends _EmptyProductRepository {
  _StaticProductRepository(this.product);

  final ProductData product;

  @override
  Future<ApiResult<ProductData>> getProduct(String idOrSlug) async =>
      ApiResult.success(product);
}

class _RetryProductRepository extends _EmptyProductRepository {
  var attempts = 0;

  @override
  Future<ApiResult<ProductData>> getProduct(String idOrSlug) async {
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
  Future<ApiResult<ProductData>> getProduct(String idOrSlug) async {
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
  Future<ApiResult<ProductData>> getProduct(String idOrSlug) async {
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
