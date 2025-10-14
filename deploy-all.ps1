# deploy-all.ps1
# Complete deployment automation
# Run as Administrator

param(
    [string]$DeployPath = "C:\Apps\HypermediaApp"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Complete Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build
Write-Host "Step 1: Building application..." -ForegroundColor Yellow
.\build-windows.ps1
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed!"; exit 1 }

# Step 2: Setup deployment directory
Write-Host ""
Write-Host "Step 2: Setting up deployment directory..." -ForegroundColor Yellow
.\setup-deployment.ps1 -DeployPath $DeployPath

# Step 3: Set environment variables (prompt user)
Write-Host ""
Write-Host "Step 3: Environment Variables" -ForegroundColor Yellow
Write-Host "Please ensure you've updated set-env-vars.ps1 with your credentials" -ForegroundColor Yellow
$response = Read-Host "Have you configured environment variables? (Y/N)"
if ($response -ne "Y") {
    Write-Host "Please run set-env-vars.ps1 manually first" -ForegroundColor Red
    exit 1
}

# Step 4: Install service
Write-Host ""
Write-Host "Step 4: Installing Windows Service..." -ForegroundColor Yellow
.\install-service.ps1 -DeployPath $DeployPath

# Step 5: Setup IIS
Write-Host ""
Write-Host "Step 5: Setting up IIS..." -ForegroundColor Yellow
.\setup-iis.ps1

# Step 6: Enable ARR
Write-Host ""
Write-Host "Step 6: Enabling ARR Proxy..." -ForegroundColor Yellow
.\enable-arr-proxy.ps1

# Step 7: Test
Write-Host ""
Write-Host "Step 7: Testing deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
.\test-deployment.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application at: http://localhost" -ForegroundColor Cyan
