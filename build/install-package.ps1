#Requires -Version 7.0

param(
    [Parameter(Mandatory)][string]$Rootfs,
    [Parameter(Mandatory)][string]$PkgTarball
)

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\toolchain\utils.ps1')

$pkgDbDir = Join-Path $Rootfs 'var\lib\alloy-pkgs'
New-Item -ItemType Directory -Path $Rootfs -Force | Out-Null
New-Item -ItemType Directory -Path $pkgDbDir -Force | Out-Null

$tmpDir = Join-Path $env:TEMP ("alloy-pkg-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

try {
    Write-InfoMessage "Extracting $PkgTarball into $Rootfs"
    tar -xzf $PkgTarball -C $tmpDir
    Copy-Item -Path (Join-Path $tmpDir '*') -Destination $Rootfs -Recurse -Force

    $pkgName = Split-Path $PkgTarball -Leaf
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    Add-Content -Path (Join-Path $pkgDbDir 'installed.txt') -Value "$pkgName | $stamp"

    Write-SuccessMessage "Installed: $pkgName"
    Write-InfoMessage 'Note: Rust equivalent is available via tools\alloy-pkg'
}
finally {
    Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
