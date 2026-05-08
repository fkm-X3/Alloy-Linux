#Requires -Version 7.0

[CmdletBinding()]
param(
    [ValidateSet(
        'help',
        'setup',
        'setup-host',
        'doctor',
        'build',
        'all',
        'rust-build',
        'rust-test',
    'kernel',
    'bootstrap',
    'rootfs',
    'image',
        'repro-check',
        'qemu-smoke',
        'pkg-hello',
        'install-hello',
        'clean'
    )]
    [string]$Target = 'help'
)

. (Join-Path $PSScriptRoot 'scripts\toolchain\utils.ps1')

$repoRoot = Get-RepoRoot

function Invoke-Script {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string[]]$Arguments = @()
    )

    & $Path @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Path"
    }
}

function Show-Help {
    @'
Alloy-Linux PowerShell targets
  setup         Validate toolchain and emit env file
  setup-host    Validate Windows host prerequisites
  doctor        Diagnose Windows host prerequisites
  build         Bootstrap + build Rust workspace
  kernel        Build ARM64 kernel + boot artifacts
  bootstrap     Create rootfs bootstrap layout
  rootfs        Create minimal rootfs layout
  image         Build bootable image (pending native image tooling)
  rust-test     Run Rust workspace tests
  repro-check   Validate reproducibility manifests
  qemu-smoke    Run QEMU smoke hook
  pkg-hello     Build hello-world package tarball
  install-hello Build and install hello-world into rootfs
  clean         Remove generated build artifacts
'@ | Write-Host
}

function Invoke-Cargo {
    param([string[]]$Arguments)

    & cargo @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Cargo command failed.'
    }
}

switch ($Target) {
    'help' { Show-Help }
    'setup' { Invoke-Script (Join-Path $repoRoot 'scripts\toolchain\setup-toolchain.ps1') }
    'setup-host' { Invoke-Script (Join-Path $repoRoot 'scripts\toolchain\setup-host.ps1') }
    'doctor' { Invoke-Script (Join-Path $repoRoot 'scripts\toolchain\setup-host.ps1') -Arguments @('-Doctor') }
    'build' {
        Invoke-Script (Join-Path $repoRoot 'build\lfs-bootstrap.ps1')
        Invoke-Cargo -Arguments @('build', '--manifest-path', (Join-Path $repoRoot 'tools\Cargo.toml'), '--workspace')
    }
    'all' {
        Invoke-Script (Join-Path $repoRoot 'build\lfs-bootstrap.ps1')
        Invoke-Cargo -Arguments @('build', '--manifest-path', (Join-Path $repoRoot 'tools\Cargo.toml'), '--workspace')
    }
    'rust-build' {
        Invoke-Cargo -Arguments @('build', '--manifest-path', (Join-Path $repoRoot 'tools\Cargo.toml'), '--workspace')
    }
    'rust-test' {
        Invoke-Cargo -Arguments @('test', '--manifest-path', (Join-Path $repoRoot 'tools\Cargo.toml'), '--workspace')
    }
    'kernel' { Invoke-Script (Join-Path $repoRoot 'kernel\build.ps1') }
    'bootstrap' { Invoke-Script (Join-Path $repoRoot 'build\lfs-bootstrap.ps1') }
    'rootfs' { Invoke-Script (Join-Path $repoRoot 'build\mkrootfs.ps1') }
    'image' { Invoke-Script (Join-Path $repoRoot 'build\image.ps1') }
    'repro-check' { Invoke-Script (Join-Path $repoRoot 'ci\reproducible-check.ps1') }
    'qemu-smoke' { Invoke-Script (Join-Path $repoRoot 'ci\qemu-smoke.ps1') }
    'pkg-hello' { Invoke-Script (Join-Path $repoRoot 'packages\hello-world\build.ps1') }
    'install-hello' {
        Invoke-Script (Join-Path $repoRoot 'packages\hello-world\build.ps1')
        & (Join-Path $repoRoot 'build\install-package.ps1') `
            -Rootfs (Join-Path $repoRoot 'build\output\rootfs') `
            -PkgTarball (Join-Path $repoRoot 'packages\hello-world\hello-world-0.1-arm64.tar.gz')
        if ($LASTEXITCODE -ne 0) {
            throw 'Package install failed.'
        }
    }
    'clean' {
        Remove-Item -Recurse -Force (Join-Path $repoRoot 'build\output') -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force (Join-Path $repoRoot 'tools\target') -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force (Join-Path $repoRoot 'packages\hello-world\pkgroot') -ErrorAction SilentlyContinue
        Remove-Item -Force (Join-Path $repoRoot 'packages\hello-world\hello-world-0.1-arm64.tar.gz') -ErrorAction SilentlyContinue
    }
}
