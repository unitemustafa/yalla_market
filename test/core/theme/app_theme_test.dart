import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:yalla_market/core/theme/app_theme.dart';

void main() {
  test('global typography is reduced by one point in both themes', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      expect(theme.textTheme.headlineLarge?.fontSize, AppFontSizes.headline);
      expect(theme.textTheme.titleLarge?.fontSize, AppFontSizes.title);
      expect(theme.textTheme.titleMedium?.fontSize, AppFontSizes.sectionTitle);
      expect(theme.textTheme.bodyLarge?.fontSize, AppFontSizes.bodyLarge);
      expect(theme.textTheme.bodyMedium?.fontSize, AppFontSizes.body);
      expect(theme.textTheme.bodySmall?.fontSize, AppFontSizes.small);
      expect(theme.textTheme.labelLarge?.fontSize, AppFontSizes.body);
      expect(theme.textTheme.labelMedium?.fontSize, AppFontSizes.label);
      expect(theme.textTheme.labelSmall?.fontSize, AppFontSizes.small);
    }
  });
}
