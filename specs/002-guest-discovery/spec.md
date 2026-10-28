# Feature Specification: Guest Discovery (G1)

**Feature Branch**: `feature/002-guest-discovery`

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "OnAir Guest App Plan.md" — the next open phase of the plan, G1 Discovery:
Home feed with cache, search and filters with full-stay availability, full apartment details
(gallery, rules and policies, mini availability calendar, approved reviews), and visitor browsing
that returns to the same point after sign-in.

**Sources**: `docs/OnAir Guest App Plan.md` (§1.1–§1.2, §5.1–§5.3, §6.3–§6.5, §10.1, §12, §13,
§14.2, §17 G1), `docs/OnAir Master Plan.md` (decisions 97–99, §13.4, AC-003, AC-010, AC-012,
AC-013, AC-047), `docs/UI_UX_DESIGN_SYSTEM.md`, `.specify/memory/constitution.md` v2.0.0,
`specs/001-guest-app-foundation/spec.md` (G0, already delivered).

## Clarifications

### Session 2026-10-28

- Q: Can a guest search without choosing a location, or is a location required? → A: Location
  is optional; a search without a location covers all areas.
- Q: When does a guest see the apartment's detailed address? → A: It is public on the apartment
  details page for everyone, including visitors (replaces the proposed "after confirmation" rule
  in Guest Plan §6.5 / §19.8).
- Q: Is the details calendar view-only, or can the guest pick dates from it? → A: The guest can
  pick arrival and departure on it; those dates replace any search dates and are carried into
  "Book now".
- Q: What happens when someone opens a shared link without the app installed? → A: The link
  sends them to the OnAir app's store page (Google Play or App Store, by device); no web
  preview page.
- Q: Without internet, can the guest open apartment pages they viewed before? → A: No. Only Home
  content is saved on the device; a page already open stays visible until the guest leaves it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find an apartment that is free for the whole stay (Priority: P1)

A person planning a trip opens Search, picks a location (governorate, city, or area), the arrival
and departure dates, and the number of guests. They can narrow the list by nightly price range,
minimum bedrooms and bathrooms, amenities, and property type, and sort by price (low to high or
high to low) or newest. The results show only approved apartments that are free for every night
of the requested stay. When dates are chosen, each result shows the nightly price and the total
for the stay, both as given by the server.

**Why this priority**: Finding a free apartment for specific dates is the reason a guest opens
the app and the entry point of every booking. Without reliable availability filtering, guests
waste time on apartments they cannot book (AC-012).

**Independent Test**: With seeded Staging or mock data containing approved, unapproved, booked,
blocked, and on-hold apartments, run searches with and without dates and filters, and confirm
that only approved apartments free for every requested night appear, that filters and sorting
change the list correctly, and that more results load as the tester scrolls.

**Acceptance Scenarios**:

1. **Given** the guest is on Search, **When** they type part of a location name, **Then**
   matching governorates, cities, and areas are suggested as they type, and an older suggestion
   list never replaces a newer one.
2. **Given** the guest chose a location, dates, and number of guests, **When** they search,
   **Then** the results list only approved apartments that are free for every night between
   arrival and departure and accept that many guests (AC-003, AC-012).
3. **Given** an apartment is booked, blocked by its owner, or held for another guest on any one
   night of the requested stay, **When** the guest searches those dates, **Then** that apartment
   does not appear.
4. **Given** dates are chosen, **When** results are shown, **Then** each card shows the final
   nightly price and "total for X nights", both taken from the server and never calculated on
   the device.
5. **Given** the guest searches without dates, **When** results are shown, **Then** each card
   shows the nightly price only, and the app explains that dates are needed to book.
6. **Given** the guest opens the filters panel, **When** they change any filter, **Then** the
   panel shows "Show X results" for the current choices, offers "Clear all", and applies the
   filters only when the guest confirms.
7. **Given** filters are active, **When** results are shown, **Then** each active filter
   appears as a removable chip above the list, and removing one refreshes the results.
8. **Given** more results exist than are shown, **When** the guest scrolls near the end,
   **Then** the next batch loads automatically without losing the scroll position.
9. **Given** no apartment matches, **When** the search finishes, **Then** the guest sees "No
   apartments are available for these criteria" with suggestions to change the dates or filters.
10. **Given** the guest opened an apartment from the results, **When** they go back, **Then**
    the same results, filters, and scroll position are shown without searching again.
11. **Given** the guest searched before, **When** they open Search again later, **Then** the
    last search is pre-filled so they can repeat or adjust it.

---

### User Story 2 - Understand an apartment fully before deciding to book (Priority: P1)

A guest opens an apartment and sees everything needed to decide: a photo gallery (swipe, and
full-screen view with zoom), name, type, area and city, the average rating and number of
approved reviews, bedrooms, bathrooms, maximum guests and size, an expandable description,
amenities, the area and detailed address, the stay rules (guests, visitors, check-in and check-out
times, other conditions), the deposit and cancellation policy in plain words, a small calendar
of unavailable days on which they can also pick their dates, and the latest approved reviews. A bar fixed at the bottom shows the final
nightly price and a "Book now" button. The stay rules and policy are visible before "Book now".

**Why this priority**: The decision to pay happens on this screen. Guests must understand the
price, rules, and cancellation terms before they commit, and the screen must prove which terms
they saw (AC-013).

**Independent Test**: Open several seeded apartments (with deposit, with full payment, with and
without reviews, with unavailable days) and confirm that every section shows the server's data,
that the owner's contact details and any "message the owner" option are absent, and that the
terms shown are the ones carried forward when "Book now" is tapped.

**Acceptance Scenarios**:

1. **Given** the guest taps an apartment card, **When** the details open, **Then** the card's
   photo appears at once and is replaced by a sharper version when it arrives.
2. **Given** the details are open, **When** the guest swipes the photos or taps one, **Then**
   they can move through all photos with a position indicator and open a full-screen view that
   supports zoom.
3. **Given** the details are open, **When** the guest reads the price, **Then** it is the final
   nightly price from the server as one number; no base price, margin, or extra fee appears
   (AC-010).
4. **Given** the details are open, **When** the guest scrolls, **Then** the stay rules and the
   deposit and cancellation policy are part of the page itself (not behind another step), and
   the fixed bottom bar always shows the price and "Book now".
5. **Given** the policy has a deposit, **When** the guest reads the policy section, **Then** it
   states the deposit (as a share or amount), the last moment for free cancellation, and what
   happens after it, in plain Arabic without accounting terms.
6. **Given** the apartment has unavailable days, **When** the guest views the calendar, **Then**
   those days are marked unavailable with no reason shown and no information about other
   guests' bookings.
7. **Given** the guest arrived with search dates or none, **When** they pick an arrival and a
   departure on the calendar, **Then** the new dates replace the old ones, appear in the bottom
   bar, and a range crossing an unavailable night cannot be picked.
8. **Given** the apartment has approved reviews, **When** the guest reaches the reviews
   section, **Then** the latest three approved reviews appear with a short reviewer name (for
   example "أحمد م."), plus "See all" that opens the full list in batches.
9. **Given** the apartment has no approved reviews, **When** the details open, **Then** no
   rating number is shown and the reviews section says there are no reviews yet.
10. **Given** any apartment, **When** the guest looks for a way to contact the owner, **Then**
    there is none: no owner phone, email, or chat; only "Have a question? Contact OnAir"
    (AC-047).
11. **Given** a signed-in guest taps "Book now", **When** the booking flow starts, **Then** the
    exact version of the terms that was on screen is carried into it as the guest's acceptance
    (AC-013), together with the current dates and number of guests.
12. **Given** the apartment is no longer approved or published, **When** the guest opens it from
    a list, a saved screen, or a link, **Then** a neutral "This apartment is not available"
    screen appears (AC-003).

---

### User Story 3 - Get ideas from the Home tab (Priority: P2)

A person opens the app and lands on Home. They see a greeting (with their name if signed in), a
prominent search box, a row of areas and destinations with the number of apartments in each,
suggested apartments, and the newest apartments. A signed-in guest with an upcoming confirmed
booking also sees a short card for it. On later visits, the last Home content appears instantly
and refreshes in the background.

**Why this priority**: Home is the first screen every guest sees and the main way to browse
without a plan, but a guest who knows what they want can use Search directly, so it ranks after
search and details.

**Independent Test**: Open the app as a visitor and as a signed-in guest on seeded data, confirm
each Home section loads independently, that an area opens matching search results, that a card
opens its details, and that a second launch shows the previous content at once, including when
offline.

**Acceptance Scenarios**:

1. **Given** the app opens on Home, **When** content is loading, **Then** each section shows its
   own skeleton, and a slow or failed section does not stop the others from appearing.
2. **Given** a section fails, **When** the guest sees its error, **Then** that section offers
   "Try again" while the others stay usable.
3. **Given** the guest taps the search box, **When** Search opens, **Then** it is ready for
   location, dates, and guests.
4. **Given** the guest taps an area, **When** the results open, **Then** they show apartments in
   that area.
5. **Given** the guest opened Home before, **When** they open it again, **Then** the previous
   content appears at once and is updated quietly when fresh data arrives.
6. **Given** the guest pulls down on Home, **When** they release, **Then** all sections refresh.
7. **Given** no approved apartments exist, **When** Home loads, **Then** it shows "No apartments
   are available right now" with an action to search.
8. **Given** a signed-in guest has an upcoming confirmed booking, **When** Home loads, **Then** a
   short card shows the nearest one with its status and dates; visitors and guests without one
   see no such card.

---

### User Story 4 - Browse as a visitor and continue after signing in (Priority: P2)

A visitor browses Home, Search, and apartment details without an account. When they tap an
action that needs an account (such as "Book now" or "Contact OnAir"), sign-in opens. After
signing in or creating an account, they return to the same apartment with the same dates and
number of guests they had chosen, and the action continues from there.

**Why this priority**: Letting people browse freely and asking for an account only at the moment
of commitment keeps the path to booking short. G0 built the general return-after-sign-in rule;
this story applies it to discovery with the guest's choices kept.

**Independent Test**: As a visitor, search with dates and guests, open an apartment, tap "Book
now", sign in, and confirm the app lands on the same apartment with the same dates and guests and
continues into booking. Repeat with cancelling sign-in.

**Acceptance Scenarios**:

1. **Given** a visitor, **When** they use Home, Search, results, details, the gallery, or the
   reviews list, **Then** nothing asks them to sign in.
2. **Given** a visitor on an apartment with chosen dates and guests, **When** they tap "Book
   now" and sign in successfully, **Then** they return to the same apartment with the same dates
   and guests, and the booking flow continues.
3. **Given** a visitor on sign-in, **When** they cancel, **Then** they return to the same
   apartment with their choices kept, still as a visitor.
4. **Given** a visitor creates a new account from that sign-in, **When** sign-up finishes,
   **Then** they return to the same point just as after a sign-in.

---

### User Story 5 - Share an apartment or a search (Priority: P3)

A guest shares an apartment or a search with family or friends. The recipient opens the link and
lands on that apartment, or on the same search results, in the app.

**Why this priority**: Sharing helps groups decide together and brings in new users, but booking
works without it.

**Independent Test**: Share an apartment and a search from the app, open each link on another
device with the app installed, and confirm it lands on the right screen; open a link to an
unapproved apartment and a malformed link and confirm the neutral "not available" result.

**Acceptance Scenarios**:

1. **Given** the guest is on an apartment, **When** they tap Share, **Then** the device share
   sheet opens with a link to that apartment.
2. **Given** the guest is on search results, **When** they share the search, **Then** the link
   carries the location, dates, guests, filters, and sort.
3. **Given** someone opens an apartment link, **When** the app opens, **Then** that apartment's
   details are shown, as a visitor if they have no account.
4. **Given** a link points to an unapproved, removed, or unknown apartment, or its ID is
   malformed, **When** it is opened, **Then** the neutral "not available" screen appears, the
   link changes nothing, and it reveals nothing about whether the apartment exists.
5. **Given** a shared search link has dates in the past, **When** it is opened, **Then** the
   search opens with the other criteria kept and the guest is asked to choose new dates.
6. **Given** the recipient does not have the app, **When** they open a shared link, **Then**
   they are sent to the OnAir app's store page for their device.

---

### Edge Cases

- Departure on or before arrival, or arrival in the past: the date picker does not allow it; a
  stay is at least one night.
- More guests than any apartment allows: the search returns no results with the standard empty
  message; on details, the maximum guests is shown clearly.
- An apartment becomes unavailable for the chosen dates between search and details: details show
  the server's current calendar; the booking step (G2) rejects the dates if still taken.
- The nightly price changes between the card and the details: details show the server's current
  price; the app never keeps an old price for booking.
- The terms change while the guest is on the details: the booking step (G2) is rejected by the
  server and the app shows the new terms again before the guest can continue.
- No internet: a top banner says there is no connection; Home shows its saved content; content
  already loaded on a screen stays visible; searching, loading more, and "Book now" are disabled
  until the connection returns.
- The guest types fast in the location field: only the latest text produces suggestions, and
  earlier requests are dropped.
- The guest leaves a screen while it is loading: its pending requests stop and do not update
  another screen.
- An apartment has a single photo or no photo: the gallery adapts (no indicator for one photo; a
  themed placeholder when none).
- A very long description, rules text, or amenity list: shown shortened with "Show more" or
  "See all".
- A reference list (locations, amenities, property types) fails to load: Search still opens and
  shows an error with retry for that part only.
- The server returns an error the app does not recognise: the generic unexpected-error message
  with a reference number is shown.
- An apartment saved in the Home cache was unpublished since: opening it shows "not available",
  and the next Home refresh removes it.

## Requirements *(mandatory)*

### Functional Requirements

**Home**

- **FR-001**: Home MUST show, in this order: a header with a greeting (with the guest's name
  when signed in) and the notifications bell, a search box, areas and destinations with each
  area's number of apartments, suggested apartments, and newest apartments.
- **FR-002**: Home MUST show only approved and published apartments in every section (AC-003).
  Which apartments are "suggested" MUST be decided by the server; the app shows the list it
  receives and adds no ranking of its own.
- **FR-003**: Home MUST show a short card for the nearest upcoming confirmed booking of a
  signed-in guest when the server provides one, with its status and dates, and MUST hide it for
  visitors and guests without one.
- **FR-004**: Each Home section MUST load, fail, and retry independently, with a skeleton shaped
  like its content while loading.
- **FR-005**: Home MUST show the last successfully loaded content at once on later visits and
  then refresh it in the background, and MUST support pull-to-refresh.
- **FR-006**: Tapping the search box MUST open Search; tapping an area MUST open results for
  that area; tapping an apartment MUST open its details.

**Search**

- **FR-007**: Search MUST let the guest set: location (governorate, city, or area chosen from
  server suggestions as they type), arrival and departure dates, number of guests, a nightly
  price range, minimum bedrooms, minimum bathrooms, amenities (multiple choice), property type,
  and sort order (price low to high, price high to low, newest).
- **FR-008**: The lists of locations, amenities, and property types MUST come from the server
  and MUST be kept on the device so they appear quickly, refreshing when the server reports a
  newer version.
- **FR-009**: Location and dates MUST both be optional for searching; a search without a
  location covers all areas, and the guest can search with no criteria at all. Arrival MUST NOT
  be in the past, and departure MUST be after arrival.
- **FR-010**: Location suggestions MUST update while the guest types, without waiting for them
  to finish, and MUST discard results of earlier, outdated typing.
- **FR-011**: Filters MUST be edited in a panel that shows the server's result count for the
  current choices ("Show X results"), offers "Clear all", and applies only on confirmation.
- **FR-012**: The last search (location, dates, guests, filters, sort) MUST be kept on the
  device and pre-filled when Search is opened again. It MUST NOT contain personal data.

**Results**

- **FR-013**: Availability for the full requested stay MUST be applied by the server. The app
  MUST NOT receive and then hide unavailable apartments; any apartment the server returns for
  the dates is shown as returned (AC-012).
- **FR-014**: Each result card MUST show at least a photo, name, area and city, the average
  approved rating when one exists, and the final nightly price. When dates are set, it MUST also
  show "total for X nights" as given by the server.
- **FR-015**: Results MUST load in batches as the guest scrolls, keeping the scroll position,
  and MUST show active filters as removable chips above the list.
- **FR-016**: The results, filters, and scroll position MUST be kept while the guest opens an
  apartment and comes back, and while they switch tabs, without a new search.
- **FR-017**: When nothing matches, results MUST show a clear empty message with suggestions to
  change the dates or filters.

**Apartment details**

- **FR-018**: Details MUST show: a photo gallery with a position indicator and a full-screen
  view with zoom; name, property type, area and city; average rating and number of approved
  reviews; bedrooms, bathrooms, maximum guests, and size; an expandable description; amenities
  with "See all"; area and detailed address; stay rules (guests, visitors and their number, check-in
  and check-out times, other conditions); the deposit and cancellation policy; a calendar of
  unavailable days; the latest three approved reviews with "See all"; and a fixed bottom bar
  with the final nightly price and "Book now".
- **FR-019**: The displayed price MUST be the final nightly price from the server as a single
  amount in Egyptian pounds. The app MUST NOT show or derive a base price, margin, discount, or
  any fee (AC-010).
- **FR-020**: The details page MUST show the area and city and the detailed address text from the
  approved listing to everyone, including visitors. Location is shown as text only (no map in
  this version). Owner contact details stay hidden (FR-024).
- **FR-021**: The stay rules and the deposit and cancellation policy MUST be shown on the details
  page itself, so the guest can read them before tapping "Book now", in plain Arabic without
  accounting terms, stating the deposit, the last moment for free cancellation, and what happens
  after it.
- **FR-022**: The calendar MUST mark unavailable days without any reason and without revealing
  other guests' bookings. The guest MUST be able to move between months and pick an arrival and
  a departure date on it. A range that includes an unavailable night or a past day MUST NOT be
  selectable. Picked dates replace any dates from Search, are shown in the bottom bar, and are
  the dates carried by "Book now". The device MUST NOT calculate a stay total from them.
- **FR-023**: Only approved reviews MUST appear, each with a rating, comment, date, and a short
  reviewer name (first name and initial). The full list MUST load in batches. With no approved
  reviews, no rating number is shown.
- **FR-024**: The owner's personal details (phone, email, name beyond what the listing publishes)
  MUST NOT appear, and there MUST be no way to message or call the owner. The only contact option
  is "Have a question? Contact OnAir", which opens OnAir support linked to the apartment
  (AC-047).
- **FR-025**: When the guest taps "Book now", the app MUST carry the exact terms version that was
  shown into the booking flow as the guest's acceptance (AC-013), together with the current
  dates (picked on the calendar, otherwise from Search) and the number of guests from Search.
- **FR-026**: The first photo MUST appear immediately from the card's already loaded image, then
  a sharper version replaces it. Reviews and the calendar MUST load only when the guest scrolls
  near them.
- **FR-027**: An apartment that is not approved, not published, removed, or unknown MUST show a
  neutral "This apartment is not available" screen that does not reveal whether it exists
  (AC-003).

**Visitors and returning after sign-in**

- **FR-028**: Home, Search, results, apartment details, the gallery, and the reviews list MUST be
  usable without an account.
- **FR-029**: "Book now" and "Contact OnAir" MUST require an account. For a visitor, they open
  sign-in; after sign-in or sign-up the guest MUST return to the same apartment with the same
  dates and guests and the tapped action MUST continue. Cancelling sign-in returns them to the
  same apartment as a visitor with their choices kept.

**Sharing and links**

- **FR-030**: The guest MUST be able to share an apartment, and a search (location, dates,
  guests, filters, sort), through the device share sheet as a verified OnAir link.
- **FR-031**: Opening an apartment or search link MUST land on that screen, for visitors too.
  The link MUST be format-checked first and MUST NOT change anything by itself; a malformed or
  forbidden link shows the neutral "not available" screen. Past dates in a search link are
  dropped and the guest is asked for new dates. On a device without the app, the link MUST send
  the person to the OnAir app's store page for their device (Google Play or App Store); no web
  preview of the apartment is shown.

**States, performance, and quality**

- **FR-032**: Every discovery screen MUST provide Loading (content-shaped skeleton), Empty,
  Error (message, retry, and reference number for unexpected errors), Offline (top banner,
  saved content shown, server actions disabled), and Success states. Only Home content and the
  reference lists are saved on the device for offline use; apartment details and search results
  are not stored for later, and a page that is already open stays visible offline until the
  guest leaves it. Opening a new apartment offline shows the offline state with retry.
- **FR-033**: Photos MUST be requested at the size they are displayed, with a themed placeholder
  while loading; only the next gallery photo may be fetched ahead.
- **FR-034**: Pending requests MUST stop when their screen is closed and MUST NOT update another
  screen.
- **FR-035**: All discovery screens MUST work in Light and Dark, right-to-left, and at the
  largest supported text size, use only design-system colors and text styles, and take every
  text from the translation files.
- **FR-036**: Every icon-only control (share, close, gallery arrows, filter chips' remove) MUST
  have a screen-reader label, touch targets MUST be at least 48×48, and the search → results →
  details journey MUST be usable with TalkBack and VoiceOver.
- **FR-037**: Amounts MUST be shown in Egyptian pounds and dates in the shared app format, both
  formatted in one place.
- **FR-038**: Until the real backend tables are ready, every discovery screen MUST work against
  the local mock built from the same draft contracts, so development and tests are not blocked.

### Key Entities

- **Published Apartment (listing)**: The public, approved version of an apartment: name, type,
  area and city, detailed address, photos in order, bedrooms, bathrooms, maximum guests,
  size, description, amenities, stay rules, policy summary, terms version, final nightly price,
  average approved rating, and number of approved reviews. Never includes owner contact details,
  base price, or margin.
- **Apartment Card**: The short form of a listing used in lists: photo, name, area and city,
  rating, final nightly price, and, when dates are set, the number of nights and the stay total
  from the server.
- **Location**: A governorate, city, or area that apartments belong to and that guests search
  by; areas on Home show their number of apartments.
- **Amenity** and **Property Type**: Server-provided reference lists used for filters and
  display.
- **Search Criteria**: Location, optional arrival and departure dates, guests, price range,
  minimum bedrooms and bathrooms, amenities, property type, and sort order. The last one is kept
  on the device and can be carried in a shared link.
- **Results Page**: One batch of apartment cards plus a marker to load the next batch and the
  total count.
- **Unavailable Days**: For one apartment and a date range, the days that cannot be booked, with
  no reason attached.
- **Approved Review**: Rating (1–5), comment, date, and short reviewer name; only reviews OnAir
  approved.
- **Stay Terms Version**: An identifier of the exact rules and policy text the guest saw on the
  details screen, carried into booking as their acceptance.
- **Home Feed**: The combined Home content (areas, suggested, newest, and the signed-in guest's
  upcoming booking card), kept on the device for instant display.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time visitor can go from opening the app to the details of an apartment
  that is free for their chosen dates in under 60 seconds.
- **SC-002**: Across all seeded test searches with dates, 0 apartments appear that are booked,
  blocked, or held on any requested night.
- **SC-003**: 0 unapproved or unpublished apartments appear on Home or in Search, or open from a
  link.
- **SC-004**: On a repeat launch, previously loaded Home content is visible within 1 second,
  including without a connection.
- **SC-005**: Scrolling through at least 100 search results on a mid-range Android phone shows no
  noticeable stutter, and the next batch appears before the guest reaches the end in normal
  scrolling.
- **SC-006**: When an apartment is opened from a card, its first photo is visible immediately
  (no blank photo area) in 100% of tests.
- **SC-007**: In 100% of tests, a visitor who signs in or signs up from "Book now" returns to the
  same apartment with the same dates and guests.
- **SC-008**: 0 owner contact details or owner messaging options exist anywhere in discovery.
- **SC-009**: 100% of discovery screens pass visual comparisons in Light, Dark, right-to-left,
  and enlarged text, and have tests for their Loading, Empty, Error, Offline, and Success states.
- **SC-010**: The search → results → details journey can be completed end to end with TalkBack
  and with VoiceOver.
- **SC-011**: In usability checks, at least 90% of testers correctly state, after reading an
  apartment's details, the nightly price, the deposit, and until when they can cancel for free.

## Assumptions

- G0 (feature 001) is delivered: navigation shell, sign-in and sign-up, the general
  return-after-sign-in rule, link handling with a configurable domain, design system, error
  handling, Money and date formatting, and the local mock. G1 builds on these.
- Seeded data (approved and unapproved apartments, booked, blocked, and held dates, apartments
  with deposit and with full payment, apartments with and without reviews) is available on
  Staging or in the local mock. Real listings depend on the Owner app and Admin dashboard
  (Guest Plan §17 G1).
- Availability, approval, final price, stay totals, suggestion logic, and result counts are
  computed by the server; the app only displays them (Constitution Principle II).
- "Book now" in G1 delivers the sign-in gate, the return to the same point, and carrying the
  shown terms version, dates, and guests. The booking flow itself (verify phone, choose dates,
  quote, summary, payment) and the server's recording of terms acceptance belong to G2.
- "Contact OnAir" requires sign-in and opens the support entry point linked to the apartment;
  the full support experience is delivered in G4.
- The upcoming-booking card on Home and the unread count on the bell show real data once
  bookings (G2) and notifications (G2) exist; until then they stay hidden or show no count.
- Favorites (adding or removing with the heart) belong to G5 and are not part of G1. Writing
  reviews belongs to G5; G1 only displays approved reviews.
- There is no map in this version (Guest Plan §1.2, §6.4.3); location is shown as text.
- The detailed address is public on the details page (Clarification 2026-10-28), recorded in
  `docs/decisions/D-001-public-property-address.md` and reflected in Guest Plan §6.5, §6.8,
  §10.1, §18, and §19.8. It still needs agreement from the team and the backend owner, since the
  public listing data must include the address text (without coordinates). Arrival instructions
  stay visible only after a booking is confirmed.
- The default sort is the server's default (assumed newest first) unless the guest picks one.
- Results load in batches of about 20 (Guest Plan §6.4.2, proposed); the exact size can change
  without affecting the experience.
- The link domain is still open (Guest Plan §19.2); sharing uses the configurable domain from
  G0 and is fully testable on Staging. The redirect to the store for devices without the app is
  served from that domain, outside this repository, and must be agreed with the team.
- Western digits (123) stay in use until the numeral decision (Guest Plan §4.9) is made, as in
  G0.
- The last search is stored on the device as a non-sensitive preference and is not cleared at
  sign-out, since it holds no personal data.
- The final Figma for apartment details is not ready; G1 delivers the functional content in the
  proposed order (Guest Plan §6.5), and the final visual design is applied in G6 without
  changing behaviour.
