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
}
