# setup-deployment.ps1
# Run as Administrator

param(
    [string]$DeployPath = "C:\Apps\HypermediaApp"
)

Write-Host "Setting up deployment directory..." -ForegroundColor Cyan

# Create deployment directory
New-Item -ItemType Directory -Force -Path $DeployPath | Out-Null
Write-Host "✓ Created directory: $DeployPath" -ForegroundColor Green

# Copy application files
Write-Host "Copying application files..." -ForegroundColor Yellow
Copy-Item -Path "hypermedia-app.exe" -Destination $DeployPath -Force
Copy-Item -Path "static" -Destination $DeployPath -Recurse -Force

Write-Host "✓ Files copied successfully" -ForegroundColor Green

# Set permissions
$acl = Get-Acl $DeployPath
$permission = "NT AUTHORITY\NETWORK SERVICE", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl $DeployPath $acl

Write-Host "✓ Permissions set" -ForegroundColor Green
Write-Host "Deployment directory ready: $DeployPath" -ForegroundColor Cyan
