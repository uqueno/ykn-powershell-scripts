# MobaXterm SSH Config Integration Guide

**Purpose**: Configure MobaXterm to use your existing `~/.ssh/config` file  
**Date**: September 23, 2025  
**Compatibility**: MobaXterm Professional/Home Edition  

---

## 📋 Setup Steps

### Step 1: Locate Your SSH Config File

Your SSH config file is located at:

```text
C:\Users\yukio\.ssh\config
```

### Step 2: Configure MobaXterm SSH Settings

#### Option A: Global SSH Configuration (Recommended)

1. Open MobaXterm Settings:
   - Launch MobaXterm
   - Go to `Settings` → `Configuration`
2. Navigate to SSH Settings:
   - Click on the `SSH` tab in the Configuration window
3. Set SSH Client Configuration:
   - Check ✅ **"Use internal SSH agent (MobAgent)"**
   - (Leave any *SSH client configuration file* field blank if present)
   - Optionally check ✅ **"Use external Pageant"** if you use PuTTY tools
4. SSH Agent Forwarding:
   - Note: Agent forwarding is configured per-session, not globally in v23.1
5. Apply Settings:
   - Click `OK` to save the configuration
   - Restart MobaXterm for changes to take effect

#### Option B: Per-Session Configuration

1. Create New SSH Session:
   - Click `Session` → `SSH`
2. Advanced Settings:
   - In v23.1 the GUI may NOT display a "Use SSH config file" checkbox
   - If present, enable it and select: `C:\Users\yukio\.ssh\config`
   - Otherwise rely on manual or host-based entry (see below)

---

## ⚠️ Impact on Existing SSH Sessions

### Will This Affect Your Existing Sessions?

Short Answer: No, your existing SSH sessions will remain unchanged.

Detailed Explanation:

- ✅ Existing sessions preserve their individual configurations
- ✅ SSH config file usage is opt-in per session  
- ✅ Global SSH agent settings enhance but don't replace existing auth
- ✅ You can gradually migrate sessions to use SSH config

### Migration Strategy for Existing Sessions

1. Test first: Create new sessions using SSH config before modifying existing ones
2. Parallel setup: Keep existing sessions while testing new approach
3. Gradual migration: Convert sessions one by one as needed
4. Backup: Export your existing MobaXterm configuration before changes

---

## 🔧 Connection Setup Methods

### Method 1: Step-by-Step SSH Config Setup for v23.1

#### Step 1: Create New SSH Session

1. Start new session:
   - Click **"Session"** button (top toolbar)
   - Select **"SSH"**
2. Basic SSH settings tab:
   - Remote host: `coolify-contabo-n8n` (use SSH config host name)
   - Specify username: Leave unchecked (will use SSH config if supported)
   - Port: `22`

Alternative (if host alias not resolved):

- Remote host: `5.75.149.118`
- Specify username: Check ✅
- Username: `root`
- Port: `22`

#### Step 2: Configure Advanced SSH Settings

1. Click the key icon next to **Advanced SSH settings**
2. In the **Advanced SSH protocol settings** dialog:
   - ✅ Attempt authentication using the SSH agent
   - ✅ Allow agent forwarding (if you need agent forwarding)
   - Click **OK** to close

Note: In v23.1, there's no guaranteed always-present GUI option labeled *Use SSH config file*. If absent, proceed with manual host/IP setup.

#### Step 3: Set Session Name

1. Open the Session settings tab (third tab)
2. Session name: `coolify-contabo-n8n`
3. Icon: Optional

#### Step 4: Save and Test

1. Click **OK** to save the session
2. Double-click the saved session to test connection

---

### Complete Step-by-Step for All Three Connections

#### Connection 1: Coolify (Root Access)

```text
Basic SSH settings:
├── Remote host: 5.75.149.118
├── ✅ Specify username: root  
└── Port: 22

Advanced SSH settings:
├── ✅ Attempt authentication using the SSH agent
└── (If visible) Use SSH config file: C:\Users\yukio\.ssh\config

Session settings:
└── Session name: coolify-contabo-n8n
```

#### Connection 2: Docker (User Access)

```text
Basic SSH settings:
├── Remote host: 5.75.149.118
├── ✅ Specify username: yukio
└── Port: 22

Advanced SSH settings:
├── ✅ Attempt authentication using the SSH agent
└── (If visible) Use SSH config file: C:\Users\yukio\.ssh\config

Session settings:
└── Session name: docker-contabo-n8n
```

#### Connection 3: Portainer (Portainer User)

```text
Basic SSH settings:
├── Remote host: 5.75.149.118
├── ✅ Specify username: portainer
└── Port: 22

Advanced SSH settings:
├── ✅ Attempt authentication using the SSH agent
└── (If visible) Use SSH config file: C:\Users\yukio\.ssh\config

Session settings:
└── Session name: portainer-contabo-n8n
```

### Method 2: Import from SSH Config (If Present)

1. Use Session Import Feature (if available):
   - `Tools` → `MobaSSHConfig` (if present)
   - Select your SSH config file
   - Import available hosts

### Method 3: Manual Session Creation

For each connection in your SSH config, create a MobaXterm session (manual mapping already shown above).

---

## 🔑 SSH Key Management

### Load Keys into MobaXterm

1. Access SSH Agent:
   - In MobaXterm, click the `MobAgent` tab (bottom panel)
2. Add Your SSH Keys:
   - Click `+` (Add key)
   - Navigate to: `C:\Users\yukio\.ssh\`
   - Select and add each private key:
     - `contabo_ed25519_20250923_ssh_root@5.75.149.118_windows`
     - `contabo_ed25519_20250923_ssh_yukio@5.75.149.118_windows`
     - `contabo_ed25519_20250923_ssh_portainer@5.75.149.118_windows`
3. Verify Key Loading:
   - Keys appear in MobAgent panel as *Loaded*

---

## 📝 Your Current SSH Config Reference

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

### Test Configuration

1. Verify SSH Config Loading:
   - Open MobaXterm
   - Check that MobAgent shows loaded keys
2. Test Connection:
   - Start session and confirm key-based auth
3. Validate All Connections:
   - Test: `coolify-contabo-n8n`, `docker-contabo-n8n`, `portainer-contabo-n8n`

---

## 🔧 MobaXterm v23.1 Specific Notes

### Interface Differences

1. SSH Agent Forwarding:
   - Location: Per-session (Advanced SSH settings)
2. SSH Config File Usage:
   - May not appear; rely on manual host mapping
3. Session Templates:
   - Configure one, duplicate for others

### Version-Specific Workflow

1. Configure global SSH agent (load keys)
2. Create session (host alias or IP)
3. Enable agent forwarding if required

---

## 🛠️ Troubleshooting

### Common Issues and Solutions

**"Config file not found"**:

- Verify path & permissions

**Authentication failures**:

- Confirm keys loaded in MobAgent

**Host not found**:

- Use IP + username manually

**Connection timeouts**:

- Test network / firewall

---

## 🚀 Advanced Configuration

### Session Templates

1. Configure base session
2. Duplicate and adjust

### Automation Scripts

```batch
@echo off
rem Example placeholder for automating session creation
echo (Requires knowledge of MobaXterm session file format)
```

---

## 📋 Benefits of SSH Config Integration

- Consistency across tools
- Centralized connection management
- Easier maintenance
- Improved security posture

---

## 📞 Support Resources

- Official docs: <https://mobaxterm.mobatek.net/documentation.html>
- Use `SSH-Connection-Tester.ps1` to validate hosts first

---

**Setup Date**: September 23, 2025
**Next Review**: October 23, 2025
**Related Docs**: SSH-Connection-Tester-Documentation.md, SSH Key Generation Scripts, VS Code Remote-SSH Configuration

---

*This guide ensures consistent SSH configuration across all your development tools.*
<!-- end -->