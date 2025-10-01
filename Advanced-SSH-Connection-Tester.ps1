# Advanced VS Code SSH Connection Test Tool
# Reads SSH config and allows interactive testing of connections

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$env:USERPROFILE\.ssh\config",
    
    [Parameter(Mandatory=$false)]
    [string]$AutoTest = ""
)

Write-Host "Advanced VS Code SSH Connection Tester" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta

# Function to parse SSH config file
function Get-SSHConnections {
    param([string]$ConfigFilePath)
    
    if (-not (Test-Path $ConfigFilePath)) {
        Write-Host "❌ SSH config file not found: $ConfigFilePath" -ForegroundColor Red
        return $null
    }
    
    $connections = @()
    $currentHost = $null
    
    Get-Content $ConfigFilePath | ForEach-Object {
        $line = $_.Trim()
        
        # Skip empty lines and comments
        if ($line -eq "" -or $line.StartsWith("#")) {
            return
        }
        
        # Parse Host entries
        if ($line -match "^Host\s+(.+)$") {
            # Save previous host if exists
            if ($currentHost) {
                $connections += $currentHost
            }
            
            $hostName = $Matches[1]
            # Skip wildcard hosts
            if ($hostName -ne "*") {
                $currentHost = @{
                    Name = $hostName
                    HostName = ""
                    User = ""
                    IdentityFile = ""
                    Port = "22"
                }
            } else {
                $currentHost = $null
            }
        }
        elseif ($currentHost -and $line -match "^\s*(\w+)\s+(.+)$") {
            $key = $Matches[1]
            $value = $Matches[2].Trim('"')
            
            switch ($key) {
                "HostName" { $currentHost.HostName = $value }
                "User" { $currentHost.User = $value }
                "IdentityFile" { $currentHost.IdentityFile = $value }
                "Port" { $currentHost.Port = $value }
            }
        }
    }
    
    # Add the last host
    if ($currentHost) {
        $connections += $currentHost
    }
    
    return $connections
}

# Function to test SSH connection
function Test-SSHConnection {
    param($Connection)
    
    Write-Host "`n🔍 Testing connection to: $($Connection.Name)" -ForegroundColor Cyan
    Write-Host "   Host: $($Connection.HostName)" -ForegroundColor White
    Write-Host "   User: $($Connection.User)" -ForegroundColor White
    Write-Host "   Port: $($Connection.Port)" -ForegroundColor White
    Write-Host "   Key:  $([System.IO.Path]::GetFileName($Connection.IdentityFile))" -ForegroundColor White
    
    Write-Host "`n⏳ Attempting connection..." -ForegroundColor Yellow
    
    try {
        # Test basic connectivity first
        $testResult = Test-NetConnection -ComputerName $Connection.HostName -Port $Connection.Port -WarningAction SilentlyContinue
        
        if (-not $testResult.TcpTestSucceeded) {
            Write-Host "❌ Network connectivity failed to $($Connection.HostName):$($Connection.Port)" -ForegroundColor Red
            return $false
        }
        
        Write-Host "✅ Network connectivity successful" -ForegroundColor Green
        
        # Test SSH authentication
        $sshResult = ssh -o ConnectTimeout=10 -o BatchMode=yes $Connection.Name "whoami" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ SSH authentication successful!" -ForegroundColor Green
            Write-Host "   Remote user: $sshResult" -ForegroundColor White
            
            # Get additional system info
            Write-Host "`n📊 Remote system information:" -ForegroundColor Cyan
            $osInfo = ssh -o ConnectTimeout=5 $Connection.Name "uname -a" 2>$null
            $uptime = ssh -o ConnectTimeout=5 $Connection.Name "uptime" 2>$null
            
            if ($osInfo) {
                Write-Host "   OS: $osInfo" -ForegroundColor Gray
            }
            if ($uptime) {
                Write-Host "   Uptime: $uptime" -ForegroundColor Gray
            }
            
            return $true
        } else {
            Write-Host "❌ SSH authentication failed" -ForegroundColor Red
            Write-Host "   Error: $sshResult" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "❌ Connection test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to display connection menu
function Show-ConnectionMenu {
    param($Connections)
    
    Write-Host "`n📋 Available SSH Connections:" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Gray
    
    for ($i = 0; $i -lt $Connections.Count; $i++) {
        $conn = $Connections[$i]
        $keyFile = if ($conn.IdentityFile) { [System.IO.Path]::GetFileName($conn.IdentityFile) } else { "default" }
        
        Write-Host "[$($i + 1)] $($conn.Name)" -ForegroundColor Yellow
        Write-Host "     → $($conn.User)@$($conn.HostName):$($conn.Port)" -ForegroundColor White
        Write-Host "     → Key: $keyFile" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "[A] Test All Connections" -ForegroundColor Green
    Write-Host "[Q] Quit" -ForegroundColor Red
}

# Main execution
Write-Host "`n📂 Reading SSH config: $ConfigPath" -ForegroundColor Cyan

$connections = Get-SSHConnections -ConfigFilePath $ConfigPath

if (-not $connections -or $connections.Count -eq 0) {
    Write-Host "❌ No SSH connections found in config file" -ForegroundColor Red
    Write-Host "   Make sure your SSH config file exists and has Host entries" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found $($connections.Count) SSH connection(s)" -ForegroundColor Green

# Auto-test mode
if ($AutoTest) {
    $targetConnection = $connections | Where-Object { $_.Name -eq $AutoTest }
    if ($targetConnection) {
        $result = Test-SSHConnection -Connection $targetConnection
        if ($result) {
            Write-Host "`n🎯 VS Code Remote-SSH should work with this connection!" -ForegroundColor Green
        } else {
            Write-Host "`n⚠️ Fix the connection issues before using with VS Code" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Connection '$AutoTest' not found in config" -ForegroundColor Red
    }
    exit 0
}

# Interactive mode
do {
    Show-ConnectionMenu -Connections $connections
    
    $choice = Read-Host "`nSelect connection to test (1-$($connections.Count), A, or Q)"
    
    switch ($choice.ToUpper()) {
        "Q" {
            Write-Host "`nExiting..." -ForegroundColor Gray
            break
        }
        
        "A" {
            Write-Host "`n🚀 Testing all connections..." -ForegroundColor Green
            $successCount = 0
            
            foreach ($conn in $connections) {
                if (Test-SSHConnection -Connection $conn) {
                    $successCount++
                }
                Write-Host "`n" + "-" * 50 -ForegroundColor Gray
            }
            
            Write-Host "`n📊 Summary: $successCount/$($connections.Count) connections successful" -ForegroundColor $(if ($successCount -eq $connections.Count) { "Green" } else { "Yellow" })
        }
        
        default {
            try {
                $index = [int]$choice - 1
                if ($index -ge 0 -and $index -lt $connections.Count) {
                    $selectedConnection = $connections[$index]
                    $result = Test-SSHConnection -Connection $selectedConnection
                    
                    if ($result) {
                        Write-Host "`n🎯 This connection is ready for VS Code Remote-SSH!" -ForegroundColor Green
                        Write-Host "`nVS Code Steps:" -ForegroundColor Cyan
                        Write-Host "1. Press Ctrl+Shift+P" -ForegroundColor White
                        Write-Host "2. Type: Remote-SSH: Connect to Host" -ForegroundColor White
                        Write-Host "3. Select: $($selectedConnection.Name)" -ForegroundColor Yellow
                    } else {
                        Write-Host "`n⚠️ Fix the connection issues before using with VS Code" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "❌ Invalid selection. Please choose 1-$($connections.Count), A, or Q" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ Invalid input. Please enter a number, A, or Q" -ForegroundColor Red
            }
        }
    }
    
    if ($choice.ToUpper() -ne "Q") {
        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
    
} while ($choice.ToUpper() -ne "Q")

Write-Host "`n✨ SSH Connection Testing completed!" -ForegroundColor Green