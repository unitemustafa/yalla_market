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
  static const String emptyStoreLight =
      '$_placeholdersPath/empty_store_light.jpg';
  // Logos
  static const String homeBrandLogo = '$_logosPath/yallamarket_home_logo.png';

  static String themedLogo({required bool isDarkMode}) {
    return homeBrandLogo;
  }

  static String defaultAvatarForGender(String? gender) {
    return gender?.trim().toLowerCase() == 'female'
        ? defaultFemaleUserAvatar
        : defaultUserAvatar;
  }

  // Demo image aliases intentionally share one bundled placeholder. Product,
  // brand, banner, and category artwork should come from the API/database.
  // Onboarding artwork
  static const String onboardingProducts =
      '$_imagesPath/onboarding/onboarding_products.webp';
  static const String onboardingCashOnDelivery =
      '$_imagesPath/onboarding/onboarding_cash_on_delivery.webp';
  static const String onboardingFastDelivery =
      '$_imagesPath/onboarding/onboarding_fast_delivery.webp';

  // Banners
  static const String promoBanner1 = temporaryMarketPlaceholder;
  static const String promoBanner2 = temporaryMarketPlaceholder;
  static const String promoBanner3 = temporaryMarketPlaceholder;

  // Category icons
  static const String diningChairIcon = temporaryMarketPlaceholder;
  static const String shoesIcon = temporaryMarketPlaceholder;
  static const String smartphoneIcon = temporaryMarketPlaceholder;
  static const String tailorsDummyIcon = temporaryMarketPlaceholder;

  // Products
  static const String leatherJacket1 = temporaryMarketPlaceholder;
  static const String leatherJacket2 = temporaryMarketPlaceholder;
  static const String leatherJacket3 = temporaryMarketPlaceholder;
  static const String nikeAirJordanSingleBlue = temporaryMarketPlaceholder;
  static const String nikeAirMax = temporaryMarketPlaceholder;
  static const String nikeShoes = temporaryMarketPlaceholder;
  static const String nikeWildhorse = temporaryMarketPlaceholder;
  static const String samsungS9Mobile = temporaryMarketPlaceholder;
  static const String samsungS9MobileBack = temporaryMarketPlaceholder;
  static const String samsungS9MobileWithBack = temporaryMarketPlaceholder;
  static const String tomiDogFood = temporaryMarketPlaceholder;
  static const String tshirtBlueCollar = temporaryMarketPlaceholder;
  static const String tshirtBlueNoCollarFront = temporaryMarketPlaceholder;
  static const String tshirtGreenCollar = temporaryMarketPlaceholder;
  static const String tshirtRedCollar = temporaryMarketPlaceholder;
  static const String tshirtYellowCollar = temporaryMarketPlaceholder;
}
