import 'package:flutter/widgets.dart';

import 'app_language_controller.dart';
import 'app_text_catalog.dart';
import 'app_texts_ar.dart' as ar;
import 'app_texts_en.dart' as en;

class AppTranslations {
  const AppTranslations._(this.language);

  final AppLanguage language;

  static const List<Locale> supportedLocales = [Locale('ar'), Locale('en')];

  static AppTranslations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppTranslations._(AppLanguage.fromCode(locale.languageCode));
  }

  static AppTranslations get current {
    return AppTranslations._(AppLanguageController.instance.value);
  }

  String _text(String key) {
    final text = AppTextCatalog.keyed[key];
    if (text == null) return key;
    return language.isArabic ? text.ar : text.en;
  }

  String phrase(String value) {
    if (value.trim().isEmpty) return value;
    if (!language.isArabic) return AppTextCatalog.phrases[value]?.en ?? value;

    final direct =
        AppTextCatalog.phrases[value]?.ar ?? AppTextCatalog.keyed[value]?.ar;
    if (direct != null) return direct;

    if (value.endsWith(' products')) {
      if (value.startsWith('View ')) {
        final brand = value.substring(5, value.length - 9);
        return ar.StoreTexts.productsForBrand(brand);
      }

      final count = value.replaceFirst(' products', '');
      if (int.tryParse(count) != null) {
        return ar.StoreTexts.productCountLabel(count);
      }
    }

    if (value.endsWith(' product')) {
      final count = value.replaceFirst(' product', '');
      if (int.tryParse(count) != null) {
        return ar.StoreTexts.productCountLabel(count);
      }
    }

    if (value.endsWith(' stores') || value.endsWith(' store')) {
      final count = value
          .replaceFirst(' stores', '')
          .replaceFirst(' store', '');
      if (int.tryParse(count) != null) return ar.StoreTexts.storeCount(count);
    }

    if (value.endsWith(' markets') || value.endsWith(' market')) {
      final count = value
          .replaceFirst(' markets', '')
          .replaceFirst(' market', '');
      if (int.tryParse(count) != null) return ar.StoreTexts.marketCount(count);
    }

    if (value.endsWith(' offers') || value.endsWith(' offer')) {
      final count = value
          .replaceFirst(' offers', '')
          .replaceFirst(' offer', '');
      if (int.tryParse(count) != null) return ar.StoreTexts.offerCount(count);
    }

    if (value.startsWith('Page ')) {
      return value
          .replaceFirst('Page ', ar.CommonTexts.pagePrefix)
          .replaceFirst(' of ', ar.CommonTexts.pageSeparator);
    }

    if (value.endsWith(' item') || value.endsWith(' items')) {
      final count = value.replaceFirst(' items', '').replaceFirst(' item', '');
      if (int.tryParse(count) != null) {
        return ar.StoreTexts.productCountLabel(count);
      }
    }

    if (value.endsWith(' item(s) added to cart')) {
      final count = value.replaceFirst(' item(s) added to cart', '');
      if (int.tryParse(count) != null) {
        return ar.OrderTexts.itemsAddedToCart(count);
      }
    }

    if (value.startsWith('Remove ') &&
        value.endsWith(' from your saved delivery locations?')) {
      final name = value.substring(
        7,
        value.length - ' from your saved delivery locations?'.length,
      );
      return ar.AddressTexts.removeLocation(name);
    }

    if (value.endsWith(' is selected for checkout.')) {
      final name = value.substring(0, value.length - 26);
      return ar.AddressTexts.selectedForCheckout(name);
    }

    if (value.startsWith('Qty ')) {
      return value.replaceFirst('Qty ', ar.CommonTexts.quantityPrefix);
    }

    if (value.startsWith('No route defined for ')) {
      return ar.CommonTexts.undefinedRoute(
        value.substring('No route defined for '.length),
      );
    }

    if (value.startsWith('You can change your username again on ')) {
      final date = value.substring(
        'You can change your username again on '.length,
      );
      return ar.AuthTexts.usernameChangeDate(date);
    }

    if (value.startsWith('Your ') && value.endsWith(' has been saved.')) {
      final field = value.substring(5, value.length - 16);
      return ar.CommonTexts.fieldSaved(phrase(field));
    }

    if (value.startsWith('No ') && value.endsWith(' products yet')) {
      final brand = value.substring(3, value.length - 13);
      return ar.StoreTexts.noBrandProducts(brand);
    }

    if (value.startsWith('No ') && value.endsWith(' items yet')) {
      final category = value.substring(3, value.length - 10);
      return ar.StoreTexts.noCategoryItems(category);
    }

    if (value.endsWith(' copied')) {
      return ar.CommonTexts.copied(value.substring(0, value.length - 7));
    }

    if (value.startsWith('Fresh ') && value.endsWith(' picks')) {
      final title = phrase(value.substring(6, value.length - 6));
      return ar.HomeTexts.freshPicks(title);
    }

    if (value.startsWith('No results for "')) {
      final query = value.substring(16, value.length - 1);
      return ar.StoreTexts.noSearchResults(query);
    }

    return value;
  }

  String get appName => _text('appName');
  String get skip => _text('skip');
  String get continueText => _text('continueText');
  String get done => _text('done');
  String get startShopping => _text('startShopping');
  String get submit => _text('submit');
  String get resendEmail => _text('resendEmail');

  String get onboardingTitle1 => _text('onboardingTitle1');
  String get onboardingDesc1 => _text('onboardingDesc1');
  String get onboardingTitle2 => _text('onboardingTitle2');
  String get onboardingDesc2 => _text('onboardingDesc2');
  String get onboardingTitle3 => _text('onboardingTitle3');
  String get onboardingDesc3 => _text('onboardingDesc3');

  String get welcomeBack => _text('welcomeBack');
  String get loginSubtitle => _text('loginSubtitle');
  String get email => _text('email');
  String get password => _text('password');
  String get rememberMe => _text('rememberMe');
  String get forgetPasswordLink => _text('forgetPasswordLink');
  String get signIn => _text('signIn');
  String get signInSuccessTitle => _text('signInSuccessTitle');
  String get signInSuccessMessage => _text('signInSuccessMessage');
  String get createAccount => _text('createAccount');
  String get dontHaveAccount => _text('dontHaveAccount');
  String get signUpAction => _text('signUpAction');
  String get orContinueWith => _text('orContinueWith');
  String get languageTooltip => _text('languageTooltip');
  String get signInCreateAccountTitle => _text('signInCreateAccountTitle');
  String get signInCredentialsTitle => _text('signInCredentialsTitle');
  String get signInConnectionTitle => _text('signInConnectionTitle');
  String get signInFailureTitle => _text('signInFailureTitle');

  String get createYourAccount => _text('createYourAccount');
  String get firstName => _text('firstName');
  String get lastName => _text('lastName');
  String get username => _text('username');
  String get phoneNumber => _text('phoneNumber');
  String get iAgreeTo => _text('iAgreeTo');
  String get privacyPolicy => _text('privacyPolicy');
  String get and => _text('and');
  String get termsOfUse => _text('termsOfUse');

  String get forgetPasswordTitle => _text('forgetPasswordTitle');
  String get forgetPasswordDesc => _text('forgetPasswordDesc');
  String get verifyEmailTitle => _text('verifyEmailTitle');
  String get verifyEmailDesc => _text('verifyEmailDesc');
  String get passwordResetTitle => _text('passwordResetTitle');
  String get passwordResetDesc => _text('passwordResetDesc');
  String get successTitle => _text('successTitle');
  String get successDesc => _text('successDesc');

  String get fieldRequired => _text('fieldRequired');
  String get invalidEmail => _text('invalidEmail');
  String get passwordTooShort => _text('passwordTooShort');
  String get passwordTooLong => _text('passwordTooLong');
  String get passwordWeak => _text('passwordWeak');
  String get passwordMedium => _text('passwordMedium');
  String get invalidPhone => _text('invalidPhone');

  // ---------------------------------------------------------------------------
  // Typed interpolation methods — use these instead of dynamic phrase() calls
  // to avoid fragile string-pattern matching.
  // ---------------------------------------------------------------------------

  String productCount(int count) {
    return language.isArabic
        ? ar.StoreTexts.productCount(count)
        : en.StoreTexts.productCount(count);
  }

  String searchResults(int count, String query) {
    return language.isArabic
        ? ar.StoreTexts.searchResults(count, query)
        : en.StoreTexts.searchResults(count, query);
  }

  String savedLocations(int count) {
    return language.isArabic
        ? ar.AddressTexts.savedLocations(count)
        : en.AddressTexts.savedLocations(count);
  }

  String regionSwitchTitle({required bool unsupported}) {
    if (unsupported) {
      return language.isArabic
          ? ar.RegionTexts.outsideServiceAreaTitle
          : en.RegionTexts.outsideServiceAreaTitle;
    }
    return language.isArabic
        ? ar.RegionTexts.locationChangedTitle
        : en.RegionTexts.locationChangedTitle;
  }

  String regionSwitchMessage({
    required String currentRegion,
    required String detectedRegion,
    required bool unsupported,
  }) {
    if (unsupported) {
      return language.isArabic
          ? ar.RegionTexts.outsideServiceAreaMessage
          : en.RegionTexts.outsideServiceAreaMessage;
    }
    return language.isArabic
        ? ar.RegionTexts.locationChangedMessage(currentRegion, detectedRegion)
        : en.RegionTexts.locationChangedMessage(currentRegion, detectedRegion);
  }

  String keepCurrentRegion(String region) {
    return language.isArabic
        ? ar.RegionTexts.keepCurrentRegion(region)
        : en.RegionTexts.keepCurrentRegion(region);
  }

  String changeToRegion(String region) {
    return language.isArabic
        ? ar.RegionTexts.changeToRegion(region)
        : en.RegionTexts.changeToRegion(region);
  }

  String get currentRegionFallback {
    return language.isArabic
        ? ar.RegionTexts.currentRegionFallback
        : en.RegionTexts.currentRegionFallback;
  }

  String get cartClearedRegionWarning {
    return language.isArabic
        ? ar.RegionTexts.cartClearedRegionWarning
        : en.RegionTexts.cartClearedRegionWarning;
  }
}

extension AppTranslationContext on BuildContext {
  AppTranslations get translations => AppTranslations.of(this);

  String tr(String value) => translations.phrase(value);

  bool get isArabicLanguage => translations.language.isArabic;

  String productCount(int count) => translations.productCount(count);

  String searchResults(int count, String query) =>
      translations.searchResults(count, query);

  String savedLocations(int count) => translations.savedLocations(count);

  String regionSwitchTitle({required bool unsupported}) =>
      translations.regionSwitchTitle(unsupported: unsupported);

  String regionSwitchMessage({
    required String currentRegion,
    required String detectedRegion,
    required bool unsupported,
  }) => translations.regionSwitchMessage(
    currentRegion: currentRegion,
    detectedRegion: detectedRegion,
    unsupported: unsupported,
  );

  String keepCurrentRegion(String region) =>
      translations.keepCurrentRegion(region);

  String changeToRegion(String region) => translations.changeToRegion(region);

  String get currentRegionFallback => translations.currentRegionFallback;

  String get cartClearedRegionWarning => translations.cartClearedRegionWarning;
}
