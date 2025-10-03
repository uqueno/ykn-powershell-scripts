# Fix-DockerWSL-Ubuntu2404.ps1
# Purpose: Fully reset WSL service, repair Ubuntu-24.04, reset Docker integration, and verify backend

Write-Host "=== Docker Desktop WSL Integration Repair for Ubuntu-24.04 ===" -ForegroundColor Cyan

# 1. Shut down all WSL instances
Write-Host "Shutting down all WSL instances..." -ForegroundColor Yellow
wsl --shutdown

# 2. Restart the WSL service engine
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
    $settings | ConvertTo-Json -Depth 10 | Set-Content $dockerSettingsPath -Encoding UTF8
    Write-Host "Disabled WSL integration for Ubuntu-24.04" -ForegroundColor Yellow

    # Re-enable Ubuntu-24.04
    $settings.wslEngine.enabledDistros += "Ubuntu-24.04"
    $settings | ConvertTo-Json -Depth 10 | Set-Content $dockerSettingsPath -Encoding UTF8
    Write-Host "Re-enabled WSL integration for Ubuntu-24.04" -ForegroundColor Yellow
} else {
    Write-Host "Docker Desktop settings.json not found. Skipping integration reset." -ForegroundColor Red
}

# 5. Start Ubuntu-24.04 and verify it launches
Write-Host "Starting Ubuntu-24.04..." -ForegroundColor Yellow
wsl --distribution Ubuntu-24.04 -- echo "WSL started successfully"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Ubuntu-24.04 started successfully." -ForegroundColor Green
} else {
    Write-Host "Failed to start Ubuntu-24.04. Please check the distro manually." -ForegroundColor Red
    exit 1
}

# 6. Verify Docker backend proxy inside WSL
Write-Host "Checking Docker backend proxy inside WSL..." -ForegroundColor Yellow
$proxyCheck = wsl --distribution Ubuntu-24.04 -- bash -c "pgrep -fa docker-desktop-proxy"
if ($proxyCheck) {
    Write-Host "Docker backend proxy is running inside WSL:" -ForegroundColor Green
    Write-Host $proxyCheck
} else {
    Write-Host "Docker backend proxy is NOT running. It will start when Docker Desktop launches." -ForegroundColor Red
}

# 7. Restart Docker Desktop if installed in default path
$dockerPath = "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    Write-Host "Restarting Docker Desktop..." -ForegroundColor Yellow
    Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
    Start-Process "$dockerPath"
} else {
    Write-Host "Docker Desktop not found in default location. Please restart it manually." -ForegroundColor Red
}

Write-Host "=== Repair & Verification Complete ===" -ForegroundColor Cyan
