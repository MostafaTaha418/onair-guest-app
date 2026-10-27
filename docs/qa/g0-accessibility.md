# G0 Accessibility Review (SC-009)

Scope: the Guest App Foundation (G0) screens and design-system components.
Constitution VI and FR requirements: Arabic-first RTL, `Semantics` labels on every
icon-only control, ≥ 48×48 touch targets, visible + announced field errors, text scale
clamped to 1.3×, logical RTL focus order.

## 1. Static code verification (automatable — done)

Checked on 2026-10-28 against `lib/` (design system + all G0 screens):

| Requirement | Where | Result |
|---|---|---|
| Icon-only controls have labels | Home notifications bell: `Semantics(label: notifications, button: true)` + `tooltip` (`home_placeholder_screen.dart`) | ✓ |
| Icon-only controls have labels | Login close button: `tooltip: authClose` (`login_screen.dart`) | ✓ |
| Icon-only controls have labels | Bottom nav items: per-item `Semantics` labels from `OnAirBottomNav` (`on_air_bottom_nav.dart`, T046) | ✓ |
| Non-icon controls | Sign-out button and every other action carries a visible text label; splash and the update-screen icon are decorative | ✓ |
| Touch targets ≥ 48×48 | Buttons use `Dimens.minTouchTarget` (48) height; account sign-out enforces `minimumSize: Size(0, 48)`; `IconButton`s use the 48-dp Material default | ✓ |
| Touch targets ≥ 48×48 | `OnAirOtpField`: the six 44×48 boxes are visual only — input is captured by a full-row invisible `TextField`, so the effective target is the whole field | ✓ |
| Field errors visible + announced | `OnAirTextField` shows the error text under the field and exposes it as a live region (`Semantics` `liveRegion`, T032) | ✓ |
| Text scaling | `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` at the app root (T039); goldens render every component and key screens at 1.3× in light/dark | ✓ |
| RTL layout | Locale fixed to `ar`; layout uses directional APIs; widget tests pin RTL (`app_locale_test.dart`, `app_shell_test.dart`) | ✓ |
| Focus order | Widget order follows reading order in every screen (single-column layouts,ListView ordering); no explicit focus traps | ✓ (static) |
| No hard-coded strings/colors | Enforced by `tool/check_hardcoded_styles.sh` in CI and the l10n rule | ✓ |

## 2. Screen-reader end-to-end runs (needs devices — pending)

The remaining part of SC-009 requires the phone sign-in journey completed with TalkBack
(Android) and VoiceOver (iOS) on real devices against the Staging backend. The Staging
Supabase project is not connected yet (research R22), so these runs are **pending**;
record the result of each step here when executed.

Procedure (repeat for TalkBack and VoiceOver):

1. Enable the screen reader, open the app → splash → Home (announce: Home, tab bar).
2. Activate My Bookings → login screen announced with title and fields.
3. Enter a Staging test number → error/next state announced (invalid format hint,
   country-not-supported message, or code-sent state).
4. Enter the OTP → each keystroke reachable, completion submits; error under the field
   is announced automatically (live region).
5. Complete profile (name, terms checkbox state announced) → Home signed in.
6. Sign out from My Account → confirmation and return to Home as visitor.

Result table:

| Device / reader | Date | Result | Notes |
|---|---|---|---|
| Android (TalkBack) | — | Pending Staging setup | — |
| iOS (VoiceOver) | — | Pending Staging setup | — |

**Status: static pass complete; SC-009 stays open until the two device runs above are
recorded.**
