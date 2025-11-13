$ErrorActionPreference = 'Stop'

$packageName = 'projwarp'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = 'https://github.com/ricky-ultimate/projwarp/releases/download/v0.1.0/projwarp-v0.1.0-x86_64-pc-windows-msvc.zip'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  url64bit      = $url64
  checksum64    = 'CHECKSUM_HERE'
  checksumType64= 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

# Add proj function to PowerShell profile
$profileScript = @'

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

# Add to profile if not already there
$profilePath = $PROFILE
if (Test-Path $profilePath) {
    $content = Get-Content $profilePath -Raw
    if ($content -notmatch 'function proj') {
        Add-Content $profilePath "`n$profileScript"
        Write-Host "Added 'proj' function to PowerShell profile" -ForegroundColor Green
    }
} else {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Add-Content $profilePath $profileScript
    Write-Host "Created PowerShell profile and added 'proj' function" -ForegroundColor Green
}

Write-Host "`nInstallation complete! Restart your terminal or run: . `$PROFILE" -ForegroundColor Cyan
