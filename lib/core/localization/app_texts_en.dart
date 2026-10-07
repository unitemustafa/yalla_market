// نصوص يلا ماركت الإنجليزية، مقسمة حسب الشاشة والقسم.
//
// عدّل قيمة المتغير المطلوب هنا لتغيير النص في التطبيق.
// نفس أسماء الأقسام والمتغيرات موجودة في ملف اللغة الأخرى.
// عند إضافة نص جديد، أضف متغيره في الملفين واربطه في app_text_catalog.dart.

/// اسم التطبيق والعلامة.
abstract final class BrandTexts {
  // ─── التطبيق ───
  static const appName = 'Yalla Market';
}

/// الأزرار والرسائل العامة.
abstract final class CommonTexts {
  // ─── الأزرار العامة ───
  static const skip = 'Skip';
  static const continueText = 'Continue';
  static const done = 'Done';
  static const startShopping = 'Start Shopping';
  static const submit = 'Submit';
  static const resendEmail = 'Resend Email';

  // ─── أزرار وإجراءات ───
  static const cancel = 'Cancel';
  static const clear = 'Clear';
  static const clearSearch = 'Clear search';
  static const close = 'Close';
  static const confirm = 'Confirm';
  static const delete = 'Delete';
  static const doneLabel = 'Done';
  static const edit = 'Edit';
  static const next = 'Next';
  static const previous = 'Previous';
  static const back = 'Back';
  static const save = 'Save';
  static const saveChanges = 'Save Changes';
  static const search = 'Search';
  static const retry = 'Retry';
  static const refresh = 'Refresh';
  static const tryAgain = 'Try again';
  static const yes = 'Yes';
  static const no = 'No';
  static const yesContinue = 'Yes, continue';
  static const iUnderstand = 'I understand';
  static const orContinueWith = 'Or continue with';

  // ─── اختيارات ───
  static const selectAnOption = 'Select an option';
  static const selectTheSuitableOption = 'Select the suitable option';
  static const pleaseSelectAnOption = 'Please select an option.';
  static const selected = 'Selected';
  static const selectedVariation = 'Selected variation';
  static const chooseManually = 'Choose manually';
  static const chooseAdditions = 'Choose additions';
  static const chooseAGenderOption = 'Choose a gender option';

  // ─── حالات ───
  static const status = 'Status';
  static const available = 'Available';
  static const cancelled = 'Cancelled';
  static const notSet = 'Not set';
  static const notSpecified = 'Not specified';
  static const noChangesToSave = 'No changes to save.';

  // ─── أخطاء عامة ───
  static const noInternetConnection = 'No internet connection.';
  static const noInternetConnectionLabel = 'No internet connection';
  static const connectionProblem = 'Connection problem';
  static const couldNotContinue = 'Could not continue';
  static const couldNotOpenGallery = 'Could not open gallery';
  static const couldNotOpenLink = 'Could not open link';
  static const downloadUnavailableHere = 'Download unavailable here';
  static const serverError = 'Server error';
  static const serverErrorLabel = 'Server error.';
  static const pleaseTryAgain = 'Please try again.';
  static const tooManyRequestsTryAgainLater =
      'Too many requests. Try again later.';
  static const serviceUnavailable = 'Service unavailable';
  static const noRouteDefinedFor = 'No route defined for';
  static const noCountriesFound = 'No countries found';

  // ─── تحميل ومحتوى ───
  static const loadingContent = 'Loading content...';
  static const loadingVersion = 'Loading version...';
  static const imageSavedSuccessfully = 'Image saved successfully';

  // ─── بيانات شخصية ───
  static const personalInformation = 'Personal Information';
  static const editPersonalDetails = 'Edit personal details';
  static const keepDeliveryDetailsFresh = 'Keep delivery details fresh';
  static const searchCountryOrCode = 'Search country or code';
  static const selectCountry = 'Select country';
  static const searchSmarter = 'Search smarter';
  static const trendingSearches = 'Trending searches';
  static const viewAll = 'View all';
  static const trackCurrentAndPreviousPurchases =
      'Track current and previous purchases';
  static const keepSearchResultsFamilyFriendly =
      'Keep search results family friendly.';
  static const tryAnotherSectionOrChooseAll =
      'Try another section or choose All.';
  static const searchTheMenu = 'Search the menu...';

  // ─── نماذج ───
  static const additionalNotesOptional = 'Additional notes (optional)';
  static const submittingApplication = 'Submitting application...';
  static const submitApplication = 'Submit application';
  static const applicationSubmitted = 'Application submitted';
  static const deliveryConfirmedLater = 'Delivery: confirmed later';
  static const spacesAreNotAllowedInThisField =
      'Spaces are not allowed in this field';

  // ─── أكواد التحقق ───
  static const sendCode = 'Send code';
  static const sendingCode = 'Sending code...';
  static const resendCode = 'Resend code';
  static const resendIn = 'Resend in';
  static const codeAlreadySent = 'Code already sent';
  static const couldNotSendCode = 'Could not send code';
  static const pleaseWaitBeforeRequestingAnotherCode =
      'Please wait before requesting another code.';
  static const resendAvailableIn = 'Resend available in';
  static const sending = 'Sending...';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String fieldSaved(String field) => 'Your $field has been saved.';
  static String copied(String value) => '$value copied';
  static String undefinedRoute(String route) => 'No route defined for $route';
  static const pagePrefix = 'Page ';
  static const pageSeparator = ' of ';
  static const quantityPrefix = 'Qty ';
}

/// شاشات الترحيب.
abstract final class OnboardingTexts {
  // ─── شاشات الترحيب ───
  static const onboardingTitle1 = 'Discover Deals You\'ll Love';
  static const onboardingDesc1 =
      'Explore fashion, tech, home picks, and daily deals made easy to browse.';
  static const onboardingTitle2 = 'Pay Your Way';
  static const onboardingDesc2 =
      'Review your cart, choose a payment method, and confirm your order with confidence.';
  static const onboardingTitle3 = 'Fast Delivery to Your Door';
  static const onboardingDesc3 =
      'Track every step until your order arrives right at your door.';
}

/// تسجيل الدخول والحساب والتحقق من البيانات.
abstract final class AuthTexts {
  // ─── تسجيل الدخول ───
  static const welcomeBack = 'Welcome back,';
  static const loginSubtitle = 'The first online market in El Tal El Kebir.';
  static const email = 'E-Mail';
  static const password = 'Password';
  static const rememberMe = 'Remember Me';
  static const forgetPasswordLink = 'Forgot Password?';
  static const signIn = 'Sign In';
  static const signInSuccessTitle = 'Signed in successfully';
  static const signInSuccessMessage = 'Welcome back to Yalla Market.';
  static const createAccount = 'Create Account';
  static const dontHaveAccount = 'Don\'t have an account?';
  static const signUpAction = 'Sign Up';
  static const orContinueWith = 'Or Continue With';
  static const signInCreateAccountTitle = 'Create an account';
  static const signInCredentialsTitle = 'Check your credentials';
  static const signInConnectionTitle = 'Connection problem';
  static const signInFailureTitle = 'Sign in failed';

  // ─── إنشاء الحساب ───
  static const createYourAccount = 'Let\'s create your account';
  static const firstName = 'First Name';
  static const lastName = 'Last Name';
  static const username = 'Username';
  static const phoneNumber = 'Phone Number';
  static const iAgreeTo = 'I agree to ';
  static const privacyPolicy = 'Privacy Policy';
  static const and = ' and ';
  static const termsOfUse = 'Terms of use';

  // ─── استعادة كلمة السر ───
  static const forgetPasswordTitle = 'Forgot password';
  static const forgetPasswordDesc =
      'No worries. Enter your email and we\'ll send you a secure password reset link.';
  static const verifyEmailTitle = 'Verify your email address!';
  static const verifyEmailDesc =
      'Your account is almost ready. Verify your email to start shopping and unlock personalized offers.';
  static const passwordResetTitle = 'Password Reset Email Sent';
  static const passwordResetDesc =
      'We\'ve sent you a secure link to change your password and keep your account protected.';
  static const successTitle = 'Your account was\ncreated successfully!';
  static const successDesc =
      'Welcome to Yalla Market. Your account is ready for a smooth online shopping experience.';

  // ─── التحقق من المدخلات ───
  static const fieldRequired = 'This field is required';
  static const invalidEmail = 'Please enter a valid email';
  static const passwordTooShort = 'Password must be at least 8 characters';
  static const passwordTooLong = 'Password must be 72 characters or fewer.';
  static const passwordWeak =
      'Password is weak. Use uppercase, lowercase, a number, and a symbol.';
  static const passwordMedium =
      'Medium password. Add more variety to make it strong.';
  static const invalidPhone = 'Please enter a valid phone number';

  // ─── تسجيل الدخول والحساب ───
  static const mobilePhoneNumber = 'Mobile phone number';
  static const mobileEmailUsername = 'Mobile / Email / Username';
  static const enterAValidEmailUsernameOrPhoneNumber =
      'Enter a valid email, username, or phone number';
  static const sessionExpired = 'Session expired';
  static const accountDisabled = 'Account disabled';
  static const emailNotVerified = 'Account email has not been verified.';
  static const wrongAppCredentials = 'This login is only for client accounts.';
  static const invalidSignInCredentials = 'Invalid sign-in credentials.';
  static const sessionExpiredHint =
      'Sign in again to continue. Remember Me keeps you signed in after closing the app.';
  static const signInAgainBeforePlacingAnOrder =
      'Sign in again before placing an order.';
  static const emailAndPasswordAreRequired = 'Email and password are required.';
  static const invalidCredentials = 'Invalid email or password.';
  static const logout = 'Logout';
  static const areYouSureYouWantToLogout = 'Are you sure you want to logout?';
  static const couldNotSignYouIn = 'Could not sign you in.';
  static const couldNotSignYouOut = 'Could not sign you out.';
  static const aNewSignInWasVerifiedSuccessfully =
      'A new sign-in was verified successfully.';
  static const noLocalUserSession = 'No local user session.';
  static const couldNotRestoreYourSession = 'Could not restore your session.';
  static const accountAlreadyExists = 'Account already exists';
  static const accountCreationFailed = 'Account creation failed';
  static const accountCreatedSuccessfully = 'Account created successfully';
  static const couldNotCreateYourAccount = 'Could not create your account.';
  static const weWillVerifyItWhileCreatingYourAccount =
      'We will verify it while creating your account.';
  static const pleaseAgreeToThePrivacyPolicyAndTermsOfUse =
      'Please agree to the Privacy Policy and Terms of use before creating your account.';

  // ─── استعادة الحساب ───
  static const accountRestored = 'Account restored';
  static const yourAccountWasRestoredByTheYallaMarketTeam =
      'Your account was restored by the Yalla Market team.';
  static const accountRestoredByYallaMarketSupportTeam =
      'Account restored by Yalla Market support team';
  static const yourAccountHasBeenRestoredYouCanSignInAgain =
      'Your account has been restored. You can sign in again.';
  static const accountPermanentlyDeleted = 'Account permanently deleted';
  static const yourAccountHasBeenPermanentlyDeletedCreateANewAccount =
      'Your account has been permanently deleted. Create a new account to continue.';
  static const yourAccountIsDisabledContactTechnicalSupportOrCreateA =
      'Your account is disabled. Contact technical support or create a new account.';

  // ─── البروفايل ───
  static const profile = 'Profile';
  static const profileInformation = 'Profile Information';
  static const profilePhotoUpdated = 'Profile photo updated';
  static const profileUpdated = 'Profile updated';
  static const editProfile = 'Edit profile';
  static const uploadProfilePhoto = 'Upload profile photo';
  static const uploadingProfilePhoto = 'Uploading profile photo...';
  static const couldNotLoadYourProfile = 'Could not load your profile.';
  static const couldNotRefreshProfile = 'Could not refresh profile';
  static const couldNotUpdateProfile = 'Could not update profile';
  static const couldNotUpdateProfilePhoto = 'Could not update profile photo';
  static const couldNotUpdateProfilePhotoLabel =
      'Could not update profile photo.';
  static const updateYourProfileInformation = 'Update your profile information';
  static const thisInformationAppearsOnYourProfile =
      'This information appears on your يلا ماركت profile.';
  static const weUseYourAccountDetailsToSecureYourProfileAnd =
      'We use your account details to secure your profile and personalize shopping.';

  // ─── إعدادات الحساب ───
  static const accountSettings = 'Account Settings';
  static const accountSecured = 'Account secured';
  static const accountUnavailable = 'Account unavailable';
  static const accountOrdersAndPreferences = 'Account, orders and preferences';
  static const yourAccountUsesSecureSignInAndControlledDataSharing =
      'Your account uses secure sign-in and controlled data sharing.';
  static const keepYourAccountInformationAccurateAndProtectYourPassword =
      'Keep your account information accurate and protect your password.';
  static const weUseYourAccountAndDeliveryInformationOnlyToProvide =
      'We use your account and delivery information only to provide, secure, and improve Yalla Market services.';
  static const useAccurateAccountAndDeliveryDetailsAndKeepYourPassword =
      'Use accurate account and delivery details and keep your password private.';
  static const yourEmailAndPhoneNumberHelpWithVerificationDeliveryUpdates =
      'Your email and phone number help with verification, delivery updates, and recovery.';
  static const usernameCheckSkipped = 'Username check skipped';
  static const usernameLocked = 'Username locked';
  static const usernameCanOnlyBeChangedOnceEvery7Days =
      'Username can only be changed once every 7 days.';
  static const youCanChangeYourUsernameAgainOn =
      'You can change your username again on';
  static const afterSavingYouCanChangeYourUsernameAgainAfter7 =
      'After saving, you can change your username again after 7 days.';
  static const afterSavingANewUsernameYouWillNotBeAble =
      'After saving a new username, you will not be able to change it again for 7 days.';
  static const changeUsername = 'Change username?';
  static const changeUsernameLabel = 'Change Username';
  static const checkingUsername = 'Checking username...';
  static const couldNotCheckThisUsername = 'Could not check this username.';
  static const couldNotCheckUsernameRightNow =
      'Could not check username right now.';
  static const thisUsernameIsAlreadyTaken = 'This username is already taken';
  static const thisUsernameIsAlreadyTakenLabel =
      'This username is already taken.';
  static const usernameIsAvailable = 'Username is available.';
  static const usernameIsTooLong = 'Username is too long';
  static const usernameMustBeAtLeast3Characters =
      'Username must be at least 3 characters';
  static const usernameMustIncludeALetter = 'Username must include a letter';
  static const usernameUnavailable = 'Username unavailable';
  static const youCanChangeYourUsernameAgainAfter7Days =
      'You can change your username again after 7 days.';
  static const useLettersNumbersDotsAndUnderscoresOnly =
      'Use letters, numbers, dots, and underscores only';
  static const useEnglishLettersDotsAndUnderscoresOnly =
      'Use English letters, dots, and underscores only';
  static const useEnglishLettersNumbersDotsAndUnderscoresOnly =
      'Use English letters, numbers, dots, and underscores only';
  static const eMail = 'E-mail';
  static const emailUpdates = 'Email updates';
  static const changeEmail = 'Change Email';
  static const checkingEmail = 'Checking email...';
  static const couldNotCheckThisEmail = 'Could not check this email.';
  static const couldNotCheckEmailRightNow = 'Could not check email right now.';
  static const emailCheckSkipped = 'Email check skipped';
  static const emailCheckFailed = 'Email check failed';
  static const emailCannotBeChanged = 'Email cannot be changed';
  static const contactSupportIfYouNeedHelpWithYourAccountEmail =
      'Contact support if you need help with your account email.';
  static const emailIsAlreadyRegistered = 'Email is already registered.';
  static const emailIsAvailable = 'Email is available.';
  static const emailUnavailable = 'Email unavailable';
  static const thisEmailIsAlreadyRegistered =
      'This email is already registered.';
  static const thisEmailIsNotRegistered = 'This email is not registered.';
  static const emailVerificationIsRequired = 'Email verification is required.';
  static const checkTheEmailAndTryAgain = 'Check the email and try again.';

  // ─── الموبايل ───
  static const phone = 'Phone';
  static const activationPhone = 'Activation phone';
  static const changePhone = 'Change Phone';
  static const checkingPhoneNumber = 'Checking phone number...';
  static const couldNotCheckThisPhoneNumber =
      'Could not check this phone number.';
  static const couldNotCheckPhoneNumberRightNow =
      'Could not check phone number right now.';
  static const phoneCheckSkipped = 'Phone check skipped';
  static const phoneNumberIsAlreadyRegistered =
      'Phone number is already registered.';
  static const phoneNumberIsAvailable = 'Phone number is available.';
  static const phoneUnavailable = 'Phone unavailable';
  static const thisPhoneNumberIsAlreadyRegistered =
      'This phone number is already registered.';
  static const thisIsAlreadyYourCurrentPhoneNumber =
      'This is already your current phone number.';
  static const enterAValidPhoneNumber = 'Enter a valid phone number';

  // ─── كلمة المرور والتحقق ───
  static const label8Characters = '8+ characters';
  static const numberSymbol = 'Number & symbol';
  static const upperLowercase = 'Upper & lowercase';
  static const passwordRequired = 'Password required';
  static const passwordIsRequired = 'Password is required.';
  static const enterYourPasswordFirst = 'Enter your password first.';
  static const passwordsDoNotMatch = 'Passwords do not match.';
  static const weakPassword = 'Weak password';
  static const mediumPassword = 'Medium password';
  static const strongPassword = 'Strong password';
  static const thePasswordIsIncorrect = 'The password is incorrect.';
  static const invalidPassword = 'Invalid password';
  static const invalidPasswordLabel = 'Invalid password.';
  static const newPasswordMustBeDifferentFromYourCurrentPassword =
      'New password must be different from your current password';
  static const newPasswordMustBeDifferentFromYourCurrentPasswordLabel =
      'New password must be different from your current password.';
  static const forgetPassword = 'Forget Password?';

  // ─── أمان الحساب ───
  static const accountSecurity = 'Account Security';
  static const changePassword = 'Change Password';
  static const verifyYourEmailToSetANewPassword =
      'Verify your email to set a new password';
  static const verificationCodeSent = 'Verification code sent';
  static const verificationCode = 'Verification code';
  static const enterThe6DigitVerificationCode =
      'Enter the 6-digit verification code.';
  static const newPassword = 'New Password';
  static const confirmNewPassword = 'Confirm New Password';
  static const passwordChanged = 'Password changed';
  static const yourPasswordWasChangedSuccessfullySignInAgainToContinue =
      'Your password was changed successfully. Sign in again to continue.';
  static const couldNotSendVerificationCode =
      'Could not send verification code';
  static const couldNotChangePassword = 'Could not change password';
  static const invalidVerificationCode = 'Invalid verification code';
  static const invalidVerificationCodeLabel = 'Invalid verification code.';
  static const invalidOrExpiredVerificationCode =
      'Invalid or expired verification code';
  static const invalidOrExpiredVerificationCodeLabel =
      'Invalid or expired verification code.';
  static const theVerificationCodeHasExpired =
      'The verification code has expired.';
  static const noActiveVerificationCodeWasFound =
      'No active verification code was found.';
  static const twoStepVerification = 'Two-step verification';
  static const accountDeletionNowRequiresYourAccountPasswordForConfirmation =
      'Account deletion now requires your account password for confirmation.';
  static const youCanUseTheCodeAlreadySentToYourEmail =
      'You can use the code already sent to your email.';
  static const youCanUseTheCodeAlreadySentToYourEmailLabel =
      'You can use the code already sent to your email. You can request another code when the timer ends.';

  // ─── حذف الحساب ───
  static const deleteAccount = 'Delete Account';
  static const deleteAccountPermanently = 'Delete account permanently?';
  static const accountWasNotDeleted = 'Account was not deleted';
  static const couldNotDeleteYourAccount = 'Could not delete your account.';
  static const permanentlyRemoveYourProfile =
      'Permanently remove your يلا ماركت profile';
  static const permanentlyRemoveYourYallaMarketProfile =
      'Permanently remove your Yalla Market profile';
  static const permanentlyRemoveYourProfileAndPersonalData =
      'Permanently remove your profile and personal data';
  static const thisCannotBeUndoneEnterYourAccountPasswordToConfirm =
      'This cannot be undone. Enter your account password to confirm permanent deletion.';
  static const deletingYourAccountRemovesYourProfileSavedAddressesCartReviews =
      'Deleting your account removes your profile, saved addresses, cart, reviews, and order history. This cannot be undone.';
  static const finishOrCancelAnyActiveOrdersFirst =
      'Finish or cancel any active orders first.';
  static const reviewActiveRefundsBeforeDeleting =
      'Review active refunds before deleting.';

  // ─── الإشعارات والتحديثات (حساب) ───
  static const ordersDealsAndAccountUpdates =
      'Orders, deals and account updates';
  static const orderOfferAndAccountUpdatesWillAppearHere =
      'Order, offer, and account updates will appear here.';
  static const offersOrderUpdatesAndAccountAlerts =
      'Offers, order updates, and account alerts';
  static const dealsOrderUpdatesAndAccountAlerts =
      'Deals, order updates and account alerts.';
  static const misuseOfOffersAccountsOrPaymentMethodsMayLimitAccess =
      'Misuse of offers, accounts, or payment methods may limit access to the app.';
  static const supportOrdersAndAccountHelp = 'Support, orders and account help';
  static const quickerHelpWithOrdersReturnsAndAccountIssues =
      'Quicker help with orders, returns, and account issues.';
  static const stayCloseToOrdersOffersAndAccountActivity =
      'Stay close to orders, offers and account activity.';
  static const receiveAccountAndPrivacyAlerts =
      'Receive account and privacy alerts.';
  static const openMyOrdersFromTheAccountPageToSeeThe =
      'Open My Orders from the account page to see the latest order status and delivery updates.';
  static const useTheWhatsAppButtonOnTheAccountPageForDirect =
      'Use the WhatsApp button on the account page for direct assistance.';

  // عبارات إضافية
  static const use8CharactersWithUppercaseLowercaseNumberAndSymbol =
      'Use 8+ characters with uppercase, lowercase, number, and symbol.';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String usernameChangeDate(String date) =>
      'You can change your username again on $date';
}

/// اختيار اللغة.
abstract final class LanguageTexts {
  static const languageTooltip = 'Switch language';
}

/// المنطقة والمدينة والموقع.
abstract final class RegionTexts {
  // ─── اختيار المنطقة ───
  static const changeYourRegion = 'Change your region';
  static const youCanChangeYourRegionHereAnytimeToSeeProducts =
      'You can change your region here anytime to see products and offers for your area.';
  static const outsideTheDeliveryAreaAdjustTheLocation =
      'Outside the delivery area. Adjust the location.';
  static const yourCurrentLocationIsOutsideTheDeliveryArea =
      'Your current location is outside the delivery area.';
  static const searchForAPlaceInEgypt = 'Search for a place in Egypt';
  static const browsingRegion = 'Browsing region';
  static const changeRegion = 'Change region';
  static const changeRegionManually = 'Change region manually';
  static const chooseYourCurrentCityOrTheNearestOne =
      'Choose your current city or the nearest one';
  static const chooseYourCurrentCityOrTheNearestOneLabel =
      'Choose your current city or the nearest one.';
  static const ifYourCityIsNotAvailableChooseOther =
      'If your city is not available, choose Other.';
  static const chooseManuallyOrLetGpsDetectYourArea =
      'Choose manually or let GPS detect your area.';
  static const chooseTheBrowsingRegionUsedForProducts =
      'Choose the browsing region used for products';
  static const generalBrowsing = 'General browsing';
  static const generalRegionSaved = 'General region saved';
  static const productsAndOffersWillRefreshForYourRegion =
      'Products and offers will refresh for your region.';
  static const productsThatFitYourRegion = 'Products that fit your region';
  static const productsWillRefreshForYourSelectedRegion =
      'Products will refresh for your selected region.';
  static const region = 'Region';
  static const regionNotChanged = 'Region not changed';
  static const regionSaved = 'Region saved';
  static const couldNotUpdateYourRegionYourCartWasNotChanged =
      'Could not update your region. Your cart was not changed.';
  static const theRegionWasChangedButTheCartCouldNotBe =
      'The region was changed, but the cart could not be cleared.';
  static const notAvailableInTheCurrentRegion =
      'Not available in the current region';
  static const thisOfferIsNotAvailableInYourCityRightNow =
      'This offer is not available in your city right now.';
  static const youAreNowInASupportedRegionSwitchToSee =
      'You are now in a supported region. Switch to see its offers. Your cart will be checked at checkout.';

  // ─── GPS والموقع ───
  static const locationAccessIsRequiredBeforeChoosingAnAddress =
      'Location access is required before choosing an address.';
  static const openLocationSettings = 'Open location settings';
  static const gpsAccessIsRequiredToOpenTheMap =
      'GPS access is required to open the map.';
  static const gpsCanTryToDetectYourAreaAutomatically =
      'GPS can try to detect your area automatically.';
  static const locationAccessIsRequired = 'Location access is required';
  static const chooseYourAreaManuallyAndYouCanTryGpsAgain =
      'Choose your area manually and you can try GPS again later.';
  static const detectingLocation = 'Detecting location...';
  static const detectingYourLocation = 'Detecting your location...';
  static const enableGpsAndContinue = 'Enable GPS and continue';
  static const gpsHelpsYallaMarketShowNearbyProductsLocalOffersBetter =
      'GPS helps Yalla Market show nearby products, local offers, better delivery suggestions, and more accurate delivery pricing later.';
  static const ifYourAreaIsNotHereAddItManually =
      'If your area is not here, add it manually';
  static const locationPermissionWasNotGrantedAllowLocationToContinue =
      'Location permission was not granted. Allow location to continue.';
  static const locationServicesAreDisabledTurnOnGpsToContinue =
      'Location services are disabled. Turn on GPS to continue.';
  static const turnOnGpsAndAllowLocationAccessBeforeEnteringThe =
      'Turn on GPS and allow location access before entering the app.';
  static const locationSettings = 'Location settings';
  static const useGpsLocation = 'Use GPS location';
  static const isThisYourGovernorate = 'Is this your governorate?';
  static const isThisYourCity = 'Is this your city?';
  static const weDetectedYourCity = 'We detected your city';
  static const weDetectedYourGovernorate = 'We detected your governorate';
  static const weCouldNotDetectASupportedGovernorateChooseOneManually =
      'We could not detect a supported governorate. Choose one manually.';

  // ─── المدينة ───
  static const chooseCity = 'Choose city';
  static const chooseTheCityUsedForAvailableProducts =
      'Choose the city used for available products';
  static const chooseYourCity = 'Choose your city';
  static const city = 'City';
  static const citySaved = 'City saved';
  static const cityNameIsRequired = 'City name is required';
  static const cityName = 'City: {name}';
  static const deliveryCity = 'Delivery City';
  static const enterYourCity = 'Enter your city';
  static const locationPermissionWasNotGrantedChooseYourCityManually =
      'Location permission was not granted. Choose your city manually.';
  static const locationServicesAreDisabledChooseYourCityManually =
      'Location services are disabled. Choose your city manually.';
  static const productsWillRefreshForYourSelectedCity =
      'Products will refresh for your selected city.';
  static const saveCity = 'Save city';
  static const soWeCanShowProductsAvailableInYourArea =
      'So we can show products available in your area.';
  static const soWeCanShowShopsAvailableInYourArea =
      'So we can show shops available in your area.';
  static const weCouldNotDetectASupportedCityChooseOneManually =
      'We could not detect a supported city. Choose one manually.';
  static const otherCity = 'Other city';

  // ─── منطقة التوصيل ───
  static const chooseADeliveryArea = 'Choose a delivery area';
  static const chooseADeliveryAreaLabel = 'Choose a delivery area.';
  static const chooseADeliveryAreaToSeeThePrice =
      'Choose a delivery area to see the price';
  static const deliveryArea = 'Delivery area';
  static const directAreaDelivery = 'Direct area delivery';
  static const enterYourAreaName = 'Enter your area name';
  static const myAreaIsNotListed = 'My area is not listed';
  static const yourCityIsOutsideTheCurrentServiceCitiesEnterYour =
      'Your city is outside the current service cities. Enter your city and area manually.';
  static const area = 'Area';

  // ─── أسماء المناطق والدول ───
  static const alexandria = 'Alexandria';
  static const cairo = 'Cairo';
  static const egypt = 'Egypt';
  static const egyptianPound = 'Egyptian Pound';
  static const nasrCity = 'Nasr City';
  static const newCairo = 'New Cairo';
  static const downtownCairo = 'Downtown Cairo';
  static const enterAValidEgyptianMobileNumberStartingWith011 =
      'Enter a valid Egyptian mobile number starting with 01, 1, 201, or +201.';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static const outsideServiceAreaTitle = 'Outside service area';
  static const locationChangedTitle = 'Location changed';
  static const outsideServiceAreaMessage =
      'It looks like you are outside our current service cities. Do you want to switch to General?';
  static String locationChangedMessage(
    String currentRegion,
    String detectedRegion,
  ) =>
      'Your current region is $currentRegion, and it looks like you are now in $detectedRegion. Do you want to change region?';
  static String keepCurrentRegion(String region) => 'Keep $region';
  static String changeToRegion(String region) => 'Change to $region';
  static const currentRegionFallback = 'your current region';
  static const cartClearedRegionWarning =
      'Changing region will clear your cart.';
}

/// العناوين والخريطة والشحن.
abstract final class AddressTexts {
  // ─── إدارة العناوين ───
  static const deliveryAddress = 'Delivery address';
  static const newAddress = 'New address';
  static const saveAddress = 'Save address';
  static const addNewAddress = 'Add new address';
  static const addAddress = 'Add Address';
  static const addAnAddressToStartCheckoutFaster =
      'Add an address to start checkout faster.';
  static const addressDeleted = 'Address deleted';
  static const addressSaved = 'Address saved';
  static const addressUpdated = 'Address updated';
  static const addressUpdateFailed = 'Address update failed';
  static const addressName = 'Address name';
  static const addressDetails = 'Address details';
  static const addressLabelOptional = 'Address label (optional)';
  static const addressRequired = 'Address required';
  static const addresses = 'Addresses';
  static const chooseASavedAddress = 'Choose a saved address';
  static const completeAddressDetailsHelpCheckoutAndDeliveryMoveFaster =
      'Complete address details help checkout and delivery move faster.';
  static const couldNotUpdateAddresses = 'Could not update addresses.';
  static const deleteAddress = 'Delete address?';
  static const deliveryAddressNeeded = 'Delivery address needed';
  static const deliveryIsNoLongerAvailableForThisAddress =
      'Delivery is no longer available for this address';
  static const editAddress = 'Edit Address';
  static const myAddresses = 'My Addresses';
  static const reviewAddress = 'Review address';
  static const selectAddress = 'Select Address';
  static const setShoppingDeliveryAddress = 'Set shopping delivery address';
  static const homeWorkOtherAddress = 'Home, Work, Other address';
  static const streetBuildingFloorLandmark =
      'Street, building, floor, landmark';
  static const removeNameFromYourSavedDeliveryLocations =
      'Remove {name} from your saved delivery locations?';
  static const saveADeliveryLocation = 'Save a delivery location';
  static const updateThisDeliveryLocation = 'Update this delivery location';
  static const storesWillAppearHereWhenTheyCoverYourAddress =
      'Stores will appear here when they cover your address.';
  static const thisStoreIsNotAvailableForYourCurrentAddress =
      'This store is not available for your current address.';
  static const yourPackageIsOnTheWayToYourAddress =
      'Your package is on the way to your address.';

  // ─── تفاصيل العنوان ───
  static const apartment = 'Apartment';
  static const house = 'House';
  static const office = 'Office';
  static const buildingName = 'Building name';
  static const apartmentNumber = 'Apartment number';
  static const floor = 'Floor';
  static const floorOptional = 'Floor (optional)';
  static const houseName = 'House name';
  static const company = 'Company';
  static const familyHome = 'Family home';
  static const street = 'Street';
  static const nameThisAddressSoYouCanIdentifyItEasily =
      'Name this address so you can identify it easily.';

  // ─── الخريطة والموقع ───
  static const confirmDeliveryLocation = 'Confirm delivery location';
  static const continueWithThisLocation = 'Continue with this location';
  static const yourOrderWillBeDeliveredToThisLocation =
      'Your order will be delivered to this location';
  static const placeSearchFailed = 'Place search failed.';
  static const addressLookupFailedYouCanStillContinue =
      'Address lookup failed. You can still continue.';
  static const findingTheAddress = 'Finding the address...';
  static const couldNotFindYourCurrentLocationTryAgain =
      'Could not find your current location. Try again.';
  static const mapLocationSelected = 'Map location selected';
  static const chooseLocationOnMap = 'Choose location on map';
  static const yourCurrentLocationIsSelectedMoveTheMapToAdjust =
      'Your current location is selected. Move the map to adjust it.';
  static const locationSelectedManually = 'Location selected manually.';
  static const currentLocationIsUnavailableMoveTheMapToChooseIt =
      'Current location is unavailable. Move the map to choose it manually.';
  static const automaticLocation = 'Automatic location';
  static const locationIsTakingTooLong = 'Location is taking too long';
  static const enableYourLocation = 'Enable your location';
  static const useMyCurrentLocation = 'Use my current location';
  static const editLocation = 'Edit location';
  static const couldNotUseYourCurrentLocation =
      'Could not use your current location.';
  static const couldNotFindYourCurrentLocationChooseOneManually =
      'Could not find your current location. Choose one manually.';

  // ─── الشحن ───
  static const shippingAddress = 'Shipping Address';
  static const shippingCompany = 'Shipping Company';
  static const shippingCompanyRequired = 'Shipping company required';
  static const chooseAShippingCompanyBeforeCompletingTheOrder =
      'Choose a shipping company before completing the order.';
  static const shippingAddressRequired = 'Shipping address required';
  static const completeTheDeliveryAddressFirst =
      'Complete the delivery address first.';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String savedLocations(int count) =>
      '$count saved location${count == 1 ? '' : 's'}';
  static String removeLocation(String name) =>
      'Remove $name from your saved delivery locations?';
  static String selectedForCheckout(String name) =>
      '$name is selected for checkout.';
}

/// المتاجر والمنتجات والبحث.
abstract final class StoreTexts {
  // ─── المتاجر ───
  static const store = 'Store';
  static const shop = 'Shop';
  static const market = 'Market';
  static const markets = 'Markets';
  static const popularStores = 'Popular Stores';
  static const latestStores = 'Latest Stores';
  static const browseAllPopularStores = 'Browse all popular stores';
  static const popularStoresWillAppearHereOnceAvailable =
      'Popular stores will appear here once available.';
  static const loadingStore = 'Loading store...';
  static const loadingStores = 'Loading stores...';
  static const storeCouldNotLoad = 'Store could not load';
  static const storeUnavailable = 'Store unavailable';
  static const noStoresAvailable = 'No stores available';
  static const noStoresFound = 'No stores found';
  static const noStoreCategories = 'No store categories';
  static const browseTheNewestStores = 'Browse the newest stores';
  static const newStoresWillAppearHereOnceAdded =
      'New stores will appear here once added.';
  static const categoriesWillAppearHereOnceStoresAreAvailable =
      'Categories will appear here once stores are available.';
  static const productsWillAppearHereOnceThisStoreIsReady =
      'Products will appear here once this store is ready.';
  static const tryADifferentStoreName = 'Try a different store name.';
  static const searchStores = 'Search stores...';
  static const tSStore = 'T\'s Store';
  static const marketBreakdown = 'Market breakdown';
  static const yallaMarket = 'Yalla Market';

  // ─── المنتجات ───
  static const products = 'Products';
  static const items = 'Items';
  static const popularProducts = 'Popular Products';
  static const latestProducts = 'Latest Products';
  static const loadingProducts = 'Loading products...';
  static const productsCouldNotLoad = 'Products could not load';
  static const noProductsAvailable = 'No products available';
  static const noProductsFound = 'No products found';
  static const noProductsInThisSection = 'No products in this section';
  static const productIsOutOfStock = 'Product is out of stock';
  static const inStock = 'In Stock';
  static const outOfStock = 'Out of Stock';
  static const stock = 'Stock';
  static const price = 'Price';
  static const egpPrice = 'EGP {price}';
  static const itemAdded = 'Item added';
  static const itemRemoved = 'Item removed';
  static const minimumQuantityIs1 = 'Minimum quantity is 1';
  static const noItemsToReview = 'No items to review';
  static const selectQuantityFirst = 'Select quantity first';
  static const browseTheLatestProducts = 'Browse the latest products';
  static const browseAllCuratedProducts = 'Browse all curated products';
  static const productsWillAppearHereOnceTheCatalogIsReady =
      'Products will appear here once the catalog is ready.';
  static const tryAnotherProductName = 'Try another product name.';
  static const searchProducts = 'Search products...';
  static const exploreProducts = 'Explore products';
  static const startShopping = 'Start Shopping';
  static const continueShopping = 'Continue Shopping';
  static const hideAgeRestrictedProducts = 'Hide age-restricted products';

  // ─── العروض ───
  static const offers = 'Offers';
  static const nearbyOffers = 'Nearby offers';
  static const packageOffer = 'Package offer';
  static const offerPrice = 'Offer price';
  static const personalizedOffers = 'Personalized offers';
  static const curatedPicksAndBrandDeals = 'Curated picks and brand deals';
  static const curatedPicksAndCategoryDeals =
      'Curated picks and category deals';
  static const sendThisProductOrCopyItsLink =
      'Send this product or copy its link.';
  static const copyProductLink = 'Copy product link';
  static const sendThisOfferOrCopyItsLink = 'Send this offer or copy its link.';

  // ─── البراندات ───
  static const brands = 'Brands';
  static const brandsPicks = 'Brands & picks';
  static const featuredBrands = 'Featured Brands';
  static const allBrands = 'All Brands';
  static const thisBrandCatalogIsEmptyTryAnotherBrandOrCheck =
      'This brand catalog is empty. Try another brand or check back later.';

  // ─── الأقسام والفئات ───
  static const categories = 'Categories';
  static const allCategories = 'All Categories';
  static const categoriesPicks = 'Categories & picks';
  static const featuredCategories = 'Featured Categories';
  static const popularCategories = 'Popular Categories';
  static const marketSections = 'Market sections';
  static const exploreMarketCategories = 'Explore market categories';
  static const exploreTrustedStores = 'Explore trusted stores';
  static const productsAndCategories = 'Products and categories';
  static const productsShopsAndCategories = 'Products, shops and categories';
  static const searchShops = 'Shops';
  static const searchCategories = 'Categories';
  static const searchProductsShopsAndCategories =
      'Search products, shops and categories...';
  static const tryAProductShopOrCategoryName =
      'Try a product, shop or category name.';
  static const loadMoreProducts = 'Load more products';
  static const pleaseLoginToSearch = 'Please login to search';
  static const productsBrandsAndCategories = 'Products, brands and categories';
  static const thisCategoryIsEmptyTryAnotherCategoryOrCheckBack =
      'This category is empty. Try another category or check back later.';

  // ─── البحث والفلتر ───
  static const filterProducts = 'Filter products...';
  static const sortBy = 'Sort by';
  static const sortProducts = 'Sort products';
  static const higherPrice = 'Higher Price';
  static const lowerPrice = 'Lower Price';
  static const searchBrandsProducts = 'Search brands, products...';
  static const searchProductsBrands = 'Search products, brands...';
  static const searchProductsBrandsCategories =
      'Search products, brands, categories...';
  static const searchCategoriesProducts = 'Search categories, products...';
  static const searchProductsAndCategories =
      'Search products and categories...';
  static const tryABrandCategoryOrAShorterProductName =
      'Try a brand, category, or a shorter product name.';
  static const tryACategoryOrAShorterProductName =
      'Try a category or a shorter product name.';
  static const tryProductNamesBrandsCategoriesOrSaleKeywords =
      'Try product names, brands, categories, or sale keywords.';
  static const tryProductNamesCategoriesOrSaleKeywords =
      'Try product names, categories, or sale keywords.';
  static const tryAnotherSearchCategoryOrSortingOption =
      'Try another search, category, or sorting option.';
  static const tryItFromTheWebPreview = 'Try it from the web preview.';

  // ─── معلومات المتجر ───
  static const savedProductsAndStores = 'Saved products and stores';
  static const generalProductsAndOffersWillBeShown =
      'General products and offers will be shown.';
  static const youWillSeeGeneralProductsAndOffers =
      'You will see general products and offers.';
  static const fixedPriceDelivery = 'Fixed-price delivery';
  static const deliveryPriceDeterminedLater =
      'Delivery - price determined later';
  static const deliveryEgpPrice = 'Delivery: EGP {price}';
  static const yallaMarketMakesShoppingFromLocalMarketsSimpleAndFast =
      'Yalla Market makes shopping from local markets simple and fast.';
  static const simpleShoppingFromTrustedLocalMarkets =
      'Simple shopping from trusted local markets.';
  static const usingYallaMarket = 'Using Yalla Market';
  static const localPricesAndDelivery = 'Local prices and delivery';
  static const shoppingSetup = 'Shopping setup';
  static const pendingReview = 'Pending review';
  static const review = 'Review';
  static const previewSalesBeforeTheyGoLive =
      'Preview sales before they go live.';
  static const useShoppingActivityForBetterDeals =
      'Use shopping activity for better deals.';
  static const yourItemWillBeShippedSoon = 'Your item will be shipped soon!';
  static const ratingsAndReviewsAreVerifiedAndAreFromPeopleWho =
      'Ratings and reviews are verified and are from people who use the same type of device that you use.';
  static const saveTheProductsYouLoveAndFindThemHereWhenever =
      'Save the products you love and find them here whenever you are ready.';
  static const tuneShoppingAlertsAndDataUsage =
      'Tune shopping, alerts and data usage';
  static const freshPicksAreAvailableInTheMostRequestedCategories =
      'Fresh picks are available in the most requested categories.';

  // ─── الدول (في سياق المتجر) ───
  static const unitedArabEmirates = 'United Arab Emirates';
  static const unitedKingdom = 'United Kingdom';
  static const unitedStates = 'United States';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String productsForBrand(String brand) => 'View $brand products';
  static String productCountLabel(String count) =>
      '$count product${count == '1' ? '' : 's'}';
  static String productCount(int count) =>
      '$count product${count == 1 ? '' : 's'}';
  static String storeCount(String count) =>
      '$count store${count == '1' ? '' : 's'}';
  static String marketCount(String count) =>
      '$count market${count == '1' ? '' : 's'}';
  static String offerCount(String count) =>
      '$count offer${count == '1' ? '' : 's'}';
  static String searchResults(int count, String query) =>
      '$count result${count == 1 ? '' : 's'} for "$query"';
  static String noBrandProducts(String brand) => 'No $brand products yet';
  static String noCategoryItems(String category) => 'No $category items yet';
  static String noSearchResults(String query) => 'No results for "$query"';
}

/// الطلبات والسلة والدفع.
abstract final class OrderTexts {
  // ─── السلة ───
  static const cart = 'Cart';
  static const myCart = 'My Cart';
  static const yourCartIsEmpty = 'Your cart is empty';
  static const addToCart = 'Add to cart';
  static const addItemsToYourCartBeforeCheckout =
      'Add items to your cart before checkout.';
  static const addProductsYouLikeAndReviewThemHereBeforeCheckout =
      'Add products you like and review them here before checkout.';
  static const addRemoveProductsAndMoveToCheckout =
      'Add, remove products and move to checkout';
  static const productAddedToCart = 'Product added to cart';
  static const itemRemovedFromCart = 'Item removed from cart';
  static const thisProductCannotBeAddedToCartRightNow =
      'This product cannot be added to cart right now.';
  static const yourCartWasClearedAndContentWasRefreshed =
      'Your cart was cleared and content was refreshed.';

  // ─── الدفع ───
  static const checkout = 'Checkout';
  static const checkoutFailed = 'Checkout failed';
  static const confirmOrder = 'Confirm Order';
  static const confirmItemsAndPayment = 'Confirm items and payment';
  static const confirmingYourOrder = 'Confirming your order';
  static const processingYourOrder = 'Processing your order';
  static const pleaseWaitWhileWeSaveYourOrderDetails =
      'Please wait while we save your order details.';
  static const paymentMethod = 'Payment Method';
  static const selectPaymentMethod = 'Select Payment Method';
  static const paymentSuccess = 'Payment Success!';
  static const cashOnDelivery = 'Cash on Delivery';
  static const payWhenYourOrderArrives = 'Pay when your order arrives';
  static const payCash = 'Pay cash';
  static const payCashOnline = 'Pay cash & online';
  static const paymentAndSensitiveDataShouldOnlyBeEnteredOnTrusted =
      'Payment and sensitive data should only be entered on trusted checkout screens.';
  static const chooseWhereOrdersShouldArrive =
      'Choose where orders should arrive';

  // ─── الطلبات ───
  static const orders = 'Orders';
  static const myOrders = 'My Orders';
  static const orderSummary = 'Order Summary';
  static const orderReview = 'Order Review';
  static const orderTotal = 'Order Total';
  static const orderTotalLabel = 'Order total';
  static const orderConfirmed = 'Order confirmed';
  static const orderConfirmedSuccessfully = 'Order Confirmed Successfully!';
  static const orderConfirmationFailed = 'Order confirmation failed';
  static const orderDate = 'Order date';
  static const orderRejected = 'Order rejected';
  static const yourOrderOrderIdWasRejected =
      'Your order #{orderId} was rejected.';
  static const newOrderAssigned = 'New order assigned';
  static const aNewOrderOrderIdHasBeenAssignedToYou =
      'A new order #{orderId} has been assigned to you.';
  static const newOrderRequiresReview = 'New order requires review';
  static const orderOrderIdRequiresAdminReview =
      'Order #{orderId} requires admin review.';
  static const orderTrackingVisibility = 'Order tracking visibility';
  static const ordersCouldNotLoad = 'Orders could not load';
  static const loadingOrders = 'Loading orders...';
  static const noOrdersInThisPeriod = 'No orders in this period';
  static const inProgressAndCompletedOrders =
      'In-progress and completed orders';
  static const orderTotalsAreStillLoading = 'Order totals are still loading.';
  static const couldNotRefreshOrderTotalsTryAgain =
      'Could not refresh order totals. Try again.';
  static const ordersReturnsAndCancellationsFollowTheStorePoliciesShownAt =
      'Orders, returns, and cancellations follow the store policies shown at checkout.';
  static const yourOrderHasBeenCreatedSuccessfully =
      'Your order has been created successfully.';

  // ─── التوصيل والشحن ───
  static const delivered = 'Delivered';
  static const deliveryFee = 'delivery fee';
  static const deliveryPrice = 'Delivery price';
  static const deliveryPriceWillBeConfirmedLater =
      'Delivery price will be confirmed later';
  static const deliveryPriceApproval = 'Delivery price approval';
  static const theDeliveryPriceWasSetByTheAdministrationReviewIt =
      'The delivery price was set by the administration. Review it before approving.';
  static const approveDeliveryPrice = 'Approve delivery price';
  static const deliveryPriceApproved = 'Delivery price approved';
  static const couldNotApproveDeliveryPrice =
      'Could not approve delivery price';
  static const fixedDeliveryPricePrice = 'Fixed delivery price: {price}';
  static const moreAccurateDeliveryPriceLater =
      'More accurate delivery price later';
  static const externalShippingPriceLater = 'External shipping - price later';
  static const shippingFee = 'Shipping Fee';
  static const shippingDate = 'Shipping Date';
  static const shippingDateLabel = 'Shipping date';
  static const couldNotLoadShippingCompanies =
      'Could not load shipping companies.';
  static const shippingCompaniesAreStillLoading =
      'Shipping companies are still loading.';
  static const nameIsSelectedForCheckout = '{name} is selected for checkout.';

  // ─── المبالغ ───
  static const discount = 'Discount';
  static const offerDiscount = 'Offer discount';
  static const subtotal = 'Subtotal';
  static const marketTotal = 'Market total';
  static const productsSubtotal = 'Products subtotal';
  static const taxFee = 'Tax Fee';
  static const total = 'Total';

  // ─── نصوص متنوعة (طلبات) ───
  static const youAreOfflineShowingSavedContentCheckoutAndUpdatesNeed =
      'You are offline. Showing saved content; checkout and updates need internet.';
  static const productAvailabilityPricesAndDeliveryTimesCanChangeBeforeAn =
      'Product availability, prices, and delivery times can change before an order is confirmed.';
  static const ordersAndAvailability = 'Orders and availability';
  static const makeFeelYours = 'Make يلا ماركت feel yours';
  static const refundFromOrderCwt0152 = 'Refund from order CWT0152';
  static const howCanITrackMyOrder = 'How can I track my order?';
  static const trackOrder = 'Track order';
  static const trackMyOrder = 'Track my order';
  static const activeDiscountsAndRewards = 'Active discounts and rewards';
  static const allowSupportToViewOrderStatus =
      'Allow support to view order status.';
  static const canYouTrackMyOrder = 'Can you track my order?';
  static const fasterHandlingForEligibleOrders =
      'Faster handling for eligible orders.';
  static const freshProductsVerifiedBrandsAndQuickCartActions =
      'Fresh products, verified brands, and quick cart actions.';
  static const freshProductsTrustedCategoriesAndQuickCartActions =
      'Fresh products, trusted categories, and quick cart actions.';
  static const hiINeedHelpTrackingMyLatestOrder =
      'Hi, I need help tracking my latest order.';
  static const sureYourOrderIsBeingPreparedAndShouldShipToday =
      'Sure. Your order is being prepared and should ship today.';
  static const discountsUpTo = 'Discounts up to';
  static const orderHelpRefundsAndDeliveryUpdates =
      'Order help, refunds and delivery updates';
  static const ordersRefundsAndDeliveryUpdates =
      'Orders, refunds and delivery updates';
  static const yourNikeTrainingOrderIsBeingPrepared =
      'Your Nike training order is being prepared.';
  static const yourSportsOrderIsBeingPrepared =
      'Your sports order is being prepared.';

  // عبارات إضافية
  static const iNeedARefund = 'I need a refund.';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String itemsAddedToCart(String count) =>
      '$count item(s) added to cart';
}

/// الإشعارات.
abstract final class NotificationTexts {
  static const notifications = 'Notifications';
  static const notificationsUpdated = 'Notifications updated';
  static const notificationDeleted = 'Notification deleted';
  static const notificationDetails = 'Notification details';
  static const notificationsMarkedAsRead = 'Notifications marked as read';
  static const loadingNotifications = 'Loading notifications...';
  static const noNotificationsYet = 'No notifications yet';
  static const unreadNotifications = 'unread notifications';
  static const pushNotifications = 'Push notifications';
  static const mobileNotifications = 'Mobile Notifications';
  static const refreshNotifications = 'Refresh notifications';
  static const markAllAsRead = 'Mark all as read';
  static const deleteAllNotifications = 'Delete all notifications';
  static const deleteAllNotificationsLabel = 'Delete all notifications?';
  static const thisWillPermanentlyDeleteAllYourNotifications =
      'This will permanently delete all your notifications.';
  static const allNotificationsDeleted = 'All notifications deleted';
  static const couldNotDeleteAllNotifications =
      'Could not delete all notifications.';
  static const couldNotMarkNotificationsAsRead =
      'Could not mark notifications as read.';
  static const couldNotMarkNotificationAsRead =
      'Could not mark notification as read.';
  static const couldNotRefreshNotifications =
      'Could not refresh notifications.';
  static const couldNotUpdateNotifications = 'Could not update notifications.';
  static const notificationsCouldNotLoad = 'Notifications could not load';
}

/// المفضلة والمشاركة.
abstract final class FavoriteTexts {
  // ─── المفضلة ───
  static const wishlist = 'Wishlist';
  static const favoriteProducts = 'Favorite products';
  static const favoriteStores = 'Favorite stores';
  static const savedProductsAndFavorites = 'Saved products and favorites';
  static const yourWishlistIsWaiting = 'Your wishlist is waiting';
  static const addedToWishlist = 'Added to wishlist';
  static const itemAddedToWishlist = 'Item added to wishlist';
  static const itemRemovedFromWishlist = 'Item removed from wishlist';
  static const removedFromWishlist = 'Removed from wishlist';
  static const couldNotUpdateFavoriteStores =
      'Could not update favorite stores';
  static const storeAddedToFavorites = 'Store added to favorites';
  static const storeRemovedFromFavorites = 'Store removed from favorites';

  // ─── المشاركة ───
  static const share = 'Share';
  static const shareProduct = 'Share product';
  static const shareOffer = 'Share offer';
  static const shareWith = 'Share with...';
  static const copyLink = 'Copy link';
  static const productLinkCopied = 'Product link copied';
  static const offerLinkCopied = 'Offer link copied';
  static const youCanShareItWithAnyone = 'You can share it with anyone.';
  static const couldNotShareProduct = 'Could not share product';
  static const couldNotShareOffer = 'Could not share offer';
  static const couldNotShareStore = 'Could not share store';
}

/// الشراكة والدعم وعن التطبيق.
abstract final class PartnerTexts {
  // ─── الدعم الفني ───
  static const technicalSupport = 'Technical Support';
  static const contactSupportForAssistance = 'Contact support for assistance.';
  static const whatsapp = 'WhatsApp';
  static const couldNotOpenWhatsApp = 'Could not open WhatsApp';
  static const notSupportedHere = 'Not supported here';
  static const supportChat = 'Support chat';
  static const supportChatWillBeAvailableSoon =
      'Support chat will be available soon';
  static const supportIsOnline = 'Support is online';
  static const support = 'يلا ماركت Support';
  static const howDoIContactSupport = 'How do I contact support?';
  static const returnHelp = 'Return help';
  static const prioritySupport = 'Priority support';
  static const iNeedHelpWithAReturn = 'I need help with a return.';
  static const thanksSupportWillReviewThisAndReplyShortly =
      'Thanks. Support will review this and reply shortly.';

  // ─── حول التطبيق ───
  static const aboutTheApp = 'About the app';
  static const learnMoreAboutYallaMarket = 'Learn more about Yalla Market';
  static const aboutYallaMarket = 'About Yalla Market';
  static const privacyPolicy = 'Privacy policy';
  static const privacyPolicyLabel = 'Privacy Policy';
  static const privacyStatusProtected = 'Privacy status: protected';
  static const termsOfUse = 'Terms of use';
  static const pleaseAcceptThePrivacyPolicyAndTermsOfUse =
      'Please accept the Privacy Policy and Terms of use.';
  static const everythingYouNeedToKnowAboutTheApp =
      'Everything you need to know about the app';

  // ─── الشراكة ───
  static const registerAsAPartner = 'Register as a partner';
  static const joinYallaMarketAsAStoreOrServicePartner =
      'Join Yalla Market as a store or service partner';
  static const growYourBusinessWithYallaMarket =
      'Grow your business with Yalla Market';
  static const becomeAYallaMarketPartner = 'Become a Yalla Market partner';
  static const tellUsAboutYourBusinessAndOurTeamWillContact =
      'Tell us about your business and our team will contact you after reviewing your application.';
  static const businessInformation = 'Business information';
  static const businessName = 'Business name';
  static const businessType = 'Business type';
  static const numberOfBranches = 'Number of branches';
  static const label1Branch = '1 branch';
  static const label2Branches = '2 branches';
  static const label3Branches = '3 branches';
  static const label4Branches = '4 branches';
  static const label5Branches = '5 branches';
  static const contactPerson = 'Contact person';
  static const yourRoleInTheBusiness = 'Your role in the business';
  static const ownerPartner = 'Owner / Partner';
  static const managerLegalRepresentative = 'Manager / Legal representative';
  static const contactDetails = 'Contact details';
  static const doYouHaveATradeLicense = 'Do you have a trade license?';
  static const restaurant = 'Restaurant';
  static const serviceProvider = 'Service provider';
  static const couldNotSubmitPartnerApplication =
      'Could not submit partner application';
  static const couldNotSubmitPartnerApplicationLabel =
      'Could not submit partner application.';
  static const partnerApplicationResponseWasIncomplete =
      'Partner application response was incomplete.';
  static const youAlreadyHaveAPartnerApplicationUnderReview =
      'You already have a partner application under review.';
  static const weReceivedThePartnerApplicationFor =
      'We received the partner application for';
  static const ourTeamWillReviewItAndContactYouSoon =
      'Our team will review it and contact you soon.';
  static const weWillContactYouSoon = 'We will contact you soon.';
  static const contactToActivate = 'Contact to Activate';

  // ─── الخصوصية والبيانات ───
  static const thisHelpsPersonalizeYourShoppingExperience =
      'This helps personalize your shopping experience.';
  static const activateItThroughSupportToUnlockPremiumShoppingPerks =
      'Activate it through support to unlock premium shopping perks.';
  static const askSupportForADataCopyBeforeYouDelete =
      'Ask support for a data copy before you delete.';
  static const dataProtection = 'Data protection';
  static const weApplySecurityControlsToProtectYourInformationAndNever =
      'We apply security controls to protect your information and never sell your personal data.';
  static const yourInformation = 'Your information';
}

/// الإعدادات والمظهر.
abstract final class SettingsTexts {
  static const appSettings = 'App Settings';
  static const appSettingsLabel = 'App settings';
  static const appPreferences = 'App Preferences';
  static const appPreferencesLabel = 'App preferences';
  static const openAppSettings = 'Open app settings';
  static const appearance = 'Appearance';
  static const theme = 'Theme';
  static const dark = 'Dark';
  static const light = 'Light';
  static const alwaysUseTheDarkTheme = 'Always use the dark theme.';
  static const alwaysUseTheLightTheme = 'Always use the light theme.';
  static const useYourDeviceThemeSetting = 'Use your device theme setting.';
  static const language = 'Language';
  static const currency = 'Currency';
  static const currencySaved = 'Currency saved';
  static const dataPreferences = 'Data preferences';
  static const safeMode = 'Safe Mode';
  static const safeModeLabel = 'Safe mode';
  static const useThisShortcutForTheSettingsPeopleChangeMostOften =
      'Use this shortcut for the settings people change most often.';
}

/// الرئيسية والترويج.
abstract final class HomeTexts {
  static const home = 'Home';
  static const discoverLimitlessChoicesAndUnmatchedConvenience =
      'Discover Limitless Choices and Unmatched Convenience.';
  static const freshDealsAreLoading = 'Fresh deals are loading';
  static const homePetsAndDailyEssentials = 'Home, pets and daily essentials';
  static const membershipBenefits = 'Membership benefits';
  static const popularity = 'Popularity';
  static const everythingYouNeedInOnePlace = 'Everything you need in one place';
  static const howDoIPlaceAnOrder = 'How do I place an order?';
  static const chooseYourMarketAndProductsAddTheDeliveryAddressThen =
      'Choose your market and products, add the delivery address, then confirm your order from the cart.';

  // عبارات إضافية
  static const fastDeliveryToYourDoor = 'Fast Delivery to Your Door';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String freshPicks(String title) => 'Fresh $title picks';
}

/// الوقت والتاريخ.
abstract final class TimeTexts {
  // ─── الوقت النسبي ───
  static const justNow = 'Just now';
  static const minAgo = 'min ago';
  static const minsAgo = 'mins ago';
  static const hourAgo = 'hour ago';
  static const hoursAgo = 'hours ago';
  static const daysAgo = 'days ago';
  static const minutes = 'minutes';
  static const minutesMin = '{minutes} min';
  static const today = 'Today';
  static const yesterday = 'Yesterday';
  static const thisWeek = 'This week';
  static const thisMonth = 'This month';
  static const endsToday = 'Ends today';
  static const label3DaysLeft = '3 days left';
  static const label1WeekLeft = '1 week left';

  // ─── التاريخ ───
  static const chooseDate = 'Choose date';
  static const day = 'Day';
  static const month = 'Month';
  static const year = 'Year';
  static const selectedDays = 'Selected days';
  static const birthDate = 'Birth Date';
  static const changeBirthDate = 'Change Birth Date';
  static const chooseYourBirthDate = 'Choose your birth date';

  // ─── تحديثات الحالة ───
  static const contentUpdated = 'Content updated';
  static const languageUpdated = 'Language updated';
  static const statusUpdated = 'Status updated';
  static const themeUpdated = 'Theme updated';
  static const shipmentUpdate = 'Shipment update';
  static const popularCategoriesUpdated = 'Popular categories updated';
  static const activateNow = 'Activate now';

  // ─── متنوع (وقت) ───
  static const goodDayForShopping = 'Good day for shopping';
  static const usuallyRepliesInAFewMinutes = 'Usually replies in a few minutes';
  static const iWouldLikeToReceiveUpdatesByWhatsApp =
      'I would like to receive updates by WhatsApp';
  static const offlineUpdatesHint =
      'No internet connection. Check your network to continue updates.';
  static const youCanAlsoAskAboutRefundsReturnsOrDeliveryUpdates =
      'You can also ask about refunds, returns, or delivery updates.';
  static const thisVariationIsAvailableNowWithLimitedStock =
      'This variation is available now with limited stock.';
  static const everydayTrainingJacket = 'Everyday training jacket';
}

/// التسميات والأقسام والنصوص المتنوعة.
abstract final class GeneralTexts {
  // ─── تسميات أساسية ───
  static const name = 'Name';
  static const type = 'Type';
  static const color = 'Color';
  static const size = 'Size';
  static const small = 'Small';
  static const medium = 'Medium';
  static const large = 'Large';
  static const xLarge = 'X-Large';
  static const variant = 'Variant';
  static const description = 'Description';
  static const country = 'Country';
  static const state = 'State';
  static const postalCode = 'Postal Code';
  static const gender = 'Gender';
  static const male = 'Male';
  static const female = 'Female';
  static const other = 'Other';
  static const preferNotToSay = 'Prefer not to say';
  static const firstName = 'First name';
  static const lastName = 'Last name';
  static const lastNameLabel = 'Last Name';
  static const firstNameLabel = 'First Name';
  static const mobileNumber = 'Mobile number';
  static const landlineOptional = 'Landline (optional)';
  static const egp = 'EGP';
  static const version = 'Version';
  static const frequentlyAskedQuestions = 'Frequently asked questions';

  // ─── إجراءات ───
  static const add = 'Add';
  static const addToBag = 'Add to Bag';
  static const apply = 'Apply';
  static const change = 'Change';
  static const changeGender = 'Change Gender';
  static const changeName = 'Change Name';
  static const download = 'Download';
  static const enter = 'Enter';
  static const from = 'From';
  static const to = 'To';
  static const reset = 'Reset';
  static const send = 'Send';
  static const skip = 'Skip';
  static const switchText = 'Switch';
  static const all = 'All';
  static const defaultText = 'Default';
  static const custom = 'Custom';
  static const manual = 'Manual';
  static const automatic = 'Automatic';
  static const general = 'General';

  // ─── حالات ───
  static const active = 'Active';
  static const approved = 'Approved';
  static const disabled = 'Disabled';
  static const expired = 'Expired';
  static const verified = 'Verified';
  static const pending = 'Pending';
  static const pickedUp = 'Picked up';
  static const preparing = 'Preparing';
  static const ready = 'Ready';
  static const rejected = 'Rejected';
  static const permanent = 'Permanent';
  static const permanentDeletion = 'Permanent deletion';
  static const online = 'Online';
  static const offline = 'Offline';
  static const comingSoon = 'Coming soon';
  static const welcome = 'Welcome';
  static const gotIt = 'Got it';

  // ─── التوصيل ───
  static const delivery = 'Delivery';
  static const deliveryType = 'Delivery type';
  static const deliveryWithin = 'Delivery within';
  static const deliveringTo = 'Delivering to:';
  static const free = 'Free';
  static const freeDelivery = 'Free delivery';
  static const priorityDelivery = 'Priority delivery';
  static const betterDeliveryExperience = 'Better delivery experience';
  static const courier = 'Courier';
  static const courierAssigned = 'Courier assigned';
  static const later = 'Later';
  static const determinedLater = 'Determined later';
  static const shipmentOnTheWay = 'Shipment on the way';

  // ─── العضوية ───
  static const goldMembership = 'Gold Membership';
  static const goldMember = 'Gold member';
  static const goldMemberIsInactive = 'Gold member is inactive';
  static const inactivePlan = 'Inactive plan';
  static const earlySaleAccess = 'Early sale access';

  // ─── النصوص والمحتوى ───
  static const readMore = ' read more';
  static const showLess = ' show less';
  static const additionalInstructionsOptional =
      'Additional instructions (optional)';
  static const additionalValue = 'Additional value';
  static const agreementRequired = 'Agreement required';
  static const beforeDeleting = 'Before deleting';
  static const imageDownloadStarted = 'Image download started';
  static const hdImageQuality = 'HD Image Quality';
  static const writeAMessage = 'Write a message...';
  static const typeAMessage = 'Type a message';
  static const addANewStop = 'Add a new stop';
  static const quickControls = 'Quick controls';
  static const refund = 'Refund';
  static const security = 'Security';
  static const securityAndDataControls = 'Security and data controls';
  static const newArrivals = 'New arrivals';
  static const sale = 'Sale';
  static const additions = 'Additions';
  static const thisFieldIsRequired = 'This field is required';
  static const thisFieldIsRequiredLabel = 'This field is required.';
  static const enterAValidMobileNumber = 'Enter a valid mobile number.';
  static const pleaseCompleteTheRequiredFields =
      'Please complete the required fields.';
  static const nameIsTooShort = 'Name is too short';
  static const requireACodeForSensitiveActions =
      'Require a code for sensitive actions.';
  static const iAgreeTo = 'I agree to ';
  static const and = ' and ';
  static const enterAValidEmailAddress = 'Enter a valid email address.';
  static const enterAValidEmailAddressLabel = 'Enter a valid email address';
  static const useAnEmailAddressYouCanAccessForAccountRecovery =
      'Use an email address you can access for account recovery.';
  static const welcomeTo = 'Welcome to يلا ماركت.';

  // ─── الأقسام ───
  static const clothes = 'Clothes';
  static const electronics = 'Electronics';
  static const electronicDevices = 'Electronic devices';
  static const mobile = 'Mobile';
  static const accessories = 'Accessories';
  static const spareParts = 'Spare parts';
  static const fashion = 'Fashion';
  static const furniture = 'Furniture';
  static const lifestyle = 'Lifestyle';
  static const pets = 'Pets';
  static const shoes = 'Shoes';
  static const sportShoes = 'Sport Shoes';
  static const sports = 'Sports';
  static const sportsEquipment = 'Sports Equipment';
  static const trackSuits = 'Track Suits';
  static const shoesKitsAndTrainingGear = 'Shoes, kits and training gear';
  static const jacketsShirtsAndOutfits = 'Jackets, shirts and outfits';
  static const phonesDevicesAndAccessories = 'Phones, devices and accessories';
  static const newest = 'Newest';
  static const bestMatch = 'Best match';
  static const systemDefault = 'System default';
  static const toActivate = 'To activate';
  static const paypal = 'PayPal';
  static const paypalBalance = 'PayPal Balance';

  // ─── الدول والمدن ───
  static const argentina = 'Argentina';
  static const india = 'India';
  static const pakistan = 'Pakistan';
  static const saudiArabia = 'Saudi Arabia';
  static const turkey = 'Turkey';
  static const usa = 'USA';
  static const heliopolis = 'Heliopolis';
  static const maadi = 'Maadi';
  static const zamalek = 'Zamalek';
  static const shubra = 'Shubra';
  static const helwan = 'Helwan';
  static const label15May = '15 May';
  static const mokattam = 'Mokattam';
  static const mansoura = 'Mansoura';
  static const hurghada = 'Hurghada';
  static const sharmElSheikh = 'Sharm El Sheikh';
  static const tanta = 'Tanta';
  static const naamaBay = 'Naama Bay';
  static const nabq = 'Nabq';
  static const hadaba = 'Hadaba';

  // ─── اللغة ───
  static const arabic = 'Arabic';
  static const arabicInterface = 'Arabic interface';
  static const english = 'English';
  static const englishInterface = 'English interface';

  // ─── عينات المنتجات (Demo / Preview) ───
  static const appleIPhone8Black64Gb = 'APPLE iPhone 8 (Black, 64 GB)';
  static const blueTShirtForAllAges = 'Blue T-shirt for all ages';
  static const black = 'Black';
  static const green = 'Green';
  static const red = 'Red';
  static const lightweightActiveTee = 'Lightweight active tee';
  static const performanceGymKit = 'Performance gym kit';
  static const premiumLeatherJacket = 'Premium leather jacket';
  static const eliteTrainingFootball = 'Elite training football';
  static const courtReadyAccessories = 'Court-ready accessories';
  static const warmupStreetHoodie = 'Warmup street hoodie';
  static const airMaxRunningShoes = 'Air Max running shoes';
  static const wildhorseTrailShoes = 'Wildhorse trail shoes';
  static const greenNikeSportsShoe = 'Green Nike sports shoe';
  static const nikeAirJordanOrange = 'Nike Air Jordan Orange';
  static const nikeAirJordanRedBlack = 'Nike Air Jordan Red Black';
  static const nikeWildhorseRunningShoe = 'Nike Wildhorse Running Shoe';
  static const jordanCourtBlue = 'Jordan court blue';
  static const samsungS9MobileBundle = 'Samsung S9 mobile bundle';
  static const tomiDryFoodPack = 'Tomi dry food pack';
  static const visaEnding4721 = 'Visa ending 4721';
  static const label20OffSportsPicks = '20% off sports picks';
  static const greenSportsShoe = 'Green sports shoe';
  static const redBlackSportsSneaker = 'Red black sports sneaker';
  static const orangeSportsSneaker = 'Orange sports sneaker';
  static const trailRunningShoe = 'Trail running shoe';
  static const blueCourtSneaker = 'Blue court sneaker';
  static const codingWithT = 'Coding with T';

  // ─── البراندات ───
  static const acer = 'Acer';
  static const adidas = 'Adidas';
  static const apple = 'Apple';
  static const hermanMiller = 'Herman Miller';
  static const ikea = 'IKEA';
  static const jordan = 'Jordan';
  static const kenwood = 'Kenwood';
  static const nike = 'Nike';
  static const puma = 'Puma';
  static const zara = 'ZARA';
}
