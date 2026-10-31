# G2 Accessibility Review

Scope: Guest Booking & Payment (G2) — Book now, verify identity, dates, summary, payment
page, payment return, My Bookings, booking details, and the notification center.
Constitution VI and FR-038: Arabic-first RTL, `Semantics` labels on every icon-only
control, ≥ 48×48 touch targets, visible + announced field errors, text scale clamped to
1.3×, logical RTL focus order — plus the G2-specific rule that the owner-deadline
countdown must not announce every second.

## 1. Static code verification (automatable — done)

Checked on 2026-10-31 against the G2 screens and their new components:

| Requirement | Where | Result |
|---|---|---|
| Countdown announced once, not per tick | `_DeadlineCountdown` wraps the ticking `CountdownText` in `ExcludeSemantics` and exposes a single static `Semantics(label: <deadline text>)` on its container (`payment_return_screen.dart`) | ✓ |
| Icon-only controls have labels | Notifications bell: `Semantics(label, button: true)` + tooltip, with the unread count announced as `unreadBadge(count)` (`home_header.dart`) | ✓ |
| Icon-only controls have labels | Verify-screen retake buttons and the payment page's close button use text labels or `tooltip`s (`verify_identity_screen.dart`, `mock_payment_page.dart`) | ✓ |
| Touch targets ≥ 48×48 | All G2 actions use `OnAirPrimaryButton` / Material buttons (48-dp default); calendar day cells are `Dimens.minTouchTarget` squares (`range_calendar.dart`) | ✓ |
| Field errors visible + announced | Phone/WhatsApp fields on verify reuse `OnAirTextField`, whose error text is a live region (`verify_identity_screen.dart`) | ✓ |
| Stepper semantics | The dates-screen guest stepper is the same `CounterStepper` verified in G1 (`value` + `label` announced) | ✓ |
| Banner actions announced | The unfinished-payment banner and quote-changed banner use `InfoBanner` with a text button carrying a visible label (`unfinished_payment_banner.dart`, `summary_screen.dart`) | ✓ |
| Text scaling | `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` at the app root; the booking-flow goldens render dates, summary (plain + re-priced), payment return (all five states), and the notification center at 1.3× in light/dark | ✓ |
| RTL layout | Locale fixed to `ar`; all G2 layout uses `EdgeInsetsDirectional` / `AlignmentDirectional` (`summary_screen.dart`, `bookings_screen.dart`, `payment_return_screen.dart`) | ✓ (static) |
| Focus order | Single-column flows: dates → summary → return → details walk top-to-bottom; the notification center is one `SliverList` | ✓ (static) |
| No hard-coded strings/colors | Enforced by `tool/check_hardcoded_styles.sh` (zero hits) and the l10n rule; G2 interruption texts live in the ARB (`unfinishedPaymentBanner`, `quoteChangedNotice`, `termsChangedNotice`, …) | ✓ |

## 2. Screen-reader end-to-end runs (needs devices — pending)

The remaining part is quickstart scenario 25: the G2 journey (Book now → verify → dates →
summary → pay → result → My Bookings → details → notifications) completed with TalkBack
(Android) and VoiceOver (iOS) on real devices. Record the result of each screen here when
executed.

Procedure (repeat for TalkBack and VoiceOver):

1. Property: «احجز الآن» announced as a button at the end of the details walk.
2. Verify identity: phone field with its label and error live region, «has WhatsApp»
   switch, code field, resend button with its countdown.
3. Dates: calendar day cells (unavailable = «مش متاح»), guest stepper value, the nights
   summary, «متابعة» button.
4. Summary: amount rows in reading order (changed rows announce the old struck-through
   value then the new one), policy lines, the «الدفع» / «أكّد المبالغ الجديدة» button.
5. Payment page: the mock page's buttons (or the Kashier page on Staging) announced.
6. Payment return: «جاري التأكيد…» announced while waiting; the success screen announces
   the deadline text exactly once — never a per-second tick.
7. My Bookings: tabs announced, booking cards merged into one label with status and dates.
8. Details: status message, payments, timeline; arrival instructions only when confirmed.
9. Notifications: «X إشعار غير مقروء» on the bell, list rows with title + body, «تحديد
   الكل كمقروء» action.

Result table:

| Screen | TalkBack result | VoiceOver result | Notes |
|---|---|---|---|
| Book now / verify | — | — | Left open for the tester (scenario 25) |
| Dates | — | — | — |
| Summary | — | — | — |
| Payment page | — | — | — |
| Payment return | — | — | Static countdown rule verified in code |
| My Bookings / details | — | — | — |
| Notifications | — | — | — |

**Status: static pass complete; the device runs above remain open (they do not block the
G2 code review — same treatment as the G1 review).**
