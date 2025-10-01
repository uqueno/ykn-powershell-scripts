# Configure VS Code to use PowerShell as Default Terminal
# This script updates VS Code settings to use PowerShell locally

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowCurrentSettings = $false
)

Write-Host "VS Code PowerShell Terminal Configuration" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta

# VS Code settings path
$vsCodeSettingsPath = "$env:APPDATA\Code\User\settings.json"

Write-Host "`n📂 VS Code Settings Location:" -ForegroundColor Cyan
Write-Host "   $vsCodeSettingsPath" -ForegroundColor White

# Check if settings file exists
if (Test-Path $vsCodeSettingsPath) {
    Write-Host "✅ VS Code settings file found" -ForegroundColor Green
    
    if ($ShowCurrentSettings) {
        Write-Host "`n📋 Current Settings:" -ForegroundColor Cyan
        Get-Content $vsCodeSettingsPath | Write-Host -ForegroundColor Gray
    }
} else {
    Write-Host "📝 VS Code settings file not found - will be created" -ForegroundColor Yellow
}

# PowerShell terminal settings
$powerShellSettings = @'
{
    "terminal.integrated.defaultProfile.windows": "PowerShell",
    "terminal.integrated.profiles.windows": {
        "PowerShell": {
            "source": "PowerShell",
            "icon": "terminal-powershell"
        },
        "Command Prompt": {
            "path": [
                "${env:windir}\\Sysnative\\cmd.exe",
                "${env:windir}\\System32\\cmd.exe"
            ],
            "args": [],
            "icon": "terminal-cmd"
        },
        "Git Bash": {
            "source": "Git Bash"
        },
        "WSL": {
            "source": "Windows.Terminal.Wsl"
        }
    },
    "terminal.integrated.fontSize": 14,
    "terminal.integrated.fontFamily": "Consolas, 'Courier New', monospace",
    "terminal.integrated.cursorBlinking": true,
    "terminal.integrated.cursorStyle": "line",
    "terminal.integrated.showExitAlert": false,
    "remote.SSH.useLocalServer": false,
    "remote.SSH.showLoginTerminal": true
}
'@

Write-Host "`n⚙️ PowerShell Terminal Settings:" -ForegroundColor Cyan
Write-Host $powerShellSettings -ForegroundColor Gray

Write-Host "`n🔧 Configuration Options:" -ForegroundColor Yellow
Write-Host "1. Automatically apply these settings" -ForegroundColor White
Write-Host "2. Show manual configuration steps" -ForegroundColor White
Write-Host "3. Backup current settings and apply" -ForegroundColor White
Write-Host "4. Exit without changes" -ForegroundColor White

$choice = Read-Host "`nSelect option (1-4)"

switch ($choice) {
    "1" {
        Write-Host "`n🚀 Applying PowerShell terminal settings..." -ForegroundColor Green
        
        # Backup existing settings if they exist
        if (Test-Path $vsCodeSettingsPath) {
            $backupPath = "$vsCodeSettingsPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $vsCodeSettingsPath $backupPath
            Write-Host "✅ Backup created: $backupPath" -ForegroundColor Green
        }
        
        # Write new settings
        $powerShellSettings | Out-File -FilePath $vsCodeSettingsPath -Encoding UTF8
        Write-Host "✅ VS Code settings updated!" -ForegroundColor Green
        Write-Host "   Restart VS Code to apply changes" -ForegroundColor Yellow
    }
    
    "2" {
        Write-Host "`n📋 Manual Configuration Steps:" -ForegroundColor Cyan
        Write-Host "1. Open VS Code" -ForegroundColor White
        Write-Host "2. Press Ctrl+, (Settings)" -ForegroundColor White
        Write-Host "3. Search for 'terminal.integrated.defaultProfile.windows'" -ForegroundColor White
        Write-Host "4. Set to 'PowerShell'" -ForegroundColor White
        Write-Host "5. Or press Ctrl+Shift+P and search 'Terminal: Select Default Profile'" -ForegroundColor White
        Write-Host "6. Choose 'PowerShell'" -ForegroundColor White
    }
    
    "3" {
        Write-Host "`n💾 Creating backup and applying settings..." -ForegroundColor Green
        
        if (Test-Path $vsCodeSettingsPath) {
            $backupPath = "$vsCodeSettingsPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $vsCodeSettingsPath $backupPath
            Write-Host "✅ Backup created: $backupPath" -ForegroundColor Green
            
            # Try to merge with existing settings
            try {
                $existingSettings = Get-Content $vsCodeSettingsPath | ConvertFrom-Json
                Write-Host "⚙️ Merging with existing settings..." -ForegroundColor Yellow
                
                # Add PowerShell terminal settings
                $existingSettings | Add-Member -NotePropertyName "terminal.integrated.defaultProfile.windows" -NotePropertyValue "PowerShell" -Force
                
                $existingSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $vsCodeSettingsPath -Encoding UTF8
                Write-Host "✅ Settings merged and updated!" -ForegroundColor Green
            } catch {
                Write-Host "⚠️ Could not merge settings, applying new configuration..." -ForegroundColor Yellow
                $powerShellSettings | Out-File -FilePath $vsCodeSettingsPath -Encoding UTF8
                Write-Host "✅ New settings applied!" -ForegroundColor Green
            }
        } else {
            $powerShellSettings | Out-File -FilePath $vsCodeSettingsPath -Encoding UTF8
            Write-Host "✅ Settings file created!" -ForegroundColor Green
        }
        
        Write-Host "   Restart VS Code to apply changes" -ForegroundColor Yellow
    }
    
    "4" {
        Write-Host "`nExiting without changes..." -ForegroundColor Gray
        exit 0
    }
    
    default {
        Write-Host "`n⚠️ Invalid option selected" -ForegroundColor Red
        Write-Host "Use the manual steps above or run the script again" -ForegroundColor Yellow
    }
}

Write-Host "`n🎯 Additional Terminal Options:" -ForegroundColor Cyan
Write-Host "• Ctrl+` (backtick) - Toggle terminal" -ForegroundColor White
Write-Host "• Ctrl+Shift+` - Create new terminal" -ForegroundColor White
Write-Host "• Terminal dropdown - Switch between PowerShell, CMD, WSL" -ForegroundColor White

Write-Host "`n✨ PowerShell will now be your default VS Code terminal!" -ForegroundColor Green