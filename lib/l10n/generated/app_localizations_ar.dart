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
}
