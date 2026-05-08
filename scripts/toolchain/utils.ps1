#Requires -Version 7.0

<#
.SYNOPSIS
    PowerShell utility functions for Alloy-Linux build system

.DESCRIPTION
    Shared utilities for setup, building, and validation on Windows
#>

# ============================================================================
# Path Utilities
# ============================================================================

function Resolve-AlloyPath {
    <#
    .SYNOPSIS
        Resolve an Alloy-Linux repository path
    
    .PARAMETER Path
        Relative path from repo root
    #>
    param([string]$Path)
    
    if (-not $env:ALLOY_REPO_ROOT) {
        $env:ALLOY_REPO_ROOT = (git -C $PSScriptRoot rev-parse --show-toplevel)
    }

    Join-Path $env:ALLOY_REPO_ROOT $Path
}

function Get-RepoRoot {
    <#
    .SYNOPSIS
        Get the Alloy-Linux repository root directory
    #>
    if ($env:ALLOY_REPO_ROOT) {
        return $env:ALLOY_REPO_ROOT
    }
    
    $env:ALLOY_REPO_ROOT = (git -C $PSScriptRoot rev-parse --show-toplevel)
    return $env:ALLOY_REPO_ROOT
}

# ============================================================================
# YAML Utilities
# ============================================================================

function Get-YamlValue {
    <#
    .SYNOPSIS
        Extract a value from a simple YAML file
    
    .PARAMETER Path
        Path to YAML file
    
    .PARAMETER Key
        Key to extract (supports nested keys like 'parent.child')
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Key
    )
    
    if (-not (Test-Path $Path)) {
        throw "YAML file not found: $Path"
    }
    
    $content = Get-Content -Path $Path -Raw
    $lines = $content -split "`n"
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ($line -match "^${Key}\s*:\s*(.+)$") {
            $value = $matches[1].Trim()
            # Remove quotes if present
            $value = $value -replace '^[\"'']|[\"'']$', ''
            return $value
        }
    }
    
    return $null
}

# ============================================================================
# Prerequisite Checking
# ============================================================================

function Test-CommandExists {
    <#
    .SYNOPSIS
        Test if a command exists in PATH
    
    .PARAMETER Command
        Command name to test
    #>
    param([string]$Command)
    
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Test-ExecutableExists {
    <#
    .SYNOPSIS
        Test if an executable file exists
    
    .PARAMETER Path
        Path to executable
    #>
    param([string]$Path)
    
    if (Test-Path $Path -PathType Leaf) {
        # Check if it's executable on Windows
        return $true
    }
    return $false
}

function Find-CrossCompilerBinary {
    <#
    .SYNOPSIS
        Find a cross-compiler binary (aarch64-linux-gnu-*)
    
    .PARAMETER BinaryName
        Name of binary (e.g., 'gcc', 'ld', 'as')
    
    .PARAMETER SearchPaths
        Optional array of paths to search
    #>
    param(
        [Parameter(Mandatory)][string]$BinaryName,
        [string]$Prefix = 'aarch64-linux-gnu-',
        [string[]]$SearchPaths = @(
            "C:\msys64\mingw64\bin",
            "C:\msys64\usr\bin",
            "C:\Program Files\LLVM\bin",
            "$env:PROGRAMFILES\LLVM\bin",
            "$env:USERPROFILE\scoop\apps\gcc-aarch64-none-linux-gnu\current\bin"
        )
    )
    
    $prefixed = "${Prefix}${BinaryName}"
    
    # Try to find in PATH first
    if (Test-CommandExists $prefixed) {
        return $prefixed
    }
    
    # Search in common locations
    foreach ($searchPath in $SearchPaths) {
        if (Test-Path $searchPath) {
            $fullPath = Join-Path $searchPath "${prefixed}.exe"
            if (Test-ExecutableExists $fullPath) {
                return $fullPath
            }
        }
    }
    
    return $null
}

function Resolve-CrossCompilePrefix {
    <#
    .SYNOPSIS
        Resolve the best available AArch64 GNU cross-compiler prefix

    .PARAMETER PreferredPrefix
        Primary prefix from the versions manifest
    #>
    param([Parameter(Mandatory)][string]$PreferredPrefix)

    $candidatePrefixes = @($PreferredPrefix)
    if ($PreferredPrefix -ne 'aarch64-none-linux-gnu-') {
        $candidatePrefixes += 'aarch64-none-linux-gnu-'
    }

    foreach ($prefix in $candidatePrefixes) {
        if (
            (Test-CommandExists "${prefix}gcc") -and
            (Test-CommandExists "${prefix}ld") -and
            (Test-CommandExists "${prefix}as")
        ) {
            return $prefix
        }

        $gccPath = Find-CrossCompilerBinary -BinaryName 'gcc' -Prefix $prefix
        if ($gccPath -and ($gccPath -like "*${prefix}gcc.exe")) {
            return $prefix
        }
    }

    throw "No supported AArch64 GNU cross-compiler prefix found. Tried: $($candidatePrefixes -join ', ')"
}

# ============================================================================
# Error Handling
# ============================================================================

function Write-ErrorMessage {
    <#
    .SYNOPSIS
        Write an error message with formatting
    
    .PARAMETER Message
        Error message to display
    #>
    param([string]$Message)
    
    Write-Host "ERROR: $Message" -ForegroundColor Red -BackgroundColor Black
}

function Write-WarningMessage {
    <#
    .SYNOPSIS
        Write a warning message with formatting
    
    .PARAMETER Message
        Warning message to display
    #>
    param([string]$Message)
    
    Write-Host "WARNING: $Message" -ForegroundColor Yellow -BackgroundColor Black
}

function Write-SuccessMessage {
    <#
    .SYNOPSIS
        Write a success message with formatting
    
    .PARAMETER Message
        Success message to display
    #>
    param([string]$Message)
    
    Write-Host "SUCCESS: $Message" -ForegroundColor Green -BackgroundColor Black
}

function Write-InfoMessage {
    <#
    .SYNOPSIS
        Write an info message with formatting
    
    .PARAMETER Message
        Info message to display
    #>
    param([string]$Message)
    
    Write-Host "INFO: $Message" -ForegroundColor Cyan -BackgroundColor Black
}

# ============================================================================
# Command Execution
# ============================================================================

function Invoke-AlloyCommand {
    <#
    .SYNOPSIS
        Execute a command with error checking
    
    .PARAMETER Command
        PowerShell command to execute
    
    .PARAMETER Description
        Human-readable description of what's being done
    
    .PARAMETER AllowFailure
        If $true, don't exit on failure
    #>
    param(
        [Parameter(Mandatory)][scriptblock]$Command,
        [string]$Description = "Executing command",
        [bool]$AllowFailure = $false
    )
    
    Write-InfoMessage $Description
    
    try {
        & $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-ErrorMessage "$Description failed: $_"
        if (-not $AllowFailure) {
            exit 1
        }
    }
}

# ============================================================================
# Environment Setup
# ============================================================================

function Get-ToolchainEnvPath {
    <#
    .SYNOPSIS
        Get the standard toolchain environment output path
    #>
    param([string]$RepoRoot = (Get-RepoRoot))

    Join-Path $RepoRoot "build\output\toolchain.env.ps1"
}

function Export-ToolchainEnv {
    <#
    .SYNOPSIS
        Export toolchain environment variables to a PowerShell file
    
    .PARAMETER Path
        Output file path
    
    .PARAMETER Variables
        Hashtable of environment variables to export
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][hashtable]$Variables
    )
    
    $outputDir = Split-Path $Path -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $content = @"
# Alloy-Linux Toolchain Environment
# This file was auto-generated. Do not edit manually.
# Source this file before building: . `$PSScriptRoot\toolchain.env.ps1

"@
    
    foreach ($key in $Variables.Keys) {
        $value = $Variables[$key]
        # Escape single quotes in values
        $value = $value -replace "'", "''"
        $content += ('$env:' + $key + " = '$value'`n")
    }
    
    Set-Content -Path $Path -Value $content -Encoding UTF8
    Write-SuccessMessage "Toolchain environment exported to: $Path"
}

function Import-ToolchainEnv {
    <#
    .SYNOPSIS
        Import toolchain environment from a PowerShell env file
    
    .PARAMETER Path
        Path to toolchain.env.ps1 file
    #>
    param([Parameter(Mandatory)][string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "Toolchain environment file not found: $Path"
    }
    
    . $Path
}

# ============================================================================
# Validation
# ============================================================================

function Assert-DirectoryExists {
    <#
    .SYNOPSIS
        Assert that a directory exists, throw if it doesn't
    
    .PARAMETER Path
        Directory path to check
    
    .PARAMETER Description
        What this directory is for (for error message)
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Description = "Directory"
    )
    
    if (-not (Test-Path $Path -PathType Container)) {
        throw "$Description not found: $Path"
    }
}

function Assert-FileExists {
    <#
    .SYNOPSIS
        Assert that a file exists, throw if it doesn't
    
    .PARAMETER Path
        File path to check
    
    .PARAMETER Description
        What this file is for (for error message)
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Description = "File"
    )
    
    if (-not (Test-Path $Path -PathType Leaf)) {
        throw "$Description not found: $Path"
    }
}
