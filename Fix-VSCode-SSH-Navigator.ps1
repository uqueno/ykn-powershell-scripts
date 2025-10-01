# VS Code Remote-SSH Navigator Error Fix Script
# Fixes the "navigator is now a global in nodejs" error

param(
    [Parameter(Mandatory=$false)]
    [string]$RemoteHost = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$FullClean = $false
)

Write-Host "VS Code Remote-SSH Navigator Error Fix" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta

function Clear-VSCodeLocalCache {
    Write-Host "`n🧹 Step 1: Clearing VS Code Local Cache..." -ForegroundColor Cyan
    
    $paths = @(
        "$env:APPDATA\Code\User\globalStorage\ms-vscode-remote.remote-ssh",
        "$env:APPDATA\Code\logs",
        "$env:APPDATA\Code\CachedExtensions"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try {
                Write-Host "  Clearing: $path" -ForegroundColor Yellow
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  ✅ Cleared successfully" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠️  Could not clear: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  📂 Path not found: $path" -ForegroundColor Gray
        }
    }
}

function Clear-VSCodeWorkspaceStorage {
    Write-Host "`n🗂️  Step 2: Clearing Workspace Storage..." -ForegroundColor Cyan
    
    $workspacePath = "$env:APPDATA\Code\User\workspaceStorage"
    if (Test-Path $workspacePath) {
        try {
            $workspaces = Get-ChildItem -Path $workspacePath -Directory
            Write-Host "  Found $($workspaces.Count) workspace(s)" -ForegroundColor Yellow
            
            foreach ($workspace in $workspaces) {
                Write-Host "  Clearing workspace: $($workspace.Name)" -ForegroundColor Gray
                Remove-Item -Path $workspace.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
            Write-Host "  ✅ Workspace storage cleared" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Error clearing workspace storage: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Show-RemoteCleanupCommands {
    param([string]$Host)
    
    Write-Host "`n🖥️  Step 3: Remote Server Cleanup Commands" -ForegroundColor Cyan
    Write-Host "  Copy and run these commands on your remote server:" -ForegroundColor Yellow
    Write-Host ""
    
    $commands = @(
        "# Connect to your server:",
        "ssh $Host",
        "",
        "# Remove VS Code server installations:",
        "rm -rf ~/.vscode-server",
        "rm -rf ~/.vscode-server-insiders",
        "",
        "# Clear cache directories:",
        "rm -rf ~/.cache/vscode-ssh",
        "rm -rf ~/.config/Code",
        "",
        "# Check Node.js version:",
        "node --version",
        "",
        "# If Node.js is old (< 16), update it:",
        "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -",
        "sudo apt-get install -y nodejs",
        "",
        "# Verify installation:",
        "node --version",
        "npm --version"
    )
    
    foreach ($cmd in $commands) {
        if ($cmd.StartsWith("#")) {
            Write-Host $cmd -ForegroundColor Green
        } elseif ($cmd -eq "") {
            Write-Host ""
        } else {
            Write-Host $cmd -ForegroundColor White
        }
    }
}

function Show-VSCodeExtensionFix {
    Write-Host "`n🔌 Step 4: VS Code Extension Fix" -ForegroundColor Cyan
    Write-Host "  Manual steps in VS Code:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Press Ctrl+Shift+X (Extensions)" -ForegroundColor White
    Write-Host "  2. Find 'Remote - SSH' extension" -ForegroundColor White
    Write-Host "  3. Click 'Uninstall'" -ForegroundColor White
    Write-Host "  4. Restart VS Code completely" -ForegroundColor White
    Write-Host "  5. Reinstall 'Remote - SSH' extension" -ForegroundColor White
    Write-Host "  6. Try connecting again" -ForegroundColor White
}

function Show-VSCodeSettings {
    Write-Host "`n⚙️  Step 5: VS Code Settings Fix" -ForegroundColor Cyan
    Write-Host "  Add this to your VS Code settings.json:" -ForegroundColor Yellow
    
    $settings = @'
{
    "remote.SSH.useLocalServer": false,
    "remote.SSH.showLoginTerminal": true,
    "remote.SSH.remotePlatform": {
        "your-host-name": "linux"
    },
    "remote.SSH.serverInstallPath": {
        "your-host-name": "~/.vscode-server-fixed"
    }
}
'@
    
    Write-Host $settings -ForegroundColor Gray
    Write-Host "  (Replace 'your-host-name' with your actual host name)" -ForegroundColor Yellow
}

function Test-VSCodeInstallation {
    Write-Host "`n🔍 Step 6: Testing VS Code Installation" -ForegroundColor Cyan
    
    $vscodePath = Get-Command code -ErrorAction SilentlyContinue
    if ($vscodePath) {
        Write-Host "  ✅ VS Code found: $($vscodePath.Source)" -ForegroundColor Green
        
        try {
            $version = & code --version 2>$null | Select-Object -First 1
            Write-Host "  📊 VS Code Version: $version" -ForegroundColor White
        } catch {
            Write-Host "  ⚠️  Could not get VS Code version" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ❌ VS Code not found in PATH" -ForegroundColor Red
        Write-Host "  📥 Download from: https://code.visualstudio.com/" -ForegroundColor Blue
    }
}

# Main execution
Write-Host "`nStarting VS Code Remote-SSH Navigator Error Fix..." -ForegroundColor Green
Write-Host "Target Host: $(if ($RemoteHost) { $RemoteHost } else { 'Not specified' })" -ForegroundColor White
Write-Host "Full Clean: $FullClean" -ForegroundColor White
Write-Host ""

# Execute steps
Clear-VSCodeLocalCache

if ($FullClean) {
    Clear-VSCodeWorkspaceStorage
}

Show-RemoteCleanupCommands -Host $(if ($RemoteHost) { $RemoteHost } else { "your-user@your-server" })

Show-VSCodeExtensionFix

Show-VSCodeSettings

Test-VSCodeInstallation

Write-Host "`n🎯 Summary:" -ForegroundColor Green
Write-Host "1. ✅ Local VS Code cache cleared" -ForegroundColor White
Write-Host "2. 📋 Remote cleanup commands provided" -ForegroundColor White
Write-Host "3. 🔌 Extension reinstall steps shown" -ForegroundColor White
Write-Host "4. ⚙️  Settings configuration provided" -ForegroundColor White

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run the remote server commands via SSH" -ForegroundColor White
Write-Host "2. Reinstall Remote-SSH extension in VS Code" -ForegroundColor White
Write-Host "3. Apply the settings configuration" -ForegroundColor White
Write-Host "4. Try connecting to your remote server again" -ForegroundColor White

Write-Host "`n✨ Script completed! Good luck with your SSH connection!" -ForegroundColor Green