import 'package:flutter_map/flutter_map.dart';

MapCachingProvider appMapCachingProvider() {
  return BuiltInMapCachingProvider.getOrCreateInstance(
    maxCacheSize: 64 * 1024 * 1024,
    overrideFreshAge: const Duration(days: 7),
  );
}

NetworkTileProvider createAppMapTileProvider() {
  return NetworkTileProvider(
    abortObsoleteRequests: true,
    cachingProvider: appMapCachingProvider(),
  );
}
