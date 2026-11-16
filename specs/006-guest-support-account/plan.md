# Implementation Plan: Guest Support & Account (G4)

**Branch**: `feature/006-guest-support-account` | **Date**: 2026-11-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-guest-support-account/spec.md`

## Summary

Replace the two placeholders (`SupportEntryPlaceholderScreen`, `AccountPlaceholderScreen`) with the
full G4 surface:

- **Support** (`features/support`):
  - support home: FAQ Hero header, «حالاتي» with open cases first, «حالة جديدة», FAQ entry, call
    button;
  - new case: type, optional linked booking or apartment, description, up to 5 attachments;
  - case details: guest-visible messages, reply with attachments, live updates while open;
  - public FAQ with search and an offline copy.

  Every existing «كلّم الدعم» / «تواصل مع OnAir» entry point and every `support.*` notification now
  lands on a real screen.
- **Private attachments** (`lib/core/files/`):
  - pick from camera, gallery or files;
  - re-encode photos to JPEG (EXIF/GPS stripped, longest side ≤ 2048 px);
  - get a signed PUT URL from Node `POST /v1/uploads/sign` and upload;
  - view through `GET /v1/files/{id}/url`, never cached on disk.

  Files are uploaded **before** the case or reply exists, against a client `draft_id` that is also the
  idempotency key of the create/reply call (research R3, delta U2).
- **Account** (`features/account`):
  - the account screen: profile row, edit name, sign-in method and phone rows from S005, settings
    rows, legal links, sign-out;
  - «الأمان»: change password for password accounts, the sessions list with per-device and all-others
    sign-out (clarified);
  - «الإشعارات»: category × channel switches with locked mandatory rows;
  - «حذف الحساب»: explanation → server blocker check → email code → immediate deletion (clarified).
- **App settings** (`lib/app/settings/`): `AppSettingsCubit` for language (ar/en) and appearance
  (system/light/dark), stored in the two `shared_preferences` keys sign-out already preserves
  (`localeCode`, `themeMode`). Today `app.dart` hard-codes `Locale('ar')` and `ThemeMode.system`.

**Backend dependency:** as-built `onair-backend` has:
- the `support_cases`, `case_messages` and `attachments` tables, with `case_messages` in the Realtime
  publication;
- `common_list_faq`, `common_get/set_notification_preferences`, `common_update_profile`,
  `common_authorize_upload/download`;
- Node `/v1/uploads/sign`, `/v1/files/{id}/url` and `/v1/otp/send`.

It is missing:
- all four guest support RPCs and draft uploads;
- the account-deletion request/confirm pair;
- the sessions list and ending sessions;
- password change with the current password;
- the preference catalog with mandatory flags;
- public app-config fields (support hours, legal URLs, upload limits).

These are drafted as deltas **U1–U10** in
[contracts/supabase-support-account.md](contracts/supabase-support-account.md) and
[contracts/node-account.md](contracts/node-account.md). They are implemented in
`D:\flutter\onair-backend` (never here, AGENTS.md). Until they ship, every journey runs on the mock
backend (`BackendMode.mock`), as in G1–S005.

Details: [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md).

## Technical Context

**Language/Version**: Dart 3.12.2, Flutter 3.44.3 (stable), SDK constraint `^3.12.2`. No native code.

**Primary Dependencies**:
- Existing stack:
  - `flutter_bloc`, `go_router`, `supabase_flutter` (RPC, Realtime, `auth.signOut`);
  - `dio` + the generated Node client (`signUpload`, `getFileUrl`, `/v1/otp/send`);
  - `url_launcher` (`tel:`, legal pages in the in-app browser), `app_settings` (device notification
    settings);
  - `shared_preferences` (language, theme), `intl`, `timezone`, `uuid`.
- **Added** (research R1–R2):
  - `image_picker` (camera and gallery photos);
  - `file_picker` (PDF only);
  - `flutter_image_compress` (re-encode to JPEG, EXIF dropped, resize).
- Contract regeneration: `node-api.openapi.yaml` gains `support_draft` and `/v1/account/password`. The
  generated client is regenerated, never hand-edited.

**Storage**:
- `shared_preferences`: `localeCode` and `themeMode`, already listed in
  `SignOutService.preservedPreferenceKeys`.
- FAQ JSON cache via the existing cache module: public and non-personal, so it survives sign-out.
- Nothing personal is persisted:
  - case lists, messages, drafts, picked files and signed URLs stay in memory;
  - picked or compressed temporary files are deleted after upload or when the screen closes.

**Testing**:
- `flutter_test`, `bloc_test`, `mocktail`, `fake_async` (case live-update fallback polling, session
  heartbeat timer, deletion code countdown).
- `alchemist` goldens:
  - support home (empty, list, offline);
  - new case with attachments (uploading, failed, ready);
  - case details (guest/OnAir bubbles, closed state);
  - FAQ;
  - account screen (email user, Google user, visitor);
  - security (password row present/absent, sessions);
  - notification preferences with locked rows;
  - delete account (explanation, blocked, code step).

  Each golden covers Light, Dark, RTL, LTR, 1.3× text, 320 dp and 800 dp widths, and keyboard open
  where there is input.
- `integration_test` (mock):
  - `support_case_mock_test.dart`: booking → new case with 2 photos → staff reply arrives → reply on
    the resolved case reopens it;
  - `account_settings_mock_test.dart`: name, language, theme, preferences, password, end a session;
  - `delete_account_mock_test.dart`: blocked by an active booking, then a successful deletion → visitor.
- Staging variants once U1–U10 ship.

**Target Platform**: Android 7.0+ (API 24) and iOS 15+.
- Camera and photo-library usage descriptions are added to `Info.plist`.
- Android uses the system photo picker through `image_picker`, so no storage permission is needed.

**Project Type**: Mobile app (single Flutter project at repository root), plus backend deltas in the
separate `onair-backend` repository.

**Performance Goals**:
- Support home and the account screen show a skeleton within one frame.
- The FAQ renders from cache in < 2 s (SC-008).
- A staff reply appears in an open case within 5 s (SC-003) through a Realtime channel scoped to that
  case, with 10 s polling as the fallback while the channel is down.
- Photo re-encoding runs off the UI thread. The UI shows progress and keeps 60 fps.
- Case and message lists use slivers with cursor pagination.

**Constraints**:
- Constitution II: case status, deletion blockers, mandatory notification flags, password rules,
  session ownership and upload limits all come from the server.
- Constitution IV:
  - EXIF stripped before upload;
  - signed URLs never cached on disk;
  - no PII in logs (case bodies and names are masked);
  - sign-out and deletion reuse `SignOutService`.
- Constitution VIII: Realtime use on the open case screen is a recorded deviation (Complexity
  Tracking).
- Open plan items stay configurable (§19): attachment limits come from server config; the support
  number and hours come from `app_config`; English can be hidden by an `app_config` flag.

**Scale/Scope**:
- **Screens — new:**
  - support home, new case, case details, FAQ;
  - account (rebuilt), edit name (sheet), security, change password, notification preferences, delete
    account (with its code step);
  - language and appearance pickers (sheets).
- **Screens — changed:** account suspended (adds FAQ and call), booking details / property support
  entry (route only).
- **Routes:** 8 new or changed; see [contracts/app-routes.md](contracts/app-routes.md).
- **New design-system components:** 4 — `AttachmentTile`, `MessageBubble`, `SettingsRow` (icon tones
  from Settings Icons), `CaseStatusChip`.
- **Backend calls:** 11 RPCs (4 new support, 1 changed profile, 2 deletion, 3 sessions,
  2 preferences) and 3 Node routes (`signUpload` changed, `getFileUrl`, new `/v1/account/password`),
  plus `/v1/otp/send` for the deletion email code.
- **Volume:** pilot scale. Tens of cases per guest at most, so paginate at 20 per page.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Checked against constitution **v2.1.0**.

| Principle | How G4 complies | Status |
|---|---|---|
| I. Master Plan fidelity & scope | Implements Guest Plan §6.17, §6.18 and §17 G4 only. No owner contact (AC-047): a case is always with OnAir. The guest form offers only the five plan types. Profile photo is deferred (clarified), and so is email change. §19 items 4–7 are not invented: limits, support number and hours, and the English flag come from server config; retention is server/legal. | PASS |
| II. Server is the authority | Case status (including reopening a resolved case) is set by the server. The deletion blocker comes only from the server (`ACCOUNT_HAS_ACTIVE_BOOKINGS` + details). Mandatory notification rows come from the server catalog. The app never decides them. The password rule check is UX only. Session ownership and "current session" come from the server. | PASS |
| III. Payment integrity | Untouched. Deletion is refused server-side while a payment or refund is open. | PASS |
| IV. Security & privacy | Photos are re-encoded with EXIF dropped (R2). Uploads use short-lived signed URLs, and viewing re-fetches the URL, with no disk cache (R4). Logout and deletion reuse `SignOutService` (session, device token, caches, Google sign-out). Password change requires the current password on the server (U8). A revoked session signs out on the next heartbeat (R7). Case bodies are never logged. | PASS |
| V. Design system | The new components live in `lib/design_system/components/`. The FAQ Hero gradient is used only on the support/FAQ header (§4.3). Settings Icons tones are used for the rows (Danger for deletion and sign-out). `CaseStatusChip` carries text + icon. No hex or font-size literals. | PASS |
| VI. Arabic-first, RTL & a11y | All copy is in `.arb`. Switching language flips direction live. Message bubbles align by author with directional insets. Attachment tiles and the call/remove icons have Semantics labels. Locked switches announce «إلزامي». Goldens run at 1.3×. | PASS |
| VII. Layered, feature-first | `features/support` and `features/account` each have domain interfaces with Supabase and Mock implementations. File picking, compression and upload sit in `lib/core/files/` (shared with future G5/G3 evidence). App settings live in `lib/app/settings/`. The three new packages pass review in research R1–R2. | PASS |
| VIII. UX states & performance | Every screen has skeleton, empty, error + reference, offline banner with actions disabled, and success. Lists use slivers + cursor. The Realtime channel closes on exit. See Complexity Tracking for the Realtime scope. | PASS (with recorded deviation) |
| IX. Test discipline | Test-first for: `CaseStatus` mapping and ordering, the reopen-on-reply rendering, attachment validation and upload state machine, draft idempotency (one case per draft), deletion blocker mapping, the session-revoked → sign-out path, the preference lock rule, and the language/theme persistence. Security tests: a deep link to a foreign case shows not-found (mock + staging); internal notes are never returned (staging); repeated create/reply taps → one record; deletion with an active booking is refused even with a crafted request (staging). Linked ACs: AC-047; store account-deletion requirement. | PASS |
| Repository constraints | No backend code here. Deltas U1–U10 are in `contracts/` for `onair-backend`, inside the existing `onair-api` Worker. | PASS |

### Post-design re-check (after Phase 1)

All rows stay PASS. Points checked specifically:

- **Server authority (II)**:
  - [data-model.md](data-model.md) §1 `CaseStatus.isReplyable` is display-only; a refused reply shows
    the server's `CASE_CLOSED`.
  - §6 `DeletionBlocker` is built only from the server error details.
- **No early or duplicate writes (IV / IX)**:
  - [contracts/supabase-support-account.md](contracts/supabase-support-account.md) U1 makes create and
    reply idempotent on `draft_id`.
  - U2 binds draft attachments only inside that call.
- **Privacy (IV)**: [data-model.md](data-model.md) §2 `AttachmentDraft` holds a temp file path that is
  deleted after upload or on dispose. `FileUrl` is memory-only with its `expires_at`.
- **Design (V)**: [contracts/ui-screens.md](contracts/ui-screens.md) maps every section to existing or
  the 4 new components.

## Project Structure

### Documentation (this feature)

```text
specs/006-guest-support-account/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R1–R10
├── data-model.md        # Phase 1: app-side models and states
├── quickstart.md        # Phase 1: setup and validation scenarios
├── contracts/
│   ├── supabase-support-account.md  # Backend deltas U1–U7, U9–U10 (RPCs, Realtime, config)
│   ├── node-account.md              # Backend deltas U2 (uploads) + U8 (password)
│   ├── app-routes.md                # Route, guard and notification-routing changes
│   └── ui-screens.md                # Screen → component map, copy keys, golden matrix
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks; not created here)
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── settings/
│   │   ├── app_settings_cubit.dart        # NEW: locale (ar/en) + ThemeMode, shared_preferences
│   │   └── app_settings_store.dart        # NEW: keys localeCode/themeMode
│   ├── app.dart                           # reads AppSettingsCubit instead of hard-coded values
│   └── router/
│       ├── routes.dart                    # + support, supportFaq, accountSecurity, accountPassword,
│       │                                  #   accountNotifications, accountDelete
│       ├── app_router.dart                # wire real screens; remove placeholders
│       ├── redirect.dart                  # /support/faq public; others account-gated (unchanged rule)
│       └── notification_router.dart       # support.* → /support/:caseId (target_id)
├── core/
│   ├── files/
│   │   ├── attachment_picker.dart         # NEW: camera / gallery / PDF
│   │   ├── image_sanitizer.dart           # NEW: JPEG re-encode, EXIF drop, ≤2048 px
│   │   ├── upload_limits.dart             # NEW: from app_config (server), defaults if absent
│   │   └── private_file_uploader.dart     # NEW: signUpload → PUT, progress, cancel
│   ├── config/app_config.dart             # + supportHours, termsUrl, privacyUrl, uploadLimits,
│   │                                      #   englishEnabled
│   ├── session/session_heartbeat.dart     # NEW: common_heartbeat on resume + every 60 s
│   └── errors/error_mapper.dart           # + CASE_CLOSED, ATTACHMENT_REJECTED, SESSION_REVOKED,
│                                          #   SESSION_IS_CURRENT, PASSWORD_INCORRECT, PASSWORD_WEAK
├── design_system/tokens/on_air_colors.dart  # + Settings Icons tones (UI_UX_DESIGN_SYSTEM.md)
├── design_system/components/
│   ├── attachment_tile.dart               # NEW
│   ├── message_bubble.dart                # NEW
│   ├── settings_row.dart                  # NEW
│   └── status_chip.dart                   # + CaseStatusChip
├── features/
│   ├── support/
│   │   ├── domain/{support_case,case_message,support_repository,faq_item,attachment_draft}.dart
│   │   ├── data/{supabase_support_repository,mock_support_server,faq_cache}.dart
│   │   └── presentation/
│   │       ├── home/{support_home_cubit,support_home_screen}.dart
│   │       ├── new_case/{new_case_cubit,new_case_screen}.dart
│   │       ├── case/{case_details_cubit,case_details_screen,case_live_channel}.dart
│   │       ├── faq/{faq_cubit,faq_screen}.dart
│   │       └── widgets/{attachment_strip,reply_composer,call_support_button}.dart
│   ├── account/
│   │   ├── domain/{account_repository,active_session,notification_preference,deletion}.dart
│   │   ├── data/{supabase_account_repository,mock_account_server}.dart
│   │   └── presentation/
│   │       ├── account_screen.dart        # replaces account_placeholder_screen.dart
│   │       ├── edit_name_sheet.dart
│   │       ├── security/{security_cubit,security_screen,change_password_screen}.dart
│   │       ├── notifications/{preferences_cubit,preferences_screen}.dart
│   │       ├── delete/{delete_account_cubit,delete_account_screen}.dart
│   │       └── account_suspended_screen.dart   # + FAQ + call
│   └── support/presentation/support_entry_placeholder_screen.dart   # DELETED
├── l10n/app_ar.arb, app_en.arb            # new keys (contracts/ui-screens.md §4)
└── bootstrap.dart                         # wire repositories (remote/mock), heartbeat, settings

ios/Runner/Info.plist                      # + NSCameraUsageDescription, NSPhotoLibraryUsageDescription
contracts/node-api.openapi.yaml            # + support_draft entity, /v1/account/password (then regenerate)
contracts/error-codes.md                   # + G4 codes

test/ …                                    # cubits, repositories, mock servers, goldens, router
integration_test/
├── support_case_mock_test.dart
├── account_settings_mock_test.dart
└── delete_account_mock_test.dart
```

**Structure Decision**: Single Flutter project in the existing feature-first layout.
- Support and account are separate features because they share nothing but the core file uploader.
- File handling is core infrastructure because G5 reviews and future evidence uploads will reuse it.
- Language and theme are app-level settings, not account data: they also work for visitors, and only
  the language is mirrored to the profile when signed in.
- Backend work is specified as contracts only.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Realtime subscription on the open **support case** screen (Constitution VIII allows it only on payment verification and an open booking's details) | FR-005 / SC-003: a staff reply must appear within 5 s while the guest is reading the case. Guest Plan §2.7.2 already names Realtime for `case_messages`, and the backend has it in the publication. Scope is the same as the allowed booking case: one channel, filtered to one case id, opened on enter and closed on exit. | Polling every 5 s while the screen is open meets the latency only at 12 requests per minute per viewer. It would also re-read the whole conversation, or need a new "since" endpoint. It is kept only as the 10 s fallback when the channel drops. Recommend a PATCH amendment adding "an open support case" to the allowed list. |
