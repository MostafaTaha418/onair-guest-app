# G1 App Size (T106)

Per-ABI release APK sizes before and after G1, against the SC-002 budget
(**< ~30 MB** per ABI). Both builds from the same machine and toolchain
(Flutter 3.44.3 / Dart 3.12.2, R8 minify + resource shrinking on, icon
tree-shaking active — `MaterialIcons-Regular.otf` reduced 99.5%):

```bash
flutter build apk --flavor staging -t lib/main_staging.dart \
  --split-per-abi --release --dart-define-from-file=env/example.json
```

- **Before G1:** commit `0eecffa` (G0 final, built in a scratch worktree 2026-10-29).
- **After G1:** commit `a81c7a7` (G1 complete, T001–T109).

| ABI | Before G1 | After G1 | Delta |
|---|---|---|---|
| armeabi-v7a | 17.32 MB (18,164,773 B) | 17.31 MB (18,154,618 B) | −0.01 MB |
| arm64-v8a | 19.70 MB (20,653,965 B) | 19.67 MB (20,627,430 B) | −0.03 MB |
| x86_64 | 21.02 MB (22,045,785 B) | 21.06 MB (22,084,786 B) | +0.04 MB |

Notes:

- The G1 dependencies (`cached_network_image`, `share_plus`, `path_provider`,
  T001) land inside the noise: the per-ABI deltas above are ±0.04 MB and two
  of the three ABIs did not grow at all. Budget headroom stays > 10 MB.
- R8 strips the unused share_plus platform implementations per ABI, which is
  why the deltas do not accumulate across all three.
- Both builds pass `--dart-define-from-file` but not `--obfuscate`
  (`--split-debug-info`); the CI distributed build adds those, and the size
  difference is marginal. Re-measure release-over-release with the CI command
  when tracking growth:
  `flutter build apk --flavor staging -t lib/main_staging.dart --obfuscate --split-debug-info=build/symbols --dart-define-from-file=env/staging.json --split-per-abi`
