#!/usr/bin/env bash
# Runs on a booted Android emulator (see .github/workflows/ci.yml).
#
# 1. Builds a debug APK, installs it, launches it, and fails if the app is not
#    running 20 s later or crashed (FATAL EXCEPTION for our package).
# 2. Runs integration tests on API 34 when they exist and the
#    STAGING_ENV_JSON secret is available. API 24 checks install and launch;
#    running the full suite there duplicates API 34 and can stall in adb.
set -euo pipefail

build_args="$(bash tool/ci/build_args.sh build)"
test_args="$(bash tool/ci/build_args.sh test)"

api_level="$(adb shell getprop ro.build.version.sdk | tr -d '\r')"
echo "Android API level: $api_level"

# shellcheck disable=SC2086
flutter build apk --debug $build_args

tmp="$(mktemp -d)"
apks=(build/app/outputs/flutter-apk/*debug*.apk)
apk="${apks[0]}"
aapt="$(ls "$ANDROID_HOME"/build-tools/*/aapt | sort -V | tail -1)"
"$aapt" dump badging "$apk" > "$tmp/badging.txt"
pkg="$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" "$tmp/badging.txt")"
echo "Installing $apk ($pkg)"

if [[ "$api_level" -lt 34 ]]; then
  # Legacy emulators can stall on ADB's streamed install path.
  timeout 180s adb install --no-streaming -r "$apk"
else
  timeout 180s adb install -r "$apk"
fi
adb logcat -c
adb shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null
sleep 20

running=false
if adb shell pidof "$pkg" >/dev/null 2>&1; then
  running=true
else
  adb shell ps > "$tmp/ps.txt" 2>/dev/null || true
  if grep -q "$pkg" "$tmp/ps.txt"; then running=true; fi
fi

adb logcat -d > "$tmp/logcat.txt" || true
if [[ "$running" != true ]]; then
  echo "::error::$pkg is not running 20 s after launch"
  tail -n 400 "$tmp/logcat.txt"
  exit 1
fi

crashes="$(grep -A3 "FATAL EXCEPTION" "$tmp/logcat.txt" | grep -c "Process: $pkg" || true)"
if [[ "${crashes:-0}" -gt 0 ]]; then
  echo "::error::$pkg crashed after launch"
  grep -A30 "FATAL EXCEPTION" "$tmp/logcat.txt" || true
  exit 1
fi
echo "Launch check passed."

if [[ "$api_level" -lt 34 ]]; then
  echo "API $api_level build, install, launch, and crash checks passed; integration suite runs on API 34 and iOS."
elif compgen -G "integration_test/*_test.dart" >/dev/null; then
  if [[ -n "${STAGING_ENV_JSON:-}" ]]; then
    # shellcheck disable=SC2086
    flutter test integration_test $test_args
  else
    echo "::warning::Integration tests skipped: STAGING_ENV_JSON secret is not set."
  fi
fi
