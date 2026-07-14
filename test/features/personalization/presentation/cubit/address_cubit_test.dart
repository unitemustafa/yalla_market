import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/personalization/domain/entities/address.dart';
import 'package:yalla_market/features/personalization/domain/repositories/address_repository.dart';
import 'package:yalla_market/features/personalization/domain/usecases/address_usecases.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/address_cubit.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/address_state.dart';

import '../../../../helpers/domain_fixtures.dart';

void main() {
  group('AddressCubit', () {
    test('loads addresses when requested', () async {
      final cubit = AddressCubit(
        _addressUseCases(_FakeAddressRepository(addresses: [sampleAddress])),
      );
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<AddressLoading>(), isA<AddressReady>()]),
      );

      await cubit.loadAddresses();
      await expectedStates;

      final state = cubit.state as AddressReady;
      expect(state.selectedAddress?.id, sampleAddress.id);
      await cubit.close();
    });

    test('saves and selects a new address', () async {
      final repository = _FakeAddressRepository();
      final cubit = AddressCubit(_addressUseCases(repository));
      await Future<void>.delayed(Duration.zero);

      final saved = await cubit.saveAddress(sampleAddress);

      expect(saved, isTrue);
      expect(cubit.state.selectedAddress?.id, sampleAddress.id);
      await cubit.close();
    });

    test('marks the first newly created address as default', () async {
      final repository = _FakeAddressRepository();
      final cubit = AddressCubit(_addressUseCases(repository));
      await Future<void>.delayed(Duration.zero);

      final saved = await cubit.saveAddress(
        sampleAddress.copyWith(id: '', isDefault: false),
      );

      expect(saved, isTrue);
      expect(repository.lastSavedAddress?.isDefault, isTrue);
      await cubit.close();
    });

    test(
      'uses the dedicated default-address lookup during initial load',
      () async {
        final repository = _FakeAddressRepository(addresses: [sampleAddress]);
        final cubit = AddressCubit(_addressUseCases(repository));
        await cubit.loadAddresses();

        expect(repository.getSelectedAddressCalls, 1);
        expect(cubit.state.selectedAddress?.id, sampleAddress.id);
        await cubit.close();
      },
    );

    test('keeps stale addresses when an operation fails', () async {
      final repository = _FakeAddressRepository(addresses: [sampleAddress]);
      final cubit = AddressCubit(_addressUseCases(repository));
      await cubit.loadAddresses();
      repository.nextFailure = const ServerFailure('Address API failed.');

      final selected = await cubit.selectAddress('missing');

      expect(selected, isFalse);
      final state = cubit.state as AddressFailure;
      expect(state.message, 'Address API failed.');
      expect(state.addresses.single.id, sampleAddress.id);
      await cubit.close();
    });

    test(
      'clearSession ignores an address response from the old session',
      () async {
        final loadDelay = Completer<void>();
        final repository = _FakeAddressRepository(
          addresses: [sampleAddress],
          loadDelay: loadDelay,
        );
        final cubit = AddressCubit(_addressUseCases(repository));

        final load = cubit.loadAddresses();
        cubit.clearSession();
        loadDelay.complete();
        await load;

        expect(cubit.state, isA<AddressInitial>());
        expect(cubit.state.addresses, isEmpty);
        await cubit.close();
      },
    );
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
  _FakeAddressRepository({
    List<AddressData> addresses = const [],
    this.loadDelay,
  }) : _addresses = List.of(addresses);

  final List<AddressData> _addresses;
  final Completer<void>? loadDelay;
  String? _selectedAddressId;
  Failure? nextFailure;
  AddressData? lastSavedAddress;
  int getSelectedAddressCalls = 0;

  @override
  Future<ApiResult<List<AddressData>>> getAddresses() async {
    await loadDelay?.future;
    return _result();
  }

  @override
  Future<ApiResult<AddressData?>> getSelectedAddress() async {
    getSelectedAddressCalls += 1;
    return ApiResult.success(_selectedAddress());
  }

  @override
  Future<ApiResult<List<AddressData>>> saveAddress(AddressData address) async {
    lastSavedAddress = address;
    final index = _addresses.indexWhere((item) => item.id == address.id);
    if (index == -1) {
      _addresses.add(address);
    } else {
      _addresses[index] = address;
    }
    _selectedAddressId = address.id;
    return _result();
  }

  @override
  Future<ApiResult<List<AddressData>>> deleteAddress(String id) async {
    _addresses.removeWhere((address) => address.id == id);
    return _result();
  }

  @override
  Future<ApiResult<List<AddressData>>> selectAddress(String id) async {
    _selectedAddressId = id;
    return _result();
  }

  Future<ApiResult<List<AddressData>>> _result() async {
    if (nextFailure case final failure?) {
      nextFailure = null;
      return ApiResult.failure(failure);
    }

    final selected = _selectedAddressId ?? _firstAddressId();
    return ApiResult.success(
      _addresses
          .map((address) => address.copyWith(isDefault: address.id == selected))
          .toList(growable: false),
    );
  }

  AddressData? _selectedAddress() {
    if (_addresses.isEmpty) return null;
    final selected = _selectedAddressId;
    if (selected == null) return _addresses.first;
    return _addresses.firstWhere(
      (address) => address.id == selected,
      orElse: () => _addresses.first,
    );
  }

  String? _firstAddressId() {
    if (_addresses.isEmpty) return null;
    return _addresses.first.id;
  }
}
