Kernel

Contains kernel configuration, patches and helper scripts used to build the Linux kernel for ARM64.
Place defconfig files, patches/ and build scripts here. Use build/ for orchestration.

Current defaults:
- Source and version are read from `meta/versions.yaml`
- Primary target profile is Orange Pi 5 (`configs/orangepi5.fragment`)
- Boot artifacts are exported into `build/output/boot/`
