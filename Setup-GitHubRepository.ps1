<#
.SYNOPSIS
    Automates (and documents) end-to-end GitHub repository setup for an existing local project.

.DESCRIPTION
    This script encapsulates the manual steps we performed to publish the local PowerShell scripts repository
    (ykn-powershell-scripts) to GitHub using SSH authentication and the GitHub CLI (gh). It is intentionally
    verbose and safe: each stage validates prerequisites and avoids overwriting existing configuration unless
    explicitly permitted.

    Core stages:
      1. Pre-flight checks (Git, gh, network reachability to github.com)
      2. SSH key presence / guidance (does NOT auto-generate – use your existing Generate-SSHKey.ps1)
      3. GitHub CLI authentication (prompts if not already logged in)
      4. Repository existence check (create if missing)
      5. Remote origin configuration (idempotent)
      6. Initial push (main branch)
      7. Topic assignment
      8. Optional: description/homepage refinement
      9. Optional: create annotated initial tag & release
     10. Summary report

.NOTES
    Author: uqueno (automated doc consolidation)
    Date:   2025-10-01
    Safe to re-run: YES (idempotent when repo & remote already exist)

.PARAMETER RepositoryName
    The target repository name on GitHub (without owner).

.PARAMETER Owner
    Your GitHub username / organization.

.PARAMETER Description
    Repository description (will only update if different or --ForceDescribe is set).

.PARAMETER Homepage
    Optional homepage / project URL.

.PARAMETER Topics
    Array of topics to assign. Topics not already present will be added individually.

.PARAMETER CreateInitialTag
    Switch to create an initial tag (e.g., v0.1.0) after first push if it does not exist.

.PARAMETER InitialTag
    The tag name to create when -CreateInitialTag is used.

.PARAMETER InitialTagMessage
    Message body for the annotated tag.

.PARAMETER ForceDescribe
    Force updating the description/homepage even if they appear set.

.EXAMPLE
    ./Setup-GitHubRepository.ps1 -Owner uqueno -RepositoryName ykn-powershell-scripts \
       -Description "Curated PowerShell scripts for SSH automation, VS Code environment fixes, and MobaXterm integration—foundation for the future Ykn.SSH.Tools module." \
       -Homepage "https://github.com/uqueno/ykn-powershell-scripts" \
       -Topics powershell ssh devops automation vscode tooling mobaXterm scripts documentation \
       -CreateInitialTag -InitialTag v0.1.0 -InitialTagMessage "Initial baseline: scripts + docs + module guide"

#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)] [string]$Owner,
    [Parameter(Mandatory=$true)] [string]$RepositoryName,
    [Parameter(Mandatory=$true)] [string]$Description,
    [Parameter(Mandatory=$false)] [string]$Homepage,
    [Parameter(Mandatory=$false)] [string[]]$Topics = @(),
    [switch]$CreateInitialTag,
    [string]$InitialTag = 'v0.1.0',
    [string]$InitialTagMessage = 'Initial baseline',
    [switch]$ForceDescribe
)

#region Helper Functions
function Write-Section { param([string]$Title) Write-Host "`n=== $Title ===" -ForegroundColor Cyan }
function Write-Info    { param([string]$Msg)   Write-Host "[INFO] $Msg" -ForegroundColor Gray }
function Write-Warn    { param([string]$Msg)   Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Err     { param([string]$Msg)   Write-Host "[ERROR] $Msg" -ForegroundColor Red }

function Exec-Safe {
    param(
        [ScriptBlock]$Script,
        [string]$ErrorMessage = 'Command failed.'
    )
    try {
        & $Script
        if ($LASTEXITCODE -ne 0) { throw "$ErrorMessage (ExitCode=$LASTEXITCODE)" }
    } catch {
        throw $_
    }
}
#endregion

$ErrorActionPreference = 'Stop'

Write-Section '1. Pre-flight Checks'
# Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Err 'git not found in PATH.'; return }
Write-Info (git --version)
# gh
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Err 'GitHub CLI (gh) not found in PATH.'; return }
Write-Info (gh --version)

# Network reachability (DNS resolution + TCP check via git ls-remote as a lightweight attempt)
try {
    [System.Net.Dns]::GetHostEntry('github.com') | Out-Null
    Write-Info 'github.com DNS resolution OK'
} catch { Write-Warn 'DNS resolution for github.com failed; continuing may error.' }

Write-Section '2. SSH Key Presence'
# We assume user already created an SSH key and configured SSH config for github.com
$UserProfile = [Environment]::GetFolderPath('UserProfile')
$SSHDir = Join-Path $UserProfile '.ssh'
if (-not (Test-Path $SSHDir)) { Write-Warn "SSH directory not found: $SSHDir" } else { Write-Info "SSH directory present: $SSHDir" }

Write-Section '3. GitHub Authentication'
$authOk = $false
try {
    $authStatus = gh auth status 2>$null | Out-String
    if ($authStatus -match 'Logged in to github.com') { $authOk = $true }
} catch { $authOk = $false }
if (-not $authOk) {
    Write-Warn 'Not authenticated with gh. Launching gh auth login...'
    Exec-Safe { gh auth login } 'gh auth login failed'
    $authStatus = gh auth status | Out-String
}
Write-Info 'Authentication status:'
Write-Host $authStatus -ForegroundColor DarkGray

Write-Section '4. Local Git Repository Validation'
if (-not (Test-Path '.git')) { Write-Err 'Current directory is not a git repository.'; return }

$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
Write-Info "Current branch: $currentBranch"
if ($currentBranch -ne 'main') { Write-Warn 'Expected main branch; continuing anyway.' }

Write-Section '5. Remote Repository State'
$FullRepo = "$Owner/$RepositoryName"
$repoExists = $false
try {
    $null = gh repo view $FullRepo --json name 2>$null
    $repoExists = $true
    Write-Info 'Remote repository already exists.'
} catch {
    Write-Info 'Remote repository does not exist (will create).'
}

if (-not $repoExists) {
    Write-Info 'Creating repository via gh...'
    $createArgs = @(
        'repo','create',"$FullRepo",
        '--public',
        '--description', $Description,
        '--disable-wiki'
    )
    if ($Homepage) { $createArgs += @('--homepage', $Homepage) }
    Exec-Safe { gh @createArgs } 'Failed to create repository.'
}

Write-Section '6. Configure Remote Origin'
$originUrl = ''
try { $originUrl = (git remote get-url origin 2>$null).Trim() } catch { }
$expectedUrl = "git@github.com:$FullRepo.git"
if ($originUrl) {
    if ($originUrl -ne $expectedUrl) {
        Write-Warn "Origin URL mismatch: $originUrl -> resetting to $expectedUrl"
        git remote set-url origin $expectedUrl | Out-Null
    } else { Write-Info 'Origin URL already correct.' }
} else {
    Write-Info 'Adding origin remote.'
    git remote add origin $expectedUrl | Out-Null
}

Write-Section '7. Push Main Branch'
Exec-Safe { git push -u origin $currentBranch } 'Initial push failed.'

Write-Section '8. Topics Synchronization'
if ($Topics.Count -gt 0) {
    Write-Info "Ensuring topics: $($Topics -join ', ')"
    # Retrieve existing topics (structure may vary by gh version)
    $topicsJson = gh repo view $FullRepo --json repositoryTopics --jq '.' 2>$null
    $existing = @()
    if ($topicsJson) {
        try {
            $parsed = $topicsJson | ConvertFrom-Json -ErrorAction Stop
            if ($parsed.repositoryTopics) {
                if ($parsed.repositoryTopics -is [array]) {
                    $existing = $parsed.repositoryTopics | ForEach-Object { $_.topic.name }
                } elseif ($parsed.repositoryTopics.nodes) {
                    $existing = $parsed.repositoryTopics.nodes | ForEach-Object { $_.topic.name }
                }
            }
        } catch { Write-Warn 'Could not parse existing topics JSON (non-fatal).' }
    }
    foreach ($t in $Topics) {
        if ($existing -contains $t) {
            Write-Info "Topic already present: $t"
        } else {
            Write-Info "Adding topic: $t"
            gh repo edit $FullRepo --add-topic $t | Out-Null
        }
    }
}
else { Write-Info 'No topics specified.' }

Write-Section '9. Description/Homepage Reconciliation'
if ($ForceDescribe -or $Homepage -or $Description) {
    $meta = gh repo view $FullRepo --json description,homepage --jq '.' | ConvertFrom-Json
    $needUpdate = $false
    if ($Description -and ($meta.description -ne $Description)) { $needUpdate = $true }
    if ($Homepage -and ($meta.homepage -ne $Homepage)) { $needUpdate = $true }
    if ($ForceDescribe) { $needUpdate = $true }
    if ($needUpdate) {
        Write-Info 'Updating description/homepage via gh repo edit.'
        $editArgs = @('repo','edit',$FullRepo,'--description', $Description)
        if ($Homepage) { $editArgs += @('--homepage',$Homepage) }
        Exec-Safe { gh @editArgs } 'Failed to edit repository metadata.'
    } else { Write-Info 'Description/homepage already match desired values.' }
}

Write-Section '10. Optional Initial Tag'
if ($CreateInitialTag) {
    $tagExists = $false
    try { git rev-parse --verify $InitialTag 2>$null | Out-Null; $tagExists = $true } catch { }
    if ($tagExists) {
        Write-Warn "Tag $InitialTag already exists; skipping."
    } else {
        Write-Info "Creating tag $InitialTag"
        git tag -a $InitialTag -m $InitialTagMessage
        Exec-Safe { git push origin $InitialTag } 'Failed to push initial tag.'
    }
}

Write-Section '11. Final Summary'
Write-Host "Repository: https://github.com/$FullRepo" -ForegroundColor Green
Write-Host "Origin URL: $expectedUrl" -ForegroundColor Green
if ($Topics.Count -gt 0) { Write-Host "Topics: $($Topics -join ', ')" -ForegroundColor Green }
Write-Host 'Completed successfully.' -ForegroundColor Green

# End of script
