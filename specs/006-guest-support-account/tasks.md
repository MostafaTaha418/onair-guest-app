---

description: "Task list for G4 — Guest support & account"
---

# Tasks: Guest Support & Account (G4)

**Input**: `specs/006-guest-support-account/` — [spec.md](spec.md), [plan.md](plan.md),
[research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md)

**Tests**: REQUIRED. Constitution IX requires:
- test-first for domain logic, guards and state machines;
- widget tests for Loading / Empty / Error / Offline / Success;
- goldens for new screens and components;
- security tests.

Write each test task **before** its implementation task and check that it fails first.

**Organization**: Phases follow the spec's user stories in priority order: US1–US4 (P1), US5–US6
(P2), US7 (P3). Phase 2 blocks every story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1…US7 from spec.md

---

## 0. Rules for the implementer (read before ANY task)

When in doubt, **stop and ask**. Do not guess a business rule (Constitution I).

1. **Read before you write.** Open every file a task names, plus the closest existing file of the same
   kind, and copy its patterns:
   - `lib/features/stay/` for a full feature (domain interface + `supabase_*` + `mock_*` server +
     cubits);
   - `lib/features/stay/presentation/claims/evidence_url_cache.dart` for signed URLs;
   - `lib/core/realtime/notification_signal.dart` for a Realtime channel with a controllable fake;
   - `lib/features/auth/presentation/otp_screen.dart` and
     `lib/features/stay/presentation/cash/cash_confirm_screen.dart` for an email-code step;
   - `test/features/account/goldens/` and `test/features/stay/goldens/` for goldens.
2. **Never edit** `lib/core/api/generated/**` by hand. To change the Node client:
   1. edit `contracts/node-api.openapi.yaml`;
   2. run `dart run swagger_parser`;
   3. run `dart run build_runner build --delete-conflicting-outputs`.
3. **Never write backend code here** (no SQL, no migrations, no Worker code; AGENTS.md). Backend work
   is U1–U10 in `contracts/supabase-support-account.md` and `contracts/node-account.md`, done in
   `D:\flutter\onair-backend`.
4. **UI rules:**
   - Read `DESIGN.md`, `docs/design_reference/README.md` and references **#12 Profile**, **#13
     Settings** and **#26** before any screen.
   - Every string goes in **both** `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`, then run
     `flutter gen-l10n`.
   - No `Color(0x…)` and no raw font sizes. Use `context.colors`, theme text styles and
     `Dimens.*`.
   - Use `EdgeInsetsDirectional` / `AlignmentDirectional` / `start` / `end` only.
   - Every icon-only control gets `Semantics(label: …)` and a touch target ≥ 48 dp.
   - Every async button: disable on the first tap, show the loader inside the button, and wrap it
     with `RapidSubmitGuard` (`lib/features/auth/presentation/widgets/rapid_submit_guard.dart`).
5. **Mock mode is the default** (`BACKEND_MODE=mock`). Every email code is
   `MockBackend.verificationCode` (`'123456'`).
6. **Privacy:** never log, print or send to crash reports:
   - case or message bodies;
   - names, emails or phones;
   - passwords;
   - file names;
   - signed URLs.

   Use `AppLogger` with IDs only. Never write drafts, picked files or signed URLs to
   `shared_preferences`, `JsonFileCache` or any disk cache. Temp files from compression are deleted
   after upload or discard.
7. **After every phase**, run these in order and fix everything before moving on:
   ```bash
   dart format .
   flutter analyze
   flutter test
   ```
   Regenerate only the goldens a task names (`flutter test --update-goldens <file>`), and inspect
   the PNG before accepting it.
8. Commit after each phase with a conventional message, for example `feat(support): …` or
   `test(account): …`.

### Reference values (use exactly these)

| Name | Value |
|---|---|
| Guest case types (form) | `booking`, `payment`, `refund`, `property_issue`, `other` |
| System case types (display) | `damage_dispute`, `complaint`, `stay_exception`; anything else → `unknown` |
| Case statuses | `open`→«مفتوحة», `in_progress`→«قيد المتابعة», `waiting_user`→«مستني ردك», `resolved`→«اتحلّت», `closed`→«مقفولة»; anything else → `unknown` |
| Open statuses (list first) | `open`, `in_progress`, `waiting_user` |
| Case description | trimmed, **10–4000** characters |
| Reply body | trimmed, **1–4000** characters |
| Name | trimmed, **2–80** characters |
| Page sizes | cases 20; messages 50 |
| Upload defaults (if `app_config.upload_limits` absent) | `image_mb: 10`, `pdf_mb: 15`, `max_files: 5` |
| Photo sanitizing | JPEG, quality 80, longest side ≤ 2048 px, `keepExif: false` |
| Allowed pick types | photos (camera/gallery; HEIC/PNG/JPEG → JPEG) and `pdf` only |
| Upload entity for drafts | `entity_type: support_draft`, `entity_id: <draftId UUID v4>` |
| Live case fallback poll | every 10 s while the Realtime channel is not subscribed |
| Signed URL refresh | when < 30 s to `expires_at`, or after 403 |
| Session heartbeat | `common_heartbeat` on app resume + every 60 s in the foreground |
| Password rule (UX) | ≥ 8 characters, at least one letter and one digit, new ≠ current |
| Prefs keys (kept on sign-out) | `localeCode` (`ar`/`en`, default `ar`), `themeMode` (`system`/`light`/`dark`, default `system`) |
| New routes | `AppRoutes.support='/support'`, `supportFaq='/support/faq'`, `accountSecurity='/account/security'`, `accountPassword='/account/security/password'`, `accountNotifications='/account/notifications'`, `accountDelete='/account/delete'` |
| New error codes | `CASE_CLOSED`, `ATTACHMENT_REJECTED` (`details.reason`: `too_large`/`type_not_allowed`/`too_many`), `SESSION_REVOKED`, `SESSION_IS_CURRENT`, `PASSWORD_INCORRECT`, `PASSWORD_WEAK`; `ACCOUNT_HAS_ACTIVE_BOOKINGS` gains `details.blockers` |
| RPCs (U1/U5/U6/U7/U9) | `common_list_my_support_cases(p_cursor,p_limit)`, `common_get_support_case(p_case_id,p_before_cursor)`, `common_create_support_case(p_type,p_body,p_draft_id,p_booking_id,p_property_id,p_attachment_ids)`, `common_reply_support_case(p_case_id,p_body,p_draft_id,p_attachment_ids)`, `common_list_faq('guest')`, `common_request_account_deletion()`, `common_confirm_account_deletion(p_challenge_id,p_code)`, `common_list_my_sessions()`, `common_end_session(p_session_id)`, `common_end_other_sessions()`, `common_heartbeat()`, `common_update_profile(p_full_name,p_locale)`, `common_get_notification_preferences()`, `common_set_notification_preferences(p_items)` |
| Node routes | `POST /v1/uploads/sign` (+`support_draft`), `GET /v1/files/{id}/url`, `POST /v1/otp/send`, **new** `POST /v1/account/password` |
| User-Agent | `OnAirGuest/<version> (<android\|ios> <os version>; <model>)` on Supabase and Dio clients |

### Localization keys (add to both ARB files)

| Key | Arabic | English |
|---|---|---|
| `supportTitle` | الدعم | Support |
| `supportSubtitle` | إحنا هنا عشان نساعدك | We're here to help |
| `supportMyCases` | حالاتي | My cases |
| `supportFinishedCases` | حالات منتهية | Finished cases |
| `supportNewCase` | حالة جديدة | New case |
| `supportEmpty` | لسه مفتحتش أي حالة | You haven't opened any cases yet |
| `supportLastUpdate` | آخر تحديث {time} | Updated {time} |
| `supportStatusOpen` / `InProgress` / `WaitingUser` / `Resolved` / `Closed` / `Unknown` | مفتوحة / قيد المتابعة / مستني ردك / اتحلّت / مقفولة / حالة غير معروفة | Open / In progress / Waiting for you / Resolved / Closed / Unknown status |
| `supportTypeBooking` / `Payment` / `Refund` / `PropertyIssue` / `Other` / `DamageDispute` / `Complaint` / `StayException` / `Unknown` | حجز / دفع / استرداد / مشكلة في الشقة / أخرى / اعتراض على مطالبة / شكوى / استثناء في الإقامة / أخرى | Booking / Payment / Refund / Apartment problem / Other / Damage dispute / Complaint / Stay exception / Other |
| `supportType` | نوع المشكلة | Issue type |
| `supportLinkBooking` | اربط بحجز | Link a booking |
| `supportLinkedBooking` | الحجز {code} | Booking {code} |
| `supportLinkedProperty` | الشقة: {title} | Apartment: {title} |
| `supportDescription` | اكتب اللي حصل | Describe what happened |
| `supportDescriptionTooShort` | اكتب 10 حروف على الأقل | Write at least 10 characters |
| `supportSend` | إرسال | Send |
| `supportCreated` | وصلتنا حالتك رقم {code} | We got your case {code} |
| `supportDiscardTitle` | تسيب الحالة من غير ما تبعتها؟ | Leave without sending? |
| `supportDiscard` | سيبها | Discard |
| `supportKeepEditing` | كمّل | Keep editing |
| `supportReplyHint` | اكتب ردك | Write a reply |
| `supportOnAir` | OnAir | OnAir |
| `supportCaseClosed` | الحالة دي اتقفلت | This case is closed |
| `supportOpenNewCase` | افتح حالة جديدة | Open a new case |
| `supportResolvedNotice` | الحالة اتحلّت. لو لسه محتاج مساعدة ردّ هنا وهنفتحها تاني | This case was resolved. Still need help? Reply here and we'll reopen it. |
| `supportCaseNotFound` | الحالة دي مش موجودة | This case isn't available |
| `supportBackToSupport` | الرجوع للدعم | Back to support |
| `supportAttach` | إضافة | Add |
| `supportAttachCamera` / `Gallery` / `Pdf` | الكاميرا / الصور / ملف PDF | Camera / Photos / PDF file |
| `supportAttachHint` | لحد {count} ملفات، صور أو PDF | Up to {count} files, photos or PDF |
| `supportAttachRemove` | شيل الملف | Remove file |
| `supportAttachRetry` | إعادة المحاولة | Retry |
| `supportAttachFailed` | فشل الرفع | Upload failed |
| `supportAttachmentRejectedTooLarge` | الملف أكبر من {size} ميجا | The file is larger than {size} MB |
| `supportAttachmentRejectedType` | النوع ده مش مسموح. صور أو PDF بس | This type isn't allowed. Photos or PDF only |
| `supportAttachmentRejectedTooMany` | وصلت للحد: {count} ملفات | Limit reached: {count} files |
| `supportFaq` | الأسئلة الشائعة | FAQ |
| `supportFaqSearch` | ابحث في الأسئلة | Search questions |
| `supportFaqNoResults` | مفيش نتايج | No results |
| `supportFaqStale` | ممكن تكون المعلومات دي قديمة | This information may be out of date |
| `supportCall` | اتصل بخدمة العملاء | Call customer service |
| `supportCallHours` | مواعيد العمل: {hours} | Working hours: {hours} |
| `supportCallCopied` | اتنسخ الرقم | Number copied |
| `accountEdit` | تعديل | Edit |
| `accountEditName` | تعديل الاسم | Edit name |
| `accountNameLabel` | الاسم | Name |
| `accountNameInvalid` | الاسم لازم يكون من 2 لـ 80 حرف | Name must be 2–80 characters |
| `accountSave` | حفظ | Save |
| `accountSectionGeneral` / `Security` / `Support` / `Legal` | عام / الأمان / الدعم / قانوني | General / Security / Support / Legal |
| `accountNotifications` | الإشعارات | Notifications |
| `accountAppearance` | المظهر | Appearance |
| `accountLanguage` | اللغة | Language |
| `settingsThemeSystem` / `Light` / `Dark` | حسب الجهاز / فاتح / داكن | System / Light / Dark |
| `settingsLanguageArabic` / `English` | العربية / English | العربية / English |
| `accountSecurityRow` | الأمان والأجهزة | Security & devices |
| `accountTerms` | الشروط والأحكام | Terms & conditions |
| `accountPrivacy` | سياسة الخصوصية | Privacy policy |
| `accountSignOut` | تسجيل الخروج | Sign out |
| `accountSignOutConfirm` | تخرج من حسابك؟ | Sign out of your account? |
| `accountDelete` | حذف الحساب | Delete account |
| `accountVisitorTitle` | سجّل دخولك عشان تتابع حجوزاتك | Sign in to manage your bookings |
| `accountChangePassword` | تغيير كلمة المرور | Change password |
| `accountCurrentPassword` / `NewPassword` / `ConfirmPassword` | كلمة المرور الحالية / كلمة المرور الجديدة / تأكيد كلمة المرور | Current password / New password / Confirm password |
| `accountPasswordMismatch` | كلمتين المرور مش زي بعض | Passwords don't match |
| `accountPasswordSameAsOld` | اختار كلمة مرور مختلفة عن الحالية | Choose a password different from the current one |
| `accountPasswordIncorrect` | كلمة المرور الحالية غلط | Current password is incorrect |
| `accountPasswordChanged` | تم تغيير كلمة المرور، وخرّجنا باقي الأجهزة | Password changed, and other devices were signed out |
| `accountDevices` | الأجهزة المسجّل دخولها | Signed-in devices |
| `accountThisDevice` | الجهاز ده | This device |
| `accountLastActive` | آخر نشاط {time} | Last active {time} |
| `accountUnknownDevice` | جهاز | Device |
| `accountEndSession` | خروج | Sign out |
| `accountEndOthers` | تسجيل الخروج من كل الأجهزة التانية | Sign out of all other devices |
| `accountEndOthersConfirm` | هتخرج من كل الأجهزة ما عدا الجهاز ده | You'll be signed out everywhere except this device |
| `accountSessionIsCurrent` | ده الجهاز اللي معاك. استخدم «تسجيل الخروج» | This is your current device. Use "Sign out" |
| `prefsDeviceBlocked` | إشعارات الجهاز مقفولة للتطبيق | Device notifications are off for this app |
| `prefsOpenSettings` | افتح الإعدادات | Open settings |
| `prefsPush` / `prefsEmail` | إشعارات الجهاز / البريد | Device notifications / Email |
| `prefsMandatory` | إشعارات ضرورية للحجز والدفع ومش بتتقفل | Essential booking and payment notifications can't be turned off |
| `prefsMandatoryLabel` | إلزامي | Required |
| `prefsSaveFailed` | مقدرناش نحفظ التغيير | Couldn't save the change |
| `notifCategory<Key>` (one per server category) + `notifCategoryUnknown` | (from the server category list) / أخرى | … / Other |
| `deleteTitle` | حذف الحساب | Delete account |
| `deleteWhatGoes` | هنمسح بياناتك الشخصية: الاسم والبريد والرقم والمفضلة والتفضيلات | We'll erase your personal data: name, email, phone, favorites and preferences |
| `deleteWhatStays` | حجوزاتك ومدفوعاتك القديمة هتفضل محفوظة من غير بياناتك، زي ما القانون بيطلب | Past bookings and payments stay on record without your personal data, as the law requires |
| `deleteFinal` | الحذف نهائي ومالوش رجوع | Deletion is final and can't be undone |
| `deleteUnderstand` | فاهم إن الحذف نهائي | I understand deletion is final |
| `deleteCta` | احذف حسابي | Delete my account |
| `deleteBlockedTitle` | مينفعش تحذف الحساب دلوقتي | You can't delete your account yet |
| `deleteBlockerBooking` / `Refund` / `Claim` | عندك حجز لسه شغال {code} / عندك استرداد لسه بيتنفذ {code} / عندك مطالبة لسه مفتوحة {code} | Active booking {code} / Refund in progress {code} / Open claim {code} |
| `deleteCodeSent` | بعتنا كود على {email} | We sent a code to {email} |
| `deleteConfirm` | تأكيد الحذف | Confirm deletion |
| `deleteDone` | حسابك اتحذف | Your account was deleted |

Placeholders (`{time}`, `{code}`, `{title}`, `{count}`, `{size}`, `{hours}`, `{email}`) need `@key`
metadata in `app_en.arb`, like the existing `authRateLimited`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependencies, platform permissions, contract files, tokens and copy that every story
uses.

- [X] T001 Add `image_picker`, `file_picker` and `flutter_image_compress` (latest stable versions that support Flutter 3.44 / Dart 3.12) to `dependencies` in `pubspec.yaml`, alphabetically. Run `flutter pub get` and commit `pubspec.lock`. Note the app-size delta (`flutter build apk --analyze-size --target-platform android-arm64 --flavor staging -t lib/main_staging.dart`) in the PR description (Constitution VII).
- [X] T002 [P] Add `NSCameraUsageDescription` («OnAir بيستخدم الكاميرا عشان تصوّر مرفقات لحالة الدعم») and `NSPhotoLibraryUsageDescription` («OnAir بيستخدم الصور عشان ترفق صور لحالة الدعم») to `ios/Runner/Info.plist`, with English in `ios/Runner/en.lproj/InfoPlist.strings` (create it if missing). Add no Android storage permission (the system photo picker needs none).
- [X] T003 [P] Update `contracts/node-api.openapi.yaml`:
  - add `support_draft` to the `entity_type` enum of `/v1/uploads/sign`;
  - add `POST /v1/account/password`, `operationId: changePassword`, exactly as in `specs/006-guest-support-account/contracts/node-account.md` U8.

  Then run `dart run swagger_parser` and `dart run build_runner build --delete-conflicting-outputs`. Verify that `lib/core/api/generated/models/entity_type.dart` has `supportDraft('support_draft')` and that `rest_client.dart` has `changePassword`.
- [X] T004 [P] Add the G4 rows to `contracts/error-codes.md` (code, phase `G4`, l10n key, Arabic copy, show-reference = no) for every "New error codes" value in the Reference table. Also note `details.blockers` on `ACCOUNT_HAS_ACTIVE_BOOKINGS`.
- [X] T005 [P] Add every key from "Localization keys" to `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`, with placeholder metadata, and run `flutter gen-l10n`.
- [X] T006 [P] Add the Settings Icons tones to `lib/design_system/tokens/on_air_colors.dart` as `settingsIconBlueBg/Fg`, `settingsIconTealBg/Fg`, `settingsIconOrangeBg/Fg`, `settingsIconNeutralBg/Fg` and `settingsIconDangerBg/Fg`. Use the light and dark values from `docs/UI_UX_DESIGN_SYSTEM.md` §«Settings Icons» exactly (Blue `#D6EBF7/#006399` · dark `#1E3A5F/#81D4FA`; Teal `#D1F0EA/#00796B` · `#1A3D38/#80CBC4`; Orange `#FFE8CC/#E65100` · `#3D2E1B/#FFB74D`; Neutral `#E8E8E8/#6B7280` · `#2A3340/#B0BEC5`; Danger `#FDECEA/#C62828` · `#3D1B1F/#EF9A9A`), including in `copyWith`/`lerp`. Extend `test/design_system/` token tests to assert them.

**Checkpoint**: `flutter analyze` is clean, `flutter gen-l10n` succeeds, and the generated client compiles.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Errors, config, the file pipeline, app settings, the shared components and the route constants. ⚠️ No story starts before this phase is green.

### Tests first (Phase 2)

- [X] T007 [P] Extend `test/core/errors/error_mapper_test.dart`: each new code (`CASE_CLOSED`, `ATTACHMENT_REJECTED`, `SESSION_REVOKED`, `SESSION_IS_CURRENT`, `PASSWORD_INCORRECT`, `PASSWORD_WEAK`) maps to its `ErrorCode` and l10n key (data-model §9). `details` is kept, and `ATTACHMENT_REJECTED` exposes `details['reason']`.
- [X] T008 [P] Extend the `AppConfig` parsing test (`test/core/config/app_config_test.dart`, create if missing):
  - parse `support_hours_ar/en`, `guest_terms_url_ar/en`, `privacy_url_ar/en`, `upload_limits` and `english_enabled`;
  - missing `upload_limits` → `image_mb: 10, pdf_mb: 15, max_files: 5`;
  - missing `english_enabled` → `true`;
  - empty `support_phone` → `supportContact.phone == null`.
- [X] T009 [P] Write `test/core/files/image_sanitizer_test.dart` with a fake compressor port. It must assert:
  - the request is JPEG, quality 80, `minWidth/minHeight` that keep the longest side ≤ 2048, `keepExif: false`;
  - the output goes to the temp dir;
  - an error → `AttachmentPrepareFailure`;
  - a PDF passes through unchanged.
- [X] T010 [P] Write `test/core/files/private_file_uploader_test.dart` (fake signer + fake PUT client, `fake_async`). It must assert:
  - preparing → uploading(progress) → uploaded(attachmentId);
  - sign returns `ATTACHMENT_REJECTED too_large` → failed(tooLarge) and no PUT;
  - a PUT network error → failed(network), and retry signs again;
  - cancel aborts the PUT and deletes the temp file;
  - the temp file is deleted after success;
  - the sign request uses `entity_type: support_draft` and `entity_id: <draftId>`.
- [X] T011 [P] Write `test/core/files/upload_limits_test.dart`:
  - type allowed: image or pdf only;
  - size checked **after** sanitizing against `image_mb`/`pdf_mb` × 1024²;
  - count check: the 6th file with `max_files: 5` → `tooMany`.
- [X] T012 [P] Write `test/app/settings/app_settings_cubit_test.dart` (in-memory `SharedPreferences.setMockInitialValues`):
  - the defaults are `ar` + `system`;
  - a change persists to `localeCode`/`themeMode` and survives a new cubit instance;
  - `en` is refused when `englishEnabled == false`;
  - when signed in, a language change calls the profile-locale sync once, and a failure sets `pendingLocaleSync` that is retried on `start()`.
- [X] T013 [P] Extend `test/app/router/routes_test.dart` (or the existing routes test found with `grep -rl requiresAccount test/`):
  - `/support`, `/account/security`, `/account/security/password`, `/account/notifications` and `/account/delete` require an account;
  - `/support/faq` does **not**;
  - `/support/<uuid v4>` requires an account and is linkable;
  - `/support/new` and `/support/faq` never match `_supportCase`.
- [X] T014 [P] Extend `test/app/router/notification_router_test.dart`:
  - `support.staff_replied` and `support.case_resolved` with a UUID `entityId` → `/support/<id>`;
  - a non-UUID `entityId` → `/support`;
  - `account.password_changed` → `/account/security`;
  - `account.phone_changed` → `/account`.

### Implementation (Phase 2)

- [X] T015 Add `caseClosed`, `attachmentRejected`, `sessionRevoked`, `sessionIsCurrent`, `passwordIncorrect` and `passwordWeak` to `ErrorCode` in `lib/core/errors/api_error.dart`, and map them in `lib/core/errors/error_mapper.dart` (keys from data-model §9: `supportCaseClosed`, `supportAttachmentRejected*` by reason, `errorUnauthenticated`, `accountSessionIsCurrent`, `accountPasswordIncorrect`, `authPasswordRule`). Makes T007 pass.
- [X] T016 Extend `AppConfig` in `lib/core/config/app_config.dart`:
  - `SupportContact supportContact` (phone, `hoursAr`, `hoursEn`);
  - `LegalLinks legal` (`termsUrl`/`privacyUrl` per locale);
  - `UploadLimits uploadLimits`;
  - `bool englishEnabled`.

  Parse the keys of contracts U10 with the defaults above, and update `MockBackend.appConfig` in `lib/core/config/mock_backend.dart`:
  - phone `+201000000000`;
  - hours «يوميًا 9ص–9م» / "Daily 9am–9pm";
  - placeholder `https://example.invalid/terms` URLs;
  - the default limits;
  - English enabled.

  Makes T008 pass.
- [X] T017 [P] Create `lib/core/files/upload_limits.dart`: `UploadLimits`, `AttachmentKind { image, pdf }`, and `AttachmentCheck validate({kind, sizeBytes, currentCount})` returning `ok | tooLarge(maxMb) | typeNotAllowed | tooMany(max)`. Makes T011 pass.
- [X] T018 [P] Create `lib/core/files/attachment_picker.dart`: the `AttachmentPicker` interface with `pickCamera()`, `pickGallery({int max})` and `pickPdf()`, each returning `List<PickedFile{path, name, sizeBytes, mime}>` (`[]` on cancel). Implement `PluginAttachmentPicker` with `image_picker` (`ImageSource.camera`/`pickMultiImage(limit:)`) and `file_picker` (`FileType.custom`, `allowedExtensions: ['pdf']`, `withData: false`). Add `FakeAttachmentPicker` in `test/helpers/`.
- [X] T019 [P] Create `lib/core/files/image_sanitizer.dart`: `ImageSanitizer.prepare(PickedFile) → PreparedFile{tempPath, sizeBytes, mime:'image/jpeg'|'application/pdf', width?, height?}` using `FlutterImageCompress.compressAndGetFile` with the values from the Reference table. PDFs are copied as-is (a size check only). Put the plugin call behind a small `CompressorPort` so tests use a fake. Makes T009 pass.
- [X] T020 Create `lib/core/files/private_file_uploader.dart`:
  - `PrivateFileUploader.upload(PreparedFile, {required String draftId, CancelToken?}) → Stream<UploadProgress>`;
  - steps: generated `signUpload` (`support_draft`, draftId, mime, size), then a raw `Dio().put(uploadUrl, data: file stream, headers: {Content-Type: mime, Content-Length: size})` with **no auth header**, emitting progress, then `uploaded(attachmentId)`;
  - map server errors through `ErrorMapper`;
  - always delete `tempPath` at the end (success, failure after the final retry is abandoned, or cancel).

  Makes T010 pass.
- [X] T021 Move `lib/features/stay/presentation/claims/evidence_url_cache.dart` to `lib/core/files/file_url_cache.dart` (rename the class to `FileUrlCache`, memory only, refresh < 30 s to expiry or after 403), update its G3 imports and tests (`grep -rl EvidenceUrlCache lib test`), and keep the G3 behaviour unchanged.
- [X] T022 Create `lib/app/settings/app_settings_store.dart` (read/write `localeCode`/`themeMode`) and `lib/app/settings/app_settings_cubit.dart` (`AppSettings{locale, themeMode, englishEnabled, pendingLocaleSync}`; `setLocale`, `setThemeMode`; an injected `Future<void> Function(String locale)? syncProfileLocale`). Then:
  - provide the cubit above `MaterialApp.router` in `lib/app/app.dart`;
  - replace the hard-coded `locale: const Locale('ar')` and `themeMode: ThemeMode.system` with the cubit state;
  - wire it in `lib/bootstrap.dart`.

  Makes T012 pass.
- [X] T023 [P] Create `lib/design_system/components/settings_row.dart` (`SettingsRow` + `SettingsGroup` + `SettingsIconTone {blue, teal, orange, neutral, danger}`) per contracts/ui-screens.md §1: 56 dp minimum height, a 40 dp tinted icon tile with radius 12, title/subtitle/trailing slots, a mirrored chevron, and `enabled`/`locked` variants with merged Semantics. Add `test/design_system/goldens/settings_row_golden_test.dart` (all tones, value/chevron/switch trailing, disabled, locked) in Light/Dark, RTL/LTR, 1.0/1.3.
- [X] T024 [P] Create `lib/design_system/components/message_bubble.dart`:
  - `MessageBubble(author, body, time, attachments, sendState)`;
  - guest bubbles are end-aligned in the primary container, OnAir bubbles start-aligned on surface with an «OnAir» label;
  - the time is in Cairo time via the shared formatter;
  - a sending/failed indicator with retry;
  - Semantics read «{author}، {time}: {body}».

  Golden test `test/design_system/goldens/message_bubble_golden_test.dart`.
- [X] T025 [P] Create `lib/design_system/components/attachment_tile.dart`:
  - `AttachmentTile` with the states preparing / uploading(progress) / failed(retry) / ready, in image-thumb or PDF variants;
  - a remove button with Semantics `supportAttachRemove`;
  - 72 dp in the composer, adaptive in the bubble grid;
  - the image builder is injected, so the screen supplies `FileUrlCache` images.

  Golden test `test/design_system/goldens/attachment_tile_golden_test.dart`.
- [X] T026 [P] Add `CaseStatusChip` to `lib/design_system/components/status_chip.dart`, with text + icon per status and tokens from contracts/ui-screens.md §1 (never color only). Extend the existing status chip golden test.
- [X] T027 Add the route constants from the Reference table to `lib/app/router/routes.dart`:
  - add the new paths to `requiresAccount`, and the static paths to the allowed set;
  - keep `/support/faq` public;
  - declare `/support/faq` and `/support/new` before `/support/:caseId` in `lib/app/router/app_router.dart` (temporarily building `NotAvailableScreen` for the new paths until each story wires its screen).

  Makes T013 pass.
- [X] T028 Update `lib/app/router/notification_router.dart`: `support.*` → `AppRoutes.supportCase(entityId)` when it is a UUID v4, else `AppRoutes.support`; `account.password_changed` → `accountSecurity`; other `account.*` → `account`. Add the `AppRoutes.supportCase(String id)` builder. Makes T014 pass.

**Checkpoint**: all Phase 2 tests pass, the app runs unchanged in mock mode, and the components' goldens are approved.

---

## Phase 3: User Story 1 — Follow and reply to my support cases (Priority: P1) 🎯 MVP

**Goal**: A signed-in guest sees «حالاتي» (open first), opens a case, reads only guest-visible messages, replies with attachments, and sees OnAir replies live. A reply on «اتحلّت» reopens the case; «مقفولة» refuses replies.

**Independent Test**: In mock mode with the seeded cases (one `waiting_user`, one `resolved`, one `closed`): check the order and statuses, reply with one photo on the waiting case, get a mock staff reply within 5 s, reply on the resolved case → «مفتوحة», and see the closed case offer «افتح حالة جديدة».

### Tests for US1

- [ ] T029 [P] [US1] Write `test/features/support/domain/support_case_test.dart`:
  - `SupportCase.fromJson` maps every field of the contracts U1 list item;
  - `CaseType`/`CaseStatus` unknown values → `unknown(raw)`;
  - `isOpen` is true only for `open|in_progress|waiting_user`;
  - `isReplyable` is false only for `closed`;
  - the list order is open first, then `lastActivityAt` descending;
  - `CaseMessage` maps `author: guest|onair` and attachments (`kind image|pdf`, size, width/height).
- [ ] T030 [P] [US1] Write `test/features/support/data/mock_support_server_test.dart`. It must assert:
  - the seeds (3 cases + 1 system `damage_dispute` case);
  - `list` paginates 20 per page with a cursor;
  - `get` on a foreign or unknown id → `NOT_FOUND`;
  - internal notes in the seed are never returned;
  - `reply` with the same `draftId` twice → one message;
  - a reply on `resolved` → status `open`;
  - a reply on `closed` → `CASE_CLOSED`;
  - a reply on `waiting_user` → `in_progress`;
  - a body outside 1–4000 → `VALIDATION_FAILED`;
  - a staff auto-reply is scheduled 3 s after a guest message (`fake_async`) and emits a change signal.
- [ ] T031 [P] [US1] Write `test/features/support/data/supabase_support_repository_test.dart` with a fake `rpc(fn, params)`:
  - exact function names and parameter names from the Reference table (`p_case_id`, `p_draft_id`, `p_attachment_ids`, `p_body`, `p_cursor`, `p_limit`, `p_before_cursor`);
  - response mapping;
  - errors go through `ErrorMapper`.
- [ ] T032 [P] [US1] Write `test/features/support/presentation/support_home_cubit_test.dart` (`bloc_test`):
  - loading → ready(cases, hasMore);
  - empty;
  - error with a reference;
  - offline keeps the last list and sets `offline: true`;
  - `loadMore` appends and stops at a `null` cursor;
  - a refresh on the `support.staff_replied` notification signal re-reads once.
- [ ] T033 [P] [US1] Write `test/features/support/presentation/case_details_cubit_test.dart` (`bloc_test` + `fake_async` + a controllable live channel):
  - load → ready, messages ascending;
  - a channel event → exactly one re-read;
  - channel not subscribed → a 10 s poll, which stops once subscribed and on `close()`;
  - `send` with a body: an optimistic `sending` row, then `sent` with the server id, the draft cleared and a **new** `draftId`;
  - a double `send` → one repository call;
  - `CASE_CLOSED` → the state switches to closed and the typed text is kept;
  - a resolved case reply → the status from the response (`open`) is shown;
  - `NOT_FOUND` → notFound;
  - `send` is blocked while any attachment is not `uploaded`.
- [ ] T034 [P] [US1] Write `test/features/support/presentation/reply_composer_test.dart` (widget):
  - the send button is disabled when the trimmed body is empty or an upload is pending/failed, and while offline;
  - attach opens the 3-option sheet;
  - the limit hint uses `UploadLimits.maxFiles`;
  - the remove/retry Semantics labels exist;
  - the composer stays visible with the keyboard open.
- [ ] T035 [P] [US1] Write `test/features/support/presentation/support_home_screen_test.dart` and `case_details_screen_test.dart` (widget), covering skeleton / empty / error + reference / offline banner / success; the closed notice + «افتح حالة جديدة» navigating to `/support/new?booking=<id>`; the resolved notice above the composer; and the not-found view with «الرجوع للدعم».
- [ ] T036 [P] [US1] Write goldens `test/features/support/goldens/support_home_golden_test.dart` (empty, list open + finished, offline) and `case_details_golden_test.dart` (conversation with attachments, resolved, closed; keyboard open), using the matrix in contracts/ui-screens.md §5.

### Implementation for US1

- [ ] T037 [P] [US1] Create `lib/features/support/domain/support_case.dart` (`SupportCase`, `CaseType`, `CaseStatus` with `isOpen`/`isReplyable`, `CasePage`, `CaseDetails`, `CaseMessage`, `MessageAuthor`, `MessageSendState`, `AttachmentRef`) exactly per data-model §1–§2, including `CaseType.guestSelectable = [booking, payment, refund, propertyIssue, other]`. Makes T029 pass.
- [ ] T038 [P] [US1] Create `lib/features/support/domain/attachment_draft.dart` (`AttachmentDraft`, `AttachmentUploadState`) and `lib/features/support/domain/support_repository.dart` (interface: `listCases({cursor})`, `getCase(id, {beforeCursor})`, `createCase(NewCaseDraft)`, `reply(caseId, ReplyDraft)`, `listFaq()`, `Stream<void> caseChanges(caseId)` + `Stream<bool> liveConnected`).
- [ ] T039 [US1] Create `lib/features/support/data/mock_support_server.dart` with the seeds, rules and auto-reply from T030, plus the debug tools sheet `lib/features/support/presentation/mock_support_tools_sheet.dart` (long press on the case app bar, debug + mock only, with «رد من OnAir», «اتحلّت», «اتقفلت»). Makes T030 pass.
- [ ] T040 [US1] Create `lib/features/support/data/supabase_support_repository.dart` (RPCs from the Reference table) and `lib/features/support/data/case_live_channel.dart`:
  - a Supabase channel `support-case-<id>` with `postgres_changes` INSERT on `case_messages` (`case_id=eq.<id>`) and UPDATE on `support_cases` (`id=eq.<id>`);
  - it emits `void` only (the payload is never read) and reports the subscription status;
  - `dispose()` unsubscribes.

  Copy the structure of `lib/core/realtime/notification_signal.dart`, including a `Controllable*` fake. Makes T031 pass.
- [ ] T041 [US1] Wire `SupportRepository` in `lib/bootstrap.dart`: remote → `SupabaseSupportRepository(rpc, client)`, mock → `MockSupportServer`. Also provide `PrivateFileUploader`, `ImageSanitizer`, `AttachmentPicker` and `FileUrlCache` as `RepositoryProvider`s.
- [ ] T042 [US1] Create `lib/features/support/presentation/home/support_home_cubit.dart` and `support_home_screen.dart`:
  - the FAQ Hero gradient header with «حالة جديدة» / «الأسئلة الشائعة» pills (the FAQ pill navigates to `AppRoutes.supportFaq`, which is wired in US3);
  - the sliver list of case cards (code, type label, `CaseStatusChip`, linked booking line, «آخر تحديث {relative}», unread dot), with the «حالات منتهية» divider before the first non-open case;
  - empty and offline states, pull-to-refresh, pagination.

  Makes T032 and T035 (home) pass.
- [ ] T043 [US1] Create `lib/features/support/presentation/widgets/attachment_strip.dart` (a horizontal list of `AttachmentTile` + «إضافة» tile; uses `AttachmentPicker` → `ImageSanitizer` → `UploadLimits.validate` → `PrivateFileUploader`; shows rejections with `supportAttachmentRejected*`) and `reply_composer.dart` (a text field, attach, a send icon button of 48 dp with Semantics `supportSend`, `RapidSubmitGuard`). Makes T034 pass.
- [ ] T044 [US1] Create `lib/features/support/presentation/case/case_details_cubit.dart` and `case_details_screen.dart`:
  - the app bar with code + `CaseStatusChip`;
  - a collapsible info card (the linked booking taps to `/bookings/:id`);
  - `MessageBubble` list with older pages on scroll-up;
  - the composer; the closed and resolved notices; the not-found view;
  - opening the live channel on enter and closing it on dispose; the 10 s fallback poll.

  Makes T033, T035 (details) and T036 pass.
- [ ] T045 [US1] Wire `/support` → `SupportHomeScreen` and `/support/:caseId` → `CaseDetailsScreen` (validate UUID v4, else `NotAvailableScreen`) in `lib/app/router/app_router.dart`, pushed on the root navigator.
- [ ] T046 [US1] Add a «الدعم» entry to the current account screen (`lib/features/account/presentation/account_placeholder_screen.dart`; US5 replaces the whole screen later). In `lib/features/stay/presentation/claims/damage_claim_screen.dart`, make the «رقم الحالة» text tappable to `/support/<support_case_id>` when the claim JSON has `support_case_id` (add the field to `DamageClaim` in `lib/features/stay/domain/damage_claim.dart`, nullable).
- [ ] T047 [US1] Security test `test/features/support/security/case_isolation_test.dart` (mock): a deep link to another guest's case id and to `/support/not-a-uuid` both show the neutral not-found view, make no extra calls, and reveal no case data. Add a Staging variant `integration_test/support_isolation_staging_test.dart` (skipped unless `BACKEND_MODE=remote`) that also asserts no `internal` message body appears.

**Checkpoint**: US1 works end-to-end in mock mode. Notifications open the case.

---

## Phase 4: User Story 2 — Open a new support case (Priority: P1)

**Goal**: The guest picks a type, optionally links a booking or apartment, writes ≥ 10 characters, attaches up to 5 files, and sends exactly once. Entry from a booking or apartment pre-links it.

**Independent Test**: From booking details «تواصل مع OnAir», confirm the booking chip and type «حجز», add 2 photos, send twice quickly → one case at the top of «حالاتي» with the booking linked.

### Tests for US2

- [ ] T048 [P] [US2] Extend `test/features/support/data/mock_support_server_test.dart` for create:
  - the type must be in `guestSelectable`, else `VALIDATION_FAILED`;
  - the description is "trimmed, **10–4000** characters";
  - the same `draftId` twice → the same `case_id`/`code`;
  - attachments must belong to the draft, and > `max_files` → `ATTACHMENT_REJECTED too_many`;
  - a foreign `bookingId` → `NOT_FOUND`;
  - the new case is listed first.
- [ ] T049 [P] [US2] Write `test/features/support/presentation/new_case_cubit_test.dart`:
  - the initial state from `?booking=<uuid>` → booking linked + type `booking`;
  - `?property=<uuid>` → property linked + type `other`;
  - an invalid uuid param is ignored;
  - `canSend` follows data-model §3 exactly;
  - the `draftId` is a v4 UUID created once per form, and a network-failure retry reuses it;
  - a double submit → one call;
  - success → `created(caseId, code)`;
  - `hasContent` drives the discard prompt.
- [ ] T050 [P] [US2] Write `test/features/support/presentation/new_case_screen_test.dart` (widget):
  - the type chips are required;
  - the counter shows `n/4000` and «اكتب 10 حروف على الأقل»;
  - the linked chip is removable;
  - «اربط بحجز» lists the guest's bookings (code + dates) from the existing bookings repository;
  - back with content → the discard sheet;
  - offline → send disabled with the banner;
  - success → replaced by `/support/<id>` with the `supportCreated` snackbar.
- [ ] T051 [P] [US2] Golden `test/features/support/goldens/new_case_golden_test.dart`: prefilled booking, uploading + failed tiles, ready; keyboard open; full matrix.

### Implementation for US2

- [ ] T052 [US2] Implement `createCase` in `lib/features/support/data/mock_support_server.dart` and `supabase_support_repository.dart` (`common_create_support_case` with `p_type, p_body, p_draft_id, p_booking_id, p_property_id, p_attachment_ids`). Makes T048 pass.
- [ ] T053 [US2] Create `lib/features/support/presentation/new_case/new_case_cubit.dart` (`NewCaseDraft` per data-model §3) and `new_case_screen.dart`:
  - type chips; the linked booking/property chip;
  - the «اربط بحجز» bottom sheet using `BookingsRepository` (only the guest's own bookings, code + dates);
  - a multiline `OnAirTextField` with a counter;
  - `AttachmentStrip`;
  - `BottomActionBar` «إرسال» with `RapidSubmitGuard`;
  - `PopScope` discard confirmation via `OnAirConfirmSheet`.

  Makes T049–T051 pass.
- [ ] T054 [US2] Wire `/support/new` → `NewCaseScreen` in `lib/app/router/app_router.dart` (query `booking`, `property` and `type`, UUID-validated), delete `lib/features/support/presentation/support_entry_placeholder_screen.dart` and `test/features/support/support_entry_placeholder_test.dart`, and confirm the booking details, `contact_support` action and property entry points still build the same URLs (`booking_action_ui.dart`, `booking_details_screen.dart`, `property_screen.dart`).
- [ ] T055 [US2] Write `integration_test/support_case_mock_test.dart`:
  - booking details → «تواصل مع OnAir» → 2 photos (`FakeAttachmentPicker`) → double-tap send → one case;
  - the staff reply arrives (mock auto-reply) → mark resolved via the tools → reply → status «مفتوحة»;
  - mark closed → «افتح حالة جديدة» pre-links the booking.

**Checkpoint**: US1 + US2 make the full basic support loop.

---

## Phase 5: User Story 3 — FAQ and calling support (Priority: P1)

**Goal**: The FAQ is public, searchable, localized and cached. The call button uses the published number and hours, and hides without them.

**Independent Test**: As a visitor, open «حسابي» → «الأسئلة الشائعة», search, expand, switch to English, go offline and reopen (cached + banner), then tap the call button.

### Tests for US3

- [ ] T056 [P] [US3] Write `test/features/support/presentation/faq_cubit_test.dart`:
  - load → items sorted by `sortOrder`, localized by the current locale (`question_ar/answer_ar` or `_en`);
  - the result is written to the cache;
  - offline + cache → items + `stale: true`;
  - offline without cache → the offline error;
  - search normalizes Arabic (أ/إ/آ→ا, ة→ه, ى→ي, diacritics removed), is case-insensitive over question + answer, and empty results → `noResults`.
- [ ] T057 [P] [US3] Write `test/features/support/presentation/call_support_button_test.dart`:
  - hidden when `supportContact.phone == null`;
  - shows the hours line when present;
  - a tap launches `tel:<E.164>`;
  - when `canLaunchUrl` is false → a sheet with the number and a copy action (snackbar `supportCallCopied`);
  - the Semantics label is `supportCall`.
- [ ] T058 [P] [US3] Write `test/features/support/presentation/faq_screen_test.dart` (widget: skeleton, list, no results with «افتح حالة جديدة» routing a visitor to login with a return path, stale banner, error) and golden `test/features/support/goldens/faq_golden_test.dart`.

### Implementation for US3

- [ ] T059 [P] [US3] Create `lib/features/support/domain/faq_item.dart` and `lib/features/support/data/faq_cache.dart`:
  - a `JsonFileCache.appSupport(name: 'faq_v1')` cache;
  - public data, so it is **not** cleared on sign-out: add nothing to `CacheCleaner`.

  Implement `listFaq()` (`common_list_faq('guest')`, callable by anon) in both repositories, with 6 seeded Q&As in Arabic and English in the mock.
- [ ] T060 [US3] Create `lib/features/support/presentation/faq/faq_cubit.dart` and `faq_screen.dart` (FAQ Hero header with a search field, expandable cards, stale banner, call button at the bottom). Wire `/support/faq` → `FaqScreen` as a **public** route. Makes T056 and T058 pass.
- [ ] T061 [P] [US3] Create `lib/features/support/presentation/widgets/call_support_button.dart` reading `AppConfig.supportContact`. Use it in `SupportHomeScreen`, `FaqScreen` and `lib/features/account/presentation/account_suspended_screen.dart` (also add a «الأسئلة الشائعة» link there). Makes T057 pass.
- [ ] T062 [US3] In the S005 WhatsApp code step (`lib/features/auth/phone_verification/presentation/widgets/whatsapp_code_step.dart`), point «كلّم الدعم» to `/support/faq` for `incomplete` accounts (the call button is on that screen), instead of `/support/new` (contracts/app-routes.md). Update its widget test.

**Checkpoint**: The FAQ and the call button work for visitors and suspended accounts.

---

## Phase 6: User Story 4 — Delete my account (Priority: P1)

**Goal**: Explanation → server blocker check → email code → immediate deletion → visitor home. Blocked deletion shows the reasons with links.

**Independent Test**: The mock account with an active booking is blocked with the booking listed. A normal mock account: wrong code → error, then `123456` → «حسابك اتحذف» and the app is a visitor.

### Tests for US4

- [ ] T063 [P] [US4] Write `test/features/account/domain/deletion_test.dart`: `DeletionBlocker.fromDetails` parses `details.blockers` (`kind booking|refund|damage_claim`, `id`, `code`); an unknown kind is kept as `other` and still listed; empty or missing blockers → an empty list.
- [ ] T064 [P] [US4] Write `test/features/account/data/mock_account_server_test.dart` (deletion part):
  - `blocked@onair.test` → `ACCOUNT_HAS_ACTIVE_BOOKINGS` with one booking blocker;
  - otherwise → `challengeId` + `maskedEmail`;
  - confirm with a wrong code → `OTP_INVALID`;
  - with `123456` → deleted;
  - a blocker added between request and confirm → `ACCOUNT_HAS_ACTIVE_BOOKINGS` at confirm.
- [ ] T065 [P] [US4] Write `test/features/account/presentation/delete_account_cubit_test.dart`:
  - explain → checking → blocked | codeStep(challengeId, maskedEmail, SendWindow from `/v1/otp/send`);
  - double tap on «احذف حسابي» → one request and one send;
  - `OTP_INVALID`/`OTP_EXPIRED`/`OTP_ATTEMPTS_EXCEEDED`/`RATE_LIMITED` map to the existing email-code messages;
  - confirm success → calls `SignOutService.signOut()` once (even if server sign-out throws) → `deleted`.
- [ ] T066 [P] [US4] Write `test/features/account/presentation/delete_account_screen_test.dart` (widget):
  - the 3 bullets;
  - «احذف حسابي» disabled until «فاهم إن الحذف نهائي» is checked;
  - the blocked view lists blockers that tap to `/bookings/<id>`, plus «كلّم الدعم» → `/support`;
  - the code step uses `OnAirOtpField` + `CountdownText`;
  - offline disables the buttons.

  Golden `test/features/account/goldens/delete_account_golden_test.dart` (explain, blocked, code step; full matrix).
- [ ] T067 [P] [US4] Write `integration_test/delete_account_mock_test.dart`: the blocked account → the blocked view; a normal account → code → visitor home with the `deleteDone` snackbar shown once (not again after a restart); `/bookings` now asks for sign-in.

### Implementation for US4

- [ ] T068 [P] [US4] Create `lib/features/account/domain/account_repository.dart`, the interface that grows in later stories: `requestDeletion() → DeletionRequest{challengeId, maskedEmail}`, `sendDeletionCode(challengeId) → SendWindow`, `confirmDeletion(challengeId, code)`. Also create `lib/features/account/domain/deletion.dart` (`DeletionBlocker`, `DeletionBlockedException(blockers)`). Makes T063 pass.
- [ ] T069 [US4] Create `lib/features/account/data/mock_account_server.dart` (deletion rules from T064) and `lib/features/account/data/supabase_account_repository.dart`:
  - `common_request_account_deletion()`;
  - Node `/v1/otp/send` through the generated client, the same way the cash code is sent in `lib/features/stay/data/supabase_stay_repository.dart` `sendCashCode`;
  - `common_confirm_account_deletion(p_challenge_id, p_code)`.

  Wire both in `lib/bootstrap.dart`. Makes T064 pass.
- [ ] T070 [US4] Create `lib/features/account/presentation/delete/delete_account_cubit.dart` and `delete_account_screen.dart` per contracts/ui-screens.md «Delete account»:
  - reuse `OnAirOtpField`, `CountdownText` and the `SendWindow` rendering from S005/G3;
  - after success: `context.go(AppRoutes.home, extra: const AccountDeletedNotice())`, and show the snackbar once from the home screen when that extra is present.

  Makes T065 and T066 pass.
- [ ] T071 [US4] Wire `/account/delete` → `DeleteAccountScreen` in `lib/app/router/app_router.dart`. Add a temporary «حذف الحساب» Danger row to the current account screen (US5 replaces it). Make sure `SignOutService` tolerates a failed server sign-out after deletion and still clears the session, the device token record, caches and personal Cubits (`lib/features/account_gate/application/sign_out_service.dart`); add a unit test for that path.

**Checkpoint**: Store-required deletion works in mock mode. MVP (US1–US4) is complete.

---

## Phase 7: User Story 5 — Profile, language, appearance, legal and sign-out (Priority: P2)

**Goal**: The full «حسابي» screen: profile header with initials, edit name, settings rows, language and appearance sheets, legal links, sign-out, and the visitor variant.

**Independent Test**: Change the name, switch to English + dark, restart → all persist and the initials follow the name; open the terms and privacy pages; sign out → visitor rows only.

### Tests for US5

- [ ] T072 [P] [US5] Extend `test/features/account/data/mock_account_server_test.dart` + a supabase repository test for `updateProfile({fullName, locale})` → `common_update_profile(p_full_name, p_locale)`:
  - a null parameter is omitted from the update;
  - the name is "trimmed, **2–80** characters" else `VALIDATION_FAILED`;
  - the locale is `ar|en`.
- [ ] T073 [P] [US5] Write `test/features/account/presentation/account_screen_test.dart` (widget, replacing `account_placeholder_test.dart`):
  - email user: all rows; the S005 phone row with «متأكد»/«تغيير»;
  - Google user: the sign-in method shows Google;
  - visitor: the sign-in card + language, appearance, FAQ, terms, privacy only (FR-028);
  - the support row's unread dot follows `SupportHomeCubit`/a repository flag;
  - the call row is hidden without a number;
  - sign-out asks for confirmation, then calls `SignOutService.signOut()` once;
  - terms/privacy open the locale URL in the in-app browser (`LaunchMode.inAppBrowserView`).
- [ ] T074 [P] [US5] Write `test/features/account/presentation/edit_name_sheet_test.dart`:
  - live validation of 2–80 characters after trim (`accountNameInvalid`);
  - save disabled while invalid or saving;
  - a double tap → one call;
  - success updates the header and initials;
  - the sheet stays above the keyboard.

  And `settings_sheets_test.dart`:
  - language and appearance radios apply immediately through `AppSettingsCubit`;
  - English is hidden when `englishEnabled == false`.
- [ ] T075 [P] [US5] Golden `test/features/account/goldens/account_screen_golden_test.dart` (email user, Google user, visitor) and `edit_name_sheet_golden_test.dart` (valid, too short; keyboard open), full matrix.

### Implementation for US5

- [ ] T076 [US5] Add `updateProfile({String? fullName, String? locale})` to `AccountRepository`, implemented in the mock and the Supabase repository (`common_update_profile`). After a name change, refresh `AuthCubit` (`refreshAccount()` from S005) so `GuestAccount.fullName` updates everywhere. Add `GuestAccount.initials` (the first letters of the first two name words, upper-cased for Latin). Makes T072 pass.
- [ ] T077 [US5] Create `lib/features/account/presentation/account_screen.dart` (replacing `account_placeholder_screen.dart`; delete the placeholder and its test) per contracts/ui-screens.md «Account»:
  - the #12-style header;
  - `SettingsGroup`s «عام» / «الأمان» / «الدعم» / «قانوني», plus the Danger rows;
  - reuse the S005 sign-in method and phone row widgets (move them to `lib/features/account/presentation/widgets/` if they are private classes);
  - the visitor variant.

  Wire `/account` to it. Makes T073 pass.
- [ ] T078 [P] [US5] Create `lib/features/account/presentation/edit_name_sheet.dart` and `lib/features/account/presentation/settings_sheets.dart` (language and appearance radio sheets). Wire the `AppSettingsCubit.syncProfileLocale` callback to `AccountRepository.updateProfile(locale:)` when signed in (in `lib/bootstrap.dart`). Makes T074 and T075 pass.
- [ ] T079 [US5] Write `integration_test/account_settings_mock_test.dart` (part 1):
  - edit the name → the header changes;
  - switch to English → the UI is LTR;
  - dark mode;
  - restart the app (re-pump `App` with the same preferences) → all persist;
  - sign out → the visitor variant.

**Checkpoint**: The account screen is complete.

---

## Phase 8: User Story 6 — Security: password and active sessions (Priority: P2)

**Goal**: Password accounts change their password with the current one (other devices sign out). Everyone sees their sessions, can end one or all others, and an ended device signs out on its next app open or within 60 s.

**Independent Test**: The mock lists the current device + 2 others: end one, then end all others. Change the password with a wrong current one, then the right one. Simulate `SESSION_REVOKED` from the heartbeat → «انتهت الجلسة» and sign-in with the return path.

### Tests for US6

- [ ] T080 [P] [US6] Write `test/features/account/domain/active_session_test.dart`: parse the contracts U6 item; `platform` unknown → `unknown`; an empty `device_label` → the `accountUnknownDevice` fallback flag; ordering puts the current one first, then `lastActiveAt` descending.
- [ ] T081 [P] [US6] Extend `test/features/account/data/mock_account_server_test.dart`:
  - `listSessions` → 3 sessions with one current;
  - `endSession(current)` → `SESSION_IS_CURRENT`;
  - `endSession(other)` removes it;
  - `endOtherSessions()` leaves only the current one;
  - `changePassword`: a social account → `ACTION_NOT_ALLOWED`; a wrong current → `PASSWORD_INCORRECT`; the 6th wrong attempt within 15 min → `RATE_LIMITED` with `retry_at`; a weak new password → `PASSWORD_WEAK`; success ends the other sessions.
- [ ] T082 [P] [US6] Write `test/features/account/presentation/security_cubit_test.dart`:
  - loading → ready(sessions);
  - ending one marks it `ending`, then removes it after the server confirms (and reverts with an error on failure);
  - end-all-others shows `endingAll` and leaves only the current one;
  - double taps → one call each.
- [ ] T083 [P] [US6] Write `test/features/account/presentation/change_password_cubit_test.dart`:
  - the rules are "≥ 8 characters, at least one letter and one digit, new ≠ current", and confirm must match;
  - errors map to fields (`PASSWORD_INCORRECT` → the current field; `RATE_LIMITED` → a countdown notice);
  - success → `done`, and the fields are cleared;
  - `close()` clears the passwords.
- [ ] T084 [P] [US6] Write `test/core/session/session_heartbeat_test.dart` (`fake_async`, fake lifecycle):
  - it calls `common_heartbeat` on resume and every 60 s while resumed, and stops when paused;
  - `SESSION_REVOKED` or `UNAUTHENTICATED` → exactly one call to the existing safe sign-out with the «انتهت الجلسة» message and the current location as the return path;
  - other errors are ignored;
  - it does not run for visitors.
- [ ] T085 [P] [US6] Write `test/core/network/user_agent_test.dart`: the builder returns `OnAirGuest/<version> (<android|ios> <os version>; <model>)` from the `package_info_plus` / platform fakes, and it is set on the Dio factory and the Supabase client headers.
- [ ] T086 [P] [US6] Write `test/features/account/presentation/security_screen_test.dart` and `change_password_screen_test.dart` (widget):
  - the password row is shown only when `hasPassword`;
  - the current device has the «الجهاز ده» chip and no end action;
  - the all-others button is hidden when only one session exists and confirms via a sheet;
  - offline disables actions;
  - success snackbar `accountPasswordChanged`;
  - `/account/security/password` redirects to `/account/security` when `!hasPassword`.

  Goldens `test/features/account/goldens/security_golden_test.dart` (with password + 3 sessions, social, ending one) and `change_password_golden_test.dart` (empty, rule met, incorrect current; keyboard open).

### Implementation for US6

- [ ] T087 [P] [US6] Create `lib/features/account/domain/active_session.dart` (data-model §5). Add `listSessions()`, `endSession(id)`, `endOtherSessions()` and `changePassword({current, next})` to `AccountRepository`; implement them in the mock (T081 rules) and the Supabase repository (the RPCs `common_list_my_sessions`, `common_end_session(p_session_id)`, `common_end_other_sessions`; the generated `changePassword` Node call). Makes T080 and T081 pass.
- [ ] T088 [US6] Create `lib/core/session/session_heartbeat.dart` (a `WidgetsBindingObserver`, 60 s `Timer.periodic` only while resumed and signed in; calls an injected `heartbeat()`; on `SESSION_REVOKED`/`UNAUTHENTICATED` triggers the existing session-expired sign-out in `lib/features/account_gate/presentation/session_listener.dart`). Add `heartbeat()` to the auth/profile data source (`common_heartbeat()`; the mock can be told to revoke). Start it from `lib/bootstrap.dart`. Makes T084 pass.
- [ ] T089 [P] [US6] Create `lib/core/network/user_agent.dart` and set the header in `lib/core/network/dio_factory.dart` and in the `Supabase.initialize(headers: …)` call in `lib/bootstrap.dart`. Makes T085 pass.
- [ ] T090 [US6] Create `lib/features/account/presentation/security/security_cubit.dart`, `security_screen.dart`, `change_password_cubit.dart` and `change_password_screen.dart` per contracts/ui-screens.md (reuse the registration strength meter and the `authPasswordRule` line). Wire `/account/security` and `/account/security/password` (with the `hasPassword` redirect), and link the «الأمان والأجهزة» row from the account screen. Makes T082, T083 and T086 pass.
- [ ] T091 [US6] Extend `integration_test/account_settings_mock_test.dart` (part 2):
  - end one session, then all others;
  - change the password with a wrong then the right current one → the success snackbar;
  - a mock revoke on the next heartbeat → «انتهت الجلسة» → sign in again → back on `/account/security`.

**Checkpoint**: Security and session control work, and revoked devices sign out.

---

## Phase 9: User Story 7 — Notification preferences (Priority: P3)

**Goal**: Category × channel switches from the server catalog, with locked mandatory rows, optimistic saves that revert on failure, and a device-blocked banner.

**Independent Test**: Turn off push for «الدعم» in mock mode; a mock staff reply creates an in-app notification but no push banner. Booking rows are locked. A failed save reverts.

### Tests for US7

- [ ] T092 [P] [US7] Write `test/features/account/domain/notification_preference_test.dart`: parse the contracts U9 catalog; an unknown category → `labelKey = notifCategoryUnknown`; `in_app` is never present; a mandatory category has all channels enabled.
- [ ] T093 [P] [US7] Write `test/features/account/presentation/preferences_cubit_test.dart`:
  - load → ready;
  - a toggle is optimistic (`saving: true`) → confirmed;
  - a failure → reverted + an error event with retry;
  - toggling a mandatory category is a no-op and never calls the repository;
  - rapid toggles on the same switch send only the final value after the in-flight call;
  - `deviceNotificationsBlocked` comes from `PushPermissionCoordinator`.
- [ ] T094 [P] [US7] Write `test/features/account/presentation/preferences_screen_test.dart` (widget):
  - locked rows show the lock icon, a disabled switch and `prefsMandatory`, with Semantics «إلزامي»;
  - the blocked banner's «افتح الإعدادات» calls `AppSettings.openAppSettings(type: AppSettingsType.notification)`;
  - offline disables the switches.

  Golden `test/features/account/goldens/preferences_golden_test.dart` (mixed with locked rows, blocked banner).

### Implementation for US7

- [ ] T095 [P] [US7] Create `lib/features/account/domain/notification_preference.dart` (data-model §7). Add `getPreferences()`/`setPreference(category, channel, enabled)` to `AccountRepository`:
  - the Supabase implementation calls `common_get_notification_preferences()` and `common_set_notification_preferences(p_items: [{category, channel, enabled}])`;
  - the mock seeds `booking` (mandatory), `payment` (mandatory), `support`, `reminders`, `review` and `account` (mandatory), and suppresses the mock push for disabled categories.

  Add the `notifCategory<Key>` l10n keys for these seeds. Makes T092 pass.
- [ ] T096 [US7] Create `lib/features/account/presentation/notifications/preferences_cubit.dart` and `preferences_screen.dart`, wire `/account/notifications`, and link the «الإشعارات» row. Makes T093 and T094 pass.
- [ ] T097 [US7] Extend `integration_test/account_settings_mock_test.dart` (part 3): turn off push for `support` → a mock staff reply → the in-app notification appears and no push banner; the booking row cannot change.

**Checkpoint**: All seven stories work independently in mock mode.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [ ] T098 [P] Extend `test/features/stay/logging_rules_test.dart`'s approach in a new `test/features/support/logging_rules_test.dart`: grep-based assertions that `lib/features/support/**`, `lib/features/account/**` and `lib/core/files/**` never pass `body`, `fullName`, `email`, `password`, `uploadUrl`/`url` or file `name` to `AppLogger`/`CrashReporter`.
- [ ] T099 [P] Write `test/core/files/no_disk_persistence_test.dart`: after upload success, failure and cancel, the temp dir has no leftover sanitized files. `FileUrlCache` has no disk backing. `SignOutService` clears the support and account cubits (`PersonalDataResetter` in `lib/features/account_gate/application/personal_data_resetter.dart` gets the new cubits/repositories registered).
- [ ] T100 Run the full golden matrix (contracts/ui-screens.md §5) and approve each diff. Check 320 dp and 800 dp widths and 1.3× text for clipping (SC-009).
- [ ] T101 Accessibility pass with TalkBack (Android emulator) and VoiceOver (iOS simulator) on the account, security, preferences, delete, support home, new case and case details screens. Check that every control is announced, locked switches say «إلزامي», and the RTL focus order is logical. Fix the findings (quickstart V20).
- [ ] T102 [P] Profile-mode check on a mid-range Android device: the case list scrolls at 60 fps, photo sanitizing keeps the UI responsive (no frame > 32 ms during compression), and there is no leaked Realtime channel after leaving a case (DevTools).
- [ ] T103 [P] Draft the constitution PATCH amendment proposal in `docs/decisions/D-003-realtime-open-support-case.md`: allow Realtime on «an open support case», with the plan.md Complexity Tracking rationale. Owner review is needed before merge; **do not** edit `.specify/memory/constitution.md` without approval.
- [ ] T104 [P] Update `docs/OnAir Guest App Plan.md` §17 G4: tick the three items with a dated status note like the G3/S005 notes (mock-complete; remote waits for U1–U10). Update §19 items 4–7 with the defaults now in use and who decides. Add a G4 row to §18 for the backend owner (U1–U10).
- [ ] T105 [P] Add a pointer section to `contracts/supabase-backend.md` and `contracts/README.md` linking `specs/006-guest-support-account/contracts/` (U1–U10), like the S005 entry.
- [ ] T106 Run quickstart.md §3 (analyze, test, the three integration tests) and every V1–V20 scenario in mock mode. Record the results in the PR description. Staging runs follow once U1–U10 are deployed.

---

## Dependencies & Execution Order

### Phase dependencies

- **Phase 1 (Setup)**: no dependencies.
- **Phase 2 (Foundational)**: depends on Phase 1 and **blocks all stories**.
- **Phases 3–9 (stories)**: each depends on Phase 2.
  - **US1** builds the support domain, repository, mock server and composer.
  - **US2** depends on US1's domain, repository and `AttachmentStrip` (T037–T043).
  - **US3** depends on US1's repository interface (T038) only.
  - **US4** is independent of US1–US3. It creates `AccountRepository` (T068).
  - **US5** depends on US4's `AccountRepository` (T068). It replaces the account screen that US1/US4 added temporary rows to.
  - **US6** depends on T068 and on US5's account screen for the row link (T077). Its domain and heartbeat can start in parallel with US5.
  - **US7** depends on T068 and on US5's account screen for the row link (T077).
- **Phase 10 (Polish)**: after the stories you ship.

### Story dependency graph

```text
Setup → Foundational ─┬─ US1 ─┬─ US2
                      │       └─ US3
                      └─ US4 ── US5 ─┬─ US6
                                     └─ US7
```

### Within each story

Tests (fail first) → domain → data (mock + Supabase) → bootstrap wiring → cubits → screens → routes → integration test.

## Parallel Examples

```text
# Phase 1, all at once:
T002 Info.plist · T003 OpenAPI + regenerate · T004 error-codes.md · T005 l10n · T006 tokens

# Phase 2 tests together, then the independent implementation files:
T007–T014 (tests) → T017 upload_limits · T018 attachment_picker · T019 image_sanitizer ·
T023 settings_row · T024 message_bubble · T025 attachment_tile · T026 CaseStatusChip

# After Phase 2, two developers:
Dev A: US1 → US2 → US3
Dev B: US4 → US5 → US6 → US7

# US1 tests together:
T029 · T030 · T031 · T032 · T033 · T034 · T035 · T036
```

## Implementation Strategy

### MVP (P1 stories, in order)

1. Phase 1 + Phase 2.
2. **US1 + US2**: a working support loop. Every «كلّم الدعم» lands on real screens. Demo it.
3. **US3**: FAQ and call. Visitors and suspended accounts get help.
4. **US4**: account deletion, the store requirement. **MVP = US1–US4**: shippable to the pilot,
   together with the existing account rows from S005.

### Then

5. **US5**: the full account and settings screen (replaces the temporary rows).
6. **US6**: security and sessions (needs backend U6/U8 for Remote mode).
7. **US7**: notification preferences (needs U9 for Remote mode).
8. Phase 10 polish, then Staging runs as backend deltas land (U1–U10 tracked in
   contracts/supabase-support-account.md).

## Notes

- **Remote mode depends on the backend:**
  - US1–US2: U1–U4;
  - US3: U10, partly — the FAQ RPC already exists;
  - US4: U5;
  - US5: U7 + U10;
  - US6: U6 + U8;
  - US7: U9.

  Build and test everything in mock mode first. Never fake a backend behaviour in Remote code.
- `[P]` tasks touch different files. Two tasks editing `lib/bootstrap.dart`, `app_router.dart` or the
  ARB files are never `[P]` with each other.
- Commit after each phase. Stop at any checkpoint to demo the story on its own.
