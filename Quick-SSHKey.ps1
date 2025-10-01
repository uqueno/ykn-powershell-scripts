# Quick SSH Key Generator for Contabo VPS
# Uses predefined parameters for quick key generation

# Default parameters based on your current setup
$DefaultParams = @{
    Hosting = "contabo-vps"
    Encryption = "ed25519-key"
    Timestamp = "20250923"
    Protocol = "ssh"
    UserInstance = "portainer@vmi2747748"
    Client = "zest"
}

Write-Host "Quick SSH Key Generator for Contabo VPS" -ForegroundColor Magenta
Write-Host "=======================================" -ForegroundColor Magenta

# Display current parameters
Write-Host "`nCurrent Parameters:" -ForegroundColor Yellow
$DefaultParams.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
}

# Ask user if they want to proceed with defaults or customize
Write-Host "`nOptions:" -ForegroundColor Cyan
Write-Host "  [1] Generate with current parameters" -ForegroundColor White
Write-Host "  [2] Customize parameters" -ForegroundColor White
Write-Host "  [3] Exit" -ForegroundColor White

$choice = Read-Host "`nSelect option (1-3)"

switch ($choice) {
    "1" {
        Write-Host "`nGenerating SSH key with default parameters..." -ForegroundColor Green
        & "$PSScriptRoot\Generate-SSHKey.ps1" @DefaultParams
    }
    "2" {
        Write-Host "`nCustomize Parameters:" -ForegroundColor Yellow
        
        $hosting = Read-Host "Hosting provider [$($DefaultParams.Hosting)]"
        if ([string]::IsNullOrWhiteSpace($hosting)) { $hosting = $DefaultParams.Hosting }
        
        $encryption = Read-Host "Encryption type [$($DefaultParams.Encryption)]"
        if ([string]::IsNullOrWhiteSpace($encryption)) { $encryption = $DefaultParams.Encryption }
        
        $timestamp = Read-Host "Timestamp [$($DefaultParams.Timestamp)]"
        if ([string]::IsNullOrWhiteSpace($timestamp)) { $timestamp = $DefaultParams.Timestamp }
        
        $protocol = Read-Host "Protocol [$($DefaultParams.Protocol)]"
        if ([string]::IsNullOrWhiteSpace($protocol)) { $protocol = $DefaultParams.Protocol }
        
        $userInstance = Read-Host "User@Instance [$($DefaultParams.UserInstance)]"
        if ([string]::IsNullOrWhiteSpace($userInstance)) { $userInstance = $DefaultParams.UserInstance }
        
        $client = Read-Host "Client [$($DefaultParams.Client)]"
        if ([string]::IsNullOrWhiteSpace($client)) { $client = $DefaultParams.Client }
        
        Write-Host "`nGenerating SSH key with custom parameters..." -ForegroundColor Green
        & "$PSScriptRoot\Generate-SSHKey.ps1" -Hosting $hosting -Encryption $encryption -Timestamp $timestamp -Protocol $protocol -UserInstance $userInstance -Client $client
    }
    "3" {
        Write-Host "Exiting..." -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Warning "Invalid option selected. Exiting..."
        exit 1
    }
}

Write-Host "`nQuick generator completed!" -ForegroundColor Green