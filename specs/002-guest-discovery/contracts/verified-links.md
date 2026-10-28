# Contract: Verified-Link Domain Files and Store Fallback (DRAFT)

**Audience**: whoever runs the OnAir link domain (still open, Guest Plan §19.2; G0 uses the
configurable `LINK_DOMAIN`). **Status**: draft for review.

**Sources**: spec FR-030–FR-031 and Clarification 2026-10-28 (store page, no web preview);
Constitution III (verified links, not custom schemes).

The app side is built and testable now. Everything below is served by the domain, outside this
repository.

## 1. Domain association files

| File | Path | Content |
|---|---|---|
| Android App Links | `https://<LINK_DOMAIN>/.well-known/assetlinks.json` | `delegate_permission/common.handle_all_urls` for package `com.onair.guest` (Production) and `com.onair.guest.staging` (Staging, on the staging domain), with each signing key's SHA-256 fingerprint |
| iOS Universal Links | `https://<LINK_DOMAIN>/.well-known/apple-app-site-association` | `applinks.details` for the Team ID + bundle IDs, with `components` for `/property/*`, `/search/results`, `/payment/return`, `/bookings/*`, `/support/*` |

Requirements:
- Served over HTTPS with status 200 and `Content-Type: application/json`, and no redirects.
- Staging and Production use separate domains (or subdomains) so test builds never open live
  links.
- App IDs are still provisional (G0 R14). Update both files when they are final.

## 2. Fallback for devices without the app

When the app is not installed, the OS opens the URL in the browser. For the paths in §1, the
domain responds as follows:

| Visitor's device | Response |
|---|---|
| Android | `302` to the Google Play listing of the OnAir Guest app |
| iOS | `302` to the App Store listing of the OnAir Guest app |
| Other / unknown | `302` to a static OnAir page with both store badges (no apartment preview) |

- **No apartment data:** the fallback must not show any apartment data (no title, photo, or
  price). That matches the clarification, and it means the domain needs no backend access.
- **Path and query:** the original path and query may be dropped. Restoring the destination
  after install (deferred deep linking) is **out of scope** for G1.
- **Caching:** responses should be cacheable for a short time only, so store URLs can change.

## 3. App-side guarantees (already in G0 + G1)

- Only `https` links on exactly `LINK_DOMAIN` are accepted. User-info and unknown paths
  resolve to `/not-available`.
- IDs are validated as UUID v4. Query parameters are whitelisted per route
  ([app-routes.md](app-routes.md)).
- Links never change state; data is always fetched again.

## 4. Acceptance

1. On a device with the Staging build, tapping a staging property link opens the details
   screen. Tapping a search link opens results with the same criteria.
2. On a device without the app, the same links open the right store page.
3. A link with a bad ID or an unknown path opens `/not-available` in the app.
