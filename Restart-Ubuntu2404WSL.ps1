# Restart-Ubuntu2404WSL.ps1
# Purpose: Restart WSL service engine and Ubuntu-24.04 distro for Docker Desktop

Write-Host "=== Restarting WSL Service Engine ===" -ForegroundColor Cyan

# Stop all running WSL instances
wsl --shutdown

# Restart the LxssManager service (WSL host service)
Write-Host "Restarting LxssManager service..." -ForegroundColor Yellow
Stop-Service -Name LxssManager -Force
Start-Service -Name LxssManager

# Update WSL to latest version (optional but recommended)
Write-Host "Updating WSL core..." -ForegroundColor Yellow
wsl --update

# Restart the Ubuntu-24.04 distro
Write-Host "Starting Ubuntu-24.04..." -ForegroundColor Yellow
wsl --distribution Ubuntu-24.04

# Optional: Restart Docker Desktop (if installed in default path)
$dockerPath = "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerPath) {
    Write-Host "Restarting Docker Desktop..." -ForegroundColor Yellow
    Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
    Start-Process "$dockerPath"
} else {
    Write-Host "Docker Desktop not found in default location. Please restart it manually." -ForegroundColor Red
}

Write-Host "=== WSL and Docker restart complete ===" -ForegroundColor Green
