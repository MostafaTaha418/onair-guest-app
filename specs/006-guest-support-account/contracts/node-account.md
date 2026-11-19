# Backend deltas U2 and U8 — Node `onair-api` Worker

These are drafts for `D:\flutter\onair-backend\services` (the existing `onair-api` Worker; no new
Worker). After the backend accepts them, the app-side `contracts/node-api.openapi.yaml` is updated
and the Dart client is regenerated (never hand-edited).

## U2 — Draft uploads for support (changed `POST /v1/uploads/sign`)

The request body adds the `support_draft` entity:

```yaml
entity_type:
  type: string
  enum: [support_case, case_message, damage_claim, support_draft]   # + support_draft
entity_id:
  type: string
  format: uuid          # for support_draft: the client draft_id (UUID v4)
mime_type:
  enum: [image/jpeg, image/png, image/webp, application/pdf]        # unchanged
```

**`common_authorize_upload` rules for `support_draft`:**
- The caller is an `active` guest. `incomplete` → `PROFILE_INCOMPLETE`.
- The size is within `upload_limits` (`image_mb` for images, `pdf_mb` for PDF). Otherwise →
  `ATTACHMENT_REJECTED`, `details.reason = too_large` or `type_not_allowed`.
- At most `upload_limits.max_files` attachments per `(uploaded_by, draft_id)`. Otherwise →
  `ATTACHMENT_REJECTED`, `details.reason = too_many`.
- The `attachments` row is created with `entity_type = 'support_draft'`, `entity_id = draft_id`,
  `uploaded_by = auth.uid()`.

**Binding:**
- `common_create_support_case` / `common_reply_support_case` (U1) re-parent the attachments to
  `case_message`.
- `private.cleanup_expired()` deletes unbound `support_draft` rows and their R2 objects after 24 h.

**Download:** `GET /v1/files/{id}/url` is unchanged. Before binding, only the uploader may read a
`support_draft` attachment, which supports thumbnails right after upload. After binding, the case
owner and `support.handle` staff may read it.

The app re-encodes photos to JPEG with EXIF removed (research R2). The server still validates the
magic bytes on the first GET or by a background check, per its existing capability.

## U8 — Change password (new `POST /v1/account/password`)

```yaml
/v1/account/password:
  post:
    operationId: changePassword
    security: [bearerAuth]
    parameters: [ $ref: '#/components/parameters/RequestId' ]
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            additionalProperties: false
            required: [current_password, new_password]
            properties:
              current_password: { type: string, minLength: 1, maxLength: 128 }
              new_password:     { type: string, minLength: 8, maxLength: 128 }
    responses:
      '204': { description: Password changed; other sessions ended }
      '400': { $ref: '#/components/responses/Error' }   # PASSWORD_WEAK, VALIDATION_FAILED
      '401': { $ref: '#/components/responses/Error' }   # UNAUTHENTICATED, PASSWORD_INCORRECT
      '403': { $ref: '#/components/responses/Error' }   # ACTION_NOT_ALLOWED (no password), ACCOUNT_SUSPENDED
      '429': { $ref: '#/components/responses/Error' }   # RATE_LIMITED (details.retry_at)
```

**Behaviour:**
1. Resolve the caller from the bearer JWT, along with its `session_id`.
2. If the user has no email/password identity → `ACTION_NOT_ALLOWED` (FR-029).
3. Rate limit: 5 wrong current passwords per user per 15 min → `RATE_LIMITED` with `retry_at`.
4. Verify `current_password` with the GoTrue password grant for the user's email. A failure →
   `PASSWORD_INCORRECT`. The tokens issued by the check are discarded, and the session created by
   the check is deleted.
5. Validate `new_password`: ≥ 8 characters, at least one letter and one digit, different from the
   current one. Otherwise → `PASSWORD_WEAK`.
6. Update the password with the admin API.
7. Delete every `auth.sessions` row of the user except the caller's `session_id` (clarified
   2026-11-16).
8. Emit `account.password_changed` (in-app + email, mandatory). Write `audit_log` without the
   password.

Passwords are never logged. Request bodies on this route are excluded from Worker logging.

## Not changed

`POST /v1/otp/send` already sends email codes for `account_deletion` challenges (purpose listed in
the Backend Master Plan §5.2). It needs no change beyond confirming that this purpose is enabled on
the email channel, with the existing email ladder.
