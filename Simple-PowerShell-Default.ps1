# Set PowerShell as Default Terminal in VS Code
Write-Host "Setting PowerShell as VS Code Default Terminal" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta

$vsCodeSettingsPath = "$env:APPDATA\Code\User\settings.json"

Write-Host "`nVS Code Settings Path: $vsCodeSettingsPath" -ForegroundColor Cyan

# Check if settings file exists
if (Test-Path $vsCodeSettingsPath) {
    Write-Host "Settings file exists - creating backup..." -ForegroundColor Yellow
    $backupPath = "$vsCodeSettingsPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $vsCodeSettingsPath $backupPath -ErrorAction SilentlyContinue
    Write-Host "Backup created: $backupPath" -ForegroundColor Green
}

# Create settings JSON content
$settings = @{
    "terminal.integrated.defaultProfile.windows" = "PowerShell"
    "terminal.integrated.profiles.windows" = @{
        "PowerShell" = @{
            "source" = "PowerShell"
            "icon" = "terminal-powershell"
        }
        "Command Prompt" = @{
            "path" = @(
                "${env:windir}\Sysnative\cmd.exe",
                "${env:windir}\System32\cmd.exe"
            )
            "args" = @()
            "icon" = "terminal-cmd"
        }
        "Git Bash" = @{
            "source" = "Git Bash"
        }
        "WSL" = @{
            "source" = "Windows.Terminal.Wsl"
        }
    }
    "terminal.integrated.fontSize" = 14
    "terminal.integrated.fontFamily" = "Consolas, 'Courier New', monospace"
    "remote.SSH.useLocalServer" = $false
    "remote.SSH.showLoginTerminal" = $true
}

# Convert to JSON and save
$jsonSettings = $settings | ConvertTo-Json -Depth 10
$jsonSettings | Out-File -FilePath $vsCodeSettingsPath -Encoding UTF8

Write-Host "`nPowerShell terminal settings applied!" -ForegroundColor Green
Write-Host "Restart VS Code to see the changes." -ForegroundColor Yellow

Write-Host "`nQuick VS Code Terminal Shortcuts:" -ForegroundColor Cyan
Write-Host "• Ctrl+` (backtick) - Toggle terminal" -ForegroundColor White
Write-Host "• Ctrl+Shift+` - New terminal instance" -ForegroundColor White
Write-Host "• Terminal dropdown - Switch profiles" -ForegroundColor White

Write-Host "`nDone! PowerShell is now your default terminal." -ForegroundColor Green