# MobaXterm v23.1: Visual Step-by-Step Setup Guide

## 🎯 **Connection Name Location Found!**

**Answer**: The **connection name** is set in the **"Session settings"** tab (third tab) as **"Session name"**.

---

## 📋 **Detailed Step-by-Step Process**

### **Step 1: Start New Session**
```
1. Click "Session" button (toolbar)
2. Click "SSH" 
3. SSH session dialog opens with 3 tabs:
   ├── Basic SSH settings (Tab 1) ← Start here
   ├── Advanced SSH settings (Tab 2)
   └── Session settings (Tab 3) ← Connection name goes here
```

### **Step 2: Basic SSH Settings (Tab 1)**
```
Fill in these fields:
├── Remote host: 5.75.149.118
├── ✅ Specify username (check this box!)
├── Username: root (for coolify example)
└── Port: 22
```

### **Step 3: Advanced SSH Settings (Tab 2)**
```
Enable these options:
├── ✅ Attempt authentication using the SSH agent ← You found this!
├── ✅ Use SSH config file ← Enable this
└── SSH config file: C:\Users\yukio\.ssh\config ← Browse to select
```

### **Step 4: Session Settings (Tab 3)**
```
Set your connection name:
├── Session name: coolify-contabo-n8n ← This is your connection name!
├── Icon: (choose any icon you like)
└── Other options: (leave defaults)
```

### **Step 5: Save and Test**
```
1. Click "OK" to save
2. Session appears in left sidebar
3. Double-click session name to connect
4. Should connect automatically using SSH key
```

---

## 🔧 **Before You Start: Ensure SSH Keys Are Loaded**

### **Load SSH Keys in MobAgent:**
1. **Find MobAgent tab** (bottom panel of MobaXterm)
2. **Click "+" button** to add keys
3. **Navigate to**: `C:\Users\yukio\.ssh\`
4. **Add these three keys**:
   ```
   contabo_ed25519_20250923_ssh_root@5.75.149.118_windows
   contabo_ed25519_20250923_ssh_yukio@5.75.149.118_windows
   contabo_ed25519_20250923_ssh_portainer@5.75.149.118_windows
   ```
5. **Verify**: Keys show "Loaded" status in MobAgent

---

## 🎯 **Quick Setup for First Connection (Coolify)**

### **Tab 1 - Basic SSH settings:**
- Remote host: `5.75.149.118`
- ✅ Specify username: `root`
- Port: `22`

### **Tab 2 - Advanced SSH settings:**
- Click the **key icon** 🔑 next to "Advanced SSH settings"
- In the dialog that opens:
  - ✅ Attempt authentication using the SSH agent
  - ✅ Allow agent forwarding (if needed)
  - Click **OK**

### **Tab 3 - Session settings:**
- Session name: `coolify-contabo-n8n`

### **Click OK and Test!**

---

## ✅ **Success Indicators**

### **What You Should See:**
1. **Session appears** in left sidebar with name "coolify-contabo-n8n"
2. **Double-click connects** without password prompt
3. **Terminal shows**: `root@your-server:~#`
4. **No authentication errors** in connection log

### **If Connection Fails:**
1. **Check MobAgent**: Ensure SSH keys are loaded
2. **Test with your script**: Run `SSH-Connection-Tester.ps1` first
3. **Verify config file**: Ensure path is correct
4. **Check server**: Ping `5.75.149.118` to verify connectivity

---

## 🚀 **After First Success: Create Other Connections**

### **Repeat the process for:**

#### **Docker Connection:**
- Username: `yukio`
- Session name: `docker-contabo-n8n`
- (Same host and settings otherwise)

#### **Portainer Connection:**
- Username: `portainer`  
- Session name: `portainer-contabo-n8n`
- (Same host and settings otherwise)

---

## 💡 **Pro Tips**

### **Session Organization:**
- **Name Pattern**: Use descriptive names like `service-provider-purpose`
- **Icons**: Use different icons for different connection types
- **Folders**: Group related sessions in folders (right-click → New folder)

### **Time Savers:**
- **Duplicate Session**: Right-click existing session → Duplicate
- **Template**: Create one perfect session, then duplicate and modify
- **Bookmark**: Pin frequently used sessions to top

---

**Next Step**: Start with the coolify connection using these exact steps!