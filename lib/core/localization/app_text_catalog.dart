import 'app_texts_ar.dart' as ar;
import 'app_texts_en.dart' as en;

/// الربط بين مفاتيح الترجمة الحالية ومتغيرات النصوص في الملفين.
/// عدّل النص نفسه في app_texts_ar.dart أو app_texts_en.dart.
/// هذا الملف يحتوي على المراجع فقط؛ أضف الربط هنا عند إضافة نص جديد.
abstract final class AppTextCatalog {
  static const keyed = <String, ({String ar, String en})>{
    'appName': (ar: ar.BrandTexts.appName, en: en.BrandTexts.appName),
    'skip': (ar: ar.CommonTexts.skip, en: en.CommonTexts.skip),
    'continueText': (
      ar: ar.CommonTexts.continueText,
      en: en.CommonTexts.continueText,
    ),
    'done': (ar: ar.CommonTexts.done, en: en.CommonTexts.done),
    'startShopping': (
      ar: ar.CommonTexts.startShopping,
      en: en.CommonTexts.startShopping,
    ),
    'submit': (ar: ar.CommonTexts.submit, en: en.CommonTexts.submit),
    'resendEmail': (
      ar: ar.CommonTexts.resendEmail,
      en: en.CommonTexts.resendEmail,
    ),
    'onboardingTitle1': (
      ar: ar.OnboardingTexts.onboardingTitle1,
      en: en.OnboardingTexts.onboardingTitle1,
    ),
    'onboardingDesc1': (
      ar: ar.OnboardingTexts.onboardingDesc1,
      en: en.OnboardingTexts.onboardingDesc1,
    ),
    'onboardingTitle2': (
      ar: ar.OnboardingTexts.onboardingTitle2,
      en: en.OnboardingTexts.onboardingTitle2,
    ),
    'onboardingDesc2': (
      ar: ar.OnboardingTexts.onboardingDesc2,
      en: en.OnboardingTexts.onboardingDesc2,
    ),
    'onboardingTitle3': (
      ar: ar.OnboardingTexts.onboardingTitle3,
      en: en.OnboardingTexts.onboardingTitle3,
    ),
    'onboardingDesc3': (
      ar: ar.OnboardingTexts.onboardingDesc3,
      en: en.OnboardingTexts.onboardingDesc3,
    ),
    'welcomeBack': (ar: ar.AuthTexts.welcomeBack, en: en.AuthTexts.welcomeBack),
    'loginSubtitle': (
      ar: ar.AuthTexts.loginSubtitle,
      en: en.AuthTexts.loginSubtitle,
    ),
    'email': (ar: ar.AuthTexts.email, en: en.AuthTexts.email),
    'password': (ar: ar.AuthTexts.password, en: en.AuthTexts.password),
    'rememberMe': (ar: ar.AuthTexts.rememberMe, en: en.AuthTexts.rememberMe),
    'forgetPasswordLink': (
      ar: ar.AuthTexts.forgetPasswordLink,
      en: en.AuthTexts.forgetPasswordLink,
    ),
    'signIn': (ar: ar.AuthTexts.signIn, en: en.AuthTexts.signIn),
    'signInSuccessTitle': (
      ar: ar.AuthTexts.signInSuccessTitle,
      en: en.AuthTexts.signInSuccessTitle,
    ),
    'signInSuccessMessage': (
      ar: ar.AuthTexts.signInSuccessMessage,
      en: en.AuthTexts.signInSuccessMessage,
    ),
    'createAccount': (
      ar: ar.AuthTexts.createAccount,
      en: en.AuthTexts.createAccount,
    ),
    'dontHaveAccount': (
      ar: ar.AuthTexts.dontHaveAccount,
      en: en.AuthTexts.dontHaveAccount,
    ),
    'signUpAction': (
      ar: ar.AuthTexts.signUpAction,
      en: en.AuthTexts.signUpAction,
    ),
    'orContinueWith': (
      ar: ar.AuthTexts.orContinueWith,
      en: en.AuthTexts.orContinueWith,
    ),
    'languageTooltip': (
      ar: ar.LanguageTexts.languageTooltip,
      en: en.LanguageTexts.languageTooltip,
    ),
    'signInCreateAccountTitle': (
      ar: ar.AuthTexts.signInCreateAccountTitle,
      en: en.AuthTexts.signInCreateAccountTitle,
    ),
    'signInCredentialsTitle': (
      ar: ar.AuthTexts.signInCredentialsTitle,
      en: en.AuthTexts.signInCredentialsTitle,
    ),
    'signInConnectionTitle': (
      ar: ar.AuthTexts.signInConnectionTitle,
      en: en.AuthTexts.signInConnectionTitle,
    ),
    'signInFailureTitle': (
      ar: ar.AuthTexts.signInFailureTitle,
      en: en.AuthTexts.signInFailureTitle,
    ),
    'createYourAccount': (
      ar: ar.AuthTexts.createYourAccount,
      en: en.AuthTexts.createYourAccount,
    ),
    'firstName': (ar: ar.AuthTexts.firstName, en: en.AuthTexts.firstName),
    'lastName': (ar: ar.AuthTexts.lastName, en: en.AuthTexts.lastName),
    'username': (ar: ar.AuthTexts.username, en: en.AuthTexts.username),
    'phoneNumber': (ar: ar.AuthTexts.phoneNumber, en: en.AuthTexts.phoneNumber),
    'iAgreeTo': (ar: ar.AuthTexts.iAgreeTo, en: en.AuthTexts.iAgreeTo),
    'privacyPolicy': (
      ar: ar.AuthTexts.privacyPolicy,
      en: en.AuthTexts.privacyPolicy,
    ),
    'and': (ar: ar.AuthTexts.and, en: en.AuthTexts.and),
    'termsOfUse': (ar: ar.AuthTexts.termsOfUse, en: en.AuthTexts.termsOfUse),
    'forgetPasswordTitle': (
      ar: ar.AuthTexts.forgetPasswordTitle,
      en: en.AuthTexts.forgetPasswordTitle,
    ),
    'forgetPasswordDesc': (
      ar: ar.AuthTexts.forgetPasswordDesc,
      en: en.AuthTexts.forgetPasswordDesc,
    ),
    'verifyEmailTitle': (
      ar: ar.AuthTexts.verifyEmailTitle,
      en: en.AuthTexts.verifyEmailTitle,
    ),
    'verifyEmailDesc': (
      ar: ar.AuthTexts.verifyEmailDesc,
      en: en.AuthTexts.verifyEmailDesc,
    ),
    'passwordResetTitle': (
      ar: ar.AuthTexts.passwordResetTitle,
      en: en.AuthTexts.passwordResetTitle,
    ),
    'passwordResetDesc': (
      ar: ar.AuthTexts.passwordResetDesc,
      en: en.AuthTexts.passwordResetDesc,
    ),
    'successTitle': (
      ar: ar.AuthTexts.successTitle,
      en: en.AuthTexts.successTitle,
    ),
    'successDesc': (ar: ar.AuthTexts.successDesc, en: en.AuthTexts.successDesc),
    'fieldRequired': (
      ar: ar.AuthTexts.fieldRequired,
      en: en.AuthTexts.fieldRequired,
    ),
    'invalidEmail': (
      ar: ar.AuthTexts.invalidEmail,
      en: en.AuthTexts.invalidEmail,
    ),
    'passwordTooShort': (
      ar: ar.AuthTexts.passwordTooShort,
      en: en.AuthTexts.passwordTooShort,
    ),
    'passwordTooLong': (
      ar: ar.AuthTexts.passwordTooLong,
      en: en.AuthTexts.passwordTooLong,
    ),
    'passwordWeak': (
      ar: ar.AuthTexts.passwordWeak,
      en: en.AuthTexts.passwordWeak,
    ),
    'passwordMedium': (
      ar: ar.AuthTexts.passwordMedium,
      en: en.AuthTexts.passwordMedium,
    ),
    'invalidPhone': (
      ar: ar.AuthTexts.invalidPhone,
      en: en.AuthTexts.invalidPhone,
    ),
  };

  static const phrases = <String, ({String ar, String en})>{
    'Change your region': (
      ar: ar.RegionTexts.changeYourRegion,
      en: en.RegionTexts.changeYourRegion,
    ),
    'You can change your region here anytime to see products and offers for your area.':
        (
          ar: ar.RegionTexts.youCanChangeYourRegionHereAnytimeToSeeProducts,
          en: en.RegionTexts.youCanChangeYourRegionHereAnytimeToSeeProducts,
        ),
    'Outside the delivery area. Adjust the location.': (
      ar: ar.RegionTexts.outsideTheDeliveryAreaAdjustTheLocation,
      en: en.RegionTexts.outsideTheDeliveryAreaAdjustTheLocation,
    ),
    'Your current location is outside the delivery area.': (
      ar: ar.RegionTexts.yourCurrentLocationIsOutsideTheDeliveryArea,
      en: en.RegionTexts.yourCurrentLocationIsOutsideTheDeliveryArea,
    ),
    'Search for a place in Egypt': (
      ar: ar.RegionTexts.searchForAPlaceInEgypt,
      en: en.RegionTexts.searchForAPlaceInEgypt,
    ),
    'Browsing region': (
      ar: ar.RegionTexts.browsingRegion,
      en: en.RegionTexts.browsingRegion,
    ),
    'Change region': (
      ar: ar.RegionTexts.changeRegion,
      en: en.RegionTexts.changeRegion,
    ),
    'Change region manually': (
      ar: ar.RegionTexts.changeRegionManually,
      en: en.RegionTexts.changeRegionManually,
    ),
    'Choose your current city or the nearest one': (
      ar: ar.RegionTexts.chooseYourCurrentCityOrTheNearestOne,
      en: en.RegionTexts.chooseYourCurrentCityOrTheNearestOne,
    ),
    'Choose your current city or the nearest one.': (
      ar: ar.RegionTexts.chooseYourCurrentCityOrTheNearestOneLabel,
      en: en.RegionTexts.chooseYourCurrentCityOrTheNearestOneLabel,
    ),
    'If your city is not available, choose Other.': (
      ar: ar.RegionTexts.ifYourCityIsNotAvailableChooseOther,
      en: en.RegionTexts.ifYourCityIsNotAvailableChooseOther,
    ),
    'Choose manually or let GPS detect your area.': (
      ar: ar.RegionTexts.chooseManuallyOrLetGpsDetectYourArea,
      en: en.RegionTexts.chooseManuallyOrLetGpsDetectYourArea,
    ),
    'Choose the browsing region used for products': (
      ar: ar.RegionTexts.chooseTheBrowsingRegionUsedForProducts,
      en: en.RegionTexts.chooseTheBrowsingRegionUsedForProducts,
    ),
    'General browsing': (
      ar: ar.RegionTexts.generalBrowsing,
      en: en.RegionTexts.generalBrowsing,
    ),
    'General region saved': (
      ar: ar.RegionTexts.generalRegionSaved,
      en: en.RegionTexts.generalRegionSaved,
    ),
    'Products and offers will refresh for your region.': (
      ar: ar.RegionTexts.productsAndOffersWillRefreshForYourRegion,
      en: en.RegionTexts.productsAndOffersWillRefreshForYourRegion,
    ),
    'Products that fit your region': (
      ar: ar.RegionTexts.productsThatFitYourRegion,
      en: en.RegionTexts.productsThatFitYourRegion,
    ),
    'Products will refresh for your selected region.': (
      ar: ar.RegionTexts.productsWillRefreshForYourSelectedRegion,
      en: en.RegionTexts.productsWillRefreshForYourSelectedRegion,
    ),
    'Region': (ar: ar.RegionTexts.region, en: en.RegionTexts.region),
    'Region not changed': (
      ar: ar.RegionTexts.regionNotChanged,
      en: en.RegionTexts.regionNotChanged,
    ),
    'Region saved': (
      ar: ar.RegionTexts.regionSaved,
      en: en.RegionTexts.regionSaved,
    ),
    'Could not update your region. Your cart was not changed.': (
      ar: ar.RegionTexts.couldNotUpdateYourRegionYourCartWasNotChanged,
      en: en.RegionTexts.couldNotUpdateYourRegionYourCartWasNotChanged,
    ),
    'The region was changed, but the cart could not be cleared.': (
      ar: ar.RegionTexts.theRegionWasChangedButTheCartCouldNotBe,
      en: en.RegionTexts.theRegionWasChangedButTheCartCouldNotBe,
    ),
    'Not available in the current region': (
      ar: ar.RegionTexts.notAvailableInTheCurrentRegion,
      en: en.RegionTexts.notAvailableInTheCurrentRegion,
    ),
    'This offer is not available in your city right now.': (
      ar: ar.RegionTexts.thisOfferIsNotAvailableInYourCityRightNow,
      en: en.RegionTexts.thisOfferIsNotAvailableInYourCityRightNow,
    ),
    'You are now in a supported region. Switch to see its offers. Your cart will be checked at checkout.':
        (
          ar: ar.RegionTexts.youAreNowInASupportedRegionSwitchToSee,
          en: en.RegionTexts.youAreNowInASupportedRegionSwitchToSee,
        ),
    'Location access is required before choosing an address.': (
      ar: ar.RegionTexts.locationAccessIsRequiredBeforeChoosingAnAddress,
      en: en.RegionTexts.locationAccessIsRequiredBeforeChoosingAnAddress,
    ),
    'Open location settings': (
      ar: ar.RegionTexts.openLocationSettings,
      en: en.RegionTexts.openLocationSettings,
    ),
    'GPS access is required to open the map.': (
      ar: ar.RegionTexts.gpsAccessIsRequiredToOpenTheMap,
      en: en.RegionTexts.gpsAccessIsRequiredToOpenTheMap,
    ),
    'GPS can try to detect your area automatically.': (
      ar: ar.RegionTexts.gpsCanTryToDetectYourAreaAutomatically,
      en: en.RegionTexts.gpsCanTryToDetectYourAreaAutomatically,
    ),
    'Location access is required': (
      ar: ar.RegionTexts.locationAccessIsRequired,
      en: en.RegionTexts.locationAccessIsRequired,
    ),
    'Choose your area manually and you can try GPS again later.': (
      ar: ar.RegionTexts.chooseYourAreaManuallyAndYouCanTryGpsAgain,
      en: en.RegionTexts.chooseYourAreaManuallyAndYouCanTryGpsAgain,
    ),
    'Detecting location...': (
      ar: ar.RegionTexts.detectingLocation,
      en: en.RegionTexts.detectingLocation,
    ),
    'Detecting your location...': (
      ar: ar.RegionTexts.detectingYourLocation,
      en: en.RegionTexts.detectingYourLocation,
    ),
    'Enable GPS and continue': (
      ar: ar.RegionTexts.enableGpsAndContinue,
      en: en.RegionTexts.enableGpsAndContinue,
    ),
    'GPS helps Yalla Market show nearby products, local offers, better delivery suggestions, and more accurate delivery pricing later.':
        (
          ar: ar
              .RegionTexts
              .gpsHelpsYallaMarketShowNearbyProductsLocalOffersBetter,
          en: en
              .RegionTexts
              .gpsHelpsYallaMarketShowNearbyProductsLocalOffersBetter,
        ),
    'If your area is not here, add it manually': (
      ar: ar.RegionTexts.ifYourAreaIsNotHereAddItManually,
      en: en.RegionTexts.ifYourAreaIsNotHereAddItManually,
    ),
    'Location permission was not granted. Allow location to continue.': (
      ar: ar.RegionTexts.locationPermissionWasNotGrantedAllowLocationToContinue,
      en: en.RegionTexts.locationPermissionWasNotGrantedAllowLocationToContinue,
    ),
    'Location services are disabled. Turn on GPS to continue.': (
      ar: ar.RegionTexts.locationServicesAreDisabledTurnOnGpsToContinue,
      en: en.RegionTexts.locationServicesAreDisabledTurnOnGpsToContinue,
    ),
    'Turn on GPS and allow location access before entering the app.': (
      ar: ar.RegionTexts.turnOnGpsAndAllowLocationAccessBeforeEnteringThe,
      en: en.RegionTexts.turnOnGpsAndAllowLocationAccessBeforeEnteringThe,
    ),
    'Location settings': (
      ar: ar.RegionTexts.locationSettings,
      en: en.RegionTexts.locationSettings,
    ),
    'Use GPS location': (
      ar: ar.RegionTexts.useGpsLocation,
      en: en.RegionTexts.useGpsLocation,
    ),
    'Is this your governorate?': (
      ar: ar.RegionTexts.isThisYourGovernorate,
      en: en.RegionTexts.isThisYourGovernorate,
    ),
    'Is this your city?': (
      ar: ar.RegionTexts.isThisYourCity,
      en: en.RegionTexts.isThisYourCity,
    ),
    'We detected your city': (
      ar: ar.RegionTexts.weDetectedYourCity,
      en: en.RegionTexts.weDetectedYourCity,
    ),
    'We detected your governorate': (
      ar: ar.RegionTexts.weDetectedYourGovernorate,
      en: en.RegionTexts.weDetectedYourGovernorate,
    ),
    'We could not detect a supported governorate. Choose one manually.': (
      ar: ar.RegionTexts.weCouldNotDetectASupportedGovernorateChooseOneManually,
      en: en.RegionTexts.weCouldNotDetectASupportedGovernorateChooseOneManually,
    ),
    'Choose city': (
      ar: ar.RegionTexts.chooseCity,
      en: en.RegionTexts.chooseCity,
    ),
    'Choose the city used for available products': (
      ar: ar.RegionTexts.chooseTheCityUsedForAvailableProducts,
      en: en.RegionTexts.chooseTheCityUsedForAvailableProducts,
    ),
    'Choose your city': (
      ar: ar.RegionTexts.chooseYourCity,
      en: en.RegionTexts.chooseYourCity,
    ),
    'City': (ar: ar.RegionTexts.city, en: en.RegionTexts.city),
    'City saved': (ar: ar.RegionTexts.citySaved, en: en.RegionTexts.citySaved),
    'City name is required': (
      ar: ar.RegionTexts.cityNameIsRequired,
      en: en.RegionTexts.cityNameIsRequired,
    ),
    'City: {name}': (ar: ar.RegionTexts.cityName, en: en.RegionTexts.cityName),
    'Delivery City': (
      ar: ar.RegionTexts.deliveryCity,
      en: en.RegionTexts.deliveryCity,
    ),
    'Enter your city': (
      ar: ar.RegionTexts.enterYourCity,
      en: en.RegionTexts.enterYourCity,
    ),
    'Location permission was not granted. Choose your city manually.': (
      ar: ar.RegionTexts.locationPermissionWasNotGrantedChooseYourCityManually,
      en: en.RegionTexts.locationPermissionWasNotGrantedChooseYourCityManually,
    ),
    'Location services are disabled. Choose your city manually.': (
      ar: ar.RegionTexts.locationServicesAreDisabledChooseYourCityManually,
      en: en.RegionTexts.locationServicesAreDisabledChooseYourCityManually,
    ),
    'Products will refresh for your selected city.': (
      ar: ar.RegionTexts.productsWillRefreshForYourSelectedCity,
      en: en.RegionTexts.productsWillRefreshForYourSelectedCity,
    ),
    'Save city': (ar: ar.RegionTexts.saveCity, en: en.RegionTexts.saveCity),
    'So we can show products available in your area.': (
      ar: ar.RegionTexts.soWeCanShowProductsAvailableInYourArea,
      en: en.RegionTexts.soWeCanShowProductsAvailableInYourArea,
    ),
    'So we can show shops available in your area.': (
      ar: ar.RegionTexts.soWeCanShowShopsAvailableInYourArea,
      en: en.RegionTexts.soWeCanShowShopsAvailableInYourArea,
    ),
    'We could not detect a supported city. Choose one manually.': (
      ar: ar.RegionTexts.weCouldNotDetectASupportedCityChooseOneManually,
      en: en.RegionTexts.weCouldNotDetectASupportedCityChooseOneManually,
    ),
    'Other city': (ar: ar.RegionTexts.otherCity, en: en.RegionTexts.otherCity),
    'Choose a delivery area': (
      ar: ar.RegionTexts.chooseADeliveryArea,
      en: en.RegionTexts.chooseADeliveryArea,
    ),
    'Choose a delivery area.': (
      ar: ar.RegionTexts.chooseADeliveryAreaLabel,
      en: en.RegionTexts.chooseADeliveryAreaLabel,
    ),
    'Choose a delivery area to see the price': (
      ar: ar.RegionTexts.chooseADeliveryAreaToSeeThePrice,
      en: en.RegionTexts.chooseADeliveryAreaToSeeThePrice,
    ),
    'Delivery area': (
      ar: ar.RegionTexts.deliveryArea,
      en: en.RegionTexts.deliveryArea,
    ),
    'Direct area delivery': (
      ar: ar.RegionTexts.directAreaDelivery,
      en: en.RegionTexts.directAreaDelivery,
    ),
    'Enter your area name': (
      ar: ar.RegionTexts.enterYourAreaName,
      en: en.RegionTexts.enterYourAreaName,
    ),
    'My area is not listed': (
      ar: ar.RegionTexts.myAreaIsNotListed,
      en: en.RegionTexts.myAreaIsNotListed,
    ),
    'Your city is outside the current service cities. Enter your city and area manually.':
        (
          ar: ar.RegionTexts.yourCityIsOutsideTheCurrentServiceCitiesEnterYour,
          en: en.RegionTexts.yourCityIsOutsideTheCurrentServiceCitiesEnterYour,
        ),
    'Area': (ar: ar.RegionTexts.area, en: en.RegionTexts.area),
    'Alexandria': (
      ar: ar.RegionTexts.alexandria,
      en: en.RegionTexts.alexandria,
    ),
    'Cairo': (ar: ar.RegionTexts.cairo, en: en.RegionTexts.cairo),
    'Egypt': (ar: ar.RegionTexts.egypt, en: en.RegionTexts.egypt),
    'Egyptian Pound': (
      ar: ar.RegionTexts.egyptianPound,
      en: en.RegionTexts.egyptianPound,
    ),
    'Nasr City': (ar: ar.RegionTexts.nasrCity, en: en.RegionTexts.nasrCity),
    'New Cairo': (ar: ar.RegionTexts.newCairo, en: en.RegionTexts.newCairo),
    'Downtown Cairo': (
      ar: ar.RegionTexts.downtownCairo,
      en: en.RegionTexts.downtownCairo,
    ),
    'Enter a valid Egyptian mobile number starting with 01, 1, 201, or +201.': (
      ar: ar.RegionTexts.enterAValidEgyptianMobileNumberStartingWith011,
      en: en.RegionTexts.enterAValidEgyptianMobileNumberStartingWith011,
    ),
    'Delivery address': (
      ar: ar.AddressTexts.deliveryAddress,
      en: en.AddressTexts.deliveryAddress,
    ),
    'New address': (
      ar: ar.AddressTexts.newAddress,
      en: en.AddressTexts.newAddress,
    ),
    'Save address': (
      ar: ar.AddressTexts.saveAddress,
      en: en.AddressTexts.saveAddress,
    ),
    'Add new address': (
      ar: ar.AddressTexts.addNewAddress,
      en: en.AddressTexts.addNewAddress,
    ),
    'Add Address': (
      ar: ar.AddressTexts.addAddress,
      en: en.AddressTexts.addAddress,
    ),
    'Add an address to start checkout faster.': (
      ar: ar.AddressTexts.addAnAddressToStartCheckoutFaster,
      en: en.AddressTexts.addAnAddressToStartCheckoutFaster,
    ),
    'Address deleted': (
      ar: ar.AddressTexts.addressDeleted,
      en: en.AddressTexts.addressDeleted,
    ),
    'Address saved': (
      ar: ar.AddressTexts.addressSaved,
      en: en.AddressTexts.addressSaved,
    ),
    'Address updated': (
      ar: ar.AddressTexts.addressUpdated,
      en: en.AddressTexts.addressUpdated,
    ),
    'Address update failed': (
      ar: ar.AddressTexts.addressUpdateFailed,
      en: en.AddressTexts.addressUpdateFailed,
    ),
    'Address name': (
      ar: ar.AddressTexts.addressName,
      en: en.AddressTexts.addressName,
    ),
    'Address details': (
      ar: ar.AddressTexts.addressDetails,
      en: en.AddressTexts.addressDetails,
    ),
    'Address label (optional)': (
      ar: ar.AddressTexts.addressLabelOptional,
      en: en.AddressTexts.addressLabelOptional,
    ),
    'Address required': (
      ar: ar.AddressTexts.addressRequired,
      en: en.AddressTexts.addressRequired,
    ),
    'Addresses': (ar: ar.AddressTexts.addresses, en: en.AddressTexts.addresses),
    'Choose a saved address': (
      ar: ar.AddressTexts.chooseASavedAddress,
      en: en.AddressTexts.chooseASavedAddress,
    ),
    'Complete address details help checkout and delivery move faster.': (
      ar: ar
          .AddressTexts
          .completeAddressDetailsHelpCheckoutAndDeliveryMoveFaster,
      en: en
          .AddressTexts
          .completeAddressDetailsHelpCheckoutAndDeliveryMoveFaster,
    ),
    'Could not update addresses.': (
      ar: ar.AddressTexts.couldNotUpdateAddresses,
      en: en.AddressTexts.couldNotUpdateAddresses,
    ),
    'Delete address?': (
      ar: ar.AddressTexts.deleteAddress,
      en: en.AddressTexts.deleteAddress,
    ),
    'Delivery address needed': (
      ar: ar.AddressTexts.deliveryAddressNeeded,
      en: en.AddressTexts.deliveryAddressNeeded,
    ),
    'Delivery is no longer available for this address': (
      ar: ar.AddressTexts.deliveryIsNoLongerAvailableForThisAddress,
      en: en.AddressTexts.deliveryIsNoLongerAvailableForThisAddress,
    ),
    'Edit Address': (
      ar: ar.AddressTexts.editAddress,
      en: en.AddressTexts.editAddress,
    ),
    'My Addresses': (
      ar: ar.AddressTexts.myAddresses,
      en: en.AddressTexts.myAddresses,
    ),
    'Review address': (
      ar: ar.AddressTexts.reviewAddress,
      en: en.AddressTexts.reviewAddress,
    ),
    'Select Address': (
      ar: ar.AddressTexts.selectAddress,
      en: en.AddressTexts.selectAddress,
    ),
    'Set shopping delivery address': (
      ar: ar.AddressTexts.setShoppingDeliveryAddress,
      en: en.AddressTexts.setShoppingDeliveryAddress,
    ),
    'Home, Work, Other address': (
      ar: ar.AddressTexts.homeWorkOtherAddress,
      en: en.AddressTexts.homeWorkOtherAddress,
    ),
    'Street, building, floor, landmark': (
      ar: ar.AddressTexts.streetBuildingFloorLandmark,
      en: en.AddressTexts.streetBuildingFloorLandmark,
    ),
    'Remove {name} from your saved delivery locations?': (
      ar: ar.AddressTexts.removeNameFromYourSavedDeliveryLocations,
      en: en.AddressTexts.removeNameFromYourSavedDeliveryLocations,
    ),
    'Save a delivery location': (
      ar: ar.AddressTexts.saveADeliveryLocation,
      en: en.AddressTexts.saveADeliveryLocation,
    ),
    'Update this delivery location': (
      ar: ar.AddressTexts.updateThisDeliveryLocation,
      en: en.AddressTexts.updateThisDeliveryLocation,
    ),
    'Stores will appear here when they cover your address.': (
      ar: ar.AddressTexts.storesWillAppearHereWhenTheyCoverYourAddress,
      en: en.AddressTexts.storesWillAppearHereWhenTheyCoverYourAddress,
    ),
    'This store is not available for your current address.': (
      ar: ar.AddressTexts.thisStoreIsNotAvailableForYourCurrentAddress,
      en: en.AddressTexts.thisStoreIsNotAvailableForYourCurrentAddress,
    ),
    'Your package is on the way to your address.': (
      ar: ar.AddressTexts.yourPackageIsOnTheWayToYourAddress,
      en: en.AddressTexts.yourPackageIsOnTheWayToYourAddress,
    ),
    'Apartment': (ar: ar.AddressTexts.apartment, en: en.AddressTexts.apartment),
    'House': (ar: ar.AddressTexts.house, en: en.AddressTexts.house),
    'Office': (ar: ar.AddressTexts.office, en: en.AddressTexts.office),
    'Building name': (
      ar: ar.AddressTexts.buildingName,
      en: en.AddressTexts.buildingName,
    ),
    'Apartment number': (
      ar: ar.AddressTexts.apartmentNumber,
      en: en.AddressTexts.apartmentNumber,
    ),
    'Floor': (ar: ar.AddressTexts.floor, en: en.AddressTexts.floor),
    'Floor (optional)': (
      ar: ar.AddressTexts.floorOptional,
      en: en.AddressTexts.floorOptional,
    ),
    'House name': (
      ar: ar.AddressTexts.houseName,
      en: en.AddressTexts.houseName,
    ),
    'Company': (ar: ar.AddressTexts.company, en: en.AddressTexts.company),
    'Family home': (
      ar: ar.AddressTexts.familyHome,
      en: en.AddressTexts.familyHome,
    ),
    'Street': (ar: ar.AddressTexts.street, en: en.AddressTexts.street),
    'Name this address so you can identify it easily.': (
      ar: ar.AddressTexts.nameThisAddressSoYouCanIdentifyItEasily,
      en: en.AddressTexts.nameThisAddressSoYouCanIdentifyItEasily,
    ),
    'Confirm delivery location': (
      ar: ar.AddressTexts.confirmDeliveryLocation,
      en: en.AddressTexts.confirmDeliveryLocation,
    ),
    'Continue with this location': (
      ar: ar.AddressTexts.continueWithThisLocation,
      en: en.AddressTexts.continueWithThisLocation,
    ),
    'Your order will be delivered to this location': (
      ar: ar.AddressTexts.yourOrderWillBeDeliveredToThisLocation,
      en: en.AddressTexts.yourOrderWillBeDeliveredToThisLocation,
    ),
    'Place search failed.': (
      ar: ar.AddressTexts.placeSearchFailed,
      en: en.AddressTexts.placeSearchFailed,
    ),
    'Address lookup failed. You can still continue.': (
      ar: ar.AddressTexts.addressLookupFailedYouCanStillContinue,
      en: en.AddressTexts.addressLookupFailedYouCanStillContinue,
    ),
    'Finding the address...': (
      ar: ar.AddressTexts.findingTheAddress,
      en: en.AddressTexts.findingTheAddress,
    ),
    'Could not find your current location. Try again.': (
      ar: ar.AddressTexts.couldNotFindYourCurrentLocationTryAgain,
      en: en.AddressTexts.couldNotFindYourCurrentLocationTryAgain,
    ),
    'Map location selected': (
      ar: ar.AddressTexts.mapLocationSelected,
      en: en.AddressTexts.mapLocationSelected,
    ),
    'Choose location on map': (
      ar: ar.AddressTexts.chooseLocationOnMap,
      en: en.AddressTexts.chooseLocationOnMap,
    ),
    'Your current location is selected. Move the map to adjust it.': (
      ar: ar.AddressTexts.yourCurrentLocationIsSelectedMoveTheMapToAdjust,
      en: en.AddressTexts.yourCurrentLocationIsSelectedMoveTheMapToAdjust,
    ),
    'Location selected manually.': (
      ar: ar.AddressTexts.locationSelectedManually,
      en: en.AddressTexts.locationSelectedManually,
    ),
    'Current location is unavailable. Move the map to choose it manually.': (
      ar: ar.AddressTexts.currentLocationIsUnavailableMoveTheMapToChooseIt,
      en: en.AddressTexts.currentLocationIsUnavailableMoveTheMapToChooseIt,
    ),
    'Automatic location': (
      ar: ar.AddressTexts.automaticLocation,
      en: en.AddressTexts.automaticLocation,
    ),
    'Location is taking too long': (
      ar: ar.AddressTexts.locationIsTakingTooLong,
      en: en.AddressTexts.locationIsTakingTooLong,
    ),
    'Enable your location': (
      ar: ar.AddressTexts.enableYourLocation,
      en: en.AddressTexts.enableYourLocation,
    ),
    'Use my current location': (
      ar: ar.AddressTexts.useMyCurrentLocation,
      en: en.AddressTexts.useMyCurrentLocation,
    ),
    'Edit location': (
      ar: ar.AddressTexts.editLocation,
      en: en.AddressTexts.editLocation,
    ),
    'Could not use your current location.': (
      ar: ar.AddressTexts.couldNotUseYourCurrentLocation,
      en: en.AddressTexts.couldNotUseYourCurrentLocation,
    ),
    'Could not find your current location. Choose one manually.': (
      ar: ar.AddressTexts.couldNotFindYourCurrentLocationChooseOneManually,
      en: en.AddressTexts.couldNotFindYourCurrentLocationChooseOneManually,
    ),
    'Shipping Address': (
      ar: ar.AddressTexts.shippingAddress,
      en: en.AddressTexts.shippingAddress,
    ),
    'Shipping Company': (
      ar: ar.AddressTexts.shippingCompany,
      en: en.AddressTexts.shippingCompany,
    ),
    'Shipping company required': (
      ar: ar.AddressTexts.shippingCompanyRequired,
      en: en.AddressTexts.shippingCompanyRequired,
    ),
    'Choose a shipping company before completing the order.': (
      ar: ar.AddressTexts.chooseAShippingCompanyBeforeCompletingTheOrder,
      en: en.AddressTexts.chooseAShippingCompanyBeforeCompletingTheOrder,
    ),
    'Shipping address required': (
      ar: ar.AddressTexts.shippingAddressRequired,
      en: en.AddressTexts.shippingAddressRequired,
    ),
    'Complete the delivery address first.': (
      ar: ar.AddressTexts.completeTheDeliveryAddressFirst,
      en: en.AddressTexts.completeTheDeliveryAddressFirst,
    ),
    'Mobile phone number': (
      ar: ar.AuthTexts.mobilePhoneNumber,
      en: en.AuthTexts.mobilePhoneNumber,
    ),
    'Don\'t have an account?': (
      ar: ar.AuthTexts.dontHaveAccount,
      en: en.AuthTexts.dontHaveAccount,
    ),
    'Sign Up': (ar: ar.AuthTexts.signUpAction, en: en.AuthTexts.signUpAction),
    'Mobile / Email / Username': (
      ar: ar.AuthTexts.mobileEmailUsername,
      en: en.AuthTexts.mobileEmailUsername,
    ),
    'Enter a valid email, username, or phone number': (
      ar: ar.AuthTexts.enterAValidEmailUsernameOrPhoneNumber,
      en: en.AuthTexts.enterAValidEmailUsernameOrPhoneNumber,
    ),
    'Session expired': (
      ar: ar.AuthTexts.sessionExpired,
      en: en.AuthTexts.sessionExpired,
    ),
    'Account disabled': (
      ar: ar.AuthTexts.accountDisabled,
      en: en.AuthTexts.accountDisabled,
    ),
    'Account email has not been verified.': (
      ar: ar.AuthTexts.emailNotVerified,
      en: en.AuthTexts.emailNotVerified,
    ),
    'This login is only for client accounts.': (
      ar: ar.AuthTexts.wrongAppCredentials,
      en: en.AuthTexts.wrongAppCredentials,
    ),
    'Invalid sign-in credentials.': (
      ar: ar.AuthTexts.invalidSignInCredentials,
      en: en.AuthTexts.invalidSignInCredentials,
    ),
    'Sign in again to continue. Remember Me keeps you signed in after closing the app.':
        (
          ar: ar.AuthTexts.sessionExpiredHint,
          en: en.AuthTexts.sessionExpiredHint,
        ),
    'Sign in again before placing an order.': (
      ar: ar.AuthTexts.signInAgainBeforePlacingAnOrder,
      en: en.AuthTexts.signInAgainBeforePlacingAnOrder,
    ),
    'Email and password are required.': (
      ar: ar.AuthTexts.emailAndPasswordAreRequired,
      en: en.AuthTexts.emailAndPasswordAreRequired,
    ),
    'Invalid email or password.': (
      ar: ar.AuthTexts.invalidCredentials,
      en: en.AuthTexts.invalidCredentials,
    ),
    'Remember Me': (ar: ar.AuthTexts.rememberMe, en: en.AuthTexts.rememberMe),
    'Sign In': (ar: ar.AuthTexts.signIn, en: en.AuthTexts.signIn),
    'Logout': (ar: ar.AuthTexts.logout, en: en.AuthTexts.logout),
    'Are you sure you want to logout?': (
      ar: ar.AuthTexts.areYouSureYouWantToLogout,
      en: en.AuthTexts.areYouSureYouWantToLogout,
    ),
    'Could not sign you in.': (
      ar: ar.AuthTexts.couldNotSignYouIn,
      en: en.AuthTexts.couldNotSignYouIn,
    ),
    'Could not sign you out.': (
      ar: ar.AuthTexts.couldNotSignYouOut,
      en: en.AuthTexts.couldNotSignYouOut,
    ),
    'A new sign-in was verified successfully.': (
      ar: ar.AuthTexts.aNewSignInWasVerifiedSuccessfully,
      en: en.AuthTexts.aNewSignInWasVerifiedSuccessfully,
    ),
    'No local user session.': (
      ar: ar.AuthTexts.noLocalUserSession,
      en: en.AuthTexts.noLocalUserSession,
    ),
    'Could not restore your session.': (
      ar: ar.AuthTexts.couldNotRestoreYourSession,
      en: en.AuthTexts.couldNotRestoreYourSession,
    ),
    'Create Account': (
      ar: ar.AuthTexts.createAccount,
      en: en.AuthTexts.createAccount,
    ),
    'Account already exists': (
      ar: ar.AuthTexts.accountAlreadyExists,
      en: en.AuthTexts.accountAlreadyExists,
    ),
    'Account creation failed': (
      ar: ar.AuthTexts.accountCreationFailed,
      en: en.AuthTexts.accountCreationFailed,
    ),
    'Account created successfully': (
      ar: ar.AuthTexts.accountCreatedSuccessfully,
      en: en.AuthTexts.accountCreatedSuccessfully,
    ),
    'Could not create your account.': (
      ar: ar.AuthTexts.couldNotCreateYourAccount,
      en: en.AuthTexts.couldNotCreateYourAccount,
    ),
    'We will verify it while creating your account.': (
      ar: ar.AuthTexts.weWillVerifyItWhileCreatingYourAccount,
      en: en.AuthTexts.weWillVerifyItWhileCreatingYourAccount,
    ),
    'Please agree to the Privacy Policy and Terms of use before creating your account.':
        (
          ar: ar.AuthTexts.pleaseAgreeToThePrivacyPolicyAndTermsOfUse,
          en: en.AuthTexts.pleaseAgreeToThePrivacyPolicyAndTermsOfUse,
        ),
    'Account restored': (
      ar: ar.AuthTexts.accountRestored,
      en: en.AuthTexts.accountRestored,
    ),
    'Your account was restored by the Yalla Market team.': (
      ar: ar.AuthTexts.yourAccountWasRestoredByTheYallaMarketTeam,
      en: en.AuthTexts.yourAccountWasRestoredByTheYallaMarketTeam,
    ),
    'Account restored by Yalla Market support team': (
      ar: ar.AuthTexts.accountRestoredByYallaMarketSupportTeam,
      en: en.AuthTexts.accountRestoredByYallaMarketSupportTeam,
    ),
    'Your account has been restored. You can sign in again.': (
      ar: ar.AuthTexts.yourAccountHasBeenRestoredYouCanSignInAgain,
      en: en.AuthTexts.yourAccountHasBeenRestoredYouCanSignInAgain,
    ),
    'Account permanently deleted': (
      ar: ar.AuthTexts.accountPermanentlyDeleted,
      en: en.AuthTexts.accountPermanentlyDeleted,
    ),
    'Your account has been permanently deleted. Create a new account to continue.':
        (
          ar: ar
              .AuthTexts
              .yourAccountHasBeenPermanentlyDeletedCreateANewAccount,
          en: en
              .AuthTexts
              .yourAccountHasBeenPermanentlyDeletedCreateANewAccount,
        ),
    'Your account is disabled. Contact technical support or create a new account.':
        (
          ar: ar
              .AuthTexts
              .yourAccountIsDisabledContactTechnicalSupportOrCreateA,
          en: en
              .AuthTexts
              .yourAccountIsDisabledContactTechnicalSupportOrCreateA,
        ),
    'Profile': (ar: ar.AuthTexts.profile, en: en.AuthTexts.profile),
    'Profile Information': (
      ar: ar.AuthTexts.profileInformation,
      en: en.AuthTexts.profileInformation,
    ),
    'Profile photo updated': (
      ar: ar.AuthTexts.profilePhotoUpdated,
      en: en.AuthTexts.profilePhotoUpdated,
    ),
    'Profile updated': (
      ar: ar.AuthTexts.profileUpdated,
      en: en.AuthTexts.profileUpdated,
    ),
    'Edit profile': (
      ar: ar.AuthTexts.editProfile,
      en: en.AuthTexts.editProfile,
    ),
    'Upload profile photo': (
      ar: ar.AuthTexts.uploadProfilePhoto,
      en: en.AuthTexts.uploadProfilePhoto,
    ),
    'Uploading profile photo...': (
      ar: ar.AuthTexts.uploadingProfilePhoto,
      en: en.AuthTexts.uploadingProfilePhoto,
    ),
    'Could not load your profile.': (
      ar: ar.AuthTexts.couldNotLoadYourProfile,
      en: en.AuthTexts.couldNotLoadYourProfile,
    ),
    'Could not refresh profile': (
      ar: ar.AuthTexts.couldNotRefreshProfile,
      en: en.AuthTexts.couldNotRefreshProfile,
    ),
    'Could not update profile': (
      ar: ar.AuthTexts.couldNotUpdateProfile,
      en: en.AuthTexts.couldNotUpdateProfile,
    ),
    'Could not update profile photo': (
      ar: ar.AuthTexts.couldNotUpdateProfilePhoto,
      en: en.AuthTexts.couldNotUpdateProfilePhoto,
    ),
    'Could not update profile photo.': (
      ar: ar.AuthTexts.couldNotUpdateProfilePhotoLabel,
      en: en.AuthTexts.couldNotUpdateProfilePhotoLabel,
    ),
    'Update your profile information': (
      ar: ar.AuthTexts.updateYourProfileInformation,
      en: en.AuthTexts.updateYourProfileInformation,
    ),
    'This information appears on your يلا ماركت profile.': (
      ar: ar.AuthTexts.thisInformationAppearsOnYourProfile,
      en: en.AuthTexts.thisInformationAppearsOnYourProfile,
    ),
    'We use your account details to secure your profile and personalize shopping.':
        (
          ar: ar.AuthTexts.weUseYourAccountDetailsToSecureYourProfileAnd,
          en: en.AuthTexts.weUseYourAccountDetailsToSecureYourProfileAnd,
        ),
    'Account Settings': (
      ar: ar.AuthTexts.accountSettings,
      en: en.AuthTexts.accountSettings,
    ),
    'Account secured': (
      ar: ar.AuthTexts.accountSecured,
      en: en.AuthTexts.accountSecured,
    ),
    'Account unavailable': (
      ar: ar.AuthTexts.accountUnavailable,
      en: en.AuthTexts.accountUnavailable,
    ),
    'Account, orders and preferences': (
      ar: ar.AuthTexts.accountOrdersAndPreferences,
      en: en.AuthTexts.accountOrdersAndPreferences,
    ),
    'Your account uses secure sign-in and controlled data sharing.': (
      ar: ar.AuthTexts.yourAccountUsesSecureSignInAndControlledDataSharing,
      en: en.AuthTexts.yourAccountUsesSecureSignInAndControlledDataSharing,
    ),
    'Keep your account information accurate and protect your password.': (
      ar: ar.AuthTexts.keepYourAccountInformationAccurateAndProtectYourPassword,
      en: en.AuthTexts.keepYourAccountInformationAccurateAndProtectYourPassword,
    ),
    'We use your account and delivery information only to provide, secure, and improve Yalla Market services.':
        (
          ar: ar.AuthTexts.weUseYourAccountAndDeliveryInformationOnlyToProvide,
          en: en.AuthTexts.weUseYourAccountAndDeliveryInformationOnlyToProvide,
        ),
    'Use accurate account and delivery details and keep your password private.':
        (
          ar: ar
              .AuthTexts
              .useAccurateAccountAndDeliveryDetailsAndKeepYourPassword,
          en: en
              .AuthTexts
              .useAccurateAccountAndDeliveryDetailsAndKeepYourPassword,
        ),
    'Your email and phone number help with verification, delivery updates, and recovery.':
        (
          ar: ar
              .AuthTexts
              .yourEmailAndPhoneNumberHelpWithVerificationDeliveryUpdates,
          en: en
              .AuthTexts
              .yourEmailAndPhoneNumberHelpWithVerificationDeliveryUpdates,
        ),
    'Username': (ar: ar.AuthTexts.username, en: en.AuthTexts.username),
    'Username check skipped': (
      ar: ar.AuthTexts.usernameCheckSkipped,
      en: en.AuthTexts.usernameCheckSkipped,
    ),
    'Username locked': (
      ar: ar.AuthTexts.usernameLocked,
      en: en.AuthTexts.usernameLocked,
    ),
    'Username can only be changed once every 7 days.': (
      ar: ar.AuthTexts.usernameCanOnlyBeChangedOnceEvery7Days,
      en: en.AuthTexts.usernameCanOnlyBeChangedOnceEvery7Days,
    ),
    'You can change your username again on': (
      ar: ar.AuthTexts.youCanChangeYourUsernameAgainOn,
      en: en.AuthTexts.youCanChangeYourUsernameAgainOn,
    ),
    'After saving, you can change your username again after 7 days.': (
      ar: ar.AuthTexts.afterSavingYouCanChangeYourUsernameAgainAfter7,
      en: en.AuthTexts.afterSavingYouCanChangeYourUsernameAgainAfter7,
    ),
    'After saving a new username, you will not be able to change it again for 7 days.':
        (
          ar: ar.AuthTexts.afterSavingANewUsernameYouWillNotBeAble,
          en: en.AuthTexts.afterSavingANewUsernameYouWillNotBeAble,
        ),
    'Change username?': (
      ar: ar.AuthTexts.changeUsername,
      en: en.AuthTexts.changeUsername,
    ),
    'Change Username': (
      ar: ar.AuthTexts.changeUsernameLabel,
      en: en.AuthTexts.changeUsernameLabel,
    ),
    'Checking username...': (
      ar: ar.AuthTexts.checkingUsername,
      en: en.AuthTexts.checkingUsername,
    ),
    'Could not check this username.': (
      ar: ar.AuthTexts.couldNotCheckThisUsername,
      en: en.AuthTexts.couldNotCheckThisUsername,
    ),
    'Could not check username right now.': (
      ar: ar.AuthTexts.couldNotCheckUsernameRightNow,
      en: en.AuthTexts.couldNotCheckUsernameRightNow,
    ),
    'This username is already taken': (
      ar: ar.AuthTexts.thisUsernameIsAlreadyTaken,
      en: en.AuthTexts.thisUsernameIsAlreadyTaken,
    ),
    'This username is already taken.': (
      ar: ar.AuthTexts.thisUsernameIsAlreadyTakenLabel,
      en: en.AuthTexts.thisUsernameIsAlreadyTakenLabel,
    ),
    'Username is available.': (
      ar: ar.AuthTexts.usernameIsAvailable,
      en: en.AuthTexts.usernameIsAvailable,
    ),
    'Username is too long': (
      ar: ar.AuthTexts.usernameIsTooLong,
      en: en.AuthTexts.usernameIsTooLong,
    ),
    'Username must be at least 3 characters': (
      ar: ar.AuthTexts.usernameMustBeAtLeast3Characters,
      en: en.AuthTexts.usernameMustBeAtLeast3Characters,
    ),
    'Username must include a letter': (
      ar: ar.AuthTexts.usernameMustIncludeALetter,
      en: en.AuthTexts.usernameMustIncludeALetter,
    ),
    'Username unavailable': (
      ar: ar.AuthTexts.usernameUnavailable,
      en: en.AuthTexts.usernameUnavailable,
    ),
    'You can change your username again after 7 days.': (
      ar: ar.AuthTexts.youCanChangeYourUsernameAgainAfter7Days,
      en: en.AuthTexts.youCanChangeYourUsernameAgainAfter7Days,
    ),
    'Use letters, numbers, dots, and underscores only': (
      ar: ar.AuthTexts.useLettersNumbersDotsAndUnderscoresOnly,
      en: en.AuthTexts.useLettersNumbersDotsAndUnderscoresOnly,
    ),
    'Use English letters, dots, and underscores only': (
      ar: ar.AuthTexts.useEnglishLettersDotsAndUnderscoresOnly,
      en: en.AuthTexts.useEnglishLettersDotsAndUnderscoresOnly,
    ),
    'Use English letters, numbers, dots, and underscores only': (
      ar: ar.AuthTexts.useEnglishLettersNumbersDotsAndUnderscoresOnly,
      en: en.AuthTexts.useEnglishLettersNumbersDotsAndUnderscoresOnly,
    ),
    'E-Mail': (ar: ar.AuthTexts.email, en: en.AuthTexts.email),
    'E-mail': (ar: ar.AuthTexts.eMail, en: en.AuthTexts.eMail),
    'Email updates': (
      ar: ar.AuthTexts.emailUpdates,
      en: en.AuthTexts.emailUpdates,
    ),
    'Change Email': (
      ar: ar.AuthTexts.changeEmail,
      en: en.AuthTexts.changeEmail,
    ),
    'Checking email...': (
      ar: ar.AuthTexts.checkingEmail,
      en: en.AuthTexts.checkingEmail,
    ),
    'Could not check this email.': (
      ar: ar.AuthTexts.couldNotCheckThisEmail,
      en: en.AuthTexts.couldNotCheckThisEmail,
    ),
    'Could not check email right now.': (
      ar: ar.AuthTexts.couldNotCheckEmailRightNow,
      en: en.AuthTexts.couldNotCheckEmailRightNow,
    ),
    'Email check skipped': (
      ar: ar.AuthTexts.emailCheckSkipped,
      en: en.AuthTexts.emailCheckSkipped,
    ),
    'Email check failed': (
      ar: ar.AuthTexts.emailCheckFailed,
      en: en.AuthTexts.emailCheckFailed,
    ),
    'Email cannot be changed': (
      ar: ar.AuthTexts.emailCannotBeChanged,
      en: en.AuthTexts.emailCannotBeChanged,
    ),
    'Contact support if you need help with your account email.': (
      ar: ar.AuthTexts.contactSupportIfYouNeedHelpWithYourAccountEmail,
      en: en.AuthTexts.contactSupportIfYouNeedHelpWithYourAccountEmail,
    ),
    'Email is already registered.': (
      ar: ar.AuthTexts.emailIsAlreadyRegistered,
      en: en.AuthTexts.emailIsAlreadyRegistered,
    ),
    'Email is available.': (
      ar: ar.AuthTexts.emailIsAvailable,
      en: en.AuthTexts.emailIsAvailable,
    ),
    'Email unavailable': (
      ar: ar.AuthTexts.emailUnavailable,
      en: en.AuthTexts.emailUnavailable,
    ),
    'This email is already registered.': (
      ar: ar.AuthTexts.thisEmailIsAlreadyRegistered,
      en: en.AuthTexts.thisEmailIsAlreadyRegistered,
    ),
    'This email is not registered.': (
      ar: ar.AuthTexts.thisEmailIsNotRegistered,
      en: en.AuthTexts.thisEmailIsNotRegistered,
    ),
    'Email verification is required.': (
      ar: ar.AuthTexts.emailVerificationIsRequired,
      en: en.AuthTexts.emailVerificationIsRequired,
    ),
    'Check the email and try again.': (
      ar: ar.AuthTexts.checkTheEmailAndTryAgain,
      en: en.AuthTexts.checkTheEmailAndTryAgain,
    ),
    'Phone': (ar: ar.AuthTexts.phone, en: en.AuthTexts.phone),
    'Phone Number': (
      ar: ar.AuthTexts.phoneNumber,
      en: en.AuthTexts.phoneNumber,
    ),
    'Activation phone': (
      ar: ar.AuthTexts.activationPhone,
      en: en.AuthTexts.activationPhone,
    ),
    'Change Phone': (
      ar: ar.AuthTexts.changePhone,
      en: en.AuthTexts.changePhone,
    ),
    'Checking phone number...': (
      ar: ar.AuthTexts.checkingPhoneNumber,
      en: en.AuthTexts.checkingPhoneNumber,
    ),
    'Could not check this phone number.': (
      ar: ar.AuthTexts.couldNotCheckThisPhoneNumber,
      en: en.AuthTexts.couldNotCheckThisPhoneNumber,
    ),
    'Could not check phone number right now.': (
      ar: ar.AuthTexts.couldNotCheckPhoneNumberRightNow,
      en: en.AuthTexts.couldNotCheckPhoneNumberRightNow,
    ),
    'Phone check skipped': (
      ar: ar.AuthTexts.phoneCheckSkipped,
      en: en.AuthTexts.phoneCheckSkipped,
    ),
    'Phone number is already registered.': (
      ar: ar.AuthTexts.phoneNumberIsAlreadyRegistered,
      en: en.AuthTexts.phoneNumberIsAlreadyRegistered,
    ),
    'Phone number is available.': (
      ar: ar.AuthTexts.phoneNumberIsAvailable,
      en: en.AuthTexts.phoneNumberIsAvailable,
    ),
    'Phone unavailable': (
      ar: ar.AuthTexts.phoneUnavailable,
      en: en.AuthTexts.phoneUnavailable,
    ),
    'This phone number is already registered.': (
      ar: ar.AuthTexts.thisPhoneNumberIsAlreadyRegistered,
      en: en.AuthTexts.thisPhoneNumberIsAlreadyRegistered,
    ),
    'This is already your current phone number.': (
      ar: ar.AuthTexts.thisIsAlreadyYourCurrentPhoneNumber,
      en: en.AuthTexts.thisIsAlreadyYourCurrentPhoneNumber,
    ),
    'Enter a valid phone number': (
      ar: ar.AuthTexts.enterAValidPhoneNumber,
      en: en.AuthTexts.enterAValidPhoneNumber,
    ),
    'Please enter a valid phone number': (
      ar: ar.AuthTexts.invalidPhone,
      en: en.AuthTexts.invalidPhone,
    ),
    '8+ characters': (
      ar: ar.AuthTexts.label8Characters,
      en: en.AuthTexts.label8Characters,
    ),
    'Number & symbol': (
      ar: ar.AuthTexts.numberSymbol,
      en: en.AuthTexts.numberSymbol,
    ),
    'Upper & lowercase': (
      ar: ar.AuthTexts.upperLowercase,
      en: en.AuthTexts.upperLowercase,
    ),
    'Password': (ar: ar.AuthTexts.password, en: en.AuthTexts.password),
    'Password required': (
      ar: ar.AuthTexts.passwordRequired,
      en: en.AuthTexts.passwordRequired,
    ),
    'Password is required.': (
      ar: ar.AuthTexts.passwordIsRequired,
      en: en.AuthTexts.passwordIsRequired,
    ),
    'Enter your password first.': (
      ar: ar.AuthTexts.enterYourPasswordFirst,
      en: en.AuthTexts.enterYourPasswordFirst,
    ),
    'Passwords do not match.': (
      ar: ar.AuthTexts.passwordsDoNotMatch,
      en: en.AuthTexts.passwordsDoNotMatch,
    ),
    'Weak password': (
      ar: ar.AuthTexts.weakPassword,
      en: en.AuthTexts.weakPassword,
    ),
    'Medium password': (
      ar: ar.AuthTexts.mediumPassword,
      en: en.AuthTexts.mediumPassword,
    ),
    'Strong password': (
      ar: ar.AuthTexts.strongPassword,
      en: en.AuthTexts.strongPassword,
    ),
    'The password is incorrect.': (
      ar: ar.AuthTexts.thePasswordIsIncorrect,
      en: en.AuthTexts.thePasswordIsIncorrect,
    ),
    'Invalid password': (
      ar: ar.AuthTexts.invalidPassword,
      en: en.AuthTexts.invalidPassword,
    ),
    'Invalid password.': (
      ar: ar.AuthTexts.invalidPasswordLabel,
      en: en.AuthTexts.invalidPasswordLabel,
    ),
    'New password must be different from your current password': (
      ar: ar.AuthTexts.newPasswordMustBeDifferentFromYourCurrentPassword,
      en: en.AuthTexts.newPasswordMustBeDifferentFromYourCurrentPassword,
    ),
    'New password must be different from your current password.': (
      ar: ar.AuthTexts.newPasswordMustBeDifferentFromYourCurrentPasswordLabel,
      en: en.AuthTexts.newPasswordMustBeDifferentFromYourCurrentPasswordLabel,
    ),
    'Forget Password?': (
      ar: ar.AuthTexts.forgetPassword,
      en: en.AuthTexts.forgetPassword,
    ),
    'Forgot Password?': (
      ar: ar.AuthTexts.forgetPasswordLink,
      en: en.AuthTexts.forgetPasswordLink,
    ),
    'Account Security': (
      ar: ar.AuthTexts.accountSecurity,
      en: en.AuthTexts.accountSecurity,
    ),
    'Change Password': (
      ar: ar.AuthTexts.changePassword,
      en: en.AuthTexts.changePassword,
    ),
    'Verify your email to set a new password': (
      ar: ar.AuthTexts.verifyYourEmailToSetANewPassword,
      en: en.AuthTexts.verifyYourEmailToSetANewPassword,
    ),
    'Verification code sent': (
      ar: ar.AuthTexts.verificationCodeSent,
      en: en.AuthTexts.verificationCodeSent,
    ),
    'Verification code': (
      ar: ar.AuthTexts.verificationCode,
      en: en.AuthTexts.verificationCode,
    ),
    'Enter the 6-digit verification code.': (
      ar: ar.AuthTexts.enterThe6DigitVerificationCode,
      en: en.AuthTexts.enterThe6DigitVerificationCode,
    ),
    'New Password': (
      ar: ar.AuthTexts.newPassword,
      en: en.AuthTexts.newPassword,
    ),
    'Confirm New Password': (
      ar: ar.AuthTexts.confirmNewPassword,
      en: en.AuthTexts.confirmNewPassword,
    ),
    'Password changed': (
      ar: ar.AuthTexts.passwordChanged,
      en: en.AuthTexts.passwordChanged,
    ),
    'Your password was changed successfully. Sign in again to continue.': (
      ar: ar.AuthTexts.yourPasswordWasChangedSuccessfullySignInAgainToContinue,
      en: en.AuthTexts.yourPasswordWasChangedSuccessfullySignInAgainToContinue,
    ),
    'Could not send verification code': (
      ar: ar.AuthTexts.couldNotSendVerificationCode,
      en: en.AuthTexts.couldNotSendVerificationCode,
    ),
    'Could not change password': (
      ar: ar.AuthTexts.couldNotChangePassword,
      en: en.AuthTexts.couldNotChangePassword,
    ),
    'Invalid verification code': (
      ar: ar.AuthTexts.invalidVerificationCode,
      en: en.AuthTexts.invalidVerificationCode,
    ),
    'Invalid verification code.': (
      ar: ar.AuthTexts.invalidVerificationCodeLabel,
      en: en.AuthTexts.invalidVerificationCodeLabel,
    ),
    'Invalid or expired verification code': (
      ar: ar.AuthTexts.invalidOrExpiredVerificationCode,
      en: en.AuthTexts.invalidOrExpiredVerificationCode,
    ),
    'Invalid or expired verification code.': (
      ar: ar.AuthTexts.invalidOrExpiredVerificationCodeLabel,
      en: en.AuthTexts.invalidOrExpiredVerificationCodeLabel,
    ),
    'The verification code has expired.': (
      ar: ar.AuthTexts.theVerificationCodeHasExpired,
      en: en.AuthTexts.theVerificationCodeHasExpired,
    ),
    'No active verification code was found.': (
      ar: ar.AuthTexts.noActiveVerificationCodeWasFound,
      en: en.AuthTexts.noActiveVerificationCodeWasFound,
    ),
    'Two-step verification': (
      ar: ar.AuthTexts.twoStepVerification,
      en: en.AuthTexts.twoStepVerification,
    ),
    'Account deletion now requires your account password for confirmation.': (
      ar: ar
          .AuthTexts
          .accountDeletionNowRequiresYourAccountPasswordForConfirmation,
      en: en
          .AuthTexts
          .accountDeletionNowRequiresYourAccountPasswordForConfirmation,
    ),
    'You can use the code already sent to your email.': (
      ar: ar.AuthTexts.youCanUseTheCodeAlreadySentToYourEmail,
      en: en.AuthTexts.youCanUseTheCodeAlreadySentToYourEmail,
    ),
    'You can use the code already sent to your email. You can request another code when the timer ends.':
        (
          ar: ar.AuthTexts.youCanUseTheCodeAlreadySentToYourEmailLabel,
          en: en.AuthTexts.youCanUseTheCodeAlreadySentToYourEmailLabel,
        ),
    'Delete Account': (
      ar: ar.AuthTexts.deleteAccount,
      en: en.AuthTexts.deleteAccount,
    ),
    'Delete account permanently?': (
      ar: ar.AuthTexts.deleteAccountPermanently,
      en: en.AuthTexts.deleteAccountPermanently,
    ),
    'Account was not deleted': (
      ar: ar.AuthTexts.accountWasNotDeleted,
      en: en.AuthTexts.accountWasNotDeleted,
    ),
    'Could not delete your account.': (
      ar: ar.AuthTexts.couldNotDeleteYourAccount,
      en: en.AuthTexts.couldNotDeleteYourAccount,
    ),
    'Permanently remove your يلا ماركت profile': (
      ar: ar.AuthTexts.permanentlyRemoveYourProfile,
      en: en.AuthTexts.permanentlyRemoveYourProfile,
    ),
    'Permanently remove your Yalla Market profile': (
      ar: ar.AuthTexts.permanentlyRemoveYourYallaMarketProfile,
      en: en.AuthTexts.permanentlyRemoveYourYallaMarketProfile,
    ),
    'Permanently remove your profile and personal data': (
      ar: ar.AuthTexts.permanentlyRemoveYourProfileAndPersonalData,
      en: en.AuthTexts.permanentlyRemoveYourProfileAndPersonalData,
    ),
    'This cannot be undone. Enter your account password to confirm permanent deletion.':
        (
          ar: ar.AuthTexts.thisCannotBeUndoneEnterYourAccountPasswordToConfirm,
          en: en.AuthTexts.thisCannotBeUndoneEnterYourAccountPasswordToConfirm,
        ),
    'Deleting your account removes your profile, saved addresses, cart, reviews, and order history. This cannot be undone.':
        (
          ar: ar
              .AuthTexts
              .deletingYourAccountRemovesYourProfileSavedAddressesCartReviews,
          en: en
              .AuthTexts
              .deletingYourAccountRemovesYourProfileSavedAddressesCartReviews,
        ),
    'Finish or cancel any active orders first.': (
      ar: ar.AuthTexts.finishOrCancelAnyActiveOrdersFirst,
      en: en.AuthTexts.finishOrCancelAnyActiveOrdersFirst,
    ),
    'Review active refunds before deleting.': (
      ar: ar.AuthTexts.reviewActiveRefundsBeforeDeleting,
      en: en.AuthTexts.reviewActiveRefundsBeforeDeleting,
    ),
    'Orders, deals and account updates': (
      ar: ar.AuthTexts.ordersDealsAndAccountUpdates,
      en: en.AuthTexts.ordersDealsAndAccountUpdates,
    ),
    'Order, offer, and account updates will appear here.': (
      ar: ar.AuthTexts.orderOfferAndAccountUpdatesWillAppearHere,
      en: en.AuthTexts.orderOfferAndAccountUpdatesWillAppearHere,
    ),
    'Offers, order updates, and account alerts': (
      ar: ar.AuthTexts.offersOrderUpdatesAndAccountAlerts,
      en: en.AuthTexts.offersOrderUpdatesAndAccountAlerts,
    ),
    'Deals, order updates and account alerts.': (
      ar: ar.AuthTexts.dealsOrderUpdatesAndAccountAlerts,
      en: en.AuthTexts.dealsOrderUpdatesAndAccountAlerts,
    ),
    'Misuse of offers, accounts, or payment methods may limit access to the app.':
        (
          ar: ar.AuthTexts.misuseOfOffersAccountsOrPaymentMethodsMayLimitAccess,
          en: en.AuthTexts.misuseOfOffersAccountsOrPaymentMethodsMayLimitAccess,
        ),
    'Support, orders and account help': (
      ar: ar.AuthTexts.supportOrdersAndAccountHelp,
      en: en.AuthTexts.supportOrdersAndAccountHelp,
    ),
    'Quicker help with orders, returns, and account issues.': (
      ar: ar.AuthTexts.quickerHelpWithOrdersReturnsAndAccountIssues,
      en: en.AuthTexts.quickerHelpWithOrdersReturnsAndAccountIssues,
    ),
    'Stay close to orders, offers and account activity.': (
      ar: ar.AuthTexts.stayCloseToOrdersOffersAndAccountActivity,
      en: en.AuthTexts.stayCloseToOrdersOffersAndAccountActivity,
    ),
    'Receive account and privacy alerts.': (
      ar: ar.AuthTexts.receiveAccountAndPrivacyAlerts,
      en: en.AuthTexts.receiveAccountAndPrivacyAlerts,
    ),
    'Open My Orders from the account page to see the latest order status and delivery updates.':
        (
          ar: ar.AuthTexts.openMyOrdersFromTheAccountPageToSeeThe,
          en: en.AuthTexts.openMyOrdersFromTheAccountPageToSeeThe,
        ),
    'Use the WhatsApp button on the account page for direct assistance.': (
      ar: ar.AuthTexts.useTheWhatsAppButtonOnTheAccountPageForDirect,
      en: en.AuthTexts.useTheWhatsAppButtonOnTheAccountPageForDirect,
    ),
    'Use 8+ characters with uppercase, lowercase, number, and symbol.': (
      ar: ar.AuthTexts.use8CharactersWithUppercaseLowercaseNumberAndSymbol,
      en: en.AuthTexts.use8CharactersWithUppercaseLowercaseNumberAndSymbol,
    ),
    'Store': (ar: ar.StoreTexts.store, en: en.StoreTexts.store),
    'Shop': (ar: ar.StoreTexts.shop, en: en.StoreTexts.shop),
    'Market': (ar: ar.StoreTexts.market, en: en.StoreTexts.market),
    'Markets': (ar: ar.StoreTexts.markets, en: en.StoreTexts.markets),
    'Popular Stores': (
      ar: ar.StoreTexts.popularStores,
      en: en.StoreTexts.popularStores,
    ),
    'Latest Stores': (
      ar: ar.StoreTexts.latestStores,
      en: en.StoreTexts.latestStores,
    ),
    'Browse all popular stores': (
      ar: ar.StoreTexts.browseAllPopularStores,
      en: en.StoreTexts.browseAllPopularStores,
    ),
    'Popular stores will appear here once available.': (
      ar: ar.StoreTexts.popularStoresWillAppearHereOnceAvailable,
      en: en.StoreTexts.popularStoresWillAppearHereOnceAvailable,
    ),
    'Loading store...': (
      ar: ar.StoreTexts.loadingStore,
      en: en.StoreTexts.loadingStore,
    ),
    'Loading stores...': (
      ar: ar.StoreTexts.loadingStores,
      en: en.StoreTexts.loadingStores,
    ),
    'Store could not load': (
      ar: ar.StoreTexts.storeCouldNotLoad,
      en: en.StoreTexts.storeCouldNotLoad,
    ),
    'Store unavailable': (
      ar: ar.StoreTexts.storeUnavailable,
      en: en.StoreTexts.storeUnavailable,
    ),
    'No stores available': (
      ar: ar.StoreTexts.noStoresAvailable,
      en: en.StoreTexts.noStoresAvailable,
    ),
    'No stores found': (
      ar: ar.StoreTexts.noStoresFound,
      en: en.StoreTexts.noStoresFound,
    ),
    'No store categories': (
      ar: ar.StoreTexts.noStoreCategories,
      en: en.StoreTexts.noStoreCategories,
    ),
    'Browse the newest stores': (
      ar: ar.StoreTexts.browseTheNewestStores,
      en: en.StoreTexts.browseTheNewestStores,
    ),
    'New stores will appear here once added.': (
      ar: ar.StoreTexts.newStoresWillAppearHereOnceAdded,
      en: en.StoreTexts.newStoresWillAppearHereOnceAdded,
    ),
    'Categories will appear here once stores are available.': (
      ar: ar.StoreTexts.categoriesWillAppearHereOnceStoresAreAvailable,
      en: en.StoreTexts.categoriesWillAppearHereOnceStoresAreAvailable,
    ),
    'Products will appear here once this store is ready.': (
      ar: ar.StoreTexts.productsWillAppearHereOnceThisStoreIsReady,
      en: en.StoreTexts.productsWillAppearHereOnceThisStoreIsReady,
    ),
    'Try a different store name.': (
      ar: ar.StoreTexts.tryADifferentStoreName,
      en: en.StoreTexts.tryADifferentStoreName,
    ),
    'Search stores...': (
      ar: ar.StoreTexts.searchStores,
      en: en.StoreTexts.searchStores,
    ),
    'T\'s Store': (ar: ar.StoreTexts.tSStore, en: en.StoreTexts.tSStore),
    'Market breakdown': (
      ar: ar.StoreTexts.marketBreakdown,
      en: en.StoreTexts.marketBreakdown,
    ),
    'Yalla Market': (
      ar: ar.StoreTexts.yallaMarket,
      en: en.StoreTexts.yallaMarket,
    ),
    'Products': (ar: ar.StoreTexts.products, en: en.StoreTexts.products),
    'Items': (ar: ar.StoreTexts.items, en: en.StoreTexts.items),
    'Popular Products': (
      ar: ar.StoreTexts.popularProducts,
      en: en.StoreTexts.popularProducts,
    ),
    'Latest Products': (
      ar: ar.StoreTexts.latestProducts,
      en: en.StoreTexts.latestProducts,
    ),
    'Loading products...': (
      ar: ar.StoreTexts.loadingProducts,
      en: en.StoreTexts.loadingProducts,
    ),
    'Products could not load': (
      ar: ar.StoreTexts.productsCouldNotLoad,
      en: en.StoreTexts.productsCouldNotLoad,
    ),
    'No products available': (
      ar: ar.StoreTexts.noProductsAvailable,
      en: en.StoreTexts.noProductsAvailable,
    ),
    'No products found': (
      ar: ar.StoreTexts.noProductsFound,
      en: en.StoreTexts.noProductsFound,
    ),
    'No products in this section': (
      ar: ar.StoreTexts.noProductsInThisSection,
      en: en.StoreTexts.noProductsInThisSection,
    ),
    'Product is out of stock': (
      ar: ar.StoreTexts.productIsOutOfStock,
      en: en.StoreTexts.productIsOutOfStock,
    ),
    'In Stock': (ar: ar.StoreTexts.inStock, en: en.StoreTexts.inStock),
    'Out of Stock': (
      ar: ar.StoreTexts.outOfStock,
      en: en.StoreTexts.outOfStock,
    ),
    'Stock': (ar: ar.StoreTexts.stock, en: en.StoreTexts.stock),
    'Price': (ar: ar.StoreTexts.price, en: en.StoreTexts.price),
    'EGP {price}': (ar: ar.StoreTexts.egpPrice, en: en.StoreTexts.egpPrice),
    'Item added': (ar: ar.StoreTexts.itemAdded, en: en.StoreTexts.itemAdded),
    'Item removed': (
      ar: ar.StoreTexts.itemRemoved,
      en: en.StoreTexts.itemRemoved,
    ),
    'Minimum quantity is 1': (
      ar: ar.StoreTexts.minimumQuantityIs1,
      en: en.StoreTexts.minimumQuantityIs1,
    ),
    'No items to review': (
      ar: ar.StoreTexts.noItemsToReview,
      en: en.StoreTexts.noItemsToReview,
    ),
    'Select quantity first': (
      ar: ar.StoreTexts.selectQuantityFirst,
      en: en.StoreTexts.selectQuantityFirst,
    ),
    'Browse the latest products': (
      ar: ar.StoreTexts.browseTheLatestProducts,
      en: en.StoreTexts.browseTheLatestProducts,
    ),
    'Browse all curated products': (
      ar: ar.StoreTexts.browseAllCuratedProducts,
      en: en.StoreTexts.browseAllCuratedProducts,
    ),
    'Products will appear here once the catalog is ready.': (
      ar: ar.StoreTexts.productsWillAppearHereOnceTheCatalogIsReady,
      en: en.StoreTexts.productsWillAppearHereOnceTheCatalogIsReady,
    ),
    'Try another product name.': (
      ar: ar.StoreTexts.tryAnotherProductName,
      en: en.StoreTexts.tryAnotherProductName,
    ),
    'Search products...': (
      ar: ar.StoreTexts.searchProducts,
      en: en.StoreTexts.searchProducts,
    ),
    'Explore products': (
      ar: ar.StoreTexts.exploreProducts,
      en: en.StoreTexts.exploreProducts,
    ),
    'Start Shopping': (
      ar: ar.StoreTexts.startShopping,
      en: en.StoreTexts.startShopping,
    ),
    'Continue Shopping': (
      ar: ar.StoreTexts.continueShopping,
      en: en.StoreTexts.continueShopping,
    ),
    'Hide age-restricted products': (
      ar: ar.StoreTexts.hideAgeRestrictedProducts,
      en: en.StoreTexts.hideAgeRestrictedProducts,
    ),
    'Offers': (ar: ar.StoreTexts.offers, en: en.StoreTexts.offers),
    'Nearby offers': (
      ar: ar.StoreTexts.nearbyOffers,
      en: en.StoreTexts.nearbyOffers,
    ),
    'Package offer': (
      ar: ar.StoreTexts.packageOffer,
      en: en.StoreTexts.packageOffer,
    ),
    'Offer price': (ar: ar.StoreTexts.offerPrice, en: en.StoreTexts.offerPrice),
    'Personalized offers': (
      ar: ar.StoreTexts.personalizedOffers,
      en: en.StoreTexts.personalizedOffers,
    ),
    'Curated picks and brand deals': (
      ar: ar.StoreTexts.curatedPicksAndBrandDeals,
      en: en.StoreTexts.curatedPicksAndBrandDeals,
    ),
    'Curated picks and category deals': (
      ar: ar.StoreTexts.curatedPicksAndCategoryDeals,
      en: en.StoreTexts.curatedPicksAndCategoryDeals,
    ),
    'Send this product or copy its link.': (
      ar: ar.StoreTexts.sendThisProductOrCopyItsLink,
      en: en.StoreTexts.sendThisProductOrCopyItsLink,
    ),
    'Copy product link': (
      ar: ar.StoreTexts.copyProductLink,
      en: en.StoreTexts.copyProductLink,
    ),
    'Send this offer or copy its link.': (
      ar: ar.StoreTexts.sendThisOfferOrCopyItsLink,
      en: en.StoreTexts.sendThisOfferOrCopyItsLink,
    ),
    'Brands': (ar: ar.StoreTexts.brands, en: en.StoreTexts.brands),
    'Brands & picks': (
      ar: ar.StoreTexts.brandsPicks,
      en: en.StoreTexts.brandsPicks,
    ),
    'Featured Brands': (
      ar: ar.StoreTexts.featuredBrands,
      en: en.StoreTexts.featuredBrands,
    ),
    'All Brands': (ar: ar.StoreTexts.allBrands, en: en.StoreTexts.allBrands),
    'This brand catalog is empty. Try another brand or check back later.': (
      ar: ar.StoreTexts.thisBrandCatalogIsEmptyTryAnotherBrandOrCheck,
      en: en.StoreTexts.thisBrandCatalogIsEmptyTryAnotherBrandOrCheck,
    ),
    'Categories': (ar: ar.StoreTexts.categories, en: en.StoreTexts.categories),
    'All Categories': (
      ar: ar.StoreTexts.allCategories,
      en: en.StoreTexts.allCategories,
    ),
    'Categories & picks': (
      ar: ar.StoreTexts.categoriesPicks,
      en: en.StoreTexts.categoriesPicks,
    ),
    'Featured Categories': (
      ar: ar.StoreTexts.featuredCategories,
      en: en.StoreTexts.featuredCategories,
    ),
    'Popular Categories': (
      ar: ar.StoreTexts.popularCategories,
      en: en.StoreTexts.popularCategories,
    ),
    'Market sections': (
      ar: ar.StoreTexts.marketSections,
      en: en.StoreTexts.marketSections,
    ),
    'Explore market categories': (
      ar: ar.StoreTexts.exploreMarketCategories,
      en: en.StoreTexts.exploreMarketCategories,
    ),
    'Explore trusted stores': (
      ar: ar.StoreTexts.exploreTrustedStores,
      en: en.StoreTexts.exploreTrustedStores,
    ),
    'Products and categories': (
      ar: ar.StoreTexts.productsAndCategories,
      en: en.StoreTexts.productsAndCategories,
    ),
    'Products, shops and categories': (
      ar: ar.StoreTexts.productsShopsAndCategories,
      en: en.StoreTexts.productsShopsAndCategories,
    ),
    'Search shops': (
      ar: ar.StoreTexts.searchShops,
      en: en.StoreTexts.searchShops,
    ),
    'Search categories': (
      ar: ar.StoreTexts.searchCategories,
      en: en.StoreTexts.searchCategories,
    ),
    'Search products, shops and categories...': (
      ar: ar.StoreTexts.searchProductsShopsAndCategories,
      en: en.StoreTexts.searchProductsShopsAndCategories,
    ),
    'Try a product, shop or category name.': (
      ar: ar.StoreTexts.tryAProductShopOrCategoryName,
      en: en.StoreTexts.tryAProductShopOrCategoryName,
    ),
    'Load more products': (
      ar: ar.StoreTexts.loadMoreProducts,
      en: en.StoreTexts.loadMoreProducts,
    ),
    'Please login to search': (
      ar: ar.StoreTexts.pleaseLoginToSearch,
      en: en.StoreTexts.pleaseLoginToSearch,
    ),
    'Products, brands and categories': (
      ar: ar.StoreTexts.productsBrandsAndCategories,
      en: en.StoreTexts.productsBrandsAndCategories,
    ),
    'This category is empty. Try another category or check back later.': (
      ar: ar.StoreTexts.thisCategoryIsEmptyTryAnotherCategoryOrCheckBack,
      en: en.StoreTexts.thisCategoryIsEmptyTryAnotherCategoryOrCheckBack,
    ),
    'Filter products...': (
      ar: ar.StoreTexts.filterProducts,
      en: en.StoreTexts.filterProducts,
    ),
    'Sort by': (ar: ar.StoreTexts.sortBy, en: en.StoreTexts.sortBy),
    'Sort products': (
      ar: ar.StoreTexts.sortProducts,
      en: en.StoreTexts.sortProducts,
    ),
    'Higher Price': (
      ar: ar.StoreTexts.higherPrice,
      en: en.StoreTexts.higherPrice,
    ),
    'Lower Price': (ar: ar.StoreTexts.lowerPrice, en: en.StoreTexts.lowerPrice),
    'Search brands, products...': (
      ar: ar.StoreTexts.searchBrandsProducts,
      en: en.StoreTexts.searchBrandsProducts,
    ),
    'Search products, brands...': (
      ar: ar.StoreTexts.searchProductsBrands,
      en: en.StoreTexts.searchProductsBrands,
    ),
    'Search products, brands, categories...': (
      ar: ar.StoreTexts.searchProductsBrandsCategories,
      en: en.StoreTexts.searchProductsBrandsCategories,
    ),
    'Search categories, products...': (
      ar: ar.StoreTexts.searchCategoriesProducts,
      en: en.StoreTexts.searchCategoriesProducts,
    ),
    'Search products and categories...': (
      ar: ar.StoreTexts.searchProductsAndCategories,
      en: en.StoreTexts.searchProductsAndCategories,
    ),
    'Try a brand, category, or a shorter product name.': (
      ar: ar.StoreTexts.tryABrandCategoryOrAShorterProductName,
      en: en.StoreTexts.tryABrandCategoryOrAShorterProductName,
    ),
    'Try a category or a shorter product name.': (
      ar: ar.StoreTexts.tryACategoryOrAShorterProductName,
      en: en.StoreTexts.tryACategoryOrAShorterProductName,
    ),
    'Try product names, brands, categories, or sale keywords.': (
      ar: ar.StoreTexts.tryProductNamesBrandsCategoriesOrSaleKeywords,
      en: en.StoreTexts.tryProductNamesBrandsCategoriesOrSaleKeywords,
    ),
    'Try product names, categories, or sale keywords.': (
      ar: ar.StoreTexts.tryProductNamesCategoriesOrSaleKeywords,
      en: en.StoreTexts.tryProductNamesCategoriesOrSaleKeywords,
    ),
    'Try another search, category, or sorting option.': (
      ar: ar.StoreTexts.tryAnotherSearchCategoryOrSortingOption,
      en: en.StoreTexts.tryAnotherSearchCategoryOrSortingOption,
    ),
    'Try it from the web preview.': (
      ar: ar.StoreTexts.tryItFromTheWebPreview,
      en: en.StoreTexts.tryItFromTheWebPreview,
    ),
    'Saved products and stores': (
      ar: ar.StoreTexts.savedProductsAndStores,
      en: en.StoreTexts.savedProductsAndStores,
    ),
    'General products and offers will be shown.': (
      ar: ar.StoreTexts.generalProductsAndOffersWillBeShown,
      en: en.StoreTexts.generalProductsAndOffersWillBeShown,
    ),
    'You will see general products and offers.': (
      ar: ar.StoreTexts.youWillSeeGeneralProductsAndOffers,
      en: en.StoreTexts.youWillSeeGeneralProductsAndOffers,
    ),
    'Fixed-price delivery': (
      ar: ar.StoreTexts.fixedPriceDelivery,
      en: en.StoreTexts.fixedPriceDelivery,
    ),
    'Delivery - price determined later': (
      ar: ar.StoreTexts.deliveryPriceDeterminedLater,
      en: en.StoreTexts.deliveryPriceDeterminedLater,
    ),
    'Delivery: EGP {price}': (
      ar: ar.StoreTexts.deliveryEgpPrice,
      en: en.StoreTexts.deliveryEgpPrice,
    ),
    'Yalla Market makes shopping from local markets simple and fast.': (
      ar: ar.StoreTexts.yallaMarketMakesShoppingFromLocalMarketsSimpleAndFast,
      en: en.StoreTexts.yallaMarketMakesShoppingFromLocalMarketsSimpleAndFast,
    ),
    'Simple shopping from trusted local markets.': (
      ar: ar.StoreTexts.simpleShoppingFromTrustedLocalMarkets,
      en: en.StoreTexts.simpleShoppingFromTrustedLocalMarkets,
    ),
    'Using Yalla Market': (
      ar: ar.StoreTexts.usingYallaMarket,
      en: en.StoreTexts.usingYallaMarket,
    ),
    'Local prices and delivery': (
      ar: ar.StoreTexts.localPricesAndDelivery,
      en: en.StoreTexts.localPricesAndDelivery,
    ),
    'Shopping setup': (
      ar: ar.StoreTexts.shoppingSetup,
      en: en.StoreTexts.shoppingSetup,
    ),
    'Pending review': (
      ar: ar.StoreTexts.pendingReview,
      en: en.StoreTexts.pendingReview,
    ),
    'Review': (ar: ar.StoreTexts.review, en: en.StoreTexts.review),
    'Preview sales before they go live.': (
      ar: ar.StoreTexts.previewSalesBeforeTheyGoLive,
      en: en.StoreTexts.previewSalesBeforeTheyGoLive,
    ),
    'Use shopping activity for better deals.': (
      ar: ar.StoreTexts.useShoppingActivityForBetterDeals,
      en: en.StoreTexts.useShoppingActivityForBetterDeals,
    ),
    'Your item will be shipped soon!': (
      ar: ar.StoreTexts.yourItemWillBeShippedSoon,
      en: en.StoreTexts.yourItemWillBeShippedSoon,
    ),
    'Ratings and reviews are verified and are from people who use the same type of device that you use.':
        (
          ar: ar.StoreTexts.ratingsAndReviewsAreVerifiedAndAreFromPeopleWho,
          en: en.StoreTexts.ratingsAndReviewsAreVerifiedAndAreFromPeopleWho,
        ),
    'Save the products you love and find them here whenever you are ready.': (
      ar: ar.StoreTexts.saveTheProductsYouLoveAndFindThemHereWhenever,
      en: en.StoreTexts.saveTheProductsYouLoveAndFindThemHereWhenever,
    ),
    'Tune shopping, alerts and data usage': (
      ar: ar.StoreTexts.tuneShoppingAlertsAndDataUsage,
      en: en.StoreTexts.tuneShoppingAlertsAndDataUsage,
    ),
    'Fresh picks are available in the most requested categories.': (
      ar: ar.StoreTexts.freshPicksAreAvailableInTheMostRequestedCategories,
      en: en.StoreTexts.freshPicksAreAvailableInTheMostRequestedCategories,
    ),
    'United Arab Emirates': (
      ar: ar.StoreTexts.unitedArabEmirates,
      en: en.StoreTexts.unitedArabEmirates,
    ),
    'United Kingdom': (
      ar: ar.StoreTexts.unitedKingdom,
      en: en.StoreTexts.unitedKingdom,
    ),
    'United States': (
      ar: ar.StoreTexts.unitedStates,
      en: en.StoreTexts.unitedStates,
    ),
    'Cart': (ar: ar.OrderTexts.cart, en: en.OrderTexts.cart),
    'My Cart': (ar: ar.OrderTexts.myCart, en: en.OrderTexts.myCart),
    'Your cart is empty': (
      ar: ar.OrderTexts.yourCartIsEmpty,
      en: en.OrderTexts.yourCartIsEmpty,
    ),
    'Add to cart': (ar: ar.OrderTexts.addToCart, en: en.OrderTexts.addToCart),
    'Add items to your cart before checkout.': (
      ar: ar.OrderTexts.addItemsToYourCartBeforeCheckout,
      en: en.OrderTexts.addItemsToYourCartBeforeCheckout,
    ),
    'Add products you like and review them here before checkout.': (
      ar: ar.OrderTexts.addProductsYouLikeAndReviewThemHereBeforeCheckout,
      en: en.OrderTexts.addProductsYouLikeAndReviewThemHereBeforeCheckout,
    ),
    'Add, remove products and move to checkout': (
      ar: ar.OrderTexts.addRemoveProductsAndMoveToCheckout,
      en: en.OrderTexts.addRemoveProductsAndMoveToCheckout,
    ),
    'Product added to cart': (
      ar: ar.OrderTexts.productAddedToCart,
      en: en.OrderTexts.productAddedToCart,
    ),
    'Item removed from cart': (
      ar: ar.OrderTexts.itemRemovedFromCart,
      en: en.OrderTexts.itemRemovedFromCart,
    ),
    'This product cannot be added to cart right now.': (
      ar: ar.OrderTexts.thisProductCannotBeAddedToCartRightNow,
      en: en.OrderTexts.thisProductCannotBeAddedToCartRightNow,
    ),
    'Your cart was cleared and content was refreshed.': (
      ar: ar.OrderTexts.yourCartWasClearedAndContentWasRefreshed,
      en: en.OrderTexts.yourCartWasClearedAndContentWasRefreshed,
    ),
    'Checkout': (ar: ar.OrderTexts.checkout, en: en.OrderTexts.checkout),
    'Checkout failed': (
      ar: ar.OrderTexts.checkoutFailed,
      en: en.OrderTexts.checkoutFailed,
    ),
    'Confirm Order': (
      ar: ar.OrderTexts.confirmOrder,
      en: en.OrderTexts.confirmOrder,
    ),
    'Confirm items and payment': (
      ar: ar.OrderTexts.confirmItemsAndPayment,
      en: en.OrderTexts.confirmItemsAndPayment,
    ),
    'Confirming your order': (
      ar: ar.OrderTexts.confirmingYourOrder,
      en: en.OrderTexts.confirmingYourOrder,
    ),
    'Processing your order': (
      ar: ar.OrderTexts.processingYourOrder,
      en: en.OrderTexts.processingYourOrder,
    ),
    'Please wait while we save your order details.': (
      ar: ar.OrderTexts.pleaseWaitWhileWeSaveYourOrderDetails,
      en: en.OrderTexts.pleaseWaitWhileWeSaveYourOrderDetails,
    ),
    'Payment Method': (
      ar: ar.OrderTexts.paymentMethod,
      en: en.OrderTexts.paymentMethod,
    ),
    'Select Payment Method': (
      ar: ar.OrderTexts.selectPaymentMethod,
      en: en.OrderTexts.selectPaymentMethod,
    ),
    'Payment Success!': (
      ar: ar.OrderTexts.paymentSuccess,
      en: en.OrderTexts.paymentSuccess,
    ),
    'Cash on Delivery': (
      ar: ar.OrderTexts.cashOnDelivery,
      en: en.OrderTexts.cashOnDelivery,
    ),
    'Pay when your order arrives': (
      ar: ar.OrderTexts.payWhenYourOrderArrives,
      en: en.OrderTexts.payWhenYourOrderArrives,
    ),
    'Pay cash': (ar: ar.OrderTexts.payCash, en: en.OrderTexts.payCash),
    'Pay cash & online': (
      ar: ar.OrderTexts.payCashOnline,
      en: en.OrderTexts.payCashOnline,
    ),
    'Payment and sensitive data should only be entered on trusted checkout screens.':
        (
          ar: ar.OrderTexts.paymentAndSensitiveDataShouldOnlyBeEnteredOnTrusted,
          en: en.OrderTexts.paymentAndSensitiveDataShouldOnlyBeEnteredOnTrusted,
        ),
    'Choose where orders should arrive': (
      ar: ar.OrderTexts.chooseWhereOrdersShouldArrive,
      en: en.OrderTexts.chooseWhereOrdersShouldArrive,
    ),
    'Orders': (ar: ar.OrderTexts.orders, en: en.OrderTexts.orders),
    'My Orders': (ar: ar.OrderTexts.myOrders, en: en.OrderTexts.myOrders),
    'Order Summary': (
      ar: ar.OrderTexts.orderSummary,
      en: en.OrderTexts.orderSummary,
    ),
    'Order Review': (
      ar: ar.OrderTexts.orderReview,
      en: en.OrderTexts.orderReview,
    ),
    'Order Total': (ar: ar.OrderTexts.orderTotal, en: en.OrderTexts.orderTotal),
    'Order total': (
      ar: ar.OrderTexts.orderTotalLabel,
      en: en.OrderTexts.orderTotalLabel,
    ),
    'Order confirmed': (
      ar: ar.OrderTexts.orderConfirmed,
      en: en.OrderTexts.orderConfirmed,
    ),
    'Order Confirmed Successfully!': (
      ar: ar.OrderTexts.orderConfirmedSuccessfully,
      en: en.OrderTexts.orderConfirmedSuccessfully,
    ),
    'Order confirmation failed': (
      ar: ar.OrderTexts.orderConfirmationFailed,
      en: en.OrderTexts.orderConfirmationFailed,
    ),
    'Order date': (ar: ar.OrderTexts.orderDate, en: en.OrderTexts.orderDate),
    'Order rejected': (
      ar: ar.OrderTexts.orderRejected,
      en: en.OrderTexts.orderRejected,
    ),
    'Your order #{orderId} was rejected.': (
      ar: ar.OrderTexts.yourOrderOrderIdWasRejected,
      en: en.OrderTexts.yourOrderOrderIdWasRejected,
    ),
    'New order assigned': (
      ar: ar.OrderTexts.newOrderAssigned,
      en: en.OrderTexts.newOrderAssigned,
    ),
    'A new order #{orderId} has been assigned to you.': (
      ar: ar.OrderTexts.aNewOrderOrderIdHasBeenAssignedToYou,
      en: en.OrderTexts.aNewOrderOrderIdHasBeenAssignedToYou,
    ),
    'New order requires review': (
      ar: ar.OrderTexts.newOrderRequiresReview,
      en: en.OrderTexts.newOrderRequiresReview,
    ),
    'Order #{orderId} requires admin review.': (
      ar: ar.OrderTexts.orderOrderIdRequiresAdminReview,
      en: en.OrderTexts.orderOrderIdRequiresAdminReview,
    ),
    'Order tracking visibility': (
      ar: ar.OrderTexts.orderTrackingVisibility,
      en: en.OrderTexts.orderTrackingVisibility,
    ),
    'Orders could not load': (
      ar: ar.OrderTexts.ordersCouldNotLoad,
      en: en.OrderTexts.ordersCouldNotLoad,
    ),
    'Loading orders...': (
      ar: ar.OrderTexts.loadingOrders,
      en: en.OrderTexts.loadingOrders,
    ),
    'No orders in this period': (
      ar: ar.OrderTexts.noOrdersInThisPeriod,
      en: en.OrderTexts.noOrdersInThisPeriod,
    ),
    'In-progress and completed orders': (
      ar: ar.OrderTexts.inProgressAndCompletedOrders,
      en: en.OrderTexts.inProgressAndCompletedOrders,
    ),
    'Order totals are still loading.': (
      ar: ar.OrderTexts.orderTotalsAreStillLoading,
      en: en.OrderTexts.orderTotalsAreStillLoading,
    ),
    'Could not refresh order totals. Try again.': (
      ar: ar.OrderTexts.couldNotRefreshOrderTotalsTryAgain,
      en: en.OrderTexts.couldNotRefreshOrderTotalsTryAgain,
    ),
    'Orders, returns, and cancellations follow the store policies shown at checkout.':
        (
          ar: ar
              .OrderTexts
              .ordersReturnsAndCancellationsFollowTheStorePoliciesShownAt,
          en: en
              .OrderTexts
              .ordersReturnsAndCancellationsFollowTheStorePoliciesShownAt,
        ),
    'Your order has been created successfully.': (
      ar: ar.OrderTexts.yourOrderHasBeenCreatedSuccessfully,
      en: en.OrderTexts.yourOrderHasBeenCreatedSuccessfully,
    ),
    'Delivered': (ar: ar.OrderTexts.delivered, en: en.OrderTexts.delivered),
    'delivery fee': (
      ar: ar.OrderTexts.deliveryFee,
      en: en.OrderTexts.deliveryFee,
    ),
    'Delivery price': (
      ar: ar.OrderTexts.deliveryPrice,
      en: en.OrderTexts.deliveryPrice,
    ),
    'Delivery price will be confirmed later': (
      ar: ar.OrderTexts.deliveryPriceWillBeConfirmedLater,
      en: en.OrderTexts.deliveryPriceWillBeConfirmedLater,
    ),
    'Delivery price approval': (
      ar: ar.OrderTexts.deliveryPriceApproval,
      en: en.OrderTexts.deliveryPriceApproval,
    ),
    'The delivery price was set by the administration. Review it before approving.':
        (
          ar: ar.OrderTexts.theDeliveryPriceWasSetByTheAdministrationReviewIt,
          en: en.OrderTexts.theDeliveryPriceWasSetByTheAdministrationReviewIt,
        ),
    'Approve delivery price': (
      ar: ar.OrderTexts.approveDeliveryPrice,
      en: en.OrderTexts.approveDeliveryPrice,
    ),
    'Delivery price approved': (
      ar: ar.OrderTexts.deliveryPriceApproved,
      en: en.OrderTexts.deliveryPriceApproved,
    ),
    'Could not approve delivery price': (
      ar: ar.OrderTexts.couldNotApproveDeliveryPrice,
      en: en.OrderTexts.couldNotApproveDeliveryPrice,
    ),
    'Fixed delivery price: {price}': (
      ar: ar.OrderTexts.fixedDeliveryPricePrice,
      en: en.OrderTexts.fixedDeliveryPricePrice,
    ),
    'More accurate delivery price later': (
      ar: ar.OrderTexts.moreAccurateDeliveryPriceLater,
      en: en.OrderTexts.moreAccurateDeliveryPriceLater,
    ),
    'External shipping - price later': (
      ar: ar.OrderTexts.externalShippingPriceLater,
      en: en.OrderTexts.externalShippingPriceLater,
    ),
    'Shipping Fee': (
      ar: ar.OrderTexts.shippingFee,
      en: en.OrderTexts.shippingFee,
    ),
    'Shipping Date': (
      ar: ar.OrderTexts.shippingDate,
      en: en.OrderTexts.shippingDate,
    ),
    'Shipping date': (
      ar: ar.OrderTexts.shippingDateLabel,
      en: en.OrderTexts.shippingDateLabel,
    ),
    'Could not load shipping companies.': (
      ar: ar.OrderTexts.couldNotLoadShippingCompanies,
      en: en.OrderTexts.couldNotLoadShippingCompanies,
    ),
    'Shipping companies are still loading.': (
      ar: ar.OrderTexts.shippingCompaniesAreStillLoading,
      en: en.OrderTexts.shippingCompaniesAreStillLoading,
    ),
    '{name} is selected for checkout.': (
      ar: ar.OrderTexts.nameIsSelectedForCheckout,
      en: en.OrderTexts.nameIsSelectedForCheckout,
    ),
    'Discount': (ar: ar.OrderTexts.discount, en: en.OrderTexts.discount),
    'Offer discount': (
      ar: ar.OrderTexts.offerDiscount,
      en: en.OrderTexts.offerDiscount,
    ),
    'Subtotal': (ar: ar.OrderTexts.subtotal, en: en.OrderTexts.subtotal),
    'Market total': (
      ar: ar.OrderTexts.marketTotal,
      en: en.OrderTexts.marketTotal,
    ),
    'Products subtotal': (
      ar: ar.OrderTexts.productsSubtotal,
      en: en.OrderTexts.productsSubtotal,
    ),
    'Tax Fee': (ar: ar.OrderTexts.taxFee, en: en.OrderTexts.taxFee),
    'Total': (ar: ar.OrderTexts.total, en: en.OrderTexts.total),
    'You are offline. Showing saved content; checkout and updates need internet.':
        (
          ar: ar
              .OrderTexts
              .youAreOfflineShowingSavedContentCheckoutAndUpdatesNeed,
          en: en
              .OrderTexts
              .youAreOfflineShowingSavedContentCheckoutAndUpdatesNeed,
        ),
    'Product availability, prices, and delivery times can change before an order is confirmed.':
        (
          ar: ar
              .OrderTexts
              .productAvailabilityPricesAndDeliveryTimesCanChangeBeforeAn,
          en: en
              .OrderTexts
              .productAvailabilityPricesAndDeliveryTimesCanChangeBeforeAn,
        ),
    'Orders and availability': (
      ar: ar.OrderTexts.ordersAndAvailability,
      en: en.OrderTexts.ordersAndAvailability,
    ),
    'Make يلا ماركت feel yours': (
      ar: ar.OrderTexts.makeFeelYours,
      en: en.OrderTexts.makeFeelYours,
    ),
    'Refund from order CWT0152': (
      ar: ar.OrderTexts.refundFromOrderCwt0152,
      en: en.OrderTexts.refundFromOrderCwt0152,
    ),
    'How can I track my order?': (
      ar: ar.OrderTexts.howCanITrackMyOrder,
      en: en.OrderTexts.howCanITrackMyOrder,
    ),
    'Track order': (ar: ar.OrderTexts.trackOrder, en: en.OrderTexts.trackOrder),
    'Track my order': (
      ar: ar.OrderTexts.trackMyOrder,
      en: en.OrderTexts.trackMyOrder,
    ),
    'Active discounts and rewards': (
      ar: ar.OrderTexts.activeDiscountsAndRewards,
      en: en.OrderTexts.activeDiscountsAndRewards,
    ),
    'Allow support to view order status.': (
      ar: ar.OrderTexts.allowSupportToViewOrderStatus,
      en: en.OrderTexts.allowSupportToViewOrderStatus,
    ),
    'Can you track my order?': (
      ar: ar.OrderTexts.canYouTrackMyOrder,
      en: en.OrderTexts.canYouTrackMyOrder,
    ),
    'Faster handling for eligible orders.': (
      ar: ar.OrderTexts.fasterHandlingForEligibleOrders,
      en: en.OrderTexts.fasterHandlingForEligibleOrders,
    ),
    'Fresh products, verified brands, and quick cart actions.': (
      ar: ar.OrderTexts.freshProductsVerifiedBrandsAndQuickCartActions,
      en: en.OrderTexts.freshProductsVerifiedBrandsAndQuickCartActions,
    ),
    'Fresh products, trusted categories, and quick cart actions.': (
      ar: ar.OrderTexts.freshProductsTrustedCategoriesAndQuickCartActions,
      en: en.OrderTexts.freshProductsTrustedCategoriesAndQuickCartActions,
    ),
    'Hi, I need help tracking my latest order.': (
      ar: ar.OrderTexts.hiINeedHelpTrackingMyLatestOrder,
      en: en.OrderTexts.hiINeedHelpTrackingMyLatestOrder,
    ),
    'Sure. Your order is being prepared and should ship today.': (
      ar: ar.OrderTexts.sureYourOrderIsBeingPreparedAndShouldShipToday,
      en: en.OrderTexts.sureYourOrderIsBeingPreparedAndShouldShipToday,
    ),
    'Discounts up to': (
      ar: ar.OrderTexts.discountsUpTo,
      en: en.OrderTexts.discountsUpTo,
    ),
    'Order help, refunds and delivery updates': (
      ar: ar.OrderTexts.orderHelpRefundsAndDeliveryUpdates,
      en: en.OrderTexts.orderHelpRefundsAndDeliveryUpdates,
    ),
    'Orders, refunds and delivery updates': (
      ar: ar.OrderTexts.ordersRefundsAndDeliveryUpdates,
      en: en.OrderTexts.ordersRefundsAndDeliveryUpdates,
    ),
    'Your Nike training order is being prepared.': (
      ar: ar.OrderTexts.yourNikeTrainingOrderIsBeingPrepared,
      en: en.OrderTexts.yourNikeTrainingOrderIsBeingPrepared,
    ),
    'Your sports order is being prepared.': (
      ar: ar.OrderTexts.yourSportsOrderIsBeingPrepared,
      en: en.OrderTexts.yourSportsOrderIsBeingPrepared,
    ),
    'I need a refund.': (
      ar: ar.OrderTexts.iNeedARefund,
      en: en.OrderTexts.iNeedARefund,
    ),
    'Notifications': (
      ar: ar.NotificationTexts.notifications,
      en: en.NotificationTexts.notifications,
    ),
    'Notifications updated': (
      ar: ar.NotificationTexts.notificationsUpdated,
      en: en.NotificationTexts.notificationsUpdated,
    ),
    'Notification deleted': (
      ar: ar.NotificationTexts.notificationDeleted,
      en: en.NotificationTexts.notificationDeleted,
    ),
    'Notification details': (
      ar: ar.NotificationTexts.notificationDetails,
      en: en.NotificationTexts.notificationDetails,
    ),
    'Notifications marked as read': (
      ar: ar.NotificationTexts.notificationsMarkedAsRead,
      en: en.NotificationTexts.notificationsMarkedAsRead,
    ),
    'Loading notifications...': (
      ar: ar.NotificationTexts.loadingNotifications,
      en: en.NotificationTexts.loadingNotifications,
    ),
    'No notifications yet': (
      ar: ar.NotificationTexts.noNotificationsYet,
      en: en.NotificationTexts.noNotificationsYet,
    ),
    'unread notifications': (
      ar: ar.NotificationTexts.unreadNotifications,
      en: en.NotificationTexts.unreadNotifications,
    ),
    'Push notifications': (
      ar: ar.NotificationTexts.pushNotifications,
      en: en.NotificationTexts.pushNotifications,
    ),
    'Mobile Notifications': (
      ar: ar.NotificationTexts.mobileNotifications,
      en: en.NotificationTexts.mobileNotifications,
    ),
    'Refresh notifications': (
      ar: ar.NotificationTexts.refreshNotifications,
      en: en.NotificationTexts.refreshNotifications,
    ),
    'Mark all as read': (
      ar: ar.NotificationTexts.markAllAsRead,
      en: en.NotificationTexts.markAllAsRead,
    ),
    'Delete all notifications': (
      ar: ar.NotificationTexts.deleteAllNotifications,
      en: en.NotificationTexts.deleteAllNotifications,
    ),
    'Delete all notifications?': (
      ar: ar.NotificationTexts.deleteAllNotificationsLabel,
      en: en.NotificationTexts.deleteAllNotificationsLabel,
    ),
    'This will permanently delete all your notifications.': (
      ar: ar.NotificationTexts.thisWillPermanentlyDeleteAllYourNotifications,
      en: en.NotificationTexts.thisWillPermanentlyDeleteAllYourNotifications,
    ),
    'All notifications deleted': (
      ar: ar.NotificationTexts.allNotificationsDeleted,
      en: en.NotificationTexts.allNotificationsDeleted,
    ),
    'Could not delete all notifications.': (
      ar: ar.NotificationTexts.couldNotDeleteAllNotifications,
      en: en.NotificationTexts.couldNotDeleteAllNotifications,
    ),
    'Could not mark notifications as read.': (
      ar: ar.NotificationTexts.couldNotMarkNotificationsAsRead,
      en: en.NotificationTexts.couldNotMarkNotificationsAsRead,
    ),
    'Could not mark notification as read.': (
      ar: ar.NotificationTexts.couldNotMarkNotificationAsRead,
      en: en.NotificationTexts.couldNotMarkNotificationAsRead,
    ),
    'Could not refresh notifications.': (
      ar: ar.NotificationTexts.couldNotRefreshNotifications,
      en: en.NotificationTexts.couldNotRefreshNotifications,
    ),
    'Could not update notifications.': (
      ar: ar.NotificationTexts.couldNotUpdateNotifications,
      en: en.NotificationTexts.couldNotUpdateNotifications,
    ),
    'Notifications could not load': (
      ar: ar.NotificationTexts.notificationsCouldNotLoad,
      en: en.NotificationTexts.notificationsCouldNotLoad,
    ),
    'Wishlist': (ar: ar.FavoriteTexts.wishlist, en: en.FavoriteTexts.wishlist),
    'Favorite products': (
      ar: ar.FavoriteTexts.favoriteProducts,
      en: en.FavoriteTexts.favoriteProducts,
    ),
    'Favorite stores': (
      ar: ar.FavoriteTexts.favoriteStores,
      en: en.FavoriteTexts.favoriteStores,
    ),
    'Saved products and favorites': (
      ar: ar.FavoriteTexts.savedProductsAndFavorites,
      en: en.FavoriteTexts.savedProductsAndFavorites,
    ),
    'Your wishlist is waiting': (
      ar: ar.FavoriteTexts.yourWishlistIsWaiting,
      en: en.FavoriteTexts.yourWishlistIsWaiting,
    ),
    'Added to wishlist': (
      ar: ar.FavoriteTexts.addedToWishlist,
      en: en.FavoriteTexts.addedToWishlist,
    ),
    'Item added to wishlist': (
      ar: ar.FavoriteTexts.itemAddedToWishlist,
      en: en.FavoriteTexts.itemAddedToWishlist,
    ),
    'Item removed from wishlist': (
      ar: ar.FavoriteTexts.itemRemovedFromWishlist,
      en: en.FavoriteTexts.itemRemovedFromWishlist,
    ),
    'Removed from wishlist': (
      ar: ar.FavoriteTexts.removedFromWishlist,
      en: en.FavoriteTexts.removedFromWishlist,
    ),
    'Could not update favorite stores': (
      ar: ar.FavoriteTexts.couldNotUpdateFavoriteStores,
      en: en.FavoriteTexts.couldNotUpdateFavoriteStores,
    ),
    'Store added to favorites': (
      ar: ar.FavoriteTexts.storeAddedToFavorites,
      en: en.FavoriteTexts.storeAddedToFavorites,
    ),
    'Store removed from favorites': (
      ar: ar.FavoriteTexts.storeRemovedFromFavorites,
      en: en.FavoriteTexts.storeRemovedFromFavorites,
    ),
    'Share': (ar: ar.FavoriteTexts.share, en: en.FavoriteTexts.share),
    'Share product': (
      ar: ar.FavoriteTexts.shareProduct,
      en: en.FavoriteTexts.shareProduct,
    ),
    'Share offer': (
      ar: ar.FavoriteTexts.shareOffer,
      en: en.FavoriteTexts.shareOffer,
    ),
    'Share with...': (
      ar: ar.FavoriteTexts.shareWith,
      en: en.FavoriteTexts.shareWith,
    ),
    'Copy link': (ar: ar.FavoriteTexts.copyLink, en: en.FavoriteTexts.copyLink),
    'Product link copied': (
      ar: ar.FavoriteTexts.productLinkCopied,
      en: en.FavoriteTexts.productLinkCopied,
    ),
    'Offer link copied': (
      ar: ar.FavoriteTexts.offerLinkCopied,
      en: en.FavoriteTexts.offerLinkCopied,
    ),
    'You can share it with anyone.': (
      ar: ar.FavoriteTexts.youCanShareItWithAnyone,
      en: en.FavoriteTexts.youCanShareItWithAnyone,
    ),
    'Could not share product': (
      ar: ar.FavoriteTexts.couldNotShareProduct,
      en: en.FavoriteTexts.couldNotShareProduct,
    ),
    'Could not share offer': (
      ar: ar.FavoriteTexts.couldNotShareOffer,
      en: en.FavoriteTexts.couldNotShareOffer,
    ),
    'Could not share store': (
      ar: ar.FavoriteTexts.couldNotShareStore,
      en: en.FavoriteTexts.couldNotShareStore,
    ),
    'Technical Support': (
      ar: ar.PartnerTexts.technicalSupport,
      en: en.PartnerTexts.technicalSupport,
    ),
    'Contact support for assistance.': (
      ar: ar.PartnerTexts.contactSupportForAssistance,
      en: en.PartnerTexts.contactSupportForAssistance,
    ),
    'WhatsApp': (ar: ar.PartnerTexts.whatsapp, en: en.PartnerTexts.whatsapp),
    'Could not open WhatsApp': (
      ar: ar.PartnerTexts.couldNotOpenWhatsApp,
      en: en.PartnerTexts.couldNotOpenWhatsApp,
    ),
    'Not supported here': (
      ar: ar.PartnerTexts.notSupportedHere,
      en: en.PartnerTexts.notSupportedHere,
    ),
    'Support chat': (
      ar: ar.PartnerTexts.supportChat,
      en: en.PartnerTexts.supportChat,
    ),
    'Support chat will be available soon': (
      ar: ar.PartnerTexts.supportChatWillBeAvailableSoon,
      en: en.PartnerTexts.supportChatWillBeAvailableSoon,
    ),
    'Support is online': (
      ar: ar.PartnerTexts.supportIsOnline,
      en: en.PartnerTexts.supportIsOnline,
    ),
    'يلا ماركت Support': (
      ar: ar.PartnerTexts.support,
      en: en.PartnerTexts.support,
    ),
    'How do I contact support?': (
      ar: ar.PartnerTexts.howDoIContactSupport,
      en: en.PartnerTexts.howDoIContactSupport,
    ),
    'Return help': (
      ar: ar.PartnerTexts.returnHelp,
      en: en.PartnerTexts.returnHelp,
    ),
    'Priority support': (
      ar: ar.PartnerTexts.prioritySupport,
      en: en.PartnerTexts.prioritySupport,
    ),
    'I need help with a return.': (
      ar: ar.PartnerTexts.iNeedHelpWithAReturn,
      en: en.PartnerTexts.iNeedHelpWithAReturn,
    ),
    'Thanks. Support will review this and reply shortly.': (
      ar: ar.PartnerTexts.thanksSupportWillReviewThisAndReplyShortly,
      en: en.PartnerTexts.thanksSupportWillReviewThisAndReplyShortly,
    ),
    'About the app': (
      ar: ar.PartnerTexts.aboutTheApp,
      en: en.PartnerTexts.aboutTheApp,
    ),
    'Learn more about Yalla Market': (
      ar: ar.PartnerTexts.learnMoreAboutYallaMarket,
      en: en.PartnerTexts.learnMoreAboutYallaMarket,
    ),
    'About Yalla Market': (
      ar: ar.PartnerTexts.aboutYallaMarket,
      en: en.PartnerTexts.aboutYallaMarket,
    ),
    'Privacy policy': (
      ar: ar.PartnerTexts.privacyPolicy,
      en: en.PartnerTexts.privacyPolicy,
    ),
    'Privacy Policy': (
      ar: ar.PartnerTexts.privacyPolicyLabel,
      en: en.PartnerTexts.privacyPolicyLabel,
    ),
    'Privacy status: protected': (
      ar: ar.PartnerTexts.privacyStatusProtected,
      en: en.PartnerTexts.privacyStatusProtected,
    ),
    'Terms of use': (
      ar: ar.PartnerTexts.termsOfUse,
      en: en.PartnerTexts.termsOfUse,
    ),
    'Please accept the Privacy Policy and Terms of use.': (
      ar: ar.PartnerTexts.pleaseAcceptThePrivacyPolicyAndTermsOfUse,
      en: en.PartnerTexts.pleaseAcceptThePrivacyPolicyAndTermsOfUse,
    ),
    'Everything you need to know about the app': (
      ar: ar.PartnerTexts.everythingYouNeedToKnowAboutTheApp,
      en: en.PartnerTexts.everythingYouNeedToKnowAboutTheApp,
    ),
    'Register as a partner': (
      ar: ar.PartnerTexts.registerAsAPartner,
      en: en.PartnerTexts.registerAsAPartner,
    ),
    'Join Yalla Market as a store or service partner': (
      ar: ar.PartnerTexts.joinYallaMarketAsAStoreOrServicePartner,
      en: en.PartnerTexts.joinYallaMarketAsAStoreOrServicePartner,
    ),
    'Grow your business with Yalla Market': (
      ar: ar.PartnerTexts.growYourBusinessWithYallaMarket,
      en: en.PartnerTexts.growYourBusinessWithYallaMarket,
    ),
    'Become a Yalla Market partner': (
      ar: ar.PartnerTexts.becomeAYallaMarketPartner,
      en: en.PartnerTexts.becomeAYallaMarketPartner,
    ),
    'Tell us about your business and our team will contact you after reviewing your application.':
        (
          ar: ar.PartnerTexts.tellUsAboutYourBusinessAndOurTeamWillContact,
          en: en.PartnerTexts.tellUsAboutYourBusinessAndOurTeamWillContact,
        ),
    'Business information': (
      ar: ar.PartnerTexts.businessInformation,
      en: en.PartnerTexts.businessInformation,
    ),
    'Business name': (
      ar: ar.PartnerTexts.businessName,
      en: en.PartnerTexts.businessName,
    ),
    'Business type': (
      ar: ar.PartnerTexts.businessType,
      en: en.PartnerTexts.businessType,
    ),
    'Number of branches': (
      ar: ar.PartnerTexts.numberOfBranches,
      en: en.PartnerTexts.numberOfBranches,
    ),
    '1 branch': (
      ar: ar.PartnerTexts.label1Branch,
      en: en.PartnerTexts.label1Branch,
    ),
    '2 branches': (
      ar: ar.PartnerTexts.label2Branches,
      en: en.PartnerTexts.label2Branches,
    ),
    '3 branches': (
      ar: ar.PartnerTexts.label3Branches,
      en: en.PartnerTexts.label3Branches,
    ),
    '4 branches': (
      ar: ar.PartnerTexts.label4Branches,
      en: en.PartnerTexts.label4Branches,
    ),
    '5 branches': (
      ar: ar.PartnerTexts.label5Branches,
      en: en.PartnerTexts.label5Branches,
    ),
    'Contact person': (
      ar: ar.PartnerTexts.contactPerson,
      en: en.PartnerTexts.contactPerson,
    ),
    'Your role in the business': (
      ar: ar.PartnerTexts.yourRoleInTheBusiness,
      en: en.PartnerTexts.yourRoleInTheBusiness,
    ),
    'Owner / Partner': (
      ar: ar.PartnerTexts.ownerPartner,
      en: en.PartnerTexts.ownerPartner,
    ),
    'Manager / Legal representative': (
      ar: ar.PartnerTexts.managerLegalRepresentative,
      en: en.PartnerTexts.managerLegalRepresentative,
    ),
    'Contact details': (
      ar: ar.PartnerTexts.contactDetails,
      en: en.PartnerTexts.contactDetails,
    ),
    'Do you have a trade license?': (
      ar: ar.PartnerTexts.doYouHaveATradeLicense,
      en: en.PartnerTexts.doYouHaveATradeLicense,
    ),
    'Restaurant': (
      ar: ar.PartnerTexts.restaurant,
      en: en.PartnerTexts.restaurant,
    ),
    'Service provider': (
      ar: ar.PartnerTexts.serviceProvider,
      en: en.PartnerTexts.serviceProvider,
    ),
    'Could not submit partner application': (
      ar: ar.PartnerTexts.couldNotSubmitPartnerApplication,
      en: en.PartnerTexts.couldNotSubmitPartnerApplication,
    ),
    'Could not submit partner application.': (
      ar: ar.PartnerTexts.couldNotSubmitPartnerApplicationLabel,
      en: en.PartnerTexts.couldNotSubmitPartnerApplicationLabel,
    ),
    'Partner application response was incomplete.': (
      ar: ar.PartnerTexts.partnerApplicationResponseWasIncomplete,
      en: en.PartnerTexts.partnerApplicationResponseWasIncomplete,
    ),
    'You already have a partner application under review.': (
      ar: ar.PartnerTexts.youAlreadyHaveAPartnerApplicationUnderReview,
      en: en.PartnerTexts.youAlreadyHaveAPartnerApplicationUnderReview,
    ),
    'We received the partner application for': (
      ar: ar.PartnerTexts.weReceivedThePartnerApplicationFor,
      en: en.PartnerTexts.weReceivedThePartnerApplicationFor,
    ),
    'Our team will review it and contact you soon.': (
      ar: ar.PartnerTexts.ourTeamWillReviewItAndContactYouSoon,
      en: en.PartnerTexts.ourTeamWillReviewItAndContactYouSoon,
    ),
    'We will contact you soon.': (
      ar: ar.PartnerTexts.weWillContactYouSoon,
      en: en.PartnerTexts.weWillContactYouSoon,
    ),
    'Contact to Activate': (
      ar: ar.PartnerTexts.contactToActivate,
      en: en.PartnerTexts.contactToActivate,
    ),
    'This helps personalize your shopping experience.': (
      ar: ar.PartnerTexts.thisHelpsPersonalizeYourShoppingExperience,
      en: en.PartnerTexts.thisHelpsPersonalizeYourShoppingExperience,
    ),
    'Activate it through support to unlock premium shopping perks.': (
      ar: ar.PartnerTexts.activateItThroughSupportToUnlockPremiumShoppingPerks,
      en: en.PartnerTexts.activateItThroughSupportToUnlockPremiumShoppingPerks,
    ),
    'Ask support for a data copy before you delete.': (
      ar: ar.PartnerTexts.askSupportForADataCopyBeforeYouDelete,
      en: en.PartnerTexts.askSupportForADataCopyBeforeYouDelete,
    ),
    'Data protection': (
      ar: ar.PartnerTexts.dataProtection,
      en: en.PartnerTexts.dataProtection,
    ),
    'We apply security controls to protect your information and never sell your personal data.':
        (
          ar: ar
              .PartnerTexts
              .weApplySecurityControlsToProtectYourInformationAndNever,
          en: en
              .PartnerTexts
              .weApplySecurityControlsToProtectYourInformationAndNever,
        ),
    'Your information': (
      ar: ar.PartnerTexts.yourInformation,
      en: en.PartnerTexts.yourInformation,
    ),
    'App Settings': (
      ar: ar.SettingsTexts.appSettings,
      en: en.SettingsTexts.appSettings,
    ),
    'App settings': (
      ar: ar.SettingsTexts.appSettingsLabel,
      en: en.SettingsTexts.appSettingsLabel,
    ),
    'App Preferences': (
      ar: ar.SettingsTexts.appPreferences,
      en: en.SettingsTexts.appPreferences,
    ),
    'App preferences': (
      ar: ar.SettingsTexts.appPreferencesLabel,
      en: en.SettingsTexts.appPreferencesLabel,
    ),
    'Open app settings': (
      ar: ar.SettingsTexts.openAppSettings,
      en: en.SettingsTexts.openAppSettings,
    ),
    'Appearance': (
      ar: ar.SettingsTexts.appearance,
      en: en.SettingsTexts.appearance,
    ),
    'Theme': (ar: ar.SettingsTexts.theme, en: en.SettingsTexts.theme),
    'Dark': (ar: ar.SettingsTexts.dark, en: en.SettingsTexts.dark),
    'Light': (ar: ar.SettingsTexts.light, en: en.SettingsTexts.light),
    'Always use the dark theme.': (
      ar: ar.SettingsTexts.alwaysUseTheDarkTheme,
      en: en.SettingsTexts.alwaysUseTheDarkTheme,
    ),
    'Always use the light theme.': (
      ar: ar.SettingsTexts.alwaysUseTheLightTheme,
      en: en.SettingsTexts.alwaysUseTheLightTheme,
    ),
    'Use your device theme setting.': (
      ar: ar.SettingsTexts.useYourDeviceThemeSetting,
      en: en.SettingsTexts.useYourDeviceThemeSetting,
    ),
    'Language': (ar: ar.SettingsTexts.language, en: en.SettingsTexts.language),
    'Currency': (ar: ar.SettingsTexts.currency, en: en.SettingsTexts.currency),
    'Currency saved': (
      ar: ar.SettingsTexts.currencySaved,
      en: en.SettingsTexts.currencySaved,
    ),
    'Data preferences': (
      ar: ar.SettingsTexts.dataPreferences,
      en: en.SettingsTexts.dataPreferences,
    ),
    'Safe Mode': (ar: ar.SettingsTexts.safeMode, en: en.SettingsTexts.safeMode),
    'Safe mode': (
      ar: ar.SettingsTexts.safeModeLabel,
      en: en.SettingsTexts.safeModeLabel,
    ),
    'Use this shortcut for the settings people change most often.': (
      ar: ar.SettingsTexts.useThisShortcutForTheSettingsPeopleChangeMostOften,
      en: en.SettingsTexts.useThisShortcutForTheSettingsPeopleChangeMostOften,
    ),
    'Home': (ar: ar.HomeTexts.home, en: en.HomeTexts.home),
    'Discover Limitless Choices and Unmatched Convenience.': (
      ar: ar.HomeTexts.discoverLimitlessChoicesAndUnmatchedConvenience,
      en: en.HomeTexts.discoverLimitlessChoicesAndUnmatchedConvenience,
    ),
    'Fresh deals are loading': (
      ar: ar.HomeTexts.freshDealsAreLoading,
      en: en.HomeTexts.freshDealsAreLoading,
    ),
    'Home, pets and daily essentials': (
      ar: ar.HomeTexts.homePetsAndDailyEssentials,
      en: en.HomeTexts.homePetsAndDailyEssentials,
    ),
    'Membership benefits': (
      ar: ar.HomeTexts.membershipBenefits,
      en: en.HomeTexts.membershipBenefits,
    ),
    'Popularity': (ar: ar.HomeTexts.popularity, en: en.HomeTexts.popularity),
    'Everything you need in one place': (
      ar: ar.HomeTexts.everythingYouNeedInOnePlace,
      en: en.HomeTexts.everythingYouNeedInOnePlace,
    ),
    'How do I place an order?': (
      ar: ar.HomeTexts.howDoIPlaceAnOrder,
      en: en.HomeTexts.howDoIPlaceAnOrder,
    ),
    'Choose your market and products, add the delivery address, then confirm your order from the cart.':
        (
          ar: ar.HomeTexts.chooseYourMarketAndProductsAddTheDeliveryAddressThen,
          en: en.HomeTexts.chooseYourMarketAndProductsAddTheDeliveryAddressThen,
        ),
    'Fast Delivery to Your Door': (
      ar: ar.HomeTexts.fastDeliveryToYourDoor,
      en: en.HomeTexts.fastDeliveryToYourDoor,
    ),
    'Just now': (ar: ar.TimeTexts.justNow, en: en.TimeTexts.justNow),
    'min ago': (ar: ar.TimeTexts.minAgo, en: en.TimeTexts.minAgo),
    'mins ago': (ar: ar.TimeTexts.minsAgo, en: en.TimeTexts.minsAgo),
    'hour ago': (ar: ar.TimeTexts.hourAgo, en: en.TimeTexts.hourAgo),
    'hours ago': (ar: ar.TimeTexts.hoursAgo, en: en.TimeTexts.hoursAgo),
    'days ago': (ar: ar.TimeTexts.daysAgo, en: en.TimeTexts.daysAgo),
    'minutes': (ar: ar.TimeTexts.minutes, en: en.TimeTexts.minutes),
    '{minutes} min': (ar: ar.TimeTexts.minutesMin, en: en.TimeTexts.minutesMin),
    'Today': (ar: ar.TimeTexts.today, en: en.TimeTexts.today),
    'Yesterday': (ar: ar.TimeTexts.yesterday, en: en.TimeTexts.yesterday),
    'This week': (ar: ar.TimeTexts.thisWeek, en: en.TimeTexts.thisWeek),
    'This month': (ar: ar.TimeTexts.thisMonth, en: en.TimeTexts.thisMonth),
    'Ends today': (ar: ar.TimeTexts.endsToday, en: en.TimeTexts.endsToday),
    '3 days left': (
      ar: ar.TimeTexts.label3DaysLeft,
      en: en.TimeTexts.label3DaysLeft,
    ),
    '1 week left': (
      ar: ar.TimeTexts.label1WeekLeft,
      en: en.TimeTexts.label1WeekLeft,
    ),
    'Choose date': (ar: ar.TimeTexts.chooseDate, en: en.TimeTexts.chooseDate),
    'Day': (ar: ar.TimeTexts.day, en: en.TimeTexts.day),
    'Month': (ar: ar.TimeTexts.month, en: en.TimeTexts.month),
    'Year': (ar: ar.TimeTexts.year, en: en.TimeTexts.year),
    'Selected days': (
      ar: ar.TimeTexts.selectedDays,
      en: en.TimeTexts.selectedDays,
    ),
    'Birth Date': (ar: ar.TimeTexts.birthDate, en: en.TimeTexts.birthDate),
    'Change Birth Date': (
      ar: ar.TimeTexts.changeBirthDate,
      en: en.TimeTexts.changeBirthDate,
    ),
    'Choose your birth date': (
      ar: ar.TimeTexts.chooseYourBirthDate,
      en: en.TimeTexts.chooseYourBirthDate,
    ),
    'Content updated': (
      ar: ar.TimeTexts.contentUpdated,
      en: en.TimeTexts.contentUpdated,
    ),
    'Language updated': (
      ar: ar.TimeTexts.languageUpdated,
      en: en.TimeTexts.languageUpdated,
    ),
    'Status updated': (
      ar: ar.TimeTexts.statusUpdated,
      en: en.TimeTexts.statusUpdated,
    ),
    'Theme updated': (
      ar: ar.TimeTexts.themeUpdated,
      en: en.TimeTexts.themeUpdated,
    ),
    'Shipment update': (
      ar: ar.TimeTexts.shipmentUpdate,
      en: en.TimeTexts.shipmentUpdate,
    ),
    'Popular categories updated': (
      ar: ar.TimeTexts.popularCategoriesUpdated,
      en: en.TimeTexts.popularCategoriesUpdated,
    ),
    'Activate now': (
      ar: ar.TimeTexts.activateNow,
      en: en.TimeTexts.activateNow,
    ),
    'Good day for shopping': (
      ar: ar.TimeTexts.goodDayForShopping,
      en: en.TimeTexts.goodDayForShopping,
    ),
    'Usually replies in a few minutes': (
      ar: ar.TimeTexts.usuallyRepliesInAFewMinutes,
      en: en.TimeTexts.usuallyRepliesInAFewMinutes,
    ),
    'I would like to receive updates by WhatsApp': (
      ar: ar.TimeTexts.iWouldLikeToReceiveUpdatesByWhatsApp,
      en: en.TimeTexts.iWouldLikeToReceiveUpdatesByWhatsApp,
    ),
    'No internet connection. Check your network to continue updates.': (
      ar: ar.TimeTexts.offlineUpdatesHint,
      en: en.TimeTexts.offlineUpdatesHint,
    ),
    'You can also ask about refunds, returns, or delivery updates.': (
      ar: ar.TimeTexts.youCanAlsoAskAboutRefundsReturnsOrDeliveryUpdates,
      en: en.TimeTexts.youCanAlsoAskAboutRefundsReturnsOrDeliveryUpdates,
    ),
    'This variation is available now with limited stock.': (
      ar: ar.TimeTexts.thisVariationIsAvailableNowWithLimitedStock,
      en: en.TimeTexts.thisVariationIsAvailableNowWithLimitedStock,
    ),
    'Everyday training jacket': (
      ar: ar.TimeTexts.everydayTrainingJacket,
      en: en.TimeTexts.everydayTrainingJacket,
    ),
    'Cancel': (ar: ar.CommonTexts.cancel, en: en.CommonTexts.cancel),
    'Clear': (ar: ar.CommonTexts.clear, en: en.CommonTexts.clear),
    'Clear search': (
      ar: ar.CommonTexts.clearSearch,
      en: en.CommonTexts.clearSearch,
    ),
    'Close': (ar: ar.CommonTexts.close, en: en.CommonTexts.close),
    'Confirm': (ar: ar.CommonTexts.confirm, en: en.CommonTexts.confirm),
    'Continue': (
      ar: ar.CommonTexts.continueText,
      en: en.CommonTexts.continueText,
    ),
    'Delete': (ar: ar.CommonTexts.delete, en: en.CommonTexts.delete),
    'Done': (ar: ar.CommonTexts.doneLabel, en: en.CommonTexts.doneLabel),
    'Edit': (ar: ar.CommonTexts.edit, en: en.CommonTexts.edit),
    'Next': (ar: ar.CommonTexts.next, en: en.CommonTexts.next),
    'Previous': (ar: ar.CommonTexts.previous, en: en.CommonTexts.previous),
    'Back': (ar: ar.CommonTexts.back, en: en.CommonTexts.back),
    'Save': (ar: ar.CommonTexts.save, en: en.CommonTexts.save),
    'Save Changes': (
      ar: ar.CommonTexts.saveChanges,
      en: en.CommonTexts.saveChanges,
    ),
    'Search': (ar: ar.CommonTexts.search, en: en.CommonTexts.search),
    'Submit': (ar: ar.CommonTexts.submit, en: en.CommonTexts.submit),
    'Retry': (ar: ar.CommonTexts.retry, en: en.CommonTexts.retry),
    'Refresh': (ar: ar.CommonTexts.refresh, en: en.CommonTexts.refresh),
    'Try again': (ar: ar.CommonTexts.tryAgain, en: en.CommonTexts.tryAgain),
    'Yes': (ar: ar.CommonTexts.yes, en: en.CommonTexts.yes),
    'No': (ar: ar.CommonTexts.no, en: en.CommonTexts.no),
    'Yes, continue': (
      ar: ar.CommonTexts.yesContinue,
      en: en.CommonTexts.yesContinue,
    ),
    'I understand': (
      ar: ar.CommonTexts.iUnderstand,
      en: en.CommonTexts.iUnderstand,
    ),
    'Or continue with': (
      ar: ar.CommonTexts.orContinueWith,
      en: en.CommonTexts.orContinueWith,
    ),
    'Select an option': (
      ar: ar.CommonTexts.selectAnOption,
      en: en.CommonTexts.selectAnOption,
    ),
    'Select the suitable option': (
      ar: ar.CommonTexts.selectTheSuitableOption,
      en: en.CommonTexts.selectTheSuitableOption,
    ),
    'Please select an option.': (
      ar: ar.CommonTexts.pleaseSelectAnOption,
      en: en.CommonTexts.pleaseSelectAnOption,
    ),
    'Selected': (ar: ar.CommonTexts.selected, en: en.CommonTexts.selected),
    'Selected variation': (
      ar: ar.CommonTexts.selectedVariation,
      en: en.CommonTexts.selectedVariation,
    ),
    'Choose manually': (
      ar: ar.CommonTexts.chooseManually,
      en: en.CommonTexts.chooseManually,
    ),
    'Choose additions': (
      ar: ar.CommonTexts.chooseAdditions,
      en: en.CommonTexts.chooseAdditions,
    ),
    'Choose a gender option': (
      ar: ar.CommonTexts.chooseAGenderOption,
      en: en.CommonTexts.chooseAGenderOption,
    ),
    'Status': (ar: ar.CommonTexts.status, en: en.CommonTexts.status),
    'Available': (ar: ar.CommonTexts.available, en: en.CommonTexts.available),
    'Cancelled': (ar: ar.CommonTexts.cancelled, en: en.CommonTexts.cancelled),
    'Not set': (ar: ar.CommonTexts.notSet, en: en.CommonTexts.notSet),
    'Not specified': (
      ar: ar.CommonTexts.notSpecified,
      en: en.CommonTexts.notSpecified,
    ),
    'No changes to save.': (
      ar: ar.CommonTexts.noChangesToSave,
      en: en.CommonTexts.noChangesToSave,
    ),
    'No internet connection.': (
      ar: ar.CommonTexts.noInternetConnection,
      en: en.CommonTexts.noInternetConnection,
    ),
    'No internet connection': (
      ar: ar.CommonTexts.noInternetConnectionLabel,
      en: en.CommonTexts.noInternetConnectionLabel,
    ),
    'Connection problem': (
      ar: ar.CommonTexts.connectionProblem,
      en: en.CommonTexts.connectionProblem,
    ),
    'Could not continue': (
      ar: ar.CommonTexts.couldNotContinue,
      en: en.CommonTexts.couldNotContinue,
    ),
    'Could not open gallery': (
      ar: ar.CommonTexts.couldNotOpenGallery,
      en: en.CommonTexts.couldNotOpenGallery,
    ),
    'Could not open link': (
      ar: ar.CommonTexts.couldNotOpenLink,
      en: en.CommonTexts.couldNotOpenLink,
    ),
    'Download unavailable here': (
      ar: ar.CommonTexts.downloadUnavailableHere,
      en: en.CommonTexts.downloadUnavailableHere,
    ),
    'Server error': (
      ar: ar.CommonTexts.serverError,
      en: en.CommonTexts.serverError,
    ),
    'Server error.': (
      ar: ar.CommonTexts.serverErrorLabel,
      en: en.CommonTexts.serverErrorLabel,
    ),
    'Please try again.': (
      ar: ar.CommonTexts.pleaseTryAgain,
      en: en.CommonTexts.pleaseTryAgain,
    ),
    'Too many requests. Try again later.': (
      ar: ar.CommonTexts.tooManyRequestsTryAgainLater,
      en: en.CommonTexts.tooManyRequestsTryAgainLater,
    ),
    'Service unavailable': (
      ar: ar.CommonTexts.serviceUnavailable,
      en: en.CommonTexts.serviceUnavailable,
    ),
    'No route defined for': (
      ar: ar.CommonTexts.noRouteDefinedFor,
      en: en.CommonTexts.noRouteDefinedFor,
    ),
    'No countries found': (
      ar: ar.CommonTexts.noCountriesFound,
      en: en.CommonTexts.noCountriesFound,
    ),
    'Loading content...': (
      ar: ar.CommonTexts.loadingContent,
      en: en.CommonTexts.loadingContent,
    ),
    'Loading version...': (
      ar: ar.CommonTexts.loadingVersion,
      en: en.CommonTexts.loadingVersion,
    ),
    'Image saved successfully': (
      ar: ar.CommonTexts.imageSavedSuccessfully,
      en: en.CommonTexts.imageSavedSuccessfully,
    ),
    'Personal Information': (
      ar: ar.CommonTexts.personalInformation,
      en: en.CommonTexts.personalInformation,
    ),
    'Edit personal details': (
      ar: ar.CommonTexts.editPersonalDetails,
      en: en.CommonTexts.editPersonalDetails,
    ),
    'Keep delivery details fresh': (
      ar: ar.CommonTexts.keepDeliveryDetailsFresh,
      en: en.CommonTexts.keepDeliveryDetailsFresh,
    ),
    'Search country or code': (
      ar: ar.CommonTexts.searchCountryOrCode,
      en: en.CommonTexts.searchCountryOrCode,
    ),
    'Select country': (
      ar: ar.CommonTexts.selectCountry,
      en: en.CommonTexts.selectCountry,
    ),
    'Search smarter': (
      ar: ar.CommonTexts.searchSmarter,
      en: en.CommonTexts.searchSmarter,
    ),
    'Trending searches': (
      ar: ar.CommonTexts.trendingSearches,
      en: en.CommonTexts.trendingSearches,
    ),
    'View all': (ar: ar.CommonTexts.viewAll, en: en.CommonTexts.viewAll),
    'Track current and previous purchases': (
      ar: ar.CommonTexts.trackCurrentAndPreviousPurchases,
      en: en.CommonTexts.trackCurrentAndPreviousPurchases,
    ),
    'Keep search results family friendly.': (
      ar: ar.CommonTexts.keepSearchResultsFamilyFriendly,
      en: en.CommonTexts.keepSearchResultsFamilyFriendly,
    ),
    'Try another section or choose All.': (
      ar: ar.CommonTexts.tryAnotherSectionOrChooseAll,
      en: en.CommonTexts.tryAnotherSectionOrChooseAll,
    ),
    'Search the menu...': (
      ar: ar.CommonTexts.searchTheMenu,
      en: en.CommonTexts.searchTheMenu,
    ),
    'Additional notes (optional)': (
      ar: ar.CommonTexts.additionalNotesOptional,
      en: en.CommonTexts.additionalNotesOptional,
    ),
    'Submitting application...': (
      ar: ar.CommonTexts.submittingApplication,
      en: en.CommonTexts.submittingApplication,
    ),
    'Submit application': (
      ar: ar.CommonTexts.submitApplication,
      en: en.CommonTexts.submitApplication,
    ),
    'Application submitted': (
      ar: ar.CommonTexts.applicationSubmitted,
      en: en.CommonTexts.applicationSubmitted,
    ),
    'Delivery: confirmed later': (
      ar: ar.CommonTexts.deliveryConfirmedLater,
      en: en.CommonTexts.deliveryConfirmedLater,
    ),
    'Spaces are not allowed in this field': (
      ar: ar.CommonTexts.spacesAreNotAllowedInThisField,
      en: en.CommonTexts.spacesAreNotAllowedInThisField,
    ),
    'Send code': (ar: ar.CommonTexts.sendCode, en: en.CommonTexts.sendCode),
    'Sending code...': (
      ar: ar.CommonTexts.sendingCode,
      en: en.CommonTexts.sendingCode,
    ),
    'Resend code': (
      ar: ar.CommonTexts.resendCode,
      en: en.CommonTexts.resendCode,
    ),
    'Resend in': (ar: ar.CommonTexts.resendIn, en: en.CommonTexts.resendIn),
    'Code already sent': (
      ar: ar.CommonTexts.codeAlreadySent,
      en: en.CommonTexts.codeAlreadySent,
    ),
    'Could not send code': (
      ar: ar.CommonTexts.couldNotSendCode,
      en: en.CommonTexts.couldNotSendCode,
    ),
    'Please wait before requesting another code.': (
      ar: ar.CommonTexts.pleaseWaitBeforeRequestingAnotherCode,
      en: en.CommonTexts.pleaseWaitBeforeRequestingAnotherCode,
    ),
    'Resend available in': (
      ar: ar.CommonTexts.resendAvailableIn,
      en: en.CommonTexts.resendAvailableIn,
    ),
    'Sending...': (ar: ar.CommonTexts.sending, en: en.CommonTexts.sending),
    'Resend Email': (
      ar: ar.CommonTexts.resendEmail,
      en: en.CommonTexts.resendEmail,
    ),
    'Name': (ar: ar.GeneralTexts.name, en: en.GeneralTexts.name),
    'Type': (ar: ar.GeneralTexts.type, en: en.GeneralTexts.type),
    'Color': (ar: ar.GeneralTexts.color, en: en.GeneralTexts.color),
    'Size': (ar: ar.GeneralTexts.size, en: en.GeneralTexts.size),
    'Small': (ar: ar.GeneralTexts.small, en: en.GeneralTexts.small),
    'Medium': (ar: ar.GeneralTexts.medium, en: en.GeneralTexts.medium),
    'Large': (ar: ar.GeneralTexts.large, en: en.GeneralTexts.large),
    'X-Large': (ar: ar.GeneralTexts.xLarge, en: en.GeneralTexts.xLarge),
    'Variant': (ar: ar.GeneralTexts.variant, en: en.GeneralTexts.variant),
    'Description': (
      ar: ar.GeneralTexts.description,
      en: en.GeneralTexts.description,
    ),
    'Country': (ar: ar.GeneralTexts.country, en: en.GeneralTexts.country),
    'State': (ar: ar.GeneralTexts.state, en: en.GeneralTexts.state),
    'Postal Code': (
      ar: ar.GeneralTexts.postalCode,
      en: en.GeneralTexts.postalCode,
    ),
    'Gender': (ar: ar.GeneralTexts.gender, en: en.GeneralTexts.gender),
    'Male': (ar: ar.GeneralTexts.male, en: en.GeneralTexts.male),
    'Female': (ar: ar.GeneralTexts.female, en: en.GeneralTexts.female),
    'Other': (ar: ar.GeneralTexts.other, en: en.GeneralTexts.other),
    'Prefer not to say': (
      ar: ar.GeneralTexts.preferNotToSay,
      en: en.GeneralTexts.preferNotToSay,
    ),
    'First name': (
      ar: ar.GeneralTexts.firstName,
      en: en.GeneralTexts.firstName,
    ),
    'Last name': (ar: ar.GeneralTexts.lastName, en: en.GeneralTexts.lastName),
    'Last Name': (
      ar: ar.GeneralTexts.lastNameLabel,
      en: en.GeneralTexts.lastNameLabel,
    ),
    'First Name': (
      ar: ar.GeneralTexts.firstNameLabel,
      en: en.GeneralTexts.firstNameLabel,
    ),
    'Mobile number': (
      ar: ar.GeneralTexts.mobileNumber,
      en: en.GeneralTexts.mobileNumber,
    ),
    'Landline (optional)': (
      ar: ar.GeneralTexts.landlineOptional,
      en: en.GeneralTexts.landlineOptional,
    ),
    'EGP': (ar: ar.GeneralTexts.egp, en: en.GeneralTexts.egp),
    'Version': (ar: ar.GeneralTexts.version, en: en.GeneralTexts.version),
    'Frequently asked questions': (
      ar: ar.GeneralTexts.frequentlyAskedQuestions,
      en: en.GeneralTexts.frequentlyAskedQuestions,
    ),
    'Add': (ar: ar.GeneralTexts.add, en: en.GeneralTexts.add),
    'Add to Bag': (ar: ar.GeneralTexts.addToBag, en: en.GeneralTexts.addToBag),
    'Apply': (ar: ar.GeneralTexts.apply, en: en.GeneralTexts.apply),
    'Change': (ar: ar.GeneralTexts.change, en: en.GeneralTexts.change),
    'Change Gender': (
      ar: ar.GeneralTexts.changeGender,
      en: en.GeneralTexts.changeGender,
    ),
    'Change Name': (
      ar: ar.GeneralTexts.changeName,
      en: en.GeneralTexts.changeName,
    ),
    'Download': (ar: ar.GeneralTexts.download, en: en.GeneralTexts.download),
    'Enter': (ar: ar.GeneralTexts.enter, en: en.GeneralTexts.enter),
    'From': (ar: ar.GeneralTexts.from, en: en.GeneralTexts.from),
    'To': (ar: ar.GeneralTexts.to, en: en.GeneralTexts.to),
    'Reset': (ar: ar.GeneralTexts.reset, en: en.GeneralTexts.reset),
    'Send': (ar: ar.GeneralTexts.send, en: en.GeneralTexts.send),
    'Skip': (ar: ar.GeneralTexts.skip, en: en.GeneralTexts.skip),
    'Switch': (ar: ar.GeneralTexts.switchText, en: en.GeneralTexts.switchText),
    'All': (ar: ar.GeneralTexts.all, en: en.GeneralTexts.all),
    'Default': (
      ar: ar.GeneralTexts.defaultText,
      en: en.GeneralTexts.defaultText,
    ),
    'Custom': (ar: ar.GeneralTexts.custom, en: en.GeneralTexts.custom),
    'Manual': (ar: ar.GeneralTexts.manual, en: en.GeneralTexts.manual),
    'Automatic': (ar: ar.GeneralTexts.automatic, en: en.GeneralTexts.automatic),
    'General': (ar: ar.GeneralTexts.general, en: en.GeneralTexts.general),
    'Active': (ar: ar.GeneralTexts.active, en: en.GeneralTexts.active),
    'Approved': (ar: ar.GeneralTexts.approved, en: en.GeneralTexts.approved),
    'Disabled': (ar: ar.GeneralTexts.disabled, en: en.GeneralTexts.disabled),
    'Expired': (ar: ar.GeneralTexts.expired, en: en.GeneralTexts.expired),
    'Verified': (ar: ar.GeneralTexts.verified, en: en.GeneralTexts.verified),
    'Pending': (ar: ar.GeneralTexts.pending, en: en.GeneralTexts.pending),
    'Picked up': (ar: ar.GeneralTexts.pickedUp, en: en.GeneralTexts.pickedUp),
    'Preparing': (ar: ar.GeneralTexts.preparing, en: en.GeneralTexts.preparing),
    'Ready': (ar: ar.GeneralTexts.ready, en: en.GeneralTexts.ready),
    'Rejected': (ar: ar.GeneralTexts.rejected, en: en.GeneralTexts.rejected),
    'Permanent': (ar: ar.GeneralTexts.permanent, en: en.GeneralTexts.permanent),
    'Permanent deletion': (
      ar: ar.GeneralTexts.permanentDeletion,
      en: en.GeneralTexts.permanentDeletion,
    ),
    'Online': (ar: ar.GeneralTexts.online, en: en.GeneralTexts.online),
    'Offline': (ar: ar.GeneralTexts.offline, en: en.GeneralTexts.offline),
    'Coming soon': (
      ar: ar.GeneralTexts.comingSoon,
      en: en.GeneralTexts.comingSoon,
    ),
    'Welcome': (ar: ar.GeneralTexts.welcome, en: en.GeneralTexts.welcome),
    'Got it': (ar: ar.GeneralTexts.gotIt, en: en.GeneralTexts.gotIt),
    'Delivery': (ar: ar.GeneralTexts.delivery, en: en.GeneralTexts.delivery),
    'Delivery type': (
      ar: ar.GeneralTexts.deliveryType,
      en: en.GeneralTexts.deliveryType,
    ),
    'Delivery within': (
      ar: ar.GeneralTexts.deliveryWithin,
      en: en.GeneralTexts.deliveryWithin,
    ),
    'Delivering to:': (
      ar: ar.GeneralTexts.deliveringTo,
      en: en.GeneralTexts.deliveringTo,
    ),
    'Free': (ar: ar.GeneralTexts.free, en: en.GeneralTexts.free),
    'Free delivery': (
      ar: ar.GeneralTexts.freeDelivery,
      en: en.GeneralTexts.freeDelivery,
    ),
    'Priority delivery': (
      ar: ar.GeneralTexts.priorityDelivery,
      en: en.GeneralTexts.priorityDelivery,
    ),
    'Better delivery experience': (
      ar: ar.GeneralTexts.betterDeliveryExperience,
      en: en.GeneralTexts.betterDeliveryExperience,
    ),
    'Courier': (ar: ar.GeneralTexts.courier, en: en.GeneralTexts.courier),
    'Courier assigned': (
      ar: ar.GeneralTexts.courierAssigned,
      en: en.GeneralTexts.courierAssigned,
    ),
    'Later': (ar: ar.GeneralTexts.later, en: en.GeneralTexts.later),
    'Determined later': (
      ar: ar.GeneralTexts.determinedLater,
      en: en.GeneralTexts.determinedLater,
    ),
    'Shipment on the way': (
      ar: ar.GeneralTexts.shipmentOnTheWay,
      en: en.GeneralTexts.shipmentOnTheWay,
    ),
    'Gold Membership': (
      ar: ar.GeneralTexts.goldMembership,
      en: en.GeneralTexts.goldMembership,
    ),
    'Gold member': (
      ar: ar.GeneralTexts.goldMember,
      en: en.GeneralTexts.goldMember,
    ),
    'Gold member is inactive': (
      ar: ar.GeneralTexts.goldMemberIsInactive,
      en: en.GeneralTexts.goldMemberIsInactive,
    ),
    'Inactive plan': (
      ar: ar.GeneralTexts.inactivePlan,
      en: en.GeneralTexts.inactivePlan,
    ),
    'Early sale access': (
      ar: ar.GeneralTexts.earlySaleAccess,
      en: en.GeneralTexts.earlySaleAccess,
    ),
    ' read more': (ar: ar.GeneralTexts.readMore, en: en.GeneralTexts.readMore),
    ' show less': (ar: ar.GeneralTexts.showLess, en: en.GeneralTexts.showLess),
    'Additional instructions (optional)': (
      ar: ar.GeneralTexts.additionalInstructionsOptional,
      en: en.GeneralTexts.additionalInstructionsOptional,
    ),
    'Additional value': (
      ar: ar.GeneralTexts.additionalValue,
      en: en.GeneralTexts.additionalValue,
    ),
    'Agreement required': (
      ar: ar.GeneralTexts.agreementRequired,
      en: en.GeneralTexts.agreementRequired,
    ),
    'Before deleting': (
      ar: ar.GeneralTexts.beforeDeleting,
      en: en.GeneralTexts.beforeDeleting,
    ),
    'Image download started': (
      ar: ar.GeneralTexts.imageDownloadStarted,
      en: en.GeneralTexts.imageDownloadStarted,
    ),
    'HD Image Quality': (
      ar: ar.GeneralTexts.hdImageQuality,
      en: en.GeneralTexts.hdImageQuality,
    ),
    'Write a message...': (
      ar: ar.GeneralTexts.writeAMessage,
      en: en.GeneralTexts.writeAMessage,
    ),
    'Type a message': (
      ar: ar.GeneralTexts.typeAMessage,
      en: en.GeneralTexts.typeAMessage,
    ),
    'Add a new stop': (
      ar: ar.GeneralTexts.addANewStop,
      en: en.GeneralTexts.addANewStop,
    ),
    'Quick controls': (
      ar: ar.GeneralTexts.quickControls,
      en: en.GeneralTexts.quickControls,
    ),
    'Refund': (ar: ar.GeneralTexts.refund, en: en.GeneralTexts.refund),
    'Security': (ar: ar.GeneralTexts.security, en: en.GeneralTexts.security),
    'Security and data controls': (
      ar: ar.GeneralTexts.securityAndDataControls,
      en: en.GeneralTexts.securityAndDataControls,
    ),
    'New arrivals': (
      ar: ar.GeneralTexts.newArrivals,
      en: en.GeneralTexts.newArrivals,
    ),
    'Sale': (ar: ar.GeneralTexts.sale, en: en.GeneralTexts.sale),
    'Additions': (ar: ar.GeneralTexts.additions, en: en.GeneralTexts.additions),
    'This field is required': (
      ar: ar.GeneralTexts.thisFieldIsRequired,
      en: en.GeneralTexts.thisFieldIsRequired,
    ),
    'This field is required.': (
      ar: ar.GeneralTexts.thisFieldIsRequiredLabel,
      en: en.GeneralTexts.thisFieldIsRequiredLabel,
    ),
    'Enter a valid mobile number.': (
      ar: ar.GeneralTexts.enterAValidMobileNumber,
      en: en.GeneralTexts.enterAValidMobileNumber,
    ),
    'Please complete the required fields.': (
      ar: ar.GeneralTexts.pleaseCompleteTheRequiredFields,
      en: en.GeneralTexts.pleaseCompleteTheRequiredFields,
    ),
    'Name is too short': (
      ar: ar.GeneralTexts.nameIsTooShort,
      en: en.GeneralTexts.nameIsTooShort,
    ),
    'Require a code for sensitive actions.': (
      ar: ar.GeneralTexts.requireACodeForSensitiveActions,
      en: en.GeneralTexts.requireACodeForSensitiveActions,
    ),
    'I agree to ': (ar: ar.GeneralTexts.iAgreeTo, en: en.GeneralTexts.iAgreeTo),
    ' and ': (ar: ar.GeneralTexts.and, en: en.GeneralTexts.and),
    'Enter a valid email address.': (
      ar: ar.GeneralTexts.enterAValidEmailAddress,
      en: en.GeneralTexts.enterAValidEmailAddress,
    ),
    'Enter a valid email address': (
      ar: ar.GeneralTexts.enterAValidEmailAddressLabel,
      en: en.GeneralTexts.enterAValidEmailAddressLabel,
    ),
    'Use an email address you can access for account recovery.': (
      ar: ar.GeneralTexts.useAnEmailAddressYouCanAccessForAccountRecovery,
      en: en.GeneralTexts.useAnEmailAddressYouCanAccessForAccountRecovery,
    ),
    'Welcome to يلا ماركت.': (
      ar: ar.GeneralTexts.welcomeTo,
      en: en.GeneralTexts.welcomeTo,
    ),
    'Clothes': (ar: ar.GeneralTexts.clothes, en: en.GeneralTexts.clothes),
    'Electronics': (
      ar: ar.GeneralTexts.electronics,
      en: en.GeneralTexts.electronics,
    ),
    'Electronic devices': (
      ar: ar.GeneralTexts.electronicDevices,
      en: en.GeneralTexts.electronicDevices,
    ),
    'Mobile': (ar: ar.GeneralTexts.mobile, en: en.GeneralTexts.mobile),
    'Accessories': (
      ar: ar.GeneralTexts.accessories,
      en: en.GeneralTexts.accessories,
    ),
    'Spare parts': (
      ar: ar.GeneralTexts.spareParts,
      en: en.GeneralTexts.spareParts,
    ),
    'Fashion': (ar: ar.GeneralTexts.fashion, en: en.GeneralTexts.fashion),
    'Furniture': (ar: ar.GeneralTexts.furniture, en: en.GeneralTexts.furniture),
    'Lifestyle': (ar: ar.GeneralTexts.lifestyle, en: en.GeneralTexts.lifestyle),
    'Pets': (ar: ar.GeneralTexts.pets, en: en.GeneralTexts.pets),
    'Shoes': (ar: ar.GeneralTexts.shoes, en: en.GeneralTexts.shoes),
    'Sport Shoes': (
      ar: ar.GeneralTexts.sportShoes,
      en: en.GeneralTexts.sportShoes,
    ),
    'Sports': (ar: ar.GeneralTexts.sports, en: en.GeneralTexts.sports),
    'Sports Equipment': (
      ar: ar.GeneralTexts.sportsEquipment,
      en: en.GeneralTexts.sportsEquipment,
    ),
    'Track Suits': (
      ar: ar.GeneralTexts.trackSuits,
      en: en.GeneralTexts.trackSuits,
    ),
    'Shoes, kits and training gear': (
      ar: ar.GeneralTexts.shoesKitsAndTrainingGear,
      en: en.GeneralTexts.shoesKitsAndTrainingGear,
    ),
    'Jackets, shirts and outfits': (
      ar: ar.GeneralTexts.jacketsShirtsAndOutfits,
      en: en.GeneralTexts.jacketsShirtsAndOutfits,
    ),
    'Phones, devices and accessories': (
      ar: ar.GeneralTexts.phonesDevicesAndAccessories,
      en: en.GeneralTexts.phonesDevicesAndAccessories,
    ),
    'Newest': (ar: ar.GeneralTexts.newest, en: en.GeneralTexts.newest),
    'Best match': (
      ar: ar.GeneralTexts.bestMatch,
      en: en.GeneralTexts.bestMatch,
    ),
    'System default': (
      ar: ar.GeneralTexts.systemDefault,
      en: en.GeneralTexts.systemDefault,
    ),
    'To activate': (
      ar: ar.GeneralTexts.toActivate,
      en: en.GeneralTexts.toActivate,
    ),
    'PayPal': (ar: ar.GeneralTexts.paypal, en: en.GeneralTexts.paypal),
    'PayPal Balance': (
      ar: ar.GeneralTexts.paypalBalance,
      en: en.GeneralTexts.paypalBalance,
    ),
    'Argentina': (ar: ar.GeneralTexts.argentina, en: en.GeneralTexts.argentina),
    'India': (ar: ar.GeneralTexts.india, en: en.GeneralTexts.india),
    'Pakistan': (ar: ar.GeneralTexts.pakistan, en: en.GeneralTexts.pakistan),
    'Saudi Arabia': (
      ar: ar.GeneralTexts.saudiArabia,
      en: en.GeneralTexts.saudiArabia,
    ),
    'Turkey': (ar: ar.GeneralTexts.turkey, en: en.GeneralTexts.turkey),
    'USA': (ar: ar.GeneralTexts.usa, en: en.GeneralTexts.usa),
    'Heliopolis': (
      ar: ar.GeneralTexts.heliopolis,
      en: en.GeneralTexts.heliopolis,
    ),
    'Maadi': (ar: ar.GeneralTexts.maadi, en: en.GeneralTexts.maadi),
    'Zamalek': (ar: ar.GeneralTexts.zamalek, en: en.GeneralTexts.zamalek),
    'Shubra': (ar: ar.GeneralTexts.shubra, en: en.GeneralTexts.shubra),
    'Helwan': (ar: ar.GeneralTexts.helwan, en: en.GeneralTexts.helwan),
    '15 May': (ar: ar.GeneralTexts.label15May, en: en.GeneralTexts.label15May),
    'Mokattam': (ar: ar.GeneralTexts.mokattam, en: en.GeneralTexts.mokattam),
    'Mansoura': (ar: ar.GeneralTexts.mansoura, en: en.GeneralTexts.mansoura),
    'Hurghada': (ar: ar.GeneralTexts.hurghada, en: en.GeneralTexts.hurghada),
    'Sharm El Sheikh': (
      ar: ar.GeneralTexts.sharmElSheikh,
      en: en.GeneralTexts.sharmElSheikh,
    ),
    'Tanta': (ar: ar.GeneralTexts.tanta, en: en.GeneralTexts.tanta),
    'Naama Bay': (ar: ar.GeneralTexts.naamaBay, en: en.GeneralTexts.naamaBay),
    'Nabq': (ar: ar.GeneralTexts.nabq, en: en.GeneralTexts.nabq),
    'Hadaba': (ar: ar.GeneralTexts.hadaba, en: en.GeneralTexts.hadaba),
    'Arabic': (ar: ar.GeneralTexts.arabic, en: en.GeneralTexts.arabic),
    'Arabic interface': (
      ar: ar.GeneralTexts.arabicInterface,
      en: en.GeneralTexts.arabicInterface,
    ),
    'English': (ar: ar.GeneralTexts.english, en: en.GeneralTexts.english),
    'English interface': (
      ar: ar.GeneralTexts.englishInterface,
      en: en.GeneralTexts.englishInterface,
    ),
    'APPLE iPhone 8 (Black, 64 GB)': (
      ar: ar.GeneralTexts.appleIPhone8Black64Gb,
      en: en.GeneralTexts.appleIPhone8Black64Gb,
    ),
    'Blue T-shirt for all ages': (
      ar: ar.GeneralTexts.blueTShirtForAllAges,
      en: en.GeneralTexts.blueTShirtForAllAges,
    ),
    'Black': (ar: ar.GeneralTexts.black, en: en.GeneralTexts.black),
    'Green': (ar: ar.GeneralTexts.green, en: en.GeneralTexts.green),
    'Red': (ar: ar.GeneralTexts.red, en: en.GeneralTexts.red),
    'Lightweight active tee': (
      ar: ar.GeneralTexts.lightweightActiveTee,
      en: en.GeneralTexts.lightweightActiveTee,
    ),
    'Performance gym kit': (
      ar: ar.GeneralTexts.performanceGymKit,
      en: en.GeneralTexts.performanceGymKit,
    ),
    'Premium leather jacket': (
      ar: ar.GeneralTexts.premiumLeatherJacket,
      en: en.GeneralTexts.premiumLeatherJacket,
    ),
    'Elite training football': (
      ar: ar.GeneralTexts.eliteTrainingFootball,
      en: en.GeneralTexts.eliteTrainingFootball,
    ),
    'Court-ready accessories': (
      ar: ar.GeneralTexts.courtReadyAccessories,
      en: en.GeneralTexts.courtReadyAccessories,
    ),
    'Warmup street hoodie': (
      ar: ar.GeneralTexts.warmupStreetHoodie,
      en: en.GeneralTexts.warmupStreetHoodie,
    ),
    'Air Max running shoes': (
      ar: ar.GeneralTexts.airMaxRunningShoes,
      en: en.GeneralTexts.airMaxRunningShoes,
    ),
    'Wildhorse trail shoes': (
      ar: ar.GeneralTexts.wildhorseTrailShoes,
      en: en.GeneralTexts.wildhorseTrailShoes,
    ),
    'Green Nike sports shoe': (
      ar: ar.GeneralTexts.greenNikeSportsShoe,
      en: en.GeneralTexts.greenNikeSportsShoe,
    ),
    'Nike Air Jordan Orange': (
      ar: ar.GeneralTexts.nikeAirJordanOrange,
      en: en.GeneralTexts.nikeAirJordanOrange,
    ),
    'Nike Air Jordan Red Black': (
      ar: ar.GeneralTexts.nikeAirJordanRedBlack,
      en: en.GeneralTexts.nikeAirJordanRedBlack,
    ),
    'Nike Wildhorse Running Shoe': (
      ar: ar.GeneralTexts.nikeWildhorseRunningShoe,
      en: en.GeneralTexts.nikeWildhorseRunningShoe,
    ),
    'Jordan court blue': (
      ar: ar.GeneralTexts.jordanCourtBlue,
      en: en.GeneralTexts.jordanCourtBlue,
    ),
    'Samsung S9 mobile bundle': (
      ar: ar.GeneralTexts.samsungS9MobileBundle,
      en: en.GeneralTexts.samsungS9MobileBundle,
    ),
    'Tomi dry food pack': (
      ar: ar.GeneralTexts.tomiDryFoodPack,
      en: en.GeneralTexts.tomiDryFoodPack,
    ),
    'Visa ending 4721': (
      ar: ar.GeneralTexts.visaEnding4721,
      en: en.GeneralTexts.visaEnding4721,
    ),
    '20% off sports picks': (
      ar: ar.GeneralTexts.label20OffSportsPicks,
      en: en.GeneralTexts.label20OffSportsPicks,
    ),
    'Green sports shoe': (
      ar: ar.GeneralTexts.greenSportsShoe,
      en: en.GeneralTexts.greenSportsShoe,
    ),
    'Red black sports sneaker': (
      ar: ar.GeneralTexts.redBlackSportsSneaker,
      en: en.GeneralTexts.redBlackSportsSneaker,
    ),
    'Orange sports sneaker': (
      ar: ar.GeneralTexts.orangeSportsSneaker,
      en: en.GeneralTexts.orangeSportsSneaker,
    ),
    'Trail running shoe': (
      ar: ar.GeneralTexts.trailRunningShoe,
      en: en.GeneralTexts.trailRunningShoe,
    ),
    'Blue court sneaker': (
      ar: ar.GeneralTexts.blueCourtSneaker,
      en: en.GeneralTexts.blueCourtSneaker,
    ),
    'Coding with T': (
      ar: ar.GeneralTexts.codingWithT,
      en: en.GeneralTexts.codingWithT,
    ),
    'Acer': (ar: ar.GeneralTexts.acer, en: en.GeneralTexts.acer),
    'Adidas': (ar: ar.GeneralTexts.adidas, en: en.GeneralTexts.adidas),
    'Apple': (ar: ar.GeneralTexts.apple, en: en.GeneralTexts.apple),
    'Herman Miller': (
      ar: ar.GeneralTexts.hermanMiller,
      en: en.GeneralTexts.hermanMiller,
    ),
    'IKEA': (ar: ar.GeneralTexts.ikea, en: en.GeneralTexts.ikea),
    'Jordan': (ar: ar.GeneralTexts.jordan, en: en.GeneralTexts.jordan),
    'Kenwood': (ar: ar.GeneralTexts.kenwood, en: en.GeneralTexts.kenwood),
    'Nike': (ar: ar.GeneralTexts.nike, en: en.GeneralTexts.nike),
    'Puma': (ar: ar.GeneralTexts.puma, en: en.GeneralTexts.puma),
    'ZARA': (ar: ar.GeneralTexts.zara, en: en.GeneralTexts.zara),
  };
}
