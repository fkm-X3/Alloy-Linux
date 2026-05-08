Build

Lightweight build orchestration for Alloy-Linux. Start with simple bash scripts and Makefiles in build/. mkrootfs.sh creates a minimal rootfs template.
The repository root `Makefile` wraps the most common build/setup commands.

Key scripts:
- `lfs-bootstrap.sh`: staged LFS bootstrap scaffold (`STAGE=stage1|stage2|stage3|all`)
- `mkrootfs.sh`: create base rootfs layout
- `install-package.sh`: install package archive into rootfs
- `image.sh`: assemble ext4 image and boot files
