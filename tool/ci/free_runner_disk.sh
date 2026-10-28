#!/usr/bin/env bash
# Flutter, Gradle, the NDK and emulator images exceed the hosted runner's free
# space unless unrelated preinstalled SDKs are removed. Never run on a workstation.
set -euo pipefail

if [[ "${GITHUB_ACTIONS:-}" != true ||
      "${RUNNER_ENVIRONMENT:-}" != github-hosted ||
      "$(uname -s)" != Linux ]]; then
  echo '::error::Disk cleanup is restricted to GitHub-hosted Linux runners.'
  exit 1
fi

df -h /
sudo rm -rf /usr/share/dotnet /opt/ghc /usr/local/.ghcup \
  /usr/local/share/powershell /opt/hostedtoolcache/CodeQL
df -h /
