# Contract: App Routes, Resume Protocol, and Share Links (G1)

Extends [G0 app-routes](../specs/001-guest-app-foundation/contracts/app-routes.md). Guard order,
`from` validation, and the bottom navigation are unchanged.

Sources: Guest Plan §5.2–§5.3, spec FR-016, FR-025, FR-028–FR-031, research R9, R10, R13.

## Routes added or made real in G1

| Route | Screen | Needs account | Verified link | Placement |
|---|---|---|---|---|
| `/home` | Home (real) | no | — | Shell branch 1 |
| `/search` | Search form (real) | no | — | Shell branch 2 |
| `/search/results` | Results | no | **yes** (criteria in query) | Child of `/search` in branch 2 |
| `/property/:id` | Apartment details | no | **yes** | Top level, pushed over the shell |
| `/property/:id/gallery` | Full-screen gallery | no | — | Top level |
| `/property/:id/reviews` | All approved reviews | no | — | Top level |
| `/book/:propertyId/dates` | Booking entry (**placeholder until G2**) | **yes** | — | Top level |
| `/support/new` | New support case (**placeholder until G4**) | **yes** | — | Top level |

- `:id` and `:propertyId` must be UUID v4; anything else goes to `/not-available` (G0 rule).
- `/book/...` and `/support/new` are added to `AppRoutes.requiresAccount`.
- `/property/...` and `/search/results` stay open to visitors.

## Query parameters

### `/search/results` (and the shared search link)

Canonical, whitelisted keys only (see `SearchCriteria` in [data-model.md](../specs/002-guest-discovery/data-model.md)):

`loc` · `in` · `out` · `g` · `pmin` · `pmax` · `bed` · `bath` · `am` · `type` · `sort`

- Unknown keys are discarded.
- An invalid value drops only its own field.
- Past or inverted dates drop both dates, and the screen asks for new dates.
- `LinkParser` keeps these keys **only** for `/search/results`. For every other linkable path,
  all query parameters are still stripped (G0 behaviour).

Example: `/search/results?g=4&in=2026-11-20&loc=2b1c…&out=2026-11-23&sort=price_asc`

### `/property/:id`

| Key | Meaning | Rule |
|---|---|---|
| `checkIn`, `checkOut` | Dates carried from Search or the calendar | Both valid, or both ignored |
| `guests` | Guests carried from Search | 1–50 |
| `resume` | `book` \| `contact` (only set by the sign-in return) | Consumed once |
| `terms` | Terms version that was on screen when the visitor tapped | Opaque, ≤ 128 chars; required with `resume=book` |

These keys are internal. A shared property link carries **no** query parameters: `LinkParser`
strips them, so a link can never trigger `resume`.

### `/book/:propertyId/dates`

`checkIn`, `checkOut` (optional), `guests` (optional), `terms` (required).
- G1 placeholder: shows the apartment title and the carried values, says booking opens soon,
  and offers Back.
- G2 replaces it with the real date step, which sends `terms` to the server (AC-013).

### `/support/new`

`property=<uuid>` (optional). G1 placeholder; G4 opens a case linked to the apartment.

## Resume protocol (visitor taps "Book now" or "Contact OnAir")

```text
Visitor on /property/P?checkIn=A&checkOut=B&guests=G   (shown terms = T)
  │ tap "Book now"
  ▼
push /auth/login?from=/property/P?checkIn=A&checkOut=B&guests=G&resume=book&terms=T
  │ sign in or sign up succeeds         │ cancel
  ▼                                     ▼
redirect → from                         back to /property/P?checkIn=A&checkOut=B&guests=G
  ▼
/property/P?…&resume=book&terms=T
  1. load guest_get_property(P)
  2. replace location without resume/terms (Back never re-triggers)
  3. if loaded.terms_version == T → push /book/P/dates?checkIn=A&checkOut=B&guests=G&terms=T
     else → stay, show "الشروط اتحدّثت، راجعها قبل الحجز", user must tap again
  4. if NOT_FOUND → not-available screen
```

- **Signed-in guest:** "Book now" pushes `/book/P/dates?…&terms=<shown>` directly.
- **"Contact OnAir":** identical flow with `resume=contact`, ending at
  `/support/new?property=P`. No terms check.
- **Profile not complete after sign-up:** G0 sends the guest to `/auth/complete-profile`
  with the same `from`, so the protocol continues after that step.
- **Process death during sign-up:** the `from` location is part of the route, so the return
  survives.

## Share links

| What | URL |
|---|---|
| Apartment | `https://<LINK_DOMAIN>/property/<uuid>` |
| Search | `https://<LINK_DOMAIN>/search/results?<canonical SearchCriteria query>` |

- **Share text (localized):** the apartment title or «بحث على OnAir», then the URL. Search
  links never include the location label; it is re-resolved after opening.
- **Opening a link in the app:**
  - It follows G0 rules: format check, then fetch under RLS or RPC, then a neutral
    `/not-available` on `NOT_FOUND`.
  - Opening a link never changes any state.
- **Devices without the app:** handled by the link domain. See
  [verified-links.md](../specs/002-guest-discovery/contracts/verified-links.md).

## Back behaviour

| From | Back goes to |
|---|---|
| `/search/results` | `/search` with the same criteria (Search branch stack) |
| `/property/:id` opened from Home or Results | That tab, at the same scroll position |
| `/property/:id` opened from a link (cold) | `/home` |
| `/property/:id/gallery`, `/reviews` | `/property/:id` |
| `/book/...` placeholder | `/property/:id` |
