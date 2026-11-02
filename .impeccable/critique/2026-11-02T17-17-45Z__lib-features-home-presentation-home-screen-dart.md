---
target: الشاشة الرئيسية بكل حالاتها
total_score: 24
max_score: 40
na_heuristics:
p0_count: 0
p1_count: 3
target_identity: "file:D:\\flutter\\on_air\\lib\\features\\home\\presentation\\home_screen.dart"
target_fingerprint: "sha256:972c0a822bc9bed472180ddef9f5e812296879bb348d61309c59d9faba95aa49"
target_path: "D:\\flutter\\on_air\\lib\\features\\home\\presentation\\home_screen.dart"
timestamp: 2026-11-02T17-17-45Z
slug: lib-features-home-presentation-home-screen-dart
---
# Home screen critique

Method: design review only (detector not applicable, native platform)

Target: `lib/features/home/presentation/home_screen.dart`. Evidence: committed home goldens for ready visitor, ready signed-in, and loading in light/dark RTL at 1.0 and 1.3 text scale; source and widget tests for empty, partial error, cached offline, and booking states. No separate visual capture exists for empty or error states. Golden photos are placeholders.

## Design health score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of system status | 3 | Skeletons work; cache freshness is not explicit. |
| 2 | Match system and real world | 2 | EGP and English digit formatting in Arabic-first pricing. |
| 3 | User control and freedom | 3 | Search and retry available. |
| 4 | Consistency and standards | 3 | Shared components and tokens. |
| 5 | Error prevention | 2 | Search constraints are outside home entry. |
| 6 | Recognition rather than recall | 3 | Search, destinations, listings visible. |
| 7 | Flexibility and efficiency | 2 | No visible recent-search shortcut. |
| 8 | Aesthetic and minimalist design | 2 | Large repetitive cards; suggested/newest weakly differentiated. |
| 9 | Error recovery | 2 | Generic partial-section errors. |
| 10 | Help and documentation | 2 | Empty state gives little search guidance. |
| Total | | 24/40 | |

## Design specificity verdict

The home is functional but its visible composition is category-interchangeable. The screenshots use Cairo-area fixtures; real destination inventory was not assessed. Existing components and brand colors make it coherent. Deterministic scan and browser overlay: not applicable to native Flutter.

## What works

- Search is prominent above discovery sections.
- Loading skeletons preserve section layout, and independent section failures retain other content.
- Upcoming booking appears before discovery for a signed-in guest.

## Priority issues

1. **P1 Empty state:** A generic no-listings message and search link do not guide a guest to broaden destination or dates. Improve with `$impeccable onboard`.
2. **P1 Partial errors:** Section error text is generic regardless of cause; identify the failed section and give useful recovery. Improve with `$impeccable harden`.
3. **P1 Partially empty feed:** Suggested section reserves 320 pixels even with zero cards; newest can show a heading with no items. Hide empty sections or show useful next actions. Improve with `$impeccable layout`.
4. **P2 Product specificity and price reading:** Current captures do not communicate the destination focus, and price uses EGP with English digits in Arabic UI. Improve presentation using real data and localized money display, without unsupported savings claims. Improve with `$impeccable polish`.
5. **P2 State verification:** No dedicated goldens for empty, partial/full error, or offline cached states. Add visual coverage during implementation and inspect at phone size. Improve with `$impeccable audit`.

## Persona red flags

- First-time guest: The empty state can read as a lack of supply rather than a prompt to change search criteria.
- Guest on unreliable connectivity: Generic section errors do not identify what failed; cached results may appear current.
- Guest using larger text: A destination title truncates at 1.3 scale in the committed screenshot.

## Minor observations

- Golden images use placeholders; the actual photography and its crop/contrast remain unverified.
- The 1.3-scale search hint wraps onto two lines, which is preferable to clipping but changes the initial viewport height.

## Questions to consider

- Should the empty state suggest changing destination or dates before generic search?
- How should partly empty feeds preserve momentum without blank sections?
- Which actual destinations should lead when the feed contains them?
