# Contract: App Routes, Guards, and Verified Links (G0)

Source: Guest Plan §5.1–§5.3, spec FR-016–FR-021, FR-033, FR-041.

> **Changed on 28 Oct 2026 (Backend Master Plan B3–B5):** no SMS and no phone sign-in. Sign-in
> is email + password only. Sign-up collects the phone, the WhatsApp choice, and the name and
> terms. One code on the email confirms the email and the phone. `/auth/complete-profile` is
> removed. A new route lets the user confirm a pending phone before booking.

## Routes in G0

| Route | Screen | Needs account | Verified link | G0 content |
|---|---|---|---|---|
| `/splash` | Splash | no | — | Real |
| `/update-required` | Update required (blocking) | no | — | Real |
| `/not-available` | Neutral "not available" | no | — | Real |
| `/auth/login` | Sign in (email + password only) | — | — | Real |
| `/auth/register` | Create account: name, email, password, Egyptian phone, "has WhatsApp?", optional WhatsApp number, terms | — | — | Real |
| `/auth/otp` | Email code entry (signup = email + phone, recovery, phone change, account deletion) | — | — | Real |
| `/auth/forgot-password` | Request recovery code | — | — | Real |
| `/auth/new-password` | Set new password after recovery code | recovery session | — | Real |
| `/home` | Home tab | no | — | Placeholder + bell |
| `/search` | Search tab | no | — | Placeholder |
| `/bookings` | My Bookings tab | **yes** | — | Placeholder |
| `/favorites` | Favorites tab | **yes** | — | Placeholder |
| `/account` | My Account tab | **yes** | — | Placeholder + sign-out |

Routes from later phases (e.g. `/property/:id`, `/bookings/:id`) are registered as link
patterns in G0 so guards and validation are tested, but they resolve to `/not-available` until
their feature ships.

## Guard order (single `redirect`)

1. `AppConfig` says build is unsupported → `/update-required` (nothing else reachable).
2. Route needs an account and there is no session → `/auth/login?from=<location>`.
3. Signed in and on an `/auth/*` route (other than new-password) → `from` or `/home`.

The booking flow (G2) adds a check on `/book/:propertyId/*`: if `common_get_my_context()`
reports the email or the phone as not confirmed, go to `/book/:propertyId/verify-phone`. That
screen sends a code to the email and returns to the booking. The server still rejects the
payment with `EMAIL_NOT_VERIFIED` / `PHONE_NOT_VERIFIED`.

`from` is accepted only if it is a relative internal path that matches a registered route;
anything else is dropped (no open redirect).

## Verified links

- Host: `EnvConfig.linkDomain` (domain still open — Guest Plan §19.2).
- Paths accepted: the routes marked as linkable in Guest Plan §5.3 (G0 registers the patterns).
- Path IDs must match UUID v4; otherwise → `/not-available`.
- Query parameters never change state; they are navigation hints only.
- A link opened while signed out to a members-only route → sign-in first, then the link.

## Bottom navigation

Order (RTL, first on the right): Home, Search, My Bookings, Favorites, My Account.
`StatefulShellRoute.indexedStack`; each branch keeps its stack and scroll position. Active item
uses Badge/Nav Active background; labels 10/700 active, 10/500 inactive.
