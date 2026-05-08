#!/usr/bin/env bash
set -euo pipefail

ROOTFS_DIR="${1:-./build/output/rootfs}"
OUT_IMG="${2:-./build/output/alloy-arm64.img}"
BOOT_DIR="${3:-./build/output/boot}"
IMG_SIZE="${IMG_SIZE:-512M}"
TARGET="${TARGET:-orange-pi-5}"

echo "Assembling image: rootfs=$ROOTFS_DIR, boot=$BOOT_DIR, out=$OUT_IMG"

if [ ! -d "$ROOTFS_DIR" ]; then
  echo "Rootfs not found: $ROOTFS_DIR"
  exit 1
fi

mkdir -p "$(dirname "$OUT_IMG")"
# Create empty ext4 image of given size
truncate -s $IMG_SIZE "$OUT_IMG"
mkfs.ext4 -F "$OUT_IMG"
ROOT_UUID="$(blkid -s UUID -o value "$OUT_IMG")"

MNT=$(mktemp -d)
sudo mount -o loop "$OUT_IMG" "$MNT"
# Copy rootfs into image
sudo rsync -aH --numeric-ids "$ROOTFS_DIR"/ "$MNT"/

# Copy boot files if provided
if [ -d "$BOOT_DIR" ]; then
  sudo mkdir -p "$MNT/boot"
  sudo rsync -aH "$BOOT_DIR"/ "$MNT/boot"/
fi

if [ ! -f "$MNT/boot/extlinux/extlinux.conf" ]; then
  sudo mkdir -p "$MNT/boot/extlinux"
  cat <<EOF | sudo tee "$MNT/boot/extlinux/extlinux.conf" >/dev/null
DEFAULT alloy
TIMEOUT 3
MENU TITLE Alloy-Linux (${TARGET})

LABEL alloy
  LINUX /boot/Image
  FDTDIR /boot/dtbs/rockchip
  APPEND root=UUID=$ROOT_UUID rw rootwait console=ttyS2,1500000n8
EOF
fi

sync
sudo umount "$MNT"
rmdir "$MNT"

echo "Image created at $OUT_IMG"
