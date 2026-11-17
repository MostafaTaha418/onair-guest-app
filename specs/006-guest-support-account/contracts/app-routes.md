# App routes (G4 changes)

These changes apply to `lib/app/router/{routes,app_router,redirect,notification_router}.dart`. Every
`:id` is validated as UUID v4 before use (Constitution IV). Ids from links are navigation hints only.

## Routes

| Path | Screen | Account | Linkable | Notes |
|---|---|---|---|---|
| `/support` | `SupportHomeScreen` | yes | — | **new**. Pushed above the shell from «حسابي» → «الدعم» |
| `/support/new?booking=&property=&type=` | `NewCaseScreen` | yes | — | **was placeholder**. `booking`/`property` must be UUID v4, or they are dropped. `type` ∈ guest types |
| `/support/faq` | `FaqScreen` | **no** | — | **new**, public. Declared **before** `/support/:caseId` |
| `/support/:caseId` | `CaseDetailsScreen` | yes | yes | **was `NotAvailableScreen`**. Foreign or unknown id → neutral «الحالة دي مش موجودة» (`NOT_FOUND`) |
| `/account` | `AccountScreen` | visitor variant / full | — | **replaces placeholder**. Visitor sees the public rows only (FR-028) |
| `/account/security` | `SecurityScreen` | yes | — | **new**. Sessions list, plus a password row when `hasPassword` |
| `/account/security/password` | `ChangePasswordScreen` | yes | — | **new**. Redirects to `/account/security` when `!hasPassword` |
| `/account/notifications` | `NotificationPreferencesScreen` | yes | — | **new** |
| `/account/delete` | `DeleteAccountScreen` | yes | — | **new**. Normal account gate. `incomplete` accounts never reach it in this release; the server would still allow them to delete |
| `/account/phone` | (S005) | yes | — | unchanged |
| `/account-suspended` | `AccountSuspendedScreen` | — | — | adds «الأسئلة الشائعة» and the call button (FR-016) |

Edit name, language and appearance are bottom sheets on `/account`, not routes.

## Redirect rules

- `AppRoutes.requiresAccount` adds `/support`, `/account/security`, `/account/security/password`,
  `/account/notifications` and `/account/delete`. `/support/faq` is explicitly **not** in it.
- The existing rules apply unchanged:
  - visitor → login with return location;
  - `incomplete` → `/auth/complete-profile` (S005);
  - suspended/deleted → `/account-suspended`.
- `/support/faq` is added to the static allowed paths. `/support` and the `/account/*` routes are
  added too.
- After deletion succeeds, `SignOutService` runs and the app navigates with `go(AppRoutes.home)`, so
  the stack is cleared. The one-time notice is passed as an `extra`, never in the URL.

## Entry points re-pointed

| From | Before | After |
|---|---|---|
| Booking details «تحتاج مساعدة؟ تواصل مع OnAir» / `contact_support` action | `/support/new?booking=<id>` → placeholder | same URL → `NewCaseScreen`, with type `booking` preselected |
| Property «لديك سؤال؟ تواصل مع OnAir» | `/support/new?property=<id>` → placeholder | same URL → `NewCaseScreen`, with type `other` preselected and the property linked |
| Damage claim «رقم الحالة» (G3) | text only | tappable → `/support/:caseId` when the claim returns `support_case_id` |
| WhatsApp code «كلّم الدعم» (S005) | `/support/new` | `/support` for active accounts. For `incomplete` accounts → `/support/faq` + call button (cases need an active account) |
| Notification `support.staff_replied` / `support.case_resolved` | `/support/new` | `/support/<target_id>` when it is a UUID, else `/support` (U4) |
| Notification `account.password_changed` / `account.phone_changed` | `/account` | `/account/security` (password) or `/account` (phone) |

## Navigation stack

`/account` is the 5th tab (shell). The support, security, preferences and delete screens are pushed
on top of the shell with `parentNavigatorKey: root`, so the bottom navigation hides while composing,
as with booking flows. Back always returns to the previous screen. From a notification cold start,
back from a case goes to `/support`, then `/account`.
