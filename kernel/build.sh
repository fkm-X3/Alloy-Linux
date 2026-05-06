#!/usr/bin/env bash
set -euo pipefail

# Simple kernel build wrapper for ARM64
KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)/.."
BUILD_DIR="${1:-$KERNEL_DIR/build}"
ARCH="${ARCH:-arm64}"
CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"
JOBS="${JOBS:-$(nproc)}"

mkdir -p "$BUILD_DIR"

echo "Building kernel (ARCH=$ARCH, CROSS_COMPILE=$CROSS_COMPILE) -> $BUILD_DIR"

pushd "$KERNEL_DIR" >/dev/null

if [ ! -d src ]; then
  echo "Kernel source not found in $KERNEL_DIR/src. Place a kernel git clone or source tarball in kernel/src/"
  exit 1
fi

# Apply patches if present
if compgen -G "patches/*.patch" > /dev/null; then
  for p in patches/*.patch; do
    echo "Applying patch: $p"
    patch -p1 < "$p"
  done
fi

# Use defconfig if available
if [ -f configs/defconfig ]; then
  echo "Using configs/defconfig"
  make O="$BUILD_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
else
  echo "No configs/defconfig found. Provide one in kernel/configs/ or run menuconfig interactively."
  exit 1
fi

# Build image and dtbs
make O="$BUILD_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j"$JOBS" Image dtbs

# Install modules into a temporary rootfs inside build dir
make O="$BUILD_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE modules_install INSTALL_MOD_PATH="$BUILD_DIR/rootfs"

echo "Kernel build complete. Outputs in: $BUILD_DIR"
popd >/dev/null
