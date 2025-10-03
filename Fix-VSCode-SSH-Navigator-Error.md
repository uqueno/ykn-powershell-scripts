# VS Code Remote-SSH "navigator is now a global" Error Fix

**Error Message**: `navigator is now a global in nodejs, please see https://aka.ms/vscode-extensions/navigator for additional info on this error.: PendingMigrationError`

**Issue Date**: September 23, 2025  
**Status**: Known VS Code Remote-SSH compatibility issue

## 🔍 Problem Analysis

This error occurs when:

- VS Code Remote-SSH extension conflicts with Node.js versions
- Cached VS Code server data is corrupted on remote server
- Extension compatibility issues with newer Node.js globals
- VS Code server components need refresh/update

## 🛠️ Solution Steps (Try in Order)

### Step 1: Clear VS Code Remote Server Cache (Local)

```powershell
# In VS Code, press Ctrl+Shift+P and run:
# "Remote-SSH: Kill VS Code Server on Host"

# Or manually clear local SSH cache:
Remove-Item -Path "$env:APPDATA\Code\User\globalStorage\ms-vscode-remote.remote-ssh\vscode-ssh-host-*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\Code\User\workspaceStorage\*" -Recurse -Force -ErrorAction SilentlyContinue
```

### Step 2: Clean Remote Server VS Code Installation

```bash
# SSH into your server and run:
ssh your-user@your-server

# Remove VS Code server installation
rm -rf ~/.vscode-server
rm -rf ~/.vscode-server-insiders

# Clear any cached data
rm -rf ~/.cache/vscode-ssh
```

### Step 3: Update Remote-SSH Extension

```powershell
# In VS Code:
# 1. Go to Extensions (Ctrl+Shift+X)
# 2. Find "Remote - SSH"
# 3. Uninstall it
# 4. Restart VS Code
# 5. Reinstall "Remote - SSH" extension
```

### Step 4: Use Specific VS Code Server Version

Add this to your SSH config or VS Code settings:

```json
{
    "remote.SSH.serverInstallPath": {
        "your-host": "~/.vscode-server-fixed"
    },
    "remote.SSH.useLocalServer": false
}
```

### Step 5: Node.js Version Check (On Remote Server)

```bash
# Check Node.js version on remote server
node --version
npm --version

# If Node.js is very old (< 16), consider updating:
# For Ubuntu/Debian:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify version
node --version
```

## 🚀 Quick Fix PowerShell Script
