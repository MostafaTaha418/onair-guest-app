# Contract: Supabase Backend — Identity, Profile, Config, Devices (Guest App)

**Audience**: backend implementer (`onair-backend`). **Status**: aligned with
[`docs/OnAir Backend Master Plan.md`](../docs/OnAir%20Backend%20Master%20Plan.md) (28 Oct 2026).
That plan is the single source of names. If this file disagrees with it, the plan wins.

**Sources**: Master Plan §2.3, §13.4, §16.1; Backend Master Plan B3–B6, §4.4, §5.1, §5.2,
§9.5–§9.6, §12.1, §17.

> **Changed on 28 Oct 2026 (replaces the G0 draft):**
> - **No SMS anywhere.** The phone provider and the Send SMS hook are removed. There is no phone
>   sign-in.
> - Sign-up and sign-in use **email + password** only.
> - Sign-up collects the name, an **Egyptian phone number**, "does this number have WhatsApp?"
>   and an optional separate WhatsApp number.
> - **One 6-digit code sent to the email confirms both the email and the phone.**
> - `complete_guest_profile` is removed. The profile is created at sign-up from the sign-up
>   metadata.
> - Push tokens are registered through RPC (`common_register_device`), not the Node
>   `/v1/devices` route.

## 1. Auth configuration

| Setting | Value | Why |
|---|---|---|
| Phone provider | **Off** | No SMS (B3) |
| Email provider | On, confirm email **on**, SMTP = Resend | B4 |
| Email OTP length | 6 | B5 |
| Email templates (confirm signup, reset password, change email) | Body shows `{{ .Token }}` only, **no** `{{ .ConfirmationURL }}` / links. The signup template says the code confirms the email **and the phone number** | B5 |
| Session inactivity timeout | **30 days** (needs the Pro plan) | Master Plan §16.1 |
| Refresh token rotation + reuse detection | On | |
| Password | min 8, letters + digits, leaked-password protection | |
| Anonymous sign-ins, social providers | **Off** | |
| Rate limits | On code send, verify, sign-in, recovery; 429 with `retry_after` where possible | |

## 2. Sign-up and confirmation flow

1. App calls:
   ```dart
   supabase.auth.signUp(
     email: email,
     password: password,
     data: {
       'full_name': name,
       'phone_e164': '+2010xxxxxxxx',
       'phone_has_whatsapp': true,          // the switch
       'whatsapp_e164': null,               // only when phone_has_whatsapp == false (optional)
       'accepted_terms_version': config.guestTermsVersion,
       'locale': 'ar',
     },
   );
   ```
2. Trigger `private.handle_new_user` (on `auth.users` insert) creates the `profiles` row. It
   **fails the sign-up** with:
   - `PHONE_COUNTRY_NOT_SUPPORTED`: `phone_e164` (or `whatsapp_e164`) does not match
     `^\+201[0125]\d{8}$`.
   - `PHONE_ALREADY_USED`: the phone belongs to another non-deleted profile.
   - `VALIDATION_FAILED`: missing or invalid name; `whatsapp_e164` sent while
     `phone_has_whatsapp = true`.
   - `TERMS_CHANGED`: `accepted_terms_version ≠ app_config.guest_terms_version`.
3. Supabase emails a **6-digit code** (Resend).
4. App calls `verifyOtp(type: OtpType.signup, email, token)`. Trigger
   `private.handle_email_confirmed` (on `auth.users.email_confirmed_at` change) sets
   `profiles.phone_verified_at = now()`.
5. **Recovery:** `resetPasswordForEmail` → `verifyOtp(type: OtpType.recovery)` →
   `updateUser(password)`. The message is the same whether the account exists or not.

The app maps trigger errors from the `AuthException` message (`<CODE>` text) with
`ErrorMapper`.

## 3. Tables the Guest App reads

### `profiles` (one table for every user type)

| Column | Type | App use |
|---|---|---|
| `id` | uuid PK = `auth.users.id` | |
| `full_name` | text | Display |
| `email` | text | Display (copy of `auth.users.email`) |
| `phone_e164` | text not null | Display |
| `phone_verified_at` | timestamptz, null | "Confirmed" badge; booking is blocked while null |
| `phone_has_whatsapp` | bool | Switch |
| `whatsapp_e164` | text, null | Optional WhatsApp number |
| `avatar_key` | text, null | |
| `locale` | `ar` \| `en` | Notification / email language |
| `accepted_terms_version`, `accepted_terms_at` | | |
| `status` | `active` \| `suspended` \| `deleted` | |
| `created_at`, `updated_at` | | |

RLS:
- `select`: `id = auth.uid()` only.
- No client `insert/update/delete`; writes only through the RPCs in §4.

### `app_config` (single row, `id = 1`)

| Column | Type |
|---|---|
| `min_build_guest_android`, `min_build_guest_ios` | int |
| `min_build_partner_android`, `min_build_partner_ios` | int (not used by this app) |
| `support_phone`, `support_whatsapp` | text (E.164) |
| `guest_terms_version` | text |
| `partner_terms_version` | text (not used by this app) |
| `terms_url`, `privacy_url` | text |

RLS: `select` for `anon` and `authenticated`; no client writes.

## 4. RPC (`common_*`)

| Function | Purpose | Errors |
|---|---|---|
| `common_get_my_context() returns jsonb` | Profile + `email_verified` + `phone_verified` + workspaces (empty for a guest) | `UNAUTHENTICATED` |
| `common_update_profile(p_full_name text, p_phone_has_whatsapp bool, p_whatsapp_e164 text, p_locale text, p_avatar_key text) returns profiles` | Edit everything except the main phone | `VALIDATION_FAILED`, `PHONE_COUNTRY_NOT_SUPPORTED` |
| `common_request_phone_change(p_new_phone text, p_has_whatsapp bool, p_whatsapp_e164 text) returns uuid` | Creates a `phone_change` challenge; returns `challenge_id`. The app then calls Node `POST /v1/otp/send` | `PHONE_COUNTRY_NOT_SUPPORTED`, `PHONE_ALREADY_USED`, `RATE_LIMITED` |
| `common_verify_otp(p_challenge_id uuid, p_code text) returns jsonb` | Verifies a challenge (`phone_change`, `account_deletion`) and applies it | `OTP_INVALID`, `OTP_EXPIRED`, `RATE_LIMITED` |
| `common_request_account_deletion() returns uuid` | `account_deletion` challenge | `ACCOUNT_HAS_ACTIVE_BOOKINGS` |
| `common_confirm_account_deletion(p_challenge_id uuid, p_code text)` | Anonymizes the profile, keeps financial records, signs out every session | `OTP_INVALID`, `OTP_EXPIRED` |
| `common_register_device(p_token text, p_app text, p_platform text, p_locale text)` | Upsert into `device_tokens`; this app always sends `p_app = 'guest'` | `VALIDATION_FAILED` |
| `common_unregister_device(p_token text)` | Called at sign-out; idempotent | — |
| `common_heartbeat(p_workspace_id uuid default null)` | Updates `profiles.last_seen_at` (at most once every few minutes) | — |
| `common_list_faq(p_audience text)` | `'guest'` | — |

Codes are delivered to the email by the Node route `POST /v1/otp/send`
([node-api.openapi.yaml](node-api.openapi.yaml)). The code itself is never stored in plain
text (`private.otp_challenges.code_hash`).

## 5. Errors

- Postgres functions: `raise exception '<CODE>' using errcode = 'P0001'`.
- Node: the unified `ErrorResponse` in [node-api.openapi.yaml](node-api.openapi.yaml).
- Codes and Arabic copy: [error-codes.md](error-codes.md).

## 6. Isolation (MUST, automated)

With two Staging test accounts A and B:
1. A signed in: `select * from profiles where id = <B.id>` returns **0 rows**.
2. A signed in: no `common_*` call can change B's row.
3. Anonymous: `select` on `profiles` returns 0 rows.
4. A cannot read B's `device_tokens` or `notifications`.

`integration_test/isolation_test.dart` runs these against Staging.

## 7. Staging test data

- Two test email accounts for isolation and recovery tests: one whose phone has WhatsApp, and
  one with a separate WhatsApp number.
- One account that is signed up but not confirmed (email and phone not confirmed).
- No SMS test numbers (removed).
- `app_config` row with `min_build_guest_* = 1`.

## 8. Changes the Guest App code needs (G0 rework)

| Area | Old (G0 code) | New |
|---|---|---|
| Sign-in | Phone tab + SMS code (`signInWithOtp(phone)`, `OtpType.sms`) | **Remove.** Email + password only |
| Sign-up | Email sign-up without a phone; phone sign-up | Email + password + `phone_e164` + `phone_has_whatsapp` + optional `whatsapp_e164` in `signUp(data:)` |
| Profile completion | `/auth/complete-profile` + `complete_guest_profile` RPC | **Remove.** Name and terms go with `signUp`; edits use `common_update_profile` |
| `app_config` columns | `min_supported_build_android`, `min_supported_build_ios`, `current_terms_version` | `min_build_guest_android`, `min_build_guest_ios`, `guest_terms_version` (+ `support_whatsapp`, `terms_url`, `privacy_url`) |
| `profiles` columns | `id, full_name, accepted_terms_*` | + `email`, `phone_e164`, `phone_verified_at`, `phone_has_whatsapp`, `whatsapp_e164`, `locale`, `status` |
| Push tokens | Node `POST /v1/devices`, `DELETE /v1/devices/{token}` | RPC `common_register_device` / `common_unregister_device` |
| Error codes | — | Add `PHONE_ALREADY_USED`, `NOT_FOUND`, `PERMISSION_DENIED`, `ACCOUNT_SUSPENDED`, `ACCOUNT_HAS_ACTIVE_BOOKINGS`. `PROFILE_INCOMPLETE` stays mapped but is no longer expected in the normal flow |
