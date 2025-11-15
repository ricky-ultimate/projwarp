#Requires -Version 5.1

<#
.SYNOPSIS
    Quick installer for projwarp - downloads and installs automatically
.DESCRIPTION
    Downloads the latest projwarp release and installs it with shell integration
#>

param(
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Failure { Write-Host $args -ForegroundColor Red }

$repo = "ricky-ultimate/projwarp"
$InstallDir = Join-Path $env:LOCALAPPDATA "projwarp"
$BinaryPath = Join-Path $InstallDir "projwarp.exe"

Write-Info "Installing projwarp..."

try {
    # Get latest release info
    if ($Version -eq "latest") {
        Write-Info "Fetching latest release..."
        $release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
        $Version = $release.tag_name
    }

    Write-Info "Installing version: $Version"

    # Download URL
    $downloadUrl = "https://github.com/$repo/releases/download/$Version/projwarp-$Version-x86_64-pc-windows-msvc.zip"
    $tempZip = Join-Path $env:TEMP "projwarp.zip"
    $tempExtract = Join-Path $env:TEMP "projwarp-extract"

    # Download
    Write-Info "Downloading from GitHub..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing

    # Extract
    Write-Info "Extracting..."
    if (Test-Path $tempExtract) {
        Remove-Item $tempExtract -Recurse -Force
    }
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

    # Find the binary
    $exePath = Get-ChildItem -Path $tempExtract -Filter "projwarp.exe" -Recurse | Select-Object -First 1

    if (-not $exePath) {
        throw "Binary not found in downloaded archive"
    }

    # Create install directory
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    # Copy binary
    Copy-Item $exePath.FullName $BinaryPath -Force
    Write-Success "Installed binary to: $BinaryPath"

    # Add to PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
        $env:Path += ";$InstallDir"
        Write-Success "Added to PATH"
    } else {
        Write-Info "Already in PATH"
    }

    # Setup PowerShell profile
    $profilePath = $PROFILE
    $projFunction = @'

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
            if ($alias) { & projwarp add --alias $alias }
            else { & projwarp add }
            return
        }

        if ($name -eq "remove" -or $name -eq "rm") {
            if ($secondArg) { & projwarp remove $secondArg }
            elseif ($alias) { & projwarp remove $alias }
            else { Write-Host "Usage: proj remove <alias>" -ForegroundColor Yellow }
            return
        }

        if ($name -eq "rename" -or $name -eq "mv") {
            if ($thirdArg) { & projwarp rename $secondArg $thirdArg }
            elseif ($secondArg -and $alias) { & projwarp rename $secondArg $alias }
            else { Write-Host "Usage: proj rename <old> <new>" -ForegroundColor Yellow }
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

    # Create profile if it doesn't exist
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
        Write-Success "Created PowerShell profile"
    }

    # Add or update function
    $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($profileContent -like "*function proj*") {
        Write-Info "'proj' function already exists in profile"
        $response = Read-Host "Replace with latest version? (y/N)"
        if ($response -eq "y" -or $response -eq "Y") {
            $profileContent = $profileContent -replace '(?s)# projwarp.*?^}', ''
            $profileContent = $profileContent.Trim()
            Set-Content $profilePath "$profileContent`n$projFunction"
            Write-Success "Updated PowerShell profile"
        }
    } else {
        Add-Content $profilePath "`n$projFunction"
        Write-Success "Added 'proj' function to PowerShell profile"
    }

    # Cleanup
    Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

    Write-Success "`n✓ Installation complete!"
    Write-Info "`nQuick start:"
    Write-Info "  1. Restart your terminal (or run: . `$PROFILE)"
    Write-Info "  2. Navigate to a project: cd C:\path\to\my-project"
    Write-Info "  3. Register it: proj add"
    Write-Info "  4. Jump from anywhere: proj my-project"
    Write-Info "`nRun 'proj' to see all commands"

} catch {
    Write-Failure "`nInstallation failed: $_"
    Write-Info "`nTry manual installation:"
    Write-Info "  1. Download from: https://github.com/$repo/releases"
    Write-Info "  2. Extract and run: .\install.ps1"
    exit 1
}
