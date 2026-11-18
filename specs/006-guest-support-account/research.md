# Research: Guest Support & Account (G4)

Phase 0 decisions for [plan.md](plan.md). Each entry: Decision / Rationale / Alternatives.

## R1 — Picking photos and PDFs

**Decision**:
- `image_picker` for camera and gallery photos. It uses the Android system photo picker, so no
  storage permission is needed, and PHPicker on iOS.
- `file_picker` restricted to `pdf` for documents.
- Both sit behind one `AttachmentPicker` interface in `lib/core/files/`, and the mock replaces it in
  tests.

**Rationale**:
- Both are Flutter-team or widely maintained and already common in Flutter apps.
- Neither needs a background service.
- `image_picker` is first-party.
- Limiting `file_picker` to PDF keeps the attack surface and the UI small.

**Alternatives**:
- `file_selector`: no camera, and the PDF filter is weaker on Android.
- `wechat_assets_picker`: a heavy custom UI that does not follow `DESIGN.md`.
- A camera-only flow: the guest usually already has the photos.

## R2 — Photo compression and EXIF removal

**Decision**: `flutter_image_compress` re-encodes every picked photo to JPEG:
- quality 80;
- longest side ≤ 2048 px;
- `keepExif: false`, which drops all metadata including GPS;
- HEIC/HEIF and PNG input also become JPEG.

The output is a temp file in the app cache dir, deleted after the upload or when the draft is
discarded. PDFs are sent unchanged, only size- and type-checked.

**Rationale**:
- Constitution IV requires EXIF/GPS removal before upload.
- Re-encoding guarantees it, where tag-stripping does not.
- It also brings typical phone photos (3–8 MB) under 1 MB, which matters on mobile networks.
- The work runs natively, off the UI thread.

**Alternatives**:
- The pure-Dart `image` package: 5–10× slower on the UI isolate, and needs an isolate.
- Uploading originals and stripping on the server: the GPS would leave the device.
- WebP output: the server allows it, but JPEG is safer for staff viewing tools.

## R3 — Upload before the case exists (draft binding)

**Decision**:
- When the new-case form or a reply composer opens, the app creates a `draft_id` (UUID v4).
- Each attachment is signed with `entity_type: support_draft`, `entity_id: draft_id` (delta U2).
- `common_create_support_case` / `common_reply_support_case` receive `p_draft_id` and
  `p_attachment_ids`. They are idempotent on `draft_id`: a retry returns the same case or message.
  They re-parent the attachments to the new message in the same transaction.
- Unbound draft attachments are purged by the backend after 24 h.

**Rationale**:
- The as-built `common_authorize_upload` needs an existing entity (`support_case` or
  `case_message`).
- Creating the case first and uploading after would leave half-created cases when an upload fails,
  and would break "send waits until every file is uploaded" (FR-012).
- One id doing both jobs (idempotency + upload grouping) satisfies FR-009 with no extra state.

**Alternatives**:
- Create the case first, then upload against it, then "finalize": three calls and a visible partial
  state.
- Base64 attachments inside the RPC: blows the request size and bypasses the private R2 store.

## R4 — Viewing private attachments

**Decision**:
- Thumbnails and the full viewer fetch a URL from `GET /v1/files/{id}/url` on demand.
- The URL is kept in an in-memory map keyed by attachment id, with its `expires_at`.
- It is re-fetched when within 30 s of expiry or after a 403/expired error.
- Images load through `Image.network` with an in-memory cache only, never `cached_network_image`'s
  disk cache.
- PDFs open in the in-app browser (Custom Tabs / SFSafariViewController) from the signed URL.
- This reuses the G3 `EvidenceUrlCache` approach, moved to `core/files`.

**Rationale**: Constitution IV forbids persisting private attachments and their links. G3 already
proved the pattern for damage evidence.

**Alternatives**:
- Downloading PDFs to show them in-app: writes a private file to disk.
- Long-lived URLs: they would leak if shared.

## R5 — Live case updates

**Decision**:
- One Supabase Realtime channel per open case screen, `postgres_changes` on `case_messages` filtered
  by `case_id=eq.<id>`, plus `support_cases` `UPDATE` filtered by `id=eq.<id>` for status.
- The event only signals: the cubit re-reads the case through `common_get_support_case`. RLS still
  hides internal notes, and the payload is never trusted for content.
- The channel closes on dispose.
- While the channel is not `subscribed`, a 10 s poll runs instead.
- The case list refreshes on return and on the `support.staff_replied` in-app notification signal.

**Rationale**:
- SC-003 (≤ 5 s) with minimal traffic.
- Re-reading through the RPC keeps one code path for what the guest may see.
- This mirrors the booking-details pattern. It is recorded as a constitution deviation in plan.md
  Complexity Tracking.

**Alternatives**:
- Polling only: see Complexity Tracking.
- Realtime on the list screen: more channels for little value; the notification signal covers it.

## R6 — Account deletion flow

**Decision**: «حذف الحساب» works in three steps:
1. **Explanation screen.** On «احذف حسابي» the app calls `common_request_account_deletion()`. The
   server either returns `challenge_id` or raises `ACCOUNT_HAS_ACTIVE_BOOKINGS` with
   `details: {blockers: [{kind: booking|refund|damage_claim, id, code}]}`.
2. **Send the code.** The app calls Node `POST /v1/otp/send` (`channel: email`), which shows the
   existing email-code step (`OnAirOtpField` + `CountdownText`, the server's `next_send_at`).
3. **Confirm.** `common_confirm_account_deletion(challenge_id, code)`, then `SignOutService.signOut()`
   with the server sign-out tolerated to fail (sessions are already gone), then the visitor home with
   a one-time snackbar.

The server anonymizes the profile, ends all sessions, deletes device tokens and frees the email and
phone (delta U5).

**Rationale**:
- This matches Backend Master Plan §5.1 / §11 (`common_request_account_deletion` →
  `common_confirm_account_deletion`).
- It reuses the email OTP infrastructure from cash confirmation.
- Immediate deletion was clarified on 2026-11-16.
- Checking blockers at request time (and again at confirm) gives the reason before a code is sent
  (FR-019) and handles the race in the spec's edge cases.

**Alternatives**:
- `supabase.auth.admin.deleteUser` from Node: hard-deletes the user, which breaks the "keep financial
  records" rule.
- Deleting with the password instead of a code: Google/Apple accounts have no password.

## R7 — Sessions list and revocation detection

**Decision**:
- `common_list_my_sessions()` reads `auth.sessions` for `auth.uid()` (security definer). It returns
  id, created_at, last refresh as `last_active_at`, a coarse `platform`/`device_label` parsed from
  `user_agent` on the server, and `is_current` from `auth.jwt()->>'session_id'`.
- `common_end_session(id)` and `common_end_other_sessions()` delete the rows. Refresh tokens cascade.
  Ending the current session is refused with `SESSION_IS_CURRENT`; sign-out is used instead.
- **Detection on the ended device:** an access token stays valid until it expires, so the app calls
  `common_heartbeat()` on app resume and every 60 s in the foreground (`SessionHeartbeat`). The
  heartbeat raises `SESSION_REVOKED` when the JWT's session row is gone (delta U6). The app maps it,
  and any refresh failure, to the existing "session expired" safe sign-out.

  This turns SC-010's "next action" into "next app open, or ≤ 60 s while open". The spec is updated
  to match.
- **Device labels**: no new header or column. Supabase Auth already records `user_agent`, so the app
  sets a descriptive `User-Agent` on its Supabase and Dio clients (`OnAirGuest/<version>
  (<android|ios> <os version>; <model>)`), and the server parses it into a label.

**Rationale**:
- Supabase Auth has no client API to list sessions.
- `auth.sessions` is the source of truth, and `signOut(scope: others)` exists, but not for one chosen
  session.
- The heartbeat already exists server-side (`common_heartbeat`) and updates `last_seen_at`.

**Alternatives**:
- A custom `app_sessions` table maintained by the app: duplicates Auth state and can drift.
- Shortening the JWT expiry to 5 min: more refresh traffic for every user, all the time.

## R8 — Password change with the current password

**Decision**: Node `POST /v1/account/password {current_password, new_password}` (delta U8). It:
1. rejects accounts without a password (`ACTION_NOT_ALLOWED`);
2. verifies the current password with the GoTrue password grant for the caller's email
   (rate-limited, `PASSWORD_INCORRECT`);
3. validates the new password with the registration rule (`PASSWORD_WEAK`);
4. updates it with the admin API;
5. deletes every other `auth.sessions` row for the user;
6. emits `account.password_changed`.

The current device keeps its session.

**Rationale**:
- `supabase.auth.updateUser(password)` does not check the current password unless the project
  enforces reauthentication (an email nonce), which would add a second code flow.
- One server call keeps "end other sessions" atomic with the change (clarified 2026-11-16).

**Alternatives**:
- Client-side `signInWithPassword` to check, then `updateUser`, then `signOut(scope: others)`: three
  calls; the check can be skipped by a modified client; non-atomic.
- Reauthenticate nonce by email: more friction for a routine action.

## R9 — Language and appearance

**Decision**:
- `AppSettingsCubit` (app-level, above the router) holds `Locale` and `ThemeMode`, persisted in
  `shared_preferences` keys `localeCode` and `themeMode`. These keys are already preserved by
  `SignOutService`.
- The default is Arabic + system.
- When signed in, a language change also calls `common_update_profile(p_locale)`, best effort and
  retried on the next launch if it failed, so emails and push follow it (FR-024).
- English is listed only when `app_config.english_enabled` is true (default true; §19 item 6).

**Rationale**: These are device preferences that visitors need too. The profile copy only drives
server-sent messages.

**Alternatives**:
- Store them only in the profile: visitors couldn't change them.
- Read the device locale: the product is Arabic-first.

## R10 — Notification preferences shape

**Decision**: `common_get_notification_preferences()` changes (delta U9) to return the guest catalog:
`[{category, label_key, is_mandatory, channels: [{channel: push|email, enabled}]}]`.
- Categories with any mandatory guest type are returned `is_mandatory: true` with all channels
  enabled.
- The app renders it as-is.
- Writes go through `common_set_notification_preferences(items)`, which ignores or refuses mandatory
  categories server-side.
- In-app is not listed (always on).

**Rationale**:
- The as-built function returns only stored rows, so a new user sees nothing and the app would have
  to hard-code categories and mandatory flags. Constitution II and the spec Assumptions forbid that.

**Alternatives**: Hard-coded categories in the app: drift from `notification_types` and breaks when
the admin changes channels.

## Other resolved points

- **Attachment limits**: from `app_config.upload_limits`, which is the existing
  `platform_settings.upload_limits` `{image_mb: 10, pdf_mb: 15}` exposed publicly (U10), plus
  `max_files: 5` (new key).
  - App defaults when absent: 10 MB / 15 MB / 5 files.
  - The spec assumption ("up to 10 MB each") is refined: PDFs may be 15 MB per the server setting.
- **Support number and hours**:
  - `app_config.support_phone` already exists in the app model;
  - `support_hours_ar/en` are new and optional;
  - the call button hides when the phone is empty (FR-016).
- **Legal pages**: `app_config.terms_url` / `privacy_url` (localized `_ar`/`_en`) open in the in-app
  browser.
- **Case types offered**: `booking`, `payment`, `refund`, `property_issue`, `other`. The server
  rejects other types from guests. System-created types (`damage_dispute`, `complaint`,
  `stay_exception`, …) map to labels and default to «أخرى» when unknown.
- **Status labels**: `open`→مفتوحة, `in_progress`→قيد المتابعة, `waiting_user`→مستني ردك,
  `resolved`→اتحلّت, `closed`→مقفولة. An unknown status gets a neutral label.
- **Description limits**: 10–4000 characters (spec FR-006), mirrored server-side (U1).
