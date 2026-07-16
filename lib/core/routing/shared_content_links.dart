import '../network/api_endpoints.dart';

enum SharedContentType { product, offer }

class SharedContentDeepLink {
  const SharedContentDeepLink({required this.type, required this.id});

  final SharedContentType type;
  final String id;

  static SharedContentDeepLink? tryParse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'yallamarket') {
      return _fromSegments(
        uri.host,
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList(),
      );
    }
    if (scheme == 'http' || scheme == 'https') {
      final segments = uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (segments.length == 3 && segments.first == 'share') {
        return _fromSegments(segments[1], [segments[2]]);
      }
    }
    return null;
  }

  static SharedContentDeepLink? _fromSegments(
    String rawType,
    List<String> segments,
  ) {
    if (segments.length != 1) return null;
    final parsedId = int.tryParse(segments.single);
    if (parsedId == null || parsedId <= 0) return null;
    final type = switch (rawType.toLowerCase()) {
      'products' => SharedContentType.product,
      'offers' => SharedContentType.offer,
      _ => null,
    };
    if (type == null) return null;
    return SharedContentDeepLink(type: type, id: parsedId.toString());
  }
}

abstract final class SharedContentLinks {
  static String product(String id) => _build('products', id);

  static String offer(String id) => _build('offers', id);

  static String _build(String type, String id) {
    final encodedId = Uri.encodeComponent(id.trim());
    final root = ApiEndpoints.rootBaseUrl;
    if (root.isEmpty) return 'yallamarket://$type/$encodedId';
    return '$root/share/$type/$encodedId/';
  }
}
