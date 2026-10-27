#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <apk-or-ipa>" >&2
  exit 2
fi

artifact="$1"
if [[ ! -f "$artifact" ]]; then
  echo "Build artifact not found: $artifact" >&2
  exit 2
fi

case "${artifact,,}" in
  *.apk|*.ipa) ;;
  *)
    echo "Expected an APK or IPA: $artifact" >&2
    exit 2
    ;;
esac

command -v unzip >/dev/null 2>&1 || {
  echo "unzip is required to scan the build artifact" >&2
  exit 2
}

scan_dir="$(mktemp -d)"
cleanup() {
  rm -rf -- "$scan_dir"
}
trap cleanup EXIT

unzip -o -qq "$artifact" -d "$scan_dir"

# Only report file names. Never print a matched credential into CI logs.
declare -A forbidden_patterns=(
  [supabase-service-role]='service_role|InJvbGUiOiJzZXJ2aWNlX3JvbGUi|cm9sZSI6InNlcnZpY2Vfcm9sZSI'
  [kashier-secret]='[Kk][Aa][Ss][Hh][Ii][Ee][Rr][_-]?(api|secret|payment)?[_-]?[Kk][Ee][Yy][[:space:]]*[:=][[:space:]]*[A-Za-z0-9_-]{12,}'
  [resend-secret]='(^|[^A-Za-z0-9])re_[A-Za-z0-9]{24,}([^A-Za-z0-9]|$)'
  [sms-provider-secret]='([Ss][Mm][Ss]|[Tt][Ww][Ii][Ll][Ii][Oo]|[Mm][Ee][Ss][Ss][Aa][Gg][Ee][Bb][Ii][Rr][Dd])[_-]?(api|auth|secret)?[_-]?[Kk][Ee][Yy][[:space:]]*[:=][[:space:]]*[A-Za-z0-9_-]{12,}'
)

failed=0
for label in "${!forbidden_patterns[@]}"; do
  matches="$(grep -R -a -l -E "${forbidden_patterns[$label]}" "$scan_dir" 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    echo "Forbidden $label pattern found in:" >&2
    while IFS= read -r file; do
      echo "  ${file#"$scan_dir"/}" >&2
    done <<< "$matches"
    failed=1
  fi
done

if [[ $failed -ne 0 ]]; then
  echo "Build secret scan failed." >&2
  exit 1
fi

echo "Build secret scan passed."
