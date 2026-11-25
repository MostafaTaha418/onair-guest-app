# Feature Specification: Guest Favorites & Reviews (G5)

**Feature Branch**: `feature/007-guest-favorites-reviews`

**Created**: 2026-11-25

**Status**: Draft

**Input**: User description: "G5 — المفضلة والتقييمات لتطبيق المستأجر OnAir (الجزء 007، أولوية P1)" — the
next spec after G4 per Guest Plan §17 ("G5 — المفضلة والتقييمات (P1)"). Two capabilities: (1) **المفضلة**
— add/remove a property from favorites anywhere in the app, a «المفضلة» tab in the bottom navigation,
direct row ownership under RLS, optimistic toggle with rollback on failure, no double-submit on fast
taps, empty/loading/error states, account required; (2) **التقييمات** — write a 1–5 star rating plus a
comment, available only after a confirmed check-out, shown as «قيد المراجعة» until OnAir moderates it,
and approved reviews (abbreviated reviewer name) shown on the property details screen, with the guest's
own review and its status visible in booking details. Arabic-first RTL, both light and dark modes, and a
mock mode on the same contract until the backend is ready.

**Sources**: `docs/OnAir Guest App Plan.md` (§1.1 المفضلة/التقييم rows, §1.2, §2.7.2 `favorites` /
`property_reviews`, §4.3 Reviews gradient, §4.7 `PropertyCard`, §5.1–§5.3 routes `/favorites`,
`/property/:id`, `/property/:id/reviews`, `/bookings/:id/review`, §6.5 property details reviews section,
§6.14 المفضلة, §6.15 التقييم, §9.3 `review.approved` / `review.rejected` / `stay.completed` review
invite, §10 RPCs `favorites` insert/delete, `guest_list_favorites`, `guest_list_property_reviews`,
`guest_submit_review`, §17 G5, §19 item 4 (comment limits open for G5)), `docs/OnAir Master Plan.md`
(decision 103 favorites & reviews, AC-048/AC-049), `docs/OnAir Backend Master Plan.md`
(`favorites`, `property_reviews`), `DESIGN.md`, `docs/design_reference/README.md` and its screenshots,
`.specify/memory/constitution.md`, `specs/002-guest-discovery/spec.md` (PropertyCard, home/search feed),
`specs/004-guest-stay-cancellation/spec.md` (check-out confirmation, booking details, `available_actions`).

## Clarifications

### Session 2026-11-25

- Q: Is the review text comment mandatory or optional? → A: Optional — stars (1–5) are required and enable
  «إرسال»; the comment may be left empty.
- Q: Should the review comment length limit be fixed now or left server/config-driven (Guest Plan §19
  open item)? → A: Server/config-driven (the server is the authority); the app shows only a provisional
  max-length hint (~500 chars) for inline validation, with no invented value baked in.
- Q: If a review is rejected in moderation («غير مقبول»), may the guest edit and resubmit it? → A: The
  server decides; the app shows an «عدّل تقييمك» / resubmit action only when the server's eligibility flag
  allows it, and never assumes a second review is permitted.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Save and manage favorite apartments (Priority: P1)

A signed-in guest taps the heart on an apartment — from a property card on the home feed or search
results, or from the apartment details screen — and the apartment is saved to «المفضلة». The heart fills
immediately. Opening the «المفضلة» tab shows every saved apartment as a `PropertyCard` grid/list, each
still tappable through to its details and still bookable. Tapping a filled heart again removes the
apartment, and the change is reflected everywhere the same apartment is shown. If an apartment the guest
saved is no longer published, it appears dimmed with «غير متاحة حاليًا» and can still be removed.

**Why this priority**: Favorites is the lightest high-value action a guest takes while browsing; it
drives return visits and shortlisting before booking (decision 103), and the heart already appears on
every property card and the details gallery, so today those taps land nowhere for signed-in guests.

**Independent Test**: Sign in, favorite three apartments from different surfaces (home card, search
result, details), open «المفضلة» and confirm all three appear; remove one and confirm it disappears here
and its heart clears on the other surfaces; unpublish one (mock) and confirm it shows dimmed with
«غير متاحة حاليًا» and can still be removed.

**Acceptance Scenarios**:

1. **Given** a signed-in guest viewing a property card or details, **When** they tap the empty heart,
   **Then** the heart fills immediately (optimistic), the apartment is saved to their favorites, and the
   same filled state shows on every other place that apartment appears.
2. **Given** a saved apartment, **When** the guest taps the filled heart, **Then** it clears immediately
   and the apartment is removed from «المفضلة».
3. **Given** the save or remove request fails (network/server), **When** the response returns, **Then**
   the heart reverts to its previous state and a clear message appears, with no duplicate or orphaned
   favorite created.
4. **Given** the guest taps the heart repeatedly or very fast, **When** the requests are in flight,
   **Then** the end result matches the final intended state and no more than one favorite row exists for
   that apartment (no double-submit).
5. **Given** the guest opens «المفضلة» with no saved apartments, **When** the screen loads, **Then** an
   empty state invites them to explore and start saving, with no error shown.
6. **Given** a favorited apartment that is no longer published, **When** the guest views «المفضلة»,
   **Then** it appears dimmed with «غير متاحة حاليًا», is not tappable through to a live booking, and can
   still be removed.
7. **Given** a visitor who is not signed in, **When** they tap a heart, **Then** they are sent to sign in
   and, after success, return to the same place with the apartment now favorited.
8. **Given** the «المفضلة» list is loading or failed to load, **When** the guest is on the screen,
   **Then** a loading placeholder or a retryable error view is shown (never a blank screen), and the
   saved items are available offline from the last successful load.

---

### User Story 2 - Rate a stay after check-out (Priority: P1)

A guest who has completed a stay (confirmed check-out) opens «قيّم إقامتك» from the booking details or
from the «stay.completed» notification. They pick 1–5 stars and optionally write a short comment, then submit. The
app confirms «شكرًا! هيظهر تقييمك بعد المراجعة» and the booking details now show the review status
(«قيد المراجعة» / «منشور» / «غير مقبول»). Only one review per stay is allowed, and the option is offered
only after the server confirms the check-out.

**Why this priority**: Reviews are the trust signal that makes other guests book (decision 103,
AC-048/AC-049), and the completion notification already invites the guest to rate. Without this screen
the invitation and the «قيّم» action on completed bookings lead nowhere.

**Independent Test**: With a booking in a confirmed checked-out/completed state, open the review screen,
submit 4 stars and a comment, confirm the thank-you message and that booking details show «قيد المراجعة»;
confirm the same booking no longer offers to write a second review.

**Acceptance Scenarios**:

1. **Given** a booking the server marks as checked-out/completed, **When** the guest opens its details,
   **Then** a «قيّم إقامتك» action is available; for any other booking state the action is absent.
2. **Given** the review screen, **When** the guest has not chosen a star rating, **Then** «إرسال» is
   disabled; choosing 1–5 stars enables it.
3. **Given** the guest submits a rating and comment, **When** they tap «إرسال» twice quickly or while it
   is sending, **Then** exactly one review is created and the button shows progress until it finishes.
4. **Given** a successful submission, **When** the response returns, **Then** the guest sees
   «شكرًا! هيظهر تقييمك بعد المراجعة», and the booking details show the review as «قيد المراجعة».
5. **Given** a stay that already has a review, **When** the guest opens its details, **Then** they see
   their submitted rating/comment and its moderation status, and no option to submit again.
6. **Given** the server rejects the submission (check-out not confirmed, already reviewed, comment
   outside allowed length), **When** the response returns, **Then** a clear localized message is shown
   mapped from the server error code, and nothing is shown as submitted.
7. **Given** a «review.approved» or «review.rejected» notification, **When** the guest taps it, **Then**
   the matching booking details open (after sign-in if needed) showing the new status «منشور» / «غير
   مقبول».

---

### User Story 3 - See apartment ratings and reviews before booking (Priority: P2)

Anyone viewing an apartment (including a visitor who is not signed in) sees its average rating and the
count of approved reviews near the title, and a reviews section (in the Reviews gradient) with the most
recent approved reviews and «عرض الكل». Tapping «عرض الكل» opens the full approved-reviews list. Each
review shows stars, an abbreviated reviewer name (e.g. «أحمد م.»), the comment, and when it was written.
Only OnAir-approved reviews ever appear, and no personal data about reviewers is shown.

**Why this priority**: Ratings and reviews on details are the pay-off of US2 and complete the trust loop,
but the booking journey already functions without them, so they rank just below creating favorites and
reviews. They are read-only and available to visitors.

**Independent Test**: Open an apartment with several approved reviews, confirm the average rating and
count near the title and the latest approved reviews in the Reviews section, tap «عرض الكل» and confirm
the full list paginates with abbreviated names and no personal data; open an apartment with no approved
reviews and confirm a neutral «لسه مفيش تقييمات» state.

**Acceptance Scenarios**:

1. **Given** an apartment with approved reviews, **When** a guest or visitor opens its details, **Then**
   the average rating and approved-review count appear near the title, and the Reviews section shows the
   most recent approved reviews with «عرض الكل».
2. **Given** the reviews list, **When** it is shown, **Then** only approved reviews appear, each with
   stars, an abbreviated reviewer name, the comment, and its date; no reviewer contact or full name is
   revealed.
3. **Given** «عرض الكل», **When** the guest taps it, **Then** the full approved-reviews list opens and
   loads more as they scroll.
4. **Given** an apartment with no approved reviews, **When** its details open, **Then** a neutral empty
   reviews state is shown and the average rating area reflects «لسه مفيش تقييمات» without a misleading
   zero score.
5. **Given** the reviews fail to load, **When** the guest is on the details or reviews screen, **Then** a
   retryable error view is shown for that section only, without blocking the rest of the details.

---

### Edge Cases

- **Favorite of an unpublished/removed apartment**: shown dimmed «غير متاحة حاليًا», not navigable to a
  live booking, still removable; favoriting is blocked if the apartment is not currently discoverable.
- **Favorites across devices**: favorites belong to the account, so a guest signing in on another device
  sees the same list after the next load.
- **Sign-out / account deletion**: local favorite caches are cleared on sign-out; account deletion
  removes the guest's favorites (personal data) per the G4 deletion policy.
- **Review on a stay that was cancelled, rejected, no-show, or still in progress**: the review action is
  absent and a manual/deep-link attempt is rejected by the server (no client-side eligibility decision).
- **Rejected review («غير مقبول»)**: the booking shows the status; whether the guest may edit and
  resubmit is the server's decision, rendered from the server's action/eligibility flag — the app does
  not assume a second review is allowed.
- **Comment length**: the minimum/maximum comment length is enforced by the server; the app mirrors the
  server-provided limit for inline validation and shows the mapped error if the server rejects it.
- **Offline**: favoriting while offline reverts with an «مفيش اتصال» message; the last loaded favorites
  and property reviews remain readable offline.
- **Very long comments / RTL mixed with Latin / emoji**: render correctly in both themes and at the
  largest supported text scale without breaking cards.
- **Rapid toggling the heart** while a previous request is in flight resolves to the final state with a
  single resulting row.

## Requirements *(mandatory)*

### Functional Requirements

#### Favorites

- **FR-001**: Signed-in guests MUST be able to add an apartment to favorites and remove it, from a
  property card (home feed, search results, favorites list) and from the apartment details screen.
- **FR-002**: Favoriting MUST apply optimistically — the heart updates immediately — and MUST revert to
  the prior state with a clear message if the request fails, leaving no duplicate or orphaned favorite.
- **FR-003**: The favorite state of an apartment MUST be consistent across every surface that shows it
  within the session (toggling it in one place updates the others).
- **FR-004**: The system MUST prevent double-submission on fast or repeated taps so that at most one
  favorite row exists per apartment per guest, and the final state matches the guest's last intent.
- **FR-005**: The «المفضلة» tab MUST list the guest's saved apartments as property cards, each navigable
  to its details and bookable, with loading, empty, and retryable error states.
- **FR-006**: A favorited apartment that is no longer published MUST appear dimmed with «غير متاحة
  حاليًا», MUST NOT lead to a live booking, and MUST remain removable.
- **FR-007**: Favorites MUST require an account; a visitor who taps a heart MUST be routed to sign in and
  returned to the same place with the intended favorite applied after success.
- **FR-008**: Each guest MUST see and modify only their own favorites (row ownership enforced server-side);
  the app never reads or writes another guest's favorites.
- **FR-009**: The last successfully loaded favorites MUST be readable offline; favoriting actions attempted
  offline MUST revert with a no-connection message.

#### Writing a review

- **FR-010**: The «قيّم إقامتك» action MUST be offered only for bookings the server reports as
  checked-out/completed; the app MUST NOT decide eligibility on its own and MUST render it from server
  state / `available_actions`.
- **FR-011**: The review screen MUST let the guest choose a 1–5 star rating and, optionally, write a text
  comment; «إرسال» MUST be disabled until a star rating is chosen and MUST NOT require a comment (an empty
  comment is accepted).
- **FR-012**: The system MUST allow at most one review per stay; after a review exists, the booking MUST
  show the submitted rating, comment, and moderation status, and MUST NOT offer to submit again unless the
  server indicates resubmission is permitted.
- **FR-013**: On successful submission the app MUST show «شكرًا! هيظهر تقييمك بعد المراجعة» and reflect the
  review in booking details as «قيد المراجعة».
- **FR-014**: Review submission MUST be single-submit on double/fast taps (one review created) with a
  progress state until the response returns.
- **FR-015**: The review moderation status in booking details MUST be shown in plain Arabic as «قيد
  المراجعة» / «منشور» / «غير مقبول», derived from server state.
- **FR-016**: The review comment length limit MUST be server/config-driven (the server is the authority).
  The app MUST NOT bake in a final value; it MAY show a provisional max-length hint (~500 characters) for
  inline UX only, mirror the server-provided limit when available, and MUST show the mapped localized
  message when the server rejects the comment.
- **FR-017**: Tapping a «review.approved» / «review.rejected» / «stay.completed» (review invite)
  notification MUST open the matching booking details (after sign-in if needed) showing the current status
  or the review action.

#### Viewing approved reviews

- **FR-018**: Apartment details MUST show the average rating and the count of **approved** reviews near the
  title, and a Reviews section (Reviews gradient) with the most recent approved reviews and «عرض الكل».
- **FR-019**: «عرض الكل» MUST open the full approved-reviews list, paginated/loaded on scroll.
- **FR-020**: Only OnAir-approved reviews MUST be displayed; each shows stars, an abbreviated reviewer name,
  the comment, and its date, and MUST NOT reveal the reviewer's full name or any contact detail.
- **FR-021**: An apartment with no approved reviews MUST show a neutral empty reviews state and MUST NOT
  display a misleading zero/average score.
- **FR-022**: Reviews reading MUST be available to visitors (no account required) on details and the full
  list; the reviews section failing to load MUST not block the rest of the details.

#### Cross-cutting

- **FR-023**: All favorites and review screens MUST work in Arabic RTL and in both light and dark modes,
  use the design system (`PropertyCard`, heart `#E53935`, star `#FFB300`, Reviews gradient), and MUST NOT
  hard-code colors, text, or font sizes.
- **FR-024**: Every user-facing string MUST come from localization files; server errors MUST be shown via
  mapped localized messages (never raw server text).
- **FR-025**: Favorites and reviews MUST run against a mock implementation on the same contract so the
  screens work before the backend is ready, with a flag to switch to the real backend without UI changes.
- **FR-026**: Sign-out MUST clear locally cached favorites; account deletion MUST remove the guest's
  favorites as personal data (consistent with the G4 deletion policy).

### Key Entities *(include if feature involves data)*

- **Favorite**: a saved apartment for a guest — the apartment reference and when it was saved; owned by one
  guest, one row per guest+apartment. Carries enough of the apartment summary (title, image, price, rating)
  to render a card, plus whether the apartment is still published.
- **Property Review**: a guest's rating (1–5 stars) and comment for one completed stay — bound to one
  booking and one apartment, with a moderation status (قيد المراجعة / منشور / غير مقبول) and a created time.
- **Approved Review (public view)**: the read-only, moderated projection shown to everyone — stars,
  abbreviated reviewer name, comment, date — never the reviewer's identity or contact.
- **Apartment rating summary**: the average rating and approved-review count surfaced on cards and details,
  derived from approved reviews only.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A signed-in guest can add or remove a favorite from any surface in a single tap, and the
  change is visible on screen immediately (optimistic) and on every other surface after the action.
- **SC-002**: After any sequence of fast or repeated heart taps on one apartment, the final state matches
  the guest's last tap and exactly zero or one favorite exists for that apartment — never more.
- **SC-003**: A guest can open «المفضلة», see all saved apartments, and navigate to any apartment's details
  and start a booking without re-finding it in search.
- **SC-004**: A guest with a completed stay can submit a rating and comment and reach the thank-you
  confirmation in under one minute, and the booking immediately shows «قيد المراجعة».
- **SC-005**: No guest can submit more than one review for the same stay, and the review action never
  appears for a stay that has not been checked out.
- **SC-006**: Every apartment details screen shows the correct approved-review average and count, lists
  only approved reviews with abbreviated names, and never exposes a reviewer's full name or contact.
- **SC-007**: All favorites and reviews screens pass review in Arabic RTL, light and dark, at the largest
  supported text scale, with loading/empty/error states and no untranslated or hard-coded text.
- **SC-008**: The feature is fully usable in mock mode (no backend), and switching to the real backend
  requires no change to the screens.

## Assumptions

- **Comment length limits are an open plan item for G5** (Guest Plan §19 item 4; §6.15 «[يُحسم أثناء
  التنفيذ]»). Per the constitution, no invented final value is baked into the UI: the limit is read from
  server/app configuration (with a sensible provisional default used only for inline hints), and the server
  is the authority that accepts or rejects a comment.
- Favorites are stored per account and sync across devices on load; there is no separate device-only list.
- Favorites have no explicit ordering requirement beyond most-recently-saved first, and no folders/labels
  in this release.
- Reviews are not editable after submission in v1; whether a **rejected** review can be edited/resubmitted
  is decided by the server and rendered from its eligibility flag, not assumed by the app.
- One review per stay (per booking), as the server enforces (AC-048); the reviewer-name abbreviation format
  (e.g. «الاسم الأول + أول حرف») is produced by the server, not the app.
- Reviews and ratings shown anywhere are **approved-only**; unmoderated or rejected reviews are visible to
  their own author (in booking details) but never in public lists or averages.
- Reading reviews and ratings does not require an account; adding a favorite and writing a review do.
- Photos/media in reviews are out of scope for this release (text comment + stars only), matching the plan.
- This repository is the guest app only; the `favorites` table and `property_reviews` table, their RLS, and
  the `guest_submit_review` / `guest_list_property_reviews` / `guest_list_favorites` functions are owned by
  the backend repository (`onair-backend`); this feature consumes them and ships mock-first until they land.

## Dependencies

- Guest discovery (002) `PropertyCard` and property details screen (the heart and reviews section live
  there), and the home/search feeds that render favorite state.
- Guest stay/cancellation (004) booking details and confirmed check-out state / `available_actions` that
  gate the review action.
- Auth (005) sign-in gate and return-to-origin for the account-required favorite/review actions.
- Notifications center routing for `stay.completed` (review invite), `review.approved`, `review.rejected`.
- Backend (`onair-backend`): `favorites` (RLS, direct insert/delete + `guest_list_favorites`),
  `property_reviews` (`guest_submit_review`, `guest_list_property_reviews`), and the apartment rating
  summary surfaced in feed/details — delivered as server contract differences before remote mode on
  staging.
