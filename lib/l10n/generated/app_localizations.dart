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

  /// No description provided for @bookingEntryTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحجز'**
  String get bookingEntryTitle;

  /// No description provided for @bookingEntryComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'الحجز من التطبيق هيتفتح قريب.'**
  String get bookingEntryComingSoon;

  /// No description provided for @bookingEntryTermsCarried.
  ///
  /// In ar, this message translates to:
  /// **'الشروط اللي شفتها اتسجّلت مع الطلب.'**
  String get bookingEntryTermsCarried;

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
