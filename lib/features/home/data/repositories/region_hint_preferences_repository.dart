import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/repositories/region_hint_repository.dart';

class RegionHintPreferencesRepository implements RegionHintRepository {
  static const _prefix = 'home.region_hint_seen.';

  String _key(String userId) => '$_prefix${Uri.encodeComponent(userId)}';

  @override
  Future<ApiResult<bool>> hasSeen(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return ApiResult.success(preferences.getBool(_key(userId)) ?? false);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load region hint state.'),
      );
    }
  }

  @override
  Future<ApiResult<void>> markSeen(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(_key(userId), true);
      if (saved) return const ApiResult.success(null);
    } catch (_) {
      // Report storage failures through the feature's typed result.
    }
    return const ApiResult.failure(
      UnknownFailure('Could not save region hint state.'),
    );
  }
}
