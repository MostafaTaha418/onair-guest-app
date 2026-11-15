# UI screens — S005

Sources:
- `DESIGN.md` (auth gradient, pill fields 36dp radius, 480dp max width, 28dp padding, gradient
  primary with soft shadow, 48dp targets);
- `docs/design_reference/README.md` row 5 (Login, `current_concept`) and row 7 (OTP verification);
- the existing auth widgets (`AuthFlowScaffold`, `AuthBrandHeader`, `OnAirOtpField`,
  `CountdownText`, `RapidSubmitGuard`).

Every screen: Light/Dark, Arabic RTL and English LTR, 1.3× text, 320dp and 800dp widths, keyboard
open, offline banner, and in-button loaders that disable on first tap.

## 1. New shared component — `SocialSignInButton` (`lib/design_system/components/`)

| Property | Value |
|---|---|
| Shape | 56dp circle (touch target ≥ 48dp) |
| Surface | Social Fill token (light/dark) + quiet border (`borderSubtle`) |
| Content | official provider mark, 24dp: Google "G" full colour; Apple logo `textPrimary` (black in light, white in dark) |
| States | enabled · pressed · busy (circular progress replaces the logo, same size) · disabled (all buttons while any sign-in is in flight) |
| Semantics | button, label «المتابعة بـ Google» / «المتابعة بـ Apple» (en: "Continue with Google/Apple") |
| Assets | `assets/images/social/google_g.svg`, `apple_logo_black.svg`, `apple_logo_white.svg` from the providers' official kits, unmodified |

Goldens: each provider × {enabled, busy, disabled} × {light, dark}.

## 2. Login (`/auth/login`) — changed

As today, top to bottom: brand header, title «تسجيل الدخول», "ليس لديك حساب؟ إنشاء حساب", email
field, password field with «نسيت؟», gradient «تسجيل الدخول».

Then (new, per the current-concept capture):
- divider with centred «أو»;
- a row of `SocialSignInButton`s centred: iOS «Apple», «Google» (RTL order); Android «Google»
  only.

Removed: phone/email segmented control and the phone fields.
Error for a social failure: inline `NoticeCard` above the row. A cancel shows nothing.

## 3. Registration (`/auth/register`) — changed

Fields: name, email, password with strength hint, Terms/Privacy checkbox with links, gradient
«إنشاء حساب». Phone, «الرقم ده عليه واتساب؟» and the WhatsApp number are removed. The same «أو» +
social row follows.

## 4. «أكّد رقمك» (`/auth/complete-profile`, `/account/phone`) — new `ConfirmPhoneScreen`

Scaffold: `AuthFlowScaffold` with brand header for `register`. For `change` it uses the standard
app bar «تغيير رقم الهاتف».

### 4.1 Form step

| Element | Detail |
|---|---|
| Title | register: «أكّد رقمك» · change: «رقمك الجديد» |
| Subtitle | «هنبعتلك كود على واتساب الرقم ده عشان نتأكد إنه بتاعك» |
| Account email | read-only row with mail icon (register only) |
| Name | pill field; shown only when the account has no name; pre-filled from provider |
| Phone | pill field, `+20` prefix, `TextInputType.phone`, autofill `telephoneNumber`; local Egyptian validation; field errors: invalid, not Egyptian, already used |
| Terms | checkbox + links; shown only when the account has no accepted terms; re-shown and cleared on `TERMS_CHANGED` |
| Primary | gradient «متابعة» (disabled until valid; in-button loader) |
| Secondary | register: text button «إلغاء» → dialog «لو خرجت، التسجيل مش هيكمل» [«خروج» destructive / «كمّل»] |

### 4.2 Code step (WhatsApp)

| Element | Detail |
|---|---|
| Icon + title | WhatsApp-tinted chat icon (theme `success` role, no brand logo) + «اكتب الكود» |
| Body | «بعتنا كود على واتساب {maskedPhone}» |
| Code | `OnAirOtpField` (6 digits, paste, `AutofillHints.oneTimeCode`) |
| Primary | gradient «تأكيد» (enabled at 6 digits; in-button loader) |
| Open WhatsApp | outlined «افتح واتساب» → `url_launcher` `whatsapp://` (falls back to nothing if not installed) |
| Resend | text button «ابعت كود جديد», disabled with `CountdownText` «تقدر تطلب كود جديد بعد {mm:ss}» or «… بعد {hours}» (R8) |
| Change number | text button «تعديل الرقم» → form step with the draft |
| Notices (`NoticeCard`) | not on WhatsApp: «الرقم ده مش عليه واتساب. استخدم رقم عليه واتساب» + «تعديل الرقم» + «كلّم الدعم» · attestation: «مش قادرين نتأكد إن التطبيق أصلي. حدّث التطبيق من المتجر وجرّب تاني» · busy service: «الخدمة مشغولة دلوقتي، جرّب بعد شوية» |
| Code errors | under the field: «الكود غلط» · «الكود انتهى، اطلب كود جديد» · «استخدم آخر كود وصلك» · «جربت كتير، اطلب كود جديد» |

### 4.3 Blocked state

`NoticeCard` (warning tone): «اتوقف إرسال الأكواد مؤقتًا لحد {Cairo date-time}. لو محتاج مساعدة
كلّم الدعم». Below it: «كلّم الدعم» (opens support, or the support phone from `app_config` if
support is not built yet), and «تسجيل الخروج» for `register`. Send and resend are disabled.

### 4.4 Success

`register`: a short success toast «أهلًا بيك في OnAir 👋» and the router releases to `from`.
`change`: pop + snackbar «رقمك اتغيّر».

## 5. Account placeholder (`/account`) — minimal additions until G4

- Row «طريقة الدخول»: Google / Apple / البريد (from `authProviders`; several are joined with «،»).
- Row «رقم الهاتف»: the masked phone with a «متأكد» chip, and «تغيير» → `/account/phone`.
- No password UI exists yet. G4 must hide «تغيير كلمة المرور» when `hasPassword == false` (noted
  for G4).

## 6. Booking verify step (`/book/:id/verify`)

The phone sub-step UI is removed. When the server says `PHONE_NOT_VERIFIED`, the screen navigates
to `/auth/complete-profile?from=/book/:id/dates…`. The email sub-step is unchanged.

## 7. Localization keys (new; ar + en)

`authOr`, `authContinueWithGoogle`, `authContinueWithApple`, `authSocialFailed`,
`confirmPhoneTitle`, `confirmPhoneNewTitle`, `confirmPhoneSubtitle`, `confirmPhoneEmailLabel`,
`confirmPhoneContinue`, `confirmPhoneCancel`, `confirmPhoneLeaveTitle`, `confirmPhoneLeaveBody`,
`confirmPhoneLeaveConfirm`, `confirmPhoneLeaveStay`, `whatsappCodeTitle`, `whatsappCodeSentTo`,
`whatsappOpen`, `whatsappResend`, `whatsappResendIn`, `whatsappResendInHours`, `whatsappEditNumber`,
`whatsappNotOnWhatsApp`, `whatsappContactSupport`, `otpBlockedUntil`, `otpAttestationFailed`,
`otpTemporarilyUnavailable`, `otpSuperseded`, `otpAttemptsExceeded`, `phoneAlreadyUsed`,
`confirmPhoneWelcome`, `phoneChanged`, `accountSignInMethod`, `accountMethodGoogle`,
`accountMethodApple`, `accountMethodEmail`, `accountPhoneConfirmed`, `accountChangePhone`.

Removed keys after deletion: `authPhoneTab`, `authEmailTab`, and SMS-specific strings no longer
referenced. The `l10n` unused-key check must pass.

## 8. Golden matrix

| Screen/state | L/D | RTL/LTR | 1.3× | 320/800 | keyboard |
|---|---|---|---|---|---|
| Login with social row (iOS, Android) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Register without phone | ✓ | ✓ | ✓ | ✓ | ✓ |
| «أكّد رقمك» form: full (Apple, no name) / number-only | ✓ | ✓ | ✓ | ✓ | ✓ |
| Code step: counting (s), counting (h), ready, error, not-on-WhatsApp, attestation | ✓ | ✓ | ✓ | ✓ | — |
| Blocked | ✓ | ✓ | ✓ | ✓ | — |
| Account rows | ✓ | ✓ | ✓ | ✓ | — |
