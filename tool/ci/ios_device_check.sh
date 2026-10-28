#!/usr/bin/env bash
# Runs on a macOS runner (see .github/workflows/ci.yml).
#
# 1. Release build for real devices without code signing (proves the app
#    compiles ahead-of-time and the native project is valid).
# 2. Debug build for the simulator, installed and launched on the newest
#    available iPhone simulator; fails if the app is not running 20 s later.
# 3. Runs integration tests on the simulator when they exist and the
#    STAGING_ENV_JSON secret is available.
set -euo pipefail

build_args="$(bash tool/ci/build_args.sh build)"
test_args="$(bash tool/ci/build_args.sh test)"

# shellcheck disable=SC2086
flutter build ios --release --no-codesign $build_args

udid="$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
data = json.load(sys.stdin)["devices"]
best = None
for runtime, devices in data.items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m:
        continue
    version = (int(m.group(1)), int(m.group(2)))
    for d in devices:
        if d.get("isAvailable") and d["name"].startswith("iPhone"):
            if best is None or version > best[0]:
                best = (version, d["udid"], d["name"])
if best is None:
    sys.exit("No available iPhone simulator")
print(best[1])
print(f"Using {best[2]} (iOS {best[0][0]}.{best[0][1]})", file=sys.stderr)
')"

xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b

# shellcheck disable=SC2086
flutter build ios --simulator --debug $build_args

app="build/ios/iphonesimulator/Runner.app"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist")"
echo "Installing $app ($bundle_id)"

xcrun simctl install "$udid" "$app"
xcrun simctl launch "$udid" "$bundle_id"
sleep 20

services="$(mktemp)"
xcrun simctl spawn "$udid" launchctl list > "$services"
if ! grep -q "UIKitApplication:$bundle_id" "$services"; then
  echo "::error::$bundle_id is not running 20 s after launch"
  exit 1
fi
echo "Launch check passed."

if compgen -G "integration_test/*_test.dart" >/dev/null; then
  if [[ -n "${STAGING_ENV_JSON:-}" ]]; then
    # shellcheck disable=SC2086
    flutter test integration_test -d "$udid" $test_args
  else
    echo "::warning::Integration tests skipped: STAGING_ENV_JSON secret is not set."
  fi
fi
