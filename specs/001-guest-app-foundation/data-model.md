# Data Model: Guest App Foundation (G0)

**Feature**: [spec.md](spec.md) | **Contracts**: [contracts/](contracts/)

Server-owned records are described as the app sees them; the backend repository owns the actual
schema. Client-only types live in `lib/core` or `features/*/domain`.

---

## Server-owned (read under RLS / via auth)

### GuestAccount (Supabase auth user + profile)

| Field | Source | Type | Rules |
|---|---|---|---|
| `id` | auth user | UUID | Primary identity; equals `profiles.id` |
| `phone` | auth user | E.164 string, nullable | Egyptian only: `^\+201[0125]\d{8}$` (server-enforced) |
| `phoneVerified` | auth user `phone_confirmed_at != null` | bool | Set by the server after a correct SMS code |
| `email` | auth user | string, nullable | Lower-cased; unique across accounts |
| `emailVerified` | auth user `email_confirmed_at != null` | bool | Set after a correct emailed code |
| `fullName` | `profiles.full_name` | string | 2–80 chars after trim; required for a complete account |
| `acceptedTermsVersion` | `profiles.accepted_terms_version` | string, nullable | Must equal the current terms version for a complete account |
| `acceptedTermsAt` | `profiles.accepted_terms_at` | UTC timestamp, nullable | Server time |

- **Invariants**: at least one of `phone` / `email` is present. A phone or email belongs to at
  most one account. Email sign-up never stores a phone; phone sign-up never stores an email or
  password (Clarification Q2).
- **Completeness**: `isComplete = fullName != null && acceptedTermsVersion == currentTermsVersion`.
  Incomplete accounts are routed to `/auth/complete-profile`.
- **Access**: a signed-in user can select and update only their own `profiles` row (RLS);
  writes go through `complete_guest_profile` (see [supabase-backend.md](contracts/supabase-backend.md)).

### AppConfig (public)

| Field | Type | Rules |
|---|---|---|
| `minSupportedBuildAndroid` | int | Installed build below this → update gate |
| `minSupportedBuildIos` | int | Same for iOS |
| `supportPhone` | E.164 string | Shown on update/error screens when useful |
| `currentTermsVersion` | string | Used for completeness and the sign-up checkbox |

Readable by anonymous users. Cached in memory for the app session; refetched on resume.

### DeviceRegistration (Node command)

| Field | Type | Rules |
|---|---|---|
| `token` | string | FCM token; registered when available after sign-in, refreshed on token change |
| `platform` | `android` \| `ios` | — |
| `locale` | `ar` \| `en` | Current app locale |

Registered with `registerDeviceToken`; removed with `unregisterDeviceToken` **before** the local
session is cleared at sign-out (needs the bearer token). Failure to unregister does not block
sign-out; the server also drops tokens of ended sessions.

---

## Client-side

### EnvConfig

| Field | Type | Notes |
|---|---|---|
| `flavor` | `staging` \| `production` | From entry point |
| `supabaseUrl` | URL | Public |
| `supabaseAnonKey` | string | Public anon key only; startup asserts it is not a `service_role` JWT |
| `nodeApiBaseUrl` | HTTPS URL | Startup rejects non-HTTPS |
| `linkDomain` | host | For verified-link parsing |
| `backendMode` | `remote` \| `mock` | Optional `BACKEND_MODE`, default `remote`; `mock` uses in-memory repositories (Guest Plan §2.6) and is rejected for `production` |

### Session (secure storage)

Persisted only through `SecureSessionStorage`. Fields are Supabase's session JSON (access token,
refresh token, expiry). Never logged.

### AuthState (state machine, `features/auth/domain`)

```text
unknown ──(storage read)──► signedOut
unknown ──(valid session)──► signedIn(incomplete | complete)

signedOut ──requestCode──► codeSent(channel, target, resendAt) ──verify ok──► signedIn(...)
codeSent ──verify fail──► codeSent(+error) ──limit──► rateLimited(until) ──timer──► codeSent
signedOut ──email sign-in ok──► signedIn(...)
signedIn(incomplete) ──completeProfile ok──► signedIn(complete)
signedIn ──refresh fails / server ends session──► sessionEnded(returnTo) ──ack──► signedOut
signedIn ──signOut──► signingOut ──cleanup done──► signedOut
```

- `channel`: `sms` | `emailSignup` | `emailRecovery`.
- `resendAt` and `until` come from server responses (countdown, `retry_after`), never from a
  client constant.
- Recovery adds `recoveryVerified → setNewPassword → signedIn(...)`.

### VerificationChallenge (UI model for the code screen)

| Field | Type | Rules |
|---|---|---|
| `channel` | see above | Drives copy ("change number" vs "change email") |
| `target` | masked phone/email | Display only, e.g. `+20 10•• ••• 345` |
| `code` | 6 digits | Submit enabled only at 6 digits; never copied to clipboard |
| `resendAvailableAt` | UTC timestamp | From server |
| `attemptsLocked` | bool | From server error |

### ApiError / AppFailure

| Field | Type | Notes |
|---|---|---|
| `code` | enum (see [error-codes.md](contracts/error-codes.md)) | Unknown → `INTERNAL` |
| `messageKey` | string | `.arb` key; raw server text never shown |
| `requestId` | string | Shown as "رقم المرجع" for unexpected errors |
| `retryAfter` | Duration, nullable | For `RATE_LIMITED` |

`AppFailure` adds `network` (no response) and `cancelled` (screen disposed; never shown).

### Money (value object, `lib/core/money`)

| Field | Type | Rules |
|---|---|---|
| `amountMinor` | int | Piasters; may be negative only for adjustments; no `double` anywhere |
| `currency` | `EGP` | Only supported currency |

Formatting through one formatter (Western digits until the numerals decision). Equality by
value. Arithmetic only with the same currency.

### DateOnly / Cairo time (`lib/core/time`)

- `DateOnly(year, month, day)` for stay dates: no time zone, no time.
- Timestamps arrive as UTC ISO-8601 and are displayed in `Africa/Cairo` regardless of the device
  zone.

### Preferences (`shared_preferences`)

Only: `themeMode` (unused in G0, reserved for G4), `localeCode`, `lastSearch` (G1). Cleared
selectively at sign-out except appearance/locale.
