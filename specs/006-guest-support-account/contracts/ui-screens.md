# UI screens (G4): screen → components, copy keys, goldens

Read `DESIGN.md` and `docs/design_reference/README.md` first. The visual references for this spec are:
- **#12 Profile**: avatar circle, name, email under it, one rounded card with icon + label + value
  rows separated by hairlines.
- **#13 Settings** and **#26 Settings, older prototype**: a large title, section labels, grouped
  rounded cards, square tinted icon tiles in the Settings Icons tones, chevrons.

The references' "Payment Methods/History" rows, separate first/last name, gender and English copy
are **not** built (not in the plan). Arabic-first copy, RTL and EGP rules apply.

## 1. New design-system components (`lib/design_system/components/`)

| Component | Use | Notes |
|---|---|---|
| `SettingsRow` | every account/settings row | Tinted icon tile using new `settingsIcon{Blue,Teal,Orange,Neutral,Danger}` background/foreground pairs. These are **added to `OnAirColors`** for light and dark from `docs/UI_UX_DESIGN_SYSTEM.md` «Settings Icons» (not in code yet); title, optional subtitle and trailing (value text, chevron, switch, chip). 56 dp min height. The chevron mirrors in RTL. Disabled and locked variants. |
| `SettingsGroup` (in the same file) | section label + rounded card of rows | 16 dp radius, hairline dividers inset to the text start (as in #13) |
| `MessageBubble` | case conversation | Guest: end-aligned, `primary` container. OnAir: start-aligned, surface with an «OnAir» label. Time under it (Cairo). Attachments grid inside. Directional insets. `Semantics` reads author + time + text. |
| `AttachmentTile` | composer strip, bubble grid | Image thumb or PDF icon + name + size. States: preparing / uploading (progress ring) / failed (retry) / ready; remove «×» with a Semantics label. 72 dp square in the composer. |
| `CaseStatusChip` (in `status_chip.dart`) | case list and details | Text + icon per status. Tokens: open → Pending, in progress → Badge, waiting user → warning tone, resolved → success tone, closed → neutral. Never color only. |

Reused as-is:
- `StateViews` (skeleton/empty/error/offline), `InfoBanner`, `NoticeCard`;
- `OnAirTextField` (multiline variant), `OnAirPrimaryButton` (+ loading), `OnAirConfirmSheet` /
  `OnAirConfirmDialog`;
- `OnAirOtpField` + `CountdownText` (deletion code), `SectionHeader`, `BottomActionBar`;
- the S005 phone row («متأكد» chip, «تغيير»).

## 2. Screens

### Account (`/account`) — US5, FR-022/028

1. **Header** (#12 style): an initials avatar circle (`primary` ring), the name, the email, and an
   «تعديل» text button → edit-name sheet.
2. **Profile card**: rows for sign-in method (S005) and phone + «متأكد» + «تغيير» (S005).
3. **«عام»**: «الإشعارات» (Blue), «المظهر» (Teal, value: current), «اللغة» (Orange, value: current).
4. **«الأمان»**: «الأمان والأجهزة» (Neutral).
5. **«الدعم»**: «الدعم» (Blue, unread dot if any case has a staff reply), «الأسئلة الشائعة» (Teal),
   «اتصل بخدمة العملاء» (Blue, hidden without a number).
6. **«قانوني»**: «الشروط والأحكام», «سياسة الخصوصية».
7. **Danger zone**: «تسجيل الخروج» (Danger) and «حذف الحساب» (Danger, smaller, last).

The **visitor variant** has a header card with «سجّل الدخول» / «إنشاء حساب», then «عام» without
notifications, then FAQ, legal and the call button.

The **edit-name sheet** has one field (2–80 characters, live validation) and «حفظ» with a loader,
keyboard-safe.

The **language and appearance sheets** use radio rows. English is hidden when
`englishEnabled = false`. The change applies immediately.

### Security (`/account/security`) — US6

- «تغيير كلمة المرور» row, only when `hasPassword`.
- «الأجهزة المسجّل دخولها»: a session list, current first with a «الجهاز ده» chip. Each other row has
  a platform icon, a label and «آخر نشاط {relative}», plus a «خروج» text button with an inline
  loader.
- At the bottom: «تسجيل الخروج من كل الأجهزة التانية» (Danger outline). It is hidden when no other
  session exists and asks for confirmation in a sheet.
- States: skeleton rows / error + retry / offline (actions disabled).

### Change password (`/account/security/password`)

- Three password fields (current, new, confirm) with show/hide toggles.
- The rule line `authPasswordRule` turns green when met, and the strength meter is reused from
  registration.
- «حفظ» stays disabled until valid.
- On success: snackbar «تم تغيير كلمة المرور، وخرّجنا باقي الأجهزة», then pop.
- Errors map to fields: `PASSWORD_INCORRECT` under the current field, `RATE_LIMITED` as a countdown
  notice.

### Notification preferences (`/account/notifications`) — US7

- An `InfoBanner` when device notifications are blocked: «إشعارات الجهاز مقفولة» + «افتح الإعدادات»
  (`app_settings`).
- One card per category: title, then switch rows «إشعارات الجهاز» / «البريد».
- Mandatory categories show a lock icon, disabled switches set on, and the note «إشعارات ضرورية للحجز
  والدفع ومش بتتقفل». Semantics announce «إلزامي».

### Delete account (`/account/delete`) — US4

1. **Explain**:
   - Danger icon, title «حذف الحساب».
   - Three plain bullets: what is deleted, what is kept without your data, «مالوش رجوع» (FR-017,
     FR-021a).
   - A checkbox «فاهم إن الحذف نهائي».
   - «احذف حسابي» (Danger button), disabled until the box is checked.
2. **Blocked**: a `NoticeCard` with «مينفعش تحذف الحساب دلوقتي», the blocker list (booking code →
   tap opens it), and «كلّم الدعم».
3. **Code**: «بعتنا كود على {masked email}», `OnAirOtpField`, `CountdownText` from the server, «إعادة
   الإرسال», then «تأكيد الحذف» (Danger).
4. **Done**: navigate to the visitor home; a one-time snackbar «حسابك اتحذف».

### Support home (`/support`) — US1

- A header with the **FAQ Hero gradient** (§4.3): title «الدعم», subtitle, and two pills — «حالة
  جديدة» (primary on gradient) and «الأسئلة الشائعة».
- «حالاتي» is a sliver list of case cards: code, type label, `CaseStatusChip`, linked booking line,
  «آخر تحديث {relative}», and an unread dot. Open cases come first, then a «حالات منتهية» divider.
- Empty state: an icon, «لسه مفتحتش أي حالة», and «حالة جديدة».
- At the bottom: «اتصل بخدمة العملاء» + hours, when a number is published.
- Pull to refresh. Pagination uses a loader row.

### New case (`/support/new`) — US2

- Type: required chips (حجز، دفع، استرداد، مشكلة في الشقة، أخرى).
- Linked booking or apartment: a removable chip. Without a link, there is an optional «اربط بحجز»
  picker listing the guest's bookings (code + dates).
- Description: a multiline field with a counter `n/4000` and min-10 validation.
- Attachments: an `AttachmentTile` strip plus an «إضافة» tile, which opens a sheet with three options:
  الكاميرا / الصور / ملف PDF. It shows the limit hint («لحد 5 ملفات، صور أو PDF»).
- `BottomActionBar`: «إرسال» with a loader. It is disabled while invalid or uploading, and when
  offline.
- Back with content asks «تسيب الحالة من غير ما تبعتها؟».
- On success: replace with `/support/:id`; the snackbar says «وصلتنا حالتك رقم {code}».

### Case details (`/support/:caseId`) — US1

- App bar: the code and `CaseStatusChip`. Under it, a collapsible info card: type, linked booking
  (tap → booking), opened date.
- The conversation in `MessageBubble`s, with older messages loaded on scroll-up.
- **Composer** (`ReplyComposer`), pinned above the keyboard: text field, attach button, send icon
  button (48 dp, Semantics «إرسال») and an attachment strip above it.
- **Closed state**: the composer is replaced by `NoticeCard` «الحالة دي اتقفلت» + «افتح حالة جديدة».
- **Resolved state**: a `NoticeCard` «الحالة اتحلّت. لو لسه محتاج مساعدة ردّ هنا وهنفتحها تاني»,
  above a normal composer.
- Not found: a neutral «الحالة دي مش موجودة» + «الرجوع للدعم».

### FAQ (`/support/faq`) — US3

- FAQ Hero header with a search field.
- An expandable list (`ExpansionTile` styled as cards).
- No results: «مفيش نتايج» + «افتح حالة جديدة» (visitor → sign-in first).
- Offline from cache: an `InfoBanner` «ممكن تكون المعلومات دي قديمة».
- At the bottom: the call button.

## 3. States matrix (all screens)

| Screen | Skeleton | Empty | Error + ref | Offline | Success |
|---|---|---|---|---|---|
| Account | profile + rows | — | profile read failed, rows still usable | banner; editing disabled | ✓ |
| Security | session rows | only this device | ✓ | banner; buttons disabled | ✓ |
| Preferences | category cards | — | ✓ | banner; switches disabled | ✓ |
| Delete | — | — | ✓ | banner; buttons disabled | ✓ |
| Support home | case cards | ✓ | ✓ | cached-in-memory list + banner | ✓ |
| New case | — | — | inline + snackbar | banner; send disabled; draft kept | ✓ |
| Case details | bubbles | — | ✓ / not found | banner; send disabled; text kept | ✓ |
| FAQ | rows | no results | ✓ (no cache) | cache + banner | ✓ |

## 4. Copy keys (Arabic source, Egyptian tone; English added alongside)

Prefixes:
- `support*`: home, new case, case, FAQ, attachments, statuses `supportStatus{Open,InProgress,
  WaitingUser,Resolved,Closed,Unknown}`, types `supportType{Booking,Payment,Refund,PropertyIssue,
  Other,DamageDispute,Complaint,StayException,Unknown}`.
- `account*`: rows, sheets, security, sessions, password, deletion.
- `settings*`: language, appearance.
- `notifCategory*`: preference categories, with an unknown fallback.

Error keys are listed in [../data-model.md](../data-model.md) §9 and added to
`contracts/error-codes.md`. No raw server text is ever shown (Constitution VI).

## 5. Golden matrix

Each golden is rendered in **Light + Dark × ar-RTL + en-LTR × 1.0 + 1.3 text × 320 dp + 800 dp**,
plus keyboard-open where marked ⌨.

| Golden | Variants |
|---|---|
| `account_screen` | email user, Google user (no password), visitor |
| `edit_name_sheet` ⌨ | valid, too short |
| `security_screen` | with password + 3 sessions, social (no password row), ending one |
| `change_password_screen` ⌨ | empty, rule met, incorrect current |
| `preferences_screen` | mixed with locked rows, device blocked banner |
| `delete_account_screen` | explain, blocked, code step |
| `support_home` | empty, list (open + finished), offline |
| `new_case_screen` ⌨ | prefilled booking, uploading + failed tiles, ready |
| `case_details` ⌨ | conversation with attachments, resolved notice, closed |
| `faq_screen` | list, search no results, offline cache |
| components | `SettingsRow` (all tones/trailing), `MessageBubble`, `AttachmentTile` (all states), `CaseStatusChip` |
