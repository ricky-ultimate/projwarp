#Requires -Version 5.1

<#
.SYNOPSIS
    Installs projwarp CLI tool and configures PowerShell profile
.DESCRIPTION
    This script installs the projwarp binary and adds the proj wrapper function to your PowerShell profile

.PARAMETER Uninstall
    Uninstalls projwarp and removes shell integration

.NOTES
    If you get an execution policy error, run:
    Unblock-File -Path .\install.ps1
    Or: powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
    .\install.ps1
    Installs projwarp

.EXAMPLE
    .\install.ps1 -Uninstall
    Uninstalls projwarp
#>
param(
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Failure { Write-Host $args -ForegroundColor Red }

# Configuration
$InstallDir = Join-Path $env:LOCALAPPDATA "projwarp"
$BinaryName = "projwarp.exe"
$BinaryPath = Join-Path $InstallDir $BinaryName

$ProjFunction = @'

# projwarp - Project navigation tool
function proj {
    param(
        [Parameter(Position = 0)]
        [string]$name,
        [Parameter(Position = 1)]
        [string]$secondArg,
        [Parameter(Position = 2)]
        [string]$thirdArg,
        [switch]$code,
        [string]$alias
    )

    $previousOutputEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    try {
        if (-not $name) {
            Write-Host "Usage:" -ForegroundColor Cyan
            Write-Host "  proj add [-alias <n>]         Add current directory"
            Write-Host "  proj remove <alias>           Remove a project alias"
            Write-Host "  proj rename <old> <new>       Rename a project alias"
            Write-Host "  proj list                     List all projects"
            Write-Host "  proj <n> [-code]              Jump to project or open in VS Code"
            return
        }

        if ($name -eq "add") {
            if ($alias) {
                & projwarp add --alias $alias
            } else {
                & projwarp add
            }
            return
        }

        if ($name -eq "remove" -or $name -eq "rm") {
            if ($secondArg) {
                & projwarp remove $secondArg
            } elseif ($alias) {
                & projwarp remove $alias
            } else {
                Write-Host "Usage: proj remove <alias>" -ForegroundColor Yellow
            }
            return
        }

        if ($name -eq "rename" -or $name -eq "mv") {
            if ($thirdArg) {
                & projwarp rename $secondArg $thirdArg
            } elseif ($secondArg -and $alias) {
                & projwarp rename $secondArg $alias
            } else {
                Write-Host "Usage: proj rename <old> <new>" -ForegroundColor Yellow
            }
            return
        }

        if ($name -eq "list") {
            & projwarp list
            return
        }

        if ($code) {
            $output = & projwarp go $name 2>&1 | Out-String
            $output = $output.Trim()

            if ($output -and $output -notmatch "No match found") {
                if (Test-Path $output) {
                    & code $output
                    Write-Host "Opening '$output' in VS Code..." -ForegroundColor Green
                } else {
                    Write-Host "Path exists in config but not on disk: $output" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Project '$name' not found." -ForegroundColor Red
            }
        } else {
            $output = & projwarp go $name 2>&1 | Out-String
            $output = $output.Trim()

            if ($output -and $output -notmatch "No match found") {
                if (Test-Path $output) {
                    Set-Location $output
                    Write-Host "Jumped to: $output" -ForegroundColor Green
                } else {
                    Write-Host "Path exists in config but not on disk: $output" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Project '$name' not found." -ForegroundColor Red
            }
        }
    } finally {
        [Console]::OutputEncoding = $previousOutputEncoding
    }
}
'@

function Install-Projwarp {
    Write-Info "Installing projwarp..."

    # Check if binary exists in current directory
    if (-not (Test-Path ".\target\release\$BinaryName")) {
        Write-Failure "Error: Binary not found at .\target\release\$BinaryName"
        Write-Info "Please run 'cargo build --release' first"
        exit 1
    }

    # Create install directory
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        Write-Success "Created installation directory: $InstallDir"
    }

    # Copy binary
    Copy-Item ".\target\release\$BinaryName" $BinaryPath -Force
    Write-Success "Installed binary to: $BinaryPath"

    # Add to PATH if not already there
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$userPath;$InstallDir",
            "User"
        )
        $env:Path += ";$InstallDir"
        Write-Success "Added to PATH"
    } else {
        Write-Info "Already in PATH"
    }

    # Setup PowerShell profile
    $profilePath = $PROFILE

    # Create profile if it doesn't exist
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
        Write-Success "Created PowerShell profile: $profilePath"
    }

    # Check if proj function already exists
    $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

    if ($profileContent -like "*function proj*") {
        Write-Warning "'proj' function already exists in profile"
        $response = Read-Host "Do you want to replace it? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "Skipping profile modification"
        } else {
            # Remove old function and add new one
            $profileContent = $profileContent -replace '(?s)# projwarp.*?^}', ''
            $profileContent = $profileContent.Trim()
            Set-Content $profilePath "$profileContent`n$ProjFunction"
            Write-Success "Updated PowerShell profile"
        }
    } else {
        Add-Content $profilePath "`n$ProjFunction"
        Write-Success "Added 'proj' function to PowerShell profile"
    }

    Write-Success "`nInstallation complete!"
    Write-Info "`nTo start using projwarp:"
    Write-Info "  1. Restart your terminal (or run: . `$PROFILE)"
    Write-Info "  2. Navigate to a project directory"
    Write-Info "  3. Run: proj add"
    Write-Info "  4. From anywhere: proj <project-name>"
    Write-Info "`nRun 'proj' for help"
}

function Uninstall-Projwarp {
    Write-Info "Uninstalling projwarp..."

    # Remove binary
    if (Test-Path $BinaryPath) {
        Remove-Item $BinaryPath -Force
        Write-Success "Removed binary"
    }

    # Remove from PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -like "*$InstallDir*") {
        $newPath = ($userPath -split ';' | Where-Object { $_ -ne $InstallDir }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Success "Removed from PATH"
    }

    # Remove install directory
    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force
        Write-Success "Removed installation directory"
    }

    # Remove from profile
    $profilePath = $PROFILE
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        if ($profileContent -like "*function proj*") {
            $profileContent = $profileContent -replace '(?s)\r?\n?# projwarp.*?^}', ''
            $profileContent = $profileContent.Trim()
            Set-Content $profilePath $profileContent
            Write-Success "✓ Removed from PowerShell profile"
        }
    }

    # Remove config file
    $configPath = Join-Path $env:USERPROFILE ".projwarp.json"
    if (Test-Path $configPath) {
        $response = Read-Host "Remove project configuration (~/.projwarp.json)? (y/N)"
        if ($response -eq "y" -or $response -eq "Y") {
            Remove-Item $configPath -Force
            Write-Success "✓ Removed configuration file"
        }
    }

    Write-Success "`nUninstallation complete!"
    Write-Info "Please restart your terminal for changes to take effect"
}

# Main
try {
    if ($Uninstall) {
        Uninstall-Projwarp
    } else {
        Install-Projwarp
    }
} catch {
    Write-Failure "`nInstallation failed: $_"
    exit 1
}
