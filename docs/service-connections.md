# OnAir service connections

Verified on **2026-10-28**, using **onair3team@gmail.com**. Public identifiers live
in [`config/service-targets.json`](../config/service-targets.json). That registry
contains references only; Flutter loads its public runtime environment from the
ignored `env/staging.json` (CI uses `STAGING_ENV_JSON`).

| Service | Active connection | Credential location |
|---|---|---|
| Supabase Staging | [On Air](https://supabase.com/dashboard/project/popadthwlumlkizmauak), Frankfurt | Publishable client key in ignored local environment and GitHub `STAGING_ENV_JSON` |
| Firebase Staging | [onair-staging-5579e](https://console.firebase.google.com/project/onair-staging-5579e/overview) | Committed public Android/iOS/Dart config; distribution key only in GitHub `FIREBASE_SERVICE_CREDENTIALS` |
| Firebase Production | [onair-production-3team](https://console.firebase.google.com/project/onair-production-3team/overview) | Separate committed public Android/iOS/Dart config |
| Cloudflare | `on-air.website`, account `50555d9fb23d0c265fd1ae43d4d1a4d1` | No Cloudflare token needed by Flutter; existing R2 buckets recorded for Backend work |
| Resend | Verified `on-air.website`, sending key `onair-staging-auth` | Encrypted Supabase SMTP password and GitHub `RESEND_API_KEY_STAGING` |

The Resend key permits sending only for this domain. SMTP is enabled with
`smtp.resend.com`, port `465`, username `resend`, sender
`no-reply@on-air.website` / **OnAir**. Signup confirmation and password recovery
templates display `{{ .Token }}` for the app's OTP screens. SMTP settings were
verified after reload. With explicit owner approval, email OTP uses six digits
and expires after 600 seconds, matching the app's six-box entry. A real email
delivery/OTP round trip still needs testing.
The Resend secret is server-only and is not referenced by the Flutter build workflows.

Firebase has Android and iOS apps for both `com.onair.guest.staging` and
`com.onair.guest`. The dedicated distribution service account has only
`roles/firebaseappdistro.admin`, and the `onair-staging` tester group exists.
Its JSON private key was transferred directly to GitHub Secrets without a local
file. Firebase CLI is authenticated with the team account; specify
`--account onair3team@gmail.com` when running Firebase commands. Local authentication
may still require normal re-login when sessions expire or are revoked.

The old Firebase projects were not deleted. Active app configuration and CI
distribution now reference the team projects above. Old private keys should be
retired after confirming no other consumer uses them.

## Work still needed

- **Backend:** the new database has no application migrations, and `guest-api` is
  not deployed. Its configured target URL is
  `https://popadthwlumlkizmauak.supabase.co/functions/v1/guest-api`. Implement
  `contracts/node-api.openapi.yaml` in the shared Backend repository. Use reviewed
  migrations with RLS, generated contracts/types, and shared seed data; test locally
  before Staging. Do not create application tables through Dashboard/SQL Editor.
- **Production database:** intentionally unassigned. Create a separate project
  before Production release; do not reuse the Staging database.
- **SMS:** no provider credentials were supplied or purchased. Choose a provider
  and budget, then configure Supabase Phone Auth or its Send SMS hook with provider
  secrets in the server environment. Resend supplies email only.
- **iOS push/distribution:** Apple Developer access, APNs credentials and signing
  are still required. In Firebase Project settings → Cloud Messaging → Apple app
  configuration, upload the APNs key with its Key ID and Team ID. Configure signing
  on macOS before testing notifications/TestFlight.
- **Verified app links:** publish valid `/.well-known/assetlinks.json` and
  `/.well-known/apple-app-site-association` on the domain after obtaining the real
  Android signing certificate fingerprint and Apple Team ID. DNS verification for
  Resend does not publish those files.
- **Testers:** in the Staging Firebase console → App Distribution → Testers & Groups
  → OnAir Staging, add the intended email addresses. Testers must accept invitations.
- **GitHub merge protection:** the private repository's current GitHub plan rejects
  branch protection (HTTP 403). The account owner must choose a supporting plan
  before the checks can block merges. Detailed steps are in [`ci.md`](ci.md).

These are service or implementation prerequisites, not missing public keys. Do not
send provider secrets in chat or add them to Git. Store replacements directly in
the appropriate service settings and GitHub Secrets.
