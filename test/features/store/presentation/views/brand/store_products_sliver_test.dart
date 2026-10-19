import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';
import 'package:yalla_market/features/store/domain/repositories/store_products_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_products_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_products_sliver.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../../helpers/cubit_factories.dart';

void main() {
  for (final width in [320.0, 430.0, 800.0]) {
    testWidgets('store products use three compact columns at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final products = List.generate(4, (i) => _product('product-$i'));
      final repository = _PagedRepository(
        (_, _) => ApiResult.success(_page(products)),
      );
      final cubit = StoreProductsCubit(GetStoreProductsUseCase(repository));
      addTearDown(cubit.close);
      await cubit.configure(marketId: 'market');
      await _pumpSliver(tester, cubit);

      final rects = List.generate(
        4,
        (i) => tester.getRect(_card('product-$i')),
      );
      expect(rects[1].top, rects[0].top);
      expect(rects[2].top, rects[0].top);
      expect(rects[3].top, greaterThan(rects[0].bottom));
      expect(rects[0].height, ProductCardVertical.compactGridMainAxisExtent);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('product_image_product-0')))
            .height,
        ProductCardVertical.compactImageHeight,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'keeps prior category cards visible until the replacement commits',
    (tester) async {
      final replacement = Completer<ApiResult<StoreProductPage>>();
      final repository = _PagedRepository((_, subcategoryId) {
        if (subcategoryId == 'new') {
          return replacement.future;
        }
        return ApiResult.success(_page([_product('old')], count: 1));
      });
      final cubit = StoreProductsCubit(GetStoreProductsUseCase(repository));
      addTearDown(cubit.close);
      await cubit.configure(marketId: 'market', subcategoryId: 'old');
      await _pumpSliver(tester, cubit);

      final pending = cubit.configure(marketId: 'market', subcategoryId: 'new');
      await tester.pump();
      expect(_card('old'), findsOneWidget);
      expect(_card('new'), findsNothing);

      replacement.complete(
        ApiResult.success(_page([_product('new')], count: 1)),
      );
      await pending;
      await tester.pumpAndSettle();
      expect(_card('old'), findsNothing);
      expect(_card('new'), findsOneWidget);
    },
  );

  testWidgets('additional-page failure preserves mounted cards and retries', (
    tester,
  ) async {
    var attempts = 0;
    final repository = _PagedRepository((page, _) {
      if (page == 1) {
        return ApiResult.success(
          _page([_product('one')], hasMore: true, count: 2),
        );
      }
      attempts++;
      return attempts == 1
          ? const ApiResult.failure(ServerFailure('offline'))
          : ApiResult.success(_page([_product('two')], count: 2));
    });
    final cubit = StoreProductsCubit(GetStoreProductsUseCase(repository));
    addTearDown(cubit.close);
    await cubit.configure(marketId: 'market');
    await _pumpSliver(tester, cubit);
    final original = tester.element(_card('one'));

    await cubit.loadMore();
    await tester.pump();
    expect(find.text('offline'), findsOneWidget);
    expect(identical(tester.element(_card('one')), original), isTrue);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.pages, [1, 2, 2]);
    expect(_card('two'), findsOneWidget);
  });
}

Future<void> _pumpSliver(WidgetTester tester, StoreProductsCubit cubit) async {
  final cart = makeCartCubit();
  final wishlist = makeWishlistCubit();
  addTearDown(cart.close);
  addTearDown(wishlist.close);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: cart),
          BlocProvider.value(value: wishlist),
        ],
        child: const Scaffold(
          body: CustomScrollView(
            slivers: [StoreProductsSliver(categoryKey: 'all')],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byWidgetPredicate(
  (widget) => widget is ProductCardVertical && widget.productId == id,
);

StoreProductPage _page(
  List<ProductData> products, {
  bool hasMore = false,
  int? count,
}) => StoreProductPage(
  products: products,
  count: count ?? products.length,
  hasMore: hasMore,
);
ProductData _product(String id) => ProductData(
  id: id,
  image: '',
  title: id,
  brand: 'Store',
  price: '10',
  oldPrice: null,
  discount: '',
  tags: const [],
);

class _PagedRepository implements StoreProductsRepository {
  _PagedRepository(this._handler);
  final FutureOr<ApiResult<StoreProductPage>> Function(int, String?) _handler;
  final List<int> pages = [];
  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async {
    pages.add(page);
    return await _handler(page, subcategoryId);
  }
}
