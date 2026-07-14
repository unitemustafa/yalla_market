const _responsiveWidthBuckets = <int>[
  96,
  160,
  256,
  384,
  640,
  960,
  1280,
  1600,
  2048,
];

int _responsiveWidth(int requestedWidth) {
  final width = requestedWidth.clamp(1, _responsiveWidthBuckets.last);
  return _responsiveWidthBuckets.firstWhere(
    (candidate) => candidate >= width,
    orElse: () => _responsiveWidthBuckets.last,
  );
}

String optimizedCloudinaryImageUrl(String source, {int? targetWidth}) {
  final uri = Uri.tryParse(source);
  if (uri == null || uri.host.toLowerCase() != 'res.cloudinary.com') {
    return source;
  }

  const marker = '/image/upload/';
  final markerIndex = uri.path.indexOf(marker);
  if (markerIndex < 0) return source;

  final insertionIndex = markerIndex + marker.length;
  final remainder = uri.path.substring(insertionIndex);
  if (remainder.startsWith('f_auto,q_auto')) return source;

  final transformations = <String>['f_auto', 'q_auto'];
  if (targetWidth != null && targetWidth > 0) {
    transformations
      ..add('c_limit')
      ..add('w_${_responsiveWidth(targetWidth)}');
  }

  final path =
      '${uri.path.substring(0, insertionIndex)}'
      '${transformations.join(',')}/$remainder';
  return uri.replace(path: path).toString();
}
