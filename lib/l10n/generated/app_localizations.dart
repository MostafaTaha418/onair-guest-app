import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'OnAir'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @bookings.
  ///
  /// In ar, this message translates to:
  /// **'حجوزاتي'**
  String get bookings;

  /// No description provided for @favorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get favorites;

  /// No description provided for @account.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get account;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيك'**
  String get welcome;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get seeAll;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get retry;

  /// No description provided for @emptyState.
  ///
  /// In ar, this message translates to:
  /// **'مفيش بيانات لعرضها دلوقتي.'**
  String get emptyState;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل'**
  String get loading;

  /// No description provided for @offline.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالإنترنت.'**
  String get offline;

  /// No description provided for @referenceNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم المرجع: {ref}'**
  String referenceNumber(String ref);

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @phoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get phoneNumber;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @verificationCode.
  ///
  /// In ar, this message translates to:
  /// **'كود التأكيد'**
  String get verificationCode;

  /// No description provided for @sendCode.
  ///
  /// In ar, this message translates to:
  /// **'ابعت الكود'**
  String get sendCode;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @errorUnauthenticated.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة. سجّل الدخول مرة أخرى.'**
  String get errorUnauthenticated;

  /// No description provided for @authPhoneCountryNotSupported.
  ///
  /// In ar, this message translates to:
  /// **'حاليًا ندعم أرقام الموبايل المصرية فقط. تقدر تسجّل بالبريد الإلكتروني.'**
  String get authPhoneCountryNotSupported;

  /// No description provided for @authOtpInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير صحيح. راجع الرسالة وجرّب تاني.'**
  String get authOtpInvalid;

  /// No description provided for @authOtpExpired.
  ///
  /// In ar, this message translates to:
  /// **'الكود انتهت صلاحيته. اطلب كود جديد.'**
  String get authOtpExpired;

  /// No description provided for @authRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كتير. جرّب تاني بعد {time}.'**
  String authRateLimited(String time);

  /// No description provided for @errorValidationFailed.
  ///
  /// In ar, this message translates to:
  /// **'راجع البيانات المكتوبة.'**
  String get errorValidationFailed;

  /// No description provided for @authTermsChanged.
  ///
  /// In ar, this message translates to:
  /// **'الشروط اتحدّثت. راجعها ووافق عليها للمتابعة.'**
  String get authTermsChanged;

  /// No description provided for @authProfileIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'كمّل بياناتك للمتابعة.'**
  String get authProfileIncomplete;

  /// No description provided for @appUpdateRequired.
  ///
  /// In ar, this message translates to:
  /// **'لازم تحدّث التطبيق للمتابعة.'**
  String get appUpdateRequired;

  /// No description provided for @bookingPhoneNotVerified.
  ///
  /// In ar, this message translates to:
  /// **'أكّد رقم موبايلك قبل الحجز.'**
  String get bookingPhoneNotVerified;

  /// No description provided for @bookingEmailNotVerified.
  ///
  /// In ar, this message translates to:
  /// **'أكّد بريدك قبل الحجز.'**
  String get bookingEmailNotVerified;

  /// No description provided for @bookingDatesUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ دي مش متاحة.'**
  String get bookingDatesUnavailable;

  /// No description provided for @bookingGuestsExceeded.
  ///
  /// In ar, this message translates to:
  /// **'عدد الضيوف أكبر من المسموح.'**
  String get bookingGuestsExceeded;

  /// No description provided for @bookingQuoteExpired.
  ///
  /// In ar, this message translates to:
  /// **'السعر اتحدّث. راجع الملخص من جديد.'**
  String get bookingQuoteExpired;

  /// No description provided for @propertyNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الشقة دي مش متاحة حاليًا.'**
  String get propertyNotAvailable;

  /// No description provided for @errorActionNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء ده مش متاح دلوقتي.'**
  String get errorActionNotAllowed;

  /// No description provided for @stayCollectorNotAuthorized.
  ///
  /// In ar, this message translates to:
  /// **'المحصّل غير مفوّض. تواصل مع خدمة العملاء.'**
  String get stayCollectorNotAuthorized;

  /// No description provided for @errorUnexpected.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة غير متوقعة. رقم المرجع: {ref}'**
  String errorUnexpected(String ref);

  /// No description provided for @errorNoConnection.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالإنترنت.'**
  String get errorNoConnection;

  /// No description provided for @errorCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء العملية.'**
  String get errorCancelled;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد أو كلمة المرور غير صحيحة.'**
  String get authInvalidCredentials;

  /// No description provided for @authCodeSent.
  ///
  /// In ar, this message translates to:
  /// **'بعتنا لك كود التأكيد.'**
  String get authCodeSent;

  /// No description provided for @authRecoverySent.
  ///
  /// In ar, this message translates to:
  /// **'لو البريد مسجّل، هتوصلك رسالة الاستعادة.'**
  String get authRecoverySent;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @notAvailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح حاليًا'**
  String get notAvailable;

  /// No description provided for @searchEmpty.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ البحث عن مكان إقامتك.'**
  String get searchEmpty;

  /// No description provided for @bookingsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'حجوزاتك هتظهر هنا.'**
  String get bookingsEmpty;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'الأماكن المفضلة هتظهر هنا.'**
  String get favoritesEmpty;

  /// No description provided for @accountEmpty.
  ///
  /// In ar, this message translates to:
  /// **'بيانات حسابك هتظهر هنا.'**
  String get accountEmpty;

  /// No description provided for @authLoginTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بيك في OnAir'**
  String get authLoginTitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابك'**
  String get authRegisterTitle;

  /// No description provided for @authPhoneHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 01012345678'**
  String get authPhoneHint;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم موبايل مصري صحيح من 11 رقم.'**
  String get authPhoneInvalid;

  /// No description provided for @authPhoneTab.
  ///
  /// In ar, this message translates to:
  /// **'الموبايل'**
  String get authPhoneTab;

  /// No description provided for @authEmailTab.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmailTab;

  /// No description provided for @authEmailComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل بالبريد الإلكتروني هيتاح قريبًا.'**
  String get authEmailComingSoon;

  /// No description provided for @authTermsPrefix.
  ///
  /// In ar, this message translates to:
  /// **'بالمتابعة أنت توافق على'**
  String get authTermsPrefix;

  /// No description provided for @terms.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacy;

  /// No description provided for @authNoAccount.
  ///
  /// In ar, this message translates to:
  /// **'لسه معندكش حساب؟'**
  String get authNoAccount;

  /// No description provided for @authHasAccount.
  ///
  /// In ar, this message translates to:
  /// **'عندك حساب بالفعل؟'**
  String get authHasAccount;

  /// No description provided for @authCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authCreateAccount;

  /// No description provided for @authCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كود التأكيد'**
  String get authCodeTitle;

  /// No description provided for @authCodeDescription.
  ///
  /// In ar, this message translates to:
  /// **'بعتنا كود من 6 أرقام إلى {phone}'**
  String authCodeDescription(String phone);

  /// No description provided for @authResend.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الكود'**
  String get authResend;

  /// No description provided for @authResendIn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال بعد {time}'**
  String authResendIn(String time);

  /// No description provided for @authChangePhone.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رقم الموبايل'**
  String get authChangePhone;

  /// No description provided for @authCompleteProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'كمّل بياناتك'**
  String get authCompleteProfileTitle;

  /// No description provided for @authNameInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الاسم لازم يكون من حرفين إلى 80 حرف.'**
  String get authNameInvalid;

  /// No description provided for @authAcceptTerms.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على الشروط والأحكام وسياسة الخصوصية'**
  String get authAcceptTerms;

  /// No description provided for @authTermsRequired.
  ///
  /// In ar, this message translates to:
  /// **'لازم توافق على الشروط للمتابعة.'**
  String get authTermsRequired;

  /// No description provided for @authWaitSeconds.
  ///
  /// In ar, this message translates to:
  /// **'{seconds} ثانية'**
  String authWaitSeconds(int seconds);

  /// No description provided for @authEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بريد إلكتروني صحيح.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRule.
  ///
  /// In ar, this message translates to:
  /// **'8 أحرف على الأقل، بينهم حرف ورقم'**
  String get authPasswordRule;

  /// No description provided for @authPasswordWeak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيفة'**
  String get authPasswordWeak;

  /// No description provided for @authPasswordMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get authPasswordMedium;

  /// No description provided for @authPasswordStrong.
  ///
  /// In ar, this message translates to:
  /// **'قوية'**
  String get authPasswordStrong;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get authForgotPassword;

  /// No description provided for @authRecoveryTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get authRecoveryTitle;

  /// No description provided for @authRecoveryDescription.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بريدك وسنبعت لك كود الاستعادة.'**
  String get authRecoveryDescription;

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور جديدة'**
  String get authNewPasswordTitle;

  /// No description provided for @authNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كلمة المرور'**
  String get authNewPassword;

  /// No description provided for @authChangeEmail.
  ///
  /// In ar, this message translates to:
  /// **'تغيير البريد الإلكتروني'**
  String get authChangeEmail;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In ar, this message translates to:
  /// **'غير مؤكد'**
  String get authEmailNotVerified;

  /// No description provided for @authVerifyNow.
  ///
  /// In ar, this message translates to:
  /// **'أكد الآن'**
  String get authVerifyNow;

  /// No description provided for @authEmailStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة البريد الإلكتروني'**
  String get authEmailStatus;

  /// No description provided for @authSignUpWithEmail.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب بالبريد'**
  String get authSignUpWithEmail;

  /// No description provided for @authSignInWithEmail.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول بالبريد'**
  String get authSignInWithEmail;

  /// No description provided for @authClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get authClose;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
