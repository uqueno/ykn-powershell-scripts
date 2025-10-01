# VS Code Remote-SSH Navigator Error Quick Fix
param([string]$RemoteHost = "coolify-contabo-n8n")

Write-Host "VS Code Remote-SSH Navigator Error Fix" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta

Write-Host "`nClearing VS Code Local Cache..." -ForegroundColor Cyan
Remove-Item -Path "$env:APPDATA\Code\User\globalStorage\ms-vscode-remote.remote-ssh\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\Code\logs\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\Code\User\workspaceStorage\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Local cache cleared!" -ForegroundColor Green

Write-Host "`nRemote Server Commands:" -ForegroundColor Cyan
Write-Host "ssh $RemoteHost" -ForegroundColor White
Write-Host "rm -rf ~/.vscode-server" -ForegroundColor White
Write-Host "rm -rf ~/.vscode-server-insiders" -ForegroundColor White

Write-Host "`nVS Code Steps:" -ForegroundColor Cyan
Write-Host "1. Uninstall Remote-SSH extension" -ForegroundColor White
Write-Host "2. Restart VS Code" -ForegroundColor White
Write-Host "3. Reinstall Remote-SSH extension" -ForegroundColor White
Write-Host "`nDone!" -ForegroundColor Green
