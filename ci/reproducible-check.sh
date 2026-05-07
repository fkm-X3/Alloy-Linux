#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$REPO_ROOT/meta/versions.yaml" ]; then
  echo "Missing meta/versions.yaml"
  exit 1
fi

if ! grep -q '^kernel_version:' "$REPO_ROOT/meta/versions.yaml"; then
  echo "meta/versions.yaml does not define kernel_version"
  exit 1
fi

if [ ! -f "$REPO_ROOT/meta/targets/orangepi5.yaml" ]; then
  echo "Missing Orange Pi 5 target profile"
  exit 1
fi

echo "Reproducibility manifest checks passed."
