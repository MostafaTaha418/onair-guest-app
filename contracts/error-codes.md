# Contract: Error Codes and Messages (G0)

The app never shows raw server text. Each code maps to one `.arb` key. Unknown codes →
`INTERNAL` with the reference number (`request_id`). Arabic copy below is the proposed default;
final wording lives in `lib/l10n/app_ar.arb`.

| Code | Used in G0 | ARB key (camelCase) | Proposed Arabic copy | Shows reference? |
|---|---|---|---|---|
| `UNAUTHENTICATED` | yes | `errorUnauthenticated` | انتهت الجلسة. سجّل الدخول مرة أخرى. | no |
| `PHONE_COUNTRY_NOT_SUPPORTED` | yes | `authPhoneCountryNotSupported` | حاليًا ندعم أرقام الموبايل المصرية فقط. تقدر تسجّل بالبريد الإلكتروني. | no |
| `OTP_INVALID` | yes | `authOtpInvalid` | الكود غير صحيح. راجع الرسالة وجرّب تاني. | no |
| `OTP_EXPIRED` | yes | `authOtpExpired` | الكود انتهت صلاحيته. اطلب كود جديد. | no |
| `RATE_LIMITED` | yes | `authRateLimited` | محاولات كتير. جرّب تاني بعد {time}. | no |
| `VALIDATION_FAILED` | yes | `errorValidationFailed` | راجع البيانات المكتوبة. | no |
| `TERMS_CHANGED` | yes | `authTermsChanged` | الشروط اتحدّثت. راجعها ووافق عليها للمتابعة. | no |
| `PROFILE_INCOMPLETE` | yes | `authProfileIncomplete` | كمّل بياناتك للمتابعة. | no |
| `APP_VERSION_UNSUPPORTED` | yes | `appUpdateRequired` | لازم تحدّث التطبيق للمتابعة. | no |
| `PHONE_NOT_VERIFIED` | mapped (G2) | `bookingPhoneNotVerified` | أكّد رقم موبايلك قبل الحجز. | no |
| `EMAIL_NOT_VERIFIED` | mapped (G2) | `bookingEmailNotVerified` | أكّد بريدك قبل الحجز. | no |
| `DATES_UNAVAILABLE` | mapped (G2) | `bookingDatesUnavailable` | التواريخ دي مش متاحة. | no |
| `GUESTS_EXCEEDED` | mapped (G2) | `bookingGuestsExceeded` | عدد الضيوف أكبر من المسموح. | no |
| `QUOTE_EXPIRED` | mapped (G2) | `bookingQuoteExpired` | السعر اتحدّث. راجع الملخص من جديد. | no |
| `PROPERTY_NOT_AVAILABLE` | mapped (G1) | `propertyNotAvailable` | الشقة دي مش متاحة حاليًا. | no |
| `ACTION_NOT_ALLOWED` | mapped | `errorActionNotAllowed` | الإجراء ده مش متاح دلوقتي. | no |
| `COLLECTOR_NOT_AUTHORIZED` | mapped (G3) | `stayCollectorNotAuthorized` | المحصّل غير مفوّض. تواصل مع خدمة العملاء. | no |
| `INTERNAL` | yes | `errorUnexpected` | حصلت مشكلة غير متوقعة. رقم المرجع: {ref} | **yes** |
| *(network)* | yes | `errorNoConnection` | مفيش اتصال بالإنترنت. | no |

Uniform-message rule (FR-028): sign-in failure for email/password always uses
`authInvalidCredentials` ("البريد أو كلمة المرور غير صحيحة"); code send and recovery always
use `authCodeSent` / `authRecoverySent`, regardless of whether the account exists.

Language note: tone is plain Arabic for guests, no accounting terms (Constitution VI). The
designer/owner may switch the copy to Modern Standard Arabic; keys stay the same.
