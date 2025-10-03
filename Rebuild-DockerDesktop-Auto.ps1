#
# Chunk 1 — Parameters, Help, and Initial Setup
#
[CmdletBinding()]
param(
    [switch]$Help,
    [switch]$MyVerbose,
    [switch]$Interactive,
    [switch]$CloseDocker,
    [switch]$SkipInstall,
    [string[]]$EnableDistros = @("Ubuntu-24.04"),
    [switch]$ForceDownload
)

# If the script was invoked with no parameters/arguments, default to showing help.
# Use PSBoundParameters.Count and $args to detect truly empty invocation (works reliably for advanced scripts).
if (($PSBoundParameters.Count -eq 0) -and ($args.Count -eq 0)) {
    $Help = $true
}

function Show-Help {
    Write-Host "=== Docker Desktop Safe Rebuild Script ===" -ForegroundColor Cyan
    Write-Host "Quick usage:" -ForegroundColor Yellow
    Write-Host "  .\Rebuild-DockerDesktop-Auto.ps1 [-Help] [-MyVerbose] [-Interactive] [-CloseDocker] [-SkipInstall] [-EnableDistros <array>] [-ForceDownload]" -ForegroundColor White
    Write-Host ""
    Write-Host "Switches (detailed):" -ForegroundColor Yellow
    Write-Host "  -Help           Show this help message and exit." -ForegroundColor White
    Write-Host "  -MyVerbose      Enable additional informational logging for each step." -ForegroundColor White
    Write-Host "  -Interactive    Prompt to pick which WSL distros to enable for Docker integration." -ForegroundColor White
    Write-Host "  -CloseDocker    Close Docker Desktop after verification (useful for CI or scripted flows)." -ForegroundColor White
    Write-Host "  -SkipInstall    Skip download/install step. Use when installer is already present or only integration is required." -ForegroundColor White
    Write-Host "  -EnableDistros  Array of distro names to enable (default: 'Ubuntu-24.04'). Example: -EnableDistros @('Ubuntu-24.04','Ubuntu')" -ForegroundColor White
    Write-Host "  -ForceDownload  Force re-download of the Docker Desktop installer even if a cached installer exists." -ForegroundColor White
    Write-Host ""
    Write-Host "Behavior notes:" -ForegroundColor Yellow
    Write-Host "  - The script requires Administrator elevation for cleanup and service steps." -ForegroundColor White
    Write-Host "  - Docker Desktop first-run UI (EULA/sign-in) must be accepted in an interactive session. The script creates and runs a scheduled task to launch Docker Desktop in the interactive user session to allow those prompts." -ForegroundColor White
    Write-Host "  - If you run the full script elevated, the scheduled-task mechanism ensures the interactive UI runs in your logged-on session so settings.json is created in your profile." -ForegroundColor White
    Write-Host "  - The script supports enabling multiple WSL distros in the same run; pass an array to -EnableDistros." -ForegroundColor White
    Write-Host "  - The script operates on WSL integration (wslEngine settings). It does not change Docker's container mode (Windows vs Linux) or make Windows-native PowerShell a Docker engine." -ForegroundColor White
    Write-Host ""
    Write-Host "Common use cases (switch sets):" -ForegroundColor Yellow
    Write-Host "  1) Full reinstall with complete cleanup and fresh download" -ForegroundColor Cyan
    Write-Host "     - Purpose: Remove old settings/distros, download latest installer, install, enable integration, verify." -ForegroundColor White
    Write-Host "     - Command:" -ForegroundColor White
    Write-Host "         .\\Rebuild-DockerDesktop-Auto.ps1 -MyVerbose -EnableDistros @('Ubuntu-24.04') -ForceDownload" -ForegroundColor Green
    Write-Host ""
    Write-Host "  2) Reinstall & cleanup, but do not re-download installer if already cached" -ForegroundColor Cyan
    Write-Host "     - Purpose: Same as #1 but uses cached installer to save bandwidth/time." -ForegroundColor White
    Write-Host "     - Command:" -ForegroundColor White
    Write-Host "         .\\Rebuild-DockerDesktop-Auto.ps1 -MyVerbose -EnableDistros @('Ubuntu-24.04')" -ForegroundColor Green
    Write-Host ""
    Write-Host "  3) Only enable WSL integration + verification (no installer or uninstall)" -ForegroundColor Cyan
    Write-Host "     - Purpose: When Docker Desktop is already installed and you only need to enable distros or re-run proxy checks." -ForegroundColor White
    Write-Host "     - Command:" -ForegroundColor White
    Write-Host "         .\\Rebuild-DockerDesktop-Auto.ps1 -SkipInstall -MyVerbose -EnableDistros @('Ubuntu-24.04')" -ForegroundColor Green
    Write-Host ""
    Write-Host "  4) Interactive selection and then close Docker after verification" -ForegroundColor Cyan
    Write-Host "     - Purpose: Let the user pick distros interactively and have the script close Docker when finished." -ForegroundColor White
    Write-Host "     - Command:" -ForegroundColor White
    Write-Host "         .\\Rebuild-DockerDesktop-Auto.ps1 -Interactive -CloseDocker" -ForegroundColor Green
    Write-Host ""
    Write-Host "  5) Enable two (or more) distros in one run" -ForegroundColor Cyan
    Write-Host "     - Purpose: Enable integration for multiple WSL distros (example: Ubuntu-24.04 and Ubuntu)." -ForegroundColor White
    Write-Host "     - Command:" -ForegroundColor White
    Write-Host "         .\\Rebuild-DockerDesktop-Auto.ps1 -MyVerbose -EnableDistros @('Ubuntu-24.04','Ubuntu')" -ForegroundColor Green
    Write-Host ""
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "  - If the script times out waiting for settings.json, start Docker Desktop manually once in your interactive session and accept any prompts, then re-run with -SkipInstall if you only need integration." -ForegroundColor White
    Write-Host "  - Use -MyVerbose to see where the script is waiting or failing." -ForegroundColor White
    Write-Host ""
    Write-Host "Examples summary:" -ForegroundColor Yellow
    Write-Host "  Full reinstall:        .\\Rebuild-DockerDesktop-Auto.ps1 -MyVerbose -EnableDistros @('Ubuntu-24.04') -ForceDownload" -ForegroundColor White
    Write-Host "  Use cached installer:  .\\Rebuild-DockerDesktop-Auto.ps1 -MyVerbose -EnableDistros @('Ubuntu-24.04')" -ForegroundColor White
    Write-Host "  Skip install step:     .\\Rebuild-DockerDesktop-Auto.ps1 -SkipInstall -MyVerbose -EnableDistros @('Ubuntu-24.04')" -ForegroundColor White
    Write-Host "  Interactive + close:   .\\Rebuild-DockerDesktop-Auto.ps1 -Interactive -CloseDocker" -ForegroundColor White
    Write-Host "  Enable two distros:    .\\Rebuild-DockerDesktop-Auto.ps1 -MyVerbose -EnableDistros @('Ubuntu-24.04','Ubuntu')" -ForegroundColor White
}

if ($Help) { Show-Help; exit 0 }

# Fail-fast: convert non-terminating errors to terminating so script aborts automatically on failures.
$ErrorActionPreference = 'Stop'

# Global trap to print a helpful message and exit with non-zero code on any unhandled exception.
trap {
    Write-Host "Fatal error: $($_.Exception.Message)" -ForegroundColor Red
    if ($MyVerbose) { Write-Host "$($_.Exception | Out-String)" -ForegroundColor DarkGray }
    exit 1
}

function Write-StepLog($msg) { if ($MyVerbose) { Write-Host "[INFO] $msg" -ForegroundColor DarkGray } }

# New helper: unify Start-Process usage and error handling.
# - Avoids mixing NoNewWindow and WindowStyle.
# - Always Waits and returns the Process object (or throws on failure).
function Run-Process {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter()][object]$ArgumentList = $null,    # string or array
        [string]$WorkingDirectory = $null,
        [switch]$HiddenWindow
    )

    $argsList = @()
    if ($null -ne $ArgumentList) {
        if ($ArgumentList -is [System.Array]) { $argsList = $ArgumentList }
        else { $argsList = @($ArgumentList) }
    }

    $startInfo = @{
        FilePath     = $FilePath
        ArgumentList = $argsList
        Wait         = $true
        PassThru     = $true
    }
    if ($WorkingDirectory) { $startInfo.WorkingDirectory = $WorkingDirectory }
    if ($HiddenWindow) { $startInfo.WindowStyle = 'Hidden' }

    try {
        return Start-Process @startInfo
    } catch {
        # Avoid ambiguous interpolation when $FilePath contains ":" (e.g. "C:\...")
        Write-StepLog ("Run-Process failed for '{0}': {1}" -f $FilePath, $_.Exception.Message)
        throw
    }
}

# Ensure admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    exit 1
}

# Interactive distro selection
if ($Interactive) {
    $available = (wsl --list --quiet 2>$null) -split "\r?\n"
    if (-not $available) { Write-Host "No WSL distros found." -ForegroundColor Red; exit 1 }
    Write-Host "Available WSL distros:" -ForegroundColor Yellow
    $i = 1
    foreach ($d in $available) { Write-Host "[$i] $d"; $i++ }
    $selection = Read-Host "Enter numbers separated by commas"
    $EnableDistros = @()
    foreach ($num in $selection -split ",") {
        $idx = [int]$num - 1
        if ($idx -ge 0 -and $idx -lt $available.Count) { $EnableDistros += $available[$idx] }
    }
    if (-not $EnableDistros) { Write-Host "No valid distros selected." -ForegroundColor Red; exit 1 }
}

#
# Chunk 2 — Core Functions
#
function Stop-DockerProcesses {
    Write-Host "[STEP 1] Stopping Docker processes..." -ForegroundColor Yellow
    $processes = @("Docker Desktop", "com.docker.backend", "com.docker.service", "Docker Desktop.exe")
    foreach ($n in $processes) {
        $proc = Get-Process -Name $n -ErrorAction SilentlyContinue
        if ($proc) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-StepLog "Stopped process: $n"
        }
    }
    Start-Sleep -Seconds 5  # Increased delay to ensure full stop
}

function Remove-DockerWSLDistros {
    Write-Host "[STEP 2] Removing old Docker WSL distros..." -ForegroundColor Yellow
    $existing = (wsl --list --quiet 2>$null) -split "\r?\n"
    foreach ($d in @("docker-desktop", "docker-desktop-data")) {
        if ($existing -and ($existing -contains $d)) {
            wsl --terminate $d 2>$null
            wsl --unregister $d 2>$null
            Write-StepLog "Removed WSL distro: $d"
        } else {
            Write-StepLog "WSL distro not found: $d"
        }
    }
}

function Remove-PathSafe([string]$path) {
    if (-not (Test-Path $path)) { return }
    try {
        Remove-Item -Recurse -Force $path -ErrorAction Stop
        Write-StepLog "Removed $path"
    } catch {
        Write-StepLog "Could not remove $path completely: $($_.Exception.Message)"
    }
}

function Clear-DockerConfig {
    Write-Host "[STEP 3] Clearing old Docker Desktop settings..." -ForegroundColor Yellow
    foreach ($p in "$Env:APPDATA\Docker", "$Env:LOCALAPPDATA\Docker", "$Env:ProgramData\Docker") {
        if (Test-Path $p) {
            try {
                Remove-Item -Recurse -Force $p -ErrorAction Stop
                Write-StepLog "Removed $p"
            } catch {
                Write-StepLog "Failed to remove $p on first try: $($_.Exception.Message). Retrying..."
                Start-Sleep -Seconds 2
                try {
                    Remove-Item -Recurse -Force $p -ErrorAction Stop
                    Write-StepLog "Removed $p on retry"
                } catch {
                    Write-StepLog "Could not remove ${p}: $($_.Exception.Message)"
                }
            }
        } else {
            Write-StepLog "Path not found: $p"
        }
    }
}

function Get-DockerInstaller {
    Write-Host "[STEP 4] Downloading latest Docker Desktop installer..." -ForegroundColor Yellow
    $url = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $path = "$Env:TEMP\DockerDesktopInstaller.exe"
    if (-not $ForceDownload -and (Test-Path $path) -and ((Get-Item $path).Length -gt 5MB)) {
        Write-StepLog "Installer already present at $path"
        return $path
    }
    Invoke-WebRequest -Uri $url -OutFile $path
    Write-StepLog "Downloaded installer to $path"
    return $path
}

function Install-DockerDesktop([string]$installerPath) {
    Write-Host "[STEP 5] Installing Docker Desktop..." -ForegroundColor Yellow
    $srvc = @("install", "--quiet", "--accept-license")
    $proc = Run-Process -FilePath $installerPath -ArgumentList $srvc
    if ($proc.ExitCode -ne 0) {
        throw "Docker Desktop installer exited with code $($proc.ExitCode)"
    }
    Write-StepLog "Docker Desktop installation complete."
}

function Start-DockerPrivilegedService {
    Write-Host "[STEP 5a] Ensuring Docker privileged helper service is running..." -ForegroundColor Yellow
    $name = "com.docker.service"
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue

    if (-not $svc) {
        $svcExe = "$Env:ProgramFiles\Docker\Docker\com.docker.service"
        if (Test-Path $svcExe) {
            Write-StepLog "Service '$name' not found. Creating it."
            sc.exe create $name binPath= "\"$svcExe\"" start= demand DisplayName= "Docker Desktop Service" obj= "LocalSystem" | Out-Null
            Start-Sleep -Seconds 1
            $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        } else {
            Write-Host "Service binary not found at $svcExe. Reinstall/repair Docker Desktop." -ForegroundColor Red
            return
        }
    }

    try { Set-Service -Name $name -StartupType Manual } catch { Write-StepLog "Could not set startup type: $($_.Exception.Message)" }

    if ($svc.Status -ne 'Running') {
        try {
            Start-Service -Name $name -ErrorAction Stop
            Write-Host "Started $name." -ForegroundColor Green
        } catch {
            Write-Host "Failed to start ${name}: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-StepLog "$name already running."
    }
}

# New: Create and run a scheduled task that launches Docker Desktop in the interactive (non-elevated) user session.
# This is useful when the script is running elevated but Docker Desktop must complete first-run UI steps in the interactive session.
function Start-DockerInteractiveViaScheduledTask {
    param(
        [string]$TaskName = "DockerDesktop-Interactive-Launch-$env:USERNAME",
        [int]$CreateTimeoutSeconds = 10
    )

    Write-Host "[STEP 5b] Ensuring Docker Desktop is launched in the interactive user session via Scheduled Task..." -ForegroundColor Yellow

    $exe = Join-Path $Env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
    if (-not (Test-Path $exe)) {
        Write-Host ("Docker Desktop executable not found at: {0}" -f $exe) -ForegroundColor Red
        return $null
    }

    # If settings.json already exists for the current user, assume interactive init already happened.
    $userSettings = Join-Path $Env:APPDATA "Docker\settings.json"
    if (Test-Path $userSettings) {
        Write-StepLog ("Found existing settings.json at: {0}" -f $userSettings)
        return $null
    }

    # Prefer ScheduledTasks cmdlets (more reliable) when available
    if (Get-Command -Name Register-ScheduledTask -ErrorAction SilentlyContinue) {
        Write-StepLog ("Using ScheduledTasks cmdlets to create and run task: {0}" -f $TaskName)

        $action    = New-ScheduledTaskAction -Execute $exe
        $trigger   = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(8)
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

        try {
            Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Force
            Start-ScheduledTask -TaskName $TaskName
            Write-StepLog ("Scheduled task '{0}' registered and started via ScheduledTasks cmdlets." -f $TaskName)
            return $TaskName
        } catch {
            Write-StepLog ("ScheduledTasks cmdlets failed: {0}. Falling back to schtasks.exe." -f $_.Exception.Message)
            # fall through to schtasks fallback below
        }
    }

    # Fallback: use schtasks.exe (older environments). Use argument arrays to avoid quoting issues.
    Write-StepLog ("Falling back to schtasks.exe to create and run: {0}" -f $TaskName)
    $createArgs = @("/Create", "/TN", $TaskName, "/TR", $exe, "/RL", "LIMITED", "/SC", "ONCE", "/ST", "00:00", "/F", "/RU", $env:USERNAME)
    try {
        $createProc = Run-Process -FilePath "schtasks.exe" -ArgumentList $createArgs -HiddenWindow
    } catch {
        Write-StepLog ("schtasks create threw an exception: {0}" -f $_.Exception.Message)
        $createProc = $null
    }

    if ($createProc -and $createProc.ExitCode -ne 0) {
        Write-StepLog ("schtasks create returned exit code {0}. Attempting fallback create without explicit /RU." -f $createProc.ExitCode)
        $createArgs2 = @("/Create", "/TN", $TaskName, "/TR", $exe, "/RL", "LIMITED", "/SC", "ONCE", "/ST", "00:00", "/F")
        try {
            $fallback = Run-Process -FilePath "schtasks.exe" -ArgumentList $createArgs2 -HiddenWindow
            if ($fallback.ExitCode -ne 0) { throw ("schtasks fallback create failed with exit code {0}" -f $fallback.ExitCode) }
        } catch {
            Write-Host ("Failed to create scheduled task: {0}" -f $_.Exception.Message) -ForegroundColor Red
            throw
        }
    }

    Start-Sleep -Seconds 1

    Write-StepLog ("Running scheduled task: {0}" -f $TaskName)
    try {
        Run-Process -FilePath "schtasks.exe" -ArgumentList @("/Run", "/TN", $TaskName) -HiddenWindow | Out-Null
    } catch {
        Write-Host ("Failed to run scheduled task '{0}': {1}" -f $TaskName, $_.Exception.Message) -ForegroundColor Red
        throw
    }

    # Give a short grace period for the task to start an interactive process
    Start-Sleep -Seconds 3

    return $TaskName
}

# Modified Wait-SettingsJson: accept a flag to skip starting Docker from the elevated context.
function Wait-SettingsJson {
    param([switch]$SkipStart)

    Write-Host "[STEP 5c] Waiting for Docker Desktop to initialize settings (settings.json)..." -ForegroundColor Yellow

    $exe = Join-Path $Env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
    if (-not (Test-Path $exe)) {
        Write-Host ("Docker Desktop executable not found at: {0}" -f $exe) -ForegroundColor Red
        exit 1
    }

    if (-not $SkipStart) {
        # Start Docker Desktop if not already running (legacy behavior; may start elevated instance)
        $dockerProc = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
        if (-not $dockerProc) {
            Write-StepLog ("Starting Docker Desktop process: {0}" -f $exe)
            Run-Process -FilePath $exe -WorkingDirectory (Split-Path $exe)
            Start-Sleep -Seconds 3
        }
    } else {
        Write-StepLog "Skipping elevated start of Docker Desktop; waiting for interactive session to create settings.json."
    }

    # Candidate locations to check for settings.json (current user, all profiles, systemprofile)
    $candidates = @()
    $candidates += (Join-Path $Env:APPDATA "Docker\settings.json")
    $candidates += (Join-Path $Env:LOCALAPPDATA "Docker\settings.json")

    # Look across all user profiles (helps when the interactive process wrote settings in another profile)
    $userProfiles = Get-ChildItem -Path C:\Users -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    foreach ($p in $userProfiles) {
        $candidates += (Join-Path $p "AppData\Roaming\Docker\settings.json")
        $candidates += (Join-Path $p "AppData\Local\Docker\settings.json")
    }

    # include systemprofile as well
    $candidates += (Join-Path "C:\Windows\System32\config\systemprofile\AppData\Roaming" "Docker\settings.json")
    $candidates = $candidates | Select-Object -Unique

    $timeout = (Get-Date).AddMinutes(7)
    while ((Get-Date) -lt $timeout) {
        foreach ($p in $candidates) {
            if (Test-Path $p) {
                Write-StepLog ("Found settings.json at: {0}" -f $p)
                return $p
            }
        }

        # If Docker Desktop process isn't running in this session, note and continue waiting
        $dockerProc = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
        if (-not $dockerProc) {
            Write-StepLog "Docker Desktop process not found in this session. Waiting for interactive launch..."
        }

        Start-Sleep -Seconds 5
    }

    Write-Host "Timed out waiting for settings.json. Common causes:" -ForegroundColor Red
    Write-Host " - Docker Desktop requires interactive acceptance of license or sign-in." -ForegroundColor DarkYellow
    Write-Host " - Docker Desktop may be running in a different user session than this elevated script." -ForegroundColor DarkYellow
    Write-Host "Workarounds:" -ForegroundColor Yellow
    Write-Host " - Start Docker Desktop manually in the interactive user session and accept prompts, then re-run this script." -ForegroundColor Yellow
    Write-Host " - Or run the launch/wait part of this script as the normal user (non-elevated)." -ForegroundColor Yellow
    exit 1
}

#
# Chunk 3 — Integration, Verification, and Main
#
function Enable-WSLIntegration([string]$settingsPath, [string[]]$distros) {
    Write-Host "[STEP 6] Enabling WSL integration..." -ForegroundColor Yellow
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    if (-not $settings.wslEngine) { $settings | Add-Member -MemberType NoteProperty -Name wslEngine -Value @{} }
    if (-not $settings.wslEngine.enabledDistros) { $settings.wslEngine | Add-Member -MemberType NoteProperty -Name enabledDistros -Value @() }
    $existing = (wsl --list --quiet 2>$null) -split "\r?\n"
    foreach ($d in $distros) {
        if ($existing -contains $d) {
            if ($settings.wslEngine.enabledDistros -notcontains $d) {
                $settings.wslEngine.enabledDistros += $d
                Write-Host "Enabled WSL integration for: $d" -ForegroundColor Green
            } else {
                Write-StepLog "Already enabled: $d"
            }
        } else {
            Write-Host "WSL distro not found, skipping: $d" -ForegroundColor DarkYellow
        }
    }
    $settings | ConvertTo-Json -Depth 12 | Set-Content $settingsPath -Encoding UTF8
}

function Test-DockerProxy([string[]]$distros) {
    Write-Host "[STEP 7] Verifying docker-desktop-proxy in enabled distros..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    foreach ($d in $distros) {
        Write-Host "Checking in distro: $d" -ForegroundColor Cyan

        $proxyPathCheck = wsl --distribution $d -- bash -c "ls /mnt/wsl/docker-desktop/docker-desktop-proxy 2>/dev/null"
        if (-not $proxyPathCheck) {
            Write-Host "docker-desktop-proxy not found in $d - initialization may have failed." -ForegroundColor Red
            continue
        }

        Write-Host "docker-desktop-proxy binary found." -ForegroundColor Green
        $null = wsl --distribution $d -- bash -c "/mnt/wsl/docker-desktop/docker-desktop-proxy --help >/dev/null 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "docker-desktop-proxy executed successfully in $d." -ForegroundColor Green
        } else {
            Write-Host "docker-desktop-proxy exists but failed to run in $d." -ForegroundColor Red
        }
    }
}

function Stop-DockerIfRequested {
    param([bool]$close)
    if (-not $close) { return }
    Write-Host "[STEP 8] Closing Docker Desktop..." -ForegroundColor Yellow
    foreach ($n in "Docker Desktop", "com.docker.backend", "com.docker.service") {
        Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "Docker Desktop closed." -ForegroundColor Green
}

# ===================== Main =====================
Write-Host "=== Docker Desktop Safe Rebuild Script with Verification ===" -ForegroundColor Cyan

Stop-DockerProcesses
Remove-DockerWSLDistros
Clear-DockerConfig

if (-not $SkipInstall) {
    $installer = Get-DockerInstaller
    Install-DockerDesktop -installerPath $installer
}

Start-DockerPrivilegedService

# Attempt to launch Docker Desktop in the interactive user session via a scheduled task.
# This ensures first-run UI (EULA/sign-in/permissions) can be accepted by the interactive session.
$taskName = Start-DockerInteractiveViaScheduledTask

# Wait for settings.json to appear. If we used the scheduled task, avoid starting Docker from the elevated session.
if ($taskName) {
    $settingsPath = Wait-SettingsJson -SkipStart
    # Cleanup scheduled task (best-effort)
    if ($taskName) {
        Write-StepLog "Removing scheduled task: $taskName"
        Run-Process -FilePath "schtasks.exe" -ArgumentList @("/Delete","/TN",$taskName,"/F") -HiddenWindow | Out-Null
    }
} else {
    # No scheduled task created (either settings.json already existed or interactive launch not needed),
    # fall back to previous behavior: attempt to start Docker from this context and wait.
    $settingsPath = Wait-SettingsJson
}

# Proceed with integration and verification using the discovered settings.json
Enable-WSLIntegration -settingsPath $settingsPath -distros $EnableDistros
Test-DockerProxy -distros $EnableDistros
Stop-DockerIfRequested -close $CloseDocker

# ensure final output uses consistent quoting
Write-Host "=== Done ===" -ForegroundColor Cyan
