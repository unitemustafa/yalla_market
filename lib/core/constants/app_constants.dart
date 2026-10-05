abstract final class AppConstants {
  static const appName = 'Yalla Market';
}

abstract final class AppRadius {
  static const md = 8.0;
}

/// Shared category layout measured from the reference at a 360 logical-pixel width.
abstract final class AppCategoryLayout {
  static const height = 84.0;
  static const cardWidth = 76.0;
  static const iconSize = 56.0;
  static const cornerRadius = 12.0;
  static const spacing = 8.0;
  static const rowSpacing = 7.0;
  static const columns = 4;
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
}
