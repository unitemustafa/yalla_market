import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';
import 'package:yalla_market/features/search/domain/entities/catalog_search_results.dart';
import 'package:yalla_market/features/search/domain/usecases/search_catalog_usecase.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_cubit.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_state.dart';
import 'package:yalla_market/features/search/presentation/views/search_view.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import '../../search_fixtures.dart';

void main() {
  late TestCatalogSearchRepository repository;
  late CatalogSearchCubit cubit;

  setUp(() {
    repository = TestCatalogSearchRepository();
    cubit = CatalogSearchCubit(
      SearchCatalogUseCase(repository),
      GetSelectedCityUseCase(SearchLocationRepository()),
    );
  });

  tearDown(() => cubit.close());

  Future<void> mount(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider<CartCubit>(create: (_) => _CartCubit()),
          BlocProvider<WishlistCubit>(create: (_) => _WishlistCubit()),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SearchView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('catalog_search_field')),
      'product',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  Finder card(String id) => find.byWidgetPredicate(
    (widget) => widget is ProductCardVertical && widget.productId == id,
  );

  testWidgets(
    'Given visible products when loading more starts and fails then existing cards are not rebuilt',
    (tester) async {
      final nextPage = Completer<ApiResult<CatalogSearchResults>>();
      repository.handler = (_, page) => page == 1
          ? const ApiResult.success(
              CatalogSearchResults(products: [_first], hasMoreProducts: true),
            )
          : nextPage.future;
      await mount(tester);
      await search(tester);
      final beforeElement = tester.element(card('one'));
      final beforeWidget = tester.widget<ProductCardVertical>(card('one'));

      final pending = cubit.loadMore();
      await tester.pump();
      expect(tester.element(card('one')), same(beforeElement));
      expect(
        tester.widget<ProductCardVertical>(card('one')),
        same(beforeWidget),
      );
      expect((cubit.state as CatalogSearchReady).loadingMore, isTrue);

      nextPage.complete(const ApiResult.failure(ServerFailure('offline')));
      await pending;
      await tester.pump();

      expect(tester.element(card('one')), same(beforeElement));
      expect(
        tester.widget<ProductCardVertical>(card('one')),
        same(beforeWidget),
      );
      expect((cubit.state as CatalogSearchReady).moreError, 'offline');
    },
  );

  testWidgets(
    'Given an appended page when it completes then the summary updates and existing cards retain identity',
    (tester) async {
      final nextPage = Completer<ApiResult<CatalogSearchResults>>();
      repository.handler = (_, page) => page == 1
          ? const ApiResult.success(
              CatalogSearchResults(products: [_first], hasMoreProducts: true),
            )
          : nextPage.future;
      await mount(tester);
      await search(tester);
      final beforeElement = tester.element(card('one'));
      final beforeWidget = tester.widget<ProductCardVertical>(card('one'));

      final pending = cubit.loadMore();
      await tester.pump();
      nextPage.complete(
        const ApiResult.success(
          CatalogSearchResults(products: [_second], hasMoreProducts: false),
        ),
      );
      await pending;
      await tester.pumpAndSettle();

      expect(cubit.state.results.products, hasLength(2));
      expect(find.text('2 results for "product"'), findsOneWidget);
      expect(tester.element(card('one')), same(beforeElement));
      expect(
        tester.widget<ProductCardVertical>(card('one')),
        same(beforeWidget),
      );
      expect(card('two'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

const _first = ProductData(
  id: 'one',
  image: AppAssets.defaultProduct,
  title: 'First',
  brand: 'Market',
  price: '10',
  oldPrice: null,
  discount: '',
  tags: [],
);

const _second = ProductData(
  id: 'two',
  image: AppAssets.defaultProduct,
  title: 'Second',
  brand: 'Market',
  price: '20',
  oldPrice: null,
  discount: '',
  tags: [],
);

class _CartCubit extends Cubit<List<CartItemData>> implements CartCubit {
  _CartCubit() : super(const []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WishlistCubit extends Cubit<List<WishlistItem>>
    implements WishlistCubit {
  _WishlistCubit() : super(const []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
