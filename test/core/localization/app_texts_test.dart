import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_text_catalog.dart';
import 'package:yalla_market/core/localization/app_texts_ar.dart' as ar;
import 'package:yalla_market/core/localization/app_texts_en.dart' as en;
import 'package:yalla_market/core/localization/app_translations.dart';

void main() {
  late AppLanguage previousLanguage;

  setUp(() {
    previousLanguage = AppLanguageController.instance.value;
    AppLanguageController.instance.value = AppLanguage.arabic;
  });

  tearDown(() {
    AppLanguageController.instance.value = previousLanguage;
  });

  test(
    'named constants are available in matching sections in both languages',
    () {
      expect(ar.BrandTexts.appName, 'يلا ماركت');
      expect(en.BrandTexts.appName, 'Yalla Market');
      expect(ar.CommonTexts.retry, 'حاول تاني');
      expect(en.CommonTexts.retry, 'Retry');
      expect(AppTextCatalog.phrases['Retry'], (
        ar: ar.CommonTexts.retry,
        en: en.CommonTexts.retry,
      ));
      expect(AppTextCatalog.phrases['Invalid email or password.'], (
        ar: ar.AuthTexts.invalidCredentials,
        en: en.AuthTexts.invalidCredentials,
      ));
    },
  );

  test(
    'all catalog phrases reach the public translation API in both languages',
    () {
      for (final language in AppLanguage.values) {
        AppLanguageController.instance.value = language;
        for (final entry in AppTextCatalog.phrases.entries) {
          expect(
            AppTranslations.current.phrase(entry.key),
            language.isArabic ? entry.value.ar : entry.value.en,
            reason: '${language.code}: ${entry.key}',
          );
        }
      }
    },
  );

  test('keyed getters read the selected language catalog', () {
    for (final language in AppLanguage.values) {
      AppLanguageController.instance.value = language;
      final translations = AppTranslations.current;
      expect(
        translations.appName,
        language.isArabic ? ar.BrandTexts.appName : en.BrandTexts.appName,
      );
      expect(
        translations.onboardingTitle1,
        language.isArabic
            ? ar.OnboardingTexts.onboardingTitle1
            : en.OnboardingTexts.onboardingTitle1,
      );
      expect(
        translations.signIn,
        language.isArabic ? ar.AuthTexts.signIn : en.AuthTexts.signIn,
      );
      expect(
        translations.passwordWeak,
        language.isArabic
            ? ar.AuthTexts.passwordWeak
            : en.AuthTexts.passwordWeak,
      );
    }
  });

  test(
    'legacy dynamic phrases preserve their interpolation and formatting',
    () {
      const examples = <String, String>{
        'View Nike products': 'اعرض منتجات Nike',
        '02 products': '02 منتج',
        '1 product': '1 منتج',
        '2 stores': '2 محل',
        '1 store': '1 محل',
        '2 markets': '2 سوق',
        '1 market': '1 سوق',
        '2 offers': '2 عرض',
        '1 offer': '1 عرض',
        'Page 2 of 3': 'صفحة 2 من 3',
        '2 items': '2 منتج',
        '1 item': '1 منتج',
        '2 item(s) added to cart': 'تمت إضافة 2 منتج للسلة',
        'Remove Home from your saved delivery locations?':
            'تحذف Home من عناوين التوصيل المحفوظة؟',
        'Home is selected for checkout.': 'Home محدد للدفع.',
        'Qty 02': 'الكمية 02',
        'No route defined for /missing': 'مفيش مسار باسم /missing',
        'You can change your username again on 2026-10-03':
            'تقدر تغيّر اسم المستخدم تاني في 2026-10-03.',
        'Your E-Mail has been saved.': 'تم حفظ الإيميل.',
        'No Nike products yet': 'لسه مفيش منتجات من Nike',
        'No Groceries items yet': 'لسه مفيش عناصر في Groceries',
        'Link copied': 'تم نسخ Link',
        'Fresh Nike picks': 'اختيارات جديدة من Nike',
        'No results for "milk"': 'مفيش نتائج لـ "milk"',
      };

      for (final entry in examples.entries) {
        expect(AppTranslations.current.phrase(entry.key), entry.value);
      }
      AppLanguageController.instance.value = AppLanguage.english;
      for (final entry in examples.entries) {
        expect(AppTranslations.current.phrase(entry.key), entry.key);
      }
    },
  );

  test('unknown and empty phrases keep their original value', () {
    for (final language in AppLanguage.values) {
      AppLanguageController.instance.value = language;
      for (final value in ['', ' \n ', 'Unknown display text', 'نص غير مسجل']) {
        expect(AppTranslations.current.phrase(value), value);
      }
    }
  });

  test('typed count helpers preserve zero, singular and plural text', () {
    final arabic = AppTranslations.current;
    for (final count in [0, 1, 2]) {
      expect(arabic.productCount(count), '$count منتج');
      expect(arabic.searchResults(count, 'milk'), '$count نتيجة لـ "milk"');
      expect(arabic.savedLocations(count), '$count عنوان محفوظ');
    }
    AppLanguageController.instance.value = AppLanguage.english;
    final english = AppTranslations.current;
    expect(english.productCount(0), '0 products');
    expect(english.productCount(1), '1 product');
    expect(english.productCount(2), '2 products');
    expect(english.searchResults(1, 'milk'), '1 result for "milk"');
    expect(english.searchResults(2, 'milk'), '2 results for "milk"');
    expect(english.savedLocations(1), '1 saved location');
    expect(english.savedLocations(2), '2 saved locations');
  });

  test('region helpers keep display text in the selected language', () {
    final arabic = AppTranslations.current;
    expect(
      arabic.regionSwitchTitle(unsupported: true),
      'أنت خارج مناطق الخدمة',
    );
    expect(
      arabic.regionSwitchTitle(unsupported: false),
      'تم اكتشاف تغيير في موقعك',
    );
    expect(
      arabic.regionSwitchMessage(
        currentRegion: 'التل الكبير',
        detectedRegion: 'الإسماعيلية',
        unsupported: false,
      ),
      'منطقتك الحالية هي التل الكبير، ويبدو أنك الآن في الإسماعيلية. هل تريد تغيير المنطقة؟',
    );
    expect(
      arabic.regionSwitchMessage(
        currentRegion: 'التل الكبير',
        detectedRegion: 'الإسماعيلية',
        unsupported: true,
      ),
      'يبدو أنك خارج مدن الخدمة الحالية. هل تريد التبديل إلى جاهز للشحن؟',
    );
    expect(arabic.keepCurrentRegion('التل الكبير'), 'البقاء في التل الكبير');
    expect(arabic.changeToRegion('الإسماعيلية'), 'التغيير إلى الإسماعيلية');
    expect(arabic.currentRegionFallback, 'منطقتك الحالية');
    expect(
      arabic.cartClearedRegionWarning,
      'سيؤدي تغيير المنطقة إلى تفريغ السلة.',
    );

    AppLanguageController.instance.value = AppLanguage.english;
    final english = AppTranslations.current;
    expect(
      english.regionSwitchTitle(unsupported: true),
      'Outside service area',
    );
    expect(english.regionSwitchTitle(unsupported: false), 'Location changed');
    expect(
      english.regionSwitchMessage(
        currentRegion: 'A',
        detectedRegion: 'B',
        unsupported: false,
      ),
      'Your current region is A, and it looks like you are now in B. Do you want to change region?',
    );
    expect(
      english.regionSwitchMessage(
        currentRegion: 'A',
        detectedRegion: 'B',
        unsupported: true,
      ),
      'It looks like you are outside our current service cities. Do you want to switch to General?',
    );
    expect(english.keepCurrentRegion('A'), 'Keep A');
    expect(english.changeToRegion('B'), 'Change to B');
    expect(english.currentRegionFallback, 'your current region');
    expect(
      english.cartClearedRegionWarning,
      'Changing region will clear your cart.',
    );
  });
}
