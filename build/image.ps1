#Requires -Version 7.0

param(
    [string]$RootfsDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\output\rootfs'),
    [string]$OutImg = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\output\alloy-orangepi5.img'),
    [string]$BootDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\output\boot')
)

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\toolchain\utils.ps1')

Assert-DirectoryExists -Path $RootfsDir -Description 'Rootfs'
New-Item -ItemType Directory -Path (Split-Path $OutImg -Parent) -Force | Out-Null

$repoRoot = Get-RepoRoot
$linuxScript = @'
#!/usr/bin/env bash
set -euo pipefail
ROOTFS_DIR="$(wslpath -a "$1")"
OUT_IMG="$(wslpath -a "$2")"
BOOT_DIR="$(wslpath -a "$3")"
REPO_ROOT="$(wslpath -a "$4")"
cd "$REPO_ROOT"
bash build/image.sh "$ROOTFS_DIR" "$OUT_IMG" "$BOOT_DIR"
'@

$tempScript = Join-Path $env:TEMP ("alloy-image-" + [guid]::NewGuid().ToString('N') + ".sh")
$linuxScript = $linuxScript -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($tempScript, $linuxScript, [System.Text.UTF8Encoding]::new($false))

Write-InfoMessage "Assembling image via WSL backend: $OutImg"

$linuxScriptPath = (& wsl.exe -e wslpath -a $tempScript).Trim()

try {
    & wsl.exe -u root -e bash $linuxScriptPath $RootfsDir $OutImg $BootDir $repoRoot
    if ($LASTEXITCODE -ne 0) {
        throw 'Image assembly failed.'
    }
}
finally {
    Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
}

Write-SuccessMessage "Image created at $OutImg"
