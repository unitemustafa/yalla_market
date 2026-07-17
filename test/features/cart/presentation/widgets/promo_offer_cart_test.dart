import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/domain/repositories/cart_repository.dart';
import 'package:yalla_market/features/cart/domain/usecases/cart_usecases.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/home/domain/entities/home_data.dart';
import 'package:yalla_market/features/home/presentation/widgets/promo_slider.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';

void main() {
  group('PromoSlider offer cart items', () {
    testWidgets('offer image stays clear behind dynamic content', (
      tester,
    ) async {
      final cartCubit = _cartCubit();
      await cartCubit.loadCartForUser('user-scrim');

      await tester.pumpWidget(_Subject(cartCubit: cartCubit, offerId: '5'));
      await tester.pump();

      final scrim = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('promo_offer_image_scrim')),
      );
      final gradient = (scrim.decoration as BoxDecoration).gradient!;
      final colors = (gradient as LinearGradient).colors;
      expect(colors[0].a, closeTo(0.30, 0.01));
      expect(colors[1].a, 0);
      expect(colors[2].a, closeTo(0.44, 0.01));

      await tester.pumpWidget(const SizedBox.shrink());
      await cartCubit.close();
    });

    testWidgets('offer card follows the compact reference layout', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 260));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cartCubit = _cartCubit();
      await cartCubit.loadCartForUser('user-layout');

      await tester.pumpWidget(
        _Subject(
          cartCubit: cartCubit,
          offerId: '5',
          endsAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await tester.pump();

      final badge = find.text('Discount - 15% off');
      final countdownLabel = find.text('day');
      final buyButton = find.byKey(const ValueKey('promo_offer_buy_button'));
      final countdown = find.byKey(const ValueKey('promo_offer_countdown'));
      expect(find.text('Buy now'), findsOneWidget);
      expect(find.text('Fresh offer'), findsNothing);
      expect(find.text('Daily discount'), findsNothing);
      expect(find.text('EGP 78'), findsNothing);
      expect(find.text('EGP 92'), findsNothing);
      expect(
        find.byKey(const ValueKey('promo_offer_background')),
        findsOneWidget,
      );
      expect(badge, findsOneWidget);
      expect(countdownLabel, findsOneWidget);
      expect(buyButton, findsOneWidget);
      expect(countdown, findsOneWidget);
      expect(
        tester.getRect(buyButton).overlaps(tester.getRect(countdown)),
        isFalse,
      );
      expect(
        tester.getTopLeft(countdownLabel).dy,
        greaterThan(tester.getTopLeft(badge).dy),
      );
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pump();
      await tester.tap(find.text('Buy now'));
      await tester.pumpAndSettle();
      expect(find.text('Fresh offer'), findsOneWidget);
      expect(find.text('Daily discount'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('After discount'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await cartCubit.close();
    });

    testWidgets('announcement card uses its CTA instead of buy now', (
      tester,
    ) async {
      final cartCubit = _cartCubit();
      await cartCubit.loadCartForUser('user-announcement');

      await tester.pumpWidget(
        _Subject(cartCubit: cartCubit, offerId: '9', announcement: true),
      );
      await tester.pump();

      expect(find.text('Watch campaign'), findsOneWidget);
      expect(find.text('Buy now'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await cartCubit.close();
    });

    testWidgets('offer details expose share and copy-link actions', (
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
      final cartCubit = _cartCubit();
      await cartCubit.loadCartForUser('user-share');

      await tester.pumpWidget(_Subject(cartCubit: cartCubit, offerId: '5'));
      await tester.tap(find.byKey(const ValueKey('promo_offer_card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppIcons.send_1));
      await tester.pumpAndSettle();

      expect(find.text('Share offer'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Copy link'), findsOneWidget);

      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();

      expect(copiedText, 'yallamarket://offers/5');
      expect(find.text('Offer link copied'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await cartCubit.close();
    });

    testWidgets('add offer to cart keeps numeric offer id', (tester) async {
      final cartCubit = _cartCubit();
      await cartCubit.loadCartForUser('user-a');

      await tester.pumpWidget(_Subject(cartCubit: cartCubit, offerId: '5'));
      await tester.tap(find.byKey(const ValueKey('promo_offer_card')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Checkout').last);
      await tester.tap(find.text('Checkout').last);
      await tester.pumpAndSettle();

      expect(cartCubit.state, hasLength(1));
      expect(cartCubit.state.single.id, '5');
      expect(cartCubit.state.single.productId, '5');
      expect(cartCubit.state.single.itemType, 'offer');
      expect(cartCubit.state.single.variantId, isNull);
      expect(cartCubit.state.single.title, 'Fresh offer');
      expect(cartCubit.state.single.offerProducts, hasLength(2));
      expect(
        cartCubit.state.single.offerProducts.map((product) => product.title),
        ['Chips', 'Harissa'],
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await cartCubit.close();
    });

    testWidgets(
      'invalid offer id shows validation failure and keeps cart empty',
      (tester) async {
        final cartCubit = _cartCubit();
        await cartCubit.loadCartForUser('user-a');

        await tester.pumpWidget(_Subject(cartCubit: cartCubit, offerId: 'bad'));
        await tester.tap(find.byKey(const ValueKey('promo_offer_card')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Checkout').last);
        await tester.tap(find.text('Checkout').last);
        await tester.pump();

        expect(cartCubit.state, isEmpty);
        expect(
          find.text('This offer cannot be added to cart right now.'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        await cartCubit.close();
      },
    );
  });
}

class _Subject extends StatelessWidget {
  const _Subject({
    required this.cartCubit,
    required this.offerId,
    this.endsAt,
    this.announcement = false,
  });

  final CartCubit cartCubit;
  final String offerId;
  final DateTime? endsAt;
  final bool announcement;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>.value(value: cartCubit),
        BlocProvider<LocationCubit>(
          create: (_) => _locationCubit()..syncCity(CityData.general),
        ),
      ],
      child: MaterialApp(
        routes: {
          AppRoutes.checkout: (_) => const Scaffold(body: Text('Checkout')),
        },
        home: Scaffold(
          body: PromoSlider(
            offers: [
              _offer(offerId, endsAt: endsAt, announcement: announcement),
            ],
          ),
        ),
      ),
    );
  }
}

HomeOfferData _offer(String id, {DateTime? endsAt, bool announcement = false}) {
  return HomeOfferData(
    id: id,
    title: 'Fresh offer',
    description: 'Daily discount',
    image: '',
    type: announcement ? 'announcement' : 'discount',
    discount: '15',
    startsAt: null,
    endsAt: endsAt,
    marketName: 'Fresh Market',
    announcementUrl: announcement ? 'https://example.com/campaign' : '',
    announcementCtaLabel: announcement ? 'Watch campaign' : '',
    products: const [
      ProductData(
        id: '7',
        image: 'chips.png',
        title: 'Chips',
        brand: 'Grocery Store',
        price: '20.00',
        oldPrice: null,
        discount: '0.00',
        tags: [],
        offerQuantity: 1,
      ),
      ProductData(
        id: '6',
        image: 'harissa.png',
        title: 'Harissa',
        brand: 'Dessert Store',
        price: '80.00',
        oldPrice: null,
        discount: '10.00',
        tags: [],
        offerQuantity: 1,
      ),
    ],
  );
}

CartCubit _cartCubit() {
  final repository = _FakeCartRepository();
  return CartCubit(
    CartUseCases(
      getItems: GetCartItemsUseCase(repository),
      addItem: AddCartItemUseCase(repository),
      incrementQuantity: IncrementCartItemQuantityUseCase(repository),
      decrementQuantity: DecrementCartItemQuantityUseCase(repository),
      removeItem: RemoveCartItemUseCase(repository),
      clearCart: ClearCartUseCase(repository),
    ),
  );
}

LocationCubit _locationCubit() {
  final repository = _FakeLocationRepository();
  return LocationCubit(
    LocationUseCases(
      activateUser: ActivateLocationUserUseCase(repository),
      getAvailableCities: GetAvailableCitiesUseCase(repository),
      getSelectedCity: GetSelectedCityUseCase(repository),
      hasSeenCitySelection: HasSeenCitySelectionUseCase(repository),
      markCitySelectionSeen: MarkCitySelectionSeenUseCase(repository),
      clearSelectedCity: ClearSelectedCityUseCase(repository),
      saveSelectedCity: SaveSelectedCityUseCase(repository),
      detectCurrentLocation: DetectCurrentLocationUseCase(repository),
      useCurrentLocation: UseCurrentLocationUseCase(repository),
      openAppSettings: OpenLocationAppSettingsUseCase(repository),
      openLocationSettings: OpenDeviceLocationSettingsUseCase(repository),
    ),
  );
}

class _FakeCartRepository implements CartRepository {
  final List<CartItemData> _items = [];

  @override
  Future<ApiResult<List<CartItemData>>> addItem(
    String userKey,
    CartItemData item,
    int quantityToAdd,
  ) async {
    _items.add(item.copyWith(quantity: quantityToAdd));
    return ApiResult.success(List.unmodifiable(_items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> clear(String userKey) async {
    _items.clear();
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<List<CartItemData>>> decrementQuantity(
    String userKey,
    String id,
  ) async {
    return ApiResult.success(List.unmodifiable(_items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> getItems(String userKey) async {
    return ApiResult.success(List.unmodifiable(_items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> incrementQuantity(
    String userKey,
    String id,
  ) async {
    return ApiResult.success(List.unmodifiable(_items));
  }

  @override
  Future<ApiResult<List<CartItemData>>> removeItem(
    String userKey,
    String id,
  ) async {
    _items.removeWhere((item) => item.id == id);
    return ApiResult.success(List.unmodifiable(_items));
  }
}

class _FakeLocationRepository implements LocationRepository, LocationUserScope {
  @override
  Future<ApiResult<void>> activateUser(String userId) async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> clearSelectedCity() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<CityData>> detectCurrentLocation({
    bool requestPermission = true,
  }) async {
    return const ApiResult.success(CityData.general);
  }

  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async {
    return const ApiResult.success(CityData.supported);
  }

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async {
    return const ApiResult.success(CityData.general);
  }

  @override
  Future<ApiResult<bool>> hasSeenCitySelection() async {
    return const ApiResult.success(true);
  }

  @override
  Future<ApiResult<void>> markCitySelectionSeen() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> openAppSettings() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> openLocationSettings() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<CityData>> saveSelectedCity(CityData city) async {
    return ApiResult.success(city);
  }

  @override
  Future<ApiResult<CityData>> useCurrentLocation() async {
    return const ApiResult.success(CityData.general);
  }
}
