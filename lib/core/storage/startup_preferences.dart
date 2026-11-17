import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../errors/failure.dart';
import '../network/api_result.dart';

/// Local preferences are optional at startup; never hold the native splash open.
abstract final class StartupPreferences {
  static Future<ApiResult<SharedPreferences>> load({
    Duration timeout = const Duration(seconds: 3),
    Future<SharedPreferences> Function()? read,
  }) async {
    try {
      final preferences = await Future<SharedPreferences>.sync(
        read ?? SharedPreferences.getInstance,
      ).timeout(timeout);
      return ApiResult.success(preferences);
    } on TimeoutException {
      return const ApiResult.failure(
        NetworkFailure('Saved preferences took too long to load.'),
      );
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load saved preferences.'),
      );
    }
  }
}
