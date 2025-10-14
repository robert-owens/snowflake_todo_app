# build-windows.ps1
Write-Host "Building for Windows..." -ForegroundColor Cyan

$env:GOOS="windows"
$env:GOARCH="amd64"
$env:CGO_ENABLED="0"

# Generate templ files
Write-Host "Generating templ files..." -ForegroundColor Yellow
templ generate

# Build
Write-Host "Building executable..." -ForegroundColor Yellow
go build -o hypermedia-app.exe ./cmd/server

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Build complete: hypermedia-app.exe" -ForegroundColor Green
} else {
    Write-Host "✗ Build failed!" -ForegroundColor Red
    exit 1
}
