# Contract: Supabase Backend Requirements for G0 (DRAFT)

**Audience**: backend owner (Guest Plan §2.3). **Status**: draft for review.
**Sources**: Master Plan §2.3, §13.4, §16.1; spec FR-022–FR-038, FR-041.

The Guest App relies on everything below. Items marked **MUST** are needed for the G0 exit
criterion on Staging.

## 1. Auth configuration

| Setting | Value | Why |
|---|---|---|
| Phone provider | Enabled, via **Send SMS hook** → Node service | Provider choice stays with backend; hook enforces Egypt-only |
| Egypt-only | Hook **MUST** reject any phone not matching `^\+201[0125]\d{8}$` with an error the app maps to `PHONE_COUNTRY_NOT_SUPPORTED` | Clarification Q4 |
| SMS OTP | 6 digits; expiry and resend interval set by backend | FR-022/023 |
| Email provider | Enabled, confirm email **on**; SMTP = Resend | FR-024/027 |
| Email OTP length | 6 | Clarification Q1 |
| Email templates (confirm signup, reset password) | Body shows `{{ .Token }}` only; **no** `{{ .ConfirmationURL }}` / links | Clarification Q1 |
| Session inactivity timeout | **30 days** | Clarification Q3 (needs a Supabase plan that supports it — confirm) |
| Refresh token rotation + reuse detection | On | Constitution IV |
| Rate limits | Per number / email / IP on OTP send, verify, sign-in, recovery; 429 with `retry_after` where possible | FR-029 |
| Leaked-password protection / minimum length | Min 8, letters + digits | FR-025 (server is final judge) |
| Anonymous sign-ins, social providers | **Off** | FR-031 |

## 2. Tables (app-facing columns)

### `profiles`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK, FK → `auth.users.id` | |
| `full_name` | text, null until completed | 2–80 chars |
| `accepted_terms_version` | text, null | |
| `accepted_terms_at` | timestamptz, null | Server `now()` |
| `created_at` / `updated_at` | timestamptz | |

RLS:
- `select`: `id = auth.uid()` only.
- `insert` / `update` / `delete` from clients: **denied**; writes only via the RPC below.

### `app_config` (single row)

| Column | Type |
|---|---|
| `min_supported_build_android` | int |
| `min_supported_build_ios` | int |
| `support_phone` | text (E.164) |
| `current_terms_version` | text |

RLS: `select` for `anon` and `authenticated`; no client writes.

## 3. RPC

### `complete_guest_profile(full_name text, terms_version text) returns profiles`

- `security definer`, acts only on `auth.uid()`; rejects if not signed in (`UNAUTHENTICATED`).
- Validates `full_name` (trim, 2–80 chars) → `VALIDATION_FAILED`.
- Requires `terms_version = app_config.current_terms_version` → else `TERMS_CHANGED`.
- Upserts the caller's row, sets `accepted_terms_at = now()`.

## 4. Errors

Auth errors surface as Supabase `AuthException`s; the app maps them by status + error code to the
codes in [error-codes.md](error-codes.md). The Node service (SMS hook, devices) uses the unified
`ErrorResponse` in [node-api.openapi.yaml](node-api.openapi.yaml).

## 5. Isolation (MUST, automated)

With two Staging test accounts A and B:
1. A signed in: `select * from profiles where id = <B.id>` returns **0 rows**.
2. A signed in: calling `complete_guest_profile` cannot change B's row.
3. Anonymous: `select` on `profiles` returns 0 rows.

The Guest App's `integration_test/isolation_test.dart` runs these against Staging (SC-006).

## 6. Staging test data

- Test phone numbers with fixed OTPs (Supabase test-OTP feature) for E2E — **never** in
  Production.
- Two test email accounts for isolation and recovery tests.
- `app_config` row with `min_supported_build_*` = 1.
