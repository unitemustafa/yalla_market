import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/location/data/repositories/location_repository_impl.dart';
import 'package:yalla_market/features/location/di/location_di.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';

void main() {
  test('demo location selection stays local without an API client', () async {
    SharedPreferences.setMockInitialValues({});
    final sl = GetIt.asNewInstance();
    registerLocationDependencies(sl, useDemoRepositories: true);
    final repository = sl<LocationRepositoryImpl>();

    final cities = await repository.getAvailableCities();
    cities.when(
      success: (values) => expect(values, isNotEmpty),
      failure: (error) => fail(error.message),
    );

    final saved = await repository.saveSelectedCity(CityData.general);
    saved.when(
      success: (city) => expect(city.isGeneral, isTrue),
      failure: (error) => fail(error.message),
    );

    final selected = await repository.getSelectedCity();
    selected.when(
      success: (city) => expect(city?.isGeneral, isTrue),
      failure: (error) => fail(error.message),
    );
  });
}
