# Windows flashing and install workflow

This guide covers writing a built Alloy-Linux image from Windows and notes on the Linux installer path.

## Prerequisites

- Built image exists: `build/output/alloy-orangepi5.img`
- Boot artifacts exist: `build/output/boot/Image` and `build/output/boot/dtbs/`
- Target media is inserted (SD card or USB/NVMe adapter used for provisioning)

Optional checksum before flashing:

```bash
sha256sum build/output/alloy-orangepi5.img
```

## Option A: Flash from WSL with `dd`

1. Identify the device:

```bash
lsblk
```

2. Unmount mounted partitions from that device (example `/dev/sdX`):

```bash
sudo umount /dev/sdX* 2>/dev/null || true
```

3. Write image:

```bash
sudo dd if=build/output/alloy-orangepi5.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

Use the full disk device (for example `/dev/sdX`), not a partition (`/dev/sdX1`).

## Option B: Flash with a Windows GUI imager

- Use a raw image writer such as Balena Etcher or Rufus.
- Select `build/output/alloy-orangepi5.img`.
- Double-check the destination drive before starting.
- Safely eject media when complete.

## Installer path

`installer/install.sh` now partitions a target disk, formats boot/root ext4 partitions, installs the rootfs, copies boot assets, and writes `fstab` plus `extlinux.conf`.

Usage:

```bash
installer/install.sh /dev/sdX build/output/rootfs build/output/boot
```

The script expects a whole-disk device and the built rootfs/boot artifacts. It writes `root=UUID=...` into `extlinux.conf` so the installed system is not tied to a fixed device name.

## First boot checks (Orange Pi 5)

- Serial console/U-Boot sees extlinux config.
- Kernel and DTB load from `/boot`.
- Root filesystem mounts read-write and reaches login shell.

If boot fails, capture serial logs and re-check `extlinux.conf` paths plus copied DTBs.
