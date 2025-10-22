# PowerShell script to transfer files to server
# Usage: .\transfer-to-server.ps1 -Server "user@server-ip"

param(
    [Parameter(Mandatory=$true)]
    [string]$Server,

    [string]$RemoteDir = "/opt/tou_document_parser"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Transfer Files to Server" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Server: $Server"
Write-Host "Remote Directory: $RemoteDir"
Write-Host ""

# Check if ssh is available
try {
    ssh -V 2>&1 | Out-Null
} catch {
    Write-Host "Error: SSH not found. Please install OpenSSH or use WSL." -ForegroundColor Red
    exit 1
}

# Check if scp is available
try {
    scp 2>&1 | Out-Null
} catch {
    Write-Host "Error: SCP not found. Please install OpenSSH or use WSL." -ForegroundColor Red
    exit 1
}

# Create remote directory
Write-Host "Creating remote directory..." -ForegroundColor Yellow
ssh $Server "mkdir -p $RemoteDir"

# List of files to transfer
$files = @(
    "Dockerfile",
    "Dockerfile.production",
    "docker-compose.yml",
    "server.py",
    "pyproject.toml",
    "nginx.conf",
    "deploy.sh"
)

# Transfer individual files
Write-Host "Transferring files..." -ForegroundColor Yellow
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  → $file" -ForegroundColor Gray
        scp $file "${Server}:${RemoteDir}/"
    } else {
        Write-Host "  ⚠ $file not found, skipping..." -ForegroundColor DarkYellow
    }
}

# Transfer directories
Write-Host "Transferring directories..." -ForegroundColor Yellow

if (Test-Path "web") {
    Write-Host "  → web/" -ForegroundColor Gray
    scp -r web "${Server}:${RemoteDir}/"
}

if (Test-Path "build/flutter_assets") {
    Write-Host "  → build/" -ForegroundColor Gray
    ssh $Server "mkdir -p ${RemoteDir}/build"
    scp -r build/flutter_assets "${Server}:${RemoteDir}/build/"
}

Write-Host ""
Write-Host "✓ Files transferred successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. SSH into your server: ssh $Server"
Write-Host "2. Navigate to directory: cd $RemoteDir"
Write-Host "3. Run deployment: chmod +x deploy.sh && ./deploy.sh"
Write-Host ""

# Ask if user wants to SSH now
$response = Read-Host "Do you want to SSH into the server now? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    ssh $Server
}
