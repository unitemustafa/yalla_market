import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/city_data.dart';
import '../../domain/entities/dismissed_region_suggestion.dart';
import '../../domain/usecases/location_usecases.dart';
import '../../domain/usecases/region_suggestion_usecases.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(this._useCases, {RegionSuggestionUseCases? regionSuggestions})
    : _regionSuggestions = regionSuggestions,
      super(const LocationInitial());

  final LocationUseCases _useCases;
  final RegionSuggestionUseCases? _regionSuggestions;
  static const _dismissedSuggestionTtl = Duration(hours: 24);
  bool _gpsSuggestionCheckedThisSession = false;
  final Set<String> _dismissedSuggestionKeys = {};
  String? _activeUserKey;

  Future<bool> activateUser(String userId) async {
    final result = await _useCases.activateUser(userId);
    final activated = result.when(success: (_) => true, failure: (_) => false);
    if (!activated) return false;

    _activeUserKey = userId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    _dismissedSuggestionKeys.clear();
    await _restoreDismissedSuggestion();
    return true;
  }

  /// Hydrates city state from an already-resolved city (e.g. from SplashCubit).
  void syncCity(CityData? city) =>
      emit(LocationReady(city, state.availableCities));

  void clearSession() {
    _gpsSuggestionCheckedThisSession = false;
    _dismissedSuggestionKeys.clear();
    _activeUserKey = null;
    emit(const LocationReady(null));
  }

  bool consumeGpsSuggestionSlot() {
    if (_gpsSuggestionCheckedThisSession) return false;
    _gpsSuggestionCheckedThisSession = true;
    return true;
  }

  bool wasSuggestionDismissed(CityData? current, CityData? detected) {
    return _dismissedSuggestionKeys.contains(_suggestionKey(current, detected));
  }

  Future<void> markSuggestionDismissed(
    CityData? current,
    CityData? detected,
  ) async {
    final suggestionKey = _suggestionKey(current, detected);
    _dismissedSuggestionKeys.add(suggestionKey);

    final activeUserKey = _activeUserKey;
    final regionSuggestions = _regionSuggestions;
    if (activeUserKey == null ||
        activeUserKey.isEmpty ||
        regionSuggestions == null) {
      return;
    }
    await regionSuggestions.saveDismissed(
      activeUserKey,
      DismissedRegionSuggestion(
        suggestionKey: suggestionKey,
        dismissedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _restoreDismissedSuggestion() async {
    final activeUserKey = _activeUserKey;
    final regionSuggestions = _regionSuggestions;
    if (activeUserKey == null ||
        activeUserKey.isEmpty ||
        regionSuggestions == null) {
      return;
    }
    final result = await regionSuggestions.getDismissed(activeUserKey);
    final suggestion = result.when(
      success: (value) => value,
      failure: (_) => null,
    );
    final suggestionKey = suggestion?.suggestionKey;
    final dismissedAt = suggestion?.dismissedAt.toUtc();
    final now = DateTime.now().toUtc();
    if (suggestionKey == null ||
        suggestionKey.isEmpty ||
        dismissedAt == null ||
        now.difference(dismissedAt) >= _dismissedSuggestionTtl) {
      await regionSuggestions.clearDismissed(activeUserKey);
      return;
    }
    _dismissedSuggestionKeys.add(suggestionKey);
  }

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
        emit(LocationFailure(failure.message, null, state.availableCities));
        return null;
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

  Future<GpsRegionDetection?> detectMarketRegionSuggestion() async {
    final useCase = _useCases.detectMarketRegion;
    if (useCase == null) return null;
    emit(LocationDetecting(state.selectedCity, state.availableCities));

    final result = await useCase();
    return result.when(
      success: (detection) {
        emit(LocationReady(state.selectedCity, state.availableCities));
        return detection;
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

  String _suggestionKey(CityData? current, CityData? detected) {
    return '${current?.slug ?? 'none'}:${current?.serviceCityId ?? ''}->'
        '${detected?.slug ?? 'none'}:${detected?.serviceCityId ?? ''}';
  }
}
