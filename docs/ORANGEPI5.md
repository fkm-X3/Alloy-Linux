# Orange Pi 5 target profile

This document defines the first-class Alloy-Linux hardware profile.

## Board baseline

- Board: Orange Pi 5
- SoC: RK3588
- Architecture: ARM64
- Boot strategy: U-Boot

## Boot artifacts

- Kernel image: `/boot/Image`
- DTB path: `/boot/dtbs/rockchip/`
- Boot config: `/boot/extlinux/extlinux.conf`

## Rootfs/image assumptions

- Partition table: GPT
- Partition 1: boot (ext4)
- Partition 2: rootfs (ext4)

## CI fallback

QEMU ARM64 is used as a smoke-test fallback to keep boot regressions visible in CI even when no physical board is attached.
