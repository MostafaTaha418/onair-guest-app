---
name: OnAir
description: Arabic-first coastal apartment design system for guest and partner apps
colors:
  primary: "#006399"
  primary-light: "#147DBC"
  primary-dark: "#0A3D62"
  primary-deep: "#005580"
  brand-mark: "#00639A"
  accent-light: "#00677D"
  accent-dark: "#81D4FA"
  background-light: "#F7F7F3"
  background-dark: "#0F1419"
  surface-light: "#FFFFFF"
  surface-dark: "#1A2332"
  detail-surface-light: "#EBEBE7"
  detail-surface-dark: "#151C26"
  text-primary-light: "#1A1A2E"
  text-primary-dark: "#FFFFFF"
  text-secondary-light: "#6B7280"
  text-secondary-dark: "#B0BEC5"
  border-light: "#E1E1E1"
  border-dark: "#2A3544"
  selected-light: "#D6EBF7"
  selected-dark: "#1E3A5F"
  on-primary: "#FFFFFF"
  favorite: "#E53935"
  star: "#FFB300"
  available-badge: "#237A37"
  vip-gold: "#D4AF37"
  vip-surface-light: "#F5F0E1"
  vip-surface-dark: "#1C1810"
  vip-border-light: "#E8D9A8"
  vip-border-dark: "#4A3F1A"
  offer-light: "#FFF3E0"
  offer-dark: "#3D2E1B"
  offer-border-light: "#FFE0B2"
  offer-border-dark: "#6D4C1B"
  warning-light: "#ED6C02"
  warning-dark: "#FFB74D"
  warning-container-light: "#FFCC80"
  warning-container-dark: "#E65100"
  on-warning-container-light: "#E65100"
  on-warning-container-dark: "#FFCC80"
  error-light: "#C62828"
  error-dark: "#FFCDD2"
  success-light: "#2E7D32"
  success-dark: "#81C784"
  success-container-light: "#A5D6A7"
  success-container-dark: "#1B5E20"
  on-success-container-light: "#1B5E20"
  on-success-container-dark: "#A5D6A7"
  info-light: "#0288D1"
  info-dark: "#4FC3F7"
  info-container-light: "#81D4FA"
  info-container-dark: "#0277BD"
  on-info-container-light: "#01579B"
  on-info-container-dark: "#E1F5FE"
  pending-background-light: "#006399"
  pending-background-dark: "#1E3A5F"
  pending-text: "#FFFFFF"
  completed-background-light: "#E8F5E9"
  completed-background-dark: "#1B3D2F"
  completed-text-light: "#2E7D32"
  completed-text-dark: "#81C784"
  rejected-background-light: "#FDECEA"
  rejected-background-dark: "#3D1B1F"
  rejected-text-light: "#C62828"
  rejected-text-dark: "#EF9A9A"
  cancelled-background-light: "#F3F4F6"
  cancelled-background-dark: "#2A2A2A"
  cancelled-text-light: "#6B7280"
  cancelled-text-dark: "#B0BEC5"
  auth-gradient-start-light: "#004B74"
  auth-gradient-end-light: "#147DBC"
  auth-gradient-start-dark: "#002D47"
  auth-gradient-end-dark: "#0A3D62"
typography:
  auth-title:
    fontFamily: Cairo
    fontSize: "36px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-0.5px"
  section-title:
    fontFamily: Cairo
    fontSize: "18px"
    fontWeight: 800
  area-title:
    fontFamily: Cairo
    fontSize: "17px"
    fontWeight: 800
  card-title:
    fontFamily: Cairo
    fontSize: "15px"
    fontWeight: 800
  body:
    fontFamily: Cairo
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  input:
    fontFamily: Cairo
    fontSize: "15px"
    fontWeight: 500
  price:
    fontFamily: Cairo
    fontSize: "14px"
    fontWeight: 800
  action:
    fontFamily: Cairo
    fontSize: "15px"
    fontWeight: 600
  label:
    fontFamily: Cairo
    fontSize: "12px"
    fontWeight: 500
  navigation:
    fontFamily: Cairo
    fontSize: "10px"
    fontWeight: 700
rounded:
  chip: "8px"
  field: "12px"
  button: "12px"
  card: "16px"
  sheet: "24px"
  auth-field: "36px"
  pill: "999px"
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
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.action}"
    rounded: "{rounded.button}"
    height: "48px"
  search-light:
    backgroundColor: "{colors.surface-light}"
    textColor: "{colors.text-secondary-light}"
    rounded: "{rounded.pill}"
    height: "50px"
  search-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.text-secondary-dark}"
    rounded: "{rounded.pill}"
    height: "50px"
  apartment-card-light:
    backgroundColor: "{colors.surface-light}"
    textColor: "{colors.text-primary-light}"
    rounded: "{rounded.card}"
    padding: "16px"
  apartment-card-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.text-primary-dark}"
    rounded: "{rounded.card}"
    padding: "16px"
  navigation-light:
    backgroundColor: "{colors.surface-light}"
    textColor: "{colors.text-secondary-light}"
    rounded: "{rounded.pill}"
    height: "56px"
  navigation-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.text-secondary-dark}"
    rounded: "{rounded.pill}"
    height: "56px"
  status-success-light:
    backgroundColor: "{colors.success-container-light}"
    textColor: "{colors.on-success-container-light}"
    rounded: "{rounded.pill}"
  status-success-dark:
    backgroundColor: "{colors.success-container-dark}"
    textColor: "{colors.on-success-container-dark}"
    rounded: "{rounded.pill}"
---

# Design System: OnAir

## Overview

**Creative North Star: "A calm Egyptian coast, ready to explore."** OnAir combines sea blue, warm off-white space, confident Cairo type, and real property photography. The interface is practical and calm: one clear action at a time, readable prices, and restrained status color. This visual identity is shared by the guest app and the property partner app. Each app keeps the flows and navigation its users actually need.

This is the **standalone design contract** for new screens and features. The YAML frontmatter is machine-readable; the rules below say how to apply it. In Flutter, frontmatter `px` values mean logical dp for layout and sp for text, never screenshot pixels. The palette and component rules in this file are normative.

**Key characteristics:**

- Arabic first, with genuinely mirrored English layouts.
- Sea-blue header fading into a warm page, clean surfaces, large photos.
- Compact navigation and search, rounded cards, quiet borders.
- EGP prices and real product states; no claims or badges invented from a mockup.

**Partner handoff:** copy this file alone into the partner app root. The exact OnAir mark and Arabic/English lockups are embedded below as SVG source; save the appropriate blocks as assets or render them as vectors. Install the Cairo font family from a public font package such as Flutter's `google_fonts` package, with weights 400/500/600/700/800. Map these tokens to one shared partner theme, then apply the components to owner tasks such as properties, availability, booking requests, and payouts. This document contains the design rules and brand artwork needed for that work.

## Colors

Use semantic roles, not raw hex values in individual screens. Resolve each `*-light` or `*-dark` role by theme. `background-*` is the page canvas; `surface-*` is a card, form, sheet, or floating navigation surface. `text-primary-*` and `text-secondary-*` establish hierarchy. `primary` marks main actions and EGP prices; `accent-*` marks links such as “عرض الكل”. `selected-*` highlights an active navigation destination or a small chip. The floating bar itself has the surface color with no contrasting outline.

Home and auth backgrounds start with `primary-light` in light mode or `primary-dark` in dark mode and fade vertically into `background-*`. The current Flutter background gradient stops are 0, 0.44, and 0.7, with the last two stops using the background. Auth buttons use `auth-gradient-start-*` to `auth-gradient-end-*`, plus a small soft blue shadow. Photo overlays use a navy-to-transparent scrim only where text needs contrast.

Use `favorite` for a saved heart, `star` for ratings, `available-badge` for verified availability, and `vip-gold` with `vip-surface-*` only for a real VIP state. `offer-*` is a panel background only when an offer exists. Use matching background/foreground pairs for success, warning, info, pending, completed, rejected, and cancelled chips. Status always has a label or icon; color alone never conveys meaning. Disabled and loading controls keep their dimensions.

**The Evidence Rule.** Never show an availability, discount, VIP, rating, or payment badge unless product data establishes that state. “Available today” means available for tonight in the current guest app; it does not promise instant entry or approval.

## Typography

Cairo is the display, body, input, and label family in both languages. Install Regular (400), Medium (500), SemiBold (600), Bold (700), and ExtraBold (800) from a font package or the Cairo font's public distribution. Reuse the frontmatter roles rather than choosing a new size on each screen. On screens narrower than 360dp, the auth title reduces from 36sp to 32sp.

The hierarchy is: large auth title; 18sp bold section title; 17sp area title; 15sp bold apartment title; 14sp bold price; 14–16sp body; 12sp supporting label; 10sp navigation label. Body text wraps with comfortable line height. A property title and its price occupy opposite logical edges and may each take two lines. Format EGP amounts, dates, and phone numbers for the active locale; keep mixed Arabic/Latin strings readable in RTL.

**The Readable Cairo Rule.** Allow system text scaling. Increase control height or wrap before truncating an important price, action, validation error, or status.

## Layout

Use a 16dp screen gutter and the frontmatter spacing scale. The normal rhythm is 8dp within compact controls, 12–16dp inside cards, and 24–40dp between sections. Components size to content; screenshot raster pixels are not layout values. Respect status and navigation bars, cutouts, keyboards, and bottom sheets. Leave scroll extent so a floating bar never hides the last actionable item.

Home begins with a compact brand/greeting header, favorite control, a 50dp search field, and a separate 50dp filter action. A signed-in guest sees the white OnAir mark alone next to the greeting; a visitor sees mark plus name. The favorite action is a 56dp circular surface. The blue top gradient matches the auth screens. “عرض الكل” aligns opposite its section title. The home preview shows up to five areas, five available-tonight properties, and five newest properties; each has a dedicated full collection.

The phone navigation is a **floating capsule** over scrolling content. Its four guest destinations are Home, Bookings, Notifications, and Account. Each tab has a 20dp icon above a 10sp label. The selected tab uses `selected-*`. The bar has minimum 56dp content height, 16dp horizontal outer inset, and safe-area spacing; content remains visible around it. Search opens from the home search field. The adjacent filter action opens a bottom sheet and leads to separate filter results. In the partner app, keep these proportions but choose destinations from owner workflows. On wide tablets, adapt navigation instead of stretching the phone capsule across the screen.

Center forms and reading content at a sensible maximum width; auth currently caps at 480dp and uses 28dp side padding. Narrow phones, landscape, 1.3× text, and open keyboards must remain usable. Use directional spacing/alignment/positioning, not hard-coded left/right. Arabic mirrors layout: a back chevron points toward the right edge; English points left. Preserve system Back behavior.

**The Safe Area Rule.** Floating or sticky controls may overlay content only when users can scroll the last action fully above them.

## Elevation & Depth

Depth comes mainly from contrast between the warm page, clean surfaces, and photography. Use a quiet border or soft shadow when a card needs separation; avoid stacked heavy shadows. The auth gradient button has a 12dp blur shadow offset 4dp down. A dark scrim supports text on area and VIP imagery. Dark mode uses its own surfaces and borders rather than a mechanical inversion.

## Shapes

Ordinary cards use 16dp corners, ordinary buttons and fields 12dp, chips 8dp, and modal sheets 24dp. Auth fields use a 36dp pill radius; search and floating navigation are full capsules. Primary actions are at least 48dp high; icon-only touch targets are at least 48×48dp. Keep the same corner language in owner and guest surfaces and in loading/error states.

## Components

- **Brand:** use the exact vector artwork embedded below. White mark over the blue header; theme-colored mark on a plain surface. The same mark appears above login, registration, recovery, OTP, and new-password forms, as on the splash screen. A signed-in home header shows the mark alone; a visitor header shows mark plus name. Do not replace it with a generic home or profile icon. To make a white variant, replace `#00639A` with `#FFFFFF` in the SVG fill attributes.

  ```svg
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 50 65"><title>OnAir mark</title><g transform="translate(-25 -21)"><path d="M25 86V46a25 25 0 0 1 50 0v40H63V46a13 13 0 0 0-26 0v40Z" fill="#00639A"/><circle cx="55" cy="62" r="5" fill="#00639A"/></g></svg>
  ```

  **English lockup (exact vector):**

  ```svg
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 330.95 89.405"><title>OnAir logo</title><g transform="translate(0 88.205)"><g transform="translate(-33.925 -116.702) scale(1.357)"><path d="M25 86V46a25 25 0 0 1 50 0v40H63V46a13 13 0 0 0-26 0v40Z" fill="#00639A"/><circle cx="55" cy="62" r="5" fill="#00639A"/></g><path transform="translate(94.35 0) scale(0.1 -0.1)" d="M333,-12Q224,-12 158.5,26Q93,64 64,142Q35,220 35,338Q35,457 64,535.5Q93,614 158.5,653Q224,692 333,692Q442,692 507,653Q572,614 601,535.5Q630,457 630,338Q630,218 601,140.5Q572,63 507.5,25.5Q443,-12 333,-12ZM333,120Q391,120 420,144Q449,168 459,217Q469,266 469,338Q469,410 459,460Q449,510 420,535.5Q391,561 333,561Q276,561 246.5,535.5Q217,510 206.5,460.5Q196,411 196,338Q196,267 206.5,218Q217,169 246,144.5Q275,120 333,120Z" fill="#00639A"/><path transform="translate(159.05 0) scale(0.1 -0.1)" d="M49,0L49,503L201,503L201,472Q217,482 239,491.5Q261,501 285.5,507.5Q310,514 332,514Q385,514 420,500.5Q455,487 476,457Q497,427 506,378Q515,329 515,259L515,0L362,0L362,250Q362,297 356,326Q350,355 335,368Q320,381 292,381Q276,381 259,378Q242,375 227,370Q212,365 202,360L202,0L49,0Z" fill="#00639A"/><path transform="translate(213.15 0) scale(0.1 -0.1)" d="M9,0L177,680L441,680L610,0L451,0L417,125L197,125L165,0L9,0ZM220,250L397,250L328,554L290,554L220,250Z" fill="#00639A"/><path transform="translate(273.15 0) scale(0.1 -0.1)" d="M49,0L49,503L202,503L202,0L49,0ZM49,573L49,695L202,695L202,573L49,573Z" fill="#00639A"/><path transform="translate(296.45 0) scale(0.1 -0.1)" d="M49,0L49,503L202,503L202,446Q218,459 242,473.5Q266,488 293,500Q320,512 345,515L345,369Q321,366 294,357.5Q267,349 243,338.5Q219,328 202,319L202,0L49,0Z" fill="#00639A"/></g></svg>
  ```

  **Arabic lockup (exact vector):**

  ```svg
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400.95 132.7"><title>OnAir logo (Arabic)</title><g transform="translate(0 100.80000000000001)"><path transform="translate(1.3 0) scale(0.1 -0.1)" d="M253,0L253,131L382,131L382,0L253,0ZM47,-258Q36,-258 20,-256.5Q4,-255 -13,-254L-8,-125Q8,-125 23,-126Q38,-127 45,-127Q82,-127 103.5,-98Q125,-69 125,-14L125,503L278,503L278,-14Q278,-85 249,-140.5Q220,-196 168,-227Q116,-258 47,-258ZM382,0L382,131Q388,131 391.5,126.5Q395,122 397.5,113.5Q400,105 401,93Q402,81 402,66Q402,51 401,38.5Q400,26 397.5,17.5Q395,9 391.5,4.5Q388,0 382,0Z" fill="#00639A"/><path transform="translate(39.5 0) scale(0.1 -0.1)" d="M0,0L0,131L269,131L176,54L176,503L329,503L329,0L0,0ZM0,0Q-5,0 -9,4.5Q-13,9 -15,17.5Q-17,26 -18.5,38.5Q-20,51 -20,66Q-20,86 -18,100.5Q-16,115 -11.5,123Q-7,131 0,131L0,0ZM35,-224L35,-102L181,-102L181,-224L35,-224ZM232,-224L232,-102L378,-102L378,-224L232,-224Z" fill="#00639A"/><path transform="translate(79.4 0) scale(0.1 -0.1)" d="M88,0L88,703L240,703L240,0L88,0ZM99,-309Q79,-285 68.5,-263Q58,-241 58,-217Q58,-180 77,-151.5Q96,-123 127,-106.5Q158,-90 195,-90Q216,-90 237,-95.5Q258,-101 272,-111L236,-178Q227,-173 217.5,-171Q208,-169 199,-169Q175,-169 162,-182Q149,-195 149,-215Q149,-227 154,-238Q159,-249 169,-260L99,-309ZM35,-319L35,-241L293,-241L293,-319L35,-319Z" fill="#00639A"/><path transform="translate(133.9 0) scale(0.1 -0.1)" d="M349,-248Q260,-248 190,-215.5Q120,-183 80,-126Q40,-69 40,4Q40,24 43,56.5Q46,89 51,129Q56,169 62.5,211.5Q69,254 75,294L226,274Q216,207 208.5,152.5Q201,98 197,60.5Q193,23 193,5Q193,-32 211,-59.5Q229,-87 264,-102Q299,-117 349,-117Q402,-117 433,-101.5Q464,-86 477,-60.5Q490,-35 490,-3L490,503L643,503L643,-3Q643,-77 605,-132Q567,-187 500.5,-217.5Q434,-248 349,-248ZM266,552L266,674L420,674L420,552L266,552Z" fill="#00639A"/><path transform="translate(205 0) scale(0.1 -0.1)" d="M248,-258Q210,-258 169,-252.5Q128,-247 83,-237L106,-115Q155,-121 189.5,-124Q224,-127 248,-127Q316,-127 346,-103Q376,-79 376,-30L376,394L407,372L296,372Q262,372 239,363.5Q216,355 204.5,328.5Q193,302 193,247Q193,196 203,171Q213,146 236,138.5Q259,131 296,131L376,131L376,0L296,0Q212,0 154.5,27Q97,54 68.5,109Q40,164 40,247Q40,331 68.5,388Q97,445 154.5,474Q212,503 296,503L529,503L529,-30Q529,-100 494,-151.5Q459,-203 396,-230.5Q333,-258 248,-258Z" fill="#00639A"/><path transform="translate(264.6 0) scale(0.1 -0.1)" d="M88,0L88,703L240,703L240,0L88,0ZM99,789Q79,813 68.5,835Q58,857 58,881Q58,918 77,946.5Q96,975 127,991.5Q158,1008 195,1008Q216,1008 237,1002.5Q258,997 272,987L236,920Q227,925 217.5,927Q208,929 199,929Q175,929 162,916Q149,903 149,883Q149,871 154,860Q159,849 169,838L99,789ZM35,779L35,857L293,857L293,779L35,779Z" fill="#00639A"/><g transform="translate(291.375 -125.646) scale(1.461)"><path d="M25 86V46a25 25 0 0 1 50 0v40H63V46a13 13 0 0 0-26 0v40Z" fill="#00639A"/><circle cx="45" cy="62" r="5" fill="#00639A"/></g></g></svg>
  ```

- **Icons:** use Cupertino first, then Lucide if Cupertino has no clear match. Keep outline/filled pairs consistent. Simple `<`/`>` chevrons mirror with locale and retain accessible labels.
- **Primary action:** solid `primary` with `on-primary` text, 12dp corners and at least 48dp height. Auth uses the blue gradient and pill form where shown. Disable immediately during an asynchronous action so rapid taps cause one operation; show progress in place without resizing. Secondary actions use quiet text or outlined styles.
- **Inputs and validation:** theme surface fill, neutral border, blue focus, distinct error border and message below the relevant field. Auth fields are pill-shaped with 15sp Cairo text and 22dp horizontal inset. Empty and invalid fields show specific localized errors on submit. Preserve keyboard action, autofill, obscuring, focus order, and loading behavior.
- **Area card:** 140×170dp photo-led tile in the phone carousel, 16dp corners, dark lower scrim, 12dp inset, white title and small count badge. The full collection can use a responsive grid with the same card character.
- **Apartment card:** 16dp rounded surface; 16:11 cover image; optional badges over the photo at logical start/end; 16dp information inset. Title and EGP price sit at opposite logical edges. Location/rating follow; attributes wrap in selected-tone chips when present. A 48dp details button fills the row beside an independent 48dp favorite button. Arabic mirrors the composition. Missing offers or unknown availability leave no placeholder badge.
- **Property detail and booking:** lead with gallery, title and EGP nightly price, verified offer/availability panels, facts, amenities, location, reviews, rules, and a clear booking action where implemented. Booking uses distinct check-in/check-out controls and an itemized price summary. Show only implemented payment and booking options.
- **Lists and notifications:** grouped surface cards, compact filter chips, meaningful unread/status indicators, and clear actions. Apply the same rhythm to reservations, favorites, settings, and partner management lists.
- **States:** use skeletons for loading, a useful action in empty states, retry for recoverable errors, offline feedback, and visible disabled states. Keep page structure stable while data arrives. Protect confirmations against repeated taps.

Use platform back and keyboard conventions with this brand styling on Android and iOS. Respect the operating system's reduced-motion preference; animation should clarify a transition rather than delay a task.

## Do's and Don'ts

- **Do** read this file before a new guest or partner feature spec, plan, task list, or UI implementation. In Spec Kit, add this requirement to `spec.md`: “All UI in this feature follows the root DESIGN.md tokens, components, and interaction rules in Arabic/English, RTL/LTR, light/dark, narrow/wide layouts, enlarged text, keyboard, loading/empty/error states, accessibility, and repeated-tap protection.” Carry it into `plan.md`, `tasks.md`, and verification.
- **Do** create one shared partner theme and component library from these roles, then reuse them in every feature.
- **Do** use the embedded vectors for the exact mark and lockups, and install Cairo as specified above. Compare rendered screens against the component descriptions in this document.
- **Do** verify a new screen in both languages and themes, at narrow and wide widths and increased text scale.
- **Don't** copy screenshot status bars, system navigation, clipping, placeholder photos, old English text, dollar prices, or unimplemented checkout features.
- **Don't** copy a guest flow into the partner app just to match a screenshot. Share the visual system while keeping partner permissions, tasks, and actions truthful.
- **Don't** create a second color, font, or radius vocabulary inside a feature. Update this contract and the shared theme together when the identity changes.
