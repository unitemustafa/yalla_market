import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/location/domain/usecases/location_usecases.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
import 'package:yalla_market/features/personalization/domain/entities/address.dart';
import 'package:yalla_market/features/personalization/domain/repositories/address_repository.dart';
import 'package:yalla_market/features/personalization/domain/usecases/address_usecases.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/address_cubit.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/add_new_address_view.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/address_location_picker_view.dart';

void main() {
  testWidgets('fits a compact iPhone viewport without layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeAddressRepository();
    await _pumpAddressView(
      tester,
      repository: repository,
      child: const AddNewAddressView(),
    );
    await tester.pumpAndSettle();

    expect(find.text('New address'), findsOneWidget);
    expect(find.text('Save address'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('saves a general address without GPS coordinates', (
    tester,
  ) async {
    final repository = _FakeAddressRepository();
    await _pumpAddressView(
      tester,
      repository: repository,
      child: const AddNewAddressView(),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(9));
    await tester.enterText(fields.at(0), 'Mansoura');
    await tester.enterText(fields.at(1), 'University District');
    await tester.enterText(fields.at(2), 'Nile Building');
    await tester.enterText(fields.at(3), '12');
    await tester.enterText(fields.at(4), '3');
    await tester.enterText(fields.at(5), '12 Tahrir St');
    await tester.enterText(fields.at(6), '+201000000001');
    await tester.enterText(fields.at(8), 'Home');

    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();

    final saved = repository.lastSavedAddress;
    expect(saved, isNotNull);
    expect(saved!.latitude, isNull);
    expect(saved.longitude, isNull);
    expect(saved.serviceCityId, isNull);
    expect(saved.deliveryAreaId, isNull);
    expect(saved.manualCity, 'Mansoura');
    expect(saved.manualArea, 'University District');
  });

  testWidgets('saves a new address with the confirmed map coordinates', (
    tester,
  ) async {
    final repository = _FakeAddressRepository();
    await _pumpAddressView(
      tester,
      repository: repository,
      child: const AddNewAddressView(
        initialLocation: SelectedMapLocation(
          latitude: 30.0444,
          longitude: 31.2357,
          formattedAddress: '12 Tahrir St, Cairo, Egypt',
          placeId: 'geo-home',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Cairo');
    await tester.enterText(fields.at(1), 'Downtown');
    await tester.enterText(fields.at(2), 'Nile Building');
    await tester.enterText(fields.at(3), '12');
    await tester.enterText(fields.at(4), '3');
    await tester.enterText(fields.at(5), '12 Tahrir St');
    await tester.enterText(fields.at(6), '+201000000001');
    await tester.enterText(fields.at(8), 'Home');

    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();

    expect(repository.lastSavedAddress?.latitude, 30.0444);
    expect(repository.lastSavedAddress?.longitude, 31.2357);
    expect(
      repository.lastSavedAddress?.formattedAddress,
      '12 Tahrir St, Cairo, Egypt',
    );
    expect(repository.lastSavedAddress?.placeId, 'geo-home');
  });
}

Future<void> _pumpAddressView(
  WidgetTester tester, {
  required _FakeAddressRepository repository,
  required Widget child,
}) async {
  final addressCubit = AddressCubit(_addressUseCases(repository));
  final locationCubit = LocationCubit(
    _locationUseCases(_FakeLocationRepository()),
  )..syncCity(CityData.general);
  addTearDown(addressCubit.close);
  addTearDown(locationCubit.close);
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: addressCubit),
        BlocProvider.value(value: locationCubit),
      ],
      child: MaterialApp(home: child),
    ),
  );
}

AddressUseCases _addressUseCases(AddressRepository repository) {
  return AddressUseCases(
    getAddresses: GetAddressesUseCase(repository),
    getSelectedAddress: GetSelectedAddressUseCase(repository),
    saveAddress: SaveAddressUseCase(repository),
    deleteAddress: DeleteAddressUseCase(repository),
    selectAddress: SelectAddressUseCase(repository),
  );
}

LocationUseCases _locationUseCases(LocationRepository repository) {
  return LocationUseCases(
    activateUser: ActivateLocationUserUseCase(repository as LocationUserScope),
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
  );
}

class _FakeAddressRepository implements AddressRepository {
  AddressData? lastSavedAddress;

  @override
  Future<ApiResult<List<AddressData>>> getAddresses() async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<AddressData?>> getSelectedAddress() async {
    return const ApiResult.success(null);
  }

  @override
  Future<ApiResult<List<AddressData>>> saveAddress(AddressData address) async {
    lastSavedAddress = address;
    return ApiResult.success([address.copyWith(id: 'address_1')]);
  }

  @override
  Future<ApiResult<List<AddressData>>> deleteAddress(String id) async {
    return const ApiResult.success([]);
  }

  @override
  Future<ApiResult<List<AddressData>>> selectAddress(String id) async {
    return const ApiResult.success([]);
  }
}

class _FakeLocationRepository implements LocationRepository, LocationUserScope {
  @override
  Future<ApiResult<void>> activateUser(String userId) async =>
      const ApiResult.success(null);

  @override
  Future<ApiResult<void>> clearSelectedCity() async =>
      const ApiResult.success(null);

  @override
  Future<ApiResult<CityData>> detectCurrentLocation({
    bool requestPermission = true,
  }) async => const ApiResult.success(CityData.general);

  @override
  Future<ApiResult<List<CityData>>> getAvailableCities() async =>
      const ApiResult.success(CityData.supported);

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async =>
      const ApiResult.success(CityData.general);

  @override
  Future<ApiResult<bool>> hasSeenCitySelection() async =>
      const ApiResult.success(true);

  @override
  Future<ApiResult<void>> markCitySelectionSeen() async =>
      const ApiResult.success(null);

  @override
  Future<ApiResult<void>> openAppSettings() async =>
      const ApiResult.success(null);

  @override
  Future<ApiResult<void>> openLocationSettings() async =>
      const ApiResult.success(null);

  @override
  Future<ApiResult<CityData>> saveSelectedCity(CityData city) async =>
      ApiResult.success(city);

  @override
  Future<ApiResult<CityData>> useCurrentLocation() async =>
      const ApiResult.success(CityData.general);
}
