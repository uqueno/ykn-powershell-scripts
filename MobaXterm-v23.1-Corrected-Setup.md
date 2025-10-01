# MobaXterm v23.1: Corrected Setup Based on Your Screenshots

## 🎯 Key Discovery: No "Use SSH Config File" Option in GUI

Based on your screenshots, MobaXterm v23.1 doesn't have the "Use SSH config file" option in the interface previously described. This guide uses the correct approach for your version.

---

## 📋 Corrected Step-by-Step Process

### Method 1: Use SSH Config Host Names (Recommended)

#### Step 1 (Aliases): Basic SSH Settings

```text
Remote host: coolify-contabo-n8n  ← Use SSH config host name directly
☐ Specify username: (leave unchecked - let SSH config handle it)
Port: 22
```

#### Step 2 (Aliases): Advanced SSH Settings

```text
1. Click the key icon (Advanced SSH settings)
2. In dialog:
   ├── ✅ Attempt authentication using the SSH agent
   ├── ✅ Allow agent forwarding (optional)
   └── Click OK
```

#### Step 3 (Aliases): Session Settings

```text
Session name: coolify-contabo-n8n
Icon: (choose any)
```

### Method 2: Manual Configuration (If Method 1 Fails)

#### Step 1 (Manual): Basic SSH Settings

```text
Remote host: 5.75.149.118  ← Use actual IP
✅ Specify username: root  ← Check this box and enter username
Port: 22
```

#### Step 2 (Manual): Advanced SSH Settings

```text
1. Click the key icon
2. In dialog:
   ├── ✅ Attempt authentication using the SSH agent
   └── Click OK
```

#### Step 3 (Manual): Session Settings

```text
Session name: coolify-contabo-n8n
```

---

## 🔧 How SSH Config Integration Works in v23.1

### Behind the Scenes

1. MobaXterm checks: `C:\Users\yukio\.ssh\config` (if supported)
2. When you use: `coolify-contabo-n8n` as remote host
3. MobaXterm attempts to match the Host entry
4. If not resolved: fallback to manual configuration

### Your SSH Config Provides

```ssh
Host coolify-contabo-n8n
    HostName 5.75.149.118
    User root
    IdentityFile C:\Users\yukio\.ssh\contabo_ed25519_... 
```

---

## 🚀 Try This First: Quick Test

### Create Test Session

1. Session → SSH
2. Basic SSH settings:
   - Remote host: `coolify-contabo-n8n`
   - Specify username: ☐ (unchecked)
   - Port: 22
3. Advanced SSH settings:
   - Key icon → enable agent auth
4. Session settings:
   - Session name: `Test-Coolify`
5. Save & connect

---

## ✅ Success Indicators

### If SSH Config Method Works

- Connection succeeds without password prompt
- Shows `root@server` (or relevant user)
- Uses key-based authentication automatically

### If It Doesn't Work

- Use manual IP + username method
- Still benefits from SSH agent authentication

---

## 🎯 All Three Connections Setup

### Method 1 (SSH Config Host Names)

- Coolify → Remote host: `coolify-contabo-n8n` → Session: `Coolify-Root`
- Docker → Remote host: `docker-contabo-n8n` → Session: `Docker-Yukio`
- Portainer → Remote host: `portainer-contabo-n8n` → Session: `Portainer-User`

### Method 2 (Manual)

- Coolify → `5.75.149.118` + user `root`
- Docker → `5.75.149.118` + user `yukio`
- Portainer → `5.75.149.118` + user `portainer`

---

## 💡 Pro Tip

Test with your `SSH-Connection-Tester.ps1` first; if that succeeds, mirror the settings here.

---

## End of Guide
<!-- end -->