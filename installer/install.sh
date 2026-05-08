#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: installer/install.sh <block-device> <rootfs-dir> [boot-dir]" >&2
  echo "  <block-device>  Whole-disk target such as /dev/sdX or /dev/nvme0n1" >&2
  echo "  <rootfs-dir>    Rootfs tree to install" >&2
  echo "  [boot-dir]      Boot artifacts directory (default: build/output/boot)" >&2
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage
  exit 1
fi

DEVICE="$1"
ROOTFS="$2"
BOOT_DIR="${3:-$REPO_ROOT/build/output/boot}"

partition_path() {
  local device="$1"
  local number="$2"
  if [[ "$device" =~ [0-9]$ ]]; then
    printf '%sp%s' "$device" "$number"
  else
    printf '%s%s' "$device" "$number"
  fi
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

wait_for_block() {
  local path="$1"
  local attempts=30
  while [ "$attempts" -gt 0 ]; do
    if [ -b "$path" ]; then
      return 0
    fi
    sleep 1
    attempts=$((attempts - 1))
  done
  echo "Timed out waiting for block device: $path" >&2
  exit 1
}

run_root() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    "$@"
  else
    if ! command -v sudo >/dev/null 2>&1; then
      echo "This installer needs root privileges or sudo." >&2
      exit 1
    fi
    sudo "$@"
  fi
}

require_command mkfs.ext4
require_command blkid
require_command mount
require_command umount
require_command rsync
if ! command -v parted >/dev/null 2>&1 && ! command -v sfdisk >/dev/null 2>&1; then
  echo "Missing required command: parted or sfdisk" >&2
  exit 1
fi

if [ ! -b "$DEVICE" ]; then
  echo "Block device not found: $DEVICE" >&2
  exit 1
fi

if [ ! -d "$ROOTFS" ]; then
  echo "Rootfs path not found: $ROOTFS" >&2
  exit 1
fi

if [ ! -d "$BOOT_DIR" ]; then
  echo "Boot artifacts path not found: $BOOT_DIR" >&2
  exit 1
fi

BOOT_PART="$(partition_path "$DEVICE" 1)"
ROOT_PART="$(partition_path "$DEVICE" 2)"
MOUNT_ROOT="$(mktemp -d)"
BOOT_MOUNT="$MOUNT_ROOT/boot"
ROOT_UUID=""
BOOT_UUID=""
mounted_root=0
mounted_boot=0

cleanup() {
  set +e
  if [ "$mounted_boot" -eq 1 ]; then
    run_root umount "$BOOT_MOUNT"
  fi
  if [ "$mounted_root" -eq 1 ]; then
    run_root umount "$MOUNT_ROOT"
  fi
  rm -rf "$MOUNT_ROOT"
}

trap cleanup EXIT

echo "Preparing Orange Pi 5 disk layout on $DEVICE"
echo "  - p1 boot ext4 (256M)"
echo "  - p2 rootfs ext4 (remaining)"

run_root wipefs -a "$DEVICE"
if command -v parted >/dev/null 2>&1; then
  run_root parted -s "$DEVICE" mklabel gpt
  run_root parted -s "$DEVICE" mkpart boot ext4 1MiB 257MiB
  run_root parted -s "$DEVICE" mkpart rootfs ext4 257MiB 100%
else
  run_root sfdisk --wipe always --wipe-partitions always "$DEVICE" <<EOF
label: gpt
,256MiB
;
EOF
fi

if command -v partprobe >/dev/null 2>&1; then
  run_root partprobe "$DEVICE" || true
fi
if command -v partx >/dev/null 2>&1; then
  run_root partx -u "$DEVICE" || run_root partx -a "$DEVICE" || true
fi
if command -v udevadm >/dev/null 2>&1; then
  run_root udevadm settle || true
fi

wait_for_block "$BOOT_PART"
wait_for_block "$ROOT_PART"

run_root mkfs.ext4 -F -L ALLOY-BOOT "$BOOT_PART"
run_root mkfs.ext4 -F -L ALLOY-ROOT "$ROOT_PART"

ROOT_UUID="$(blkid -s UUID -o value "$ROOT_PART")"
BOOT_UUID="$(blkid -s UUID -o value "$BOOT_PART")"

mkdir -p "$MOUNT_ROOT" "$BOOT_MOUNT"
run_root mount "$ROOT_PART" "$MOUNT_ROOT"
mounted_root=1
run_root mkdir -p "$BOOT_MOUNT"
run_root mount "$BOOT_PART" "$BOOT_MOUNT"
mounted_boot=1

run_root rsync -aH --numeric-ids "$ROOTFS"/ "$MOUNT_ROOT"/
run_root rsync -aH --numeric-ids "$BOOT_DIR"/ "$BOOT_MOUNT"/

run_root mkdir -p "$MOUNT_ROOT/etc" "$BOOT_MOUNT/extlinux"
run_root tee "$MOUNT_ROOT/etc/fstab" >/dev/null <<EOF
UUID=$ROOT_UUID / ext4 defaults,noatime 0 1
UUID=$BOOT_UUID /boot ext4 defaults,noatime 0 2
EOF

run_root tee "$BOOT_MOUNT/extlinux/extlinux.conf" >/dev/null <<EOF
DEFAULT alloy
TIMEOUT 3
MENU TITLE Alloy-Linux (Orange Pi 5)

LABEL alloy
  LINUX /boot/Image
  FDTDIR /boot/dtbs/rockchip
  APPEND root=UUID=$ROOT_UUID rw rootwait console=ttyS2,1500000n8
EOF

sync
echo "Installed Alloy-Linux to $DEVICE"
