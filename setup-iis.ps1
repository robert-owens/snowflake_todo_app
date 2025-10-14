# setup-iis.ps1
# Run as Administrator

Import-Module WebAdministration

$siteName = "HypermediaApp"
$appPoolName = "HypermediaAppPool"
$sitePath = "C:\inetpub\hypermedia-app"
$port = 80
$hostName = "localhost"  # Change to your domain

Write-Host "Setting up IIS site..." -ForegroundColor Cyan

# Create site directory
New-Item -ItemType Directory -Force -Path $sitePath | Out-Null
Write-Host "✓ Created site directory: $sitePath" -ForegroundColor Green

# Create web.config
$webConfig = @'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="ReverseProxyInboundRule" stopProcessing="true">
                    <match url="(.*)" />
                    <action type="Rewrite" url="http://localhost:8080/{R:1}" />
                    <serverVariables>
                        <set name="HTTP_X_ORIGINAL_HOST" value="{HTTP_HOST}" />
                        <set name="HTTP_X_FORWARDED_FOR" value="{REMOTE_ADDR}" />
                        <set name="HTTP_X_FORWARDED_PROTO" value="{HTTPS}" />
                    </serverVariables>
                </rule>
            </rules>
        </rewrite>
        <httpProtocol>
            <customHeaders>
                <add name="X-Content-Type-Options" value="nosniff" />
                <add name="X-Frame-Options" value="SAMEORIGIN" />
            </customHeaders>
        </httpProtocol>
    </system.webServer>
</configuration>
'@

$webConfig | Out-File -FilePath "$sitePath\web.config" -Encoding UTF8
Write-Host "✓ Created web.config" -ForegroundColor Green

# Create Application Pool
if (Test-Path "IIS:\AppPools\$appPoolName") {
    Write-Host "Removing existing app pool..." -ForegroundColor Yellow
    Remove-WebAppPool -Name $appPoolName
}

New-WebAppPool -Name $appPoolName
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value ""
Write-Host "✓ Created application pool: $appPoolName" -ForegroundColor Green

# Create Website
if (Test-Path "IIS:\Sites\$siteName") {
    Write-Host "Removing existing site..." -ForegroundColor Yellow
    Remove-Website -Name $siteName
}

New-Website -Name $siteName `
    -PhysicalPath $sitePath `
    -ApplicationPool $appPoolName `
    -Port $port `
    -HostHeader $hostName

Write-Host "✓ Created website: $siteName" -ForegroundColor Green

# Start the site
Start-Website -Name $siteName
Write-Host "✓ Started website" -ForegroundColor Green

Write-Host ""
Write-Host "IIS site setup complete!" -ForegroundColor Cyan
Write-Host "  Site: $siteName" -ForegroundColor White
Write-Host "  Path: $sitePath" -ForegroundColor White
Write-Host "  Port: $port" -ForegroundColor White
Write-Host "  Host: $hostName" -ForegroundColor White
Write-Host ""
Write-Host "Access your app at: http://$hostName" -ForegroundColor Green
