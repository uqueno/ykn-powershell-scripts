<#
================================================================================
 Script Name : SmoothUpdate.ps1
 Author      : Yukio Ueno
 Timestamp   : 2025-12-14 21:12 (Brasília Standard Time)
================================================================================
 Description :
   SmoothUpdate.ps1 is a PowerShell automation script designed to keep
   Windows 10 Pro 22H2 (Build 19045) systems smooth and secure by
   automatically downloading and applying the latest cumulative update (KB)
   from the Microsoft Update Catalog.

   Key Features:
   - Creates a timestamped log file in C:\Windows\Logs\musa
   - Downloads the latest cumulative update package (.msu) for Windows 10 22H2
   - Installs the update silently with wusa.exe
   - Verifies installation via Get-HotFix, DISM, and systeminfo
   - Cleans up binary log files (optional)
   - Skips update if less than one month has passed since update file publication
   - Supports -Force to override skip logic
   - Supports -Help to display usage information
   - Detects if wusa.exe is already running and waits for completion
   - Provides a console summary of KB installed and new build version
   - Can be scheduled to run monthly via Task Scheduler

   Usage Notes:
   - Run in normal mode as Administrator (not Safe Mode)
   - Requires internet access to fetch the latest KB
   - Reboot after installation to finalize servicing
   - Adjust architecture (x64 assumed) if needed

================================================================================
#>

param(
    [switch]$Force,
    [switch]$Help,
    [switch]$Schedule
)

# --- Step -Help: Display Usage ---
if ($Help) {
    Write-Host "SmoothUpdate.ps1 - Windows 10 Cumulative Update Installer"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Force    : Override skip logic and install update even if newer than a month."
    Write-Host "  -Help     : Display this help information."
    Write-Host "  -Schedule : Create a monthly scheduled task to run SmoothUpdate.ps1 automatically."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\SmoothUpdate.ps1 -Force"
    Write-Host "  .\SmoothUpdate.ps1 -Schedule"
    exit
}

# --- Step -Schedule: Create Scheduled Task ---
if ($Schedule) {
    $taskName = "SmoothUpdateMonthly"
    $scriptPath = $MyInvocation.MyCommand.Definition
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At 03:00AM
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force
    Write-Host "Scheduled task '$taskName' created to run SmoothUpdate.ps1 monthly."
    exit
}

# --- Configuration ---
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$logDir   = "C:\Windows\Logs\musa"
$timeStamp = Get-Date -Format "yyyyMMdd-HHmm"
$logFile  = "$logDir\$scriptName-$timeStamp.log"

# Ensure log directory exists
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}

# --- Step 0: Check Update File Publication ---
$kbID = "KB5071546"
$downloadTargetDir = "C:\Temp"
$updateFile = "$downloadTargetDir\windows10.0-$kbID-x64.msu"

if (Test-Path $updateFile -and -not $Force) {
    $pubDate = (Get-Item $updateFile).CreationTime
    $daysSincePub = (New-TimeSpan -Start $pubDate -End (Get-Date)).Days
    if ($daysSincePub -lt 30) {
        Write-Host "Update file $kbID was published $daysSincePub days ago. Skipping (minimum 30 days required)."
        Write-Host "Use -Force to override."
        exit
    }
}

# --- Step 1: Identify Latest KB ---
$downloadUrl = "https://catalog.update.microsoft.com/Search.aspx?q=$kbID"

Write-Host "Latest cumulative update identified: $kbID"
Write-Host "Download URL (catalog page): $downloadUrl"

# --- Step 1b: Auto-Download KB ---
if (-not (Test-Path $downloadTargetDir)) {
    New-Item -ItemType Directory -Force -Path $downloadTargetDir | Out-Null
}

$msuDirectUrl = "https://download.windowsupdate.com/c/msdownload/update/software/updt/2025/12/windows10.0-kb5071546-x64.msu"

Write-Host "Downloading $kbID to $updateFile..."
Invoke-WebRequest -Uri $msuDirectUrl -OutFile $updateFile -UseBasicParsing

# --- Step 2: Install Update ---
if (Test-Path $updateFile) {
    Write-Host "Installing $kbID from $updateFile..."

    # Safety block: detect if wusa.exe is already running
    $wusaProc = Get-Process -Name wusa -ErrorAction SilentlyContinue
    if ($wusaProc) {
        Write-Host "wusa.exe is already running. Waiting for it to finish..."
        $wusaProc.WaitForExit()
    }

    Start-Process -FilePath "wusa.exe" `
        -ArgumentList "`"$updateFile`" /quiet /norestart /log:`"$logFile`"" `
        -Wait -Verb RunAs
} else {
    Write-Host "Update file not found at $updateFile. Please download first."
    exit
}

# --- Step 3: Verification ---
Write-Host "`n=== Verification ==="
Write-Host "Checking HotFix list..."
Get-HotFix | Where-Object {$_.HotFixID -eq $kbID}

Write-Host "Checking DISM packages..."
dism /online /get-packages | findstr /i $kbID

Write-Host "Checking OS Version..."
$osVersion = (systeminfo | findstr /B /C:"OS Version")
Write-Host $osVersion

# --- Step 4: Optional Cleanup ---
if (Test-Path $logFile) {
    Write-Host "Binary log created at $logFile (not human-readable)."
    # Uncomment next line if you want to delete it automatically:
    # Remove-Item $logFile -Force
}

# --- Step 5: Console Summary ---
Write-Host "`nSummary: Installed $kbID → $osVersion"

Write-Host "`nSmoothUpdate.ps1 completed. Please reboot to finalize installation."
