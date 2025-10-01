# Advanced SSH Connection Tester for VS Code
# Reads SSH config and provides interactive connection testing

param(
    [string]$ConfigPath = "$env:USERPROFILE\.ssh\config"
)

Write-Host "Advanced SSH Connection Tester" -ForegroundColor Magenta
Write-Host "==============================" -ForegroundColor Magenta

# Parse SSH config file
function Get-SSHHosts {
    param([string]$ConfigFile)
    
    $hosts = @()
    $currentHost = @{}
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Config file not found: $ConfigFile" -ForegroundColor Red
        return $hosts
    }
    
    Get-Content $ConfigFile | ForEach-Object {
        $line = $_.Trim()
        
        if ($line -match "^Host\s+(.+)$" -and $Matches[1] -ne "*") {
            if ($currentHost.Name) {
                $hosts += $currentHost
            }
            $currentHost = @{
                Name = $Matches[1]
                HostName = ""
                User = ""
                IdentityFile = ""
                Port = "22"
            }
        }
        elseif ($line -match "^\s*HostName\s+(.+)$") {
            $currentHost.HostName = $Matches[1]
        }
        elseif ($line -match "^\s*User\s+(.+)$") {
            $currentHost.User = $Matches[1]
        }
        elseif ($line -match "^\s*IdentityFile\s+(.+)$") {
            $currentHost.IdentityFile = $Matches[1].Trim('"')
        }
        elseif ($line -match "^\s*Port\s+(.+)$") {
            $currentHost.Port = $Matches[1]
        }
    }
    
    if ($currentHost.Name) {
        $hosts += $currentHost
    }
    
    return $hosts
}

# Test SSH connection
function Test-Connection {
    param($ConnectionInfo)
    
    Write-Host "`nTesting: $($ConnectionInfo.Name)" -ForegroundColor Cyan
    Write-Host "  Host: $($ConnectionInfo.HostName)" -ForegroundColor White
    Write-Host "  User: $($ConnectionInfo.User)" -ForegroundColor White
    Write-Host "  Port: $($ConnectionInfo.Port)" -ForegroundColor White
    
    try {
        $result = ssh -o ConnectTimeout=5 -o BatchMode=yes $ConnectionInfo.Name "whoami" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Status: ✅ SUCCESS" -ForegroundColor Green
            Write-Host "  Remote User: $result" -ForegroundColor White
            return $true
        } else {
            Write-Host "  Status: ❌ FAILED" -ForegroundColor Red
            Write-Host "  Error: $result" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Status: ❌ ERROR" -ForegroundColor Red
        Write-Host "  Message: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Write-Host "`nReading SSH config: $ConfigPath" -ForegroundColor Cyan

$sshHosts = Get-SSHHosts -ConfigFile $ConfigPath

if ($sshHosts.Count -eq 0) {
    Write-Host "No SSH hosts found in config file" -ForegroundColor Yellow
    exit
}

Write-Host "Found $($sshHosts.Count) SSH host(s)" -ForegroundColor Green

# Display menu
Write-Host "`nAvailable SSH Connections:" -ForegroundColor Cyan
for ($i = 0; $i -lt $sshHosts.Count; $i++) {
    $connection = $sshHosts[$i]
    Write-Host "[$($i + 1)] $($connection.Name) ($($connection.User)@$($connection.HostName):$($connection.Port))" -ForegroundColor Yellow
}
Write-Host "[A] Test All" -ForegroundColor Green
Write-Host "[Q] Quit" -ForegroundColor Red

do {
    $choice = Read-Host "`nSelect option"
    
    if ($choice.ToUpper() -eq "Q") {
        break
    }
    elseif ($choice.ToUpper() -eq "A") {
        Write-Host "`nTesting all connections..." -ForegroundColor Green
        $successCount = 0
        foreach ($connection in $sshHosts) {
            if (Test-Connection -ConnectionInfo $connection) {
                $successCount++
            }
        }
        Write-Host "`nResults: $successCount/$($sshHosts.Count) successful" -ForegroundColor $(if ($successCount -eq $sshHosts.Count) { "Green" } else { "Yellow" })
    }
    elseif ($choice -match "^\d+$" -and [int]$choice -ge 1 -and [int]$choice -le $sshHosts.Count) {
        $selectedHost = $sshHosts[[int]$choice - 1]
        $success = Test-Connection -ConnectionInfo $selectedHost
        
        if ($success) {
            Write-Host "`nVS Code Steps:" -ForegroundColor Cyan
            Write-Host "1. Ctrl+Shift+P" -ForegroundColor White
            Write-Host "2. Remote-SSH: Connect to Host" -ForegroundColor White
            Write-Host "3. Select: $($selectedHost.Name)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Invalid choice. Please try again." -ForegroundColor Red
    }
    
} while ($true)

Write-Host "`nDone!" -ForegroundColor Green