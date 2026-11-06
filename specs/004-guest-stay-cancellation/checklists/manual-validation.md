# G3 manual validation

**Run date:** 2026-11-06  
**Build:** `staging` with `BACKEND_MODE=mock`  
**Targets:** Infinix X6870 (`147512558W003037`) and Pixel 3a API 34 (`emulator-5554`)  
**Status:** Partially run on the physical Infinix in Arabic/dark mode. The app built, installed, and launched in `staging/mock`; account creation, OTP `123456`, My Bookings, scrolling through the G3 fixtures, and booking details were exercised. The emulator walkthrough was blocked because Codex computer control required explicit access to the QEMU system window. No unobserved scenario or display variant is marked as passed.

Automated coverage is recorded in Notes only. It does not replace the manual variants required by T095.

| Scenario | AR light | AR dark | EN | 1.3× | Notes |
|---|---|---|---|---|---|
| 1. Deposit-only confirmed booking details | Not run | Partial | Not run | Not run | On Infinix, the G3 card showed `مطلوب منك: ادفع المبلغ المتبقي` and the confirmed state. A full online-payment walkthrough was not completed. Covered by booking details, remaining payment, journey, and golden tests. |
| 2. Pay remaining online succeeds | Not run | Not run | Not run | Not run | Covered by payment return, remaining outcome, and journey tests. |
| 3. Failed remaining payment and fast double tap | Not run | Not run | Not run | Not run | `rapid double pay starts one remaining payment` and payment-attempt retry tests pass. |
| 4. Cash phone validation and authorization | Not run | Not run | Not run | Not run | Covered by cash cubit and screen tests, including unauthorized collector handling. |
| 5. Cash OTP, resend, receipt, and offline receipt | Not run | Not run | Not run | Not run | Covered by cash confirmation, receipt, offline, and semantics tests. |
| 6. Collector-recorded cash notification | Not run | Not run | Not run | Not run | Covered by G3 notification routing and mock journey tests. |
| 7. Guest and owner check-in acknowledgement | Not run | Not run | Not run | Not run | Covered by stay acknowledgement cubit, journey, and golden tests. |
| 8. Guest and owner checkout acknowledgement | Not run | Not run | Not run | Not run | Covered by stay acknowledgement journey and tracker goldens. |
| 9. Free, deposit-lost, and no-refund cancellation | Not run | Not run | Not run | Not run | Covered by cancellation cubit, flow, and all policy-case goldens. |
| 10. Cancellation terms change and reconfirmation | Not run | Not run | Not run | Not run | Covered by cancellation changed-terms tests and golden. |
| 11. Refund stage progression | Not run | Not run | Not run | Not run | Covered by booking status and cancellation journey tests. |
| 12. Damage claim evidence and dispute validation | Not run | Not run | Not run | Not run | Covered by claim screen, cache, journey, and return-refresh tests. |
| 13. Accept, decline, and expire replacement offer | Not run | Not run | Not run | Not run | Covered by offer cubit/widget, journey, and golden tests. |
| 14. Airplane mode with cached details | Not run | Not run | Not run | Not run | Offline behavior is covered by repository, screen, and action-disabled widget tests. |
| 15. Cross-guest cancellation and claim isolation | Not run | Not run | Not run | Not run | Route UUID validation and not-available behavior are covered automatically; manual isolation remains required. |
| 16. Full visual pass, 320dp and tablet | Not run | Partial | Not run | Not run | Home, login, registration, OTP, My Bookings, and booking details were visually inspected on the Infinix in Arabic/dark mode with no observed overflow. G3 goldens pass for light/dark, RTL/LTR, AR/EN, 1.3×, 320dp, and 800dp; the remaining direct variants are still required. |

## Automated verification completed

- `tool/check_hardcoded_styles.sh`: passed.
- `dart format --output=none --set-exit-if-changed .`: 496 files, no changes.
- `flutter analyze`: passed with no issues.
- `flutter test --exclude-tags golden`: 890 tests passed.
- `flutter test --tags golden`: 252 golden tests passed after visual review of the Cairo due-date correction.

## To unblock T095

Grant Codex computer-use access to the Android Emulator/QEMU window (or keep the physical phone session in the foreground), rerun all 16 scenarios without leaving the in-memory mock session, replace each `Not run`/`Partial` cell with `Pass` or `Fail`, add device-specific notes, and only then mark T095 complete in `tasks.md`.
