# MobaXterm SSH Config Integration Guide

**Purpose**: Configure MobaXterm to use your existing `~/.ssh/config` file  
**Date**: September 23, 2025  
**Compatibility**: MobaXterm Professional/Home Edition  

---

## 📋 Setup Steps

### **Step 1: Locate Your SSH Config File**
Your SSH config file is located at:
```
C:\Users\yukio\.ssh\config
```

### **Step 2: Configure MobaXterm SSH Settings**

#### **Option A: Global SSH Configuration (Recommended)**

1. **Open MobaXterm Settings**:
   - Launch MobaXterm
   - Go to `Settings` → `Configuration`

2. **Navigate to SSH Settings**:
   - Click on the `SSH` tab in the Configuration window

3. **Set SSH Client Configuration**:
   - Check ✅ **"Use internal SSH agent (MobAgent)"**
   - **SSH client configuration file**: Leave blank initially (see note below)
   - Optionally check ✅ **"Use external Pageant"** if you use PuTTY tools

4. **SSH Agent Forwarding** (Not visible in SSH tab):
   - **Note**: SSH agent forwarding is configured per-session, not globally
   - This setting will be available when creating individual SSH sessions
   - **Alternative**: Agent forwarding can be enabled in Advanced SSH settings per session

5. **Apply Settings**:
   - Click `OK` to save the configuration
   - Restart MobaXterm for changes to take effect

#### **Option B: Per-Session Configuration**

1. **Create New SSH Session**:
   - Click `Session` → `SSH`

2. **Enable Config File Usage**:
   - In the SSH session dialog, go to `Advanced SSH settings` tab
   - Check ✅ **"Use SSH config file"**
   - Browse and select: `C:\Users\yukio\.ssh\config`

---

## ⚠️ Impact on Existing SSH Sessions

### **Will This Affect Your Existing Sessions?**

**Short Answer**: No, your existing SSH sessions will remain unchanged.

**Detailed Explanation**:
- ✅ **Existing sessions preserve their individual configurations**
- ✅ **SSH config file usage is opt-in per session**  
- ✅ **Global SSH agent settings enhance but don't replace existing auth**
- ✅ **You can gradually migrate sessions to use SSH config**

### **Migration Strategy for Existing Sessions**:

1. **Test First**: Create new sessions using SSH config before modifying existing ones
2. **Parallel Setup**: Keep existing sessions while testing new SSH config approach
3. **Gradual Migration**: Convert sessions one by one as needed
4. **Backup**: Export your existing MobaXterm configuration before changes

---

## 🔧 Connection Setup Methods

### **Method 1: Step-by-Step SSH Config Setup for v23.1**

#### **Step 1: Create New SSH Session**
1. **Start New Session**:
   - Click **"Session"** button (top toolbar)
   - Select **"SSH"** 

2. **Basic SSH Settings Tab**:
   - **Remote host**: `coolify-contabo-n8n` (use your SSH config host name!)
   - **Specify username**: Leave unchecked (will use SSH config)
   - **Port**: Leave as default `22`

**Alternative Method** (if SSH config host names don't work):
   - **Remote host**: `5.75.149.118` (actual server IP)
   - **Specify username**: Check this box ✅
   - **Username**: `root` (for coolify connection example)
   - **Port**: `22`

#### **Step 2: Configure Advanced SSH Settings**
1. **Click the key icon** next to "Advanced SSH settings" (as shown in your screenshots)
2. **In the "Advanced SSH protocol settings" dialog**:
   - ✅ **"Attempt authentication using the SSH agent"** (you already found this!)
   - ✅ **"Allow agent forwarding"** (if you need agent forwarding)
   - Click **OK** to close this dialog

**Note**: In v23.1, there's no "Use SSH config file" option in the GUI. Instead, we'll use the SSH config indirectly through host names.

#### **Step 3: Set Session Name**
1. **Session settings tab** (third tab):
   - **Session name**: `coolify-contabo-n8n` (this is your connection name!)
   - **Icon**: Choose an appropriate icon (optional)

#### **Step 4: Save and Test**
1. **Click "OK"** to save the session
2. **Double-click** the saved session to test connection

---

### **Complete Step-by-Step for All Three Connections**

#### **Connection 1: Coolify (Root Access)**
```
Basic SSH settings:
├── Remote host: 5.75.149.118
├── ✅ Specify username: root  
└── Port: 22

Advanced SSH settings:
├── ✅ Attempt authentication using the SSH agent
├── ✅ Use SSH config file
└── SSH config file: C:\Users\yukio\.ssh\config

Session settings:
└── Session name: coolify-contabo-n8n
```

#### **Connection 2: Docker (User Access)**
```
Basic SSH settings:
├── Remote host: 5.75.149.118
├── ✅ Specify username: yukio
└── Port: 22

Advanced SSH settings:
├── ✅ Attempt authentication using the SSH agent
├── ✅ Use SSH config file
└── SSH config file: C:\Users\yukio\.ssh\config

Session settings:
└── Session name: docker-contabo-n8n
```

#### **Connection 3: Portainer (Portainer User)**
```
Basic SSH settings:
├── Remote host: 5.75.149.118
├── ✅ Specify username: portainer
└── Port: 22

Advanced SSH settings:
├── ✅ Attempt authentication using the SSH agent
├── ✅ Use SSH config file
└── SSH config file: C:\Users\yukio\.ssh\config

Session settings:
└── Session name: portainer-contabo-n8n
```

### **Method 2: Import from SSH Config**

1. **Use Session Import Feature** (if available):
   - Go to `Tools` → `MobaSSHConfig` (if present)
   - Select your SSH config file
   - Import available hosts

### **Method 3: Manual Session Creation**

For each connection in your SSH config, create a MobaXterm session:

#### **For coolify-contabo-n8n**:
```
Remote host: 5.75.149.118
Username: root
Port: 22
Private key: C:\Users\yukio\.ssh\contabo_ed25519_20250923_ssh_root@5.75.149.118_windows
```

#### **For docker-contabo-n8n**:
```
Remote host: 5.75.149.118
Username: yukio
Port: 22
Private key: C:\Users\yukio\.ssh\contabo_ed25519_20250923_ssh_yukio@5.75.149.118_windows
```

#### **For portainer-contabo-n8n**:
```
Remote host: 5.75.149.118
Username: portainer
Port: 22
Private key: C:\Users\yukio\.ssh\contabo_ed25519_20250923_ssh_portainer@5.75.149.118_windows
```

---

## 🔑 SSH Key Management

### **Load Keys into MobaXterm**

1. **Access SSH Agent**:
   - In MobaXterm, click the `MobAgent` tab (bottom panel)

2. **Add Your SSH Keys**:
   - Click `+` (Add key)
   - Navigate to your SSH keys directory: `C:\Users\yukio\.ssh\`
   - Select and add each private key:
     - `contabo_ed25519_20250923_ssh_root@5.75.149.118_windows`
     - `contabo_ed25519_20250923_ssh_yukio@5.75.149.118_windows`
     - `contabo_ed25519_20250923_ssh_portainer@5.75.149.118_windows`

3. **Verify Key Loading**:
   - Keys should appear in the MobAgent panel
   - Status should show as "Loaded"

---

## 📝 Your Current SSH Config Reference

For reference, your SSH config file contains:

```ssh
# Coolify Server Connection (Root Access)
Host coolify-contabo-n8n
    HostName 5.75.149.118
    User root
    IdentityFile C:\Users\yukio\.ssh\contabo_ed25519_20250923_ssh_root@5.75.149.118_windows

# Docker Server Connection (User Access)  
Host docker-contabo-n8n
    HostName 5.75.149.118
    User yukio
    IdentityFile C:\Users\yukio\.ssh\contabo_ed25519_20250923_ssh_yukio@5.75.149.118_windows

# Portainer Server Connection (Portainer User)
Host portainer-contabo-n8n
    HostName 5.75.149.118
    User portainer
    IdentityFile C:\Users\yukio\.ssh\contabo_ed25519_20250923_ssh_portainer@5.75.149.118_windows
```

---

## ✅ Verification Steps

### **Test Configuration**

1. **Verify SSH Config Loading**:
   - Open MobaXterm
   - Check that MobAgent shows your loaded keys
   - Verify SSH config file path is set correctly

2. **Test Connection**:
   - Create a new SSH session using host name from config
   - Attempt connection to verify automatic authentication
   - Check that connection uses correct user and key

3. **Validate All Connections**:
   - Test each of your three configured hosts:
     - `coolify-contabo-n8n`
     - `docker-contabo-n8n`
     - `portainer-contabo-n8n`

---

---

## 🔧 MobaXterm v23.1 Specific Notes

### **Interface Differences**:

1. **SSH Agent Forwarding**:
   - **Location**: Available in **individual session settings**, not global SSH tab
   - **Access**: Session → SSH → Advanced SSH settings → "SSH agent forwarding"
   - **Per-Session**: Must be enabled for each session that needs it

2. **SSH Config File Usage**:
   - **Method**: Per-session configuration in Advanced SSH settings
   - **Global Setting**: Limited to SSH agent and authentication preferences
   - **Best Practice**: Configure SSH config file path in session templates

3. **Session Templates**:
   - **Create Template**: Set up one session with SSH config file usage
   - **Duplicate**: Use as template for other sessions
   - **Efficiency**: Saves time when creating multiple similar connections

### **Version-Specific Workflow**:

1. **Configure Global SSH Agent**: 
   - SSH tab → Enable "Use internal SSH agent (MobAgent)"
   - Load your SSH keys in MobAgent panel

2. **Per-Session SSH Config**:
   - Create session → Advanced SSH settings
   - Enable "Use SSH config file" 
   - Set path: `C:\Users\yukio\.ssh\config`

3. **Optional Agent Forwarding**:
   - Enable per session in Advanced SSH settings
   - Only needed for sessions requiring agent forwarding

---

## 🛠️ Troubleshooting

### **Common Issues and Solutions**

#### **"Config file not found" Error**:
- Verify path: `C:\Users\yukio\.ssh\config`
- Check file exists and is readable
- Ensure proper file permissions

#### **Authentication Failures**:
- Verify SSH keys are loaded in MobAgent
- Check private key file paths in config
- Ensure key permissions are correct (see your Generate-SSHKey.ps1 script)

#### **Host Not Found**:
- Verify SSH config syntax
- Check that MobaXterm is reading the config file
- Restart MobaXterm after config changes

#### **Connection Timeouts**:
- Test with your SSH-Connection-Tester.ps1 script first
- Verify network connectivity
- Check server availability

---

## 🚀 Advanced Configuration

### **Session Templates**

Create session templates for easy replication:

1. **Configure Base Session**:
   - Set up SSH config file usage
   - Configure preferred terminal settings
   - Set up key forwarding options

2. **Save as Template**:
   - Right-click session → `Duplicate session`
   - Modify for different hosts
   - Save with descriptive names

### **Automation Scripts**

You can automate MobaXterm session creation:

```batch
@echo off
rem Create MobaXterm session files
echo Creating MobaXterm sessions from SSH config...

rem This would require MobaXterm session file format knowledge
rem Contact MobaXterm support for session automation details
```

---

## 📋 Benefits of SSH Config Integration

### **Consistency**:
- ✅ Same configuration across VS Code, PowerShell, and MobaXterm
- ✅ Centralized connection management
- ✅ Consistent authentication methods

### **Maintenance**:
- ✅ Single file to update for all tools
- ✅ Version control friendly configuration
- ✅ Easy backup and restoration

### **Security**:
- ✅ Centralized key management
- ✅ Consistent security policies
- ✅ Easier audit trail

---

## 📞 Support Resources

### **MobaXterm Documentation**:
- Official documentation: [mobaxterm.mobatek.net](https://mobaxterm.mobatek.net/documentation.html)
- SSH configuration guides
- Session management tutorials

### **Your Existing Tools**:
- Use `SSH-Connection-Tester.ps1` to verify connections work before MobaXterm setup
- Refer to `Generate-SSHKey.ps1` documentation for key management
- Check VS Code Remote-SSH configuration for consistency

---

**Setup Date**: September 23, 2025  
**Next Review**: October 23, 2025  
**Related Documentation**: 
- SSH-Connection-Tester-Documentation.md
- SSH Key Generation Scripts
- VS Code Remote-SSH Configuration

---

*This guide ensures consistent SSH configuration across all your development tools.*