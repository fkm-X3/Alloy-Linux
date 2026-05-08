#Requires -Version 7.0

param(
    [string]$BuildDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\output\kernel')
)

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\toolchain\utils.ps1')

Assert-DirectoryExists -Path (Split-Path $BuildDir -Parent) -Description 'Kernel output parent'
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

$repoRoot = Get-RepoRoot
$versionsFile = Join-Path $repoRoot 'meta\versions.yaml'
$arch = Get-YamlValue -Path $versionsFile -Key 'arch'
$resolvedPrefix = Resolve-CrossCompilePrefix -PreferredPrefix (Get-YamlValue -Path $versionsFile -Key 'cross_compile_prefix')
$jobs = [Environment]::ProcessorCount
$linuxScript = @'
#!/usr/bin/env bash
set -euo pipefail
BUILD_DIR="$(wslpath -a "$1")"
VERSIONS_FILE="$(wslpath -a "$2")"
ARCH="$3"
JOBS="$4"
KERNEL_SRC_DIR="$(wslpath -a "$5")"
BOOT_OUT_DIR="$(wslpath -a "$6")"
REPO_ROOT="$(wslpath -a "$7")"

# Ensure Linux-side cross toolchain is present (install via apt if missing)
if ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
  echo "aarch64-linux-gnu-gcc not found in WSL; attempting to install via apt"
  apt-get update -y
  apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu || { echo "Failed to install cross toolchain"; exit 1; }
fi

# Install common kernel build dependencies if missing
PKGS=(build-essential libncurses-dev bison flex libssl-dev bc python3 libelf-dev)
MISSING=false
for p in "${PKGS[@]}"; do
  if ! dpkg -s "$p" >/dev/null 2>&1; then
    MISSING=true
    break
  fi
done
if [ "$MISSING" = true ]; then
  echo "Installing kernel build dependencies: ${PKGS[*]}"
  apt-get update -y
  apt-get install -y ${PKGS[*]} || { echo "Failed to install build dependencies"; exit 1; }
fi

# Build in WSL native filesystem to avoid issues with /mnt/c (Windows filesystem)
TMPROOT=$(mktemp -d /tmp/alloy-kernel-XXXX)
echo "Using WSL native temp dir: $TMPROOT"
mkdir -p "$TMPROOT/src" "$TMPROOT/build" "$TMPROOT/downloads"
# Copy kernel source into native tmp to avoid filesystem limitations
tar -C "$KERNEL_SRC_DIR" -cf - . | tar -C "$TMPROOT/src" -xf -

CROSS_COMPILE="aarch64-linux-gnu-"
# Run kernel build with BUILD_DIR inside native tmp
ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" VERSIONS_FILE="$VERSIONS_FILE" JOBS="$JOBS" KERNEL_SRC_DIR="$TMPROOT/src" BOOT_OUT_DIR="$TMPROOT/boot" bash kernel/build.sh "$TMPROOT/build"

# Copy artifacts back to host-backed BOOT_OUT_DIR
mkdir -p "$BOOT_OUT_DIR"
cp -a "$TMPROOT/build/arch/arm64/boot/Image" "$BOOT_OUT_DIR/Image"
mkdir -p "$BOOT_OUT_DIR/dtbs"
cp -a "$TMPROOT/build/arch/arm64/boot/dts/rockchip" "$BOOT_OUT_DIR/dtbs/"
# Also copy modules if present
if [ -d "$TMPROOT/build/rootfs" ]; then
  mkdir -p "$TMPROOT/build/rootfs"
fi
# Cleanup tmp dir
rm -rf "$TMPROOT"
'@

$tempScript = Join-Path $env:TEMP ("alloy-kernel-" + [guid]::NewGuid().ToString('N') + ".sh")
$linuxScript = $linuxScript -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($tempScript, $linuxScript, [System.Text.UTF8Encoding]::new($false))

try {
    $linuxScriptPath = (& wsl.exe -e wslpath -a $tempScript).Trim()
    & wsl.exe -u root -e bash $linuxScriptPath $BuildDir $versionsFile $arch $jobs (Join-Path $repoRoot 'kernel\src') (Join-Path $repoRoot 'build\output\boot') $repoRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Kernel build failed.'
    }
}
finally {
    Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
}

Write-SuccessMessage "Kernel build complete. Outputs in: $BuildDir"
Write-SuccessMessage "Boot artifacts exported to: $(Join-Path $repoRoot 'build\output\boot')"
