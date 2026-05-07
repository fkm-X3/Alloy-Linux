#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_DIR="$SCRIPT_DIR"
BUILD_DIR="${1:-$REPO_ROOT/build/output/kernel}"
VERSIONS_FILE="${VERSIONS_FILE:-$REPO_ROOT/meta/versions.yaml}"
JOBS="${JOBS:-$(nproc)}"
KERNEL_SRC_DIR="${KERNEL_SRC_DIR:-$KERNEL_DIR/src}"
DOWNLOAD_DIR="${KERNEL_DIR}/downloads"
BOOT_OUT_DIR="${BOOT_OUT_DIR:-$REPO_ROOT/build/output/boot}"

manifest_value() {
  local key="$1"
  awk -F': ' -v k="$key" '$1==k {gsub(/"/, "", $2); print $2; exit}' "$VERSIONS_FILE"
}

mkdir -p "$BUILD_DIR"
mkdir -p "$DOWNLOAD_DIR" "$BOOT_OUT_DIR"

if [ ! -f "$VERSIONS_FILE" ]; then
  echo "Versions manifest not found: $VERSIONS_FILE"
  exit 1
fi

ARCH="${ARCH:-$(manifest_value arch)}"
CROSS_COMPILE="${CROSS_COMPILE:-$(manifest_value cross_compile_prefix)}"

KERNEL_VERSION="${KERNEL_VERSION:-$(manifest_value kernel_version)}"
KERNEL_TARBALL_URL="${KERNEL_TARBALL_URL:-$(manifest_value kernel_tarball_url)}"
KERNEL_SHA256="${KERNEL_SHA256:-$(manifest_value kernel_sha256)}"
KERNEL_TARBALL_URL="${KERNEL_TARBALL_URL//\$\{kernel_version\}/$KERNEL_VERSION}"

echo "Building kernel (ARCH=$ARCH, CROSS_COMPILE=$CROSS_COMPILE) -> $BUILD_DIR"
echo "Kernel version target: $KERNEL_VERSION"

if [ ! -f "$KERNEL_SRC_DIR/Makefile" ]; then
  TARBALL="$DOWNLOAD_DIR/linux-${KERNEL_VERSION}.tar.xz"
  if [ ! -f "$TARBALL" ]; then
    echo "Downloading kernel tarball: $KERNEL_TARBALL_URL"
    curl -fsSL "$KERNEL_TARBALL_URL" -o "$TARBALL"
  fi

  if [ -n "$KERNEL_SHA256" ]; then
    echo "$KERNEL_SHA256  $TARBALL" | sha256sum -c -
  else
    echo "kernel_sha256 is empty in $VERSIONS_FILE; skipping checksum verification."
  fi

  rm -rf "$KERNEL_SRC_DIR"
  mkdir -p "$KERNEL_SRC_DIR"
  tar -xf "$TARBALL" --strip-components=1 -C "$KERNEL_SRC_DIR"
fi

pushd "$KERNEL_SRC_DIR" >/dev/null

if compgen -G "$KERNEL_DIR/patches/*.patch" > /dev/null; then
  for p in "$KERNEL_DIR"/patches/*.patch; do
    echo "Applying patch: $p"
    patch -p1 < "$p"
  done
fi

# Use board defconfig if available, else fall back to arm64 defconfig.
if [ -f "$KERNEL_DIR/configs/defconfig" ]; then
  echo "Using kernel/configs/defconfig"
  cp "$KERNEL_DIR/configs/defconfig" "$BUILD_DIR/.config"
  make O="$BUILD_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE olddefconfig
else
  echo "No kernel/configs/defconfig found. Using arm64 defconfig."
  make O="$BUILD_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
fi

if [ -f "$KERNEL_DIR/configs/orangepi5.fragment" ]; then
  cat "$KERNEL_DIR/configs/orangepi5.fragment" >> "$BUILD_DIR/.config"
  make O="$BUILD_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE olddefconfig
fi

# Build image and dtbs
make O="$BUILD_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j"$JOBS" Image dtbs

# Install modules into a temporary rootfs inside build dir
make O="$BUILD_DIR" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE modules_install INSTALL_MOD_PATH="$BUILD_DIR/rootfs"

cp "$BUILD_DIR/arch/arm64/boot/Image" "$BOOT_OUT_DIR/Image"
mkdir -p "$BOOT_OUT_DIR/dtbs"
cp -a "$BUILD_DIR/arch/arm64/boot/dts/rockchip" "$BOOT_OUT_DIR/dtbs/"

echo "Kernel build complete. Outputs in: $BUILD_DIR"
echo "Boot artifacts exported to: $BOOT_OUT_DIR"
popd >/dev/null
