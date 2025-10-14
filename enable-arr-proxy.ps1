# enable-arr-proxy.ps1
# Run as Administrator

Write-Host "Enabling ARR Proxy..." -ForegroundColor Cyan

try {
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
        -filter "system.webServer/proxy" `
        -name "enabled" `
        -value "True"

    Write-Host "✓ ARR Proxy enabled" -ForegroundColor Green

    # Optional: Set response buffer limit
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
        -filter "system.webServer/proxy" `
        -name "responseBufferLimit" `
        -value 0

    Write-Host "✓ Response buffer limit set" -ForegroundColor Green

    # Restart IIS to apply changes
    Write-Host "Restarting IIS..." -ForegroundColor Yellow
    iisreset

    Write-Host "✓ ARR Proxy configuration complete!" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to enable ARR Proxy: $_" -ForegroundColor Red
}
