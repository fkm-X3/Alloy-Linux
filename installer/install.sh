#!/usr/bin/env bash
set -euo pipefail

DEVICE="${1:?Usage: installer/install.sh <block-device> <rootfs-dir>}"
ROOTFS="${2:?Usage: installer/install.sh <block-device> <rootfs-dir>}"

if [ ! -d "$ROOTFS" ]; then
  echo "Rootfs path not found: $ROOTFS"
  exit 1
fi

echo "Preparing Orange Pi 5 disk layout on $DEVICE"
echo "This installer scaffold does not execute partitioning yet."
echo "Planned layout:"
echo "  - p1 boot ext4 (256M)"
echo "  - p2 rootfs ext4 (remaining)"
echo
echo "To complete full install implementation:"
echo "  1. Partition and format $DEVICE"
echo "  2. Mount rootfs partition and rsync $ROOTFS"
echo "  3. Populate /boot from build/output/boot"
echo "  4. Install/configure U-Boot and extlinux"
