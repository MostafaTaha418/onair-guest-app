# Backend deltas U1, U3–U7, U9–U10 — Supabase (support, account, config)

These are drafts for `D:\flutter\onair-backend`. **No SQL or migration is written in this repository**
(AGENTS.md). The Node deltas U2 and U8 are in [node-account.md](node-account.md).

As-built baseline (2026-11-16, `onair-backend` @ `47c5447`):
- tables `support_cases`, `case_messages`, `attachments`, `faq_items`, `notification_preferences`;
- `case_messages` is in `supabase_realtime`;
- functions `common_list_faq`, `common_get/set_notification_preferences`, `common_update_profile`,
  `common_heartbeat`, `common_authorize_upload/download`, `common_verify_otp`.

Every function below is `security definer`, `search_path = public, private, pg_temp`, and granted to
`authenticated` only. It rejects `suspended`/`deleted` profiles with `ACCOUNT_SUSPENDED`, and
`incomplete` profiles with `PROFILE_INCOMPLETE`, except where noted (Constitution II). Errors use
the unified shape `{code, message_key, request_id, details}` (`contracts/error-codes.md`).

## U1 — Guest support RPCs (new)

### `common_list_my_support_cases(p_cursor text default null, p_limit int default 20) → jsonb`

```json
{ "items": [ { "id": "uuid", "code": "SC-1042", "type": "booking", "status": "waiting_user",
              "booking_id": "uuid|null", "booking_code": "OA-…|null",
              "property_id": "uuid|null", "property_title": "…|null",
              "created_at": "…Z", "last_activity_at": "…Z", "has_unread_staff_reply": true } ],
  "next_cursor": "opaque|null" }
```

- Rows: `opened_by_user_id = auth.uid()` and `opener_scope = 'guest'`.
- Order: open statuses (`open`, `in_progress`, `waiting_user`) first, then `last_activity_at desc`,
  `id`.
- `last_activity_at` = latest participants-visible message or status change.
- `has_unread_staff_reply` = a platform message newer than the guest's last read. The read marker is
  updated by `common_get_support_case`.

### `common_get_support_case(p_case_id uuid, p_before_cursor text default null) → jsonb`

```json
{ "case": { …same fields as a list item… },
  "messages": [ { "id": "uuid", "author": "guest|onair", "body": "…", "created_at": "…Z",
                  "attachments": [ { "id": "uuid", "kind": "image|pdf", "size_bytes": 123,
                                     "width": 1024, "height": 768 } ] } ],
  "next_older_cursor": "opaque|null" }
```

- The case must belong to the caller. Anything else, including a non-existent id, returns
  `NOT_FOUND`, the same as for a foreign case (Constitution II; spec US1-7).
- Only `visibility = 'participants'` messages from the guest or `author_scope = 'platform'`. Never
  `internal`, never `partner`.
- `author` is mapped server-side. Staff names are not exposed (shown as «OnAir»).
- Messages come newest page first, at most 50 per page, and the app sorts ascending.
- It also marks staff replies as read.

### `common_create_support_case(p_type text, p_body text, p_draft_id uuid, p_booking_id uuid default null, p_property_id uuid default null, p_attachment_ids uuid[] default '{}') → jsonb`

Returns `{ "case_id": "uuid", "code": "SC-…" }`.

- `p_type ∈ {booking, payment, refund, property_issue, other}`; anything else → `VALIDATION_FAILED`.
- `p_body`: trimmed, 10–4000 characters.
- `p_booking_id` must be the caller's booking; `p_property_id` must be published or tied to the
  caller's booking. Otherwise → `NOT_FOUND`.
- **Idempotent on `p_draft_id`**: a repeated call by the same user with the same draft returns the
  first result and creates nothing (FR-009).
- The first message is created from `p_body`. `p_attachment_ids` must all be `support_draft`
  attachments of this draft uploaded by the caller (U2); they are re-parented to that message in the
  same transaction. Count ≤ `upload_limits.max_files`, else `ATTACHMENT_REJECTED`
  (`details.reason = too_many`).
- Emits `support.case_created` (existing matrix) and sets `sla_due_at`.

### `common_reply_support_case(p_case_id uuid, p_body text, p_draft_id uuid, p_attachment_ids uuid[] default '{}') → jsonb`

Returns `{ "message_id": "uuid", "case_status": "open|…" }`.

- Ownership as in `common_get_support_case`.
- `status = 'closed'` → `CASE_CLOSED`.
- **`status = 'resolved'` → the reply is added and the status becomes `open`** (clarified 2026-11-16).
  `resolved_at` is kept for history, and `support.user_replied` goes to the assignee or the support
  pool.
- `waiting_user` → `in_progress` if assigned, else `open`.
- Body 1–4000 characters. Idempotent on `p_draft_id`. Attachments are handled as in create.

## U3 — Realtime and RLS for live case updates

- Add `public.support_cases` to the `supabase_realtime` publication, with `UPDATE` events only.
- RLS `select` on `case_messages` for guests must be exactly: own case
  (`opened_by_user_id = auth.uid()`), `visibility = 'participants'`, and `author_scope in ('guest',
  'platform')`. Postgres Changes respect RLS, so internal notes never reach the channel.
- RLS `select` on `support_cases` for guests: own cases. The app uses events only as a "re-read"
  signal (research R5).

## U4 — Support notifications payload

`support.staff_replied` and `support.case_resolved` (in-app + push) must carry
`entity_type = 'support_case'` and `target_id = <case id>`. The app routes them to
`/support/:caseId` (contracts/app-routes.md). Push text carries no message body (Constitution IV).

## U5 — Account deletion (new pair)

### `common_request_account_deletion() → jsonb`

Allowed for `active` and `incomplete` profiles.

**Blockers** — any of these raise `ACCOUNT_HAS_ACTIVE_BOOKINGS` with
`details.blockers = [{ "kind": "booking|refund|damage_claim", "id": "uuid", "code": "OA-…" }]`:
- a booking in `payment_pending`, `payment_verifying`, `awaiting_owner`, `confirmed` or `checked_in`;
- a refund not in a final state;
- a damage claim not `resolved`/`withdrawn`;
- a cash confirmation pending.

**Otherwise** it creates `private.otp_challenges` with `purpose = 'account_deletion'`, channel
`email`, and returns `{ "challenge_id": "uuid", "masked_email": "a***@g***.com" }`. The app then calls
Node `POST /v1/otp/send` with `{challenge_id}`, which follows the existing email ladder and returns
`next_send_at`.

### `common_confirm_account_deletion(p_challenge_id uuid, p_code text) → jsonb`

1. Verify the code through `private.verify_challenge(…, 'account_deletion')`. It returns the usual
   OTP errors.
2. Re-check the blockers (race, spec Edge Cases). If any → `ACCOUNT_HAS_ACTIVE_BOOKINGS`.
3. Anonymize, all in one transaction:
   - `profiles`: `full_name = 'Deleted user'`, `email = null`, `phone_e164 = null`,
     `status = 'deleted'`, `anonymized_at = now()`;
   - delete `favorites`, `notification_preferences` and `device_tokens`;
   - `auth.users`: scramble the email to `deleted+<uuid>@invalid`, remove the identities (Google /
     Apple), and remove the password;
   - delete every `auth.sessions` row of the user.
4. Keep bookings, payments, refunds and journal rows. They reference the anonymized profile id, with
   no personal data (Master Plan 14.6).
5. Support case texts are kept for audit. Attachments follow the legal retention policy (§19 item 7,
   server-owned).
6. `audit_log`: `account.deleted`.

Returns `{ "deleted": true }`.

**Effect:** the same email or phone can register again as a new, unrelated account. The phone and
device anti-spam keys (S005) are **not** deleted.

## U6 — Sessions (new) + revoked-session detection

### `common_list_my_sessions() → jsonb`

```json
[ { "id": "uuid", "device_label": "Samsung SM-A546 · Android 14", "platform": "android|ios|web|unknown",
    "created_at": "…Z", "last_active_at": "…Z", "is_current": true } ]
```

- Source: `auth.sessions` where `user_id = auth.uid()` and `not_after` is null or in the future.
- `last_active_at` = `coalesce(refreshed_at, updated_at, created_at)`.
- `device_label` and `platform` are parsed from `user_agent`. The app sends
  `OnAirGuest/<ver> (<os> <ver>; <model>)` (research R7). Unparsable → `unknown`, and the label is a
  generic «جهاز».
- `is_current` = `id = (auth.jwt()->>'session_id')::uuid`.
- Order: current first, then `last_active_at desc`.

### `common_end_session(p_session_id uuid) → void`

Deletes the caller's session row, which cascades the refresh tokens.
- Current session → `SESSION_IS_CURRENT`.
- Not the caller's session → `NOT_FOUND`.

### `common_end_other_sessions() → int`

Deletes all of the caller's sessions except the current one and returns the count.

### `common_heartbeat` (changed)

If `auth.jwt()->>'session_id'` has no row in `auth.sessions`, raise `SESSION_REVOKED` before the
existing checks. The app calls it on resume and every 60 s while in the foreground.

## U7 — Profile update (changed)

`common_update_profile(p_full_name text default null, p_locale text default null) → jsonb`
(new signature; the old `p_phone_has_whatsapp` / `p_whatsapp_e164` / `p_avatar_key` parameters are
obsolete since S005 and the photo deferral):
- Partial update: a null parameter leaves the field unchanged.
- Name: trimmed, 2–80 characters, not only whitespace or symbols → otherwise `VALIDATION_FAILED`.
- `p_locale ∈ {ar, en}`.

Returns the updated profile fields used by `common_get_my_context`.

## U9 — Notification preference catalog (changed)

`common_get_notification_preferences() → jsonb` returns the guest catalog, not the raw rows:

```json
[ { "category": "support", "is_mandatory": false,
    "channels": [ { "channel": "push", "enabled": true }, { "channel": "email", "enabled": true } ] },
  { "category": "booking", "is_mandatory": true,
    "channels": [ { "channel": "push", "enabled": true }, { "channel": "email", "enabled": true } ] } ]
```

- Categories are those of `notification_types` whose guest audience has push or email channels.
- `is_mandatory` = any guest type in the category is mandatory.
- `enabled` defaults to `true` when there is no row.
- `in_app` is never listed.
- `common_set_notification_preferences(p_items)` **must refuse** (`VALIDATION_FAILED`) any item for a
  mandatory category, instead of silently storing it.

## U10 — Public app config fields

Added to the anon-readable `app_config` (or a public view over `platform_settings`):

| Key | Type | Notes |
|---|---|---|
| `support_phone` | text E.164 | exists; empty → call button hidden |
| `support_hours_ar`, `support_hours_en` | text, null | free text shown under the call button |
| `guest_terms_url_ar/_en`, `privacy_url_ar/_en` | text URL | legal pages |
| `upload_limits` | jsonb | `{image_mb: 10, pdf_mb: 15, max_files: 5}`; add `max_files` |
| `english_enabled` | bool | default `true`; hides the English choice when false (§19 item 6) |

## Acceptance checks for the backend owner (Staging)

1. A guest can't read another guest's case, nor any `internal` message, through the RPCs, the REST
   tables or Realtime.
2. Calling create/reply twice with the same `draft_id` creates one case/message, and binds
   attachments once.
3. A reply on `resolved` sets `open`; a reply on `closed` → `CASE_CLOSED`.
4. Deletion is refused with blockers for each blocker kind, and succeeds otherwise. After success,
   login with the old password, Google or Apple creates no access to the old data, and every
   session's heartbeat → `SESSION_REVOKED`.
5. Ending a session makes that device's next heartbeat return `SESSION_REVOKED`. Ending the current
   session is refused.
6. Mandatory categories can't be switched off through `common_set_notification_preferences`.
