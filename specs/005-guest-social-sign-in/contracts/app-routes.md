# App routes & redirects — S005

Changes relative to `contracts/app-routes.md` (G0–G3). Every rule is evaluated by
`resolveRedirect` (`lib/app/router/redirect.dart`). The redirect is UX only, and the server rejects
incomplete accounts on its own (FR-037).

## Routes

| Path | Screen | Account | Change |
|---|---|---|---|
| `/auth/login` | `LoginScreen` | visitor | + social row (Google; + Apple on iOS); − phone tab |
| `/auth/register` | `RegisterScreen` | visitor | − phone / WhatsApp fields; + social row |
| `/auth/otp` | `OtpScreen` | visitor/pending | email codes only (signup, recovery); − SMS |
| `/auth/complete-profile` | **`ConfirmPhoneScreen(purpose: register)`** | signed-in, `incomplete` | replaces `CompleteProfileScreen`; query `from` kept |
| `/account/phone` | **`ConfirmPhoneScreen(purpose: change)`** | signed-in, `active` | **NEW**; reached from the account screen |
| `/book/:propertyId/verify` | `VerifyIdentityScreen` | signed-in | phone step → `go('/auth/complete-profile?from=/book/:id/dates…')` |

`AppRoutes.accountPhone = '/account/phone'` is added to `requiresAccount` and the registered
locations. It is **not** an auth location.

## Redirect rules (order unchanged; one rule re-sourced)

1. Version gate.
2. Splash while `AuthUnknown`.
3. `SessionEnded` → login with `from`.
4. Email code pending (`CodeSent` / `RateLimited`) → `/auth/otp`.
5. `RecoveryVerified` → `/auth/new-password`.
6. Visitor on an account route → login with `from`.
7. **Signed in and `!isComplete`** → `/auth/complete-profile?from=<target>`.
   - `isComplete` now means **server `profile_status == active`** (data-model §1).
   - This rule covers every account route **and** `/account/phone`, plus every deep link (push,
     App Links), because deep links already pass through the router.
   - Visitor screens are not account routes, so they stay reachable (FR-011).
8. Signed in, complete, on an auth location → `from` or Home.

## Navigation events

| Event | Result |
|---|---|
| Google/Apple success, account `incomplete` | rule 7 → «أكّد رقمك» with the original `from` |
| Google/Apple success, account `active` | rule 8 → `from` (FR-008) |
| Google/Apple cancel | stay on the current auth screen, no message (FR-005) |
| Email code accepted on a new email account | account `incomplete` → rule 7 |
| «أكّد رقمك» back / «إلغاء» → confirm dialog → yes | `AuthCubit.signOut()` → `resolveAuthCancelDestination(from)` as a visitor (FR-014) |
| «أكّد رقمك» success (register) | `AuthCubit.refreshAccount()` → `active` → rule 8 releases to `from` |
| `/account/phone` success (change) | `pop()` + snackbar «رقمك اتغيّر» |
| Any repository receives `PROFILE_INCOMPLETE` / `PHONE_NOT_VERIFIED` | `ProfileGate.onIncomplete()` → `refreshAccount()` → rule 7 with the current location as `from` (research R9) |
| App killed on «أكّد رقمك» or code step, reopened | restore → `incomplete` → rule 7; form starts empty (FR-015) |

## Deep-link safety

Unchanged: IDs are checked against UUID formats, and `from` must be a registered non-auth location
(`_safeReturnLocation`). No new deep links are introduced.
