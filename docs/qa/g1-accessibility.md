# G1 Accessibility Review

Scope: Guest Discovery (G1) — Home, Search, Results, Property Details, Gallery, and Reviews,
plus the G1 design-system components. Constitution VI and FR requirements: Arabic-first RTL,
`Semantics` labels on every icon-only control, ≥ 48×48 touch targets, visible + announced
field errors, text scale clamped to 1.3×, logical RTL focus order.

## 1. Static code verification (automatable — done)

Checked on 2026-10-29 against `lib/` (G1 screens, features widgets, and the new
design-system components):

| Requirement | Where | Result |
|---|---|---|
| Icon-only controls have labels | Home notifications bell: `Semantics(label: notifications, button: true)` + `tooltip` (`home_header.dart`) | ✓ |
| Icon-only controls have labels | Property share: `Semantics(label: propertyShare, button: true)` + `tooltip` (`property_screen.dart`); results share: same pattern (`results_screen.dart`) | ✓ |
| Icon-only controls have labels | Calendar previous/next month: `tooltip: calendarPrevMonth / calendarNextMonth` (`range_calendar.dart`); gallery close: `tooltip: galleryClose` (`gallery_screen.dart`); gallery-header back: `MaterialLocalizations.backButtonTooltip` (`property_gallery_header.dart`) | ✓ |
| Icon-only controls have labels | CounterStepper minus/plus: `tooltip` per button + widget-level `Semantics(value, label)` (`counter_stepper.dart`) | ✓ |
| Tappable non-button controls announced | Home search box wrapped in `Semantics(label: homeSearchHint, button: true)` (fixed in this pass; it was a bare `InkWell`) | ✓ |
| Chip removal announced | Filter chip delete uses `deleteButtonTooltipMessage` = `filterChipRemove(label)` with the chip's actual label (fixed in this pass; it passed an empty label) (`results_screen.dart`, `filter_chip_bar.dart`) | ✓ |
| Touch targets ≥ 48×48 | `IconButton`s use the 48-dp Material default; CounterStepper buttons are 48×48; RangeCalendar day cells are `Dimens.minTouchTarget` (48) squares | ✓ |
| Calendar day semantics | Each day cell exposes `calendarUnavailableDay(date)` («20 نوفمبر، مش متاح») for unavailable nights and the day number otherwise (`range_calendar.dart`) | ✓ |
| Gallery position announced | «صورة N من M» is a `Semantics(label: …, excludeSemantics: true)` label on the position pill (`property_gallery_header.dart`) and on the gallery screen | ✓ |
| Field errors visible + announced | Search location field and the G0 fields use `OnAirTextField`, whose error text is a `Semantics` live region (G0 T032) | ✓ |
| Text scaling | `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` at the app root; G1 goldens render the screens and components at 1.3× in light/dark | ✓ |
| RTL layout | Locale fixed to `ar`; all G1 layout uses `EdgeInsetsDirectional` / `AlignmentDirectional` / `PositionedDirectional`; the calendar is a direction-aware grid whose previous-month chevron points right (correct for RTL) | ✓ (static) |
| Focus order | Single-column layouts; tab order follows reading order in every G1 screen; the details screen walks one `SliverList` top-to-bottom | ✓ (static) |
| No hard-coded strings/colors | Enforced by `tool/check_hardcoded_styles.sh` (T103: zero hits) and the l10n rule | ✓ |

## 2. Screen-reader end-to-end runs (needs devices — pending)

The remaining part is quickstart scenario 17: the G1 journey (Home → Search → Results →
Details → Gallery → Reviews, plus share) completed with TalkBack (Android) and VoiceOver
(iOS) on real devices. Record the result of each screen here when executed.

Procedure (repeat for TalkBack and VoiceOver):

1. Home: greeting, search box (announced as a button), section headings, area cards with
   their listing counts; upcoming booking card when signed in.
2. Search: location field with suggestion list, date field opening the sheet, guest
   stepper (value + label announced), filters button; «ابحث» as a button.
3. Results: summary bar, filter chips with their remove actions («شيل فلتر …»), property
   cards merged into one label (title, subtitle, price); the share button announced.
4. Details: gallery position «صورة 1 من 8», section headings, specs row, rules, policy
   lines, availability calendar days (unavailable = «مش متاح»), reviews; share and
   «احجز الآن» as the last controls.
5. Gallery: close button, swipe between photos with position announcements.
6. Reviews: list of reviews with star ratings and reviewer names; pagination.
7. Share sheet: trigger the property and search share actions and confirm the system
   sheet opens with title + link.

Result table:

| Screen | TalkBack result | VoiceOver result | Notes |
|---|---|---|---|
| Home | — | — | Left open for the tester (scenario 17) |
| Search | — | — | — |
| Results | — | — | — |
| Details | — | — | — |
| Gallery | — | — | — |
| Reviews | — | — | — |

**Status: static pass complete; the device runs above remain open (they do not block the
G1 code review — same treatment as the G0 review).**
