import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/dismissed_region_suggestion.dart';
import '../../domain/repositories/region_suggestion_repository.dart';

class RegionSuggestionPreferencesRepository
    implements RegionSuggestionRepository {
  static const _keyPrefix = 'location.dismissed_gps_suggestion';

  @override
  Future<ApiResult<DismissedRegionSuggestion?>> getDismissed(
    String userKey,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final suggestionKey = preferences.getString(_keyName(userKey));
      final dismissedAt = DateTime.tryParse(
        preferences.getString(_timestampName(userKey)) ?? '',
      )?.toUtc();
      if (suggestionKey == null ||
          suggestionKey.isEmpty ||
          dismissedAt == null) {
        return const ApiResult.success(null);
      }
      return ApiResult.success(
        DismissedRegionSuggestion(
          suggestionKey: suggestionKey,
          dismissedAt: dismissedAt,
        ),
      );
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not restore the dismissed region suggestion.'),
      );
    }
  }

  @override
  Future<ApiResult<void>> saveDismissed(
    String userKey,
    DismissedRegionSuggestion suggestion,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await Future.wait([
        preferences.setString(_keyName(userKey), suggestion.suggestionKey),
        preferences.setString(
          _timestampName(userKey),
          suggestion.dismissedAt.toUtc().toIso8601String(),
        ),
      ]);
      return const ApiResult.success(null);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not save the dismissed region suggestion.'),
      );
    }
  }

  @override
  Future<ApiResult<void>> clearDismissed(String userKey) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await Future.wait([
        preferences.remove(_keyName(userKey)),
        preferences.remove(_timestampName(userKey)),
      ]);
      return const ApiResult.success(null);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not clear the dismissed region suggestion.'),
      );
    }
  }

  String _keyName(String userKey) => '$_keyPrefix.key.$userKey';

  String _timestampName(String userKey) => '$_keyPrefix.at.$userKey';
}
