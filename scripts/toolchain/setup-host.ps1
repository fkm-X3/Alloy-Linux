#Requires -Version 7.0

<#
.SYNOPSIS
    Validate or bootstrap the Windows host for Alloy-Linux

.DESCRIPTION
    Checks common Windows prerequisites for the PowerShell-based build flow and
    optionally installs a baseline set of tools through winget or Chocolatey.

.PARAMETER Doctor
    Only report missing prerequisites; do not install anything or emit setup
    output.

.PARAMETER Install
    Attempt to install missing baseline tools using winget or Chocolatey when
    available.
#>

param(
    [switch]$Doctor,
    [switch]$Install
)

. (Join-Path $PSScriptRoot "utils.ps1")

$repoRoot = Get-RepoRoot
$outputEnv = Join-Path $repoRoot "build\output\toolchain.env.ps1"
$requiredCommands = @(
    'git',
    'cargo',
    'rustup',
    'make',
    'curl',
    'tar',
    '7z'
)

function Get-PackageManager {
    if (Test-CommandExists winget) {
        return 'winget'
    }

    if (Test-CommandExists choco) {
        return 'choco'
    }

    return $null
}

function Install-BaselineTools {
    $manager = Get-PackageManager
    if (-not $manager) {
        throw 'No supported Windows package manager found (winget or Chocolatey).'
    }

    Write-InfoMessage "Using package manager: $manager"
    if ($manager -eq 'winget') {
        Invoke-AlloyCommand -Description 'Installing Git' -Command { winget install --id Git.Git -e --source winget }
        Invoke-AlloyCommand -Description 'Installing Rustup' -Command { winget install --id Rustlang.Rustup -e --source winget }
        Invoke-AlloyCommand -Description 'Installing 7-Zip' -Command { winget install --id 7zip.7zip -e --source winget }
    }
    else {
        Invoke-AlloyCommand -Description 'Installing Git' -Command { choco install git -y }
        Invoke-AlloyCommand -Description 'Installing Rustup' -Command { choco install rustup.install -y }
        Invoke-AlloyCommand -Description 'Installing 7-Zip' -Command { choco install 7zip -y }
    }
}

Write-InfoMessage 'Alloy-Linux Windows host setup'
Write-InfoMessage '==============================='

$missing = @()
foreach ($command in $requiredCommands) {
    if (-not (Test-CommandExists $command)) {
        $missing += $command
    }
}

if ($missing.Count -gt 0) {
    Write-WarningMessage 'Missing baseline tools:'
    foreach ($item in $missing) {
        Write-WarningMessage "  - $item"
    }
}

if ($Install) {
    try {
        Install-BaselineTools
    }
    catch {
        Write-ErrorMessage $_
        exit 1
    }
}

try {
    Assert-FileExists -Path (Join-Path $repoRoot 'meta\versions.yaml') -Description 'Versions manifest'
}
catch {
    Write-ErrorMessage $_
    exit 1
}

if ($Doctor) {
    if ($missing.Count -eq 0) {
        Write-SuccessMessage 'Host diagnostics passed.'
    }
    else {
        Write-ErrorMessage 'Host diagnostics found missing prerequisites.'
        exit 1
    }

    exit 0
}

& (Join-Path $PSScriptRoot 'setup-toolchain.ps1') -VersionFile (Join-Path $repoRoot 'meta\versions.yaml') -OutputEnv $outputEnv

Write-SuccessMessage 'Windows host setup complete.'
Write-InfoMessage "Load the environment with: . $outputEnv"
