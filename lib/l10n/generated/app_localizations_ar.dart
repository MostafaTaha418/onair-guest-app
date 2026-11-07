// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'OnAir';

  @override
  String get home => 'الرئيسية';

  @override
  String get search => 'بحث';

  @override
  String get bookings => 'حجوزاتي';

  @override
  String get favorites => 'المفضلة';

  @override
  String get account => 'حسابي';

  @override
  String get welcome => 'أهلًا بيك';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get retry => 'حاول تاني';

  @override
  String get emptyState => 'مفيش بيانات لعرضها دلوقتي.';

  @override
  String get loading => 'جاري التحميل';

  @override
  String get offline => 'مفيش اتصال بالإنترنت.';

  @override
  String referenceNumber(String ref) {
    return 'رقم المرجع: $ref';
  }

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get phoneNumber => 'رقم الموبايل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get verificationCode => 'كود التأكيد';

  @override
  String get sendCode => 'ابعت الكود';

  @override
  String get confirm => 'تأكيد';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get errorUnauthenticated => 'انتهت الجلسة. سجّل الدخول مرة أخرى.';

  @override
  String get authPhoneCountryNotSupported =>
      'حاليًا ندعم أرقام الموبايل المصرية فقط. تقدر تسجّل بالبريد الإلكتروني.';

  @override
  String get authOtpInvalid => 'الكود غير صحيح. راجع الرسالة وجرّب تاني.';

  @override
  String get authOtpExpired => 'الكود انتهت صلاحيته. اطلب كود جديد.';

  @override
  String authRateLimited(String time) {
    return 'محاولات كتير. جرّب تاني بعد $time.';
  }

  @override
  String get errorValidationFailed => 'راجع البيانات المكتوبة.';

  @override
  String get authTermsChanged => 'الشروط اتحدّثت. راجعها ووافق عليها للمتابعة.';

  @override
  String get authProfileIncomplete => 'كمّل بياناتك للمتابعة.';

  @override
  String get appUpdateRequired => 'لازم تحدّث التطبيق للمتابعة.';

  @override
  String get bookingPhoneNotVerified => 'أكّد رقم موبايلك قبل الحجز.';

  @override
  String get bookingEmailNotVerified => 'أكّد بريدك قبل الحجز.';

  @override
  String get bookingDatesUnavailable => 'التواريخ دي مش متاحة.';

  @override
  String get bookingGuestsExceeded => 'عدد الضيوف أكبر من المسموح.';

  @override
  String get bookingQuoteExpired => 'السعر اتحدّث. راجع الملخص من جديد.';

  @override
  String get propertyNotAvailable => 'الشقة دي مش متاحة حاليًا.';

  @override
  String get errorActionNotAllowed => 'الإجراء ده مش متاح دلوقتي.';

  @override
  String get stayCollectorNotAuthorized =>
      'الشخص ده مش مفوّض يستلم فلوس للشقة دي. متسلّمش كاش وكلّم OnAir.';

  @override
  String errorUnexpected(String ref) {
    return 'حصلت مشكلة غير متوقعة. رقم المرجع: $ref';
  }

  @override
  String get errorNoConnection => 'مفيش اتصال بالإنترنت.';

  @override
  String get errorUnexpectedNoRef => 'حصلت مشكلة غير متوقعة. جرّب تاني.';

  @override
  String get errorCancelled => 'تم إلغاء العملية.';

  @override
  String get authInvalidCredentials => 'البريد أو كلمة المرور غير صحيحة.';

  @override
  String get authCodeSent => 'بعتنا لك كود التأكيد.';

  @override
  String get authRecoverySent => 'لو البريد مسجّل، هتوصلك رسالة الاستعادة.';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notAvailable => 'غير متاح حاليًا';

  @override
  String get searchEmpty => 'ابدأ البحث عن مكان إقامتك.';

  @override
  String get bookingsEmpty => 'حجوزاتك هتظهر هنا.';

  @override
  String get favoritesEmpty => 'الأماكن المفضلة هتظهر هنا.';

  @override
  String get favoriteAdd => 'إضافة إلى المفضلة';

  @override
  String get favoriteRemove => 'إزالة من المفضلة';

  @override
  String get favoriteSaveFailed => 'تعذّر تحديث المفضلة. جرّب مرة أخرى.';

  @override
  String get favoritesLoadFailed => 'تعذّر تحميل المفضلة. جرّب مرة أخرى.';

  @override
  String get accountEmpty => 'بيانات حسابك هتظهر هنا.';

  @override
  String get authLoginTitle => 'أهلًا بيك في OnAir';

  @override
  String get authRegisterTitle => 'أنشئ حسابك';

  @override
  String get authPhoneHint => 'مثال: 01012345678';

  @override
  String get authPhoneInvalid => 'اكتب رقم موبايل مصري صحيح من 11 رقم.';

  @override
  String get authPhoneTab => 'الموبايل';

  @override
  String get authEmailTab => 'البريد الإلكتروني';

  @override
  String get authEmailComingSoon => 'التسجيل بالبريد الإلكتروني هيتاح قريبًا.';

  @override
  String get authTermsPrefix => 'بالمتابعة أنت توافق على';

  @override
  String get terms => 'الشروط والأحكام';

  @override
  String get privacy => 'سياسة الخصوصية';

  @override
  String get authNoAccount => 'لسه معندكش حساب؟';

  @override
  String get authHasAccount => 'عندك حساب بالفعل؟';

  @override
  String get authCreateAccount => 'إنشاء حساب';

  @override
  String get authCodeTitle => 'اكتب كود التأكيد';

  @override
  String authCodeDescription(String phone) {
    return 'بعتنا كود من 6 أرقام إلى $phone';
  }

  @override
  String get authResend => 'إعادة إرسال الكود';

  @override
  String authResendIn(String time) {
    return 'إعادة الإرسال بعد $time';
  }

  @override
  String get authChangePhone => 'تغيير رقم الموبايل';

  @override
  String get authCompleteProfileTitle => 'كمّل بياناتك';

  @override
  String get authNameInvalid => 'الاسم لازم يكون من حرفين إلى 80 حرف.';

  @override
  String get authAcceptTerms => 'أوافق على الشروط والأحكام وسياسة الخصوصية';

  @override
  String get authTermsRequired => 'لازم توافق على الشروط للمتابعة.';

  @override
  String authWaitSeconds(int seconds) {
    return '$seconds ثانية';
  }

  @override
  String get authEmailInvalid => 'اكتب بريد إلكتروني صحيح.';

  @override
  String get authFieldRequired => 'الحقل ده مطلوب.';

  @override
  String get authCodeRequired => 'اكتب كود التأكيد.';

  @override
  String get authCodeIncomplete => 'اكتب الكود كاملًا من 6 أرقام.';

  @override
  String get authPasswordRule => '8 أحرف على الأقل، بينهم حرف ورقم';

  @override
  String get authPasswordWeak => 'ضعيفة';

  @override
  String get authPasswordMedium => 'متوسطة';

  @override
  String get authPasswordStrong => 'قوية';

  @override
  String get authForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get authRecoveryTitle => 'استعادة كلمة المرور';

  @override
  String get authRecoveryDescription => 'اكتب بريدك وسنبعت لك كود الاستعادة.';

  @override
  String get authNewPasswordTitle => 'كلمة مرور جديدة';

  @override
  String get authNewPassword => 'حفظ كلمة المرور';

  @override
  String get authChangeEmail => 'تغيير البريد الإلكتروني';

  @override
  String get authEmailNotVerified => 'غير مؤكد';

  @override
  String get authVerifyNow => 'أكد الآن';

  @override
  String get authEmailStatus => 'حالة البريد الإلكتروني';

  @override
  String get authSignUpWithEmail => 'إنشاء الحساب بالبريد';

  @override
  String get authSignInWithEmail => 'تسجيل الدخول بالبريد';

  @override
  String get authClose => 'إغلاق';

  @override
  String get updateRequiredTitle => 'تحديث مطلوب';

  @override
  String get updateRequiredStoreButton => 'حدّث التطبيق';

  @override
  String get homeHello => 'أهلًا';

  @override
  String get homeSearchHint => 'دوّر على شقة: المكان، التاريخ، الضيوف';

  @override
  String get homeAreasTitle => 'مناطق ووجهات';

  @override
  String get homeSuggestedTitle => 'متاح من اليوم';

  @override
  String get propertyViewDetails => 'عرض التفاصيل';

  @override
  String get propertyAvailableBadge => 'متاح';

  @override
  String get propertyAvailableTonight => 'متاح الليلة';

  @override
  String get propertyBookedTonight => 'محجوز الليلة';

  @override
  String get homeNewestTitle => 'أحدث الشقق';

  @override
  String get homeUpcomingTitle => 'حجزك الجاي';

  @override
  String get homeUpcomingConfirmed => 'حجز مؤكد';

  @override
  String get homeEmpty =>
      'مفيش شقق ظاهرة دلوقتي. جرّب تبحث في مكان أو تواريخ مختلفة.';

  @override
  String homeSectionError(String section) {
    return 'تعذر تحميل $section. حاول مرة أخرى.';
  }

  @override
  String get homeEmptyAction => 'ابحث عن شقة';

  @override
  String areaListingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شقة',
      many: '$count شقة',
      few: '$count شقق',
      two: 'شقتين',
      one: 'شقة واحدة',
      zero: 'مفيش شقق',
    );
    return '$_temp0';
  }

  @override
  String get searchTitle => 'البحث';

  @override
  String get searchLocationLabel => 'المكان';

  @override
  String get searchLocationHint => 'محافظة، مدينة أو منطقة';

  @override
  String get searchAnyLocation => 'كل الأماكن';

  @override
  String get searchNoLocationMatches => 'مفيش أماكن بالاسم ده.';

  @override
  String get searchDatesLabel => 'التواريخ';

  @override
  String get searchDatesHint => 'الوصول والمغادرة';

  @override
  String get searchGuestsLabel => 'عدد الضيوف';

  @override
  String get searchGuestsAny => 'أي عدد';

  @override
  String get searchAction => 'ابحث';

  @override
  String get searchFilters => 'الفلاتر';

  @override
  String get searchClearAll => 'مسح الكل';

  @override
  String searchShowResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عرض $count نتيجة',
      two: 'عرض نتيجتين',
      one: 'عرض نتيجة واحدة',
      zero: 'مفيش نتايج',
    );
    return '$_temp0';
  }

  @override
  String get searchShowResultsUnknown => 'عرض النتايج';

  @override
  String get searchPriceRange => 'سعر الليلة';

  @override
  String get searchMinBedrooms => 'أقل عدد غرف';

  @override
  String get searchMinBathrooms => 'أقل عدد حمامات';

  @override
  String get searchAnyCount => 'أي عدد';

  @override
  String get searchAmenities => 'المرافق والمميزات';

  @override
  String get searchPropertyType => 'نوع العقار';

  @override
  String get searchSort => 'الترتيب';

  @override
  String get sortPriceAsc => 'السعر: من الأقل';

  @override
  String get sortPriceDesc => 'السعر: من الأعلى';

  @override
  String get sortNewest => 'الأحدث';

  @override
  String get searchNoResults => 'مفيش شقق متاحة بالمعايير دي.';

  @override
  String get searchNoResultsHint => 'جرّب تغيّر التواريخ أو الفلاتر.';

  @override
  String get searchDatesNeededHint => 'اختار التواريخ عشان تقدر تحجز.';

  @override
  String get searchDatesDropped =>
      'التواريخ اللي في الرابط فاتت. اختار تواريخ جديدة.';

  @override
  String get searchChooseDates => 'اختار التواريخ';

  @override
  String get searchShare => 'مشاركة البحث';

  @override
  String get shareSearchText => 'بحث على OnAir';

  @override
  String nightlyPrice(String price) {
    return '$price / الليلة';
  }

  @override
  String stayTotal(int nights, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: 'إجمالي $nights ليلة: $total',
      few: 'إجمالي $nights ليالي: $total',
      two: 'إجمالي ليلتين: $total',
      one: 'إجمالي ليلة واحدة: $total',
    );
    return '$_temp0';
  }

  @override
  String filterChipRemove(String label) {
    return 'شيل فلتر $label';
  }

  @override
  String bedroomsAtLeast(int count) {
    return '$count+ غرف';
  }

  @override
  String bathroomsAtLeast(int count) {
    return '$count+ حمامات';
  }

  @override
  String priceRangeChip(String min, String max) {
    return '$min – $max';
  }

  @override
  String get guestsDecrease => 'قلّل عدد الضيوف';

  @override
  String get guestsIncrease => 'زوّد عدد الضيوف';

  @override
  String get countDecrease => 'قلّل';

  @override
  String get countIncrease => 'زوّد';

  @override
  String get calendarConfirm => 'تمام';

  @override
  String get calendarClear => 'مسح';

  @override
  String get calendarPrevMonth => 'الشهر اللي فات';

  @override
  String get calendarNextMonth => 'الشهر الجاي';

  @override
  String get calendarRangeInvalid => 'الفترة دي فيها ليالي مش متاحة.';

  @override
  String get calendarRangeNotLoaded =>
      'التوافر لسه بيتحمّل لشهر من الفترة دي. حاول تاني بعد لحظات.';

  @override
  String get calendarRangeLoadFailed =>
      'تعذّر تحميل التوافر لشهر من الفترة دي. افتح الشهر ده واضغط إعادة المحاولة.';

  @override
  String calendarNightsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ليلة',
      few: '$count ليالي',
      two: 'ليلتين',
      one: 'ليلة واحدة',
    );
    return '$_temp0';
  }

  @override
  String calendarUnavailableDay(String date) {
    return '$date، مش متاح';
  }

  @override
  String propertyBedrooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count غرفة',
      few: '$count غرف',
      two: 'غرفتين',
      one: 'غرفة واحدة',
    );
    return '$_temp0';
  }

  @override
  String propertyBathrooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حمام',
      few: '$count حمامات',
      two: 'حمامين',
      one: 'حمام واحد',
    );
    return '$_temp0';
  }

  @override
  String propertyMaxGuests(int count) {
    return 'لحد $count ضيوف';
  }

  @override
  String propertyArea(int sqm) {
    return '$sqm م²';
  }

  @override
  String get propertyDescription => 'الوصف';

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get propertyAmenities => 'المرافق';

  @override
  String get propertySeeAllAmenities => 'عرض كل المرافق';

  @override
  String get propertyLocation => 'الموقع';

  @override
  String get propertyRules => 'قواعد الإقامة';

  @override
  String rulesCheckIn(String time) {
    return 'الاستلام من $time';
  }

  @override
  String rulesCheckOut(String time) {
    return 'المغادرة لحد $time';
  }

  @override
  String rulesVisitorsAllowed(int count) {
    return 'الزوار مسموحين (لحد $count)';
  }

  @override
  String get rulesVisitorsAllowedNoLimit => 'الزوار مسموحين';

  @override
  String get rulesVisitorsNotAllowed => 'الزوار مش مسموحين';

  @override
  String get propertyPolicy => 'العربون والإلغاء';

  @override
  String policyDepositPercent(String percent) {
    return 'العربون $percent% من إجمالي الحجز.';
  }

  @override
  String policyDepositFixed(String amount) {
    return 'العربون $amount.';
  }

  @override
  String get policyDepositFull => 'الحجز ده بيتدفع بالكامل مقدمًا.';

  @override
  String policyFreeCancellation(int hours) {
    return 'الإلغاء مجاني لحد $hours ساعة قبل ميعاد الاستلام، وبيرجعلك المبلغ كامل.';
  }

  @override
  String get policyAfterDeadline =>
      'لو لغيت بعد الميعاد ده وقبل الإقامة، بتخسر العربون بس ويرجعلك الباقي.';

  @override
  String get policyFullyPaidLate =>
      'لو الحجز مدفوع بالكامل وألغيته بعد 24 ساعة من ميعاد الاستلام، المبلغ مش بيرجع.';

  @override
  String get propertyAvailability => 'التوافر';

  @override
  String get propertyReviews => 'التقييمات';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تقييم',
      few: '$count تقييمات',
      two: 'تقييمين',
      one: 'تقييم واحد',
    );
    return '$_temp0';
  }

  @override
  String get reviewsNone => 'لسه مفيش تقييمات.';

  @override
  String get reviewsSeeAll => 'عرض كل التقييمات';

  @override
  String ratingSemantics(String rating, int count) {
    return 'التقييم $rating من 5، $count تقييم';
  }

  @override
  String get propertyContactOnAir => 'عندك سؤال؟ تواصل مع OnAir';

  @override
  String get bookNow => 'احجز الآن';

  @override
  String get propertyTermsUpdated => 'الشروط اتحدّثت. راجعها قبل ما تحجز.';

  @override
  String get propertyShare => 'مشاركة';

  @override
  String get galleryOpen => 'افتح الصور';

  @override
  String get galleryClose => 'إغلاق';

  @override
  String galleryPhotoPosition(int current, int total) {
    return 'صورة $current من $total';
  }

  @override
  String get galleryEmpty => 'مفيش صور للشقة دي.';

  @override
  String get supportEntryTitle => 'تواصل مع OnAir';

  @override
  String get supportEntryComingSoon => 'خدمة الدعم من التطبيق هتتفتح قريب.';

  @override
  String get errorAccountSuspended => 'الحساب موقوف. تواصل مع خدمة العملاء.';

  @override
  String get authPhoneAlreadyUsed => 'الرقم ده مستخدم في حساب تاني.';

  @override
  String get bookingPolicyOutOfBounds =>
      'السعر مش ثابت على التواريخ دي. جرّب تواريخ تانية أو تواصل مع الدعم.';

  @override
  String get errorConflict => 'البيانات اتغيرت. حدّث الصفحة وجرّب تاني.';

  @override
  String get bookingStateChanged => 'حالة الحجز اتغيرت. حدّث الصفحة.';

  @override
  String get errorDuplicateOperation => 'العملية دي اتعملت قبل كده.';

  @override
  String get paymentVerificationIssue =>
      'فيه مشكلة في التحقق من الدفع. فريقنا هيتواصل معاك.';

  @override
  String get close => 'إغلاق';

  @override
  String get bookingDatesTitle => 'اختار التواريخ';

  @override
  String get bookingPickCheckIn => 'اختار يوم الدخول';

  @override
  String get bookingPickCheckOut => 'اختار يوم المغادرة';

  @override
  String get bookingRangeHasUnavailable =>
      'الفترة دي فيها يوم مش متاح. اختار تواريخ تانية.';

  @override
  String bookingNightsCount(String count) {
    return 'عدد الليالي: $count';
  }

  @override
  String get bookingContinue => 'متابعة';

  @override
  String get bookingStartFromProperty => 'ابدأ الحجز من صفحة الشقة.';

  @override
  String get bookingSummaryTitle => 'ملخص الحجز';

  @override
  String get bookingNights => 'الليالي';

  @override
  String get bookingNightlyPrice => 'سعر الليلة';

  @override
  String get bookingTotal => 'الإجمالي';

  @override
  String get bookingPayNow => 'المطلوب دفعه دلوقتي';

  @override
  String get bookingRemaining => 'المتبقي';

  @override
  String bookingRemainingDue(String date) {
    return 'يتسدد قبل $date';
  }

  @override
  String get bookingPolicyTitle => 'الشروط وسياسة الإلغاء';

  @override
  String get bookingSummaryOwnerNotice =>
      'هيتبعت طلبك للمالك بعد الدفع. لو رفض أو مردّش خلال 24 ساعة هيترد لك المبلغ بالكامل.';

  @override
  String get bookingGoToPayment => 'اذهب للدفع';

  @override
  String get paymentReturnHint => 'لو خلّصت الدفع، اضغط هنا عشان نتحقق منه.';

  @override
  String get paymentCheckStatus => 'تحقق من الدفع';

  @override
  String get paymentVerifying => 'جارٍ التحقق من الدفع…';

  @override
  String get paymentVerifyingBody => 'ده ممكن ياخد دقايق. هنبلغك أول ما يتأكد.';

  @override
  String get paymentSuccessTitle => 'تم الدفع وأُرسل طلبك للمالك';

  @override
  String get paymentSuccessBody => 'التواريخ محجوزة لك لحد ما المالك يرد.';

  @override
  String ownerDeadlineCountdown(String time) {
    return 'المالك قدامه $time للرد';
  }

  @override
  String get paymentViewBooking => 'عرض الحجز';

  @override
  String get paymentFailedTitle => 'لم تكتمل عملية الدفع';

  @override
  String get paymentFailedBody => 'ولم يُخصم أي مبلغ.';

  @override
  String get paymentTryAgain => 'حاول مرة أخرى';

  @override
  String get paymentConflictTitle => 'التواريخ اتحجزت قبل اكتمال دفعتك';

  @override
  String paymentConflictBody(String amount) {
    return 'هيترد لك المبلغ بالكامل ($amount).';
  }

  @override
  String get paymentFindOtherDates => 'ابحث عن تواريخ تانية';

  @override
  String get paymentTimeoutTitle => 'لسه موصلناش تأكيد الدفع';

  @override
  String get paymentTimeoutBody => 'متقلقش ومتدفعش تاني. هنبلغك أول ما يتأكد.';

  @override
  String get paymentGoToBookings => 'اذهب لحجوزاتي';

  @override
  String get mockPaymentTitle => 'صفحة دفع تجريبية';

  @override
  String get mockPaySuccess => 'دفع ناجح';

  @override
  String get mockPayFailure => 'فشل الدفع';

  @override
  String get mockPayConflict => 'دفع ناجح بتواريخ محجوزة';

  @override
  String get mockPaySilent => 'الخادم ما يردش';

  @override
  String get mockPayClose => 'إغلاق الصفحة';

  @override
  String get verifyTitle => 'تأكيد بياناتك';

  @override
  String get verifyIntro =>
      'قبل أول حجز لازم نأكد بريدك ورقم موبايلك بكود يوصلك على البريد.';

  @override
  String get verifyEmailCodeHint => 'اكتب الكود اللي وصلك على البريد';

  @override
  String get verifyHasWhatsapp => 'الرقم ده عليه واتساب';

  @override
  String get verifyWhatsappNumber => 'رقم الواتساب (اختياري)';

  @override
  String get verifyCodeSentToEmail => 'بعتنا كود من 6 أرقام على بريدك.';

  @override
  String get verifyResend => 'ابعت الكود تاني';

  @override
  String verifyResendIn(String seconds) {
    return 'تقدر تبعت الكود تاني بعد $seconds ثانية';
  }

  @override
  String get bookingsTabCurrent => 'الحالية';

  @override
  String get bookingsTabPast => 'السابقة';

  @override
  String get bookingsTabCancelled => 'الملغاة';

  @override
  String get bookingsEmptyCurrent => 'مفيش حجوزات حالية.';

  @override
  String get bookingsEmptyPast => 'مفيش إقامات سابقة.';

  @override
  String get bookingsEmptyCancelled => 'مفيش حجوزات ملغاة.';

  @override
  String get bookingsFindApartment => 'ابحث عن شقة';

  @override
  String lastUpdated(String time) {
    return 'آخر تحديث: $time';
  }

  @override
  String get bookingStatusPaymentPending => 'بانتظار إتمام الدفع';

  @override
  String get bookingStatusPaymentVerifying => 'جارٍ التحقق من الدفع';

  @override
  String get bookingStatusAwaitingOwner => 'بانتظار تأكيد المالك';

  @override
  String get bookingStatusPaymentConflict => 'التواريخ اتحجزت قبلك';

  @override
  String get bookingStatusConfirmed => 'حجز مؤكد';

  @override
  String get bookingStatusCheckedIn => 'إقامة جارية';

  @override
  String get bookingStatusCompleted => 'إقامة مكتملة';

  @override
  String get bookingStatusRejected => 'رفض المالك';

  @override
  String get bookingStatusExpired => 'انتهت مهلة التأكيد';

  @override
  String get bookingStatusCancelled => 'ملغي';

  @override
  String get bookingStatusNoShow => 'لم يحضر';

  @override
  String get bookingStatusAbandoned => 'لم يكتمل';

  @override
  String get bookingStatusUnknown => 'تحديث على الحجز';

  @override
  String get bookingMsgPaymentPending =>
      'لم يكتمل الدفع بعد. تقدر تكمّل الدفع عشان طلبك يتبعت للمالك.';

  @override
  String get bookingMsgPaymentVerifying =>
      'نتحقق من عملية الدفع. قد يستغرق ذلك دقائق، وسنبلغك فور التأكيد.';

  @override
  String bookingMsgAwaitingOwner(String deadline) {
    return 'تم الدفع وأُرسل طلبك للمالك. المالك لديه حتى $deadline للرد. التواريخ محجوزة لك حتى ذلك الحين.';
  }

  @override
  String get bookingMsgAwaitingOwnerNoDeadline =>
      'تم الدفع وأُرسل طلبك للمالك. التواريخ محجوزة لك لحد ما يرد.';

  @override
  String get bookingMsgConfirmed => 'تم تأكيد حجزك!';

  @override
  String bookingMsgConfirmedWithRemaining(String amount) {
    return 'تم تأكيد حجزك! يجب سداد $amount قبل الاستلام.';
  }

  @override
  String get bookingMsgCheckedIn => 'نتمنى لك إقامة سعيدة.';

  @override
  String get bookingMsgCompleted => 'اكتملت إقامتك. شاركنا رأيك!';

  @override
  String bookingMsgRejected(String amount) {
    return 'اعتذر المالك عن قبول الطلب. سيتم رد كامل المبلغ ($amount). سيتواصل معك فريق OnAir وقد يقترح بديلًا إن رغبت.';
  }

  @override
  String bookingMsgExpired(String amount) {
    return 'لم يرد المالك خلال 24 ساعة. سيتم رد كامل المبلغ ($amount).';
  }

  @override
  String get bookingMsgCancelled => 'تم إلغاء الحجز.';

  @override
  String get bookingMsgNoShow =>
      'تم تسجيل عدم الحضور. للاستفسار تواصل مع الدعم.';

  @override
  String bookingMsgConflict(String amount) {
    return 'تم حجز هذه التواريخ قبل اكتمال دفعتك. سيتم رد المبلغ بالكامل ($amount).';
  }

  @override
  String get bookingMsgAbandoned => 'لم يكتمل الدفع ولم يُخصم أي مبلغ.';

  @override
  String get bookingMsgUnknown =>
      'فيه تحديث على حجزك. للاستفسار تواصل مع الدعم.';

  @override
  String get bookingCode => 'رقم الحجز';

  @override
  String get bookingCopyCode => 'نسخ رقم الحجز';

  @override
  String get bookingCodeCopied => 'تم نسخ رقم الحجز';

  @override
  String get bookingStayTitle => 'الإقامة';

  @override
  String get bookingArrival => 'الوصول';

  @override
  String get bookingDeparture => 'المغادرة';

  @override
  String get bookingCheckInTime => 'وقت الاستلام';

  @override
  String get bookingCheckOutTime => 'وقت المغادرة';

  @override
  String get bookingPaymentsTitle => 'المدفوعات';

  @override
  String get bookingPaid => 'المدفوع';

  @override
  String get paymentMethodCard => 'بطاقة / محفظة';

  @override
  String get paymentMethodCash => 'نقدًا';

  @override
  String get paymentLineSucceeded => 'تم';

  @override
  String get paymentLinePending => 'قيد التنفيذ';

  @override
  String get paymentLineFailed => 'لم يكتمل';

  @override
  String get bookingAddressTitle => 'العنوان';

  @override
  String get bookingArrivalInstructions => 'تعليمات الوصول';

  @override
  String get bookingSavedTermsTitle => 'الشروط وقت الحجز';

  @override
  String get bookingTimelineTitle => 'سجل الحجز';

  @override
  String get bookingEventGeneric => 'تحديث على الحجز';

  @override
  String get bookingContactSupport => 'تحتاج مساعدة؟ تواصل مع OnAir';

  @override
  String get refundChipRequested => 'تم طلب الاسترداد';

  @override
  String get refundChipInProgress => 'الاسترداد قيد التنفيذ';

  @override
  String get refundChipDone => 'تم رد المبلغ';

  @override
  String get refundChipProblem => 'مشكلة في الاسترداد';

  @override
  String get refundTitle => 'الاسترداد';

  @override
  String get refundAmount => 'مبلغ الاسترداد';

  @override
  String get refundStageRequested => 'طُلب';

  @override
  String get refundStageApproved => 'اعتُمد';

  @override
  String get refundStageExecuting => 'قيد التنفيذ';

  @override
  String get refundStageVerified => 'تم التحقق من وصوله';

  @override
  String get refundProblemHint =>
      'فيه مشكلة في الاسترداد. فريق OnAir بيتابعها، وتقدر تتواصل مع الدعم.';

  @override
  String get unfinishedPaymentBanner => 'عندك دفع لم يكتمل.';

  @override
  String get unfinishedPaymentOpen => 'عرض';

  @override
  String get quoteChangedNotice =>
      'السعر اتحدّث. راجع المبالغ الجديدة قبل الدفع.';

  @override
  String get quoteConfirmNew => 'أكّد المبالغ الجديدة';

  @override
  String get termsChangedNotice =>
      'الشروط اتحدّثت. راجعها ووافق عليها للمتابعة.';

  @override
  String get termsAcceptNew => 'أوافق على الشروط الجديدة';

  @override
  String get notificationsMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String get notificationsFilterAll => 'الكل';

  @override
  String get notificationsFilterBooking => 'الحجوزات';

  @override
  String get notificationsFilterPayment => 'المدفوعات';

  @override
  String get notificationsFilterOffers => 'العروض';

  @override
  String get notificationsFilterReplies => 'الردود';

  @override
  String get notificationsFilterHint => 'تصفية الإشعارات';

  @override
  String get notificationsFilterEmpty => 'مفيش إشعارات في القسم ده.';

  @override
  String get notificationsJustNow => 'دلوقتي';

  @override
  String notificationsMinutesAgo(int count) {
    return 'من $count د';
  }

  @override
  String notificationsHoursAgo(int count) {
    return 'من $count س';
  }

  @override
  String notificationsDaysAgo(int count) {
    return 'من $count أيام';
  }

  @override
  String notificationsWeeksAgo(int count) {
    return 'من $count أسابيع';
  }

  @override
  String get notificationsEmpty => 'مفيش إشعارات لسه.';

  @override
  String get notificationsOffNotice =>
      'الإشعارات مقفولة. فعّلها عشان تعرف فورًا لما المالك يرد.';

  @override
  String get notificationsOpenSettings => 'فتح الإعدادات';

  @override
  String get pushPermissionTitle => 'فعّل الإشعارات';

  @override
  String get pushPermissionBody => 'عشان تعرف فورًا لما المالك يرد على طلبك.';

  @override
  String get pushPermissionEnable => 'فعّل';

  @override
  String get pushPermissionLater => 'مش دلوقتي';

  @override
  String unreadBadge(String count) {
    return '$count إشعار غير مقروء';
  }

  @override
  String get notifBookingRequestReceivedTitle => 'تم الدفع وأُرسل طلبك';

  @override
  String get notifBookingRequestReceivedBody =>
      'المالك هيرد خلال 24 ساعة. اضغط للتفاصيل.';

  @override
  String get notifBookingConfirmedTitle => 'تم تأكيد حجزك';

  @override
  String get notifBookingConfirmedBody => 'اضغط للتفاصيل.';

  @override
  String get notifBookingRejectedTitle => 'المالك اعتذر عن الطلب';

  @override
  String get notifBookingRejectedBody =>
      'هيترد لك المبلغ بالكامل. اضغط للتفاصيل.';

  @override
  String get notifBookingExpiredTitle => 'المالك مردّش في المهلة';

  @override
  String get notifBookingExpiredBody =>
      'هيترد لك المبلغ بالكامل. اضغط للتفاصيل.';

  @override
  String get notifBookingPaymentConflictTitle => 'التواريخ اتحجزت قبل دفعتك';

  @override
  String get notifBookingPaymentConflictBody =>
      'هيترد لك المبلغ بالكامل. اضغط للتفاصيل.';

  @override
  String get notifBookingCancelledByGuestTitle => 'تم إلغاء حجزك';

  @override
  String get notifBookingCancelledByGuestBody => 'اضغط للتفاصيل.';

  @override
  String get notifBookingCancelledByPlatformTitle => 'OnAir ألغت الحجز';

  @override
  String get notifBookingCancelledByPlatformBody => 'اضغط للتفاصيل.';

  @override
  String get notifBookingReplacementOfferedTitle => 'عندك عرض بديل';

  @override
  String get notifBookingReplacementOfferedBody => 'اضغط لمراجعة العرض.';

  @override
  String get notifBookingNoShowRecordedTitle => 'تم تسجيل عدم الحضور';

  @override
  String get notifBookingNoShowRecordedBody => 'اضغط للتفاصيل.';

  @override
  String get notifBookingReopenedTitle => 'تم إعادة فتح الحجز';

  @override
  String get notifBookingReopenedBody => 'اضغط للتفاصيل.';

  @override
  String get notifPaymentFailedTitle => 'لم يكتمل الدفع';

  @override
  String get notifPaymentFailedBody => 'ولم يُخصم أي مبلغ.';

  @override
  String get notifPaymentRemainingDueTitle => 'تذكير بسداد المتبقي';

  @override
  String get notifPaymentRemainingDueBody => 'لازم يتسدد قبل الاستلام.';

  @override
  String get notifPaymentRemainingPaidTitle => 'تم سداد المتبقي';

  @override
  String get notifPaymentRemainingPaidBody => 'اضغط للتفاصيل.';

  @override
  String get notifCashConfirmationRequestedTitle => 'أكّد الدفع النقدي';

  @override
  String get notifCashConfirmationRequestedBody => 'الكود على بريدك.';

  @override
  String get notifCashPaymentConfirmedTitle => 'تم تأكيد الدفع النقدي';

  @override
  String get notifCashPaymentConfirmedBody => 'اضغط للإيصال.';

  @override
  String get notifStayCheckinReminderTitle => 'ميعاد وصولك قرّب';

  @override
  String get notifStayCheckinReminderBody => 'اضغط للتفاصيل.';

  @override
  String get notifStayCheckoutReminderTitle => 'ميعاد المغادرة قرّب';

  @override
  String get notifStayCheckoutReminderBody => 'اضغط للتفاصيل.';

  @override
  String get notifStayHostHandoverConfirmedTitle => 'المالك أكّد تسليم الشقة';

  @override
  String get notifStayHostHandoverConfirmedBody => 'أكّد استلامك من التطبيق.';

  @override
  String get notifStayCheckedInTitle => 'بدأت إقامتك';

  @override
  String get notifStayCheckedInBody => 'نتمنى لك إقامة سعيدة.';

  @override
  String get notifStayCompletedTitle => 'اكتملت إقامتك';

  @override
  String get notifStayCompletedBody => 'شاركنا رأيك!';

  @override
  String get notifDamageClaimOpenedTitle => 'فيه مطالبة على حجزك';

  @override
  String get notifDamageClaimOpenedBody => 'اضغط للمراجعة.';

  @override
  String get notifDamageResolvedTitle => 'تم البت في المطالبة';

  @override
  String get notifDamageResolvedBody => 'اضغط للتفاصيل.';

  @override
  String get notifRefundRequestedTitle => 'تم طلب الاسترداد';

  @override
  String get notifRefundRequestedBody => 'اضغط للتفاصيل.';

  @override
  String get notifRefundExecutedTitle => 'الاسترداد قيد التنفيذ';

  @override
  String get notifRefundExecutedBody => 'اضغط للتفاصيل.';

  @override
  String get notifRefundVerifiedTitle => 'تم رد المبلغ';

  @override
  String get notifRefundVerifiedBody => 'اضغط للتفاصيل.';

  @override
  String get notifSupportStaffRepliedTitle => 'رد جديد من خدمة العملاء';

  @override
  String get notifSupportStaffRepliedBody => 'اضغط للقراءة.';

  @override
  String get notifSupportCaseResolvedTitle => 'تم حل حالتك';

  @override
  String get notifSupportCaseResolvedBody => 'اضغط للتفاصيل.';

  @override
  String get notifReviewApprovedTitle => 'تم نشر تقييمك';

  @override
  String get notifReviewApprovedBody => 'شكرًا لمشاركتك.';

  @override
  String get notifReviewRejectedTitle => 'تقييمك مش هيتنشر';

  @override
  String get notifReviewRejectedBody => 'اضغط للتفاصيل.';

  @override
  String get notifAccountPhoneChangedTitle => 'تم تغيير رقم الموبايل';

  @override
  String get notifAccountPhoneChangedBody => 'لو مش انت، تواصل مع الدعم.';

  @override
  String get notifAccountPasswordChangedTitle => 'تم تغيير كلمة المرور';

  @override
  String get notifAccountPasswordChangedBody => 'لو مش انت، تواصل مع الدعم.';

  @override
  String get notifGenericTitle => 'عندك تحديث جديد';

  @override
  String get notifGenericBody => 'اضغط للتفاصيل.';

  @override
  String get stayCashNotAllowed => 'الدفع الكاش مش متاح للشقة دي.';

  @override
  String get stayCashAmountChanged =>
      'المبلغ المتبقي اتغير. راجع المبلغ الجديد.';

  @override
  String get stayRemainingNotPaid =>
      'لازم تسدد المبلغ المتبقي قبل استلام الشقة.';

  @override
  String get cancellationTermsChanged =>
      'مبلغ الاسترداد اتغير. راجع التفاصيل الجديدة.';

  @override
  String get claimAlreadyAnswered => 'المطالبة دي اتردّ عليها قبل كده.';

  @override
  String get offerNotAvailable => 'العرض ده مبقاش متاح.';

  @override
  String get stayNeedsConnection => 'الخطوة دي محتاجة اتصال بالإنترنت.';

  @override
  String get stayStepNotAvailable => 'الخطوة دي مش متاحة دلوقتي.';

  @override
  String get stayActionDone => 'تمام، اتسجّل.';

  @override
  String get dialogConfirm => 'تأكيد';

  @override
  String get dialogBack => 'رجوع';

  @override
  String get actionPayRemaining => 'ادفع المبلغ المتبقي';

  @override
  String get actionConfirmCash => 'تأكيد دفع كاش';

  @override
  String get actionCancelBooking => 'إلغاء الحجز';

  @override
  String get actionConfirmCheckin => 'استلمت الشقة';

  @override
  String get actionConfirmCheckout => 'غادرت الشقة';

  @override
  String get actionRespondClaim => 'الرد على المطالبة';

  @override
  String bookingNeedsAction(String action) {
    return 'مطلوب منك: $action';
  }

  @override
  String get bookingMsgWaitingHandover =>
      'أكّدت استلامك. مستنيين المالك يأكّد تسليم الشقة.';

  @override
  String get bookingMsgHostHandedOver =>
      'المالك أكّد تسليم الشقة. أكّد إنك استلمتها.';

  @override
  String get bookingMsgWaitingCheckout =>
      'أكّدت مغادرتك. مستنيين المالك يأكّد استلام الشقة.';

  @override
  String get bookingMsgCancelledByGuest => 'لغيت الحجز. تفاصيل الاسترداد تحت.';

  @override
  String get bookingMsgCancelledByPlatform =>
      'OnAir لغت الحجز. تفاصيل الاسترداد تحت.';

  @override
  String get bookingMsgReopened =>
      'حجزك اتفتح تاني. كمّل سداد المتبقي قبل الاستلام.';

  @override
  String get ackTitleCheckin => 'تسليم الشقة';

  @override
  String get ackTitleCheckout => 'مغادرة الشقة';

  @override
  String get ackYou => 'أنت';

  @override
  String get ackOwner => 'المالك';

  @override
  String ackConfirmedAt(String time) {
    return 'أكّد $time';
  }

  @override
  String get ackWaiting => 'مستني التأكيد';

  @override
  String get ackKeyLeftSafe => 'المفتاح اتساب في المكان المتفق عليه';

  @override
  String get checkinSheetTitle => 'استلمت الشقة فعلًا؟';

  @override
  String get checkinSheetBody => 'أكّد بس لو استلمت الشقة والمفاتيح.';

  @override
  String get checkinSheetConfirm => 'أيوه، استلمتها';

  @override
  String get checkoutSheetTitle => 'غادرت الشقة؟';

  @override
  String get checkoutSheetBody => 'أكّد بعد ما تسيب الشقة وتسلّم المفاتيح.';

  @override
  String get checkoutSheetConfirm => 'أيوه، غادرت';

  @override
  String get sheetNotYet => 'لسه';

  @override
  String get checkinProblem => 'عندي مشكلة في الاستلام';

  @override
  String get remainingTitle => 'سداد المتبقي';

  @override
  String get remainingNote => 'لازم تسدد المتبقي قبل ما تستلم الشقة.';

  @override
  String get remainingDueLabel => 'آخر ميعاد للسداد';

  @override
  String get remainingChooseMethod => 'هتدفع إزاي؟';

  @override
  String get remainingOptionOnline => 'ادفع أونلاين';

  @override
  String get remainingOptionCash => 'دفعت أو هدفع كاش';

  @override
  String remainingPayButton(String amount) {
    return 'ادفع $amount';
  }

  @override
  String get remainingCashButton => 'كمّل تأكيد الكاش';

  @override
  String get remainingPaidTitle => 'تم سداد المتبقي';

  @override
  String get remainingPaidBody => 'حجزك مدفوع بالكامل دلوقتي.';

  @override
  String get remainingFailedBody =>
      'الدفع ما كملش ومفيش أي مبلغ اتخصم. تقدر تحاول تاني.';

  @override
  String get cashTitle => 'تأكيد دفع كاش';

  @override
  String get cashAmountLabel => 'المبلغ';

  @override
  String get cashAmountLocked => 'المبلغ ثابت ومش ممكن يتغير';

  @override
  String get cashPhoneLabel => 'رقم موبايل اللي استلم الفلوس';

  @override
  String get cashPhoneHint => '01xxxxxxxxx';

  @override
  String get cashPhoneInvalid => 'اكتب رقم موبايل مصري صحيح.';

  @override
  String get cashWarning => 'متسلّمش فلوس غير لشخص مفوّض من OnAir.';

  @override
  String get cashSendCode => 'ابعت الكود على بريدي';

  @override
  String cashCodeSent(String email) {
    return 'بعتنا كود على $email';
  }

  @override
  String get cashCollectorLabel => 'المستلم';

  @override
  String cashStatement(String amount, String name) {
    return 'أؤكد إني سلّمت $amount كاش لـ $name';
  }

  @override
  String get cashResend => 'ابعت الكود تاني';

  @override
  String cashResendIn(String time) {
    return 'ابعت تاني بعد $time';
  }

  @override
  String get cashConfirmButton => 'أكّد الدفع';

  @override
  String get cashContactSupport => 'كلّم الدعم';

  @override
  String get receiptTitle => 'تم تأكيد الدفع الكاش';

  @override
  String get receiptNumber => 'رقم الإيصال';

  @override
  String get receiptDate => 'التاريخ';

  @override
  String get receiptBack => 'رجوع للحجز';

  @override
  String get receiptShow => 'عرض الإيصال';

  @override
  String get receiptCopied => 'اتنسخ رقم الإيصال';

  @override
  String get cancelTitle => 'إلغاء الحجز';

  @override
  String get cancelRefund => 'هيترجعلك';

  @override
  String get cancelNonRefundable => 'مش هيترجع';

  @override
  String cancelReasonFree(String amount) {
    return 'الإلغاء مجاني. هيترجعلك المبلغ كله ($amount).';
  }

  @override
  String cancelReasonDepositLost(String refund, String deposit, String date) {
    return 'هيترجعلك $refund. العربون $deposit مش هيترجع لأن ميعاد الإلغاء المجاني خلص يوم $date.';
  }

  @override
  String cancelReasonDepositLostNoDate(String refund, String deposit) {
    return 'هيترجعلك $refund. العربون $deposit مش هيترجع لأن ميعاد الإلغاء المجاني خلص.';
  }

  @override
  String get cancelReasonNoRefund =>
      'مفيش استرداد، لأن الحجز مدفوع بالكامل وعدّى أكتر من 24 ساعة على ميعاد الاستلام.';

  @override
  String get cancelReasonTitle => 'سبب الإلغاء (اختياري)';

  @override
  String get cancelReasonChangeOfPlans => 'خططي اتغيرت';

  @override
  String get cancelReasonFoundOther => 'لقيت مكان تاني';

  @override
  String get cancelReasonTravelProblem => 'مشكلة في السفر';

  @override
  String get cancelReasonOther => 'سبب تاني';

  @override
  String get cancelReasonOtherHint => 'اكتب السبب';

  @override
  String get cancelKeep => 'خليني محتفظ بالحجز';

  @override
  String get cancelDialogTitle => 'متأكد إنك عايز تلغي؟';

  @override
  String cancelDialogBody(String amount) {
    return 'هيترجعلك $amount.';
  }

  @override
  String get cancelDialogConfirm => 'أيوه، ألغي';

  @override
  String get claimTitle => 'مطالبة ضرر';

  @override
  String get claimsSectionTitle => 'مطالبات الضرر';

  @override
  String get claimProtection =>
      'مفيش أي مبلغ هيتخصم من غير موافقتك أو قرار من OnAir.';

  @override
  String get claimAmount => 'المبلغ المطلوب';

  @override
  String get claimEvidence => 'الصور';

  @override
  String claimEvidencePhoto(String index, String count) {
    return 'صورة $index من $count';
  }

  @override
  String get claimPhotoFailed => 'الصورة ما اتحملتش. اضغط للمحاولة تاني.';

  @override
  String get claimAgree => 'موافق';

  @override
  String get claimDispute => 'معترض';

  @override
  String get claimAgreeDialogTitle => 'توافق على المطالبة؟';

  @override
  String claimAgreeDialogBody(String amount) {
    return 'انت موافق على مبلغ $amount.';
  }

  @override
  String get claimDisputeReason => 'سبب الاعتراض';

  @override
  String get claimDisputeReasonHint => 'اكتب اللي حصل بالتفصيل';

  @override
  String get claimDisputeTooShort => 'اكتب 10 حروف على الأقل.';

  @override
  String get claimDisputeSend => 'ابعت الاعتراض';

  @override
  String claimCaseNumber(String number) {
    return 'رقم الحالة: $number';
  }

  @override
  String get claimYourAnswer => 'ردك';

  @override
  String get claimStatusOpen => 'مستنية ردك';

  @override
  String get claimStatusAccepted => 'وافقت';

  @override
  String get claimStatusDisputed => 'اعترضت';

  @override
  String get claimStatusMediation => 'عند OnAir للمراجعة';

  @override
  String get claimStatusResolved => 'اتقفلت';

  @override
  String get claimStatusWithdrawn => 'اتسحبت';

  @override
  String get claimStatusUnknown => 'فيه تحديث';

  @override
  String claimOutcomeGuestPays(String amount) {
    return 'القرار: تدفع $amount.';
  }

  @override
  String claimOutcomePartial(String amount) {
    return 'القرار: تدفع جزء من المبلغ ($amount).';
  }

  @override
  String get claimOutcomeNoCharge => 'القرار: مفيش أي مبلغ عليك.';

  @override
  String get claimOutcomeWithdrawn => 'المالك سحب المطالبة.';

  @override
  String get offerTitle => 'عرض بديل من OnAir';

  @override
  String offerPayMore(String amount) {
    return 'هتدفع $amount زيادة.';
  }

  @override
  String offerRefundDiff(String amount) {
    return 'هيترجعلك $amount.';
  }

  @override
  String get offerNoDiff => 'مفيش فرق في السعر.';

  @override
  String offerExpires(String time) {
    return 'رد قبل $time';
  }

  @override
  String get offerAccept => 'موافق على العرض';

  @override
  String get offerDecline => 'لا، عايز استرداد فلوسي';

  @override
  String get offerAcceptDialogTitle => 'توافق على العرض البديل؟';

  @override
  String get offerDeclineDialogTitle => 'ترفض العرض البديل؟';

  @override
  String get offerDeclineDialogBody => 'الاسترداد هيكمل زي ما هو.';

  @override
  String get offerStatusAccepted => 'وافقت على العرض';

  @override
  String get offerStatusDeclined => 'رفضت العرض';

  @override
  String get offerStatusExpired => 'العرض انتهى';

  @override
  String get mockToolsTitle => 'أدوات المحاكاة';

  @override
  String get mockOwnerHandover => 'المالك أكّد التسليم';

  @override
  String get mockOwnerCheckout => 'المالك أكّد الاستلام';

  @override
  String get mockOwnerCheckoutKey =>
      'المالك أكّد الاستلام (المفتاح في مكان آمن)';

  @override
  String get mockCollectorCash => 'المحصّل سجّل كاش';

  @override
  String get mockOpenClaim => 'فتح مطالبة';

  @override
  String get mockAdvanceRefund => 'تقديم مرحلة الاسترداد';

  @override
  String get mockChangeTerms => 'تغيير شروط الإلغاء مرة';

  @override
  String get offerDates => 'التواريخ';

  @override
  String placeAreaCity(String area, String city) {
    return '$area، $city';
  }
}
