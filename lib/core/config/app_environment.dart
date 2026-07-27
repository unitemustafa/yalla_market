import 'package:flutter/foundation.dart';

import '../network/api_endpoints.dart';
import 'maptiler_map_config.dart';

abstract final class AppEnvironment {
  static bool get hasApiBaseUrl => ApiEndpoints.rootBaseUrl.isNotEmpty;

  static bool get useDemoRepositories => kDebugMode && !hasApiBaseUrl;

  static void validate() {
    if (kReleaseMode && !hasApiBaseUrl) {
      throw StateError(
        'API_BASE_URL is required for release builds. '
        'Provide it with --dart-define=API_BASE_URL=<url> or '
        '--dart-define-from-file=env/production.json.',
      );
    }
    if (kReleaseMode && !MapTilerMapConfig.isConfigured) {
      throw StateError(
        'MAPTILER_API_KEY is required for release builds. '
        'Provide it with --dart-define=MAPTILER_API_KEY=<key> or '
        '--dart-define-from-file=env/production.json.',
      );
    }
  }
}
