import '../../core/network/api_endpoints.dart';

enum SharedContentType { product, offer, market }

class SharedContentDeepLink {
  const SharedContentDeepLink({
    required this.type,
    required this.id,
    this.variantId,
  });

  final SharedContentType type;
  final String id;
  final String? variantId;

  static SharedContentDeepLink? tryParse(Uri uri) {
    try {
      return _parse(uri);
    } on FormatException {
      return null;
    }
  }

  static SharedContentDeepLink? _parse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'yallamarket') {
      return _fromSegments(
        uri.host,
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList(),
        uri.queryParametersAll['variant'],
      );
    }
    if (scheme == 'http' || scheme == 'https') {
      final segments = uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (segments.length == 3 && segments.first == 'share') {
        return _fromSegments(segments[1], [
          segments[2],
        ], uri.queryParametersAll['variant']);
      }
    }
    return null;
  }

  static SharedContentDeepLink? _fromSegments(
    String rawType,
    List<String> segments,
    List<String>? variantValues,
  ) {
    if (segments.length != 1) return null;
    final parsedId = int.tryParse(segments.single);
    if (parsedId == null || parsedId <= 0) return null;
    final type = switch (rawType.toLowerCase()) {
      'products' => SharedContentType.product,
      'offers' => SharedContentType.offer,
      'markets' => SharedContentType.market,
      _ => null,
    };
    if (type == null) return null;
    final variant = variantValues?.length == 1
        ? int.tryParse(variantValues!.single)
        : null;
    return SharedContentDeepLink(
      type: type,
      id: parsedId.toString(),
      variantId:
          type == SharedContentType.product && variant != null && variant > 0
          ? variant.toString()
          : null,
    );
  }
}

abstract final class SharedContentLinks {
  static String product(String id, {String? variantId}) =>
      _build('products', id, variantId: variantId);

  static String offer(String id) => _build('offers', id);

  static String market(String id) => _build('markets', id);

  static String _build(String type, String id, {String? variantId}) {
    final encodedId = Uri.encodeComponent(id.trim());
    final root = ApiEndpoints.rootBaseUrl;
    final link = root.isEmpty
        ? 'yallamarket://$type/$encodedId'
        : '$root/share/$type/$encodedId/';
    final variant = int.tryParse(variantId?.trim() ?? '');
    if (variant == null || variant <= 0) return link;
    return Uri.parse(
      link,
    ).replace(queryParameters: {'variant': variant.toString()}).toString();
  }
}
