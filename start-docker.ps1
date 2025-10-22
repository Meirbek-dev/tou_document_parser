# PowerShell script to start Docker Desktop and wait for it to be ready
# Usage: .\start-docker.ps1

Write-Host "Starting Docker Desktop..." -ForegroundColor Cyan

# Try to start Docker Desktop
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

if (Test-Path $dockerPath) {
    Start-Process $dockerPath
    Write-Host "Docker Desktop is starting..." -ForegroundColor Yellow
    Write-Host "This may take 1-2 minutes. Please wait..." -ForegroundColor Yellow

    # Wait for Docker to be ready
    $maxAttempts = 60
    $attempt = 0
    $ready = $false

    while (-not $ready -and $attempt -lt $maxAttempts) {
        Start-Sleep -Seconds 2
        $attempt++

        try {
            $result = docker version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $ready = $true
                Write-Host ""
                Write-Host "✓ Docker Desktop is ready!" -ForegroundColor Green
                Write-Host ""
                docker version
            }
        } catch {
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
    }

    if (-not $ready) {
        Write-Host ""
        Write-Host "⚠ Docker Desktop is taking longer than expected to start." -ForegroundColor Yellow
        Write-Host "Please check Docker Desktop manually and ensure it's running." -ForegroundColor Yellow
    }
} else {
    Write-Host "Error: Docker Desktop not found at: $dockerPath" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
}
