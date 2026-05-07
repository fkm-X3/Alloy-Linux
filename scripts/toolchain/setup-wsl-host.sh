#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCTOR_ONLY=0
INSTALL_MISSING=0

usage() {
  cat <<'EOF'
Usage: scripts/toolchain/setup-wsl-host.sh [--doctor] [--install] [--help]

Options:
  --doctor   Check host prerequisites and report missing pieces, but do not
             emit build/output/toolchain.env.
  --install  Attempt to install missing Ubuntu packages with apt-get.
  --help     Show this help text.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --doctor)
      DOCTOR_ONLY=1
      ;;
    --install)
      INSTALL_MISSING=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [ "$(uname -s)" != "Linux" ]; then
  echo "This helper is intended for Linux/WSL hosts."
  exit 1
fi

if ! uname -r | tr '[:upper:]' '[:lower:]' | grep -q "microsoft"; then
  echo "Warning: WSL kernel marker not found. Continuing on generic Linux host."
fi

required_cmds=(
  bash make curl awk tar sha256sum rsync mkfs.ext4 mount sudo
  aarch64-linux-gnu-gcc aarch64-linux-gnu-ld aarch64-linux-gnu-as
)

missing_cmds=()
for cmd in "${required_cmds[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing_cmds+=("$cmd")
  fi
done

if [ "$INSTALL_MISSING" -eq 1 ]; then
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get not available; cannot auto-install prerequisites."
    exit 1
  fi
  echo "Installing prerequisite packages for Alloy-Linux build host..."
  sudo apt-get update
  sudo apt-get install -y \
    build-essential curl gawk tar xz-utils rsync e2fsprogs util-linux sudo \
    gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
  missing_cmds=()
  for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_cmds+=("$cmd")
    fi
  done
fi

if [ "${#missing_cmds[@]}" -gt 0 ]; then
  echo "Missing required commands:"
  printf '  - %s\n' "${missing_cmds[@]}"
  echo
  echo "Install with:"
  echo "  sudo apt-get update && sudo apt-get install -y build-essential curl gawk tar xz-utils rsync e2fsprogs util-linux sudo gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu"
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo is missing. Install Rust toolchain with rustup:"
  echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  exit 1
fi

if [ "$DOCTOR_ONLY" -eq 1 ]; then
  echo "Host diagnostics passed."
  exit 0
fi

"$SCRIPT_DIR/setup-toolchain.sh"
echo "WSL host setup complete."
echo "Next steps:"
echo "  source $REPO_ROOT/build/output/toolchain.env"
echo "  make kernel && make build && make image"
