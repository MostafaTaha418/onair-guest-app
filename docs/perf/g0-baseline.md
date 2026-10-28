# G0 Performance Baseline (SC-002)

Target (Constitution VIII): cold start to the Home skeleton **< ~2.5 s** on a mid-range
Android device in **Profile mode**; Android per-ABI size **< ~30 MB**, growth tracked every
release.

## Per-ABI APK size (measured 2026-10-28)

Built from `feature/001-guest-app-foundation` with:

```bash
flutter build apk --flavor staging -t lib/main_staging.dart --split-per-abi --release
```

| ABI | Size | Target |
|---|---|---|
| armeabi-v7a | 17.3 MB | < ~30 MB ✓ |
| arm64-v8a | 19.6 MB | < ~30 MB ✓ |
| x86_64 | 21.0 MB | < ~30 MB ✓ |

Notes:

- Release build, R8/minify + resource shrinking on; icon tree-shaking active
  (`MaterialIcons-Regular.otf` reduced 99.8%).
- This build did **not** pass `--obfuscate` / `--dart-define-from-file` (CI's distributed
  build does); the size difference is marginal but re-measure with the CI command when
  tracking release-over-release growth:
  `flutter build apk --flavor staging -t lib/main_staging.dart --obfuscate --split-debug-info=build/symbols --dart-define-from-file=env/staging.json --split-per-abi`
- For a detailed size breakdown per ABI, run the same command with `--analyze-size
  --target-platform android-arm64` (analyze-size requires a single target architecture).

## Cold start to Home skeleton (pending device run)

Needs a mid-range Android physical device; not measured yet. Procedure to record here:

1. Build and install the Staging flavor in Profile mode:
   `flutter run --flavor staging -t lib/main_staging.dart --profile --dart-define-from-file=env/staging.json`
2. Cold start (force-stop first): `adb shell am force-stop com.onair.guest.staging` then
   `adb shell am start -W com.onair.guest.staging/com.onair.guest.MainActivity` and record
   `TotalTime`; confirm visually that the Home skeleton (not a spinner) is the first frame
   after the splash.
3. Repeat 5 times, discard the first run (JIT/page-cache warm-up), record the median.

| Metric | Target | Measured | Date |
|---|---|---|---|
| Cold start to Home skeleton (Profile, mid-range Android) | < 2.5 s | Pending device | — |
| 60 fps scrolling | no noticeable jank | Pending device (placeholder screens are trivial in G0) | — |
