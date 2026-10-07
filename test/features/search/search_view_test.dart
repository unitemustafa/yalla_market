import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/routing/app_route_arguments.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/products/product_cards/product_card_vertical.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';
import 'package:yalla_market/features/search/domain/entities/catalog_search_results.dart';
import 'package:yalla_market/features/search/domain/usecases/search_catalog_usecase.dart';
import 'package:yalla_market/features/search/presentation/cubit/catalog_search_cubit.dart';
import 'package:yalla_market/features/search/presentation/views/search_view.dart';
import 'package:yalla_market/features/store/presentation/widgets/store_market_card.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:yalla_market/features/wishlist/presentation/cubit/wishlist_cubit.dart';

import 'search_fixtures.dart';

void main() {
  late TestCatalogSearchRepository repository;
  late CatalogSearchCubit cubit;
  late List<BrandProductsRouteArgs> opened;
  setUp(() {
    repository = TestCatalogSearchRepository();
    cubit = CatalogSearchCubit(
      SearchCatalogUseCase(repository),
      GetSelectedCityUseCase(SearchLocationRepository()),
    );
    opened = [];
    addTearDown(cubit.close);
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider<CartCubit>(create: (_) => _CartCubit()),
          BlocProvider<WishlistCubit>(create: (_) => _WishlistCubit()),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const SearchView(),
          onGenerateRoute: (settings) {
            opened.add(settings.arguments! as BrandProductsRouteArgs);
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Destination')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  Finder filter(String name) => find.byKey(ValueKey('search_filter_$name'));

  testWidgets(
    'Arabic search has four tabs and filters all three result types',
    (tester) async {
      await mount(tester);
      for (final label in ['الكل', 'المنتجات', 'المحلات', 'الفئات']) {
        expect(find.text(label), findsOneWidget);
      }
      for (final name in ['all', 'products', 'markets', 'categories']) {
        final bounds = tester.getRect(filter(name));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(360));
      }
      expect(find.text('الأقسام'), findsNothing);
      await search(tester, 'مطاعم');
      expect(find.byType(ProductCardVertical), findsOneWidget);
      expect(find.byType(StoreMarketCard), findsOneWidget);
      expect(find.text('مطاعم'), findsWidgets);

      await tester.tap(filter('markets'));
      await tester.pumpAndSettle();
      expect(find.byType(StoreMarketCard), findsOneWidget);
      expect(find.byType(ProductCardVertical), findsNothing);

      await tester.tap(filter('products'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCardVertical), findsOneWidget);
      expect(find.byType(StoreMarketCard), findsNothing);

      await tester.tap(filter('categories'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCardVertical), findsNothing);
      expect(find.text('مطاعم'), findsWidgets);
      expect(repository.calls, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'category-only and market-only results open the correct destination',
    (tester) async {
      repository.handler = (query, _) => ApiResult.success(
        query == 'مطاعم'
            ? const CatalogSearchResults(categories: [searchCategory])
            : const CatalogSearchResults(markets: [searchMarket]),
      );
      await mount(tester);
      await search(tester, 'مطاعم');
      // TextField renders the query separately; tap the category result text.
      await tester.tap(find.text('مطاعم').last);
      await tester.pumpAndSettle();
      expect(opened.single.classificationId, '3');
      expect(opened.single.marketId, isNull);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await search(tester, 'النور');
      await tester.tap(find.byType(StoreMarketCard));
      await tester.pumpAndSettle();
      expect(opened.last.marketId, '7');
      expect(opened.last.classificationId, '3');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an empty selected tab shows an empty state and clearing restores suggestions',
    (tester) async {
      repository.handler = (_, _) => const ApiResult.success(
        CatalogSearchResults(categories: [searchCategory]),
      );
      await mount(tester);
      await search(tester, 'مطاعم');
      await tester.tap(filter('markets'));
      await tester.pumpAndSettle();
      expect(find.text('جرّب اسم منتج أو محل أو فئة.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('الأكثر بحثًا'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

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
