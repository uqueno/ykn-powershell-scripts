<#
.SYNOPSIS
One-shot rebuild of Docker Desktop with WSL integration reset for Ubuntu-24.04.
#>

Write-Host "=== Docker Desktop Full Rebuild Script ===" -ForegroundColor Cyan

# 1. Terminate and unregister broken Docker WSL distros
Write-Host "[STEP 1] Removing old Docker WSL distros..." -ForegroundColor Yellow
wsl --terminate docker-desktop 2>$null
wsl --terminate docker-desktop-data 2>$null
wsl --unregister docker-desktop 2>$null
wsl --unregister docker-desktop-data 2>$null
Write-Host "Old Docker WSL distros removed." -ForegroundColor Green

# 2. Remove leftover Docker Desktop settings to clear popup message
Write-Host "[STEP 2] Clearing old Docker Desktop settings..." -ForegroundColor Yellow
$dockerConfigPaths = @(
    "$Env:APPDATA\Docker",
    "$Env:LOCALAPPDATA\Docker",
    "$Env:ProgramData\Docker"
)
foreach ($path in $dockerConfigPaths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path
        Write-Host "Removed $path" -ForegroundColor Green
    }
}

# 3. Download latest Docker Desktop installer
Write-Host "[STEP 3] Downloading latest Docker Desktop installer..." -ForegroundColor Yellow
$installerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$installerPath = "$Env:TEMP\DockerDesktopInstaller.exe"
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
Write-Host "Downloaded installer to $installerPath" -ForegroundColor Green

# 4. Install Docker Desktop silently
Write-Host "[STEP 4] Installing Docker Desktop..." -ForegroundColor Yellow
Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet" -Wait
Write-Host "Docker Desktop installation complete." -ForegroundColor Green

# 5. Enable WSL integration for Ubuntu-24.04
Write-Host "[STEP 5] Enabling WSL integration for Ubuntu-24.04..." -ForegroundColor Yellow
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

Write-Host "=== Docker Desktop Rebuild Complete ===" -ForegroundColor Cyan
Write-Host "You may now launch Docker Desktop from the Start Menu." -ForegroundColor Yellow
