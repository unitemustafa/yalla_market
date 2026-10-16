import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';
import 'package:yalla_market/features/store/domain/repositories/store_products_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_products_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_products_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/brand/store_product_search_view.dart';
import 'package:yalla_market/core/presentation/widgets/states/app_state_view.dart';

void main() {
  late _SearchProductsRepository repository;

  setUp(() async {
    repository = _SearchProductsRepository();
    await sl.reset();
    sl.registerFactory<StoreProductsCubit>(
      () => StoreProductsCubit(GetStoreProductsUseCase(repository)),
    );
  });
  tearDown(() => sl.reset());

  testWidgets('loads the market page and queries after its debounce', (
    tester,
  ) async {
    await _pumpSearch(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('store_search_results')),
        matching: find.text('Pasta'),
      ),
      findsOneWidget,
    );
    expect(find.text('Cola'), findsOneWidget);
    expect(repository.calls.single.query, isEmpty);

    final field = find.byKey(const ValueKey('store_search_page_field'));
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      'Pasta',
    );
    await tester.pump(const Duration(milliseconds: 349));
    expect(repository.calls, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(repository.calls.last.query, 'Pasta');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('store_search_results')),
        matching: find.text('Pasta'),
      ),
      findsOneWidget,
    );
    expect(find.text('Cola'), findsNothing);
  });

  testWidgets('keeps Arabic empty content in dark RTL mode', (tester) async {
    await _pumpSearch(
      tester,
      locale: const Locale('ar'),
      theme: ThemeData.dark(),
    );
    final field = find.byKey(const ValueKey('store_search_page_field'));
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      'ط؛ظٹ± ظ…ظˆط¬ظˆط¯',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('a new query replaces prior rows without reopening search', (
    tester,
  ) async {
    await _pumpSearch(tester);
    final field = find.byKey(const ValueKey('store_search_page_field'));
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextField)),
      'Updated',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Updated pasta'), findsOneWidget);
    expect(find.text('Pasta'), findsNothing);
    expect(repository.calls.map((call) => call.query), ['', 'Updated']);
  });

  testWidgets('pull to refresh requests the first page again', (tester) async {
    await _pumpSearch(tester);
    await tester.drag(
      find.byKey(const ValueKey('store_search_results')),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();

    expect(repository.calls.map((call) => call.page), [1, 1]);
    expect(find.text('Pasta'), findsOneWidget);
  });

  testWidgets('product return preserves loaded pages and scroll offset', (
    tester,
  ) async {
    repository.largeCatalog = true;
    await _pumpSearch(tester);
    final scroll = tester
        .widget<CustomScrollView>(
          find.byKey(const ValueKey('store_search_results')),
        )
        .controller!;
    scroll.jumpTo(3000);
    await tester.pumpAndSettle();
    expect(repository.calls.map((call) => call.page), [1, 2]);
    final offset = scroll.offset;

    await tester.tap(find.textContaining('Item ').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('test_product_page')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('test_product_back')));
    await tester.pumpAndSettle();

    expect(scroll.offset, offset);
    expect(repository.calls.map((call) => call.page), [1, 2]);
    expect(find.textContaining('Item ').hitTestable(), findsWidgets);
  });
}

Future<void> _pumpSearch(
  WidgetTester tester, {
  Locale? locale,
  ThemeData? theme,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) => settings.name == AppRoutes.productDetail
          ? MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => Scaffold(
                key: const ValueKey('test_product_page'),
                body: Center(
                  child: TextButton(
                    key: const ValueKey('test_product_back'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ),
              ),
            )
          : null,
      locale: locale,
      theme: theme,
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: locale?.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: const StoreProductSearchView(market: _market),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _SearchProductsRepository implements StoreProductsRepository {
  final List<_SearchCall> calls = [];
  bool largeCatalog = false;
  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async {
    calls.add(_SearchCall(query, page));
    if (largeCatalog) {
      return ApiResult.success(
        StoreProductPage(
          products: List.generate(30, (index) {
            final id = (page - 1) * 30 + index;
            return ProductData(
              id: 'item-$id',
              image: AppAssets.defaultProduct,
              title: 'Item $id',
              brand: 'Store',
              price: '10',
              oldPrice: null,
              discount: '',
              tags: const [],
            );
          }),
          count: 60,
          hasMore: page == 1,
        ),
      );
    }
    final products = switch (query) {
      'Pasta' => const [_pasta],
      'Updated' => const [_updatedPasta],
      _ when query.isNotEmpty => const <ProductData>[],
      _ => const [_pasta, _cola],
    };
    return ApiResult.success(
      StoreProductPage(
        products: products,
        count: products.length,
        hasMore: false,
      ),
    );
  }
}

class _SearchCall {
  const _SearchCall(this.query, this.page);
  final String query;
  final int page;
}

const _pasta = ProductData(
  id: 'pasta',
  image: AppAssets.defaultProduct,
  title: 'Pasta',
  brand: 'Store',
  price: '120',
  oldPrice: null,
  discount: '',
  tags: [],
  description: 'Creamy chicken pasta',
);
const _updatedPasta = ProductData(
  id: 'pasta-updated',
  image: AppAssets.defaultProduct,
  title: 'Updated pasta',
  brand: 'Store',
  price: '120',
  oldPrice: null,
  discount: '',
  tags: [],
);
const _cola = ProductData(
  id: 'cola',
  image: AppAssets.defaultProduct,
  title: 'Cola',
  brand: 'Store',
  price: '30',
  oldPrice: null,
  discount: '',
  tags: [],
  description: 'Cold drink',
);
const _market = StoreMarketData(
  id: 'market',
  name: 'Store',
  branch: '',
  status: 'active',
  classificationId: 'food',
  products: [],
  image: AppAssets.defaultStore,
  coverImage: AppAssets.emptyStoreLight,
  accentColorValue: 0xFF013C7E,
);
