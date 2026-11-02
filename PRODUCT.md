# OnAir Guest App

<!-- impeccable:product-schema 1 -->

## Platform

android

The Flutter app also targets iOS. Its current interface uses Material components across both platforms.

## Users

The primary user is a guest looking for an apartment stay and intending to book it.

## Product Purpose

OnAir helps guests discover, book, pay for, and manage short-term apartment stays. The home screen should help a guest find a suitable stay and move toward booking.

## Positioning

OnAir focuses on apartments in Egyptian destinations that the user says receive less attention from other booking apps, including Ras El Bar, Marsa Matrouh, and Baltim. The user wants prices presented in Egyptian pounds and considers fair pricing central to the product's appeal. A comparative price advantage has not been independently verified and must not be presented as a measured claim.

## Operating Context

The guest can browse destinations, suggested apartments, and newly listed apartments; search for a stay; and see an upcoming booking when one exists. The product is Arabic-first and supports right-to-left layout and English localization.

## Capabilities and Constraints

- The app is a Flutter mobile app for Android and iOS.
- Money handling in the current app supports EGP.
- The existing home screen includes search, destinations, suggested and newest apartments, and an upcoming booking section.
- UI work must preserve the existing booking and navigation flows unless a later request explicitly changes them.
- This repository is the guest app. Backend services, SQL, and migrations belong in the separate backend repository.

## Brand Commitments

The product name is OnAir. The app already has brand assets, Arabic and English copy, and a shared design system. Any home-screen refinement should work within these existing commitments unless the user requests a redesign of the identity.

## Evidence on Hand

- Existing product and platform details: `README.md`.
- Existing home behavior: `lib/features/home/presentation/`.
- Existing design system: `lib/design_system/` and `docs/UI_UX_DESIGN_SYSTEM.md`.
- Existing localized copy: `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`.
- The user supplied the destination focus and pricing intent; no verified competitive pricing study was supplied.

## Product Principles

1. Make finding and booking an apartment straightforward from the home screen.
2. Make the destination coverage visible and useful to guests.
3. Present prices clearly in Egyptian pounds without unsupported savings claims.
4. Preserve the app's Arabic-first experience and core booking flows.
