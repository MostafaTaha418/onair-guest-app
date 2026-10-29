# G1 Results-Scroll Performance (T105)

Frame timeline for scrolling the results list over the 124 published mock
fixtures (120 generated + the named apartments), opened with no criteria —
the heaviest list G1 ships. Constitution VIII: no noticeable jank in Profile
mode; the SC-002 size/cold-start budget lives in [g0-baseline.md](g0-baseline.md).

## Run command (mid-range Android device or emulator)

```bash
flutter drive \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/results_scroll_perf_test.dart \
  --flavor staging -t lib/main_staging.dart \
  --dart-define-from-file=env/staging.json
```

The driver writes the timeline summary to `build/perf/results_scroll_timeline_summary.json`
(`test_driver/perf_driver.dart` receives it through `responseDataCallback`).
The test itself skips with a printed reason in remote mode: it measures the
mock fixture list, not the network.

## What to check

- `average_frame_build_time_millis` and the 99th percentile stay well under
  the 16 ms budget for 60 fps (Profile mode, on device).
- No `Image` frames classified as slow because of image decoding — the cards
  use `cached_network_image` with sized `memCacheWidth`.
- Remote picture URLs never resolve in mock mode, so every card shows the
  placeholder box; on a Staging run with real images, re-measure and note the
  difference.

## Results (pending device run)

| Metric | Target | Measured | Date / device |
|---|---|---|---|
| Average frame build time (results scroll) | < 16 ms | Pending device | — |
| 99th percentile frame build time | < 32 ms | Pending device | — |
| Worst frame during pagination (loadMore) | no visible stall | Pending device | — |
