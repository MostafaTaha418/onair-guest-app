# Quickstart & validation: Guest Support & Account (G4)

How to run and prove G4 works. Design details live in [plan.md](plan.md),
[data-model.md](data-model.md) and [contracts/](contracts/). This is a run guide, not code.

## 1. Prerequisites

**App (this repository):**
- Flutter 3.44.3 / Dart 3.12.2.
- `env/staging.json` locally (git-ignored).
- Branch `feature/006-guest-support-account`.

**Backend (`onair-backend`, for Remote mode only):**
- Deltas **U1–U10** merged and deployed to Staging:
  - Supabase migrations: U1, U3–U7, U9–U10 — [contracts/supabase-support-account.md](contracts/supabase-support-account.md);
  - `onair-api` Worker: U2, U8 — [contracts/node-account.md](contracts/node-account.md).
- Staging `app_config` filled: `support_phone`, `support_hours_*`, legal URLs, `upload_limits` with
  `max_files`, `english_enabled`.
- At least 5 published `faq_items` for audience `guest`, in Arabic and English.
- Seed guests:
  - **G-A**: completed stays only (deletable);
  - **G-B**: a confirmed upcoming booking (deletion blocked);
  - **G-C**: email + password, signed in on 2 devices;
  - **G-D**: Google, no password.

Manual steps that are not code:
- **M1**: legal review of the deletion explanation text and the retention policy (§19 item 7).
- **M2**: support number and hours decided (§19 item 5).
- **M3**: Apple/Google store "account deletion" answers updated to point to «حسابي → حذف الحساب».
- **M4**: privacy policy, Data safety and Privacy manifest updated for support attachments, which
  contain photos, plus camera/photo-library usage.

## 2. Local setup

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Mock mode** (no backend needed): set `"BACKEND_MODE": "mock"` in your local `env/staging.json`,
then:

```bash
flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json
```

Mock conventions, extending the S005 ones:
- **Email code:** every email code (including deletion) is `123456`.
- **Support staff replies:** the mock replies 3 s after any guest message on a case. A debug-only
  long press on the case app bar opens a tools sheet: «رد من OnAir», «اتحلّت», «اتقفلت».
- **Upload failures:** files named `fail*` fail on first upload; a retry succeeds.
- **Deletion blockers:** the mock account `blocked@onair.test` has an active booking.
- **Sessions:** the mock lists the current device + 2 others.

## 3. Automated checks

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter test integration_test/support_case_mock_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter test integration_test/account_settings_mock_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

```bash
flutter test integration_test/delete_account_mock_test.dart --flavor staging --dart-define-from-file=env/staging.json
```

**Expected:** analyze has zero issues and all tests pass. The goldens follow the matrix in
[contracts/ui-screens.md](contracts/ui-screens.md) §5.

## 4. Manual validation scenarios

Run each scenario in mock mode first, then on Staging with the seed guests. Every scenario is also
checked in dark mode, in English, at 1.3× text and on a 320 dp-wide emulator.

| # | Scenario | Expected | Covers |
|---|---|---|---|
| V1 | From a booking's details tap «تواصل مع OnAir», add 2 camera photos + 1 PDF, type 20 characters, double-tap «إرسال» | One case is created with the booking linked and type «حجز». Photos are uploaded as JPEG; check that the EXIF has no GPS by downloading on Staging and inspecting. You land on the case | US2, FR-006–FR-012, SC-001/002 |
| V2 | Pick a 20 MB photo, then a `.docx` | The photo is compressed below the limit, or refused if still too big. The `.docx` is not selectable | FR-011 |
| V3 | Turn on airplane mode during an upload, then off, then «إعادة المحاولة» | The tile goes to failed then ready. Send is blocked meanwhile, and the text is kept | FR-012, Edge (offline) |
| V4 | Keep a case open; send a staff reply from mock tools / admin | The reply shows within 5 s without refreshing. The list dot updates on back | US1-4, SC-003 |
| V5 | Mark the case «اتحلّت», then reply | The notice is shown. After the reply the status becomes «مفتوحة» | US1-8 (clarified) |
| V6 | Mark the case «اتقفلت» | The composer is replaced by «افتح حالة جديدة», which pre-links the booking | US1-5, FR-004 |
| V7 | Open `https://<link-domain>/support/<another guest's case id>` and `/support/not-a-uuid` | A neutral not-found screen; nothing leaks | US1-7, SC-004 |
| V8 | Tap a `support.staff_replied` push with the app killed | The case opens (after sign-in if needed) | US1-6, U4 |
| V9 | Sign out, open «حسابي» → «الأسئلة الشائعة», search, switch to English | Works without an account. English content shows | US3, SC-008 |
| V10 | Offline, open the FAQ again | The cached list shows with the "may be out of date" banner | US3-3 |
| V11 | Tap the call button; repeat on a tablet; clear `support_phone` on Staging | The dialer opens; the tablet shows a copyable number; with no number the button is hidden | US3-4/5, FR-016 |
| V12 | Change the name, the language to English and the appearance to dark; kill and relaunch | All three persist. The UI is LTR. An English email/push arrives for the next event | US5, FR-023–FR-025 |
| V13 | G-D (Google): open «الأمان» | No password row; the sessions list is shown | US6-4 |
| V14 | G-C on devices A + B: on A end B's session; on B, resume the app | B returns to sign-in with «انتهت الجلسة» within 1 min (or on resume) | US6-5/6, SC-010 |
| V15 | G-C on A: change the password with a wrong current one, then the right one | Error under the field; then success. B is signed out, the old password fails, and the «تم تغيير كلمة المرور» notice and email arrive | US6-1/3, FR-030 |
| V16 | Turn off push for «الدعم», get a staff reply; try toggling a locked booking category | The in-app notification appears but no push. The locked switch can't change. A crafted call is refused by the server | US7, FR-034, SC-007 |
| V17 | G-B: «حذف الحساب» | Blocked, listing the booking with a tap-through. No code is sent | US4-2, SC-006 |
| V18 | G-A: delete, enter a wrong code, then the right one | Error, then success. The visitor home shows «حسابك اتحذف» once. Signing in again with the same email/Google gives a new empty account. Other devices are signed out | US4-1/3, SC-005 |
| V19 | Rapid taps on every send-type button (reply, name save, session end, password, deletion confirm) | Exactly one request each | FR-036, SC-002 |
| V20 | TalkBack/VoiceOver pass over account, case details and new case | Every control is announced, locked switches say «إلزامي», and the focus order is right in RTL | FR-037 |

## 5. Done when

- Every V-scenario passes in mock mode. On Staging they pass once U1–U10 are deployed.
- The backend owner's acceptance checks in
  [contracts/supabase-support-account.md](contracts/supabase-support-account.md) pass on Staging.
- `docs/OnAir Guest App Plan.md` §17 G4 is ticked with a status note, as for G3/S005. §19 items 4–7
  are updated with what was decided (limits, number, English, retention).
- `contracts/error-codes.md` and `contracts/node-api.openapi.yaml` are updated, and the client is
  regenerated.
