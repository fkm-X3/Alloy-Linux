# Build System — Alloy-Linux

Decision
- Custom Makefile + bash-based build system (chosen).

Rationale
- Lightweight, auditable, and easy for new contributors. Buildroot/Yocto are too heavy for the initial minimal distro; custom scripts keep bootstrap simple and allow later integration.

Core components

- Toolchain
  - Cross aarch64 toolchain (aarch64-linux-gnu-) is required. `scripts/toolchain/setup-toolchain.sh` validates host tools and emits env vars (ARCH, CROSS_COMPILE, TARGET_TRIPLE, RUST_TOOLCHAIN).
  - CI provides containerized toolchains for reproducible builds.

- Kernel
  - kernel/build.sh: fetch and prepare kernel source, apply patches from kernel/patches/, use kernel/configs/defconfig, and build Image, dtbs, and modules using ARCH=arm64 and CROSS_COMPILE.

- Rootfs
  - `build/lfs-bootstrap.sh` provides staged LFS bootstrap scaffolding.
  - `build/mkrootfs.sh` creates a minimal root filesystem layout. Packages are installed into the rootfs by extracting package artifacts.

- Packaging
  - packages/<pkg>/Alloyfile (YAML) + build.sh per package. Build outputs are .tar.gz artifacts (archive of /usr, /etc, etc).
  - Runtime package DB: /var/lib/alloy-pkgs (simple text manifest). Rust package tooling lives under `tools/alloy-pkg`; `tools/pkgmgr.py` remains a compatibility helper.

- Image assembly
  - build/image.sh assembles rootfs and boot files into an image (ext4/squashfs) and places kernel/boot artifacts in boot/.
  - Initial bootloader strategy: U-Boot (good default for ARM SBCs). Add EFI/UEFI support later if needed.

- CI & Reproducibility
  - Enforce SOURCE_DATE_EPOCH and deterministic archive options (tar --sort=name --mtime).
  - Run cross builds inside containers, and run basic tests under QEMU.
  - Provide ci/reproducible-check.sh and CI manifests under ci/.

Developer quick workflow
1. scripts/toolchain/setup-toolchain.sh
2. kernel/build.sh
3. cd packages/<pkg> && ./build.sh
4. build/mkrootfs.sh ./build/output/rootfs
5. build/install-package.sh ./build/output/rootfs <pkg-archive>
6. build/image.sh ./build/output/rootfs ./build/output/alloy-arm64.img

Next steps
- Implement kernel/build.sh, toolchain setup script, install-package helper, and CI pipeline definitions.

Notes
- Keep scripts small, well-documented, and deterministic. Prefer clarity over cleverness.
