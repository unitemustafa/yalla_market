/// A normalized focal point supplied by the media API.
///
/// Keeping this value independent of Flutter lets domain entities describe the
/// intended crop without choosing how a particular screen renders it.
class MediaFocalPoint {
  const MediaFocalPoint({required this.x, required this.y});

  static const center = MediaFocalPoint(x: 0.5, y: 0.5);
  static const topCenter = MediaFocalPoint(x: 0.5, y: 0);

  final double x;
  final double y;

  factory MediaFocalPoint.fromJson(
    Object? value, {
    MediaFocalPoint fallback = center,
  }) {
    if (value is! Map) return fallback;
    final x = _normalized(value['x']);
    final y = _normalized(value['y']);
    if (x == null || y == null) return fallback;
    return MediaFocalPoint(x: x, y: y);
  }

  static double? _normalized(Object? value) {
    final number = switch (value) {
      num value => value.toDouble(),
      String value => double.tryParse(value),
      _ => null,
    };
    if (number == null || !number.isFinite) return null;
    return number.clamp(0, 1).toDouble();
  }
}
