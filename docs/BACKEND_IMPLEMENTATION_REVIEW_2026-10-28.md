# OnAir Backend — implementation record for Claude Code review

**Date:** 2026-10-28 (Africa/Cairo)  
**Source of truth:** [`OnAir Backend Master Plan.md`](OnAir%20Backend%20Master%20Plan.md)  
**Supabase target actually modified:** staging project `popadthwlumlkizmauak` (`https://popadthwlumlkizmauak.supabase.co`). Production is not configured.  
**Status:** **INCOMPLETE — do not use for real payments or release.** This document deliberately distinguishes code written, code deployed to staging, tests run, and work still absent.

## 1. What was deployed to Supabase staging

Thirty SQL migrations under [`supabase/migrations`](../supabase/migrations/) were applied through the connected Supabase MCP. The local migration filenames were aligned with the versions returned by `list_migrations` after application. The first 15 migrations were applied in the previous session; the remaining 15 were applied during this continuation. No application data was dropped.

Database inventory at the end of this run:

| Item | Observed |
|---|---:|
| `public` tables | 49 |
| `private` tables | 2 |
| `public` tables without RLS | 0 |
| Auth users | 0 |
| Properties | 0 |
| Bookings | 0 |
| Active notification types | 16 |
| Active OnAir cron jobs | 6 |

### 1.1 Schema and access

- All **table names** in sections 4–10 of the Backend Master Plan exist: references/config, identity/workspaces, properties, bookings, money/accounting, notifications, support/tasks. This is a name-level match, **not** a completed column-by-column or behavioral audit.
- `private` schema holds `otp_challenges` and `provider_webhook_events`. Both have RLS with no application read policies, intentionally inaccessible to apps.
- All 49 public tables have RLS. Direct `INSERT/UPDATE/DELETE` grants were revoked from `anon` and `authenticated` for all public tables except direct `favorites` insert/delete. Public reference reads and scoped authenticated reads have SELECT policies.
- Permission helpers implemented: `current_profile_active`, `member_permissions`, `staff_session_verified`, `has_permission`, `has_platform_permission`, recipient helpers.
- The previously existing `public.rls_auto_enable()` function had public execute privileges revoked.
- `property_calendar_locks` has a GiST exclusion constraint on active date ranges to prevent overlapping holds/bookings/owner blocks.
- Financial money columns use `bigint` minor units; the current currency check allows only EGP.
- `trial_balance_v` was corrected so only posted entries contribute to balances.
- `notifications` and `case_messages` were added to `supabase_realtime`.

### 1.2 Identity and OTP

- `auth.users` insert trigger creates a `profiles` row from signup metadata. It checks Egyptian phone format, uniqueness, WhatsApp consistency, name, and terms version. Update trigger marks phone verified when email confirmation changes from null to non-null.
- Implemented `common_request_phone_change`, `common_verify_otp`, and `admin_start_login_challenge` plus private challenge creation, code storage, and verification. Codes are stored as bcrypt-compatible `crypt` hashes. Staff login challenge binds to the JWT `session_id`; consumed staff challenge permits that session.
- A failed code increments attempts and returns `{verified:false,error:'OTP_INVALID'}`. This differs from the plan's general `raise exception 'OTP_INVALID'` convention because raising inside the same transaction would roll back the attempt increment. Claude should review this API choice.
- Only the `phone_change` and `staff_login` paths are usable so far. Account deletion, cash confirmation, and invite acceptance are not implemented.

### 1.3 Discovery, pricing, bookings, stay

- Implemented `private.is_property_public`, `private.effective_nightly_price`, and `private.resolve_booking_terms`; platform default policies seeded at 15% markup and 30% deposit, 48-hour free cancellation. These values require product approval before launch.
- Implemented `guest_get_reference_data`, `guest_search_locations`, `guest_get_property`, `guest_get_property_unavailable_dates`, and `guest_list_property_reviews`. Public property JSON excludes latitude/longitude, access instructions, base price, and markup.
- Implemented `guest_quote_booking`, `guest_start_booking`, `guest_start_remaining_payment`, `guest_get_booking`, `guest_list_bookings`. The quote checks dates, capacity, active locks, effective price, and terms hash. `guest_start_booking` checks confirmed email/phone, consumes the quote, and creates one booking plus one pending payment using an idempotency key.
- Implemented `partner_get_booking`, `partner_list_bookings`, `partner_respond_booking`, and `admin_record_owner_phone_decision`. Partner read JSON exposes guest name/count and base total, not guest contact details or markup. Accept changes hold to booking; reject releases hold and requests refund.
- Implemented guest/partner check-in and checkout acknowledgments. Transition to checked-in requires both acknowledgments and full payment; it creates owner payable and posted journal entry. Completion posts markup revenue. Guest review creation checks completed stay.
- **Not implemented:** guest home feed/search properties, cancellation and preview, replacement offers, damage flows, cash payment, many partner property/calendar/workspace/staff methods, and most admin methods.

### 1.4 Payment, refunds, accounting

- `private.attach_payment_session` saves Kashier checkout URL/reference. `private.apply_kashier_event` handles a verified normalized event, checks amount/currency, prevents duplicate success, records payment, tries atomic hold insertion, marks conflict and requests refund when lock exclusion fires, and posts a balanced payment journal entry.
- Kashier order ID is captured from a processed event for future refunds. Refund functions implemented: request, approve, mark non-Kashier executed, record Kashier result, verify. Separation of duties is checked in these functions. A Kashier refund must have provider status `SUCCESS` before it can be marked verified.
- Initial system ledger accounts were seeded. `private.post_journal` checks total debits equal credits and posts an entry. The table trigger prevents unbalanced posting and mutation of posted entries.
- **Not implemented:** full cancellation/refund calculation, cash custody and handovers, settlement workflow, Kashier payout reconciliation, all automatic journal patterns in section 8.8, and all required finance views/contracts to production quality.

### 1.5 Notifications and cron

- Implemented `private.workspace_recipients`, `private.platform_recipients`, `private.notify`, a booking-event notification trigger, channel preference checks, and queue rows for external delivery. Notification payloads reject keys named phone/email/address/markup/amount_minor.
- **Only 16 notification types are active**. They cover selected booking, stay, payment reminder, support SLA, and refund SLA events. Section 9.7 contains many more events; full coverage is absent. Current engine needs deduplication across overlapping recipient rules and an explicit audit of all recipient/channel mappings.
- Six jobs are installed: owner response expiry (1 min), response reminders (5 min), stale payment abandonment (5 min), stay/payment reminders (hourly), SLA checks (15 min), cleanup (daily). All were observed active in `cron.job`. Reminder timing currently uses Cairo midnight, not each property's check-in/check-out time from version rules; adjust before release.

## 2. Node integrations service written, not deployed

Source: [`services/integrations`](../services/integrations/). It uses Node 20 built-in HTTP/fetch/crypto and pinned `pg@8.23.1`; a package lock file is present in the working tree. `node_modules` is gitignored. Environment variable names are listed in [`.env.example`](../services/integrations/.env.example); no secrets were put in Git.

Implemented routes:

| Route | Behavior | Verification status |
|---|---|---|
| `POST /v1/otp/send` | Authenticates Supabase JWT, checks challenge ownership, generates 6 digits, stores bcrypt hash, sends email via Resend | Source only; no Resend round trip |
| `POST /v1/guest/bookings/start-payment` | Calls guest booking RPC as authenticated user, creates Kashier session, attaches URL | Source only; no Kashier sandbox round trip |
| `POST /v1/guest/bookings/{id}/remaining-payment` | Creates remaining payment/session | Source only |
| `POST /v1/webhooks/kashier` | Verifies `x-kashier-signature` with sorted signature keys and payment API key, normalizes event, stores and applies transaction | Signature unit test and DB normalized-event test; no real webhook |
| `POST /v1/admin/refunds/{id}/execute` | Verifies staff permission, checks separation, calls Kashier refund API, records result | Source only; no Kashier sandbox round trip |
| `GET /health` | Process health | Source only |

**Still absent from Node:** R2 upload/download signing, exports, Push/FCM/APNs/web push, notification delivery worker, Kashier pending-payment reconciliation worker, Kashier payout worker, session revocation job, deployment/configuration, live monitoring, and robust recovery for an external API success followed by local database commit failure. The service needs a real `DATABASE_URL`, Supabase publishable key, Resend key, Kashier test credentials, and deployed HTTPS URL. They were not present in this execution environment. No real payment or email was sent.

## 3. Tests actually run

- [`supabase/tests/booking_core.sql`](../supabase/tests/booking_core.sql): executed against staging in a transaction with synthetic guest/owner users and rolled back. It checked profile trigger, quote price, booking creation, guest/partner data shape, normalized successful payment event, hold creation, payment journal, booking request notifications to guest and owner, partner acceptance, guest confirmation notification, check-in, owner payable, and posted check-in journal. The synthetic records were confirmed absent after rollback.
- An unbalanced manual journal was rejected with `JOURNAL_UNBALANCED`.
- `private.run_stay_and_payment_reminders()` and `private.check_slas()` executed without error on the empty project and returned 0; six jobs were observed active.
- `node --test tests` passed the exact minor-unit conversion and Kashier's published webhook signature example. `node --check` passed for the server source.
- Security advisor at the end showed 3 informational no-policy findings (`private.otp_challenges`, `private.provider_webhook_events`, `public.attachments`). The private tables are intentionally closed; attachment access is not implemented. Advisor also flags public `SECURITY DEFINER` RPCs by design. These require a manual per-function security review. Performance advisor reported **98 unindexed foreign keys**; fix before scale.
- No complete pgTAP suite, CI reset, live Auth signup, live email, Kashier sandbox, R2, Push, or deployment test was run.

## 4. Auth and environment status

- Local [`docs/service-connections.md`](service-connections.md) says staging Resend SMTP and token-only email templates were previously configured. This task did not independently verify current Auth dashboard settings or change them. Its older “SMS work still needed” paragraph conflicts with Backend Master Plan B3 and should be corrected.
- During this task, Windows browser automation stopped because it could not establish the current browser URL confidently enough to enforce its policy. No Auth UI change occurred. Supabase MCP has no Auth-settings mutation capability.
- Staging currently has **zero Auth users**, so there is no super admin membership and the required seed users/properties/bookings from section 14 have not been created. Production Supabase project is unassigned according to the local service connection record.
- Do not send secrets in chat or commit them. Configure them in the deployment secret store and the existing Supabase/Resend/Kashier dashboards.

## 5. Review priorities for Claude Code

1. **Do not approve release from this state.** Compare every table/column/check/FK/index/RLS policy against plan sections 4–10; the prior name-level table match is not a schema-conformance proof.
2. Audit every public `SECURITY DEFINER` function. In particular, `guest_start_booking` is currently callable by any authenticated client although plan 12.2 says Node-only; enforce the intended trust boundary. Review OTP invalid-attempt response shape, login challenge expiry, webhook normalization, idempotency, event transaction handling, and refund verification.
3. Implement every still-missing RPC in section 12, test its permissions and state transitions, and generate `contracts/rpc.md`, TypeScript types, and error-code mapping. The current RPC catalog is far from complete.
4. Complete section 9.7 notification catalog and exact recipients/channels, add delivery worker, verify cross-workspace isolation, and deduplicate overlapping audience rules.
5. Finish Node routes/workers, pin dependencies, add tests, configure staging secrets, deploy HTTPS service, and run real Resend/Kashier sandbox/R2/Push flows. **No real payment until this passes.**
6. Complete section 14 staging seed with non-production identities, 25+ properties, all booking/refund states, and role fixtures. Add pgTAP/Node integration tests from section 15 and run clean database reset in CI.
7. Review Auth settings from section 17 with dashboard/API access and configure the separate production project only after staging is green.
8. Add missing FK/filter indexes identified by performance advisor; verify financial views and journal rules with an accountant.

## 6. Files changed

- `supabase/migrations/*.sql` — 30 migrations, all applied to staging.
- `supabase/tests/booking_core.sql` — rollback-only integration fixture/test.
- `services/integrations/package.json`, `package-lock.json`, `.env.example`, `src/*.mjs`, `tests/kashier.test.mjs` — undeployed Node service source/tests.
- `.gitignore` — ignores nested `node_modules`.
- This report.

The existing unrelated Flutter working-tree changes were not edited by this backend task.
