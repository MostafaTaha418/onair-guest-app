---
name: OnAir Guest App
description: واجهة عربية لاستكشاف وحجز الشقق الساحلية في مصر
colors:
  primary: "#006399"
  primary-light: "#147DBC"
  primary-deep: "#005580"
  accent: "#00677D"
  background: "#F7F7F3"
  surface: "#FFFFFF"
  text-primary: "#1A1A2E"
  text-secondary: "#6B7280"
  border: "#E1E1E1"
  nav-active: "#D6EBF7"
  favorite: "#E53935"
  available: "#4CAF50"
  vip-gold: "#D4AF37"
  offer-background: "#FFF3E0"
typography:
  auth-title:
    fontFamily: Cairo
    fontSize: "36px"
    fontWeight: 800
    lineHeight: 1.1
  section-title:
    fontFamily: Cairo
    fontSize: "18px"
    fontWeight: 800
  card-title:
    fontFamily: Cairo
    fontSize: "15px"
    fontWeight: 800
  body:
    fontFamily: Cairo
    fontSize: "14px"
    fontWeight: 400
  label:
    fontFamily: Cairo
    fontSize: "12px"
    fontWeight: 500
rounded:
  chip: "8px"
  field: "12px"
  button: "12px"
  card: "16px"
  sheet: "24px"
spacing:
  space4: "4px"
  space8: "8px"
  space12: "12px"
  space16: "16px"
  space20: "20px"
  space24: "24px"
  space32: "32px"
  space40: "40px"
  space48: "48px"
---

# Design System: OnAir Guest App

## Overview

OnAir has a calm coastal character: sea blue, warm off-white, large apartment photography, and clear white cards. The supplied screenshots are the visual reference for screen composition and component character. The [screenshot index](docs/design_reference/README.md) maps each screen and explains how to resolve conflicting examples.

This file records the intended visual direction and the tokens already present in the Flutter app. Match the visual structure of the references in future UI work, while adapting the exact dimensions to Android logical pixels, Arabic RTL, text scaling, and real device insets. The screenshots are examples of appearance, not a specification of backend features, prices, or content.

## Colors

Use sea blue `primary` for primary actions, links, icons, prices, and active navigation. `primary-light` starts the top gradient, which fades into the warm `background`. White `surface` cards sit on that background. Use dark navy `text-primary` for headings and `text-secondary` for supporting details. Use the existing semantic colors for favorites, availability, offers, and VIP only where those states exist in product data. Preserve sufficient contrast over photos with a scrim or solid surface.

Source of truth in code: `lib/design_system/tokens/on_air_colors.dart`. Dark mode has corresponding semantic tokens; retain that mapping when adding components.

## Typography

Use the bundled Cairo family for Arabic and mixed Arabic/Latin UI. Headings are bold and compact; descriptions are lighter and comfortable to read. The current Flutter roles are in `lib/design_system/typography/on_air_text_styles.dart`: authentication title 36sp (32sp on narrow screens), section title 18sp, listing title 15sp, body 14–16sp, and navigation label 10sp. Let text scale and wrap. Keep numbers, dates, currencies, and mixed-language strings legible in RTL rather than copying line breaks from screenshots.

## Layout

Use a 16dp screen gutter and the existing 4/8/12/16/20/24/32/40/48dp spacing scale in `lib/design_system/tokens/dimens.dart`. Preserve the photo-led hierarchy: welcome and search, area discovery, featured apartments where available, then listings. Cards should span the available content width with consistent gaps. Respect status and navigation bar safe areas and keyboard insets. Adapt height to content; do not scale a 540px screenshot directly to device pixels. Verify small phones, larger font settings, loading, empty, error, and populated states.

## Elevation & Depth

Keep depth quiet. White cards separate from the warm background through subtle borders or a soft shadow. Image cards can use a dark lower gradient for overlaid text. The top blue gradient should blend into the page, not end in a hard band. Avoid stacking many competing shadows or colored containers.

## Shapes

Cards use 16dp corners, sheets 24dp, chips 8dp according to the current token scale. The screenshots use especially rounded search and authentication fields and a capsule bottom navigation shell; preserve that visual character when changing those surfaces. All touch targets must be at least 48dp even if the visible icon is smaller.

## Components

- **Home header:** blue to off-white vertical gradient, Arabic greeting, circular profile and favorite controls, and a prominent white search field with a separate filter action.
- **Area card:** large cropped location photo, followed by a white information panel with area name, category badge, and available property count.
- **Apartment card:** large photo, availability or offer badge only when supported by data, price in EGP, concise attributes, a clear details action, and a separate favorite action.
- **Navigation:** floating white capsule with a light blue selected item. Keep the app's actual routes and labels; screenshots from older prototypes show a different tab set.
- **Forms:** generous vertical rhythm, pill-like white fields on the warm background, prominent sea-blue primary action, clear focus and error states.
- **Detail and booking:** image-first property view, restrained blue and warm offer/info panels, clear dates and itemized prices in EGP. Show only implemented payment and booking options.
- **Secondary screens:** white grouped settings cards, filter chips for notifications and reservations, and consistent empty/error states rather than blank areas.

## Do's and Don'ts

- Do use `docs/design_reference/screenshots/` as the visual reference for each screen and compare rendered results on a device or emulator.
- Do treat the six November 2026 screenshots as the newest reference for home and auth; use the August screenshots to cover other flows and details.
- Do preserve Arabic RTL, EGP prices, real listing content, existing navigation, accessibility, and working states.
- Don't copy dollar prices, English placeholder copy, fake counts, payment methods, or prototype-only functionality from the screenshots.
- Don't treat status bars, Android system navigation, accidental clipping, or screenshot compression as part of the design.
