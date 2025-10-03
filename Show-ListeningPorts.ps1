# Shows detailed list of listening ports with process info and exposure status
# Enhanced to flag ports exposed to the world with colorized output

function Get-ExposureStatus {
    param([string]$LocalAddress)
    
    # Check if port is exposed to external networks
    switch ($LocalAddress) {
        "0.0.0.0"       { return "PUBLIC" }      # IPv4 - All interfaces
        "::"            { return "PUBLIC" }      # IPv6 - All interfaces
        "127.0.0.1"     { return "LOCAL" }       # IPv4 - Localhost only
        "::1"           { return "LOCAL" }       # IPv6 - Localhost only
        default {
            # Check for private IP ranges
            if ($LocalAddress -match "^192\.168\." -or 
                $LocalAddress -match "^10\." -or 
                $LocalAddress -match "^172\.(1[6-9]|2[0-9]|3[0-1])\.") {
                return "INTERNAL"
            }
            # Everything else is potentially external
            return "EXTERNAL"
        }
    }
}

function Get-ColorForExposure {
    param([string]$ExposureStatus)
    
    switch ($ExposureStatus) {
        "PUBLIC"    { return "Red" }
        "EXTERNAL"  { return "Yellow" }
        "INTERNAL"  { return "Cyan" }
        "LOCAL"     { return "Green" }
        default     { return "White" }
    }
}

Write-Host "`n=== LISTENING PORTS ANALYSIS ===" -ForegroundColor Magenta
Write-Host "Legend: " -NoNewline
Write-Host "PUBLIC" -ForegroundColor Red -NoNewline; Write-Host " (0.0.0.0/::) " -NoNewline
Write-Host "EXTERNAL" -ForegroundColor Yellow -NoNewline; Write-Host " (external IP) " -NoNewline  
Write-Host "INTERNAL" -ForegroundColor Cyan -NoNewline; Write-Host " (private IP) " -NoNewline
Write-Host "LOCAL" -ForegroundColor Green -NoNewline; Write-Host " (127.0.0.1/::1)" 
Write-Host ""

$connections = Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess |
    ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        $exposure = Get-ExposureStatus -LocalAddress $_.LocalAddress
        
        [PSCustomObject]@{
            LocalAddress = $_.LocalAddress
            LocalPort    = $_.LocalPort
            ProcessId    = $_.OwningProcess
            ProcessName  = $proc.ProcessName
            Exposure     = $exposure
        }
    } | Sort-Object LocalPort

# Display results with colorized output
$connections | ForEach-Object {
    $color = Get-ColorForExposure -ExposureStatus $_.Exposure
    $line = "{0,-15} {1,-6} {2,-8} {3,-20} {4}" -f $_.LocalAddress, $_.LocalPort, $_.ProcessId, $_.ProcessName, $_.Exposure
    Write-Host $line -ForegroundColor $color
}

# Summary of potentially dangerous exposed ports
$publicPorts = $connections | Where-Object { $_.Exposure -eq "PUBLIC" }
$externalPorts = $connections | Where-Object { $_.Exposure -eq "EXTERNAL" }

if ($publicPorts.Count -gt 0 -or $externalPorts.Count -gt 0) {
    Write-Host "`n=== SECURITY ALERT ===" -ForegroundColor Red
    if ($publicPorts.Count -gt 0) {
        Write-Host "⚠️  Found $($publicPorts.Count) port(s) exposed to ALL networks (0.0.0.0/::):" -ForegroundColor Red
        $publicPorts | ForEach-Object { 
            Write-Host "   Port $($_.LocalPort): $($_.ProcessName) (PID: $($_.ProcessId))" -ForegroundColor Red 
        }
    }
    if ($externalPorts.Count -gt 0) {
        Write-Host "⚠️  Found $($externalPorts.Count) port(s) on external interfaces:" -ForegroundColor Yellow
        $externalPorts | ForEach-Object { 
            Write-Host "   $($_.LocalAddress):$($_.LocalPort): $($_.ProcessName) (PID: $($_.ProcessId))" -ForegroundColor Yellow 
        }
    }
    Write-Host "Consider reviewing these exposed services for security implications.`n" -ForegroundColor White
} else {
    Write-Host "`n✅ No ports exposed to external networks detected.`n" -ForegroundColor Green
}
