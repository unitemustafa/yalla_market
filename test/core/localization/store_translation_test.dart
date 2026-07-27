import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

void main() {
  test('store subcategory empty state uses Egyptian Arabic', () {
    AppLanguageController.instance.value = AppLanguage.arabic;
    final translations = AppTranslations.current;

    expect(
      translations.phrase('No products in this section'),
      'لسه مفيش منتجات في القسم ده',
    );
    expect(
      translations.phrase('Try another section or choose All.'),
      'جرّب قسم تاني أو اختار «الكل».',
    );
  });
}
