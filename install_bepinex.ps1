# Helper script to download and install BepInEx 5.4.21.0 x64 without touching locked bootstrapper files
$ErrorActionPreference = "Stop"

$ultrakillDir = "C:\Users\pc\Downloads\ULTRAKILLOyunindir vip\ULTRAKILL.Build.22195083"
$zipPath = Join-Path $env:TEMP "BepInEx_x64_5.4.21.0.zip"
$extractTempDir = Join-Path $env:TEMP "BepInEx_Temp"

if (Test-Path $extractTempDir) {
    Remove-Item -Path $extractTempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $extractTempDir | Out-Null

Write-Host "Downloading BepInEx 5.4.21..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/BepInEx/BepInEx/releases/download/v5.4.21/BepInEx_x64_5.4.21.0.zip" -OutFile $zipPath

Write-Host "Extracting to temp folder..." -ForegroundColor Cyan
Expand-Archive -Path $zipPath -DestinationPath $extractTempDir -Force

Write-Host "Copying BepInEx folders to ULTRAKILL..." -ForegroundColor Cyan
# Copy BepInEx folder itself (contains core, config, patchers, plugins)
if (Test-Path (Join-Path $extractTempDir "BepInEx")) {
    $srcBep = Join-Path $extractTempDir "BepInEx"
    $destBep = Join-Path $ultrakillDir "BepInEx"
    Copy-Item -Path "$srcBep\*" -Destination $destBep -Recurse -Force
}

Write-Host "Cleaning up temp files..." -ForegroundColor Cyan
Remove-Item -Path $zipPath -Force
Remove-Item -Path $extractTempDir -Recurse -Force

Write-Host "BepInEx 5.4.21 core files installed successfully!" -ForegroundColor Green
