# Helper script to download and install PluginConfigurator 1.10.2
$ErrorActionPreference = "Stop"

$ultrakillDir = "C:\Users\pc\Downloads\ULTRAKILLOyunindir vip\ULTRAKILL.Build.22195083"
$zipPath = Join-Path $env:TEMP "PluginConfigurator-1.10.2.zip"
$extractTempDir = Join-Path $env:TEMP "PluginConfigurator_Temp"

if (Test-Path $extractTempDir) {
    Remove-Item -Path $extractTempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $extractTempDir | Out-Null

Write-Host "Downloading PluginConfigurator 1.10.2..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://gcdn.thunderstore.io/live/repository/packages/EternalsTeam-PluginConfigurator-1.10.2.zip" -OutFile $zipPath

Write-Host "Extracting to temp folder..." -ForegroundColor Cyan
Expand-Archive -Path $zipPath -DestinationPath $extractTempDir -Force

Write-Host "Installing PluginConfigurator to BepInEx plugins..." -ForegroundColor Cyan
$destPlugins = Join-Path $ultrakillDir "BepInEx\plugins"
if (-not (Test-Path $destPlugins)) {
    New-Item -ItemType Directory -Path $destPlugins | Out-Null
}

# Copy the DLL and folders to plugins
Copy-Item -Path "$extractTempDir\*" -Destination $destPlugins -Recurse -Force

Write-Host "Cleaning up temp files..." -ForegroundColor Cyan
Remove-Item -Path $zipPath -Force
Remove-Item -Path $extractTempDir -Recurse -Force

Write-Host "PluginConfigurator 1.10.2 installed successfully!" -ForegroundColor Green
