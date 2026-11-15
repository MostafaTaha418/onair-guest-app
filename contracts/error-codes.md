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
- **S005 deltas (14 Nov 2026):** phone codes go on WhatsApp. The WhatsApp codes below are
  *(new)*; the full deltas live in
  [specs/005-guest-social-sign-in/contracts](../specs/005-guest-social-sign-in/contracts/)
  (node-otp.md A8–A9, supabase-auth.md A5–A7).

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
| `POLICY_OUT_OF_BOUNDS` *(new)* | G2 | `bookingPolicyOutOfBounds` | السعر مش ثابت على التواريخ دي. جرّب تواريخ تانية أو تواصل مع الدعم. | **yes** |
| `ACTION_NOT_ALLOWED` | G2 | `errorActionNotAllowed` | الإجراء ده مش متاح دلوقتي. | no |
| `CANCELLATION_TERMS_CHANGED` *(new)* | G3 | `cancellationTermsChanged` | مبلغ الاسترداد اتغير. راجع التفاصيل الجديدة. | no |
| `REMAINING_NOT_PAID` *(new)* | G3 | `stayRemainingNotPaid` | لازم تسدد المبلغ المتبقي قبل استلام الشقة. | no |
| `COLLECTOR_NOT_AUTHORIZED` | G3 | `stayCollectorNotAuthorized` | الشخص ده مش مفوّض يستلم فلوس للشقة دي. متسلّمش كاش وكلّم OnAir. | no |
| `CASH_NOT_ALLOWED` *(new)* | G3 | `stayCashNotAllowed` | الدفع النقدي مش متاح للشقة دي. | no |
| `CASH_AMOUNT_CHANGED` *(new)* | G3 | `stayCashAmountChanged` | المبلغ المتبقي اتغير. راجع المبلغ الجديد. | no |
| `CLAIM_ALREADY_ANSWERED` *(new)* | G3 | `claimAlreadyAnswered` | المطالبة دي اتردّ عليها قبل كده. | no |
| `OFFER_NOT_AVAILABLE` *(new)* | G3 | `offerNotAvailable` | العرض ده مبقاش متاح. | no |
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

| `PROFILE_ALREADY_COMPLETE` *(new)* | S005 | `authProfileIncomplete` | كمّل بياناتك للمتابعة. | no |
| `OTP_SEND_BLOCKED` *(new)* | S005 | `otpBlockedUntil` | اتوقف إرسال الأكواد مؤقتًا لحد {date}. لو محتاج مساعدة كلّم الدعم | no |
| `PHONE_NOT_ON_WHATSAPP` *(new)* | S005 | `whatsappNotOnWhatsApp` | الرقم ده مش عليه واتساب. استخدم رقم عليه واتساب | no |
| `APP_ATTESTATION_FAILED` *(new)* | S005 | `otpAttestationFailed` | مش قادرين نتأكد إن التطبيق أصلي. حدّث التطبيق من المتجر وجرّب تاني | no |
| `OTP_TEMPORARILY_UNAVAILABLE` *(new)* | S005 | `otpTemporarilyUnavailable` | الخدمة مشغولة دلوقتي، جرّب بعد شوية | no |
| `OTP_SUPERSEDED` *(new)* | S005 | `whatsappUseLatestCode` | استخدم آخر كود وصلك | no |
| `OTP_ATTEMPTS_EXCEEDED` *(new)* | S005 | `otpAttemptsExceeded` | جربت كتير، اطلب كود جديد | no |

`RATE_LIMITED` in S005 carries `details.next_send_at` (the WhatsApp ladder) and
`OTP_SEND_BLOCKED` carries `details.blocked_until`; the app renders both verbatim and never
computes the ladder itself.

**Language note:** the tone is plain Arabic for guests, with no accounting terms
(Constitution VI). The designer or owner may switch the copy to Modern Standard Arabic; the keys
stay the same.
