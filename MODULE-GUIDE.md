# Module Guide: Converting Scripts into `Ykn.SSH.Tools`

## 🎯 Goal

Transform standalone scripts into a reusable, testable PowerShell module for distribution and clean reuse.

## 🚀 Why Create a Module?

- Centralized public API (`Import-Module Ykn.SSH.Tools`)
- Enables semantic versioning + manifest metadata
- Encourages writing testable, single-responsibility functions
- Enables publishing to PowerShell Gallery (optional)
- Simplifies dependency handling and autoloading

## 🗂 Proposed Structure

```text
modules/
  Ykn.SSH.Tools/
    Ykn.SSH.Tools.psd1        # Manifest
    Ykn.SSH.Tools.psm1        # Module root imports Public/*.ps1
    Public/                   # Exported functions
      New-YknSshKey.ps1
      Test-YknSshHost.ps1
      Get-YknSshConfig.ps1
    Private/                  # Internal helpers
      ConvertTo-YknNormalizedPath.ps1
      Invoke-YknSshCommand.ps1
    Format/                   # (Optional) .ps1xml view definitions
    Scripts/                  # Legacy wrappers (optional)

tests/
  New-YknSshKey.Tests.ps1
  Test-YknSshHost.Tests.ps1
```

## 🔧 Mapping Existing Scripts → Functions

| Script | Proposed Function(s) | Notes |
|--------|----------------------|-------|
| `Generate-SSHKey.ps1` | `New-YknSshKey` | Parameterize naming + output object |
| `Quick-SSHKey.ps1` | Wrapper for `New-YknSshKey` | Might be deprecated after module |
| `SSH-Connection-Tester.ps1` | `Test-YknSshHost`, `Get-YknSshConfig` | Split parsing vs testing |
| `Quick-SSH-Test.ps1` | Wrapper calling `Test-YknSshHost` | Optional after refactor |
| `Advanced-SSH-Connection-Tester.ps1` | `Measure-YknSshHost` | Extended diagnostics |
| `Set-VSCode-PowerShell-Default.ps1` | `Set-YknVsCodePowerShellDefault` | Could move to sub-module |
| `Fix-VSCode-SSH-Navigator*.ps1` | `Repair-YknVsCodeRemoteSshCache` | Provide confirmation prompts |

## 🧱 Function Design Guidelines

| Aspect | Guideline |
|--------|-----------|
| Naming | Use PascalCase with `Verb-Noun` (approved verbs) |
| Output | Return rich objects, not plain strings |
| Errors | Use `throw` for terminating, `Write-Error` for non-terminating |
| Logging | `Write-Verbose` + `Write-Debug` gated by switches |
| Parameters | Validate with `ValidateSet`, `ValidatePattern`, `ValidateNotNullOrEmpty` |
| Idempotency | Safe to call multiple times without side-effects |

## 🧪 Testing with Pester

Example test (Pester v5):

```powershell
Describe 'New-YknSshKey' {
  It 'creates key pair files' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP (New-Guid))
    $result = New-YknSshKey -User test -Host local -Address 127.0.0.1 -Client temp -OutputPath $tmp.FullName -WhatIf:$false
    Test-Path $result.PrivateKey | Should -BeTrue
    Test-Path $result.PublicKey | Should -BeTrue
  }
}
```

## 🧬 Sample Manifest (`Ykn.SSH.Tools.psd1` skeleton)

```powershell
@{
  RootModule        = 'Ykn.SSH.Tools.psm1'
  ModuleVersion     = '0.1.0'
  GUID              = '00000000-0000-0000-0000-000000000001'
  Author            = 'Yukio Ueno'
  CompanyName       = 'Individual'
  Copyright         = '(c) 2025 Yukio Ueno'
  Description       = 'Utilities for SSH key generation, connection testing, and VS Code integration.'
  PowerShellVersion = '5.1'
  FunctionsToExport = @('New-YknSshKey','Test-YknSshHost','Get-YknSshConfig')
  PrivateData       = @{ PSData = @{ Tags = 'SSH','DevOps','Automation','VSCode','PowerShell' } }
}
```

## 🔗 Module Root (`Ykn.SSH.Tools.psm1` skeleton)

```powershell
# Dot-source all public functions
Get-ChildItem -Path $PSScriptRoot/Public/*.ps1 | ForEach-Object { . $_.FullName }
# Optionally load private helpers
Get-ChildItem -Path $PSScriptRoot/Private/*.ps1 | ForEach-Object { . $_.FullName }
```

## 🛠 Refactor Workflow

1. Extract core logic from monolithic scripts into functions under `Public/` & `Private/`.
2. Ensure each function returns objects (e.g., `[pscustomobject]`).
3. Add Pester tests in `tests/` verifying key behaviors.
4. Create manifest + module root.
5. Update old scripts to call module functions (for backwards compatibility).
6. Add CI workflow (`.github/workflows/ci.yml`) running PSScriptAnalyzer + Pester.
7. Optional: Publish to Gallery with `Publish-Module`.

## 🧪 Local Module Development Usage

```powershell
# From repo root
Import-Module ./modules/Ykn.SSH.Tools/Ykn.SSH.Tools.psd1 -Force
Get-Command -Module Ykn.SSH.Tools
```

## 📦 Publishing (Optional)

```powershell
# After getting API key (Register-PSRepository PSGallery is default)
Publish-Module -Path ./modules/Ykn.SSH.Tools -NuGetApiKey $env:PSGALLERY_KEY
```

## 🔒 Security Considerations

- Never commit private keys
- Consider code-signing: create a self-signed cert and sign functions
- Validate remote host input to avoid command injection

## 🗺 Next Steps (Minimal Path)

1. Create `modules/Ykn.SSH.Tools` folder
2. Write `New-YknSshKey` function file
3. Build manifest & module root
4. Add Pester test for one function
5. Iterate + migrate other scripts

---
Questions welcome—iterate incrementally and keep commits focused.
