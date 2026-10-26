import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/domain/usecases/cart_usecases.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';
import 'package:yalla_market/features/offers/domain/repositories/offer_repository.dart';
import 'package:yalla_market/features/offers/domain/usecases/get_offers_usecase.dart';
import 'package:yalla_market/features/offers/domain/usecases/get_offer_details_usecase.dart';
import 'package:yalla_market/features/offers/presentation/cubit/offer_catalog_cubit.dart';
import 'package:yalla_market/features/offers/presentation/widgets/promo_slider.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/store/domain/repositories/store_repository.dart';
import 'package:yalla_market/features/store/domain/usecases/get_store_usecase.dart';
import 'package:yalla_market/features/store/domain/usecases/get_market_usecase.dart';
import 'package:yalla_market/features/store/presentation/cubit/store_cubit.dart';
import 'stress_app.dart';
import 'stress_fixtures.dart';

OfferData offer(
  String id,
  List<ProductData> products, {
  bool summary = false,
}) => OfferData(
  id: id,
  title: 'Offer $id',
  description: 'Fixture',
  image: AppAssets.defaultOffer,
  type: 'discount',
  discount: '10',
  startsAt: null,
  endsAt: DateTime(2100),
  marketName: 'Fixture',
  products: products,
  isSummary: summary,
);

void main() {
  tearDown(() async {
    await sl.reset();
  });
  test(
    'concurrent store requests cannot leave an oversized inactive cache',
    () async {
      final repository = _Stores();
      final cubit = StoreCubit(
        GetStoreUseCase(repository),
        getMarket: GetMarketUseCase(repository),
        maxCachedMarkets: 3,
      );
      addTearDown(cubit.close);
      await cubit.loadStore();
      await Future.wait(
        List.generate(100, (i) => cubit.ensureMarket('${i + 1}')),
      );
      expect(
        cubit.state.data!.marketsFor('stress').length,
        lessThanOrEqualTo(3),
      );
    },
  );
  test(
    'visited store details are bounded while open routes remain pinned',
    () async {
      final repository = _Stores();
      final cubit = StoreCubit(
        GetStoreUseCase(repository),
        getMarket: GetMarketUseCase(repository),
        maxCachedMarkets: 3,
      );
      addTearDown(cubit.close);
      await cubit.loadStore();
      cubit.retainMarket('1');
      for (var id = 1; id <= 300; id++) {
        await cubit.ensureMarket('$id');
      }
      expect(cubit.state.data!.marketsFor('stress').map((i) => i.id), [
        '1',
        '298',
        '299',
        '300',
      ]);
      await cubit.loadStore(force: true);
      expect(cubit.state.data!.marketsFor('stress').length, 4);
      cubit.releaseMarket('1');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.data!.marketsFor('stress').length, 3);
      final previous = repository.requests;
      await cubit.ensureMarket('1');
      expect(repository.requests, previous + 1);
      expect(cubit.state.data!.marketsFor('stress').length, 3);
    },
  );
  testWidgets('50 offers use a bounded indicator window without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await configureStressApp(StressFixtures(productCount: 1, listCount: 0));
    await tester.pumpWidget(
      StressApp(
        home: Scaffold(
          body: PromoSlider(
            offers: List.generate(50, (i) => offer('$i', const [])),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.byType(AnimatedContainer).evaluate().length,
      lessThanOrEqualTo(9),
    );
    expect(find.text('1/50'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    '300 offer products build only visible rows and the last row remains reachable',
    (tester) async {
      final fixtures = StressFixtures(productCount: 300, listCount: 0);
      await configureStressApp(fixtures);
      await tester.pumpWidget(
        StressApp(
          home: Scaffold(
            body: PromoSlider(offers: [offer('1', fixtures.products)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('promo_offer_card')).first);
      await tester.pumpAndSettle();
      final rows = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_OfferProductRow',
      );
      expect(rows.evaluate().length, inInclusiveRange(1, 20));
      await tester.scrollUntilVisible(
        find.text(fixtures.products.last.title),
        500,
        scrollable: find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 100,
      );
      expect(find.text(fixtures.products.last.title), findsOneWidget);
      expect(rows.evaluate().length, lessThan(20));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'offer summary waits for detail before exposing checkout products',
    (tester) async {
      final fixtures = StressFixtures(productCount: 2, listCount: 0);
      await configureStressApp(fixtures);
      final repository = _Offers(offer('1', fixtures.products));
      final cubit = OfferCatalogCubit(
        GetOffersUseCase(repository),
        getDetails: GetOfferDetailsUseCase(repository),
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        StressApp(
          home: BlocProvider.value(
            value: cubit,
            child: Scaffold(
              body: PromoSlider(offers: [offer('1', const [], summary: true)]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.details, 0);
      await tester.tap(find.byKey(const ValueKey('promo_offer_card')).first);
      await tester.pumpAndSettle();
      expect(repository.details, 1);
      expect(find.text(fixtures.products.first.title), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('bounded campaign image decode uses physical layout bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = (await rootBundle.load(
      AppAssets.defaultOffer,
    )).buffer.asUint8List();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 320,
            height: 180,
            child: AppImage(
              bytes: bytes,
              width: double.infinity,
              decodeToLayoutBounds: true,
            ),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, 640);
    expect((image.image as ResizeImage).height, 360);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test(
    'cart clear discards decoded snapshot even if identical data is restored externally',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = CartRepositoryImpl();
      await repository.getItems('customer');
      await repository.addItem('customer', _item, 1);
      final first =
          (await repository.getItems('customer')
                  as ApiSuccess<List<CartItemData>>)
              .data
              .first;
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString('cart_user_customer')!;
      await repository.clear('customer');
      await preferences.setString('cart_user_customer', raw);
      final second =
          (await repository.getItems('customer')
                  as ApiSuccess<List<CartItemData>>)
              .data
              .first;
      expect(second.id, first.id);
      expect(identical(second, first), isFalse);
    },
  );
  test(
    'logout releases repository memory while preserving the persisted cart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = CartRepositoryImpl();
      final cubit = CartCubit(
        CartUseCases(
          getItems: GetCartItemsUseCase(repository),
          addItem: AddCartItemUseCase(repository),
          incrementQuantity: IncrementCartItemQuantityUseCase(repository),
          decrementQuantity: DecrementCartItemQuantityUseCase(repository),
          removeItem: RemoveCartItemUseCase(repository),
          clearCart: ClearCartUseCase(repository),
          releaseMemory: ReleaseCartMemoryUseCase(repository),
        ),
      );
      addTearDown(cubit.close);
      await cubit.loadCartForUser('customer');
      await cubit.addItem(_item, 1);
      final first = cubit.state.first;
      cubit.clearSession();
      await cubit.loadCartForUser('customer');
      expect(cubit.state.first.id, first.id);
      expect(identical(cubit.state.first, first), isFalse);
    },
  );
}

const _item = CartItemData(
  id: '1',
  image: '',
  brand: 'Fixture',
  title: 'Fixture',
  price: 10,
  quantity: 1,
);

class _Stores implements StoreRepository {
  final fixtures = StressFixtures(productCount: 1, listCount: 300);
  int requests = 0;
  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async =>
      ApiResult.success(
        StoreData(
          commonClassifications: [],
          classifications: fixtures.store.classifications,
          marketsByClassificationId: {},
        ),
      );
  @override
  Future<ApiResult<StoreMarketData>> getMarket(String id) async {
    requests++;
    return ApiResult.success(fixtures.markets[int.parse(id) - 1]);
  }

  @override
  Future<ApiResult<List<StoreMarketData>>> getClassificationMarkets(
    String id,
  ) async => const ApiResult.success([]);
}

class _Offers implements OfferRepository, OfferDetailRepository {
  _Offers(this.offer);
  final OfferData offer;
  int details = 0;
  @override
  Future<ApiResult<List<OfferData>>> getOffers() async =>
      ApiResult.success([offer]);
  @override
  Future<ApiResult<OfferData>> getOffer(String id) async {
    details++;
    return ApiResult.success(offer);
  }
}
