# Alloy-Linux

Alloy-Linux is a Linux From Scratch based ARM64 distro project.

Current project direction:
- Primary hardware target: **Orange Pi 5 (RK3588)**
- Kernel policy: **pin and build latest stable Linux kernel**
- Language direction: **Rust-first for project-owned userspace/tooling**

## Repository structure

- `build/` build orchestration scripts
- `kernel/` kernel fetch/config/build scripts and patches
- `meta/` target and version manifests
- `packages/` package recipes and package build scripts
- `tools/` developer/runtime utilities (Rust tooling + legacy helpers)
- `ci/` CI helper scripts

## Quickstart (host)

1. Configure host toolchain env:
   - `scripts/toolchain/setup-toolchain.sh`
2. Build kernel for ARM64:
   - `kernel/build.sh`
3. Bootstrap base rootfs layout:
   - `build/lfs-bootstrap.sh`
4. Build Rust tools:
   - `cargo build --manifest-path tools/Cargo.toml --workspace`
5. Build an image:
   - `build/image.sh ./build/output/rootfs ./build/output/alloy-orangepi5.img`

## Makefile workflow

Use the top-level `Makefile` for faster common workflows:
- `make setup`
- `make doctor`
- `make build`
- `make kernel`
- `make image`
- `make rust-test`
- `make repro-check`

## Windows setup + flashing

For Windows users, use the native PowerShell host setup:
- `docs/windows-native-setup.md` for host setup and build commands
- `docs/windows-flash-install.md` for media flashing and install guidance

## Notes

- Linux itself is not rewritten; we use upstream kernel sources.
- Rust is used for distro-owned components (init/package tooling and related control-plane code).
