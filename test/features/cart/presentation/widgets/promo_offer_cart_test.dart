import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
    testWidgets('add offer to cart keeps numeric offer id', (tester) async {
      final cartCubit = _cartCubit();
      await cartCubit.loadCartForUser('user-a');

      await tester.pumpWidget(_Subject(cartCubit: cartCubit, offerId: '5'));
      await tester.tap(find.text('Fresh offer').first);
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
        await tester.tap(find.text('Fresh offer').first);
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
  const _Subject({required this.cartCubit, required this.offerId});

  final CartCubit cartCubit;
  final String offerId;

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
        home: Scaffold(body: PromoSlider(offers: [_offer(offerId)])),
      ),
    );
  }
}

HomeOfferData _offer(String id) {
  return HomeOfferData(
    id: id,
    title: 'Fresh offer',
    description: 'Daily discount',
    image: '',
    type: 'discount',
    discount: '15',
    startsAt: null,
    endsAt: null,
    marketName: 'Fresh Market',
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
