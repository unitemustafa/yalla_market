import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/theme/app_theme.dart';

void main() {
  test('global typography is reduced by one point in both themes', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      expect(theme.textTheme.headlineLarge?.fontSize, 27);
      expect(theme.textTheme.titleLarge?.fontSize, 23);
      expect(theme.textTheme.titleMedium?.fontSize, 17);
      expect(theme.textTheme.bodyLarge?.fontSize, 15);
      expect(theme.textTheme.bodyMedium?.fontSize, 13);
      expect(theme.textTheme.bodySmall?.fontSize, 11);
    }
  });
}
