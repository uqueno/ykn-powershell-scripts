# SSH Key Generator Script
# Follows naming convention: {hosting}_{encryption}_{timestamp}_{protocol}_{username@instance|hostname}_{client}
# Parameters: 1) hosting, 2) encryption, 3) timestamp, 4) protocol, 5) username@instance|hostname, 6) client

param(
    [Parameter(Mandatory=$true)]
    [string]$Hosting = "contabo-vps",
    
    [Parameter(Mandatory=$true)]
    [string]$Encryption = "ed25519-key",
    
    [Parameter(Mandatory=$false)]
    [string]$Timestamp = (Get-Date -Format "yyyyMMdd"),
    
    [Parameter(Mandatory=$true)]
    [string]$Protocol = "ssh",
    
    [Parameter(Mandatory=$true)]
    [string]$UserInstance = "portainer@vmi2747748",
    
    [Parameter(Mandatory=$true)]
    [string]$Client = "zest"
)

# Function to generate SSH key with proper naming convention
function New-SSHKeyPair {
    param(
        [string]$Hosting,
        [string]$Encryption,
        [string]$Timestamp,
        [string]$Protocol,
        [string]$UserInstance,
        [string]$Client
    )
    
    # Create the key name following the convention
    $KeyName = "${Hosting}_${Encryption}_${Timestamp}_${Protocol}_${UserInstance}_${Client}"
    
    # Define paths
    $SSHDir = "$env:USERPROFILE\.ssh"
    $PrivateKeyPath = "$SSHDir\$KeyName"
    $PublicKeyPath = "$SSHDir\$KeyName.pub"
    
    # Ensure .ssh directory exists
    if (!(Test-Path $SSHDir)) {
        Write-Host "Creating .ssh directory: $SSHDir" -ForegroundColor Green
        New-Item -ItemType Directory -Path $SSHDir -Force | Out-Null
    }
    
    # Generate the SSH key
    Write-Host "Generating SSH key pair..." -ForegroundColor Cyan
    Write-Host "Key name: $KeyName" -ForegroundColor Yellow
    Write-Host "Private key: $PrivateKeyPath" -ForegroundColor Yellow
    Write-Host "Public key: $PublicKeyPath" -ForegroundColor Yellow
    
    # Execute ssh-keygen command
    $sshKeygenArgs = @(
        "-t", "ed25519",
        "-C", $KeyName,
        "-f", $PrivateKeyPath,
        "-N", '""'
    )
    
    try {
        & ssh-keygen @sshKeygenArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nSSH key pair generated successfully!" -ForegroundColor Green
            
            # Set proper permissions on private key
            Write-Host "Setting secure permissions on private key..." -ForegroundColor Cyan
            icacls $PrivateKeyPath /inheritance:r /grant "${env:USERNAME}:(F)" | Out-Null
            
            # Set proper permissions on public key
            Write-Host "Setting secure permissions on public key..." -ForegroundColor Cyan
            icacls $PublicKeyPath /inheritance:r /grant "${env:USERNAME}:(F)" | Out-Null
            
            # Display key information
            Write-Host "`n" + "="*60 -ForegroundColor Green
            Write-Host "SSH KEY PAIR INFORMATION" -ForegroundColor Green
            Write-Host "="*60 -ForegroundColor Green
            
            Write-Host "`nPrivate Key Path: " -NoNewline -ForegroundColor White
            Write-Host $PrivateKeyPath -ForegroundColor Yellow
            
            Write-Host "Public Key Path:  " -NoNewline -ForegroundColor White
            Write-Host $PublicKeyPath -ForegroundColor Yellow
            
            # Show fingerprint
            Write-Host "`nKey Fingerprint:" -ForegroundColor White
            & ssh-keygen -lf $PublicKeyPath
            
            # Display public key content
            Write-Host "`nPublic Key Content (for server authorization):" -ForegroundColor White
            Write-Host "-"*50 -ForegroundColor Gray
            Get-Content $PublicKeyPath | Write-Host -ForegroundColor Cyan
            Write-Host "-"*50 -ForegroundColor Gray
            
            # Show file details
            Write-Host "`nFile Details:" -ForegroundColor White
            Get-ChildItem $PrivateKeyPath, $PublicKeyPath | Format-Table Name, Length, LastWriteTime -AutoSize
            
            Write-Host "`nNext Steps:" -ForegroundColor Green
            Write-Host "1. Add the public key to your server's ~/.ssh/authorized_keys file" -ForegroundColor White
            Write-Host "2. Use the private key path in VS Code Remote-SSH extension" -ForegroundColor White
            Write-Host "3. Test the connection: ssh -i `"$PrivateKeyPath`" user@server" -ForegroundColor White
            
        } else {
            Write-Error "Failed to generate SSH key pair. Exit code: $LASTEXITCODE"
        }
        
    } catch {
        Write-Error "Error generating SSH key: $($_.Exception.Message)"
    }
}

# Main execution
Write-Host "SSH Key Generator" -ForegroundColor Magenta
Write-Host "=================" -ForegroundColor Magenta
Write-Host "Naming Convention: {hosting}_{encryption}_{timestamp}_{protocol}_{username@instance}_{client}" -ForegroundColor Gray

# Generate the SSH key pair
New-SSHKeyPair -Hosting $Hosting -Encryption $Encryption -Timestamp $Timestamp -Protocol $Protocol -UserInstance $UserInstance -Client $Client

Write-Host "`nScript completed!" -ForegroundColor Green