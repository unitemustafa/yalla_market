import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/di/service_locator.dart';
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
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    final cartItem = cartCubit.state.singleWhere(
      (item) => item.title == 'شوربة خضار',
    );
    expect(cartItem.id, 'variant_2');
    expect(cartItem.productId, 'product_1');
    expect(cartItem.variantId, 'variant_2');
    expect(cartItem.marketId, 'market_1');
    expect(cartItem.price, 735);
    expect(cartItem.quantity, 2);
    expect(cartItem.attributes, hasLength(1));
    expect(cartItem.attributes.single.label, 'الحصة');
    expect(cartItem.attributes.single.value, 'عائلية');
  });
}

class _FakeProductRepository implements ProductRepository {
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

  @override
  Future<ApiResult<List<ProductData>>> getProducts({String? citySlug}) async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<List<ProductData>>> searchProducts(
    String query, {
    String? citySlug,
  }) async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<List<CategoryData>>> getCategories() async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<List<BrandData>>> getBrands() async {
    return const ApiResult.success([]);
  }
}
