#Requires -Version 7.0

<#
.SYNOPSIS
    Setup and validate the ARM64 cross-compilation toolchain for Windows

.DESCRIPTION
    Validates that all required cross-compiler binaries are available and
    emits a PowerShell toolchain environment file (toolchain.env.ps1).
    
    The script reads toolchain configuration from meta/versions.yaml and
    verifies that cross-compiler binaries are accessible.

.PARAMETER VersionFile
    Path to versions.yaml (defaults to meta/versions.yaml)

.PARAMETER OutputEnv
    Path where toolchain environment will be written (defaults to build/output/toolchain.env.ps1)

.EXAMPLE
    .\setup-toolchain.ps1
    
.EXAMPLE
    .\setup-toolchain.ps1 -VersionFile C:\path\to\versions.yaml
#>

param(
    [string]$VersionFile = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "meta\versions.yaml"),
    [string]$OutputEnv = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "build\output\toolchain.env.ps1")
)

# Import utilities
. (Join-Path $PSScriptRoot "utils.ps1")

# ============================================================================
# Main Script
# ============================================================================

Write-InfoMessage "Alloy-Linux Cross-Toolchain Setup (Windows)"
Write-InfoMessage "============================================"

# Validate versions file exists
try {
    Assert-FileExists -Path $VersionFile -Description "Versions manifest"
}
catch {
    Write-ErrorMessage $_
    exit 1
}

# Extract toolchain configuration from versions.yaml
Write-InfoMessage "Reading toolchain configuration from: $VersionFile"

$arch = Get-YamlValue -Path $VersionFile -Key "arch"
$crossCompilePrefix = Get-YamlValue -Path $VersionFile -Key "cross_compile_prefix"
$targetTriple = Get-YamlValue -Path $VersionFile -Key "target_triple"
$rustToolchain = Get-YamlValue -Path $VersionFile -Key "rust_toolchain"

if (-not $arch -or -not $crossCompilePrefix -or -not $targetTriple -or -not $rustToolchain) {
    Write-ErrorMessage "Missing required toolchain configuration in $VersionFile"
    exit 1
}

Write-InfoMessage "  ARCH: $arch"
Write-InfoMessage "  CROSS_COMPILE: $crossCompilePrefix"
Write-InfoMessage "  TARGET_TRIPLE: $targetTriple"
Write-InfoMessage "  RUST_TOOLCHAIN: $rustToolchain"

# ============================================================================
# Verify Cross-Compiler Binaries
# ============================================================================

Write-InfoMessage ""
Write-InfoMessage "Verifying cross-compiler binaries..."

$requiredBinaries = @('gcc', 'ld', 'as')
$missingBinaries = @()
try {
    $resolvedCrossCompilePrefix = Resolve-CrossCompilePrefix -PreferredPrefix $crossCompilePrefix
}
catch {
    Write-ErrorMessage $_
    exit 1
}

if ($resolvedCrossCompilePrefix -ne $crossCompilePrefix) {
    Write-WarningMessage "Using available cross-compiler prefix: $resolvedCrossCompilePrefix"
}

Write-InfoMessage "  Resolved CROSS_COMPILE: $resolvedCrossCompilePrefix"

foreach ($binary in $requiredBinaries) {
    $fullName = "${resolvedCrossCompilePrefix}${binary}"
    Write-InfoMessage "  Checking $fullName..."
    
    if (Test-CommandExists $fullName) {
        Write-SuccessMessage "    Found: $fullName"
    }
    else {
        $found = Find-CrossCompilerBinary -BinaryName $binary -Prefix $resolvedCrossCompilePrefix
        if ($found) {
            Write-SuccessMessage "    Found at: $found"
        }
        else {
            Write-ErrorMessage "    NOT FOUND: $fullName"
            $missingBinaries += $fullName
        }
    }
}

if ($missingBinaries.Count -gt 0) {
    Write-ErrorMessage ""
    Write-ErrorMessage "Missing required cross-compiler binaries:"
    foreach ($binary in $missingBinaries) {
        Write-ErrorMessage "  - $binary"
    }
    Write-ErrorMessage ""
    Write-ErrorMessage "Cross-compiler installation options:"
    Write-ErrorMessage "  1. Scoop: scoop install gcc-aarch64-none-linux-gnu"
    Write-ErrorMessage "  2. MSYS2: install an aarch64-linux-gnu toolchain or add wrappers"
    Write-ErrorMessage "  3. Pre-built: Download from https://developer.arm.com/downloads/-/gnu-a"
    Write-ErrorMessage "  4. Windows host: Use setup-host.ps1 to install baseline tools"
    exit 1
}

# ============================================================================
# Verify Rust Toolchain
# ============================================================================

Write-InfoMessage ""
Write-InfoMessage "Verifying Rust toolchain..."

if (-not (Test-CommandExists "cargo")) {
    Write-ErrorMessage "cargo not found in PATH"
    Write-ErrorMessage ""
    Write-ErrorMessage "Install Rust with rustup:"
    Write-ErrorMessage "  https://rustup.rs/ (recommended)"
    Write-ErrorMessage "  Or via Chocolatey: choco install rustup.install"
    exit 1
}

Write-SuccessMessage "Rust toolchain found"

# ============================================================================
# Export Environment
# ============================================================================

Write-InfoMessage ""
Write-InfoMessage "Exporting toolchain environment..."

$env_vars = @{
    ARCH = $arch
    CROSS_COMPILE = $resolvedCrossCompilePrefix
    TARGET_TRIPLE = $targetTriple
    RUST_TOOLCHAIN = $rustToolchain
}

try {
    Export-ToolchainEnv -Path $OutputEnv -Variables $env_vars
}
catch {
    Write-ErrorMessage "Failed to export toolchain environment: $_"
    exit 1
}

# ============================================================================
# Summary
# ============================================================================

Write-InfoMessage ""
Write-SuccessMessage "Toolchain setup complete!"
Write-InfoMessage ""
Write-InfoMessage "Next steps:"
Write-InfoMessage "  1. Load the environment: . $OutputEnv"
Write-InfoMessage "  2. Build kernel:        &  kernel\build.ps1"
Write-InfoMessage "  3. Build artifacts:     &  .\Build.ps1 -Target build"
Write-InfoMessage ""
Write-InfoMessage "For full build system setup, run: .\setup-host.ps1"
