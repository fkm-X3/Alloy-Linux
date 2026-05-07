#!/usr/bin/env bash
set -euo pipefail

if ! command -v qemu-system-aarch64 >/dev/null 2>&1; then
  echo "qemu-system-aarch64 not found; skipping smoke boot."
  exit 0
fi

echo "QEMU smoke hook is present. Add boot command once image artifacts are available in CI."
