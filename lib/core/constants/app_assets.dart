class AppAssets {
  AppAssets._();

  static const String _imagesPath = 'assets/images';
  static const String _logosPath = 'assets/logos';
  static const String _placeholdersPath = '$_imagesPath/placeholders';

  static const String temporaryMarketPlaceholder =
      '$_imagesPath/temporary_market_placeholder.webp';

  // Frontend-only fallbacks for API images. These paths are never persisted
  // or sent to the backend.
  static const String defaultUserAvatar =
      '$_placeholdersPath/default_user_avatar.webp';
  static const String defaultFemaleUserAvatar =
      '$_placeholdersPath/default_admin_avatar_alt.webp';
  static const String defaultStore = '$_placeholdersPath/default_store.webp';
  static const String defaultCategory =
      '$_placeholdersPath/default_category.webp';
  static const String defaultProduct =
      '$_placeholdersPath/default_product.webp';
  static const String defaultAddon = '$_placeholdersPath/default_addon.webp';
  static const String defaultOffer = '$_placeholdersPath/default_offer.webp';
  static const String defaultCourier =
      '$_placeholdersPath/default_courier.webp';

  // Logos
  static const String logo = '$_logosPath/yallamarket_logo.png';
  static const String appIconLogo = logo;
  static const String lightThemeLogo = logo;
  static const String darkThemeLogo = logo;
  static const String defaultAvatar = appIconLogo;

  static String themedLogo({required bool isDarkMode}) {
    return logo;
  }

  static String defaultAvatarForGender(String? gender) {
    return gender?.trim().toLowerCase() == 'female'
        ? defaultFemaleUserAvatar
        : defaultUserAvatar;
  }

  // Demo image aliases intentionally share one bundled placeholder. Product,
  // brand, banner, and category artwork should come from the API/database.
  // Onboarding artwork
  static const String onboardingProductsLight =
      '$_imagesPath/onboarding/light/onboarding_products_light.webp';
  static const String onboardingCashOnDeliveryLight =
      '$_imagesPath/onboarding/light/onboarding_cash_on_delivery_light.webp';
  static const String onboardingFastDeliveryLight =
      '$_imagesPath/onboarding/light/onboarding_fast_delivery_light.webp';
  static const String onboardingProductsDark =
      '$_imagesPath/onboarding/dark/onboarding_products_dark.webp';
  static const String onboardingCashOnDeliveryDark =
      '$_imagesPath/onboarding/dark/onboarding_cash_on_delivery_dark.webp';
  static const String onboardingFastDeliveryDark =
      '$_imagesPath/onboarding/dark/onboarding_fast_delivery_dark.webp';

  // Banners
  static const String promoBanner1 = temporaryMarketPlaceholder;
  static const String promoBanner2 = temporaryMarketPlaceholder;
  static const String promoBanner3 = temporaryMarketPlaceholder;

  // Brand logos
  static const String acerLogo = temporaryMarketPlaceholder;
  static const String adidasLogo = temporaryMarketPlaceholder;
  static const String appleLogo = temporaryMarketPlaceholder;
  static const String hermanMillerLogo = temporaryMarketPlaceholder;
  static const String ikeaLogo = temporaryMarketPlaceholder;
  static const String jordanLogo = temporaryMarketPlaceholder;
  static const String kenwoodLogo = temporaryMarketPlaceholder;
  static const String nikeLogo = temporaryMarketPlaceholder;
  static const String pumaLogo = temporaryMarketPlaceholder;
  static const String zaraLogo = temporaryMarketPlaceholder;

  // Category icons
  static const String bowlingIcon = temporaryMarketPlaceholder;
  static const String diningChairIcon = temporaryMarketPlaceholder;
  static const String dogHeartIcon = temporaryMarketPlaceholder;
  static const String shoesIcon = temporaryMarketPlaceholder;
  static const String smartphoneIcon = temporaryMarketPlaceholder;
  static const String tailorsDummyIcon = temporaryMarketPlaceholder;

  // Payment icons
  static const String applePay = temporaryMarketPlaceholder;
  static const String googlePay = temporaryMarketPlaceholder;
  static const String masterCard = temporaryMarketPlaceholder;
  static const String paypal = temporaryMarketPlaceholder;
  static const String paytm = temporaryMarketPlaceholder;
  static const String successfulPayment = temporaryMarketPlaceholder;
  static const String visa = temporaryMarketPlaceholder;

  // Products
  static const String leatherJacket1 = temporaryMarketPlaceholder;
  static const String leatherJacket2 = temporaryMarketPlaceholder;
  static const String leatherJacket3 = temporaryMarketPlaceholder;
  static const String leatherJacket4 = temporaryMarketPlaceholder;
  static const String nikeAirJordanBlackRed = temporaryMarketPlaceholder;
  static const String nikeAirJordanOrange = temporaryMarketPlaceholder;
  static const String nikeAirJordanSingleBlue = temporaryMarketPlaceholder;
  static const String nikeAirJordanSingleOrange = temporaryMarketPlaceholder;
  static const String nikeAirJordanWhiteMagenta = temporaryMarketPlaceholder;
  static const String nikeAirJordanWhiteRed = temporaryMarketPlaceholder;
  static const String nikeAirMax = temporaryMarketPlaceholder;
  static const String nikeBasketballGreenBlack = temporaryMarketPlaceholder;
  static const String nikeShoes = temporaryMarketPlaceholder;
  static const String nikeWildhorse = temporaryMarketPlaceholder;
  static const String samsungS9Mobile = temporaryMarketPlaceholder;
  static const String samsungS9MobileBack = temporaryMarketPlaceholder;
  static const String samsungS9MobileWithBack = temporaryMarketPlaceholder;
  static const String tomiDogFood = temporaryMarketPlaceholder;
  static const String tshirtBlueCollar = temporaryMarketPlaceholder;
  static const String tshirtBlueNoCollarBack = temporaryMarketPlaceholder;
  static const String tshirtBlueNoCollarFront = temporaryMarketPlaceholder;
  static const String tshirtGreenCollar = temporaryMarketPlaceholder;
  static const String tshirtRedCollar = temporaryMarketPlaceholder;
  static const String tshirtYellowCollar = temporaryMarketPlaceholder;
}
