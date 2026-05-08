# Windows native setup

Alloy-Linux now uses PowerShell scripts for Windows host setup.

## 1. Install prerequisites

Install these tools on Windows:

- PowerShell 7+
- Git
- Rustup / Rust
- 7-Zip
- GNU Make
- curl
- An ARM64 cross toolchain (`aarch64-none-linux-gnu-*`)

Using `winget`:

```powershell
winget install --id Git.Git -e --source winget
winget install --id Rustlang.Rustup -e --source winget
winget install --id 7zip.7zip -e --source winget
```

Using Chocolatey:

```powershell
choco install git -y
choco install rustup.install -y
choco install 7zip -y
```

Using Scoop for the cross toolchain:

```powershell
scoop bucket add extras
scoop install gcc-aarch64-none-linux-gnu
```

## 2. Run host setup

From the repository root:

```powershell
.\\scripts\\toolchain\\setup-host.ps1
```

To only check prerequisites:

```powershell
.\\scripts\\toolchain\\setup-host.ps1 -Doctor
```

To try installing baseline tools:

```powershell
.\\scripts\\toolchain\\setup-host.ps1 -Install
```

## 3. Generate toolchain environment

```powershell
.\\scripts\\toolchain\\setup-toolchain.ps1
```

This writes `build\\output\\toolchain.env.ps1`. Load it with:

```powershell
. .\\build\\output\\toolchain.env.ps1
```

## 4. Troubleshooting

- Missing `aarch64-linux-gnu-*` binaries: install `gcc-aarch64-none-linux-gnu` with Scoop or make sure a compatible cross toolchain is on `PATH`.
- Missing `cargo`: install Rustup and restart PowerShell.
- Missing `make`, `tar`, or `7z`: install MSYS2, GNU utilities, or the equivalent Windows package.
