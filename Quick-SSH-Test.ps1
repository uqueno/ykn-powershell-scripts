# Quick SSH Test - Non-interactive version
# Tests a specific SSH connection from config

param(
    [Parameter(Mandatory=$true)]
    [string]$ConnectionName
)

Write-Host "Quick SSH Connection Test" -ForegroundColor Magenta
Write-Host "========================" -ForegroundColor Magenta

# Test the connection
Write-Host "`nTesting connection: $ConnectionName" -ForegroundColor Cyan

try {
    $result = ssh -o ConnectTimeout=10 $ConnectionName "whoami" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ SUCCESS: Connected as '$result'" -ForegroundColor Green
        
        # Get system info
        $osInfo = ssh -o ConnectTimeout=5 $ConnectionName "uname -o" 2>$null
        $hostname = ssh -o ConnectTimeout=5 $ConnectionName "hostname" 2>$null
        
        if ($osInfo) { Write-Host "   OS: $osInfo" -ForegroundColor White }
        if ($hostname) { Write-Host "   Hostname: $hostname" -ForegroundColor White }
        
        Write-Host "`n🎯 VS Code Remote-SSH is ready!" -ForegroundColor Green
        Write-Host "   Use Ctrl+Shift+P → Remote-SSH: Connect to Host → $ConnectionName" -ForegroundColor Yellow
    } else {
        Write-Host "❌ FAILED: $result" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
}