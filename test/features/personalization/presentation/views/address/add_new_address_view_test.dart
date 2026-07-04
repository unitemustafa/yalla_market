import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/personalization/domain/entities/address.dart';
import 'package:yalla_market/features/personalization/domain/repositories/address_repository.dart';
import 'package:yalla_market/features/personalization/domain/usecases/address_usecases.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/address_cubit.dart';
import 'package:yalla_market/features/personalization/presentation/views/address/add_new_address_view.dart';

void main() {
  testWidgets('saves a general address without GPS coordinates', (
    tester,
  ) async {
    final repository = _FakeAddressRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AddressCubit(_addressUseCases(repository)),
          child: const AddNewAddressView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(5));
    await tester.enterText(fields.at(0), 'Home');
    await tester.enterText(fields.at(2), '12 Tahrir St');
    await tester.enterText(fields.at(3), 'Mansoura');
    await tester.enterText(fields.at(4), 'University District');

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
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
