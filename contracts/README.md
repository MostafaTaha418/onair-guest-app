# Draft backend contracts

The single source of backend names is [`docs/OnAir Backend Master Plan.md`](../docs/OnAir%20Backend%20Master%20Plan.md) (28 Oct 2026). These files describe the part the Guest App uses and were aligned with that plan on 28 Oct 2026 (no SMS, email + password sign-in, phone and WhatsApp at sign-up, `property_calendar_locks`, `common_*` RPCs). If a file here disagrees with the plan, the plan wins.

These contracts are drafts for the backend implementer to review and confirm. The reviewed sources are in `specs/001-guest-app-foundation/contracts/`; app code must not assume that unconfirmed backend behavior is already deployed.
- `supabase-discovery.md` is a G1 draft whose reviewed source is `specs/002-guest-discovery/contracts/`.
- `app-routes-g1.md` is a G1 draft whose reviewed source is `specs/002-guest-discovery/contracts/`.
- `verified-links.md` is a G1 draft whose reviewed source is `specs/002-guest-discovery/contracts/`.
- `supabase-backend.md` §8 lists the changes the G0 app code needs after the 28 Oct 2026 update.
