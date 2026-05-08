#Requires -Version 7.0

if (-not (Get-Command qemu-system-aarch64 -ErrorAction SilentlyContinue)) {
    Write-Host 'qemu-system-aarch64 not found; skipping smoke boot.'
    exit 0
}

Write-Host 'QEMU smoke hook is present. Add boot command once image artifacts are available in CI.'
