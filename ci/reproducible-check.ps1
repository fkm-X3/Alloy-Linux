#Requires -Version 7.0

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\toolchain\utils.ps1')

$repoRoot = Get-RepoRoot
$versionsFile = Join-Path $repoRoot 'meta\versions.yaml'
$targetProfile = Join-Path $repoRoot 'meta\targets\orangepi5.yaml'

Assert-FileExists -Path $versionsFile -Description 'Versions manifest'
Assert-FileExists -Path $targetProfile -Description 'Orange Pi 5 target profile'

$content = Get-Content -Path $versionsFile -Raw
if ($content -notmatch '^\s*kernel_version\s*:\s*') {
    throw 'meta\versions.yaml does not define kernel_version'
}

Write-SuccessMessage 'Reproducibility manifest checks passed.'
