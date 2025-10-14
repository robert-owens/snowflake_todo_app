# install-service.ps1
# Run as Administrator

param(
    [string]$DeployPath = "C:\Apps\HypermediaApp"
)

$serviceName = "HypermediaApp"
$displayName = "Hypermedia Application"
$description = "Go-based hypermedia application with Echo and Snowflake"
$exePath = "$DeployPath\hypermedia-app.exe"

Write-Host "Installing Windows Service..." -ForegroundColor Cyan

# Check if executable exists
if (-not (Test-Path $exePath)) {
    Write-Host "✗ Executable not found: $exePath" -ForegroundColor Red
    Write-Host "Please run setup-deployment.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check if service exists
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    Write-Host "Service already exists. Stopping and removing..." -ForegroundColor Yellow
    Stop-Service -Name $serviceName -Force
    sc.exe delete $serviceName
    Start-Sleep -Seconds 2
}

# Create the service
Write-Host "Creating service..." -ForegroundColor Yellow
New-Service -Name $serviceName `
    -BinaryPathName $exePath `
    -DisplayName $displayName `
    -Description $description `
    -StartupType Automatic

# Create event log source
New-EventLog -LogName Application -Source $serviceName -ErrorAction SilentlyContinue
Write-Host "✓ Event log source created" -ForegroundColor Green

# Start the service
Write-Host "Starting service..." -ForegroundColor Yellow
Start-Service -Name $serviceName

# Wait and check status
Start-Sleep -Seconds 3
$service = Get-Service -Name $serviceName

if ($service.Status -eq "Running") {
    Write-Host "✓ Service installed and started successfully!" -ForegroundColor Green
    Write-Host "  Status: $($service.Status)" -ForegroundColor Green
} else {
    Write-Host "✗ Service installed but not running!" -ForegroundColor Red
    Write-Host "  Status: $($service.Status)" -ForegroundColor Red
    Write-Host "  Check Event Viewer for errors" -ForegroundColor Yellow
}

# Test health endpoint
Write-Host ""
Write-Host "Testing health endpoint..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing
    Write-Host "✓ Health check passed: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "✗ Health check failed: $_" -ForegroundColor Red
}
