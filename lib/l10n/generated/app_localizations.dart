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
