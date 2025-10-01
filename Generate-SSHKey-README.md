# SSH Key Generator Scripts Documentation

**Main Script**: `Generate-SSHKey.ps1`  
**Quick Script**: `Quick-SSHKey.ps1`  
**This Documentation**: `Generate-SSHKey-README.md`

*Last Updated: September 23, 2025*

## Overview
These PowerShell scripts generate SSH key pairs following a standardized naming convention for consistent key management across multiple servers and environments.

## Naming Convention
The naming convention follows this structured pattern:
```
{hosting}_{encryption}_{timestamp}_{protocol}_{username@instance|hostname}_{client}
```

### Parameter Definitions:
1. **hosting**: Hosting provider or environment identifier
   - Examples: `contabo-vps`, `aws-ec2`, `azure-vm`, `local-dev`, `digitalocean`
   
2. **encryption**: Encryption algorithm and key type
   - Examples: `ed25519-key` (recommended), `rsa-key`, `ecdsa-key`
   
3. **timestamp**: Date in YYYYMMDD format for version tracking
   - Current format: `20250923` (auto-generated if not specified)
   - Format: `YYYY-MM-DD` → `YYYYMMDD`
   
4. **protocol**: Connection or usage protocol
   - Examples: `ssh`, `api`, `sftp`, `scp`, `rsync`
   
5. **username@instance|hostname**: Target server identification
   - Examples: `portainer@vmi2747748`, `admin@prod-server`, `root@192.168.1.100`
   
6. **client**: Source client or workstation identifier
   - Examples: `zest`, `laptop`, `workstation`, `vscode`, `ci-cd`

## Scripts in this Package

### 1. Generate-SSHKey.ps1
**Main script with full parameter control**

#### Usage:
```powershell
# With all parameters
.\Generate-SSHKey.ps1 -Hosting "contabo-vps" -Encryption "ed25519-key" -Timestamp "20250923" -Protocol "ssh" -UserInstance "portainer@vmi2747748" -Client "zest"

# With minimal parameters (timestamp auto-generated)
.\Generate-SSHKey.ps1 -Hosting "aws" -Encryption "ed25519-key" -Protocol "ssh" -UserInstance "admin@prod-server" -Client "laptop"
```

#### Parameters:
- `-Hosting` (Required): Hosting provider name
- `-Encryption` (Required): Encryption algorithm
- `-Timestamp` (Optional): Date stamp (defaults to current date)
- `-Protocol` (Required): Connection protocol
- `-UserInstance` (Required): Username@hostname pattern
- `-Client` (Required): Client identifier

### 2. Quick-SSHKey.ps1
**Interactive wrapper script with predefined defaults**

#### Usage:
```powershell
.\Quick-SSHKey.ps1
```

This script provides an interactive menu with options to:
1. Generate with current predefined parameters
2. Customize parameters interactively
3. Exit

## Examples

### Example 1: Current Contabo VPS Setup (Today: 2025-09-23)
```powershell
.\Generate-SSHKey.ps1 -Hosting "contabo-vps" -Encryption "ed25519-key" -Timestamp "20250923" -Protocol "ssh" -UserInstance "portainer@vmi2747748" -Client "zest"
```
**Generated Files:**
```
Key Name: contabo-vps_ed25519-key_20250923_ssh_portainer@vmi2747748_zest
Private:  C:\Users\yukio\.ssh\contabo-vps_ed25519-key_20250923_ssh_portainer@vmi2747748_zest
Public:   C:\Users\yukio\.ssh\contabo-vps_ed25519-key_20250923_ssh_portainer@vmi2747748_zest.pub
```

### Example 2: AWS Production Server
```powershell
.\Generate-SSHKey.ps1 -Hosting "aws-ec2" -Encryption "ed25519-key" -Protocol "ssh" -UserInstance "ubuntu@prod-web-01" -Client "workstation"
```
**Generated Files:**
```
Key Name: aws-ec2_ed25519-key_20250923_ssh_ubuntu@prod-web-01_workstation
```

### Example 3: Development Environment
```powershell
.\Generate-SSHKey.ps1 -Hosting "local-dev" -Encryption "ed25519-key" -Protocol "ssh" -UserInstance "developer@localhost" -Client "vscode"
```
**Generated Files:**
```
Key Name: local-dev_ed25519-key_20250923_ssh_developer@localhost_vscode
```

### Example 4: API Access Keys
```powershell
.\Generate-SSHKey.ps1 -Hosting "digitalocean" -Encryption "ed25519-key" -Protocol "api" -UserInstance "api@droplet-prod" -Client "automation"
```
**Generated Files:**
```
Key Name: digitalocean_ed25519-key_20250923_api_api@droplet-prod_automation
```

## Features

### 🔒 Security & Permissions
- **Secure File Permissions**: Automatically sets Windows NTFS permissions
- **User-Only Access**: Only the current user (`%USERNAME%`) has full control
- **No Inheritance**: Removes inherited permissions for maximum security
- **ED25519 Encryption**: Uses modern, secure elliptic curve cryptography

### 📊 Information Display
- **Key Fingerprint**: SHA256 fingerprint for verification
- **File Details**: Size, creation time, and location information
- **Public Key Content**: Ready-to-copy format for server authorization
- **Usage Instructions**: Clear next steps for VS Code and SSH configuration

### 🛡️ Error Handling & Validation
- **SSH Tool Validation**: Checks for `ssh-keygen` availability
- **Existing Key Detection**: Prompts before overwriting existing keys
- **Parameter Validation**: Ensures all required parameters are provided
- **Clear Error Messages**: Descriptive feedback for troubleshooting

### 🚀 Automation Features
- **Auto-Timestamp**: Uses current date if timestamp not specified
- **Batch Generation**: Can be integrated into CI/CD pipelines
- **Consistent Naming**: Enforces standardized key naming across environments

## 📦 Installation & Setup

### Prerequisites
- **Windows 10/11** with PowerShell 5.1 or later
- **OpenSSH Client** (usually pre-installed on modern Windows)
- **PowerShell Execution Policy** allowing script execution

### Installation Steps

1. **Create Scripts Directory** (if not exists):
   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\Scripts" -Force
   ```

2. **Copy Scripts** to `%USERPROFILE%\Scripts\`:
   - `Generate-SSHKey.ps1` (Main generator script)
   - `Quick-SSHKey.ps1` (Interactive wrapper)
   - `README.md` (This documentation)

3. **Set Execution Policy**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Verify OpenSSH Installation**:
   ```powershell
   ssh-keygen -help
   ```

5. **Test Installation**:
   ```powershell
   cd $env:USERPROFILE\Scripts
   .\Quick-SSHKey.ps1
   ```

## 🔌 VS Code Remote-SSH Integration

### Quick Setup Guide

1. **Install Remote-SSH Extension**:
   - Open VS Code
   - Go to Extensions (`Ctrl+Shift+X`)
   - Search for "Remote - SSH" by Microsoft
   - Install the extension

2. **Configure SSH Connection**:
   ```powershell
   # Press Ctrl+Shift+P in VS Code, then:
   # "Remote-SSH: Add New SSH Host"
   ```

3. **SSH Configuration Example**:
   ```ssh-config
   Host contabo-portainer
       HostName your-server-ip
       User portainer
       IdentityFile C:\Users\yukio\.ssh\contabo-vps_ed25519-key_20250923_ssh_portainer@vmi2747748_zest
       IdentitiesOnly yes
       PreferredAuthentications publickey
   ```

4. **Add Public Key to Server**:
   ```bash
   # On your Ubuntu server:
   echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMpKaIEiiwK03cRxFnCNwYTcFD7CCD854nxSmsSBvWLq contabo-vps_ed25519-key_20250923_ssh_portainer@vmi2747748_zest" >> ~/.ssh/authorized_keys
   ```

5. **Connect**:
   - Press `Ctrl+Shift+P`
   - Select "Remote-SSH: Connect to Host"
   - Choose your configured host

## Troubleshooting

### ssh-keygen not found
- Install OpenSSH client: `Add-WindowsCapability -Online -Name OpenSSH.Client*`

### Permission issues
- Run PowerShell as Administrator if needed
- Ensure you have write access to `%USERPROFILE%\.ssh\`

### Key already exists
- The script will prompt to overwrite existing keys
- Choose 'y' to overwrite or rename your parameters

## 📋 Best Practices

### Naming Conventions
- ✅ **Use descriptive identifiers**: Clear hosting, protocol, and client names
- ✅ **Consistent timestamps**: Always use YYYYMMDD format
- ✅ **Standard encryption**: Prefer `ed25519-key` for modern security
- ✅ **Meaningful usernames**: Include actual username and server identification

### Security Guidelines
- 🔐 **Regular rotation**: Update keys every 90-180 days
- 🔐 **Unique keys per environment**: Don't reuse keys across dev/staging/prod
- 🔐 **Backup strategy**: Secure backup of critical keys
- 🔐 **Access control**: Limit key distribution and document usage

### Organization Tips
- 📁 **Consistent location**: Keep all keys in `%USERPROFILE%\.ssh\`
- 📁 **Documentation**: Maintain inventory of keys and their purposes
- 📁 **Version control**: Track key generation dates and replacements
- 📁 **Environment separation**: Use clear client identifiers

## 🆘 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **ssh-keygen not found** | Install OpenSSH: `Add-WindowsCapability -Online -Name OpenSSH.Client*` |
| **Permission denied** | Run as Administrator or check `%USERPROFILE%\.ssh\` permissions |
| **Script execution blocked** | Set execution policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| **Key already exists** | Choose 'y' to overwrite or modify parameters for unique naming |
| **VS Code can't find key** | Verify full path: `C:\Users\yukio\.ssh\your-key-name` |

### Verification Commands
```powershell
# Check OpenSSH installation
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# Verify key permissions
icacls "C:\Users\yukio\.ssh\your-key-name"

# Test key fingerprint
ssh-keygen -lf "C:\Users\yukio\.ssh\your-key-name.pub"

# Validate SSH connection
ssh -i "C:\Users\yukio\.ssh\your-key-name" -o ConnectTimeout=10 user@server
```

## 📞 Support & Updates

**Created**: September 23, 2025  
**Version**: 1.0  
**Compatibility**: Windows 10/11, PowerShell 5.1+

For issues or improvements:
- Check PowerShell execution policy settings
- Verify OpenSSH client installation
- Ensure proper file system permissions
- Test network connectivity to target servers
- Review Windows Defender or antivirus interference