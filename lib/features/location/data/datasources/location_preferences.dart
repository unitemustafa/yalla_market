import 'package:shared_preferences/shared_preferences.dart';

class LocationPreferences {
  static const selectedCitySlugKey = 'location.selected_city_slug';
  static const selectedCityNameKey = 'location.selected_city_name';
  static const selectedRegionSourceKey = 'location.selected_region_source';
  static const citySelectionSeenKey = 'location.city_selection_seen';
  String? _activeUserId;

  Future<void> activateUser(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID is required.');
    }

    _activeUserId = normalizedUserId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final preferences = await SharedPreferences.getInstance();
    final scopedSlugKey = _scopedKey(selectedCitySlugKey);
    if (preferences.containsKey(scopedSlugKey) ||
        !preferences.containsKey(selectedCitySlugKey)) {
      return;
    }

    final legacySlug = preferences.getString(selectedCitySlugKey);
    final legacyName = preferences.getString(selectedCityNameKey);
    final legacySource = preferences.getString(selectedRegionSourceKey);
    final legacySeen = preferences.getBool(citySelectionSeenKey);
    if (legacySlug != null) {
      await preferences.setString(scopedSlugKey, legacySlug);
    }
    if (legacyName != null) {
      await preferences.setString(_scopedKey(selectedCityNameKey), legacyName);
    }
    if (legacySource != null) {
      await preferences.setString(
        _scopedKey(selectedRegionSourceKey),
        legacySource,
      );
    }
    if (legacySeen != null) {
      await preferences.setBool(_scopedKey(citySelectionSeenKey), legacySeen);
    }
    await Future.wait([
      preferences.remove(selectedCitySlugKey),
      preferences.remove(selectedCityNameKey),
      preferences.remove(selectedRegionSourceKey),
      preferences.remove(citySelectionSeenKey),
    ]);
  }

  Future<String?> getSelectedCitySlug() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_scopedKey(selectedCitySlugKey));
  }

  Future<String?> getSelectedCityName() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_scopedKey(selectedCityNameKey));
  }

  Future<String?> getSelectedRegionSource() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_scopedKey(selectedRegionSourceKey));
  }

  Future<bool> hasSeenCitySelection() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_scopedKey(citySelectionSeenKey)) ?? false;
  }

  Future<void> markCitySelectionSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scopedKey(citySelectionSeenKey), true);
  }

  Future<void> clearSelectedCity() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(_scopedKey(selectedCitySlugKey)),
      preferences.remove(_scopedKey(selectedCityNameKey)),
      preferences.remove(_scopedKey(selectedRegionSourceKey)),
      preferences.remove(_scopedKey(citySelectionSeenKey)),
    ]);
  }

  Future<void> setSelectedCity(
    String slug,
    String name, {
    required String source,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scopedKey(citySelectionSeenKey), true);
    await preferences.setString(_scopedKey(selectedCitySlugKey), slug);
    await preferences.setString(_scopedKey(selectedCityNameKey), name);
    await preferences.setString(_scopedKey(selectedRegionSourceKey), source);
  }

  String _scopedKey(String key) {
    final userId = _activeUserId;
    return userId == null ? key : '$key.user.$userId';
  }
}
