/// Canonical aspect ratios shared by every responsive image slot.
///
/// Raster dimensions are intentionally not stored here: Flutter lays content
/// out in logical pixels and the image pipeline selects an appropriate cached
/// resolution for the current device pixel ratio. The upload dimensions that
/// correspond to these ratios live in the dashboard media guide.
abstract final class AppMediaSpecs {
  static const double squareAspectRatio = 1;
  static const double offerBannerAspectRatio = 8 / 3;
  static const double campaignMediaAspectRatio = 16 / 9;
}
