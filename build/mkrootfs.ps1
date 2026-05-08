#Requires -Version 7.0

param(
    [string]$RootfsDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build\output\rootfs')
)

. (Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\toolchain\utils.ps1')

$dirs = @(
    'bin', 'boot', 'dev', 'etc', 'home', 'lib', 'lib64', 'mnt', 'opt',
    'proc', 'root', 'run', 'sbin', 'srv', 'sys', 'tmp', 'usr', 'var'
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path (Join-Path $RootfsDir $dir) -Force | Out-Null
}

foreach ($dir in @('usr\bin', 'usr\sbin', 'usr\lib', 'usr\share', 'var\lib', 'var\log', 'var\tmp')) {
    New-Item -ItemType Directory -Path (Join-Path $RootfsDir $dir) -Force | Out-Null
}

Write-InfoMessage "Created minimal rootfs at $RootfsDir"
