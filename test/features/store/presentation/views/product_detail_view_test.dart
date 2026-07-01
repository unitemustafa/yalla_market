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
  testWidgets('renders product details and adds the selected item to cart', (
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
            title: 'Running Shoe',
            brand: 'Yalla',
            price: 'EGP 1200',
            oldPrice: 'EGP 1500',
            discount: '20%',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Running Shoe'), findsWidgets);
    expect(find.text('Reviews & Ratings'), findsNothing);
    expect(find.text('Add to Bag'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.add).last);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pumpAndSettle();

    final cartItem = cartCubit.state.singleWhere(
      (item) => item.title == 'Running Shoe',
    );
    expect(cartItem.id, 'variant_1');
    expect(cartItem.productId, 'product_1');
    expect(cartItem.variantId, 'variant_1');
    expect(cartItem.marketId, 'market_1');
  });
}

class _FakeProductRepository implements ProductRepository {
  @override
  Future<ApiResult<ProductData>> getProduct(String idOrSlug) async {
    return const ApiResult.success(
      ProductData(
        id: 'product_1',
        image: AppAssets.temporaryMarketPlaceholder,
        title: 'Running Shoe',
        brand: 'Yalla',
        price: 'EGP 1200',
        oldPrice: 'EGP 1500',
        discount: '20%',
        tags: ['shoe'],
        marketId: 'market_1',
        variants: [
          ProductVariantData(id: 'variant_1', price: '1200.00', sku: 'SHOE-1'),
        ],
      ),
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
