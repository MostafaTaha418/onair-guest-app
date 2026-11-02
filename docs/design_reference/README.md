# OnAir visual reference

These 31 screenshots were supplied by the product owner on 2026-11-02. They are the visual baseline for future guest-app UI changes. The source JPEGs are preserved in `screenshots/`; they are reference material, not runtime app assets.

## How to use them

1. Read the root `DESIGN.md` and the relevant screen images before changing UI.
2. Use the November `current_concept` captures for the latest home and authentication direction. Use `ui_clone` and `prototype` captures for flows not shown there. Where images disagree, preserve the newest screen-specific layout and the current product behavior.
3. Translate proportions into Flutter logical dp rather than copying screenshot pixels. Use the token files for the starting scale, Cairo for text, at least 48dp touch targets, RTL layout, safe areas, and responsive text.
4. Compare the built screen with the reference for both populated and loading/empty/error states. Document any intentional departure in the change description.

Screenshots include old English copy, dollar amounts, payment and navigation concepts, and prototype data. They do not authorize new features or change OnAir's Arabic-first, EGP product rules. The images themselves are compressed screenshots with system bars and incidental clipping; those pixels are not UI targets.

## Screen index

The number is the image number in the original user message. All paths below are relative to this directory.

| # | Screen | File |
|---|---|---|
| 1 | Booking date calendar | [image](<screenshots/ui_clone/WhatsApp Image 2026-08-09 at 2.18.01 PM.jpeg>) |
| 2 | Booking price summary | [image](<screenshots/ui_clone/WhatsApp Image 2026-08-09 at 2.18.01 PM (1).jpeg>) |
| 3 | VIP apartment detail | [image](<screenshots/ui_clone/WhatsApp Image 2026-08-09 at 2.18.01 PM (2).jpeg>) |
| 4 | Home, English concept | [image](<screenshots/ui_clone/WhatsApp Image 2026-08-09 at 2.18.01 PM (3).jpeg>) |
| 5 | Login | [image](<screenshots/current_concept/WhatsApp Image 2026-11-02 at 9.06.18 PM.jpeg>) |
| 6 | Forgot password | [image](<screenshots/current_concept/WhatsApp Image 2026-11-02 at 9.06.17 PM (1).jpeg>) |
| 7 | OTP verification | [image](<screenshots/current_concept/WhatsApp Image 2026-11-02 at 9.06.17 PM.jpeg>) |
| 8 | Home apartment listings, Arabic | [image](<screenshots/current_concept/WhatsApp Image 2026-11-02 at 9.06.18 PM (1).jpeg>) |
| 9 | Home VIP and apartment sections, Arabic | [image](<screenshots/current_concept/WhatsApp Image 2026-11-02 at 9.06.18 PM (2).jpeg>) |
| 10 | Home top, Arabic | [image](<screenshots/current_concept/WhatsApp Image 2026-11-02 at 9.06.18 PM (3).jpeg>) |
| 11 | Reservations list | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.21 PM.jpeg>) |
| 12 | Profile | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.22 PM (1).jpeg>) |
| 13 | Settings | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.22 PM (2).jpeg>) |
| 14 | Notifications | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.22 PM (3).jpeg>) |
| 15 | Booking confirmation dialog | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.22 PM (4).jpeg>) |
| 16 | Favorites | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.22 PM.jpeg>) |
| 17 | Apartment amenities, map, reviews | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.23 PM (1).jpeg>) |
| 18 | Apartment detail top | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.23 PM (2).jpeg>) |
| 19 | Home, English prototype | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.23 PM (3).jpeg>) |
| 20 | Booking summary | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.32.23 PM.jpeg>) |
| 21 | Home, older prototype | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.17.41 PM.jpeg>) |
| 22 | Explore streets | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.18.19 PM.jpeg>) |
| 23 | Reservation statuses | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.19.32 PM.jpeg>) |
| 24 | Calendar and price breakdown | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.20.00 PM.jpeg>) |
| 25 | Notifications, older prototype | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.20.39 PM.jpeg>) |
| 26 | Settings, older prototype | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.21.54 PM.jpeg>) |
| 27 | Favorites, older prototype | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.22.17 PM.jpeg>) |
| 28 | Apartment detail, long page | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.23.18 PM.jpeg>) |
| 29 | Booking and payment concept | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.23.32 PM.jpeg>) |
| 30 | Payment choice concept | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.23.51 PM.jpeg>) |
| 31 | Checkout concept | [image](<screenshots/prototype/WhatsApp Image 2026-08-04 at 10.24.07 PM.jpeg>) |

## Measurement notes

The images show a mobile viewport around 540 screenshot pixels wide for the recent captures, while one older prototype is narrower. Screenshot pixels are raster output, so dp cannot be inferred without the capture density. The existing Flutter 16dp side gutter and spacing scale are reliable implementation anchors. Use 16dp card corners, 24dp sheets, and 48dp minimum targets as starting values, then visually tune each screen on an emulator. Auth and search controls appear more rounded than ordinary cards; apply the pill form deliberately when those screens are revised.
