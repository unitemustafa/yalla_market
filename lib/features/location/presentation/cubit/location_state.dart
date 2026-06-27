import '../../domain/entities/city_data.dart';

sealed class LocationState {
  const LocationState(this.selectedCity, [this.availableCities = const []]);

  final CityData? selectedCity;
  final List<CityData> availableCities;
}

final class LocationInitial extends LocationState {
  const LocationInitial() : super(null);
}

final class LocationLoading extends LocationState {
  const LocationLoading(super.selectedCity, [super.availableCities]);
}

final class LocationSaving extends LocationState {
  const LocationSaving(super.selectedCity, [super.availableCities]);
}

final class LocationDetecting extends LocationState {
  const LocationDetecting(super.selectedCity, [super.availableCities]);
}

final class LocationReady extends LocationState {
  const LocationReady(super.selectedCity, [super.availableCities]);
}

final class LocationFailure extends LocationState {
  const LocationFailure(
    this.message,
    super.selectedCity, [
    super.availableCities,
  ]);

  final String message;
}
