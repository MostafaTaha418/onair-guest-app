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
      'المحصّل غير مفوّض. تواصل مع خدمة العملاء.';

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
  String get homeSuggestedTitle => 'شقق مقترحة';

  @override
  String get homeNewestTitle => 'أحدث الشقق';

  @override
  String get homeUpcomingTitle => 'حجزك الجاي';

  @override
  String get homeUpcomingConfirmed => 'حجز مؤكد';

  @override
  String get homeEmpty => 'مفيش شقق متاحة دلوقتي.';

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
  String get bookingEntryTitle => 'الحجز';

  @override
  String get bookingEntryComingSoon => 'الحجز من التطبيق هيتفتح قريب.';

  @override
  String get bookingEntryTermsCarried => 'الشروط اللي شفتها اتسجّلت مع الطلب.';

  @override
  String get supportEntryTitle => 'تواصل مع OnAir';

  @override
  String get supportEntryComingSoon => 'خدمة الدعم من التطبيق هتتفتح قريب.';
}
