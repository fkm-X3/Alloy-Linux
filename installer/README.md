Installer

Text-based installer scripts for the Orange Pi 5 target.

Primary install target is Orange Pi 5 (RK3588) with a U-Boot boot flow.

Current status:
- `installer/install.sh` partitions a target disk, formats boot/root ext4 partitions, installs the rootfs, and writes `fstab` plus `extlinux.conf`.
- See `docs/windows-flash-install.md` for current Windows flashing guidance and installer notes.
