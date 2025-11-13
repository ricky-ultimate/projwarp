$ErrorActionPreference = 'Stop'

# Remove proj function from PowerShell profile
$profilePath = $PROFILE
if (Test-Path $profilePath) {
    $content = Get-Content $profilePath -Raw
    if ($content -match '(?s)# projwarp - Project navigation tool.*?^}') {
        $newContent = $content -replace '(?s)\r?\n?# projwarp - Project navigation tool.*?^}', ''
        Set-Content $profilePath $newContent.Trim()
        Write-Host "Removed 'proj' function from PowerShell profile" -ForegroundColor Green
    }
}

# Ask about removing config
$configPath = Join-Path $env:USERPROFILE ".projwarp.json"
if (Test-Path $configPath) {
    Write-Host "`nYour project configuration is stored at: $configPath" -ForegroundColor Yellow
    Write-Host "You can manually delete it if you wish to remove all project data." -ForegroundColor Yellow
}

Write-Host "`nUninstallation complete! Please restart your terminal." -ForegroundColor Cyan
