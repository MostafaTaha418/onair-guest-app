# Backend deltas A1–A7 — Auth providers, profile status, phone-verification RPCs

**For:** `onair-backend` (Supabase migrations + config). **Not implemented in this repository**
(AGENTS.md). Names follow `docs/OnAir Backend Master Plan.md`. Where this file differs, the
Backend Master Plan must be updated (D-002).

Error shape unchanged: `{ error: { code, message_key, request_id, details } }`. RPC errors are
raised as `P0001` with the code in `message` / `details` like the existing guest RPCs.

---

## A1 — Google and Apple providers (config, both environments)

- Enable the **Google** provider:
  - Client IDs = the Web client ID (audience). Add the Android and iOS client IDs to "Authorized
    Client IDs".
  - Enable **Skip nonce check** only if Staging shows iOS ID tokens carrying a nonce the app
    cannot read (research R1).
- Enable the **Apple** provider:
  - Client IDs = the iOS bundle IDs (`com.onair.guest`, `com.onair.guest.staging`);
  - Services ID / Team ID / Key ID / `.p8` for the secret.
  - The Apple client secret JWT **expires every 6 months**; add a calendar reminder.
- Local `supabase/config.toml` gets `[auth.external.google]` / `[auth.external.apple]` with
  `env(...)` placeholders. No secrets in Git.

## A2 — Identity linking and the unconfirmed-email collision

- Keep **automatic linking** on: a Google/Apple identity with an email that a **confirmed**
  account already uses joins that account (FR-039).
- If the existing user's email is **not** confirmed, the provider sign-in **takes over** the
  email. The unconfirmed email identity is removed and `encrypted_password` is cleared, so the
  old password stops working (FR-040, clarified 2026-11-13).
  - Supabase does this by default to prevent pre-account takeover. Add a pgTAP test that asserts
    it, plus a guard trigger if the hosted behaviour differs.

## A3 — `profiles.status = incomplete` and new-user handling

```sql
-- shape only; exact migration in onair-backend
alter table public.profiles
  alter column phone_e164 drop not null;
-- status gains 'incomplete' (existing: active, suspended, deleted)
alter table public.profiles
  add constraint profiles_phone_required_unless_incomplete
  check (status = 'incomplete' or phone_e164 is not null);
-- unique(phone_e164) where status <> 'deleted' stays as is (nulls do not collide)
```

- `private.handle_new_user` creates **every** new profile as `incomplete` with `phone_e164 =
  null`. This covers email signups (metadata now has `full_name`, `accepted_terms_version`,
  `locale` only) and Google/Apple signups (name from `raw_user_meta_data.full_name` / `name` when
  present; terms null).
- It no longer reads or validates `phone_e164` / `phone_has_whatsapp` / `whatsapp_e164`
  metadata. If they are sent by an old client, they are ignored.
- `private.handle_email_confirmed` stops filling `phone_verified_at`.
- **Legacy rows**: existing profiles keep `active` and their `phone_verified_at` (clarified). No
  data migration beyond the constraint.

## A4 — `common_get_my_context()` additions

The response gains:

```json
{
  "profile_status": "incomplete",
  "auth_providers": ["google"],
  "has_password": false,
  "email": "…", "email_verified": true,
  "full_name": null, "phone_e164": null, "phone_verified": false,
  "accepted_terms_version": null
}
```

`auth_providers` come from `auth.identities.provider`. `has_password` is
`encrypted_password is not null and encrypted_password <> ''`.

## A5 — `common_start_phone_verification` (new) + `common_verify_otp` (extended)

```text
common_start_phone_verification(
  p_phone text,                      -- E.164
  p_full_name text default null,     -- required if profile.full_name is null
  p_accepted_terms_version text default null,  -- required if profile.accepted_terms_version is null
  p_locale text default 'ar'
) returns jsonb  -- { challenge_id uuid }
```

Checks, in order:
1. The caller is signed in → else `UNAUTHENTICATED`.
2. `profiles.status = incomplete` → else `PROFILE_ALREADY_COMPLETE`.
3. Phone is Egyptian mobile → else `PHONE_COUNTRY_NOT_SUPPORTED`.
4. Phone is not on another non-deleted profile → else `PHONE_ALREADY_USED`.
5. Name 2–80 when required → else `VALIDATION_FAILED`.
6. Terms version equals `app_config` current when required → else `TERMS_CHANGED`.

Creates `private.otp_challenges(purpose='phone_verify', channel='whatsapp', recipient_user_id =
caller, payload = {phone_e164, full_name, accepted_terms_version, locale})`. Any previous open
`phone_verify` challenge of the caller is consumed (superseded). **Nothing is written to
`profiles`.** No code is generated here; sending is Node A8.

`common_verify_otp(p_challenge_id, p_code)` for `purpose = 'phone_verify'`, in one transaction:
1. Check the attempts, expiry and latest-code rule → `OTP_INVALID` / `OTP_EXPIRED` /
   `OTP_SUPERSEDED` / `OTP_ATTEMPTS_EXCEEDED` (5 attempts, `otp_max_attempts`).
2. Re-check that the phone is still unused → `PHONE_ALREADY_USED`, and nothing is written.
3. Update `profiles`: set `phone_e164`, `phone_verified_at = now()`, `phone_has_whatsapp = true`,
   `whatsapp_e164 = null`, `full_name` / `accepted_terms_version` / `accepted_terms_at` when they
   were in the payload, and `status = 'active'`.
4. Consume the challenge and reset the send-limit rows of the account, phone and device used
   (A8 `otp_send_limits.reset_on_success`).
5. Write `audit_log`.
6. Return the profile (same shape as A4).

## A6 — `common_request_phone_change` (changed)

```text
common_request_phone_change(p_new_phone text) returns jsonb  -- { challenge_id }
```

- The `p_has_whatsapp` / `p_whatsapp` parameters are removed. Keep a deprecated overload for one
  release if an old client could call it.
- Allowed only for `status = active`.
- The challenge is `purpose='phone_change'`, `channel='whatsapp'`, `payload = {phone_e164}`.
- `common_verify_otp` for `phone_change` applies the new phone like A5 step 3 (no name/terms),
  keeps the old phone until success, and emits `account.phone_changed`.

## A7 — `common_get_otp_status` (new), incomplete-account enforcement, cleanup

```text
common_get_otp_status(p_challenge_id uuid) returns jsonb
-- { delivery_status: 'pending'|'sent'|'delivered'|'read'|'failed',
--   failure_reason: 'not_on_whatsapp'|'other'|null,
--   expires_at, next_send_at, blocked_until, server_time }
```

Only the challenge's recipient may read it (`NOT_FOUND` otherwise).

**Incomplete enforcement** (FR-037):
- Every `guest_*` and `common_*` write RPC raises `PROFILE_INCOMPLETE` when the caller's profile
  is `incomplete`, except:
  - `common_start_phone_verification`;
  - `common_verify_otp`;
  - `common_get_otp_status`;
  - `common_get_my_context`;
  - `common_register_device` / `common_unregister_device`;
  - `common_request_account_deletion` / `common_confirm_account_deletion`.
- Implement it as `private.require_active_profile()` called at the top of each function.
- `favorites` insert/delete RLS adds `private.profile_is_active(auth.uid())`.
- The Worker rejects incomplete callers on every guest route except `/v1/otp/send` for a
  `phone_verify` challenge.
- `guest_quote_booking` and `guest_start_booking` keep `PHONE_NOT_VERIFIED` for a null or
  unverified phone. This is defence in depth for legacy rows.

**Cleanup**: a scheduled job deletes `auth.users` whose profile is `incomplete` and older than
`incomplete_account_retention_days` (default 7). It does **not** delete
`private.otp_send_limits` rows; those expire on their own (A8).

**Tests (pgTAP)**:
- the constraint;
- `handle_new_user` for email and social;
- start/verify happy path;
- each error;
- a phone that became used between start and verify;
- the incomplete-account rejection on a sample of write RPCs and favorites;
- legacy profiles untouched;
- the cleanup keeps the limits.
