# Data Model (app side): Guest Support & Account (G4)

App-side models and state for [plan.md](plan.md). Server tables are owned by `onair-backend`; their
deltas are in [contracts/](contracts/). Models are immutable (`freezed` or hand-written `final class`
with `==`, matching the existing domain files). None of them is persisted unless stated.

## 1. Support case

```text
SupportCase
  id: String (uuid)
  code: String                  // "SC-1042", shown as the case number
  type: CaseType                // booking | payment | refund | propertyIssue | other
                                // | damageDispute | complaint | stayException | unknown(raw)
  status: CaseStatus            // open | inProgress | waitingUser | resolved | closed | unknown(raw)
  bookingId: String?            // linked booking (guest's own)
  bookingCode: String?          // display only
  propertyId: String?
  propertyTitle: String?        // display only
  createdAt: DateTime (UTC)
  lastActivityAt: DateTime (UTC)
  hasUnreadStaffReply: bool     // from server; drives a dot in «حالاتي»
```

- `CaseType.guestSelectable` = `[booking, payment, refund, propertyIssue, other]`. These are the only
  types the new-case form offers (FR-006).
- `CaseStatus.isOpen` = `open | inProgress | waitingUser`. It drives the list order (FR-002): open
  first, then by `lastActivityAt` descending.
- `CaseStatus.isReplyable` = `!= closed`. It is **display only**: the server answers `CASE_CLOSED` if
  it disagrees (clarified 2026-11-16: a reply on `resolved` reopens it, and the server sets the new
  status).
- `unknown(raw)` keeps the server value and renders a neutral label (spec Edge Cases).

```text
CasePage { items: List<SupportCase>, nextCursor: String? }      // 20 per page

CaseDetails
  case: SupportCase
  messages: List<CaseMessage>           // ascending by createdAt; guest-visible only
  nextOlderCursor: String?              // long conversations load older messages on scroll-up

CaseMessage
  id: String
  author: MessageAuthor                 // guest | onair
  body: String
  createdAt: DateTime (UTC)
  attachments: List<AttachmentRef>
  sendState: MessageSendState           // sent | sending | failed (local optimistic row only)
```

`internal` notes and partner messages are never returned by the server (U1). The app has no field
for them.

## 2. Attachments

```text
AttachmentRef            // already on the server
  id: String
  kind: AttachmentKind   // image | pdf
  sizeBytes: int
  width/height: int?     // images, for layout before load

AttachmentDraft          // local, memory only
  localId: String
  kind: AttachmentKind
  displayName: String
  tempPath: String       // sanitized copy in the cache dir; deleted after upload or discard
  sizeBytes: int
  state: AttachmentUploadState
         // preparing (compressing) → uploading(progress 0..1) → uploaded(attachmentId)
         // ↘ failed(reason: tooLarge | typeNotAllowed | network | server(code)) → (retry) uploading
         // any → removed
  cancelToken                            // Dio cancel; on remove/dispose

UploadLimits            // from app_config, defaults if absent
  imageMaxBytes = 10 MB, pdfMaxBytes = 15 MB, maxFiles = 5
  allowedMime = {image/jpeg, application/pdf}   // photos are always re-encoded to JPEG

FileUrl { url: Uri, expiresAt: DateTime }      // memory map keyed by attachment id (research R4)
```

Validation, in order:
1. type (photo or PDF);
2. count (`≤ maxFiles` per draft);
3. size **after** sanitizing;
4. the server's verdict on sign or PUT.

## 3. Composer drafts (new case / reply)

```text
NewCaseDraft
  draftId: String (uuid v4)    // created on form open; idempotency key + upload group (R3)
  type: CaseType?              // required
  bookingId: String?           // prefilled from ?booking=
  propertyId: String?          // prefilled from ?property=
  body: String                 // 10..4000 chars after trim
  attachments: List<AttachmentDraft>

ReplyDraft
  draftId: String (uuid v4)    // new one after each successful send
  body: String                 // 1..4000 chars after trim (attachments-only reply needs body ≥ 1)
  attachments: List<AttachmentDraft>
```

- `canSend` = valid body, type chosen (case only), no attachment in `preparing`/`uploading`/`failed`,
  not already submitting, and online.
- A retry after a network failure reuses the same `draftId`, so the server returns the same case or
  message (FR-009).
- Drafts are never written to storage. Leaving with content shows the discard confirmation.

## 4. FAQ and support contact

```text
FaqItem { id, question, answer, sortOrder }      // already localized by the app from *_ar / *_en
FaqSnapshot { items: List<FaqItem>, fetchedAt: DateTime, locale: String }   // JSON cache (public)

SupportContact { phone: String?, hours: String? } // from AppConfig; phone empty → button hidden
```

Search is local, over question + answer. It is case-insensitive and normalizes Arabic
(أ/إ/آ→ا, ة→ه, ى→ي, diacritics removed), the same way as the backend search text.

## 5. Account

```text
GuestAccount              // existing (S005): + fields below already present: status, authProviders,
                          // hasPassword, phone, email, fullName
  initials: String        // derived for the avatar (first letters of the first two name words)

ActiveSession
  id: String
  deviceLabel: String     // server-parsed, e.g. "Samsung SM-A546 · Android 14"
  platform: SessionPlatform  // android | ios | web | unknown
  createdAt: DateTime (UTC)
  lastActiveAt: DateTime (UTC)
  isCurrent: bool

SessionsState: loading | ready(List<ActiveSession>, ending: Set<String>, endingAll: bool) | error
```

The current session is listed first and never has an "end" action (FR-031 / US6-5).

```text
PasswordChangeForm { current: String, next: String, confirm: String }
  rules (UX only, same as registration): ≥ 8 chars, a letter and a digit; next ≠ current
  submit → success | passwordIncorrect | passwordWeak | rateLimited(until) | error
```

Passwords live only in the form state and are cleared on success and on dispose.

## 6. Account deletion

```text
DeletionState
  explain                                  // FR-017 text; «احذف حسابي»
  → checking                               // common_request_account_deletion
  → blocked(List<DeletionBlocker>)         // from ACCOUNT_HAS_ACTIVE_BOOKINGS details
  → codeStep(challengeId, maskedEmail, SendWindow)   // reuses S005/G3 email-code UI pieces
  → confirming
  → deleted                                // SignOutService → visitor home + one-time notice
  (codeStep may also show: otpInvalid | otpExpired | attemptsExceeded | rateLimited)

DeletionBlocker { kind: booking | refund | damageClaim, id: String, code: String }
  // tap → /bookings/:id (refund & claim link to their booking)
```

`SendWindow` is the existing S005 model (`nextSendAt`, `blockedUntil` from the server).

## 7. Notification preferences

```text
PreferenceCategory
  key: String                 // server category, e.g. "support", "review", "reminders", "account"
  labelKey: String            // l10n key notif_category_<key>; unknown → generic label
  isMandatory: bool           // server catalog (U9)
  channels: List<PreferenceChannel>   // push | email, each { enabled: bool, saving: bool }
```

A toggle is optimistic, then calls `common_set_notification_preferences([{category, channel,
enabled}])`. On failure it reverts and shows a snackbar with retry. Mandatory rows render as disabled
switches showing `enabled: true`. `deviceNotificationsBlocked: bool` comes from the existing push
permission coordinator.

## 8. App settings (device)

```text
AppSettings { localeCode: 'ar' | 'en', themeMode: system | light | dark }
  persisted: shared_preferences 'localeCode', 'themeMode' (kept on sign-out)
  englishEnabled: from AppConfig (default true)
```

A language change while signed in also triggers `common_update_profile(p_locale)`, best effort, with a
pending flag retried on the next launch (R9).

## 9. Error codes added (mapped in `ErrorMapper`, listed in `contracts/error-codes.md`)

| Code | l10n key | Where |
|---|---|---|
| `CASE_CLOSED` | `supportCaseClosed` | reply on a closed case |
| `ATTACHMENT_REJECTED` (`details.reason`: `too_large` / `type_not_allowed` / `too_many`) | `supportAttachmentRejected*` | sign / bind |
| `ACCOUNT_HAS_ACTIVE_BOOKINGS` (exists, now with `details.blockers`) | `accountHasActiveBookings` | deletion |
| `SESSION_REVOKED` | `errorUnauthenticated` (existing copy «انتهت الجلسة…») | heartbeat |
| `SESSION_IS_CURRENT` | `accountSessionIsCurrent` | end session |
| `PASSWORD_INCORRECT` | `accountPasswordIncorrect` | password change |
| `PASSWORD_WEAK` | `authPasswordRule` (existing rule text) | password change |
