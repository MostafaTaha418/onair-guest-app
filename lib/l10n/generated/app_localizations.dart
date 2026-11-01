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

  /// No description provided for @errorUnexpectedNoRef.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة غير متوقعة. جرّب تاني.'**
  String get errorUnexpectedNoRef;

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

  /// Title of the blocking update-required screen.
  ///
  /// In ar, this message translates to:
  /// **'تحديث مطلوب'**
  String get updateRequiredTitle;

  /// Button on the update-required screen that opens the store listing.
  ///
  /// In ar, this message translates to:
  /// **'حدّث التطبيق'**
  String get updateRequiredStoreButton;

  /// No description provided for @homeHello.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا'**
  String get homeHello;

  /// No description provided for @homeSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على شقة: المكان، التاريخ، الضيوف'**
  String get homeSearchHint;

  /// No description provided for @homeAreasTitle.
  ///
  /// In ar, this message translates to:
  /// **'مناطق ووجهات'**
  String get homeAreasTitle;

  /// No description provided for @homeSuggestedTitle.
  ///
  /// In ar, this message translates to:
  /// **'شقق مقترحة'**
  String get homeSuggestedTitle;

  /// No description provided for @homeNewestTitle.
  ///
  /// In ar, this message translates to:
  /// **'أحدث الشقق'**
  String get homeNewestTitle;

  /// No description provided for @homeUpcomingTitle.
  ///
  /// In ar, this message translates to:
  /// **'حجزك الجاي'**
  String get homeUpcomingTitle;

  /// No description provided for @homeUpcomingConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'حجز مؤكد'**
  String get homeUpcomingConfirmed;

  /// No description provided for @homeEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش شقق متاحة دلوقتي.'**
  String get homeEmpty;

  /// No description provided for @homeEmptyAction.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن شقة'**
  String get homeEmptyAction;

  /// No description provided for @areaListingCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش شقق} =1{شقة واحدة} =2{شقتين} few{{count} شقق} many{{count} شقة} other{{count} شقة}}'**
  String areaListingCount(int count);

  /// No description provided for @searchTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get searchTitle;

  /// No description provided for @searchLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get searchLocationLabel;

  /// No description provided for @searchLocationHint.
  ///
  /// In ar, this message translates to:
  /// **'محافظة، مدينة أو منطقة'**
  String get searchLocationHint;

  /// No description provided for @searchAnyLocation.
  ///
  /// In ar, this message translates to:
  /// **'كل الأماكن'**
  String get searchAnyLocation;

  /// No description provided for @searchNoLocationMatches.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أماكن بالاسم ده.'**
  String get searchNoLocationMatches;

  /// No description provided for @searchDatesLabel.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ'**
  String get searchDatesLabel;

  /// No description provided for @searchDatesHint.
  ///
  /// In ar, this message translates to:
  /// **'الوصول والمغادرة'**
  String get searchDatesHint;

  /// No description provided for @searchGuestsLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد الضيوف'**
  String get searchGuestsLabel;

  /// No description provided for @searchGuestsAny.
  ///
  /// In ar, this message translates to:
  /// **'أي عدد'**
  String get searchGuestsAny;

  /// No description provided for @searchAction.
  ///
  /// In ar, this message translates to:
  /// **'ابحث'**
  String get searchAction;

  /// No description provided for @searchFilters.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get searchFilters;

  /// No description provided for @searchClearAll.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get searchClearAll;

  /// No description provided for @searchShowResults.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش نتايج} =1{عرض نتيجة واحدة} =2{عرض نتيجتين} other{عرض {count} نتيجة}}'**
  String searchShowResults(int count);

  /// No description provided for @searchShowResultsUnknown.
  ///
  /// In ar, this message translates to:
  /// **'عرض النتايج'**
  String get searchShowResultsUnknown;

  /// No description provided for @searchPriceRange.
  ///
  /// In ar, this message translates to:
  /// **'سعر الليلة'**
  String get searchPriceRange;

  /// No description provided for @searchMinBedrooms.
  ///
  /// In ar, this message translates to:
  /// **'أقل عدد غرف'**
  String get searchMinBedrooms;

  /// No description provided for @searchMinBathrooms.
  ///
  /// In ar, this message translates to:
  /// **'أقل عدد حمامات'**
  String get searchMinBathrooms;

  /// No description provided for @searchAnyCount.
  ///
  /// In ar, this message translates to:
  /// **'أي عدد'**
  String get searchAnyCount;

  /// No description provided for @searchAmenities.
  ///
  /// In ar, this message translates to:
  /// **'المرافق والمميزات'**
  String get searchAmenities;

  /// No description provided for @searchPropertyType.
  ///
  /// In ar, this message translates to:
  /// **'نوع العقار'**
  String get searchPropertyType;

  /// No description provided for @searchSort.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get searchSort;

  /// No description provided for @sortPriceAsc.
  ///
  /// In ar, this message translates to:
  /// **'السعر: من الأقل'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In ar, this message translates to:
  /// **'السعر: من الأعلى'**
  String get sortPriceDesc;

  /// No description provided for @sortNewest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get sortNewest;

  /// No description provided for @searchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'مفيش شقق متاحة بالمعايير دي.'**
  String get searchNoResults;

  /// No description provided for @searchNoResultsHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تغيّر التواريخ أو الفلاتر.'**
  String get searchNoResultsHint;

  /// No description provided for @searchDatesNeededHint.
  ///
  /// In ar, this message translates to:
  /// **'اختار التواريخ عشان تقدر تحجز.'**
  String get searchDatesNeededHint;

  /// No description provided for @searchDatesDropped.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ اللي في الرابط فاتت. اختار تواريخ جديدة.'**
  String get searchDatesDropped;

  /// No description provided for @searchChooseDates.
  ///
  /// In ar, this message translates to:
  /// **'اختار التواريخ'**
  String get searchChooseDates;

  /// No description provided for @searchShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة البحث'**
  String get searchShare;

  /// No description provided for @shareSearchText.
  ///
  /// In ar, this message translates to:
  /// **'بحث على OnAir'**
  String get shareSearchText;

  /// No description provided for @nightlyPrice.
  ///
  /// In ar, this message translates to:
  /// **'{price} / الليلة'**
  String nightlyPrice(String price);

  /// No description provided for @stayTotal.
  ///
  /// In ar, this message translates to:
  /// **'{nights, plural, =1{إجمالي ليلة واحدة: {total}} =2{إجمالي ليلتين: {total}} few{إجمالي {nights} ليالي: {total}} other{إجمالي {nights} ليلة: {total}}}'**
  String stayTotal(int nights, String total);

  /// No description provided for @filterChipRemove.
  ///
  /// In ar, this message translates to:
  /// **'شيل فلتر {label}'**
  String filterChipRemove(String label);

  /// No description provided for @bedroomsAtLeast.
  ///
  /// In ar, this message translates to:
  /// **'{count}+ غرف'**
  String bedroomsAtLeast(int count);

  /// No description provided for @bathroomsAtLeast.
  ///
  /// In ar, this message translates to:
  /// **'{count}+ حمامات'**
  String bathroomsAtLeast(int count);

  /// No description provided for @priceRangeChip.
  ///
  /// In ar, this message translates to:
  /// **'{min} – {max}'**
  String priceRangeChip(String min, String max);

  /// No description provided for @guestsDecrease.
  ///
  /// In ar, this message translates to:
  /// **'قلّل عدد الضيوف'**
  String get guestsDecrease;

  /// No description provided for @guestsIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زوّد عدد الضيوف'**
  String get guestsIncrease;

  /// No description provided for @countDecrease.
  ///
  /// In ar, this message translates to:
  /// **'قلّل'**
  String get countDecrease;

  /// No description provided for @countIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زوّد'**
  String get countIncrease;

  /// No description provided for @calendarConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get calendarConfirm;

  /// No description provided for @calendarClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get calendarClear;

  /// No description provided for @calendarPrevMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر اللي فات'**
  String get calendarPrevMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر الجاي'**
  String get calendarNextMonth;

  /// No description provided for @calendarRangeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الفترة دي فيها ليالي مش متاحة.'**
  String get calendarRangeInvalid;

  /// No description provided for @calendarRangeNotLoaded.
  ///
  /// In ar, this message translates to:
  /// **'التوافر لسه بيتحمّل لشهر من الفترة دي. حاول تاني بعد لحظات.'**
  String get calendarRangeNotLoaded;

  /// No description provided for @calendarRangeLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل التوافر لشهر من الفترة دي. افتح الشهر ده واضغط إعادة المحاولة.'**
  String get calendarRangeLoadFailed;

  /// No description provided for @calendarNightsSelected.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{ليلة واحدة} =2{ليلتين} few{{count} ليالي} other{{count} ليلة}}'**
  String calendarNightsSelected(int count);

  /// No description provided for @calendarUnavailableDay.
  ///
  /// In ar, this message translates to:
  /// **'{date}، مش متاح'**
  String calendarUnavailableDay(String date);

  /// No description provided for @propertyBedrooms.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{غرفة واحدة} =2{غرفتين} few{{count} غرف} other{{count} غرفة}}'**
  String propertyBedrooms(int count);

  /// No description provided for @propertyBathrooms.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{حمام واحد} =2{حمامين} few{{count} حمامات} other{{count} حمام}}'**
  String propertyBathrooms(int count);

  /// No description provided for @propertyMaxGuests.
  ///
  /// In ar, this message translates to:
  /// **'لحد {count} ضيوف'**
  String propertyMaxGuests(int count);

  /// No description provided for @propertyArea.
  ///
  /// In ar, this message translates to:
  /// **'{sqm} م²'**
  String propertyArea(int sqm);

  /// No description provided for @propertyDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get propertyDescription;

  /// No description provided for @showMore.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In ar, this message translates to:
  /// **'عرض أقل'**
  String get showLess;

  /// No description provided for @propertyAmenities.
  ///
  /// In ar, this message translates to:
  /// **'المرافق'**
  String get propertyAmenities;

  /// No description provided for @propertySeeAllAmenities.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل المرافق'**
  String get propertySeeAllAmenities;

  /// No description provided for @propertyLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get propertyLocation;

  /// No description provided for @propertyRules.
  ///
  /// In ar, this message translates to:
  /// **'قواعد الإقامة'**
  String get propertyRules;

  /// No description provided for @rulesCheckIn.
  ///
  /// In ar, this message translates to:
  /// **'الاستلام من {time}'**
  String rulesCheckIn(String time);

  /// No description provided for @rulesCheckOut.
  ///
  /// In ar, this message translates to:
  /// **'المغادرة لحد {time}'**
  String rulesCheckOut(String time);

  /// No description provided for @rulesVisitorsAllowed.
  ///
  /// In ar, this message translates to:
  /// **'الزوار مسموحين (لحد {count})'**
  String rulesVisitorsAllowed(int count);

  /// No description provided for @rulesVisitorsAllowedNoLimit.
  ///
  /// In ar, this message translates to:
  /// **'الزوار مسموحين'**
  String get rulesVisitorsAllowedNoLimit;

  /// No description provided for @rulesVisitorsNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'الزوار مش مسموحين'**
  String get rulesVisitorsNotAllowed;

  /// No description provided for @propertyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'العربون والإلغاء'**
  String get propertyPolicy;

  /// No description provided for @policyDepositPercent.
  ///
  /// In ar, this message translates to:
  /// **'العربون {percent}% من إجمالي الحجز.'**
  String policyDepositPercent(String percent);

  /// No description provided for @policyDepositFixed.
  ///
  /// In ar, this message translates to:
  /// **'العربون {amount}.'**
  String policyDepositFixed(String amount);

  /// No description provided for @policyDepositFull.
  ///
  /// In ar, this message translates to:
  /// **'الحجز ده بيتدفع بالكامل مقدمًا.'**
  String get policyDepositFull;

  /// No description provided for @policyFreeCancellation.
  ///
  /// In ar, this message translates to:
  /// **'الإلغاء مجاني لحد {hours} ساعة قبل ميعاد الاستلام، وبيرجعلك المبلغ كامل.'**
  String policyFreeCancellation(int hours);

  /// No description provided for @policyAfterDeadline.
  ///
  /// In ar, this message translates to:
  /// **'لو لغيت بعد الميعاد ده وقبل الإقامة، بتخسر العربون بس ويرجعلك الباقي.'**
  String get policyAfterDeadline;

  /// No description provided for @policyFullyPaidLate.
  ///
  /// In ar, this message translates to:
  /// **'لو الحجز مدفوع بالكامل وألغيته بعد 24 ساعة من ميعاد الاستلام، المبلغ مش بيرجع.'**
  String get policyFullyPaidLate;

  /// No description provided for @propertyAvailability.
  ///
  /// In ar, this message translates to:
  /// **'التوافر'**
  String get propertyAvailability;

  /// No description provided for @propertyReviews.
  ///
  /// In ar, this message translates to:
  /// **'التقييمات'**
  String get propertyReviews;

  /// No description provided for @reviewsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{تقييم واحد} =2{تقييمين} few{{count} تقييمات} other{{count} تقييم}}'**
  String reviewsCount(int count);

  /// No description provided for @reviewsNone.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش تقييمات.'**
  String get reviewsNone;

  /// No description provided for @reviewsSeeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل التقييمات'**
  String get reviewsSeeAll;

  /// No description provided for @ratingSemantics.
  ///
  /// In ar, this message translates to:
  /// **'التقييم {rating} من 5، {count} تقييم'**
  String ratingSemantics(String rating, int count);

  /// No description provided for @propertyContactOnAir.
  ///
  /// In ar, this message translates to:
  /// **'عندك سؤال؟ تواصل مع OnAir'**
  String get propertyContactOnAir;

  /// No description provided for @bookNow.
  ///
  /// In ar, this message translates to:
  /// **'احجز الآن'**
  String get bookNow;

  /// No description provided for @propertyTermsUpdated.
  ///
  /// In ar, this message translates to:
  /// **'الشروط اتحدّثت. راجعها قبل ما تحجز.'**
  String get propertyTermsUpdated;

  /// No description provided for @propertyShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get propertyShare;

  /// No description provided for @galleryOpen.
  ///
  /// In ar, this message translates to:
  /// **'افتح الصور'**
  String get galleryOpen;

  /// No description provided for @galleryClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get galleryClose;

  /// No description provided for @galleryPhotoPosition.
  ///
  /// In ar, this message translates to:
  /// **'صورة {current} من {total}'**
  String galleryPhotoPosition(int current, int total);

  /// No description provided for @galleryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش صور للشقة دي.'**
  String get galleryEmpty;

  /// No description provided for @supportEntryTitle.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع OnAir'**
  String get supportEntryTitle;

  /// No description provided for @supportEntryComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الدعم من التطبيق هتتفتح قريب.'**
  String get supportEntryComingSoon;

  /// No description provided for @errorAccountSuspended.
  ///
  /// In ar, this message translates to:
  /// **'الحساب موقوف. تواصل مع خدمة العملاء.'**
  String get errorAccountSuspended;

  /// No description provided for @authPhoneAlreadyUsed.
  ///
  /// In ar, this message translates to:
  /// **'الرقم ده مستخدم في حساب تاني.'**
  String get authPhoneAlreadyUsed;

  /// No description provided for @bookingPolicyOutOfBounds.
  ///
  /// In ar, this message translates to:
  /// **'السعر مش ثابت على التواريخ دي. جرّب تواريخ تانية أو تواصل مع الدعم.'**
  String get bookingPolicyOutOfBounds;

  /// No description provided for @errorConflict.
  ///
  /// In ar, this message translates to:
  /// **'البيانات اتغيرت. حدّث الصفحة وجرّب تاني.'**
  String get errorConflict;

  /// No description provided for @bookingStateChanged.
  ///
  /// In ar, this message translates to:
  /// **'حالة الحجز اتغيرت. حدّث الصفحة.'**
  String get bookingStateChanged;

  /// No description provided for @errorDuplicateOperation.
  ///
  /// In ar, this message translates to:
  /// **'العملية دي اتعملت قبل كده.'**
  String get errorDuplicateOperation;

  /// No description provided for @paymentVerificationIssue.
  ///
  /// In ar, this message translates to:
  /// **'فيه مشكلة في التحقق من الدفع. فريقنا هيتواصل معاك.'**
  String get paymentVerificationIssue;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @bookingDatesTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار التواريخ'**
  String get bookingDatesTitle;

  /// No description provided for @bookingRangeHasUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الفترة دي فيها يوم مش متاح. اختار تواريخ تانية.'**
  String get bookingRangeHasUnavailable;

  /// No description provided for @bookingNightsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الليالي: {count}'**
  String bookingNightsCount(String count);

  /// No description provided for @bookingContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get bookingContinue;

  /// No description provided for @bookingStartFromProperty.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الحجز من صفحة الشقة.'**
  String get bookingStartFromProperty;

  /// No description provided for @bookingSummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الحجز'**
  String get bookingSummaryTitle;

  /// No description provided for @bookingNights.
  ///
  /// In ar, this message translates to:
  /// **'الليالي'**
  String get bookingNights;

  /// No description provided for @bookingNightlyPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الليلة'**
  String get bookingNightlyPrice;

  /// No description provided for @bookingTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get bookingTotal;

  /// No description provided for @bookingPayNow.
  ///
  /// In ar, this message translates to:
  /// **'المطلوب دفعه دلوقتي'**
  String get bookingPayNow;

  /// No description provided for @bookingRemaining.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي'**
  String get bookingRemaining;

  /// No description provided for @bookingRemainingDue.
  ///
  /// In ar, this message translates to:
  /// **'يتسدد قبل {date}'**
  String bookingRemainingDue(String date);

  /// No description provided for @bookingPolicyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشروط وسياسة الإلغاء'**
  String get bookingPolicyTitle;

  /// No description provided for @bookingSummaryOwnerNotice.
  ///
  /// In ar, this message translates to:
  /// **'هيتبعت طلبك للمالك بعد الدفع. لو رفض أو مردّش خلال 24 ساعة هيترد لك المبلغ بالكامل.'**
  String get bookingSummaryOwnerNotice;

  /// No description provided for @bookingGoToPayment.
  ///
  /// In ar, this message translates to:
  /// **'اذهب للدفع'**
  String get bookingGoToPayment;

  /// No description provided for @paymentReturnHint.
  ///
  /// In ar, this message translates to:
  /// **'لو خلّصت الدفع، اضغط هنا عشان نتحقق منه.'**
  String get paymentReturnHint;

  /// No description provided for @paymentCheckStatus.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الدفع'**
  String get paymentCheckStatus;

  /// No description provided for @paymentVerifying.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من الدفع…'**
  String get paymentVerifying;

  /// No description provided for @paymentVerifyingBody.
  ///
  /// In ar, this message translates to:
  /// **'ده ممكن ياخد دقايق. هنبلغك أول ما يتأكد.'**
  String get paymentVerifyingBody;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم الدفع وأُرسل طلبك للمالك'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessBody.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ محجوزة لك لحد ما المالك يرد.'**
  String get paymentSuccessBody;

  /// No description provided for @ownerDeadlineCountdown.
  ///
  /// In ar, this message translates to:
  /// **'المالك قدامه {time} للرد'**
  String ownerDeadlineCountdown(String time);

  /// No description provided for @paymentViewBooking.
  ///
  /// In ar, this message translates to:
  /// **'عرض الحجز'**
  String get paymentViewBooking;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم تكتمل عملية الدفع'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailedBody.
  ///
  /// In ar, this message translates to:
  /// **'ولم يُخصم أي مبلغ.'**
  String get paymentFailedBody;

  /// No description provided for @paymentTryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get paymentTryAgain;

  /// No description provided for @paymentConflictTitle.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ اتحجزت قبل اكتمال دفعتك'**
  String get paymentConflictTitle;

  /// No description provided for @paymentConflictBody.
  ///
  /// In ar, this message translates to:
  /// **'هيترد لك المبلغ بالكامل ({amount}).'**
  String paymentConflictBody(String amount);

  /// No description provided for @paymentFindOtherDates.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن تواريخ تانية'**
  String get paymentFindOtherDates;

  /// No description provided for @paymentTimeoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه موصلناش تأكيد الدفع'**
  String get paymentTimeoutTitle;

  /// No description provided for @paymentTimeoutBody.
  ///
  /// In ar, this message translates to:
  /// **'متقلقش ومتدفعش تاني. هنبلغك أول ما يتأكد.'**
  String get paymentTimeoutBody;

  /// No description provided for @paymentGoToBookings.
  ///
  /// In ar, this message translates to:
  /// **'اذهب لحجوزاتي'**
  String get paymentGoToBookings;

  /// No description provided for @mockPaymentTitle.
  ///
  /// In ar, this message translates to:
  /// **'صفحة دفع تجريبية'**
  String get mockPaymentTitle;

  /// No description provided for @mockPaySuccess.
  ///
  /// In ar, this message translates to:
  /// **'دفع ناجح'**
  String get mockPaySuccess;

  /// No description provided for @mockPayFailure.
  ///
  /// In ar, this message translates to:
  /// **'فشل الدفع'**
  String get mockPayFailure;

  /// No description provided for @mockPayConflict.
  ///
  /// In ar, this message translates to:
  /// **'دفع ناجح بتواريخ محجوزة'**
  String get mockPayConflict;

  /// No description provided for @mockPaySilent.
  ///
  /// In ar, this message translates to:
  /// **'الخادم ما يردش'**
  String get mockPaySilent;

  /// No description provided for @mockPayClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الصفحة'**
  String get mockPayClose;

  /// No description provided for @verifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد بياناتك'**
  String get verifyTitle;

  /// No description provided for @verifyIntro.
  ///
  /// In ar, this message translates to:
  /// **'قبل أول حجز لازم نأكد بريدك ورقم موبايلك بكود يوصلك على البريد.'**
  String get verifyIntro;

  /// No description provided for @verifyEmailCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الكود اللي وصلك على البريد'**
  String get verifyEmailCodeHint;

  /// No description provided for @verifyHasWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'الرقم ده عليه واتساب'**
  String get verifyHasWhatsapp;

  /// No description provided for @verifyWhatsappNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الواتساب (اختياري)'**
  String get verifyWhatsappNumber;

  /// No description provided for @verifyCodeSentToEmail.
  ///
  /// In ar, this message translates to:
  /// **'بعتنا كود من 6 أرقام على بريدك.'**
  String get verifyCodeSentToEmail;

  /// No description provided for @verifyResend.
  ///
  /// In ar, this message translates to:
  /// **'ابعت الكود تاني'**
  String get verifyResend;

  /// No description provided for @verifyResendIn.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تبعت الكود تاني بعد {seconds} ثانية'**
  String verifyResendIn(String seconds);

  /// No description provided for @bookingsTabCurrent.
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get bookingsTabCurrent;

  /// No description provided for @bookingsTabPast.
  ///
  /// In ar, this message translates to:
  /// **'السابقة'**
  String get bookingsTabPast;

  /// No description provided for @bookingsTabCancelled.
  ///
  /// In ar, this message translates to:
  /// **'الملغاة'**
  String get bookingsTabCancelled;

  /// No description provided for @bookingsEmptyCurrent.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حجوزات حالية.'**
  String get bookingsEmptyCurrent;

  /// No description provided for @bookingsEmptyPast.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إقامات سابقة.'**
  String get bookingsEmptyPast;

  /// No description provided for @bookingsEmptyCancelled.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حجوزات ملغاة.'**
  String get bookingsEmptyCancelled;

  /// No description provided for @bookingsFindApartment.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن شقة'**
  String get bookingsFindApartment;

  /// No description provided for @lastUpdated.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث: {time}'**
  String lastUpdated(String time);

  /// No description provided for @bookingStatusPaymentPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار إتمام الدفع'**
  String get bookingStatusPaymentPending;

  /// No description provided for @bookingStatusPaymentVerifying.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من الدفع'**
  String get bookingStatusPaymentVerifying;

  /// No description provided for @bookingStatusAwaitingOwner.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار تأكيد المالك'**
  String get bookingStatusAwaitingOwner;

  /// No description provided for @bookingStatusPaymentConflict.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ اتحجزت قبلك'**
  String get bookingStatusPaymentConflict;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'حجز مؤكد'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusCheckedIn.
  ///
  /// In ar, this message translates to:
  /// **'إقامة جارية'**
  String get bookingStatusCheckedIn;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'إقامة مكتملة'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'رفض المالك'**
  String get bookingStatusRejected;

  /// No description provided for @bookingStatusExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة التأكيد'**
  String get bookingStatusExpired;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusNoShow.
  ///
  /// In ar, this message translates to:
  /// **'لم يحضر'**
  String get bookingStatusNoShow;

  /// No description provided for @bookingStatusAbandoned.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل'**
  String get bookingStatusAbandoned;

  /// No description provided for @bookingStatusUnknown.
  ///
  /// In ar, this message translates to:
  /// **'تحديث على الحجز'**
  String get bookingStatusUnknown;

  /// No description provided for @bookingMsgPaymentPending.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل الدفع بعد. تقدر تكمّل الدفع عشان طلبك يتبعت للمالك.'**
  String get bookingMsgPaymentPending;

  /// No description provided for @bookingMsgPaymentVerifying.
  ///
  /// In ar, this message translates to:
  /// **'نتحقق من عملية الدفع. قد يستغرق ذلك دقائق، وسنبلغك فور التأكيد.'**
  String get bookingMsgPaymentVerifying;

  /// No description provided for @bookingMsgAwaitingOwner.
  ///
  /// In ar, this message translates to:
  /// **'تم الدفع وأُرسل طلبك للمالك. المالك لديه حتى {deadline} للرد. التواريخ محجوزة لك حتى ذلك الحين.'**
  String bookingMsgAwaitingOwner(String deadline);

  /// No description provided for @bookingMsgAwaitingOwnerNoDeadline.
  ///
  /// In ar, this message translates to:
  /// **'تم الدفع وأُرسل طلبك للمالك. التواريخ محجوزة لك لحد ما يرد.'**
  String get bookingMsgAwaitingOwnerNoDeadline;

  /// No description provided for @bookingMsgConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد حجزك!'**
  String get bookingMsgConfirmed;

  /// No description provided for @bookingMsgConfirmedWithRemaining.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد حجزك! يجب سداد {amount} قبل الاستلام.'**
  String bookingMsgConfirmedWithRemaining(String amount);

  /// No description provided for @bookingMsgCheckedIn.
  ///
  /// In ar, this message translates to:
  /// **'نتمنى لك إقامة سعيدة.'**
  String get bookingMsgCheckedIn;

  /// No description provided for @bookingMsgCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت إقامتك. شاركنا رأيك!'**
  String get bookingMsgCompleted;

  /// No description provided for @bookingMsgRejected.
  ///
  /// In ar, this message translates to:
  /// **'اعتذر المالك عن قبول الطلب. سيتم رد كامل المبلغ ({amount}). سيتواصل معك فريق OnAir وقد يقترح بديلًا إن رغبت.'**
  String bookingMsgRejected(String amount);

  /// No description provided for @bookingMsgExpired.
  ///
  /// In ar, this message translates to:
  /// **'لم يرد المالك خلال 24 ساعة. سيتم رد كامل المبلغ ({amount}).'**
  String bookingMsgExpired(String amount);

  /// No description provided for @bookingMsgCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الحجز.'**
  String get bookingMsgCancelled;

  /// No description provided for @bookingMsgNoShow.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل عدم الحضور. للاستفسار تواصل مع الدعم.'**
  String get bookingMsgNoShow;

  /// No description provided for @bookingMsgConflict.
  ///
  /// In ar, this message translates to:
  /// **'تم حجز هذه التواريخ قبل اكتمال دفعتك. سيتم رد المبلغ بالكامل ({amount}).'**
  String bookingMsgConflict(String amount);

  /// No description provided for @bookingMsgAbandoned.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل الدفع ولم يُخصم أي مبلغ.'**
  String get bookingMsgAbandoned;

  /// No description provided for @bookingMsgUnknown.
  ///
  /// In ar, this message translates to:
  /// **'فيه تحديث على حجزك. للاستفسار تواصل مع الدعم.'**
  String get bookingMsgUnknown;

  /// No description provided for @bookingCode.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحجز'**
  String get bookingCode;

  /// No description provided for @bookingCopyCode.
  ///
  /// In ar, this message translates to:
  /// **'نسخ رقم الحجز'**
  String get bookingCopyCode;

  /// No description provided for @bookingCodeCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رقم الحجز'**
  String get bookingCodeCopied;

  /// No description provided for @bookingStayTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإقامة'**
  String get bookingStayTitle;

  /// No description provided for @bookingArrival.
  ///
  /// In ar, this message translates to:
  /// **'الوصول'**
  String get bookingArrival;

  /// No description provided for @bookingDeparture.
  ///
  /// In ar, this message translates to:
  /// **'المغادرة'**
  String get bookingDeparture;

  /// No description provided for @bookingCheckInTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت الاستلام'**
  String get bookingCheckInTime;

  /// No description provided for @bookingCheckOutTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت المغادرة'**
  String get bookingCheckOutTime;

  /// No description provided for @bookingPaymentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المدفوعات'**
  String get bookingPaymentsTitle;

  /// No description provided for @bookingPaid.
  ///
  /// In ar, this message translates to:
  /// **'المدفوع'**
  String get bookingPaid;

  /// No description provided for @paymentMethodCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة / محفظة'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodCash.
  ///
  /// In ar, this message translates to:
  /// **'نقدًا'**
  String get paymentMethodCash;

  /// No description provided for @paymentLineSucceeded.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get paymentLineSucceeded;

  /// No description provided for @paymentLinePending.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get paymentLinePending;

  /// No description provided for @paymentLineFailed.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل'**
  String get paymentLineFailed;

  /// No description provided for @bookingAddressTitle.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get bookingAddressTitle;

  /// No description provided for @bookingArrivalInstructions.
  ///
  /// In ar, this message translates to:
  /// **'تعليمات الوصول'**
  String get bookingArrivalInstructions;

  /// No description provided for @bookingSavedTermsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشروط وقت الحجز'**
  String get bookingSavedTermsTitle;

  /// No description provided for @bookingTimelineTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الحجز'**
  String get bookingTimelineTitle;

  /// No description provided for @bookingEventGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تحديث على الحجز'**
  String get bookingEventGeneric;

  /// No description provided for @bookingContactSupport.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج مساعدة؟ تواصل مع OnAir'**
  String get bookingContactSupport;

  /// No description provided for @refundChipRequested.
  ///
  /// In ar, this message translates to:
  /// **'تم طلب الاسترداد'**
  String get refundChipRequested;

  /// No description provided for @refundChipInProgress.
  ///
  /// In ar, this message translates to:
  /// **'الاسترداد قيد التنفيذ'**
  String get refundChipInProgress;

  /// No description provided for @refundChipDone.
  ///
  /// In ar, this message translates to:
  /// **'تم رد المبلغ'**
  String get refundChipDone;

  /// No description provided for @refundChipProblem.
  ///
  /// In ar, this message translates to:
  /// **'مشكلة في الاسترداد'**
  String get refundChipProblem;

  /// No description provided for @refundTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاسترداد'**
  String get refundTitle;

  /// No description provided for @refundAmount.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ الاسترداد'**
  String get refundAmount;

  /// No description provided for @refundStageRequested.
  ///
  /// In ar, this message translates to:
  /// **'طُلب'**
  String get refundStageRequested;

  /// No description provided for @refundStageApproved.
  ///
  /// In ar, this message translates to:
  /// **'اعتُمد'**
  String get refundStageApproved;

  /// No description provided for @refundStageExecuting.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get refundStageExecuting;

  /// No description provided for @refundStageVerified.
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من وصوله'**
  String get refundStageVerified;

  /// No description provided for @refundProblemHint.
  ///
  /// In ar, this message translates to:
  /// **'فيه مشكلة في الاسترداد. فريق OnAir بيتابعها، وتقدر تتواصل مع الدعم.'**
  String get refundProblemHint;

  /// No description provided for @unfinishedPaymentBanner.
  ///
  /// In ar, this message translates to:
  /// **'عندك دفع لم يكتمل.'**
  String get unfinishedPaymentBanner;

  /// No description provided for @unfinishedPaymentOpen.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get unfinishedPaymentOpen;

  /// No description provided for @quoteChangedNotice.
  ///
  /// In ar, this message translates to:
  /// **'السعر اتحدّث. راجع المبالغ الجديدة قبل الدفع.'**
  String get quoteChangedNotice;

  /// No description provided for @quoteConfirmNew.
  ///
  /// In ar, this message translates to:
  /// **'أكّد المبالغ الجديدة'**
  String get quoteConfirmNew;

  /// No description provided for @termsChangedNotice.
  ///
  /// In ar, this message translates to:
  /// **'الشروط اتحدّثت. راجعها ووافق عليها للمتابعة.'**
  String get termsChangedNotice;

  /// No description provided for @termsAcceptNew.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على الشروط الجديدة'**
  String get termsAcceptNew;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إشعارات لسه.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsOffNotice.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات مقفولة. فعّلها عشان تعرف فورًا لما المالك يرد.'**
  String get notificationsOffNotice;

  /// No description provided for @notificationsOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get notificationsOpenSettings;

  /// No description provided for @pushPermissionTitle.
  ///
  /// In ar, this message translates to:
  /// **'فعّل الإشعارات'**
  String get pushPermissionTitle;

  /// No description provided for @pushPermissionBody.
  ///
  /// In ar, this message translates to:
  /// **'عشان تعرف فورًا لما المالك يرد على طلبك.'**
  String get pushPermissionBody;

  /// No description provided for @pushPermissionEnable.
  ///
  /// In ar, this message translates to:
  /// **'فعّل'**
  String get pushPermissionEnable;

  /// No description provided for @pushPermissionLater.
  ///
  /// In ar, this message translates to:
  /// **'مش دلوقتي'**
  String get pushPermissionLater;

  /// No description provided for @unreadBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} إشعار غير مقروء'**
  String unreadBadge(String count);

  /// No description provided for @notifBookingRequestReceivedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم الدفع وأُرسل طلبك'**
  String get notifBookingRequestReceivedTitle;

  /// No description provided for @notifBookingRequestReceivedBody.
  ///
  /// In ar, this message translates to:
  /// **'المالك هيرد خلال 24 ساعة. اضغط للتفاصيل.'**
  String get notifBookingRequestReceivedBody;

  /// No description provided for @notifBookingConfirmedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد حجزك ✓'**
  String get notifBookingConfirmedTitle;

  /// No description provided for @notifBookingConfirmedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifBookingConfirmedBody;

  /// No description provided for @notifBookingRejectedTitle.
  ///
  /// In ar, this message translates to:
  /// **'المالك اعتذر عن الطلب'**
  String get notifBookingRejectedTitle;

  /// No description provided for @notifBookingRejectedBody.
  ///
  /// In ar, this message translates to:
  /// **'هيترد لك المبلغ بالكامل. اضغط للتفاصيل.'**
  String get notifBookingRejectedBody;

  /// No description provided for @notifBookingExpiredTitle.
  ///
  /// In ar, this message translates to:
  /// **'المالك مردّش في المهلة'**
  String get notifBookingExpiredTitle;

  /// No description provided for @notifBookingExpiredBody.
  ///
  /// In ar, this message translates to:
  /// **'هيترد لك المبلغ بالكامل. اضغط للتفاصيل.'**
  String get notifBookingExpiredBody;

  /// No description provided for @notifBookingPaymentConflictTitle.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ اتحجزت قبل دفعتك'**
  String get notifBookingPaymentConflictTitle;

  /// No description provided for @notifBookingPaymentConflictBody.
  ///
  /// In ar, this message translates to:
  /// **'هيترد لك المبلغ بالكامل. اضغط للتفاصيل.'**
  String get notifBookingPaymentConflictBody;

  /// No description provided for @notifBookingCancelledByGuestTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء حجزك'**
  String get notifBookingCancelledByGuestTitle;

  /// No description provided for @notifBookingCancelledByGuestBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifBookingCancelledByGuestBody;

  /// No description provided for @notifBookingCancelledByPlatformTitle.
  ///
  /// In ar, this message translates to:
  /// **'OnAir ألغت الحجز'**
  String get notifBookingCancelledByPlatformTitle;

  /// No description provided for @notifBookingCancelledByPlatformBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifBookingCancelledByPlatformBody;

  /// No description provided for @notifBookingReplacementOfferedTitle.
  ///
  /// In ar, this message translates to:
  /// **'عندك عرض بديل'**
  String get notifBookingReplacementOfferedTitle;

  /// No description provided for @notifBookingReplacementOfferedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لمراجعة العرض.'**
  String get notifBookingReplacementOfferedBody;

  /// No description provided for @notifBookingNoShowRecordedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل عدم الحضور'**
  String get notifBookingNoShowRecordedTitle;

  /// No description provided for @notifBookingNoShowRecordedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifBookingNoShowRecordedBody;

  /// No description provided for @notifBookingReopenedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة فتح الحجز'**
  String get notifBookingReopenedTitle;

  /// No description provided for @notifBookingReopenedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifBookingReopenedBody;

  /// No description provided for @notifPaymentFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل الدفع'**
  String get notifPaymentFailedTitle;

  /// No description provided for @notifPaymentFailedBody.
  ///
  /// In ar, this message translates to:
  /// **'ولم يُخصم أي مبلغ.'**
  String get notifPaymentFailedBody;

  /// No description provided for @notifPaymentRemainingDueTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بسداد المتبقي'**
  String get notifPaymentRemainingDueTitle;

  /// No description provided for @notifPaymentRemainingDueBody.
  ///
  /// In ar, this message translates to:
  /// **'لازم يتسدد قبل الاستلام.'**
  String get notifPaymentRemainingDueBody;

  /// No description provided for @notifPaymentRemainingPaidTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم سداد المتبقي'**
  String get notifPaymentRemainingPaidTitle;

  /// No description provided for @notifPaymentRemainingPaidBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifPaymentRemainingPaidBody;

  /// No description provided for @notifCashConfirmationRequestedTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكّد الدفع النقدي'**
  String get notifCashConfirmationRequestedTitle;

  /// No description provided for @notifCashConfirmationRequestedBody.
  ///
  /// In ar, this message translates to:
  /// **'الكود على بريدك.'**
  String get notifCashConfirmationRequestedBody;

  /// No description provided for @notifCashPaymentConfirmedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد الدفع النقدي'**
  String get notifCashPaymentConfirmedTitle;

  /// No description provided for @notifCashPaymentConfirmedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للإيصال.'**
  String get notifCashPaymentConfirmedBody;

  /// No description provided for @notifStayCheckinReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد وصولك قرّب'**
  String get notifStayCheckinReminderTitle;

  /// No description provided for @notifStayCheckinReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifStayCheckinReminderBody;

  /// No description provided for @notifStayCheckoutReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'ميعاد المغادرة قرّب'**
  String get notifStayCheckoutReminderTitle;

  /// No description provided for @notifStayCheckoutReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifStayCheckoutReminderBody;

  /// No description provided for @notifStayHostHandoverConfirmedTitle.
  ///
  /// In ar, this message translates to:
  /// **'المالك أكّد تسليم الشقة'**
  String get notifStayHostHandoverConfirmedTitle;

  /// No description provided for @notifStayHostHandoverConfirmedBody.
  ///
  /// In ar, this message translates to:
  /// **'أكّد استلامك من التطبيق.'**
  String get notifStayHostHandoverConfirmedBody;

  /// No description provided for @notifStayCheckedInTitle.
  ///
  /// In ar, this message translates to:
  /// **'بدأت إقامتك'**
  String get notifStayCheckedInTitle;

  /// No description provided for @notifStayCheckedInBody.
  ///
  /// In ar, this message translates to:
  /// **'نتمنى لك إقامة سعيدة.'**
  String get notifStayCheckedInBody;

  /// No description provided for @notifStayCompletedTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت إقامتك'**
  String get notifStayCompletedTitle;

  /// No description provided for @notifStayCompletedBody.
  ///
  /// In ar, this message translates to:
  /// **'شاركنا رأيك!'**
  String get notifStayCompletedBody;

  /// No description provided for @notifDamageClaimOpenedTitle.
  ///
  /// In ar, this message translates to:
  /// **'فيه مطالبة على حجزك'**
  String get notifDamageClaimOpenedTitle;

  /// No description provided for @notifDamageClaimOpenedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للمراجعة.'**
  String get notifDamageClaimOpenedBody;

  /// No description provided for @notifDamageResolvedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم البت في المطالبة'**
  String get notifDamageResolvedTitle;

  /// No description provided for @notifDamageResolvedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifDamageResolvedBody;

  /// No description provided for @notifRefundRequestedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم طلب الاسترداد'**
  String get notifRefundRequestedTitle;

  /// No description provided for @notifRefundRequestedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifRefundRequestedBody;

  /// No description provided for @notifRefundExecutedTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاسترداد قيد التنفيذ'**
  String get notifRefundExecutedTitle;

  /// No description provided for @notifRefundExecutedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifRefundExecutedBody;

  /// No description provided for @notifRefundVerifiedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم رد المبلغ'**
  String get notifRefundVerifiedTitle;

  /// No description provided for @notifRefundVerifiedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifRefundVerifiedBody;

  /// No description provided for @notifSupportStaffRepliedTitle.
  ///
  /// In ar, this message translates to:
  /// **'رد جديد من خدمة العملاء'**
  String get notifSupportStaffRepliedTitle;

  /// No description provided for @notifSupportStaffRepliedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للقراءة.'**
  String get notifSupportStaffRepliedBody;

  /// No description provided for @notifSupportCaseResolvedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم حل حالتك'**
  String get notifSupportCaseResolvedTitle;

  /// No description provided for @notifSupportCaseResolvedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifSupportCaseResolvedBody;

  /// No description provided for @notifReviewApprovedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر تقييمك'**
  String get notifReviewApprovedTitle;

  /// No description provided for @notifReviewApprovedBody.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا لمشاركتك.'**
  String get notifReviewApprovedBody;

  /// No description provided for @notifReviewRejectedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقييمك مش هيتنشر'**
  String get notifReviewRejectedTitle;

  /// No description provided for @notifReviewRejectedBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifReviewRejectedBody;

  /// No description provided for @notifAccountPhoneChangedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير رقم الموبايل'**
  String get notifAccountPhoneChangedTitle;

  /// No description provided for @notifAccountPhoneChangedBody.
  ///
  /// In ar, this message translates to:
  /// **'لو مش انت، تواصل مع الدعم.'**
  String get notifAccountPhoneChangedBody;

  /// No description provided for @notifAccountPasswordChangedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور'**
  String get notifAccountPasswordChangedTitle;

  /// No description provided for @notifAccountPasswordChangedBody.
  ///
  /// In ar, this message translates to:
  /// **'لو مش انت، تواصل مع الدعم.'**
  String get notifAccountPasswordChangedBody;

  /// No description provided for @notifGenericTitle.
  ///
  /// In ar, this message translates to:
  /// **'عندك تحديث جديد'**
  String get notifGenericTitle;

  /// No description provided for @notifGenericBody.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتفاصيل.'**
  String get notifGenericBody;
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
