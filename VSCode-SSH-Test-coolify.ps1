# VS Code Remote-SSH Configuration Fix for coolify-contabo-n8n
# This script ensures VS Code can connect without password prompts

Write-Host "VS Code Remote-SSH Configuration Check" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta

# Test SSH connection
Write-Host "`n🔍 Testing SSH connection..." -ForegroundColor Cyan
try {
    $result = ssh coolify-contabo-n8n "whoami" 2>&1
    if ($result -eq "coolify") {
        Write-Host "✅ SSH key authentication working!" -ForegroundColor Green
        Write-Host "   User: $result" -ForegroundColor White
    } else {
        Write-Host "❌ SSH authentication failed: $result" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ SSH connection error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check VS Code Remote-SSH extension
Write-Host "`n🔌 VS Code Remote-SSH Setup:" -ForegroundColor Cyan
Write-Host "1. Make sure Remote-SSH extension is installed" -ForegroundColor White
Write-Host "2. Press Ctrl+Shift+P in VS Code" -ForegroundColor White
Write-Host "3. Type: 'Remote-SSH: Connect to Host'" -ForegroundColor White
Write-Host "4. Select: 'coolify-contabo-n8n'" -ForegroundColor White

# Show current SSH config
Write-Host "`n⚙️ Current SSH Configuration:" -ForegroundColor Cyan
Write-Host "Host: coolify-contabo-n8n" -ForegroundColor Yellow
Write-Host "IP: 77.237.241.154" -ForegroundColor White
Write-Host "User: coolify" -ForegroundColor White
Write-Host "Key: contabo-vps_ed25519-key_20250923_ssh_coolify@vmi2747748_zest" -ForegroundColor White

# VS Code settings recommendation
Write-Host "`n📋 VS Code Settings (Optional):" -ForegroundColor Cyan
Write-Host "Add to VS Code settings.json:" -ForegroundColor Yellow
$settings = @'
{
    "remote.SSH.useLocalServer": false,
    "remote.SSH.showLoginTerminal": true,
    "remote.SSH.defaultExtensions": []
}
'@
Write-Host $settings -ForegroundColor Gray

Write-Host "`n🚀 VS Code should now connect without asking for password!" -ForegroundColor Green