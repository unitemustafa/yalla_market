import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/city_data.dart';
import '../../domain/usecases/location_usecases.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(this._useCases) : super(const LocationInitial());

  final LocationUseCases _useCases;

  /// Hydrates city state from an already-resolved city (e.g. from SplashCubit).
  void syncCity(CityData? city) =>
      emit(LocationReady(city, state.availableCities));

  Future<List<CityData>> loadAvailableCities() async {
    emit(LocationLoading(state.selectedCity, state.availableCities));
    final result = await _useCases.getAvailableCities();
    return result.when(
      success: (cities) {
        emit(LocationReady(state.selectedCity, cities));
        return cities;
      },
      failure: (failure) {
        emit(
          LocationFailure(
            failure.message,
            state.selectedCity,
            state.availableCities,
          ),
        );
        return state.availableCities;
      },
    );
  }

  Future<CityData?> loadSelectedCity() async {
    emit(LocationLoading(state.selectedCity, state.availableCities));

    final result = await _useCases.getSelectedCity();
    return result.when(
      success: (city) {
        emit(LocationReady(city, state.availableCities));
        return city;
      },
      failure: (failure) {
        emit(
          LocationFailure(
            failure.message,
            state.selectedCity,
            state.availableCities,
          ),
        );
        return state.selectedCity;
      },
    );
  }

  Future<bool> hasSeenCitySelection() async {
    final result = await _useCases.hasSeenCitySelection();
    return result.when(success: (seen) => seen, failure: (_) => false);
  }

  Future<void> markCitySelectionSeen() async {
    await _useCases.markCitySelectionSeen();
  }

  Future<bool> clearSelectedCity() async {
    final result = await _useCases.clearSelectedCity();
    return result.when(
      success: (_) {
        emit(LocationReady(null, state.availableCities));
        return true;
      },
      failure: (failure) {
        emit(
          LocationFailure(
            failure.message,
            state.selectedCity,
            state.availableCities,
          ),
        );
        return false;
      },
    );
  }

  Future<CityData?> selectCity(
    CityData city, {
    RegionSource source = RegionSource.manual,
  }) async {
    emit(LocationSaving(state.selectedCity, state.availableCities));

    final result = await _useCases.saveSelectedCity(city, source: source);
    return result.when(
      success: (savedCity) {
        emit(LocationReady(savedCity, state.availableCities));
        return savedCity;
      },
      failure: (failure) {
        emit(
          LocationFailure(
            failure.message,
            state.selectedCity,
            state.availableCities,
          ),
        );
        return null;
      },
    );
  }

  Future<CityData?> selectGeneralRegion() {
    return selectCity(CityData.general, source: RegionSource.general);
  }

  Future<CityData?> detectCurrentLocation() async {
    emit(LocationDetecting(state.selectedCity, state.availableCities));

    final result = await _useCases.detectCurrentLocation();
    return result.when(
      success: (city) {
        emit(LocationReady(city, state.availableCities));
        return city;
      },
      failure: (failure) {
        emit(
          LocationFailure(
            failure.message,
            state.selectedCity,
            state.availableCities,
          ),
        );
        return null;
      },
    );
  }

  Future<CityData?> previewCurrentLocation() async {
    final result = await _useCases.detectCurrentLocation(
      requestPermission: false,
    );
    return result.when(success: (city) => city, failure: (_) => null);
  }

  Future<CityData?> useCurrentLocation() async {
    emit(LocationDetecting(state.selectedCity, state.availableCities));

    final result = await _useCases.useCurrentLocation();
    return result.when(
      success: (city) {
        emit(LocationReady(city, state.availableCities));
        return city;
      },
      failure: (failure) {
        emit(
          LocationFailure(
            failure.message,
            state.selectedCity,
            state.availableCities,
          ),
        );
        return null;
      },
    );
  }

  Future<void> openAppSettings() async {
    await _useCases.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await _useCases.openLocationSettings();
  }
}
