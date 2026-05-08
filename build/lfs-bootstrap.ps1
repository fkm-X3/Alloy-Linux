#Requires -Version 7.0

param(
    [string]$OutDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\output'),
    [string]$RootfsDir = '',
    [ValidateSet('stage1', 'stage2', 'stage3', 'all')]
    [string]$Stage = 'all'
)

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\toolchain\utils.ps1')

$repoRoot = Get-RepoRoot
if (-not $RootfsDir) {
    $RootfsDir = Join-Path $OutDir 'rootfs'
}

$logDir = Join-Path $OutDir 'logs'
$logFile = Join-Path $logDir 'lfs-bootstrap.log'

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Write-BootstrapLog {
    param([string]$Message)

    $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $line = "[$stamp] $Message"
    $line | Tee-Object -FilePath $logFile -Append
}

function Invoke-Stage1 {
    Write-BootstrapLog 'Stage 1: cross-toolchain bootstrap metadata'
    New-Item -ItemType Directory -Path (Join-Path $OutDir 'toolchain') -Force | Out-Null
    @(
        'This directory is reserved for LFS cross-toolchain artifacts.'
        'Use scripts\toolchain\setup-toolchain.ps1 to validate host tooling.'
    ) | Set-Content -Path (Join-Path $OutDir 'toolchain\README') -Encoding UTF8
}

function Invoke-Stage2 {
    Write-BootstrapLog 'Stage 2: temporary tools skeleton'
    foreach ($dir in @('bin', 'lib', 'include')) {
        New-Item -ItemType Directory -Path (Join-Path $OutDir "temp-tools\$dir") -Force | Out-Null
    }
}

function Invoke-Stage3 {
    Write-BootstrapLog 'Stage 3: rootfs baseline layout'
    & (Join-Path $PSScriptRoot 'mkrootfs.ps1') -RootfsDir $RootfsDir
    New-Item -ItemType Directory -Path (Join-Path $RootfsDir 'etc\alloy') -Force | Out-Null
    Copy-Item -Path (Join-Path $repoRoot 'meta\versions.yaml') -Destination (Join-Path $RootfsDir 'etc\alloy\versions.yaml') -Force
}

switch ($Stage) {
    'stage1' { Invoke-Stage1 }
    'stage2' { Invoke-Stage2 }
    'stage3' { Invoke-Stage3 }
    'all' {
        Invoke-Stage1
        Invoke-Stage2
        Invoke-Stage3
    }
}

Write-BootstrapLog 'LFS bootstrap scaffold complete'
