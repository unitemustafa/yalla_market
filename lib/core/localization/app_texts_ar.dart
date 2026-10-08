// نصوص يلا ماركت العربية، مقسمة حسب الشاشة والقسم.
//
// عدّل قيمة المتغير المطلوب هنا لتغيير النص في التطبيق.
// نفس أسماء الأقسام والمتغيرات موجودة في ملف اللغة الأخرى.
// عند إضافة نص جديد، أضف متغيره في الملفين واربطه في app_text_catalog.dart.

/// اسم التطبيق والعلامة.
abstract final class BrandTexts {
  // ─── التطبيق ───
  static const appName = 'يلا ماركت';
}

/// الأزرار والرسائل العامة.
abstract final class CommonTexts {
  // ─── الأزرار العامة ───
  static const skip = 'تخطي';
  static const continueText = 'كمّل';
  static const done = 'تمام';
  static const startShopping = 'ابدأ التسوق';
  static const submit = 'إرسال';
  static const resendEmail = 'ابعت الإيميل تاني';

  // ─── أزرار وإجراءات ───
  static const cancel = 'إلغاء';
  static const clear = 'مسح';
  static const clearSearch = 'مسح البحث';
  static const close = 'إغلاق';
  static const confirm = 'تأكيد';
  static const delete = 'حذف';
  static const doneLabel = 'تم';
  static const edit = 'تعديل';
  static const next = 'التالي';
  static const previous = 'السابق';
  static const back = 'رجوع';
  static const save = 'حفظ';
  static const saveChanges = 'حفظ التغييرات';
  static const search = 'البحث';
  static const retry = 'حاول تاني';
  static const refresh = 'تحديث';
  static const tryAgain = 'حاول تاني';
  static const yes = 'نعم';
  static const no = 'لا';
  static const yesContinue = 'نعم، كمل';
  static const iUnderstand = 'فهمت';
  static const orContinueWith = 'أو كمل باستخدام';

  // ─── اختيارات ───
  static const selectAnOption = 'اختر من القائمة';
  static const selectTheSuitableOption = 'اختر الخيار المناسب';
  static const pleaseSelectAnOption = 'اختر أحد الخيارات.';
  static const selected = 'مختار';
  static const selectedVariation = 'الاختيار المحدد';
  static const chooseManually = 'اختيار يدوي';
  static const chooseAdditions = 'اختر الإضافات';
  static const chooseAGenderOption = 'اختار النوع';

  // ─── حالات ───
  static const status = 'الحالة';
  static const available = 'متوفر';
  static const cancelled = 'ملغي';
  static const notSet = 'غير محدد';
  static const notSpecified = 'غير محدد';
  static const noChangesToSave = 'مفيش تغييرات نحفظها.';

  // ─── أخطاء عامة ───
  static const noInternetConnection = 'مفيش اتصال بالإنترنت.';
  static const noInternetConnectionLabel = 'مفيش اتصال بالإنترنت.';
  static const connectionProblem = 'في مشكلة في الاتصال';
  static const couldNotContinue = 'مش قادرين نكمّل';
  static const couldNotOpenGallery = 'مش قادرين نفتح المعرض';
  static const couldNotOpenLink = 'تعذر فتح الرابط';
  static const downloadUnavailableHere = 'التحميل مش متاح هنا';
  static const serverError = 'في مشكلة في السيرفر.';
  static const serverErrorLabel = 'في مشكلة في السيرفر.';
  static const pleaseTryAgain = 'حاول تاني.';
  static const tooManyRequestsTryAgainLater =
      'طلبات كتير في وقت قصير. استنى شوية وحاول تاني.';
  static const serviceUnavailable = 'الخدمة غير متوفرة';
  static const noRouteDefinedFor = 'مفيش مسار باسم';
  static const noCountriesFound = 'مفيش دول مطابقة';

  // ─── تحميل ومحتوى ───
  static const loadingContent = 'بنحمّل المحتوى...';
  static const loadingVersion = 'جاري تحميل الإصدار...';
  static const imageSavedSuccessfully = 'تم حفظ الصورة بنجاح';

  // ─── بيانات شخصية ───
  static const personalInformation = 'البيانات الشخصية';
  static const editPersonalDetails = 'عدّل بياناتك الشخصية';
  static const keepDeliveryDetailsFresh = 'حدّث تفاصيل التوصيل';
  static const searchCountryOrCode = 'دور باسم الدولة أو الكود';
  static const selectCountry = 'اختار الدولة';
  static const searchSmarter = 'دور بذكاء';
  static const trendingSearches = 'الأكثر بحثًا';
  static const viewAll = 'عرض الكل';
  static const trackCurrentAndPreviousPurchases =
      'تابع مشترياتك الحالية والسابقة';
  static const keepSearchResultsFamilyFriendly =
      'خلي نتائج البحث مناسبة للعائلة.';
  static const tryAnotherSectionOrChooseAll = 'جرّب قسم تاني أو اختار «الكل».';
  static const searchTheMenu = 'ابحث في القائمة...';

  // ─── نماذج ───
  static const additionalNotesOptional = 'ملاحظات إضافية (اختياري)';
  static const submittingApplication = 'جاري إرسال الطلب...';
  static const submitApplication = 'إرسال الطلب';
  static const applicationSubmitted = 'تم إرسال الطلب';
  static const deliveryConfirmedLater = 'التوصيل: السعر هيتحدد لاحقًا';
  static const spacesAreNotAllowedInThisField =
      'المسافات غير مسموحة في الخانة دي';

  // ─── أكواد التحقق ───
  static const sendCode = 'إرسال الكود';
  static const sendingCode = 'جاري إرسال الكود...';
  static const resendCode = 'إعادة إرسال الكود';
  static const resendIn = 'إعادة الإرسال خلال';
  static const codeAlreadySent = 'الكود اتبعت قبل كده';
  static const couldNotSendCode = 'ما قدرناش نبعت الكود';
  static const pleaseWaitBeforeRequestingAnotherCode =
      'استنى شوية قبل ما تطلب كود جديد.';
  static const resendAvailableIn = 'تقدر تعيد الإرسال بعد';
  static const sending = 'جاري الإرسال...';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String fieldSaved(String field) => 'تم حفظ $field.';
  static String copied(String value) => 'تم نسخ $value';
  static String undefinedRoute(String route) => 'مفيش مسار باسم $route';
  static const pagePrefix = 'صفحة ';
  static const pageSeparator = ' من ';
  static const quantityPrefix = 'الكمية ';
}

/// شاشات الترحيب.
abstract final class OnboardingTexts {
  // ─── شاشات الترحيب ───
  static const onboardingTitle1 = 'كل اللي محتاجه في مكان واحد';
  static const onboardingDesc1 =
      'من البقالة والمنظفات لاحتياجات البيت.. هتلاقي منتجات كتير وتطلبها بسهولة.';
  static const onboardingTitle2 = 'ادفع لما طلبك يوصلك';
  static const onboardingDesc2 =
      'اختار الدفع عند الاستلام، وادفع بكل أمان وراحة أول ما تستلم طلبك.';
  static const onboardingTitle3 = 'توصيل سريع لحد بابك';
  static const onboardingDesc3 =
      'اطلب اللي ناقصك وسيب الباقي علينا.. طلبك هيوصلك بسرعة لحد باب البيت.';
}

/// تسجيل الدخول والحساب والتحقق من البيانات.
abstract final class AuthTexts {
  static const socialLinkTitle = 'ربط حسابك الحالي';
  static const socialLinkDescription =
      'اكتب كلمة سر حسابك في يلا ماركت لربط طريقة تسجيل الدخول دي. بيانات حسابك هتفضل زي ما هي.';
  static const socialLinkAction = 'ربط الحساب';
  // ─── تسجيل الدخول ───
  static const welcomeBack = 'أهلًا برجوعك،';
  static const loginSubtitle = 'أول أونلاين ماركت في التل الكبير';
  static const email = 'الإيميل';
  static const password = 'كلمة السر';
  static const rememberMe = 'افتكرني';
  static const forgetPasswordLink = 'نسيت كلمة السر؟';
  static const signIn = 'تسجيل الدخول';
  static const signInSuccessTitle = 'تم تسجيل الدخول بنجاح';
  static const signInSuccessMessage = 'نورت يلا ماركت من تاني.';
  static const createAccount = 'اعمل حساب جديد';
  static const dontHaveAccount = 'معندكش حساب؟';
  static const signUpAction = 'سجل دلوقتي';
  static const orContinueWith = 'أو كمل باستخدام';
  static const signInCreateAccountTitle = 'اعمل حساب جديد';
  static const signInCredentialsTitle = 'راجع بيانات الدخول';
  static const signInConnectionTitle = 'في مشكلة في الاتصال';
  static const signInFailureTitle = 'تسجيل الدخول ما تمش';

  // ─── إنشاء الحساب ───
  static const createYourAccount = 'يلا نعمل حسابك';
  static const firstName = 'الاسم الأول';
  static const lastName = 'اسم العيلة';
  static const username = 'اسم المستخدم';
  static const phoneNumber = 'رقم الموبايل';
  static const iAgreeTo = 'أنا موافق على ';
  static const privacyPolicy = 'سياسة الخصوصية';
  static const and = ' و ';
  static const termsOfUse = 'شروط الاستخدام';

  // ─── استعادة كلمة السر ───
  static const forgetPasswordTitle = 'نسيت كلمة السر';
  static const forgetPasswordDesc =
      'ولا يهمك. اكتب الإيميل وهنبعت لك لينك آمن تغير منه كلمة السر.';
  static const verifyEmailTitle = 'أكد إيميلك!';
  static const verifyEmailDesc =
      'حسابك جاهز تقريبًا. أكد الإيميل عشان تبدأ التسوق وتوصلك العروض المناسبة.';
  static const passwordResetTitle = 'بعتنا إيميل تغيير كلمة السر';
  static const passwordResetDesc =
      'بعتنا لك لينك آمن تقدر تغير منه كلمة السر وتحافظ على حسابك.';
  static const successTitle = 'تم إنشاء حسابك\nبنجاح!';
  static const successDesc =
      'أهلًا بيك في يلا ماركت. حسابك جاهز لتجربة تسوق سهلة ومريحة.';

  // ─── التحقق من المدخلات ───
  static const fieldRequired = 'الخانة دي مطلوبة';
  static const invalidEmail = 'اكتب إيميل صحيح';
  static const passwordTooShort = 'كلمة السر لازم تكون 8 حروف على الأقل';
  static const passwordTooLong = 'كلمة السر لازم تكون 72 حرف أو أقل.';
  static const passwordWeak =
      'كلمة السر ضعيفة. استخدم حرف كبير وصغير ورقم ورمز.';
  static const passwordMedium =
      'كلمة السر متوسطة. زوّد تنوع الحروف والأرقام عشان تبقى أقوى.';
  static const invalidPhone = 'اكتب رقم موبايل صحيح';

  // ─── تسجيل الدخول والحساب ───
  static const mobilePhoneNumber = 'رقم الهاتف الجوال';
  static const mobileEmailUsername = 'موبايل / إيميل / اسم مستخدم';
  static const enterAValidEmailUsernameOrPhoneNumber =
      'اكتب إيميل أو اسم مستخدم أو رقم موبايل صحيح';
  static const sessionExpired = 'انتهت الجلسة';
  static const accountDisabled = 'تم تعطيل حسابك';
  static const emailNotVerified = 'الإيميل لسه ما اتفعّلش.';
  static const wrongAppCredentials = 'الإيميل أو كلمة السر مش صحيحين.';
  static const invalidSignInCredentials = 'تعذر تسجيل الدخول بهذه البيانات.';
  static const sessionExpiredHint =
      'سجّل دخول تاني عشان تكمل. «افتكرني» بتحافظ على تسجيل دخولك بعد قفل التطبيق.';
  static const signInAgainBeforePlacingAnOrder =
      'سجّل الدخول تاني قبل تأكيد الطلب.';
  static const emailAndPasswordAreRequired = 'اكتب الإيميل وكلمة السر.';
  static const invalidCredentials = 'الإيميل أو كلمة السر مش صحيحين.';
  static const logout = 'تسجيل الخروج';
  static const areYouSureYouWantToLogout = 'متأكد إنك عايز تسجل خروج؟';
  static const couldNotSignYouIn = 'مش قادرين نسجل دخولك.';
  static const couldNotSignYouOut = 'مش قادرين نسجل خروجك.';
  static const aNewSignInWasVerifiedSuccessfully =
      'تم تأكيد تسجيل دخول جديد بنجاح.';
  static const noLocalUserSession = 'مفيش جلسة مستخدم محفوظة.';
  static const couldNotRestoreYourSession = 'مش قادرين نرجّع الجلسة.';
  static const accountAlreadyExists = 'الحساب موجود بالفعل';
  static const accountCreationFailed = 'إنشاء الحساب ما تمش';
  static const accountCreatedSuccessfully = 'تم إنشاء الحساب بنجاح';
  static const couldNotCreateYourAccount = 'مش قادرين نعمل الحساب.';
  static const weWillVerifyItWhileCreatingYourAccount =
      'هنراجعه وإحنا بنعمل الحساب.';
  static const pleaseAgreeToThePrivacyPolicyAndTermsOfUse =
      'لازم توافق على سياسة الخصوصية وشروط الاستخدام قبل إنشاء الحساب.';

  // ─── استعادة الحساب ───
  static const accountRestored = 'تم استعادة حسابك';
  static const yourAccountWasRestoredByTheYallaMarketTeam =
      'تم استعادة الحساب بواسطة فريق دعم يلا ماركت.';
  static const accountRestoredByYallaMarketSupportTeam =
      'تم استعادة الحساب بواسطة فريق دعم يلا ماركت.';
  static const yourAccountHasBeenRestoredYouCanSignInAgain =
      'تم استعادة حسابك. يمكنك تسجيل الدخول مرة أخرى.';
  static const accountPermanentlyDeleted = 'تم حذف حسابك نهائيًا';
  static const yourAccountHasBeenPermanentlyDeletedCreateANewAccount =
      'تم حذف حسابك نهائيًا. أنشئ حسابًا جديدًا للمتابعة.';
  static const yourAccountIsDisabledContactTechnicalSupportOrCreateA =
      'الحساب معطّل. تواصل مع الدعم الفني أو أنشئ حسابًا جديدًا.';

  // ─── البروفايل ───
  static const profile = 'الحساب';
  static const profileInformation = 'بيانات البروفايل';
  static const profilePhotoUpdated = 'صورة البروفايل اتحدّثت';
  static const profileUpdated = 'تم تحديث بيانات الحساب.';
  static const editProfile = 'تعديل البروفايل';
  static const uploadProfilePhoto = 'ارفع صورة البروفايل';
  static const uploadingProfilePhoto = 'جاري رفع صورة الحساب...';
  static const couldNotLoadYourProfile = 'مش قادرين نحمّل البروفايل.';
  static const couldNotRefreshProfile = 'مش قادرين نحدّث بيانات الحساب.';
  static const couldNotUpdateProfile = 'مش قادرين نحدث بيانات الحساب.';
  static const couldNotUpdateProfilePhoto = 'مش قادرين نحدّث صورة الحساب.';
  static const couldNotUpdateProfilePhotoLabel = 'مش قادرين نحدّث صورة الحساب.';
  static const updateYourProfileInformation = 'حدّث بيانات البروفايل';
  static const thisInformationAppearsOnYourProfile =
      'المعلومة دي بتظهر في بروفايلك على يلا ماركت.';
  static const weUseYourAccountDetailsToSecureYourProfileAnd =
      'بنستخدم بيانات حسابك لتأمين البروفايل وتخصيص تجربة التسوق.';

  // ─── إعدادات الحساب ───
  static const accountSettings = 'إعدادات الحساب';
  static const accountSecured = 'الحساب متأمّن';
  static const accountUnavailable = 'الحساب غير متاح';
  static const accountOrdersAndPreferences = 'الحساب والطلبات والتفضيلات';
  static const yourAccountUsesSecureSignInAndControlledDataSharing =
      'حسابك بيستخدم تسجيل دخول آمن وتحكم واضح في مشاركة البيانات.';
  static const keepYourAccountInformationAccurateAndProtectYourPassword =
      'خلي بيانات حسابك دقيقة واحمي كلمة السر.';
  static const weUseYourAccountAndDeliveryInformationOnlyToProvide =
      'بنستخدم بيانات حسابك والتوصيل فقط لتقديم خدمات يلا ماركت وتأمينها وتحسينها.';
  static const useAccurateAccountAndDeliveryDetailsAndKeepYourPassword =
      'استخدم بيانات حساب وتوصيل صحيحة وحافظ على سرية كلمة المرور.';
  static const yourEmailAndPhoneNumberHelpWithVerificationDeliveryUpdates =
      'الإيميل ورقم الموبايل بيساعدوا في التحقق وتحديثات التوصيل واسترجاع الحساب.';
  static const usernameCheckSkipped = 'تخطينا فحص اسم المستخدم';
  static const usernameLocked = 'اسم المستخدم مقفول مؤقتًا';
  static const usernameCanOnlyBeChangedOnceEvery7Days =
      'تقدر تغيّر اسم المستخدم مرة كل 7 أيام بس.';
  static const youCanChangeYourUsernameAgainOn =
      'تقدر تغيّر اسم المستخدم تاني يوم';
  static const afterSavingYouCanChangeYourUsernameAgainAfter7 =
      'بعد الحفظ تقدر تغيّر اسم المستخدم تاني بعد 7 أيام.';
  static const afterSavingANewUsernameYouWillNotBeAble =
      'بعد حفظ اسم مستخدم جديد مش هتقدر تغيّره تاني لمدة 7 أيام.';
  static const changeUsername = 'تغيير اسم المستخدم؟';
  static const changeUsernameLabel = 'تغيير اسم المستخدم';
  static const checkingUsername = 'بنراجع اسم المستخدم...';
  static const couldNotCheckThisUsername = 'مش قادرين نراجع اسم المستخدم ده.';
  static const couldNotCheckUsernameRightNow =
      'مش قادرين نراجع اسم المستخدم دلوقتي.';
  static const thisUsernameIsAlreadyTaken = 'اسم المستخدم ده مستخدم بالفعل';
  static const thisUsernameIsAlreadyTakenLabel =
      'اسم المستخدم ده مستخدم بالفعل.';
  static const usernameIsAvailable = 'اسم المستخدم متاح.';
  static const usernameIsTooLong = 'اسم المستخدم طويل جدًا';
  static const usernameMustBeAtLeast3Characters =
      'اسم المستخدم لازم يكون 3 أحرف على الأقل';
  static const usernameMustIncludeALetter = 'اسم المستخدم لازم يحتوي على حرف';
  static const usernameUnavailable = 'اسم المستخدم غير متاح';
  static const youCanChangeYourUsernameAgainAfter7Days =
      'تقدر تغيّر اسم المستخدم تاني بعد 7 أيام.';
  static const useLettersNumbersDotsAndUnderscoresOnly =
      'استخدم حروف وأرقام ونقط وشرطات سفلية فقط';
  static const useEnglishLettersDotsAndUnderscoresOnly =
      'استخدم حروف إنجليزي ونقطة وشرطة سفلية فقط';
  static const useEnglishLettersNumbersDotsAndUnderscoresOnly =
      'استخدم حروف إنجليزية وأرقام ونقطة وشرطة سفلية بس';
  static const eMail = 'الإيميل';
  static const emailUpdates = 'تنبيهات الإيميل';
  static const changeEmail = 'تغيير الإيميل';
  static const checkingEmail = 'بنراجع الإيميل...';
  static const couldNotCheckThisEmail = 'مش قادرين نراجع الإيميل ده.';
  static const couldNotCheckEmailRightNow = 'مش قادرين نراجع الإيميل دلوقتي.';
  static const emailCheckSkipped = 'تخطينا فحص الإيميل';
  static const emailCheckFailed = 'فحص الإيميل ما تمش';
  static const emailCannotBeChanged = 'تغيير الإيميل مقفول';
  static const contactSupportIfYouNeedHelpWithYourAccountEmail =
      'لو محتاج مساعدة في إيميل الحساب تواصل مع الدعم.';
  static const emailIsAlreadyRegistered = 'الإيميل ده مستخدم بالفعل.';
  static const emailIsAvailable = 'الإيميل متاح.';
  static const emailUnavailable = 'الإيميل غير متاح';
  static const thisEmailIsAlreadyRegistered = 'الإيميل ده مستخدم بالفعل.';
  static const thisEmailIsNotRegistered = 'الإيميل ده مش مسجل.';
  static const emailVerificationIsRequired =
      'حسابك محتاج تأكيد البريد الإلكتروني.';
  static const checkTheEmailAndTryAgain = 'راجع الإيميل وحاول مرة تانية.';

  // ─── الموبايل ───
  static const phone = 'الموبايل';
  static const activationPhone = 'رقم التفعيل';
  static const changePhone = 'تغيير رقم الموبايل';
  static const checkingPhoneNumber = 'بنراجع رقم الموبايل...';
  static const couldNotCheckThisPhoneNumber =
      'مش قادرين نراجع رقم الموبايل ده.';
  static const couldNotCheckPhoneNumberRightNow =
      'مش قادرين نراجع رقم الموبايل دلوقتي.';
  static const phoneCheckSkipped = 'تخطينا فحص رقم الموبايل';
  static const phoneNumberIsAlreadyRegistered =
      'رقم الموبايل ده مستخدم بالفعل.';
  static const phoneNumberIsAvailable = 'رقم الموبايل متاح.';
  static const phoneUnavailable = 'رقم الموبايل غير متاح';
  static const thisPhoneNumberIsAlreadyRegistered =
      'رقم الموبايل ده مستخدم بالفعل.';
  static const thisIsAlreadyYourCurrentPhoneNumber =
      'ده بالفعل رقم موبايلك الحالي.';
  static const enterAValidPhoneNumber = 'اكتب رقم موبايل صحيح';

  // ─── كلمة المرور والتحقق ───
  static const label8Characters = '8 حروف على الأقل';
  static const numberSymbol = 'رقم ورمز خاص';
  static const upperLowercase = 'حرف كبير وصغير';
  static const passwordRequired = 'كلمة السر مطلوبة';
  static const passwordIsRequired = 'كلمة السر مطلوبة.';
  static const enterYourPasswordFirst = 'اكتب كلمة السر الأول.';
  static const passwordsDoNotMatch = 'كلمتا السر مش متطابقتين.';
  static const weakPassword = 'كلمة سر ضعيفة';
  static const mediumPassword = 'كلمة سر متوسطة';
  static const strongPassword = 'كلمة سر قوية';
  static const thePasswordIsIncorrect = 'كلمة السر غير صحيحة.';
  static const invalidPassword = 'كلمة السر مش صحيحة.';
  static const invalidPasswordLabel = 'كلمة السر مش صحيحة.';
  static const newPasswordMustBeDifferentFromYourCurrentPassword =
      'كلمة السر الجديدة لازم تكون مختلفة عن كلمة السر الحالية.';
  static const newPasswordMustBeDifferentFromYourCurrentPasswordLabel =
      'كلمة السر الجديدة لازم تكون مختلفة عن كلمة السر الحالية.';
  static const forgetPassword = 'نسيت كلمة السر؟';

  // ─── أمان الحساب ───
  static const accountSecurity = 'أمان الحساب';
  static const changePassword = 'تغيير كلمة المرور';
  static const verifyYourEmailToSetANewPassword =
      'أكد بريدك الإلكتروني عشان تعين كلمة مرور جديدة';
  static const verificationCodeSent = 'تم إرسال كود التحقق';
  static const verificationCode = 'كود التحقق';
  static const enterThe6DigitVerificationCode =
      'اكتب كود التحقق المكوّن من 6 أرقام.';
  static const newPassword = 'كلمة المرور الجديدة';
  static const confirmNewPassword = 'تأكيد كلمة المرور الجديدة';
  static const passwordChanged = 'تم تغيير كلمة المرور';
  static const yourPasswordWasChangedSuccessfullySignInAgainToContinue =
      'تم تغيير كلمة المرور بنجاح. سجل دخول من جديد عشان تكمل.';
  static const couldNotSendVerificationCode = 'مش قادرين نبعت كود التحقق.';
  static const couldNotChangePassword = 'مش قادرين نغير كلمة المرور.';
  static const invalidVerificationCode = 'كود التحقق غلط أو انتهت صلاحيته.';
  static const invalidVerificationCodeLabel =
      'كود التحقق غلط أو انتهت صلاحيته.';
  static const invalidOrExpiredVerificationCode =
      'كود التحقق غلط أو انتهت صلاحيته.';
  static const invalidOrExpiredVerificationCodeLabel =
      'كود التحقق غلط أو انتهت صلاحيته.';
  static const theVerificationCodeHasExpired =
      'كود التحقق غلط أو انتهت صلاحيته.';
  static const noActiveVerificationCodeWasFound =
      'كود التحقق غلط أو انتهت صلاحيته.';
  static const twoStepVerification = 'التحقق بخطوتين';
  static const accountDeletionNowRequiresYourAccountPasswordForConfirmation =
      'حذف الحساب محتاج كلمة السر للتأكيد.';
  static const youCanUseTheCodeAlreadySentToYourEmail =
      'تقدر تستخدم الكود اللي اتبعت على بريدك.';
  static const youCanUseTheCodeAlreadySentToYourEmailLabel =
      'تقدر تستخدم الكود اللي اتبعت على بريدك، وتطلب كود جديد لما العداد يخلص.';

  // ─── حذف الحساب ───
  static const deleteAccount = 'حذف الحساب';
  static const deleteAccountPermanently = 'تحذف الحساب نهائي؟';
  static const accountWasNotDeleted = 'الحساب ما اتحذفش';
  static const couldNotDeleteYourAccount = 'مش قادرين نحذف الحساب.';
  static const permanentlyRemoveYourProfile =
      'احذف بروفايلك من يلا ماركت نهائيًا';
  static const permanentlyRemoveYourYallaMarketProfile =
      'احذف بروفايلك على يلا ماركت نهائيًا';
  static const permanentlyRemoveYourProfileAndPersonalData =
      'احذف ملفك الشخصي وبياناتك نهائيًا';
  static const thisCannotBeUndoneEnterYourAccountPasswordToConfirm =
      'الإجراء ده نهائي. اكتب كلمة سر الحساب لتأكيد الحذف.';
  static const deletingYourAccountRemovesYourProfileSavedAddressesCartReviews =
      'حذف الحساب هيشيل البروفايل والعناوين والسلة والمراجعات وسجل الطلبات. الإجراء ده نهائي.';
  static const finishOrCancelAnyActiveOrdersFirst =
      'خلّص أو الغي أي طلبات نشطة الأول.';
  static const reviewActiveRefundsBeforeDeleting =
      'راجع أي مستردات نشطة قبل الحذف.';

  // ─── الإشعارات والتحديثات (حساب) ───
  static const ordersDealsAndAccountUpdates = 'طلبات وعروض وتحديثات الحساب';
  static const orderOfferAndAccountUpdatesWillAppearHere =
      'تحديثات الطلبات والعروض والحساب هتظهر هنا.';
  static const offersOrderUpdatesAndAccountAlerts =
      'العروض وتحديثات الطلب وتنبيهات الحساب';
  static const dealsOrderUpdatesAndAccountAlerts =
      'عروض وتحديثات طلب وتنبيهات حساب.';
  static const misuseOfOffersAccountsOrPaymentMethodsMayLimitAccess =
      'إساءة استخدام العروض أو الحسابات أو طرق الدفع ممكن تحد من الوصول للتطبيق.';
  static const supportOrdersAndAccountHelp = 'دعم للطلبات والحساب';
  static const quickerHelpWithOrdersReturnsAndAccountIssues =
      'مساعدة أسرع في الطلبات والمرتجعات ومشاكل الحساب.';
  static const stayCloseToOrdersOffersAndAccountActivity =
      'تابع الطلبات والعروض ونشاط الحساب.';
  static const receiveAccountAndPrivacyAlerts =
      'استقبل تنبيهات الحساب والخصوصية.';
  static const openMyOrdersFromTheAccountPageToSeeThe =
      'افتح طلباتي من صفحة الحساب لمتابعة حالة الطلب وتحديثات التوصيل.';
  static const useTheWhatsAppButtonOnTheAccountPageForDirect =
      'استخدم زر واتساب في صفحة الحساب للتواصل المباشر.';

  // عبارات إضافية
  static const use8CharactersWithUppercaseLowercaseNumberAndSymbol =
      'استخدم 8 أحرف أو أكتر مع حرف كبير وصغير ورقم ورمز.';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String usernameChangeDate(String date) =>
      'تقدر تغيّر اسم المستخدم تاني في $date.';
}

/// اختيار اللغة.
abstract final class LanguageTexts {
  static const languageTooltip = 'غيّر اللغة';
}

/// المنطقة والمدينة والموقع.
abstract final class RegionTexts {
  // ─── اختيار المنطقة ───
  static const changeYourRegion = 'تغيير المنطقة';
  static const youCanChangeYourRegionHereAnytimeToSeeProducts =
      'تقدر تغيّر المنطقة من هنا في أي وقت وتشوف المنتجات والعروض المناسبة ليها.';
  static const outsideTheDeliveryAreaAdjustTheLocation =
      'خارج منطقة التوصيل، قم بتعديل الموقع';
  static const yourCurrentLocationIsOutsideTheDeliveryArea =
      'موقعك الحالي خارج منطقة التوصيل';
  static const searchForAPlaceInEgypt = 'ابحث عن مكان داخل مصر';
  static const browsingRegion = 'منطقة التصفح';
  static const changeRegion = 'تغيير المنطقة';
  static const changeRegionManually = 'غيّر المنطقة يدويًا';
  static const chooseYourCurrentCityOrTheNearestOne =
      'اختر مدينتك الحالية أو أقربهم لك';
  static const chooseYourCurrentCityOrTheNearestOneLabel =
      'اختر مدينتك الحالية أو أقربهم لك.';
  static const ifYourCityIsNotAvailableChooseOther =
      'فى حاله عدم تواجد مدينتك تقدر تختار جاهز للشحن ونشحنلك المنتج المطلوب بكل سهوله';
  static const chooseManuallyOrLetGpsDetectYourArea =
      'اختار منطقتك يدويًا أو خلّي GPS يحاول يحددها تلقائيًا.';
  static const chooseTheBrowsingRegionUsedForProducts =
      'اختار المنطقة اللي هنعرض منتجاتها';
  static const generalBrowsing = 'تصفح المنتجات الجاهزة للشحن';
  static const generalRegionSaved = 'تم حفظ اختيار جاهز للشحن';
  static const productsAndOffersWillRefreshForYourRegion =
      'المنتجات والعروض هتتحدّث حسب منطقتك.';
  static const productsThatFitYourRegion = 'منتجات مناسبة لمنطقتك';
  static const productsWillRefreshForYourSelectedRegion =
      'المنتجات هتتحدث حسب المنطقة المختارة.';
  static const region = 'المنطقة';
  static const regionNotChanged = 'المنطقة ما اتغيرتش';
  static const regionSaved = 'تم حفظ المنطقة';
  static const couldNotUpdateYourRegionYourCartWasNotChanged =
      'مش قادرين نحدّث منطقتك، والسلة ما اتغيرتش.';
  static const theRegionWasChangedButTheCartCouldNotBe =
      'المنطقة اتغيرت، لكن مش قادرين نمسح السلة.';
  static const notAvailableInTheCurrentRegion = 'غير متاح في المنطقة الحالية';
  static const thisOfferIsNotAvailableInYourCityRightNow =
      'هذا العرض غير متاح في مدينتك حاليًا.';
  static const youAreNowInASupportedRegionSwitchToSee =
      'أنت دلوقتي في منطقة مدعومة. بدّل المنطقة عشان تشوف عروضها، والسلة هتتراجع عند الدفع.';

  // ─── GPS والموقع ───
  static const locationAccessIsRequiredBeforeChoosingAnAddress =
      'لازم تفعّل الموقع قبل اختيار العنوان.';
  static const openLocationSettings = 'افتح إعدادات الموقع';
  static const gpsAccessIsRequiredToOpenTheMap =
      'لازم تفعّل GPS علشان تفتح الخريطة.';
  static const gpsCanTryToDetectYourAreaAutomatically =
      'GPS هيحاول يحدد منطقتك تلقائيًا، ولو ما ظبطش تقدر تختار يدويًا.';
  static const locationAccessIsRequired = 'مطلوب السماح بالموقع';
  static const chooseYourAreaManuallyAndYouCanTryGpsAgain =
      'اختار منطقتك يدويًا، وتقدر تجرب GPS تاني بعدين.';
  static const detectingLocation = 'بنحدد موقعك...';
  static const detectingYourLocation = 'بنحدد موقعك...';
  static const enableGpsAndContinue = 'فعّل الموقع وكمل';
  static const gpsHelpsYallaMarketShowNearbyProductsLocalOffersBetter =
      'الموقع بيساعد يلا ماركت يعرض منتجات قريبة، عروض محلية، اقتراحات توصيل أفضل، وتسعير توصيل أدق بعدين.';
  static const ifYourAreaIsNotHereAddItManually =
      'لو منطقتك مش موجودة، ضيفها يدويًا';
  static const locationPermissionWasNotGrantedAllowLocationToContinue =
      'صلاحية الموقع غير مفعلة. اسمح بالموقع عشان تكمل.';
  static const locationServicesAreDisabledTurnOnGpsToContinue =
      'خدمات الموقع مقفولة. فعّل GPS عشان تكمل.';
  static const turnOnGpsAndAllowLocationAccessBeforeEnteringThe =
      'فعّل GPS واسمح بالوصول للموقع قبل ما تدخل التطبيق.';
  static const locationSettings = 'إعدادات الموقع';
  static const useGpsLocation = 'استخدم موقع GPS';
  static const isThisYourGovernorate = 'هل دي محافظتك؟';
  static const isThisYourCity = 'هل دي مدينتك؟';
  static const weDetectedYourCity = 'حددنا مدينتك';
  static const weDetectedYourGovernorate = 'حددنا محافظتك';
  static const weCouldNotDetectASupportedGovernorateChooseOneManually =
      'مقدرناش نحدد محافظة مدعومة. اختار محافظتك يدويًا.';

  // ─── المدينة ───
  static const chooseCity = 'اختار المدينة';
  static const chooseTheCityUsedForAvailableProducts =
      'اختار المدينة اللي هنعرض منتجاتها';
  static const chooseYourCity = 'اختر مدينتك';
  static const city = 'المدينة';
  static const citySaved = 'تم حفظ المدينة';
  static const cityNameIsRequired = 'اسم المدينة مطلوب';
  static const cityName = 'المدينة: {name}';
  static const deliveryCity = 'مدينة التوصيل';
  static const enterYourCity = 'اكتب المدينة';
  static const locationPermissionWasNotGrantedChooseYourCityManually =
      'صلاحية الموقع مرفوضة. اختار مدينتك يدويًا.';
  static const locationServicesAreDisabledChooseYourCityManually =
      'خدمات الموقع مقفولة. اختار مدينتك يدويًا.';
  static const productsWillRefreshForYourSelectedCity =
      'هنحدث المنتجات حسب المدينة المختارة.';
  static const saveCity = 'حفظ المدينة';
  static const soWeCanShowProductsAvailableInYourArea =
      'علشان نعرض لك المنتجات المتاحة في منطقتك.';
  static const soWeCanShowShopsAvailableInYourArea =
      'علشان نعرض لك المحلات المتاحة في منطقتك.';
  static const weCouldNotDetectASupportedCityChooseOneManually =
      'مش قادرين نحدد مدينة مدعومة. اختار مدينة يدويًا.';
  static const otherCity = 'مدينة أخرى';

  // ─── منطقة التوصيل ───
  static const chooseADeliveryArea = 'اختار منطقة التوصيل';
  static const chooseADeliveryAreaLabel = 'اختار منطقة التوصيل.';
  static const chooseADeliveryAreaToSeeThePrice =
      'اختار منطقة التوصيل عشان تشوف السعر';
  static const deliveryArea = 'منطقة التوصيل';
  static const directAreaDelivery = 'توصيل مباشر داخل المنطقة';
  static const enterYourAreaName = 'اكتب اسم منطقتك';
  static const myAreaIsNotListed = 'منطقتي مش موجودة';
  static const yourCityIsOutsideTheCurrentServiceCitiesEnterYour =
      'مدينتك مش ضمن مدن الخدمة الحالية. اكتب مدينتك ومنطقتك يدويًا.';
  static const area = 'المنطقة';

  // ─── أسماء المناطق والدول ───
  static const alexandria = 'الإسكندرية';
  static const cairo = 'القاهرة';
  static const egypt = 'مصر';
  static const egyptianPound = 'جنيه';
  static const nasrCity = 'مدينة نصر';
  static const newCairo = 'القاهرة الجديدة';
  static const downtownCairo = 'وسط البلد';
  static const enterAValidEgyptianMobileNumberStartingWith011 =
      'اكتب رقم موبايل مصري صحيح يبدأ بـ 01 أو 1 أو 201 أو +201.';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static const outsideServiceAreaTitle = 'أنت خارج مناطق الخدمة';
  static const locationChangedTitle = 'تم اكتشاف تغيير في موقعك';
  static const outsideServiceAreaMessage =
      'يبدو أنك خارج مدن الخدمة الحالية. هل تريد التبديل إلى جاهز للشحن؟';
  static String locationChangedMessage(
    String currentRegion,
    String detectedRegion,
  ) =>
      'منطقتك الحالية هي $currentRegion، ويبدو أنك الآن في $detectedRegion. هل تريد تغيير المنطقة؟';
  static String keepCurrentRegion(String region) => 'البقاء في $region';
  static String changeToRegion(String region) => 'التغيير إلى $region';
  static const currentRegionFallback = 'منطقتك الحالية';
  static const cartClearedRegionWarning =
      'سيؤدي تغيير المنطقة إلى تفريغ السلة.';
}

/// العناوين والخريطة والشحن.
abstract final class AddressTexts {
  // ─── إدارة العناوين ───
  static const deliveryAddress = 'عنوان التوصيل';
  static const newAddress = 'عنوان جديد';
  static const saveAddress = 'حفظ العنوان';
  static const addNewAddress = 'ضيف عنوان جديد';
  static const addAddress = 'إضافة عنوان';
  static const addAnAddressToStartCheckoutFaster =
      'ضيف عنوان عشان تكمّل الدفع أسرع.';
  static const addressDeleted = 'تم حذف العنوان';
  static const addressSaved = 'العنوان اتحفظ';
  static const addressUpdated = 'العنوان اتحدّث';
  static const addressUpdateFailed = 'تعذر تحديث العنوان';
  static const addressName = 'اسم العنوان';
  static const addressDetails = 'تفاصيل العنوان';
  static const addressLabelOptional = 'تسمية العنوان (اختياري)';
  static const addressRequired = 'محتاجين عنوانك';
  static const addresses = 'العناوين';
  static const chooseASavedAddress = 'اختار عنوان محفوظ';
  static const completeAddressDetailsHelpCheckoutAndDeliveryMoveFaster =
      'تفاصيل العنوان الكاملة بتخلي الدفع والتوصيل أسرع.';
  static const couldNotUpdateAddresses = 'مش قادرين نحدّث العناوين.';
  static const deleteAddress = 'تحذف العنوان؟';
  static const deliveryAddressNeeded = 'مطلوب تحديد عنوان التوصيل';
  static const deliveryIsNoLongerAvailableForThisAddress =
      'التوصيل لم يعد متاحًا لهذا العنوان';
  static const editAddress = 'تعديل العنوان';
  static const myAddresses = 'عناويني';
  static const reviewAddress = 'مراجعة العنوان';
  static const selectAddress = 'اختار العنوان';
  static const setShoppingDeliveryAddress = 'حدد عنوان توصيل الطلبات';
  static const homeWorkOtherAddress = 'البيت، الشغل، أو عنوان تاني';
  static const streetBuildingFloorLandmark =
      'الشارع، العمارة، الدور، وعلامة مميزة';
  static const removeNameFromYourSavedDeliveryLocations =
      'تحذف {name} من عناوين التوصيل المحفوظة؟';
  static const saveADeliveryLocation = 'احفظ مكان التوصيل';
  static const updateThisDeliveryLocation = 'حدّث بيانات مكان التوصيل';
  static const storesWillAppearHereWhenTheyCoverYourAddress =
      'المحلات هتظهر هنا لما التوصيل يبقى متاح لعنوانك.';
  static const thisStoreIsNotAvailableForYourCurrentAddress =
      'المحل ده مش متاح لعنوانك الحالي.';
  static const yourPackageIsOnTheWayToYourAddress = 'الشحنة في الطريق لعنوانك.';

  // ─── تفاصيل العنوان ───
  static const apartment = 'شقة';
  static const house = 'منزل';
  static const office = 'مكتب';
  static const buildingName = 'اسم المبنى';
  static const apartmentNumber = 'رقم الشقة';
  static const floor = 'الطابق';
  static const floorOptional = 'الطابق (اختياري)';
  static const houseName = 'اسم المنزل';
  static const company = 'الشركة';
  static const familyHome = 'منزل العائلة';
  static const street = 'الشارع';
  static const nameThisAddressSoYouCanIdentifyItEasily =
      'قم بتسمية هذا العنوان لتتمكن من اختياره بسهولة.';

  // ─── الخريطة والموقع ───
  static const confirmDeliveryLocation = 'تأكيد موقع التوصيل';
  static const continueWithThisLocation = 'كمّل بالموقع ده';
  static const yourOrderWillBeDeliveredToThisLocation =
      'سيتم توصيل طلبك إلى هذا المكان';
  static const placeSearchFailed = 'تعذر البحث عن المكان.';
  static const addressLookupFailedYouCanStillContinue =
      'تعذر معرفة العنوان، وتقدر تكمل بالإحداثيات.';
  static const findingTheAddress = 'جاري معرفة العنوان...';
  static const couldNotFindYourCurrentLocationTryAgain =
      'تعذر تحديد موقعك الحالي. حاول مرة تانية.';
  static const mapLocationSelected = 'تم تحديد الموقع على الخريطة';
  static const chooseLocationOnMap = 'حدد الموقع على الخريطة';
  static const yourCurrentLocationIsSelectedMoveTheMapToAdjust =
      'موقعك الحالي متحدد. حرّك الخريطة لو محتاج تعدّله.';
  static const locationSelectedManually = 'تم تحديد الموقع يدويًا.';
  static const currentLocationIsUnavailableMoveTheMapToChooseIt =
      'تعذر تحديد موقعك الحالي. حرّك الخريطة وحدده يدويًا.';
  static const automaticLocation = 'تحديد تلقائي';
  static const locationIsTakingTooLong = 'تحديد الموقع أخد وقت طويل';
  static const enableYourLocation = 'فعّل موقعك';
  static const useMyCurrentLocation = 'استخدم موقعي الحالي';
  static const editLocation = 'تعديل الموقع';
  static const couldNotUseYourCurrentLocation =
      'مش قادرين نستخدم موقعك الحالي.';
  static const couldNotFindYourCurrentLocationChooseOneManually =
      'مش قادرين نحدد موقعك الحالي. اختار المنطقة يدويًا.';

  // ─── الشحن ───
  static const shippingAddress = 'عنوان الشحن';
  static const shippingCompany = 'شركة الشحن';
  static const shippingCompanyRequired = 'شركة الشحن مطلوبة';
  static const chooseAShippingCompanyBeforeCompletingTheOrder =
      'اختر شركة الشحن قبل إتمام الطلب.';
  static const shippingAddressRequired = 'عنوان الشحن مطلوب';
  static const completeTheDeliveryAddressFirst =
      'أكمل بيانات عنوان التوصيل أولًا.';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String savedLocations(int count) => '$count عنوان محفوظ';
  static String removeLocation(String name) =>
      'تحذف $name من عناوين التوصيل المحفوظة؟';
  static String selectedForCheckout(String name) => '$name محدد للدفع.';
}

/// المتاجر والمنتجات والبحث.
abstract final class StoreTexts {
  // ─── المتاجر ───
  static const store = 'المتجر';
  static const shop = 'متجر';
  static const market = 'المتجر';
  static const markets = 'الأسواق';
  static const popularStores = 'المحلات الشائعة';
  static const latestStores = 'أحدث المحلات';
  static const browseAllPopularStores = 'تصفح كل المحلات الشائعة';
  static const popularStoresWillAppearHereOnceAvailable =
      'المحلات الشائعة هتظهر هنا أول ما تبقى متاحة.';
  static const loadingStore = 'بنجهزلك المتجر...';
  static const loadingStores = 'جاري تحميل المحلات...';
  static const storeCouldNotLoad = 'المتجر محمّلش';
  static const storeUnavailable = 'المحل غير متاح';
  static const noStoresAvailable = 'مفيش محلات متاحة دلوقتي';
  static const noStoresFound = 'مفيش محلات مطابقة';
  static const noStoreCategories = 'مفيش أقسام في المتجر';
  static const browseTheNewestStores = 'اتصفح أحدث المحلات';
  static const newStoresWillAppearHereOnceAdded =
      'المحلات الجديدة هتظهر هنا أول ما تتضاف.';
  static const categoriesWillAppearHereOnceStoresAreAvailable =
      'الأقسام هتظهر هنا أول ما المحلات تبقى متاحة.';
  static const productsWillAppearHereOnceThisStoreIsReady =
      'المنتجات هتظهر هنا أول ما المحل يجهزها.';
  static const tryADifferentStoreName = 'جرّب اسم محل تاني.';
  static const searchStores = 'دور على محل...';
  static const tSStore = 'متجر T';
  static const marketBreakdown = 'تفاصيل المتاجر';
  static const yallaMarket = 'يلا ماركت';

  // ─── المنتجات ───
  static const products = 'المنتجات';
  static const items = 'المنتجات';
  static const popularProducts = 'المنتجات الشائعة';
  static const latestProducts = 'أحدث المنتجات';
  static const loadingProducts = 'جاري تحميل المنتجات...';
  static const productsCouldNotLoad = 'المنتجات ما اتحملتش';
  static const noProductsAvailable = 'مفيش منتجات متاحة';
  static const noProductsFound = 'مفيش منتجات';
  static const noProductsInThisSection = 'لسه مفيش منتجات في القسم ده';
  static const productIsOutOfStock = 'المنتج خلص من المخزون';
  static const inStock = 'متوفر';
  static const outOfStock = 'غير متوفر';
  static const stock = 'المخزون';
  static const price = 'السعر';
  static const egpPrice = '{price} ج.م';
  static const itemAdded = 'اتضاف';
  static const itemRemoved = 'اتشال';
  static const minimumQuantityIs1 = 'أقل كمية هي 1';
  static const noItemsToReview = 'مفيش منتجات للمراجعة';
  static const selectQuantityFirst = 'اختار الكمية الأول';
  static const browseTheLatestProducts = 'تصفح أحدث المنتجات';
  static const browseAllCuratedProducts = 'تصفح كل المنتجات المختارة';
  static const productsWillAppearHereOnceTheCatalogIsReady =
      'المنتجات هتظهر هنا أول ما الكتالوج يجهز.';
  static const tryAnotherProductName = 'جرّب اسم منتج آخر.';
  static const searchProducts = 'دور على منتج...';
  static const exploreProducts = 'استكشف المنتجات';
  static const startShopping = 'ابدأ التسوق';
  static const continueShopping = 'كمّل التسوق';
  static const hideAgeRestrictedProducts = 'إخفاء المنتجات المقيّدة حسب العمر';

  // ─── العروض ───
  static const offers = 'العروض';
  static const nearbyOffers = 'عروض قريبة';
  static const packageOffer = 'عرض باكدج';
  static const offerPrice = 'سعر العرض';
  static const personalizedOffers = 'عروض مخصصة';
  static const curatedPicksAndBrandDeals = 'اختيارات مخصوصة وعروض براندات';
  static const curatedPicksAndCategoryDeals = 'اختيارات مخصوصة وعروض فئات';
  static const sendThisProductOrCopyItsLink = 'ابعت المنتج لحد أو انسخ رابطه.';
  static const copyProductLink = 'نسخ رابط المنتج';
  static const sendThisOfferOrCopyItsLink = 'ابعت العرض لحد أو انسخ رابطه.';

  // ─── البراندات ───
  static const brands = 'البراندات';
  static const brandsPicks = 'براندات واختيارات';
  static const featuredBrands = 'براندات مميزة';
  static const allBrands = 'كل البراندات';
  static const thisBrandCatalogIsEmptyTryAnotherBrandOrCheck =
      'كتالوج البراند ده فاضي. جرّب براند تاني أو ارجع لاحقًا.';

  // ─── الأقسام والفئات ───
  static const categories = 'الأقسام';
  static const allCategories = 'كل الفئات';
  static const categoriesPicks = 'أقسام واختيارات ليك';
  static const featuredCategories = 'فئات مميزة';
  static const popularCategories = 'الفئات الشائعة';
  static const marketSections = 'أقسام الأسواق';
  static const exploreMarketCategories = 'استكشف فئات السوق';
  static const exploreTrustedStores = 'استكشف متاجر موثوقة';
  static const productsAndCategories = 'منتجات وفئات';
  static const productsShopsAndCategories = 'منتجات ومحلات وفئات';
  static const searchShops = 'المحلات';
  static const searchCategories = 'الفئات';
  static const searchProductsShopsAndCategories =
      'دور على منتجات أو محلات أو فئات...';
  static const tryAProductShopOrCategoryName = 'جرّب اسم منتج أو محل أو فئة.';
  static const loadMoreProducts = 'عرض منتجات أكتر';
  static const pleaseLoginToSearch = 'سجّل دخولك عشان تبحث';
  static const productsBrandsAndCategories = 'منتجات وبراندات وأقسام';
  static const thisCategoryIsEmptyTryAnotherCategoryOrCheckBack =
      'الفئة دي فاضية. جرّب فئة تانية أو ارجع لاحقًا.';

  // ─── البحث والفلتر ───
  static const filterProducts = 'فلتر المنتجات...';
  static const sortBy = 'رتّب حسب';
  static const sortProducts = 'ترتيب المنتجات';
  static const higherPrice = 'الأعلى سعرًا';
  static const lowerPrice = 'الأقل سعرًا';
  static const searchBrandsProducts = 'دور على براندات ومنتجات...';
  static const searchProductsBrands = 'دور على منتجات أو براندات...';
  static const searchProductsBrandsCategories =
      'دور على منتج أو براند أو قسم...';
  static const searchCategoriesProducts = 'دور على فئات ومنتجات...';
  static const searchProductsAndCategories = 'دور على منتجات أو فئات...';
  static const tryABrandCategoryOrAShorterProductName =
      'جرّب براند أو قسم أو اسم منتج أقصر.';
  static const tryACategoryOrAShorterProductName = 'جرّب فئة أو اسم منتج أقصر.';
  static const tryProductNamesBrandsCategoriesOrSaleKeywords =
      'جرّب أسماء المنتجات أو البراندات أو الأقسام أو كلمات العروض.';
  static const tryProductNamesCategoriesOrSaleKeywords =
      'جرّب أسماء منتجات أو فئات أو كلمات للعروض.';
  static const tryAnotherSearchCategoryOrSortingOption =
      'جرّب بحث تاني أو فئة أو طريقة ترتيب مختلفة.';
  static const tryItFromTheWebPreview = 'جرّبه من معاينة الويب.';

  // ─── معلومات المتجر ───
  static const savedProductsAndStores = 'المنتجات والمحلات المحفوظة';
  static const generalProductsAndOffersWillBeShown =
      'هيتم عرض المنتجات والعروض الجاهزة للشحن.';
  static const youWillSeeGeneralProductsAndOffers =
      'هتشوف المنتجات والعروض الجاهزة للشحن.';
  static const fixedPriceDelivery = 'توصيل بسعر ثابت';
  static const deliveryPriceDeterminedLater = 'دليفري - السعر يتحدد لاحقًا';
  static const deliveryEgpPrice = 'التوصيل: {price} ج.م';
  static const yallaMarketMakesShoppingFromLocalMarketsSimpleAndFast =
      'يلا ماركت بيخلي التسوق من الأسواق المحلية أسهل وأسرع.';
  static const simpleShoppingFromTrustedLocalMarkets =
      'تسوق أسهل من أسواق محلية موثوقة.';
  static const usingYallaMarket = 'استخدام يلا ماركت';
  static const localPricesAndDelivery = 'أسعار وتوصيل داخل مصر';
  static const shoppingSetup = 'إعدادات التسوق';
  static const pendingReview = 'في انتظار المراجعة';
  static const review = 'المراجعة';
  static const previewSalesBeforeTheyGoLive = 'شوف العروض قبل ما تبدأ للجميع.';
  static const useShoppingActivityForBetterDeals =
      'استخدم نشاط التسوق عشان عروض أفضل.';
  static const yourItemWillBeShippedSoon = 'طلبك هيتشحن قريب!';
  static const ratingsAndReviewsAreVerifiedAndAreFromPeopleWho =
      'التقييمات والمراجعات موثقة ومن ناس بيستخدموا نفس نوع الجهاز.';
  static const saveTheProductsYouLoveAndFindThemHereWhenever =
      'احفظ المنتجات اللي بتحبها وهتلاقيها هنا وقت ما تحتاجها.';
  static const tuneShoppingAlertsAndDataUsage =
      'ظبط التسوق والتنبيهات واستخدام البيانات';
  static const freshPicksAreAvailableInTheMostRequestedCategories =
      'اختيارات جديدة متاحة في أكتر الفئات طلبًا.';

  // ─── الدول (في سياق المتجر) ───
  static const unitedArabEmirates = 'الإمارات';
  static const unitedKingdom = 'المملكة المتحدة';
  static const unitedStates = 'الولايات المتحدة';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String productsForBrand(String brand) => 'اعرض منتجات $brand';
  static String productCountLabel(String count) => '$count منتج';
  static String productCount(int count) => '$count منتج';
  static String storeCount(String count) => '$count محل';
  static String marketCount(String count) => '$count سوق';
  static String offerCount(String count) => '$count عرض';
  static String searchResults(int count, String query) =>
      '$count نتيجة لـ "$query"';
  static String noBrandProducts(String brand) => 'لسه مفيش منتجات من $brand';
  static String noCategoryItems(String category) =>
      'لسه مفيش عناصر في $category';
  static String noSearchResults(String query) => 'مفيش نتائج لـ "$query"';
}

/// الطلبات والسلة والدفع.
abstract final class OrderTexts {
  // ─── السلة ───
  static const cart = 'السلة';
  static const myCart = 'سلتي';
  static const yourCartIsEmpty = 'السلة فاضية';
  static const addToCart = 'إضافة للسلة';
  static const addItemsToYourCartBeforeCheckout =
      'ضيف منتجات للسلة قبل ما تكمل الدفع.';
  static const addProductsYouLikeAndReviewThemHereBeforeCheckout =
      'ضيف المنتجات اللي عجبتك وراجعها هنا قبل الدفع.';
  static const addRemoveProductsAndMoveToCheckout =
      'ضيف واحذف المنتجات وكمل للدفع';
  static const productAddedToCart = 'المنتج اتضاف للسلة';
  static const itemRemovedFromCart = 'اتشال من السلة';
  static const thisProductCannotBeAddedToCartRightNow =
      'لا يمكن إضافة المنتج للسلة حاليًا.';
  static const yourCartWasClearedAndContentWasRefreshed =
      'السلة اتمسحت والمحتوى اتحدّث.';

  // ─── الدفع ───
  static const checkout = 'الدفع';
  static const checkoutFailed = 'الدفع ما تمش';
  static const confirmOrder = 'تأكيد الطلب';
  static const confirmItemsAndPayment = 'راجع المنتجات ووسيلة الدفع';
  static const confirmingYourOrder = 'جاري تأكيد طلبك';
  static const processingYourOrder = 'بنجهز طلبك';
  static const pleaseWaitWhileWeSaveYourOrderDetails =
      'من فضلك انتظر لحظات حتى نؤكد تفاصيل طلبك.';
  static const paymentMethod = 'وسيلة الدفع';
  static const selectPaymentMethod = 'اختار وسيلة الدفع';
  static const paymentSuccess = 'تم الدفع بنجاح!';
  static const cashOnDelivery = 'الدفع عند الاستلام';
  static const payWhenYourOrderArrives = 'ادفع لما طلبك يوصل';
  static const payCash = 'ادفع كاش';
  static const payCashOnline = 'ادفع كاش وأونلاين';
  static const paymentAndSensitiveDataShouldOnlyBeEnteredOnTrusted =
      'بيانات الدفع والبيانات الحساسة تتكتب بس في شاشات الدفع الموثوقة.';
  static const chooseWhereOrdersShouldArrive = 'اختار الطلبات توصل فين';

  // ─── الطلبات ───
  static const orders = 'الطلبات';
  static const myOrders = 'طلباتي';
  static const orderSummary = 'ملخص الطلب';
  static const orderReview = 'مراجعة الطلب';
  static const orderTotal = 'إجمالي الطلب';
  static const orderTotalLabel = 'إجمالي الطلب';
  static const orderConfirmed = 'تم تأكيد الطلب';
  static const orderConfirmedSuccessfully = 'تم تأكيد طلبك بنجاح!';
  static const orderConfirmationFailed = 'تعذر تأكيد الطلب';
  static const orderDate = 'تاريخ الطلب';
  static const orderRejected = 'تم رفض الطلب';
  static const yourOrderOrderIdWasRejected = 'تم رفض طلبك رقم #{orderId}.';
  static const newOrderAssigned = 'تم تعيين طلب جديد';
  static const aNewOrderOrderIdHasBeenAssignedToYou =
      'تم تعيين طلب جديد رقم #{orderId} ليك.';
  static const newOrderRequiresReview = 'طلب جديد محتاج مراجعة';
  static const orderOrderIdRequiresAdminReview =
      'الطلب رقم #{orderId} محتاج مراجعة الإدارة.';
  static const orderTrackingVisibility = 'إظهار تتبع الطلب';
  static const ordersCouldNotLoad = 'مش قادرين نحمّل الطلبات';
  static const loadingOrders = 'بنحمّل الطلبات...';
  static const noOrdersInThisPeriod = 'مفيش طلبات في الفترة دي';
  static const inProgressAndCompletedOrders = 'طلبات جارية ومكتملة';
  static const orderTotalsAreStillLoading = 'إجمالي الطلب لسه بيتحدّث.';
  static const couldNotRefreshOrderTotalsTryAgain =
      'مش قادرين نحدّث إجمالي الطلب. حاول تاني.';
  static const ordersReturnsAndCancellationsFollowTheStorePoliciesShownAt =
      'الطلبات والمرتجعات والإلغاء بيتبعوا سياسات المتجر اللي بتظهر عند الدفع.';
  static const yourOrderHasBeenCreatedSuccessfully = 'تم إنشاء طلبك بنجاح.';

  // ─── التوصيل والشحن ───
  static const delivered = 'اتسلّم';
  static const deliveryFee = 'مصاريف التوصيل';
  static const deliveryPrice = 'سعر التوصيل';
  static const deliveryPriceWillBeConfirmedLater = 'سعر التوصيل هيتحدد لاحقًا';
  static const deliveryPriceApproval = 'الموافقة على سعر التوصيل';
  static const theDeliveryPriceWasSetByTheAdministrationReviewIt =
      'تم تحديد سعر التوصيل من الإدارة. راجعه قبل الموافقة.';
  static const approveDeliveryPrice = 'الموافقة على سعر التوصيل';
  static const deliveryPriceApproved = 'تمت الموافقة على سعر التوصيل';
  static const couldNotApproveDeliveryPrice = 'تعذر تأكيد سعر التوصيل';
  static const fixedDeliveryPricePrice = 'سعر التوصيل المحدد: {price}';
  static const moreAccurateDeliveryPriceLater = 'سعر توصيل أدق لاحقًا';
  static const externalShippingPriceLater = 'شحن خارجي - السعر يحدد لاحقًا';
  static const shippingFee = 'مصاريف الشحن';
  static const shippingDate = 'تاريخ الشحن';
  static const shippingDateLabel = 'تاريخ الشحن';
  static const couldNotLoadShippingCompanies = 'تعذر تحميل شركات الشحن.';
  static const shippingCompaniesAreStillLoading = 'جاري تحميل شركات الشحن.';
  static const nameIsSelectedForCheckout = '{name} هو العنوان المختار للطلب.';

  // ─── المبالغ ───
  static const discount = 'الخصم';
  static const offerDiscount = 'خصم العرض';
  static const subtotal = 'الإجمالي الفرعي';
  static const marketTotal = 'إجمالي المتجر';
  static const productsSubtotal = 'إجمالي المنتجات';
  static const taxFee = 'الضريبة';
  static const total = 'الإجمالي';

  // ─── نصوص متنوعة (طلبات) ───
  static const youAreOfflineShowingSavedContentCheckoutAndUpdatesNeed =
      'إنت أوفلاين. بنعرض آخر محتوى محفوظ، والدفع والتحديث محتاجين إنترنت.';
  static const productAvailabilityPricesAndDeliveryTimesCanChangeBeforeAn =
      'توفر المنتجات والأسعار ومواعيد التوصيل ممكن تتغير قبل تأكيد الطلب.';
  static const ordersAndAvailability = 'الطلبات والتوفر';
  static const makeFeelYours = 'خلّي يلا ماركت على مزاجك';
  static const refundFromOrderCwt0152 = 'استرجاع من طلب CWT0152';
  static const howCanITrackMyOrder = 'إزاي أتابع طلبي؟';
  static const trackOrder = 'تتبع الطلب';
  static const trackMyOrder = 'تتبع طلبي';
  static const activeDiscountsAndRewards = 'خصومات ومكافآت نشطة';
  static const allowSupportToViewOrderStatus = 'اسمح للدعم يشوف حالة الطلب.';
  static const canYouTrackMyOrder = 'ممكن تتابع طلبي؟';
  static const fasterHandlingForEligibleOrders = 'تجهيز أسرع للطلبات المؤهلة.';
  static const freshProductsVerifiedBrandsAndQuickCartActions =
      'منتجات جديدة وبراندات موثوقة وإضافة سريعة للسلة.';
  static const freshProductsTrustedCategoriesAndQuickCartActions =
      'منتجات جديدة وفئات موثوقة وإضافة سريعة للسلة.';
  static const hiINeedHelpTrackingMyLatestOrder =
      'أهلًا، محتاج أتابع آخر طلب عندي.';
  static const sureYourOrderIsBeingPreparedAndShouldShipToday =
      'أكيد. طلبك بيتجهز ومن المفترض يتشحن النهارده.';
  static const discountsUpTo = 'خصومات حتى';
  static const orderHelpRefundsAndDeliveryUpdates =
      'مساعدة الطلبات والاسترداد وتحديثات التوصيل';
  static const ordersRefundsAndDeliveryUpdates =
      'الطلبات والاسترداد وتحديثات التوصيل';
  static const yourNikeTrainingOrderIsBeingPrepared =
      'طلب Nike بتاعك بيتجهز دلوقتي.';
  static const yourSportsOrderIsBeingPrepared =
      'طلب الرياضة بتاعك بيتجهز دلوقتي.';

  // عبارات إضافية
  static const iNeedARefund = 'محتاج استرداد.';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String itemsAddedToCart(String count) => 'تمت إضافة $count منتج للسلة';
}

/// الإشعارات.
abstract final class NotificationTexts {
  static const notifications = 'الإشعارات';
  static const notificationsUpdated = 'تم تحديث الإشعارات';
  static const notificationDeleted = 'تم حذف الإشعار';
  static const notificationDetails = 'تفاصيل الإشعار';
  static const notificationsMarkedAsRead = 'تم تعليم الإشعارات كمقروءة';
  static const loadingNotifications = 'جاري تحميل الإشعارات...';
  static const noNotificationsYet = 'مفيش إشعارات حاليًا';
  static const unreadNotifications = 'إشعارات غير مقروءة';
  static const pushNotifications = 'إشعارات الموبايل';
  static const mobileNotifications = 'إشعارات الموبايل';
  static const refreshNotifications = 'تحديث الإشعارات';
  static const markAllAsRead = 'تحديد الكل كمقروء';
  static const deleteAllNotifications = 'حذف كل الإشعارات';
  static const deleteAllNotificationsLabel = 'حذف كل الإشعارات؟';
  static const thisWillPermanentlyDeleteAllYourNotifications =
      'سيتم حذف كل إشعاراتك نهائيًا.';
  static const allNotificationsDeleted = 'تم حذف كل الإشعارات';
  static const couldNotDeleteAllNotifications = 'تعذر حذف كل الإشعارات.';
  static const couldNotMarkNotificationsAsRead =
      'تعذر تحديد الإشعارات كمقروءة.';
  static const couldNotMarkNotificationAsRead = 'تعذر تحديد الإشعار كمقروء.';
  static const couldNotRefreshNotifications = 'تعذر تحديث الإشعارات.';
  static const couldNotUpdateNotifications = 'تعذر تحديث الإشعارات.';
  static const notificationsCouldNotLoad = 'تعذر تحميل الإشعارات';
}

/// المفضلة والمشاركة.
abstract final class FavoriteTexts {
  // ─── المفضلة ───
  static const wishlist = 'المفضلة';
  static const favoriteProducts = 'المنتجات المفضلة';
  static const favoriteStores = 'المحلات المفضلة';
  static const savedProductsAndFavorites = 'منتجاتك المحفوظة والمفضلة';
  static const yourWishlistIsWaiting = 'المفضلة مستنياك';
  static const addedToWishlist = 'اتضاف للمفضلة';
  static const itemAddedToWishlist = 'اتضاف للمفضلة';
  static const itemRemovedFromWishlist = 'اتشال من المفضلة';
  static const removedFromWishlist = 'اتشال من المفضلة';
  static const couldNotUpdateFavoriteStores = 'تعذر تحديث المحلات المفضلة';
  static const storeAddedToFavorites = 'اتضاف المحل للمفضلة';
  static const storeRemovedFromFavorites = 'اتشال المحل من المفضلة';

  // ─── المشاركة ───
  static const share = 'مشاركة';
  static const shareProduct = 'مشاركة المنتج';
  static const shareOffer = 'مشاركة العرض';
  static const shareWith = 'مشاركة عبر...';
  static const copyLink = 'نسخ الرابط';
  static const productLinkCopied = 'تم نسخ رابط المنتج';
  static const offerLinkCopied = 'تم نسخ رابط العرض';
  static const youCanShareItWithAnyone = 'تقدر تبعته لأي حد دلوقتي.';
  static const couldNotShareProduct = 'تعذر مشاركة المنتج';
  static const couldNotShareOffer = 'تعذر مشاركة العرض';
  static const couldNotShareStore = 'تعذر مشاركة المحل';
}

/// الشراكة والدعم وعن التطبيق.
abstract final class PartnerTexts {
  // ─── الدعم الفني ───
  static const technicalSupport = 'الدعم الفني';
  static const contactSupportForAssistance = 'تواصل مع الدعم الفني.';
  static const whatsapp = 'واتساب';
  static const couldNotOpenWhatsApp = 'تعذر فتح واتساب';
  static const notSupportedHere = 'غير مدعومة هنا';
  static const supportChat = 'شات الدعم';
  static const supportChatWillBeAvailableSoon = 'شات الدعم هيكون متاح قريبًا';
  static const supportIsOnline = 'الدعم متاح الآن';
  static const support = 'دعم يلا ماركت';
  static const howDoIContactSupport = 'إزاي أتواصل مع الدعم؟';
  static const returnHelp = 'مساعدة المرتجعات';
  static const prioritySupport = 'دعم أولوية';
  static const iNeedHelpWithAReturn = 'محتاج مساعدة في إرجاع منتج.';
  static const thanksSupportWillReviewThisAndReplyShortly =
      'تمام. الدعم هيراجع الرسالة ويرد قريب.';

  // ─── حول التطبيق ───
  static const aboutTheApp = 'حول التطبيق';
  static const learnMoreAboutYallaMarket = 'تعرف على تطبيق يلا ماركت';
  static const aboutYallaMarket = 'نبذة عن يلا ماركت';
  static const privacyPolicy = 'سياسة الخصوصية';
  static const privacyPolicyLabel = 'سياسة الخصوصية';
  static const privacyStatusProtected = 'حالة الخصوصية: محمية';
  static const termsOfUse = 'شروط الاستخدام';
  static const pleaseAcceptThePrivacyPolicyAndTermsOfUse =
      'لازم توافق على سياسة الخصوصية وشروط الاستخدام.';
  static const everythingYouNeedToKnowAboutTheApp =
      'كل اللي تحتاج تعرفه عن التطبيق';

  // ─── الشراكة ───
  static const registerAsAPartner = 'التسجيل كشريك';
  static const joinYallaMarketAsAStoreOrServicePartner =
      'انضم ليلا ماركت كمتجر أو شريك خدمات';
  static const growYourBusinessWithYallaMarket = 'كبّر نشاطك مع يلا ماركت';
  static const becomeAYallaMarketPartner = 'كن شريكًا ليلا ماركت';
  static const tellUsAboutYourBusinessAndOurTeamWillContact =
      'عرّفنا بنشاطك وفريقنا هيتواصل معاك بعد مراجعة الطلب.';
  static const businessInformation = 'بيانات النشاط';
  static const businessName = 'اسم النشاط';
  static const businessType = 'نوع النشاط';
  static const numberOfBranches = 'عدد الفروع';
  static const label1Branch = 'فرع واحد';
  static const label2Branches = 'فرعان';
  static const label3Branches = '3 فروع';
  static const label4Branches = '4 فروع';
  static const label5Branches = '5 فروع';
  static const contactPerson = 'بيانات المسؤول';
  static const yourRoleInTheBusiness = 'دورك في النشاط';
  static const ownerPartner = 'مالك / شريك';
  static const managerLegalRepresentative = 'مدير / ممثل قانوني';
  static const contactDetails = 'بيانات التواصل';
  static const doYouHaveATradeLicense = 'هل لديك سجل تجاري؟';
  static const restaurant = 'مطعم';
  static const serviceProvider = 'مقدم خدمات';
  static const couldNotSubmitPartnerApplication = 'تعذر إرسال طلب الشراكة';
  static const couldNotSubmitPartnerApplicationLabel =
      'تعذر إرسال طلب الشراكة.';
  static const partnerApplicationResponseWasIncomplete =
      'استجابة طلب الشراكة غير مكتملة.';
  static const youAlreadyHaveAPartnerApplicationUnderReview =
      'عندك طلب شراكة قيد المراجعة بالفعل.';
  static const weReceivedThePartnerApplicationFor =
      'استلمنا طلب الشراكة الخاص بـ';
  static const ourTeamWillReviewItAndContactYouSoon =
      'فريقنا هيراجعه ويتواصل معاك قريبًا.';
  static const weWillContactYouSoon = 'سيتم التواصل معك قريبًا.';
  static const contactToActivate = 'تواصل للتفعيل';

  // ─── الخصوصية والبيانات ───
  static const thisHelpsPersonalizeYourShoppingExperience =
      'ده بيساعدنا نخصص تجربة التسوق ليك.';
  static const activateItThroughSupportToUnlockPremiumShoppingPerks =
      'فعّلها عن طريق الدعم عشان تفتح مميزات التسوق البريميوم.';
  static const askSupportForADataCopyBeforeYouDelete =
      'اطلب من الدعم نسخة من بياناتك قبل الحذف.';
  static const dataProtection = 'حماية البيانات';
  static const weApplySecurityControlsToProtectYourInformationAndNever =
      'بنطبق إجراءات أمان لحماية بياناتك ومش بنبيع بياناتك الشخصية.';
  static const yourInformation = 'بياناتك';
}

/// الإعدادات والمظهر.
abstract final class SettingsTexts {
  static const appSettings = 'إعدادات التطبيق';
  static const appSettingsLabel = 'إعدادات التطبيق';
  static const appPreferences = 'تفضيلات التطبيق';
  static const appPreferencesLabel = 'تفضيلات التطبيق';
  static const openAppSettings = 'افتح إعدادات التطبيق';
  static const appearance = 'المظهر';
  static const theme = 'الثيم';
  static const dark = 'داكن';
  static const light = 'فاتح';
  static const alwaysUseTheDarkTheme = 'استخدم الثيم الداكن دائمًا.';
  static const alwaysUseTheLightTheme = 'استخدم الثيم الفاتح دائمًا.';
  static const useYourDeviceThemeSetting = 'استخدم إعداد الثيم من الجهاز.';
  static const language = 'اللغة';
  static const currency = 'العملة';
  static const currencySaved = 'تم حفظ العملة';
  static const dataPreferences = 'تفضيلات البيانات';
  static const safeMode = 'الوضع الآمن';
  static const safeModeLabel = 'الوضع الآمن';
  static const useThisShortcutForTheSettingsPeopleChangeMostOften =
      'استخدم الاختصار ده للإعدادات اللي بتتغير كتير.';
}

/// الرئيسية والترويج.
abstract final class HomeTexts {
  static const home = 'الرئيسية';
  static const discoverLimitlessChoicesAndUnmatchedConvenience =
      'أول أونلاين ماركت في التل الكبير';
  static const freshDealsAreLoading = 'بنحمّل أحدث العروض';
  static const homePetsAndDailyEssentials = 'البيت والحيوانات واحتياجات يومية';
  static const membershipBenefits = 'مميزات العضوية';
  static const popularity = 'الأكثر شيوعًا';
  static const everythingYouNeedInOnePlace = 'كل احتياجاتك في مكان واحد';
  static const howDoIPlaceAnOrder = 'إزاي أعمل طلب؟';
  static const chooseYourMarketAndProductsAddTheDeliveryAddressThen =
      'اختار السوق والمنتجات، أضف عنوان التوصيل، وبعدها أكّد طلبك من السلة.';

  // عبارات إضافية
  static const fastDeliveryToYourDoor = 'توصيل سريع لحد بابك';

  // النصوص المتغيرة حسب العدد أو بيانات الشاشة.
  static String freshPicks(String title) => 'اختيارات جديدة من $title';
}

/// الوقت والتاريخ.
abstract final class TimeTexts {
  // ─── الوقت النسبي ───
  static const justNow = 'دلوقتي';
  static const minAgo = 'دقيقة';
  static const minsAgo = 'دقائق';
  static const hourAgo = 'ساعة';
  static const hoursAgo = 'ساعات';
  static const daysAgo = 'أيام';
  static const minutes = 'دقيقة';
  static const minutesMin = '{minutes} دقيقة';
  static const today = 'النهارده';
  static const yesterday = 'امبارح';
  static const thisWeek = 'الأسبوع ده';
  static const thisMonth = 'الشهر ده';
  static const endsToday = 'بينتهي النهارده';
  static const label3DaysLeft = 'باقي 3 أيام';
  static const label1WeekLeft = 'باقي أسبوع';

  // ─── التاريخ ───
  static const chooseDate = 'اختيار التاريخ';
  static const day = 'اليوم';
  static const month = 'الشهر';
  static const year = 'السنة';
  static const selectedDays = 'عدد الأيام المحددة';
  static const birthDate = 'تاريخ الميلاد';
  static const changeBirthDate = 'تغيير تاريخ الميلاد';
  static const chooseYourBirthDate = 'اختار تاريخ ميلادك';

  // ─── تحديثات الحالة ───
  static const contentUpdated = 'تم تحديث المحتوى';
  static const languageUpdated = 'تم تحديث اللغة';
  static const statusUpdated = 'تم تحديث الحالة';
  static const themeUpdated = 'تم تغيير الثيم';
  static const shipmentUpdate = 'تحديث الشحنة';
  static const popularCategoriesUpdated = 'تم تحديث الفئات الشائعة';
  static const activateNow = 'فعّل الآن';

  // ─── متنوع (وقت) ───
  static const goodDayForShopping = 'يوم مناسب للتسوق';
  static const usuallyRepliesInAFewMinutes = 'عادةً بيرد خلال دقايق';
  static const iWouldLikeToReceiveUpdatesByWhatsApp =
      'أرغب في استلام التحديثات عبر واتساب';
  static const offlineUpdatesHint =
      'مفيش اتصال بالإنترنت. راجع الشبكة عشان نحدّث البيانات.';
  static const youCanAlsoAskAboutRefundsReturnsOrDeliveryUpdates =
      'تقدر كمان تسأل عن الاسترداد أو المرتجعات أو تحديثات التوصيل.';
  static const thisVariationIsAvailableNowWithLimitedStock =
      'الاختيار ده متوفر حاليًا بكمية محدودة.';
  static const everydayTrainingJacket = 'جاكيت تدريب يومي';
}

/// التسميات والأقسام والنصوص المتنوعة.
abstract final class GeneralTexts {
  // ─── تسميات أساسية ───
  static const name = 'الاسم';
  static const type = 'النوع';
  static const color = 'اللون';
  static const size = 'المقاس';
  static const small = 'صغير';
  static const medium = 'متوسط';
  static const large = 'كبير';
  static const xLarge = 'كبير جدًا';
  static const variant = 'الاختيار';
  static const description = 'الوصف';
  static const country = 'الدولة';
  static const state = 'المحافظة';
  static const postalCode = 'الرمز البريدي';
  static const gender = 'النوع';
  static const male = 'ذكر';
  static const female = 'أنثى';
  static const other = 'أخرى';
  static const preferNotToSay = 'أفضل عدم الإفصاح';
  static const firstName = 'الاسم الأول';
  static const lastName = 'اسم العائلة';
  static const lastNameLabel = 'اسم العيلة';
  static const firstNameLabel = 'الاسم الأول';
  static const mobileNumber = 'رقم الموبايل';
  static const landlineOptional = 'رقم أرضي (اختياري)';
  static const egp = 'جنيه';
  static const version = 'الإصدار';
  static const frequentlyAskedQuestions = 'أسئلة متكررة';

  // ─── إجراءات ───
  static const add = 'إضافة';
  static const addToBag = 'ضيف للسلة';
  static const apply = 'تطبيق';
  static const change = 'تغيير';
  static const changeGender = 'تغيير النوع';
  static const changeName = 'تغيير الاسم';
  static const download = 'تحميل';
  static const enter = 'دخول';
  static const from = 'من';
  static const to = 'إلى';
  static const reset = 'إعادة الضبط';
  static const send = 'إرسال';
  static const skip = 'تخطِ';
  static const switchText = 'تبديل';
  static const all = 'الكل';
  static const defaultText = 'الافتراضي';
  static const custom = 'مخصص';
  static const manual = 'يدوي';
  static const automatic = 'تلقائي';
  static const general = 'جاهز للشحن';

  // ─── حالات ───
  static const active = 'نشط';
  static const approved = 'تمت الموافقة';
  static const disabled = 'معطلة';
  static const expired = 'منتهي';
  static const verified = 'موثق';
  static const pending = 'قيد الانتظار';
  static const pickedUp = 'تم الاستلام';
  static const preparing = 'جاري التجهيز';
  static const ready = 'جاهز';
  static const rejected = 'مرفوض';
  static const permanent = 'نهائي';
  static const permanentDeletion = 'حذف نهائي';
  static const online = 'متصل';
  static const offline = 'غير متصل';
  static const comingSoon = 'قريبًا';
  static const welcome = 'أهلاً بك';
  static const gotIt = 'تمام';

  // ─── التوصيل ───
  static const delivery = 'توصيل';
  static const deliveryType = 'نوع التوصيل';
  static const deliveryWithin = 'توصيل خلال';
  static const deliveringTo = 'التوصيل إلى:';
  static const free = 'مجاني';
  static const freeDelivery = 'توصيل مجاني';
  static const priorityDelivery = 'توصيل أولوية';
  static const betterDeliveryExperience = 'تجربة توصيل أفضل';
  static const courier = 'دليفيري';
  static const courierAssigned = 'تم تعيين الطيار';
  static const later = 'لاحقًا';
  static const determinedLater = 'يتحدد لاحقًا';
  static const shipmentOnTheWay = 'في الطريق';

  // ─── العضوية ───
  static const goldMembership = 'عضوية جولد';
  static const goldMember = 'عضو جولد';
  static const goldMemberIsInactive = 'عضوية جولد غير مفعّلة';
  static const inactivePlan = 'الباقة غير مفعلة';
  static const earlySaleAccess = 'وصول مبكر للعروض';

  // ─── النصوص والمحتوى ───
  static const readMore = ' اقرأ المزيد';
  static const showLess = ' عرض أقل';
  static const additionalInstructionsOptional = 'إرشادات إضافية (اختياري)';
  static const additionalValue = 'القيمة الإضافية';
  static const agreementRequired = 'الموافقة مطلوبة';
  static const beforeDeleting = 'قبل الحذف';
  static const imageDownloadStarted = 'بدأ تحميل الصورة';
  static const hdImageQuality = 'جودة صور HD';
  static const writeAMessage = 'اكتب رسالة...';
  static const typeAMessage = 'اكتب رسالة';
  static const addANewStop = 'ضيف عنوان جديد';
  static const quickControls = 'تحكم سريع';
  static const refund = 'استرجاع';
  static const security = 'الأمان';
  static const securityAndDataControls = 'تحكم في الأمان والبيانات';
  static const newArrivals = 'وصل حديثًا';
  static const sale = 'العروض';
  static const additions = 'الإضافات';
  static const thisFieldIsRequired = 'الخانة دي مطلوبة';
  static const thisFieldIsRequiredLabel = 'الحقل ده مطلوب.';
  static const enterAValidMobileNumber = 'اكتب رقم موبايل صحيح.';
  static const pleaseCompleteTheRequiredFields = 'كمّل البيانات المطلوبة.';
  static const nameIsTooShort = 'الاسم قصير جدًا';
  static const requireACodeForSensitiveActions = 'اطلب كود للإجراءات الحساسة.';
  static const iAgreeTo = 'أنا موافق على ';
  static const and = ' و ';
  static const enterAValidEmailAddress = 'اكتب بريد إلكتروني صحيح.';
  static const enterAValidEmailAddressLabel = 'اكتب إيميل صحيح';
  static const useAnEmailAddressYouCanAccessForAccountRecovery =
      'استخدم إيميل تقدر توصله لاسترجاع الحساب.';
  static const welcomeTo = 'أهلًا بيك في يلا ماركت.';

  // ─── الأقسام ───
  static const clothes = 'ملابس';
  static const electronics = 'إلكترونيات';
  static const electronicDevices = 'أجهزة إلكترونية';
  static const mobile = 'موبايل';
  static const accessories = 'إكسسوارات';
  static const spareParts = 'قطع غيار';
  static const fashion = 'موضة';
  static const furniture = 'أثاث';
  static const lifestyle = 'لايف ستايل';
  static const pets = 'حيوانات أليفة';
  static const shoes = 'أحذية';
  static const sportShoes = 'أحذية رياضية';
  static const sports = 'رياضة';
  static const sportsEquipment = 'معدات رياضية';
  static const trackSuits = 'ترنجات';
  static const shoesKitsAndTrainingGear = 'أحذية وأطقم ومستلزمات تدريب';
  static const jacketsShirtsAndOutfits = 'جاكيتات وتيشيرتات وأطقم';
  static const phonesDevicesAndAccessories = 'موبايلات وأجهزة وإكسسوارات';
  static const newest = 'الأحدث';
  static const bestMatch = 'الأقرب';
  static const systemDefault = 'حسب النظام';
  static const toActivate = 'للتفعيل';
  static const paypal = 'PayPal';
  static const paypalBalance = 'رصيد PayPal';

  // ─── الدول والمدن ───
  static const argentina = 'الأرجنتين';
  static const india = 'الهند';
  static const pakistan = 'باكستان';
  static const saudiArabia = 'السعودية';
  static const turkey = 'تركيا';
  static const usa = 'الولايات المتحدة';
  static const heliopolis = 'مصر الجديدة';
  static const maadi = 'المعادي';
  static const zamalek = 'الزمالك';
  static const shubra = 'شبرا';
  static const helwan = 'حلوان';
  static const label15May = '15 مايو';
  static const mokattam = 'المقطم';
  static const mansoura = 'المنصورة';
  static const hurghada = 'الغردقة';
  static const sharmElSheikh = 'شرم الشيخ';
  static const tanta = 'طنطا';
  static const naamaBay = 'خليج نعمة';
  static const nabq = 'نبق';
  static const hadaba = 'الهضبة';

  // ─── اللغة ───
  static const arabic = 'العربية';
  static const arabicInterface = 'واجهة عربية بالكامل';
  static const english = 'الإنجليزية';
  static const englishInterface = 'واجهة باللغة الإنجليزية';

  // ─── عينات المنتجات (Demo / Preview) ───
  static const appleIPhone8Black64Gb = 'آيفون 8 أسود 64 جيجا';
  static const blueTShirtForAllAges = 'تيشيرت أزرق لكل الأعمار';
  static const black = 'أسود';
  static const green = 'أخضر';
  static const red = 'أحمر';
  static const lightweightActiveTee = 'تيشيرت رياضي خفيف';
  static const performanceGymKit = 'طقم جيم عملي';
  static const premiumLeatherJacket = 'جاكيت جلد فاخر';
  static const eliteTrainingFootball = 'كورة تدريب احترافية';
  static const courtReadyAccessories = 'إكسسوارات جاهزة للملعب';
  static const warmupStreetHoodie = 'هودي Warmup ستريت';
  static const airMaxRunningShoes = 'كوتشي Air Max للجري';
  static const wildhorseTrailShoes = 'كوتشي Wildhorse للجري على الطرق';
  static const greenNikeSportsShoe = 'كوتشي Nike رياضي أخضر';
  static const nikeAirJordanOrange = 'Nike Air Jordan برتقالي';
  static const nikeAirJordanRedBlack = 'Nike Air Jordan أحمر وأسود';
  static const nikeWildhorseRunningShoe = 'كوتشي Nike Wildhorse للجري';
  static const jordanCourtBlue = 'Jordan أزرق للملعب';
  static const samsungS9MobileBundle = 'باقة موبايل Samsung S9';
  static const tomiDryFoodPack = 'عبوة أكل جاف Tomi';
  static const visaEnding4721 = 'فيزا آخرها 4721';
  static const label20OffSportsPicks = 'خصم 20% على اختيارات الرياضة';
  static const greenSportsShoe = 'حذاء رياضي أخضر';
  static const redBlackSportsSneaker = 'حذاء رياضي أحمر وأسود';
  static const orangeSportsSneaker = 'حذاء رياضي برتقالي';
  static const trailRunningShoe = 'حذاء جري للطرق';
  static const blueCourtSneaker = 'حذاء ملعب أزرق';
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
