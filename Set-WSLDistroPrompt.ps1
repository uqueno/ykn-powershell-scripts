# WSL Distro Prompt Configurator Script
# Configures system-wide bash prompt identification for WSL distributions
# Supports multi-user environments with enhanced fallback detection
#
# Version: 1.6
# Updated: October 2, 2025
# Changelog:
#   v1.6 - Applied tmp file approach to user bashrc addition, fixed script corruption
#   v1.5 - Removed unnecessary chmod +x (sourced files only need read permission)
#   v1.4 - Implemented tmp file approach with sed line ending conversion for reliable deployment
#   v1.3 - Fixed script generation using line-by-line approach with proper Unix line endings
#   v1.2 - Fixed script deployment using here-documents instead of base64 encoding
#   v1.1 - Fixed Windows line ending issues, added syntax validation, enhanced error handling
#   v1.0 - Initial release with multi-user support and fallback detection
#
# Credits:
#   Human Maintainer & Integrator: Yukio Ueno
#   Logic & Implementation Designer: AI Assistant

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false)]
    [string[]]$Distributions = @("Ubuntu-24.04", "Ubuntu"),
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Global", "User", "Both")]
    [string]$Scope = "Global",
    
    [Parameter(Mandatory=$false)]
    [string[]]$Users = @("ubuntu", "ubuntu-2404"),
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateBackup,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verify
)

# Function to get WSL distribution information
function Get-WSLDistributionInfo {
    param([string]$DistroName)
    
    try {
        $env:POWERSHELL_TELEMETRY_OPTOUT = 1
        $distroInfo = wsl -d $DistroName -u root -e bash -c "
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                echo \"Name:\$NAME\"
                echo \"Version:\$VERSION_ID\"
                echo \"Codename:\$UBUNTU_CODENAME\"
            fi
        " 2>`$null
        
        $info = @{}
        $distroInfo | ForEach-Object {
            if ($_ -match "^(\w+):(.*)$") {
                $info[$Matches[1]] = $Matches[2]
            }
        }
        
        return $info
    } catch {
        Write-Warning "Failed to get information for distribution: $DistroName"
        return @{}
    }
}

# Function to create the enhanced profile script content
function New-ProfileScriptContent {
    param([hashtable]$DistroInfo)
    
    # Build the script content line by line to ensure proper formatting
    $lines = @(
        '#!/bin/bash',
        '# Enhanced WSL Profile - /etc/profile.d/wsl-distro-prompt.sh',
        '# Added by WSL Distro Prompt Configurator for multi-user environment identification',
        "# Created: $((Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))",
        '# Version: 1.0',
        '#',
        '# Credits:',
        '#   Human Maintainer & Integrator: Yukio Ueno',
        '#   Logic & Implementation Designer: AI Assistant',
        '',
        'get_distro_identification() {',
        '    # Primary: Use WSL_DISTRO_NAME if available',
        '    if [ -n "$WSL_DISTRO_NAME" ]; then',
        '        echo "($WSL_DISTRO_NAME)"',
        '        return',
        '    fi',
        '    ',
        '    # Fallback: Parse /etc/os-release for detailed info',
        '    if [ -f /etc/os-release ]; then',
        '        local name version_id ubuntu_codename',
        '        ',
        '        # Extract key information from os-release',
        '        name=$(grep "^NAME=" /etc/os-release | cut -d\" -f2 | cut -d" " -f1)',
        '        version_id=$(grep "^VERSION_ID=" /etc/os-release | cut -d\" -f2)',
        '        ubuntu_codename=$(grep "^UBUNTU_CODENAME=" /etc/os-release | cut -d"=" -f2)',
        '        ',
        '        # Build distro identifier based on available info',
        '        if [ -n "$version_id" ]; then',
        '            if [ -n "$ubuntu_codename" ]; then',
        '                echo "(${name:-Ubuntu}-${version_id}-${ubuntu_codename})"',
        '            else',
        '                echo "(${name:-Ubuntu}-${version_id})"',
        '            fi',
        '        else',
        '            echo "(${name:-Ubuntu}-Unknown)"',
        '        fi',
        '    else',
        '        # Last resort: Try lsb_release',
        '        if command -v lsb_release >/dev/null 2>&1; then',
        '            local distro_id release_num',
        '            distro_id=$(lsb_release -si 2>/dev/null)',
        '            release_num=$(lsb_release -sr 2>/dev/null)',
        '            echo "(${distro_id:-Ubuntu}-${release_num:-Unknown})"',
        '        else',
        '            echo "(WSL-Unknown)"',
        '        fi',
        '    fi',
        '}',
        '',
        '# Set the custom distro identification',
        'export CUSTOM_PS1_DISTRO=$(get_distro_identification)',
        '',
        '# Apply to interactive shells only',
        'if [ -n "$PS1" ]; then',
        "    PS1='\[\033[01;32m\]\u@\h\[\033[01;33m\]`$CUSTOM_PS1_DISTRO\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\`$ '",
        'fi'
    )
    
    # Join with Unix line endings
    return $lines -join "`n"
}

# Function to apply configuration to a WSL distribution
function Set-WSLDistroPrompt {
    param(
        [string]$DistroName,
        [string]$Scope,
        [string[]]$Users,
        [switch]$CreateBackup,
        [switch]$Force
    )
    
    Write-Host "Configuring WSL distribution: $DistroName" -ForegroundColor Cyan
    
    # Get distribution information
    $distroInfo = Get-WSLDistributionInfo -DistroName $DistroName
    
    # Create profile script content
    $profileContent = New-ProfileScriptContent -DistroInfo $distroInfo
    
    if (-not $profileContent -or $profileContent.Length -eq 0) {
        Write-Error "Failed to generate profile content for $DistroName"
        return $false
    }
    
    if ($Scope -eq "Global" -or $Scope -eq "Both") {
        Write-Host "  Applying global configuration..." -ForegroundColor Yellow
        
        # Create backup if requested
        if ($CreateBackup) {
            $backupCmd = "[ -f /etc/profile.d/wsl-distro-prompt.sh ] && cp /etc/profile.d/wsl-distro-prompt.sh /etc/profile.d/wsl-distro-prompt.sh.bak.`$(date +%Y%m%d_%H%M%S)"
            $env:POWERSHELL_TELEMETRY_OPTOUT = 1
            wsl -d $DistroName -u root -e bash -c $backupCmd 2>`$null
        }
        
        # Apply global configuration
        try {
            if (-not $profileContent) {
                throw "Profile content is null or empty"
            }
            
            # Save to tmp file first, then convert line endings and move to destination
            $encodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($profileContent))
            $applyCmd = "echo '$encodedContent' | base64 -d > /tmp/wsl-distro-prompt.sh && sed -i 's/\r$//' /tmp/wsl-distro-prompt.sh && cp /tmp/wsl-distro-prompt.sh /etc/profile.d/wsl-distro-prompt.sh && rm /tmp/wsl-distro-prompt.sh"
            
            $env:POWERSHELL_TELEMETRY_OPTOUT = 1
            wsl -d $DistroName -u root -e bash -c $applyCmd 2>`$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✅ Global configuration applied successfully" -ForegroundColor Green
            } else {
                Write-Host "    ❌ Failed to apply global configuration" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Error "Error applying global configuration: $($_.Exception.Message)"
            return $false
        }
    }
    
    if ($Scope -eq "User" -or $Scope -eq "Both") {
        Write-Host "  Applying user-specific configuration..." -ForegroundColor Yellow
        
        foreach ($user in $Users) {
            try {
                # Check if user exists
                $env:POWERSHELL_TELEMETRY_OPTOUT = 1
                $userCheck = wsl -d $DistroName -u root -e bash -c "id $user >/dev/null 2>&1 && echo 'exists'" 2>`$null
                
                if ($userCheck -eq "exists") {
                    # Create backup of .bashrc if requested
                    if ($CreateBackup) {
                        $backupCmd = "[ -f /home/${user}/.bashrc ] && cp /home/${user}/.bashrc /home/${user}/.bashrc.bak.`$(date +%Y%m%d_%H%M%S)"
                        $env:POWERSHELL_TELEMETRY_OPTOUT = 1
                        wsl -d $DistroName -u root -e bash -c $backupCmd 2>`$null
                    }
                    
                    # Apply user configuration
                    $userBashrcAddition = @"
# WSL Distro Identification - Added by WSL Distro Prompt Configurator
# Credits:
#   Human Maintainer & Integrator: Yukio Ueno
#   Logic & Implementation Designer: AI Assistant
if [ -f /etc/profile.d/wsl-distro-prompt.sh ]; then
    source /etc/profile.d/wsl-distro-prompt.sh
fi
"@
                    
                    # Save to tmp file first, then convert line endings and append to bashrc
                    $encodedUserContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($userBashrcAddition))
                    $userCmd = "echo '$encodedUserContent' | base64 -d > /tmp/bashrc-addition-${user}.sh && sed -i 's/\r$//' /tmp/bashrc-addition-${user}.sh && cat /tmp/bashrc-addition-${user}.sh >> /home/${user}/.bashrc && chown ${user}:${user} /home/${user}/.bashrc && rm /tmp/bashrc-addition-${user}.sh"
                    
                    $env:POWERSHELL_TELEMETRY_OPTOUT = 1
                    wsl -d $DistroName -u root -e bash -c $userCmd 2>`$null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "    ✅ User configuration applied for: $user" -ForegroundColor Green
                    } else {
                        Write-Host "    ❌ Failed to apply user configuration for: $user" -ForegroundColor Red
                    }
                } else {
                    Write-Host "    ⚠️  User '$user' does not exist in $DistroName" -ForegroundColor Yellow
                }
            } catch {
                Write-Warning "Error configuring user '$user': $($_.Exception.Message)"
            }
        }
    }
    
    return $true
}

# Function to verify configuration
function Test-WSLDistroPromptConfiguration {
    param(
        [string]$DistroName,
        [string[]]$Users
    )
    
    Write-Host "Verifying configuration for: $DistroName" -ForegroundColor Cyan
    
    # Test global configuration
    $env:POWERSHELL_TELEMETRY_OPTOUT = 1
    $globalTest = wsl -d $DistroName -u root -e bash -c "[ -f /etc/profile.d/wsl-distro-prompt.sh ] && echo 'exists'" 2>`$null
    
    # Test that the script can be sourced without errors
    $env:POWERSHELL_TELEMETRY_OPTOUT = 1
    $syntaxTest = wsl -d $DistroName -u root -e bash -c "bash -n /etc/profile.d/wsl-distro-prompt.sh && echo 'valid'" 2>`$null
    
    if ($globalTest -eq "exists") {
        Write-Host "  ✅ Global profile script exists" -ForegroundColor Green
        
        if ($syntaxTest -eq "valid") {
            Write-Host "  ✅ Profile script syntax is valid" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Profile script has syntax issues" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ❌ Global profile script missing" -ForegroundColor Red
        return $false
    }
    
    # Test users
    foreach ($user in $Users) {
        $env:POWERSHELL_TELEMETRY_OPTOUT = 1
        $userTest = wsl -d $DistroName -u $user -e bash -l -c "echo \$CUSTOM_PS1_DISTRO" 2>`$null
        
        if ($userTest -and $userTest -ne "") {
            Write-Host "  ✅ User '$user' prompt configured: $userTest" -ForegroundColor Green
        } else {
            Write-Host "  ❌ User '$user' prompt not configured properly" -ForegroundColor Red
        }
    }
    
    return $true
}

# Main execution
Write-Host "WSL Distro Prompt Configurator" -ForegroundColor Magenta
Write-Host "==============================" -ForegroundColor Magenta
Write-Host "Enhanced multi-user WSL bash prompt identification" -ForegroundColor Gray

# Validate WSL distributions
$validDistros = @()
foreach ($distro in $Distributions) {
    $distroCheck = wsl -l -q | Where-Object { $_.Trim() -eq $distro }
    if ($distroCheck) {
        $validDistros += $distro
        Write-Host "  ✅ Found distribution: $distro" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Distribution not found: $distro" -ForegroundColor Red
    }
}

if ($validDistros.Count -eq 0) {
    Write-Error "No valid WSL distributions found. Exiting."
    exit 1
}

Write-Host "`nConfiguration Details:" -ForegroundColor White
Write-Host "  Scope: $Scope" -ForegroundColor Yellow
Write-Host "  Distributions: $($validDistros -join ', ')" -ForegroundColor Yellow
Write-Host "  Users: $($Users -join ', ')" -ForegroundColor Yellow
Write-Host "  Create Backup: $CreateBackup" -ForegroundColor Yellow

if ($WhatIfPreference) {
    Write-Host "`n[WHATIF] Would configure the following:" -ForegroundColor Cyan
    Write-Host "  Distributions: $($validDistros -join ', ')" -ForegroundColor Yellow
    Write-Host "  Scope: $Scope" -ForegroundColor Yellow
    Write-Host "  Users: $($Users -join ', ')" -ForegroundColor Yellow
    Write-Host "  Create Backup: $CreateBackup" -ForegroundColor Yellow
    Write-Host "`n[WHATIF] No changes will be made." -ForegroundColor Green
    exit 0
}

if (-not $Force) {
    $confirm = Read-Host "`nProceed with configuration? (y/N)"
    if ($confirm -notmatch "^[Yy]") {
        Write-Host "Configuration cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

# Apply configuration to each distribution
$results = @()
foreach ($distro in $validDistros) {
    if ($PSCmdlet.ShouldProcess($distro, "Configure WSL Distro Prompt")) {
        $success = Set-WSLDistroPrompt -DistroName $distro -Scope $Scope -Users $Users -CreateBackup:$CreateBackup -Force:$Force
    } else {
        $success = $false
    }
    $results += [PSCustomObject]@{
        Distribution = $distro
        Success = $success
    }
}

# Verify configuration if requested
if ($Verify) {
    Write-Host "`nVerifying configurations..." -ForegroundColor Cyan
    foreach ($distro in $validDistros) {
        Test-WSLDistroPromptConfiguration -DistroName $distro -Users $Users
    }
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "CONFIGURATION SUMMARY" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

$results | ForEach-Object {
    $status = if ($_.Success) { "✅ SUCCESS" } else { "❌ FAILED" }
    $color = if ($_.Success) { "Green" } else { "Red" }
    Write-Host "  $($_.Distribution): $status" -ForegroundColor $color
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Restart WSL terminals or run 'source ~/.bashrc' in existing sessions" -ForegroundColor White
Write-Host "2. Verify prompt shows distribution identification" -ForegroundColor White
Write-Host "3. Test with different users to ensure system-wide application" -ForegroundColor White

Write-Host "`nScript completed!" -ForegroundColor Green