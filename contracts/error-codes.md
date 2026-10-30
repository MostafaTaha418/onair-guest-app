# Contract: Error Codes and Messages (Guest App)

The single source of codes is `docs/OnAir Backend Master Plan.md` §11 (28 Oct 2026). This file
lists the codes the Guest App can receive and the ARB key for each.

- The app never shows raw server text. Each code maps to one `.arb` key.
- Unknown codes → `INTERNAL`, shown with the reference number (`request_id`).
- The Arabic copy below is the proposed default; the final wording lives in
  `lib/l10n/app_ar.arb`.
- Postgres functions raise `raise exception '<CODE>' using errcode = 'P0001'`. Node routes return
  the `ErrorResponse` in [node-api.openapi.yaml](node-api.openapi.yaml).
- **Changed on 28 Oct 2026:** there is no SMS. Every code is sent to the account's email. New
  codes are marked *(new)*.

| Code | Phase | ARB key (camelCase) | Proposed Arabic copy | Shows reference? |
|---|---|---|---|---|
| `UNAUTHENTICATED` | G0 | `errorUnauthenticated` | انتهت الجلسة. سجّل الدخول مرة أخرى. | no |
| `ACCOUNT_SUSPENDED` *(new)* | G0 | `errorAccountSuspended` | الحساب موقوف. تواصل مع خدمة العملاء. | no |
| `PERMISSION_DENIED` *(new)* | G0 | `errorPermissionDenied` | مش مسموح لك تعمل الإجراء ده. | no |
| `PHONE_COUNTRY_NOT_SUPPORTED` | G0 | `authPhoneCountryNotSupported` | حاليًا ندعم أرقام الموبايل المصرية فقط. | no |
| `PHONE_ALREADY_USED` *(new)* | G0 | `authPhoneAlreadyUsed` | الرقم ده مستخدم في حساب تاني. | no |
| `OTP_INVALID` | G0 | `authOtpInvalid` | الكود غير صحيح. راجع البريد وجرّب تاني. | no |
| `OTP_EXPIRED` | G0 | `authOtpExpired` | الكود انتهت صلاحيته. اطلب كود جديد. | no |
| `RATE_LIMITED` | G0 | `authRateLimited` | محاولات كتير. جرّب تاني بعد {time}. | no |
| `VALIDATION_FAILED` | G0 | `errorValidationFailed` | راجع البيانات المكتوبة. | no |
| `TERMS_CHANGED` | G0 | `authTermsChanged` | الشروط اتحدّثت. راجعها ووافق عليها للمتابعة. | no |
| `PROFILE_INCOMPLETE` | G0 (legacy) | `authProfileIncomplete` | كمّل بياناتك للمتابعة. | no |
| `ACCOUNT_HAS_ACTIVE_BOOKINGS` *(new)* | G4 | `accountHasActiveBookings` | مينفعش تحذف الحساب وعندك حجز أو استرداد لسه شغال. | no |
| `APP_VERSION_UNSUPPORTED` | G0 | `appUpdateRequired` | لازم تحدّث التطبيق للمتابعة. | no |
| `NOT_FOUND` | G1 | `propertyNotAvailable` (discovery) / `errorNotAvailable` (other screens) | الشقة دي مش متاحة حاليًا. / العنصر ده مش متاح. | no |
| `PROPERTY_NOT_AVAILABLE` | G1 | `propertyNotAvailable` | الشقة دي مش متاحة حاليًا. | no |
| `PHONE_NOT_VERIFIED` | G2 | `bookingPhoneNotVerified` | أكّد رقم موبايلك بالكود اللي على بريدك قبل الحجز. | no |
| `EMAIL_NOT_VERIFIED` | G2 | `bookingEmailNotVerified` | أكّد بريدك قبل الحجز. | no |
| `DATES_UNAVAILABLE` | G2 | `bookingDatesUnavailable` | التواريخ دي مش متاحة. | no |
| `GUESTS_EXCEEDED` | G2 | `bookingGuestsExceeded` | عدد الضيوف أكبر من المسموح. | no |
| `QUOTE_EXPIRED` | G2 | `bookingQuoteExpired` | السعر اتحدّث. راجع الملخص من جديد. | no |
| `PAYMENT_AMOUNT_MISMATCH` *(new)* | G2 | `paymentVerificationIssue` | فيه مشكلة في التحقق من الدفع. فريقنا هيتواصل معاك. | **yes** |
| `DUPLICATE_OPERATION` *(new)* | G2 | `errorDuplicateOperation` | العملية دي اتعملت قبل كده. | no |
| `CONFLICT` *(new)* | G2 | `errorConflict` | البيانات اتغيرت. حدّث الصفحة وجرّب تاني. | no |
| `INVALID_BOOKING_STATE` *(new)* | G2 | `bookingStateChanged` | حالة الحجز اتغيرت. حدّث الصفحة. | no |
| `ACTION_NOT_ALLOWED` | G2 | `errorActionNotAllowed` | الإجراء ده مش متاح دلوقتي. | no |
| `CANCELLATION_TERMS_CHANGED` *(new)* | G3 | `cancellationTermsChanged` | مبلغ الاسترداد اتغير. راجع التفاصيل الجديدة. | no |
| `REMAINING_NOT_PAID` *(new)* | G3 | `stayRemainingNotPaid` | لازم تسدد المبلغ المتبقي قبل استلام الشقة. | no |
| `COLLECTOR_NOT_AUTHORIZED` | G3 | `stayCollectorNotAuthorized` | المحصّل غير مفوّض. تواصل مع خدمة العملاء. | no |
| `CASH_NOT_ALLOWED` *(new)* | G3 | `stayCashNotAllowed` | الدفع النقدي مش متاح للشقة دي. | no |
| `REVIEW_NOT_ALLOWED` *(new)* | G5 | `reviewNotAllowed` | التقييم متاح بعد انتهاء الإقامة، ومرة واحدة بس. | no |
| `INTERNAL` | G0 | `errorUnexpected` | حصلت مشكلة غير متوقعة. رقم المرجع: {ref} | **yes** |
| *(network)* | G0 | `errorNoConnection` | مفيش اتصال بالإنترنت. | no |

**Uniform-message rule (FR-028):**
- A failed email/password sign-in always uses `authInvalidCredentials` ("البريد أو كلمة المرور
  غير صحيحة").
- Code send and recovery always use `authCodeSent` / `authRecoverySent`, whether or not the
  account exists.
- Exception: `PHONE_ALREADY_USED` at sign-up does reveal that a phone is in use. This follows
  the rule that one phone belongs to one account.

**Language note:** the tone is plain Arabic for guests, with no accounting terms
(Constitution VI). The designer or owner may switch the copy to Modern Standard Arabic; the keys
stay the same.
