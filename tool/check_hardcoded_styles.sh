#!/usr/bin/env bash
set -euo pipefail

command -v rg >/dev/null || { echo 'ripgrep (rg) is required.' >&2; exit 2; }

if rg -n 'Color\(0x|Colors\.|fontSize:|fontWeight:' lib \
  --glob '!design_system/**' \
  --glob '!l10n/generated/**' \
  --glob '!core/api/generated/**' \
  --glob '!**/*.g.dart' \
  --glob '!**/*.freezed.dart' \
  --glob '!lib/design_system/**' \
  --glob '!lib/l10n/generated/**' \
  --glob '!lib/core/api/generated/**'; then
  echo 'Hardcoded styles found outside the design system.' >&2
  exit 1
fi
