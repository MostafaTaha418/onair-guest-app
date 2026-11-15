# Backend deltas A8–A9 — WhatsApp code sending, limits, attestation, delivery webhook

**For:** the existing Cloudflare Worker `onair-api` (`services/integrations` in `onair-backend`)
plus its Supabase tables. **No new Worker** (its wrangler config forbids a second one). Not
implemented in this repository.

---

## A8 — `POST /v1/otp/send` (changed)

### Request

```http
POST /v1/otp/send
Authorization: Bearer <Supabase access token>
x-request-id: <uuid v4>
X-Device-Id: <iOS keychain UUID | Android ANDROID_ID>        # required for channel=whatsapp
X-Firebase-AppCheck: <App Check limited-use token>           # required for channel=whatsapp
Content-Type: application/json

{ "challenge_id": "<uuid>" }
```

`channel` comes from the challenge itself:
- `whatsapp`: `phone_verify`, `phone_change`;
- `email`: `cash_payment_confirm`, `account_deletion`, as today.

Email challenges keep today's behaviour and do not need the two new headers.

### Processing order (WhatsApp)

1. Authenticate the caller. The caller must be the challenge recipient, and the challenge must be
   open → else `401` / `404`.
2. **App Check**: verify the JWT (RS256, Firebase JWKS cached ≤ 6 h; `iss`/`aud` = project
   number of this environment; `exp`). Optional: consume a limited-use token for replay
   protection. Failure → `401 APP_ATTESTATION_FAILED`, **nothing counted, nothing sent**.
3. Validate `X-Device-Id` (non-empty, ≤ 128 chars) → else `400 VALIDATION_FAILED`.
4. Compute the keys with `HMAC-SHA256(OTP_HASH_KEY, …)`:
   - `acct:<user_id>`;
   - `phone:<e164 from payload>`;
   - `dev:<platform>:<device id>`.
5. **Limits** (one row lock per key, `select … for update`), with values from `platform_settings`:
   - For each key, if `last_send_at` is older than `otp_whatsapp_idle_reset_days` (7) → reset
     `send_count = 0`, `ladder_step = 0`.
   - If any key has `blocked_until > now()` → `429 OTP_SEND_BLOCKED` with `details:
     {blocked_until, server_time}` (the strictest key wins).
   - If any key has `send_count >= otp_whatsapp_max_sends` (10) → set `blocked_until = now() +
     otp_whatsapp_block_days` (7 d) on **all three** keys, write `audit_log` (`otp.blocked`, the
     key types only, no raw values), notify admins, and return `429 OTP_SEND_BLOCKED`.
   - If any key has `next_send_at > now()` → `429 RATE_LIMITED` with `details: {next_send_at,
     server_time}`.
   - If the global daily counter reached `otp_whatsapp_daily_cap` → `503
     OTP_TEMPORARILY_UNAVAILABLE` and alert admins (circuit breaker).
6. Generate a 6-digit code (CSPRNG). Store `crypt(code)` with `private.set_otp_code`, and set
   `expires_at = now() + otp_ttl_minutes` (10). This invalidates the previous code on the same
   challenge (`OTP_SUPERSEDED` for old codes).
7. Send the WhatsApp **authentication template** (A9). On a Meta API error, still count the send
   (anti-probing) and return `502 INTERNAL` with the `request_id`.
8. Update every key:
   - `send_count += 1`;
   - `last_send_at = now()`;
   - `next_send_at = now() + ladder[send_count]`;
   - store the Meta `message_id` on the challenge and set `delivery_status = 'pending'`.

### Ladder (`otp_whatsapp_ladder_seconds`)

`[30, 300, 3600, 86400]`, then alternate `[3600, 86400]`. The wait after send *n*:

| n | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| wait | 30 s | 5 min | 1 h | 24 h | 1 h | 24 h | 1 h | 24 h | 1 h | — (next request blocks) |

### Response `200`

```json
{
  "channel": "whatsapp",
  "masked_target": "+20 10•• ••• 678",
  "expires_at": "2026-11-13T10:10:00Z",
  "next_send_at": "2026-11-13T10:00:30Z",
  "blocked_until": null,
  "server_time": "2026-11-13T10:00:00Z"
}
```

### Errors

| HTTP | Code | details |
|---|---|---|
| 400 | `VALIDATION_FAILED` | — |
| 401 | `UNAUTHENTICATED`, `APP_ATTESTATION_FAILED` | — |
| 403 | `PROFILE_INCOMPLETE` (non-`phone_verify` purposes only) | — |
| 404 | `NOT_FOUND` | — |
| 429 | `RATE_LIMITED` | `next_send_at`, `server_time` |
| 429 | `OTP_SEND_BLOCKED` | `blocked_until`, `server_time` |
| 503 | `OTP_TEMPORARILY_UNAVAILABLE` | — |
| 502 | `INTERNAL` | — |

### Storage

```text
private.otp_send_limits
  key_hash        text primary key    -- HMAC of acct:/phone:/dev: key
  key_type        text                -- 'account' | 'phone' | 'device'
  send_count      int  not null default 0
  ladder_step     int  not null default 0
  last_send_at    timestamptz
  next_send_at    timestamptz
  blocked_until   timestamptz
  updated_at      timestamptz not null default now()

private.otp_challenges  (+ columns)
  channel           text not null default 'email'   -- 'email' | 'whatsapp'
  provider_message_id text
  delivery_status   text                             -- pending|sent|delivered|read|failed
  failure_reason    text                             -- not_on_whatsapp|other
```

**Reset on success** (`common_verify_otp`, A5/A6): set `send_count = 0`, `ladder_step = 0`,
`next_send_at = null` for the three keys used by the last send. Blocks are not reset; they expire.

**Admin lift** (later, admin web): `admin_lift_otp_block(key_hash, reason)` clears
`blocked_until` and the counters, with `audit_log`.

**`platform_settings` (new)**:
- `otp_whatsapp_ladder_seconds`;
- `otp_whatsapp_max_sends` (10);
- `otp_whatsapp_block_days` (7);
- `otp_whatsapp_idle_reset_days` (7);
- `otp_whatsapp_daily_cap` (Staging: 200);
- `incomplete_account_retention_days` (7).

`otp_ttl_minutes` (10) and `otp_max_attempts` (5) are reused.

### Edge rate limit

A Cloudflare WAF rate-limiting rule on `api.on-air.website/v1/otp/send`, per IP. Starting value:
20 requests / 10 min, action Block for 10 min. It is tuned after the pilot (Guest Plan §19 item 15).

## A9 — WhatsApp Cloud API sending and delivery webhook

### Send (inside A8 step 7)

```http
POST https://graph.facebook.com/<GRAPH_VERSION>/<WHATSAPP_PHONE_NUMBER_ID>/messages
Authorization: Bearer <WHATSAPP_ACCESS_TOKEN>
{
  "messaging_product": "whatsapp",
  "to": "<e164 without +>",
  "type": "template",
  "template": {
    "name": "<WHATSAPP_OTP_TEMPLATE>",
    "language": { "code": "ar" | "en" },
    "components": [
      { "type": "body",   "parameters": [ { "type": "text", "text": "<code>" } ] },
      { "type": "button", "sub_type": "url", "index": "0",
        "parameters": [ { "type": "text", "text": "<code>" } ] }
    ]
  }
}
```

- The template is in the **Authentication** category. It has the "Copy code" button, the security
  recommendation, and a 10-minute expiry. It is approved in Arabic and English.
- The language follows the challenge's `locale`.
- The code is never logged. The Worker logs only `request_id`, `challenge_id` and the Meta
  `message_id`.

### Webhook

- `GET /v1/webhooks/whatsapp`: verification handshake. Compare `hub.verify_token` with
  `WHATSAPP_WEBHOOK_VERIFY_TOKEN` and echo `hub.challenge`.
- `POST /v1/webhooks/whatsapp`:
  1. Verify `X-Hub-Signature-256` (HMAC-SHA256 of the raw body with `WHATSAPP_APP_SECRET`) →
     else `401`.
  2. For each `statuses[]` entry, find the challenge by `provider_message_id` and update
     `delivery_status`.
  3. On `failed` with Meta error code `131026` (receiver not on WhatsApp / unable to deliver), set
     `failure_reason = 'not_on_whatsapp'`; any other code sets `other`.
  4. Answer `200` quickly.
  5. Make processing idempotent through the existing `provider_webhook_events`.

### Worker configuration

| Name | Kind | Value |
|---|---|---|
| `WHATSAPP_ACCESS_TOKEN` | secret | System User permanent token |
| `WHATSAPP_APP_SECRET` | secret | Meta app secret |
| `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | secret | random string, also entered in Meta |
| `OTP_HASH_KEY` | secret | random ≥ 32 bytes (HMAC for phone/device/account keys) |
| `WHATSAPP_PHONE_NUMBER_ID` | var | from WhatsApp Manager |
| `WHATSAPP_WABA_ID` | var | from WhatsApp Manager |
| `WHATSAPP_OTP_TEMPLATE` | var | approved template name |
| `WHATSAPP_GRAPH_VERSION` | var | Graph API version in use |
| `FIREBASE_PROJECT_NUMBER` | var | per environment, for App Check `aud`/`iss` |

### Tests (Worker, `tests/`)

- ladder progression and 11th-request block;
- block on each key type independently (new account on a blocked device; blocked phone from a new
  device);
- idle reset after 7 days;
- reset on success;
- App Check: missing, invalid or valid;
- daily cap;
- Meta error still counted;
- webhook signature valid/invalid, status mapping, `131026` → `not_on_whatsapp`;
- no code or raw phone in logs.
