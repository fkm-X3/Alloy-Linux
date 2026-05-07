# Windows build setup (WSL2)

This project builds Linux/ARM64 artifacts with bash scripts and Linux utilities.  
On Windows, use **WSL2 (Ubuntu)** as the host environment.

## 1. Enable WSL2 and Ubuntu

In an elevated PowerShell:

```powershell
wsl --install -d Ubuntu
```

Reboot if prompted, then open Ubuntu and finish first-run account setup.

## 2. Install host prerequisites in Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential curl gawk tar xz-utils rsync e2fsprogs util-linux sudo \
  gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
```

These tools are required by current build scripts (`make`, cross-compiler binaries, `mkfs.ext4`, loop mount tooling, and archive/checksum utilities).

## 3. Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

## 4. Clone the repository in Linux filesystem

Build performance and permissions are more reliable under the WSL ext4 filesystem:

```bash
mkdir -p ~/src
cd ~/src
git clone https://github.com/fkm-X3/Alloy-Linux.git
cd Alloy-Linux
```

## 5. Run diagnostics and setup

```bash
make doctor
make setup-wsl
source build/output/toolchain.env
```

If you prefer auto-install from the helper:

```bash
bash scripts/toolchain/setup-wsl-host.sh --install
```

## 6. Build artifacts

```bash
make kernel
make build
make image
```

Expected outputs:
- Kernel artifacts: `build/output/kernel/` and `build/output/boot/`
- Rootfs scaffold: `build/output/rootfs/`
- Disk image: `build/output/alloy-orangepi5.img`

## 7. Run checks

```bash
make repro-check
make rust-test
```

## Troubleshooting

- Missing `aarch64-linux-gnu-*` tools:
  - Reinstall `gcc-aarch64-linux-gnu` and `binutils-aarch64-linux-gnu`.
- `mkfs.ext4` or loop mount failures:
  - Ensure `e2fsprogs` and `util-linux` are installed.
  - Run image creation from a shell with `sudo` privileges.
- Builds are slow or fail under `/mnt/c/...`:
  - Move repository into WSL Linux filesystem (for example `~/src/Alloy-Linux`).
- `cargo` not found:
  - Re-source `~/.cargo/env` or restart the shell after Rust installation.
