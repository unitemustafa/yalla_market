import '../network/api_endpoints.dart';

abstract final class LegalUrls {
  static Uri? get privacy => _fromRoot('/privacy/');
  static Uri? get terms => _fromRoot('/terms/');
  static Uri? get accountDeletion => _fromRoot('/account-deletion/');

  static Uri? _fromRoot(String path) {
    final root = ApiEndpoints.rootBaseUrl;
    if (root.isEmpty) return null;
    final uri = Uri.tryParse('$root$path');
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    return uri;
  }
}
