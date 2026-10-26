#!/usr/bin/env bash
# Prints the Flutter arguments for the Staging flavor, once the flavor exists.
#
#   bash tool/ci/build_args.sh build   -> args for `flutter build`
#   bash tool/ci/build_args.sh test    -> args for `flutter test integration_test`
#
# Before G0 adds flavors (no lib/main_staging.dart) it prints nothing, so the
# template app still builds. env/staging.json comes from the STAGING_ENV_JSON
# secret when set, otherwise from env/example.json (public placeholders only).
set -euo pipefail

mode="${1:-build}"

if [[ ! -f lib/main_staging.dart ]]; then
  exit 0
fi

if [[ -n "${STAGING_ENV_JSON:-}" ]]; then
  mkdir -p env
  printf '%s' "$STAGING_ENV_JSON" > env/staging.json
elif [[ ! -f env/staging.json && -f env/example.json ]]; then
  mkdir -p env
  cp env/example.json env/staging.json
fi

args="--flavor staging"
if [[ "$mode" == "build" ]]; then
  args="$args -t lib/main_staging.dart"
fi
if [[ -f env/staging.json ]]; then
  args="$args --dart-define-from-file=env/staging.json"
fi

echo "$args"
