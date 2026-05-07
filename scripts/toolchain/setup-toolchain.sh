#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSIONS_FILE="${VERSIONS_FILE:-$REPO_ROOT/meta/versions.yaml}"
OUT_ENV="${OUT_ENV:-$REPO_ROOT/build/output/toolchain.env}"

manifest_value() {
  local key="$1"
  awk -F': ' -v k="$key" '$1==k {gsub(/"/, "", $2); print $2; exit}' "$VERSIONS_FILE"
}

if [ ! -f "$VERSIONS_FILE" ]; then
  echo "Versions manifest not found: $VERSIONS_FILE"
  exit 1
fi

ARCH="${ARCH:-$(manifest_value arch)}"
CROSS_COMPILE="${CROSS_COMPILE:-$(manifest_value cross_compile_prefix)}"
TARGET_TRIPLE="${TARGET_TRIPLE:-$(manifest_value target_triple)}"
RUST_TOOLCHAIN="${RUST_TOOLCHAIN:-$(manifest_value rust_toolchain)}"

mkdir -p "$(dirname "$OUT_ENV")"

for cmd in "${CROSS_COMPILE}gcc" "${CROSS_COMPILE}ld" "${CROSS_COMPILE}as"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required cross toolchain binary: $cmd"
    exit 1
  fi
done

cat > "$OUT_ENV" <<EOF
export ARCH=$ARCH
export CROSS_COMPILE=$CROSS_COMPILE
export TARGET_TRIPLE=$TARGET_TRIPLE
export RUST_TOOLCHAIN=$RUST_TOOLCHAIN
EOF

echo "Toolchain setup complete."
echo "Source this file before building:"
echo "  source $OUT_ENV"
