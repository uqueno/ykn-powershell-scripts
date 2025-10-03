# Restart-Ubuntu2404WSL-WithDockerIntegration.ps1
# Purpose: Restart WSL service engine, Ubuntu-24.04 distro, and reset Docker Desktop WSL integration

Write-Host "=== Restarting WSL Service Engine and Resetting Docker Integration ===" -ForegroundColor Cyan

# 1. Shut down all WSL instances
wsl --shutdown

# 2. Restart the LxssManager service
Write-Host "Restarting LxssManager service..." -ForegroundColor Yellow
Stop-Service -Name LxssManager -Force
Start-Service -Name LxssManager

# 3. Update WSL core
Write-Host "Updating WSL core..." -ForegroundColor Yellow
wsl --update

# 4. Locate Docker Desktop settings.json
$dockerSettingsPath = "$Env:APPDATA\Docker\settings.json"

if (Test-Path $dockerSettingsPath) {
    Write-Host "Found Docker Desktop settings.json at $dockerSettingsPath" -ForegroundColor Green

    # Backup original settings
    $backupPath = "$dockerSettingsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $dockerSettingsPath $backupPath
    Write-Host "Backup created at $backupPath" -ForegroundColor Green

    # Read and parse JSON
    $settings = Get-Content $dockerSettingsPath -Raw | ConvertFrom-Json

    # Ensure WSL integration section exists
    if (-not $settings.wslEngine) {
        $settings | Add-Member -MemberType NoteProperty -Name wslEngine -Value @{}
    }
    if (-not $settings.wslEngine.enabledDistros) {
        $settings.wslEngine | Add-Member -MemberType NoteProperty -Name enabledDistros -Value @()
    }

    # Disable Ubuntu-24.04
    $settings.wslEngine.enabledDistros = $settings.wslEngine.enabledDistros | Where-Object { $_ -ne "Ubuntu-24.04" }
    Write-Host "Disabled WSL integration for Ubuntu-24.04" -ForegroundColor Yellow

    # Save changes
    $settings | ConvertTo-Json -Depth 10 | Set-Content $dockerSettingsPath -Encoding UTF8

    # Re-enable Ubuntu-24.04
    $settings.wslEngine.enabledDistros += "Ubuntu-24.04"
    $settings | ConvertTo-Json -Depth 10 | Set-Content $dockerSettingsPath -Encoding UTF8
    Write-Host "Re-enabled WSL integration for Ubuntu-24.04" -ForegroundColor Yellow
} else {
    Write-Host "Docker Desktop settings.json not found. Skipping integration reset." -ForegroundColor Red
}

# 5. Start Ubuntu-24.04 distro
Write-Host "Starting Ubuntu-24.04..." -ForegroundColor Yellow
wsl --distribution Ubuntu-24.04

# 6. Restart Docker Desktop if installed in default path
$dockerPath = "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    Write-Host "Restarting Docker Desktop..." -ForegroundColor Yellow
    Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
    Start-Process "$dockerPath"
} else {
    Write-Host "Docker Desktop not found in default location. Please restart it manually." -ForegroundColor Red
}

Write-Host "=== WSL and Docker integration reset complete ===" -ForegroundColor Green
