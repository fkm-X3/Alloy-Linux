#Requires -Version 7.0

. (Join-Path (Split-Path $PSScriptRoot -Parent) '..\scripts\toolchain\utils.ps1')

$pkgRoot = Join-Path $PSScriptRoot 'pkgroot'
$outFile = Join-Path $PSScriptRoot 'hello-world-0.1-arm64.tar.gz'

Remove-Item -Path $pkgRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path (Join-Path $pkgRoot 'usr\bin') -Force | Out-Null

$helloPath = Join-Path $pkgRoot 'usr\bin\hello'
@'
#!/bin/sh
echo "Hello from Alloy-Linux!"
'@ | Set-Content -Path $helloPath -NoNewline -Encoding UTF8

tar -czf $outFile -C $pkgRoot .
Write-SuccessMessage "Built: $(Split-Path $outFile -Leaf)"
