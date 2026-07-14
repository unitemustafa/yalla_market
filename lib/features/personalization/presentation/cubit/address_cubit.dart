import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/address_usecases.dart';
import 'address_state.dart';

class AddressCubit extends Cubit<AddressState> {
  AddressCubit(this._addressUseCases) : super(const AddressInitial());

  final AddressUseCases _addressUseCases;
  int _generation = 0;
  int? _loadingGeneration;

  void clearSession() {
    _generation++;
    _loadingGeneration = null;
    emit(const AddressInitial());
  }

  Future<void> loadAddresses() async {
    final generation = _generation;
    if (_loadingGeneration == generation) return;
    _loadingGeneration = generation;
    final staleAddresses = state.addresses;
    final staleSelectedId = state.selectedAddressId;
    emit(
      AddressLoading(
        addresses: staleAddresses,
        selectedAddressId: staleSelectedId,
      ),
    );

    try {
      final result = await _addressUseCases.getAddresses();
      if (!_isCurrent(generation)) return;
      await result.when(
        success: (addresses) async {
          var selectedAddressId = _selectedIdFrom(addresses);
          final selectedResult = await _addressUseCases.getSelectedAddress();
          if (!_isCurrent(generation)) return;
          selectedAddressId = selectedResult.when(
            success: (address) => address?.id ?? selectedAddressId,
            failure: (_) => selectedAddressId,
          );
          emit(
            AddressReady(
              addresses: addresses,
              selectedAddressId: selectedAddressId,
            ),
          );
        },
        failure: (failure) async {
          emit(
            AddressFailure(
              failure.message,
              addresses: staleAddresses,
              selectedAddressId: staleSelectedId,
            ),
          );
        },
      );
    } finally {
      if (_loadingGeneration == generation) {
        _loadingGeneration = null;
      }
    }
  }

  Future<bool> saveAddress(AddressData address) async {
    final generation = _generation;
    final isFirstAddress = address.id.trim().isEmpty && state.addresses.isEmpty;
    final result = await _addressUseCases.saveAddress(
      isFirstAddress ? address.copyWith(isDefault: true) : address,
    );
    return _emitAddresses(result, generation);
  }

  Future<bool> deleteAddress(String id) async {
    final generation = _generation;
    final result = await _addressUseCases.deleteAddress(id);
    return _emitAddresses(result, generation);
  }

  Future<bool> selectAddress(String id) async {
    final generation = _generation;
    final result = await _addressUseCases.selectAddress(id);
    return _emitAddresses(result, generation);
  }

  bool _emitAddresses(ApiResult<List<AddressData>> result, int generation) {
    if (!_isCurrent(generation)) return false;
    return result.when(
      success: (addresses) {
        emit(
          AddressReady(
            addresses: addresses,
            selectedAddressId: _selectedIdFrom(addresses),
          ),
        );
        return true;
      },
      failure: (failure) {
        emit(
          AddressFailure(
            failure.message,
            addresses: state.addresses,
            selectedAddressId: state.selectedAddressId,
          ),
        );
        return false;
      },
    );
  }

  bool _isCurrent(int generation) => generation == _generation && !isClosed;

  String? _selectedIdFrom(List<AddressData> addresses) {
    if (addresses.isEmpty) return null;
    for (final address in addresses) {
      if (address.isDefault) return address.id;
    }
    return addresses.first.id;
  }
}
