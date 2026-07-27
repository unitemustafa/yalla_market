abstract final class MapTilerMapConfig {
  static const apiKey = String.fromEnvironment('MAPTILER_API_KEY');
  static const userAgentPackageName = 'com.yallamarket.app';
  static const maxZoom = 20.0;

  static bool get isConfigured => apiKey.trim().isNotEmpty;

  static String tileUrl({required bool highDensity}) {
    final densitySuffix = highDensity ? '@2x' : '';
    final key = Uri.encodeQueryComponent(apiKey.trim());
    return 'https://api.maptiler.com/maps/streets-v2/256/'
        '{z}/{x}/{y}$densitySuffix.png?key=$key';
  }
}
