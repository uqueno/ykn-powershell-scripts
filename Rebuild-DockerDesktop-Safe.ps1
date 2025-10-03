<#
.SYNOPSIS
Safe rebuild of Docker Desktop with WSL integration reset for Ubuntu-24.04,
including verification of docker-desktop-proxy after install.
#>

# Stop on any unhandled error
$ErrorActionPreference = 'Stop'

Write-Host "=== Docker Desktop Safe Rebuild Script with Verification ===" -ForegroundColor Cyan

# 0. Ensure running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    exit 1
}

# 1. Stop Docker processes
Write-Host "[STEP 1] Stopping Docker processes..." -ForegroundColor Yellow
$dockerProcs = "Docker Desktop", "com.docker.backend", "com.docker.service"
foreach ($proc in $dockerProcs) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Stopping process: $($_.Name)" -ForegroundColor Green
        Stop-Process -Id $_.Id -Force
    }
}
Start-Sleep -Seconds 2

# 2. Remove old Docker WSL distros
Write-Host "[STEP 2] Removing old Docker WSL distros..." -ForegroundColor Yellow
$distros = "docker-desktop", "docker-desktop-data"
foreach ($distro in $distros) {
    if ((wsl --list --quiet) -contains $distro) {
        wsl --terminate $distro
        wsl --unregister $distro
        Write-Host "Removed WSL distro: $distro" -ForegroundColor Green
    } else {
        Write-Host "WSL distro not found: $distro" -ForegroundColor Gray
    }
}

# 3. Remove leftover Docker config
Write-Host "[STEP 3] Clearing old Docker Desktop settings..." -ForegroundColor Yellow
$dockerConfigPaths = @(
    "$Env:APPDATA\Docker",
    "$Env:LOCALAPPDATA\Docker",
    "$Env:ProgramData\Docker"
)
foreach ($path in $dockerConfigPaths) {
    if (Test-Path $path) {
        try {
            Remove-Item -Recurse -Force $path
            Write-Host "Removed $path" -ForegroundColor Green
        }
        catch {
            Write-Host "Could not remove $path completely: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Path not found: $path" -ForegroundColor Gray
    }
}

# 4. Download latest Docker Desktop installer
Write-Host "[STEP 4] Downloading latest Docker Desktop installer..." -ForegroundColor Yellow
$installerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$installerPath = "$Env:TEMP\DockerDesktopInstaller.exe"
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
Write-Host "Downloaded installer to $installerPath" -ForegroundColor Green

# 5. Install Docker Desktop silently
Write-Host "[STEP 5] Installing Docker Desktop..." -ForegroundColor Yellow
Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet" -Wait
Write-Host "Docker Desktop installation complete." -ForegroundColor Green

# 6. Enable WSL integration for Ubuntu-24.04
Write-Host "[STEP 6] Enabling WSL integration for Ubuntu-24.04..." -ForegroundColor Yellow
$settingsPath = "$Env:APPDATA\Docker\settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    if (-not $settings.wslEngine) {
        $settings | Add-Member -MemberType NoteProperty -Name wslEngine -Value @{}
    }
    if (-not $settings.wslEngine.enabledDistros) {
        $settings.wslEngine | Add-Member -MemberType NoteProperty -Name enabledDistros -Value @()
    }
    if ($settings.wslEngine.enabledDistros -notcontains "Ubuntu-24.04") {
        $settings.wslEngine.enabledDistros += "Ubuntu-24.04"
    }
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "WSL integration enabled for Ubuntu-24.04." -ForegroundColor Green
}
else {
    Write-Host "Docker settings.json not found — please enable WSL integration manually after first launch." -ForegroundColor Red
}

# 7. Verification
Write-Host "[STEP 7] Verifying docker-desktop-proxy..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
$proxyPathCheck = wsl --distribution Ubuntu-24.04 -- bash -c 'ls /mnt/wsl/docker-desktop/docker-desktop-proxy 2>/dev/null'
if ($proxyPathCheck) {
    Write-Host "docker-desktop-proxy binary found." -ForegroundColor Green
    wsl --distribution Ubuntu-24.04 -- bash -c '/mnt/wsl/docker-desktop/docker-desktop-proxy --help 2>&1'
    if ($LASTEXITCODE -eq 0) {
        Write-Host "docker-desktop-proxy executed successfully." -ForegroundColor Green
    } else {
        Write-Host "docker-desktop-proxy exists but failed to run." -ForegroundColor Red
    }
} else {
    Write-Host "docker-desktop-proxy binary NOT found — initialization may have failed." -ForegroundColor Red
}

Write-Host "=== Docker Desktop Safe Rebuild Complete ===" -ForegroundColor Cyan
