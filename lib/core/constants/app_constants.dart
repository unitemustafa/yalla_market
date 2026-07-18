abstract final class AppConstants {
  static const appName = 'Yalla Market';
  static const defaultPageSize = 20;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// The shared type scale used across Yalla Market.
///
/// Keep component text on this scale instead of introducing one-off sizes.
abstract final class AppFontSizes {
  static const micro = 8.0;
  static const caption = 10.0;
  static const small = 11.0;
  static const label = 12.0;
  static const body = 13.0;
  static const bodyLarge = 15.0;
  static const sectionTitle = 17.0;
  static const pageTitle = 20.0;
  static const subtitle = pageTitle;
  static const title = 23.0;
  static const headline = 27.0;
  static const display = 32.0;
}
