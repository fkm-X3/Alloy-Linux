# Windows flashing and install workflow

This guide covers writing a built Alloy-Linux image from Windows and handling current installer limitations.

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

## Current installer status and manual bridge steps

`installer/install.sh` is currently a scaffold and does not partition/format/install automatically.

After flashing:

1. Mount the flashed root partition and verify `/boot/extlinux/extlinux.conf` exists.
2. Verify kernel assets are present under `/boot` (`Image` and `dtbs/rockchip/...`).
3. If boot assets are missing, copy them from `build/output/boot/` into the flashed media `/boot`.
4. Ensure `extlinux.conf` points to:
   - `LINUX /boot/Image`
   - `FDTDIR /boot/dtbs/rockchip`
   - root argument matching your boot media.

## First boot checks (Orange Pi 5)

- Serial console/U-Boot sees extlinux config.
- Kernel and DTB load from `/boot`.
- Root filesystem mounts read-write and reaches login shell.

If boot fails, capture serial logs and re-check `extlinux.conf` paths plus copied DTBs.
