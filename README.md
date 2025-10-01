# ykn-powershell-scripts

Collection of PowerShell scripts for SSH automation, VS Code troubleshooting, environment setup, and general workflow acceleration.

> NOTE: Local folder was `Scripts`. Repository name uses corrected spelling: `ykn-powershell-scripts`.

## 📦 Topics / Tags

Automation, PowerShell, SSH, DevOps, VSCode, Remote-SSH, Tooling, Windows, Productivity

## 📁 Contents

| File | Purpose |
|------|---------|
| `Generate-SSHKey.ps1` | Full-featured SSH key generator with naming convention & permissions fix |
| `Quick-SSHKey.ps1` | Minimal wrapper for fast key generation |
| `SSH-Connection-Tester.ps1` | Interactive SSH host tester parsing `~/.ssh/config` |
| `Advanced-SSH-Connection-Tester.ps1` | (Planned/Experimental) Extended diagnostics version |
| `Quick-SSH-Test.ps1` | Fast single-host connectivity check |
| `VSCode-SSH-Test-*.ps1` | Targeted VS Code SSH validation scripts |
| `Fix-VSCode-SSH-Navigator*.ps1` | Workarounds for Remote-SSH navigator errors |
| `Set-VSCode-PowerShell-Default.ps1` | Set PowerShell as default terminal in VS Code |
| `Simple-PowerShell-Default.ps1` | Lightweight variant for terminal default |
| `SSH-Connection-Tester-Documentation.md` | Full technical reference for tester script |
| `MobaXterm-*.md` | Guides for MobaXterm integration attempts |
| `Generate-SSHKey-README.md` | Detailed SSH key generation documentation |
| `*.md` | Remaining documentation, troubleshooting guides, setup notes |

## 🔧 Prerequisites

- Windows 10/11 with PowerShell 5.1+ (PowerShell 7 supported for most scripts)
- OpenSSH client installed (Windows optional feature)
- VS Code (for related Remote-SSH scripts)

## 🚀 Quick Start

```powershell
# Clone (after you push this repository)
git clone https://github.com/<your-user>/ykn-powershell-scripts.git
Set-Location ykn-powershell-scripts

# List scripts
Get-ChildItem *.ps1

# Run key generator (example)
./Generate-SSHKey.ps1 -User coolify -Host vmi2747748 -Address 77.237.241.154 -Client windows
```

## 🧪 Testing Connectivity

```powershell
# Parse ~/.ssh/config and test all hosts
./SSH-Connection-Tester.ps1

# Quick single test
./Quick-SSH-Test.ps1 -Host coolify-contabo-n8n
```

## 🗂 Suggested Directory Layout

Keep scripts directly in repo root (as currently) for simplicity. Optional future structure:

```text
/scripts
/docs
/modules
/tests
```

## 🧩 Toward a Module (Overview)

A future `Ykn.SSH.Tools` PowerShell module could encapsulate reusable functions:

| Proposed Module Path | Purpose |
|----------------------|---------|
| `modules/Ykn.SSH.Tools/Ykn.SSH.Tools.psd1` | Module manifest (metadata, exported functions) |
| `modules/Ykn.SSH.Tools/Ykn.SSH.Tools.psm1` | Implementation importing individual function files |
| `modules/Ykn.SSH.Tools/Public/*.ps1` | Public functions (e.g., `New-YknSshKey`, `Test-YknSshHost`) |
| `modules/Ykn.SSH.Tools/Private/*.ps1` | Internal helpers (parsing, formatting) |
| `modules/Ykn.SSH.Tools/Format/*.ps1xml` | (Optional) Custom object views |
| `tests/*.Tests.ps1` | Pester tests for public functions |

Benefits:

- Import once: `Import-Module ./modules/Ykn.SSH.Tools`
- Clear public API & semantic versioning
- Easier packaging (PowerShell Gallery option)
- Centralized error handling & logging

See `MODULE-GUIDE.md` (added) for detailed steps.

## ✅ Roadmap Ideas

- Add Pester tests for key generator and parser functions
- Package core functions into a module (`Ykn.SSH.Tools`)
- Add parallel host testing + performance metrics
- Continuous integration (GitHub Actions) for linting (PSScriptAnalyzer)
- Optional JSON output mode for automation
- Add module manifest & convert scripts into functions
- Provide signed script examples (code signing)

## 🧹 Code Quality

Run basic linting (if PowerShell 7 installed):

```powershell
pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse"
```

## 📄 License

MIT (see `LICENSE`)

## 🙋 Support / Notes

Author: Yukio Ueno

Issues and PRs welcome. These scripts originated from iterative troubleshooting of SSH + VS Code Remote-SSH flows and are intentionally pragmatic.

---
Happy scripting! 🔧
