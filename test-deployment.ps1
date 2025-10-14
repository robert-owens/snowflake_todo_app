# test-deployment.ps1

Write-Host "Testing deployment..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Check service
Write-Host "1. Checking Windows Service..." -ForegroundColor Yellow
$service = Get-Service -Name "HypermediaApp" -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq "Running") {
    Write-Host "   ✓ Service is running" -ForegroundColor Green
} else {
    Write-Host "   ✗ Service is not running" -ForegroundColor Red
}

# Test 2: Check direct Go app
Write-Host "2. Testing Go app directly (localhost:8080)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✓ Go app responding: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Go app not responding: $_" -ForegroundColor Red
}

# Test 3: Check IIS site
Write-Host "3. Checking IIS Site..." -ForegroundColor Yellow
$site = Get-Website -Name "HypermediaApp" -ErrorAction SilentlyContinue
if ($site -and $site.State -eq "Started") {
    Write-Host "   ✓ IIS site is started" -ForegroundColor Green
} else {
    Write-Host "   ✗ IIS site is not started" -ForegroundColor Red
}

# Test 4: Check IIS proxy
Write-Host "4. Testing IIS proxy (localhost:80)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost/" -UseBasicParsing -TimeoutSec 5
    Write-Host "   ✓ IIS proxy responding: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ✗ IIS proxy not responding: $_" -ForegroundColor Red
}

# Test 5: Check ARR proxy enabled
Write-Host "5. Checking ARR proxy configuration..." -ForegroundColor Yellow
$proxyEnabled = (Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/proxy" -name "enabled").Value
if ($proxyEnabled) {
    Write-Host "   ✓ ARR proxy is enabled" -ForegroundColor Green
} else {
    Write-Host "   ✗ ARR proxy is not enabled" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testing complete!" -ForegroundColor Cyan
