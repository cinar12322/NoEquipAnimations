# ULTRAKILL No Equip Animation Mod Build Script

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Locating ULTRAKILL Installation..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Detect Steam and ULTRAKILL installation path
$steamPath = $null
try {
    $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
    if (-not $steamPath) {
        $steamPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Valve\Steam" -ErrorAction SilentlyContinue).InstallPath
    }
} catch {}

if (-not $steamPath) {
    $steamPath = "C:\Program Files (x86)\Steam"
}

$libraryFolders = @($steamPath)
if (Test-Path "$steamPath\steamapps\libraryfolders.vdf") {
    $vdfContent = Get-Content "$steamPath\steamapps\libraryfolders.vdf" -Raw
    $matches = [regex]::Matches($vdfContent, '"path"\s+"([^"]+)"')
    foreach ($match in $matches) {
        $cleanPath = $match.Groups[1].Value.Replace("\\", "\")
        if ($libraryFolders -notcontains $cleanPath) {
            $libraryFolders += $cleanPath
        }
    }
}

$ultrakillPaths = @()
foreach ($folder in $libraryFolders) {
    $ultrakillPaths += Join-Path $folder "steamapps\common\ULTRAKILL"
}
$ultrakillPaths += "C:\Users\pc\Downloads\ULTRAKILLOyunindir vip\ULTRAKILL.Build.22195083"
$ultrakillPaths += "C:\Program Files (x86)\Steam\steamapps\common\ULTRAKILL"
$ultrakillPaths += "C:\Program Files\Steam\steamapps\common\ULTRAKILL"
$ultrakillPaths += "D:\SteamLibrary\steamapps\common\ULTRAKILL"
$ultrakillPaths += "E:\SteamLibrary\steamapps\common\ULTRAKILL"

$ultrakillPath = $null
foreach ($path in $ultrakillPaths) {
    if (Test-Path "$path\ULTRAKILL.exe") {
        $ultrakillPath = $path
        break
    }
}

if (-not $ultrakillPath) {
    Write-Error "Could not locate ULTRAKILL installation! Please make sure the game is installed via Steam."
}

Write-Host "Found ULTRAKILL at: $ultrakillPath" -ForegroundColor Green

# 2. Verify dependencies
$managedDir = Join-Path $ultrakillPath "ULTRAKILL_Data\Managed"
$bepinexCoreDir = Join-Path $ultrakillPath "BepInEx\core"
$bepinexPluginsDir = Join-Path $ultrakillPath "BepInEx\plugins"

Write-Host "Verifying game and mod dependencies..." -ForegroundColor Cyan

$requiredDlls = @{
    "Assembly-CSharp" = Join-Path $managedDir "Assembly-CSharp.dll"
    "UnityEngine" = Join-Path $managedDir "UnityEngine.dll"
    "UnityEngine.CoreModule" = Join-Path $managedDir "UnityEngine.CoreModule.dll"
    "UnityEngine.AnimationModule" = Join-Path $managedDir "UnityEngine.AnimationModule.dll"
    "UnityEngine.InputLegacyModule" = Join-Path $managedDir "UnityEngine.InputLegacyModule.dll"
    "BepInEx" = Join-Path $bepinexCoreDir "BepInEx.dll"
    "0Harmony" = Join-Path $bepinexCoreDir "0Harmony.dll"
}

foreach ($dll in $requiredDlls.Keys) {
    $path = $requiredDlls[$dll]
    if (-not (Test-Path $path)) {
        if ($dll -eq "BepInEx" -or $dll -eq "0Harmony") {
            Write-Error "Could not find $dll DLL at: $path`nPlease install BepInEx 5 for ULTRAKILL first."
        } else {
            Write-Error "Could not find game assembly: $path"
        }
    }
}

Write-Host "All core dependencies verified successfully." -ForegroundColor Green

# Check if PluginConfigurator exists
$pluginConfiguratorPath = Join-Path $bepinexPluginsDir "plugins\PluginConfigurator\PluginConfigurator.dll"
if (-not (Test-Path $pluginConfiguratorPath)) {
    $pluginConfiguratorPath = Join-Path $bepinexPluginsDir "EternalsTeam-PluginConfigurator\PluginConfigurator\PluginConfigurator.dll"
}
if (-not (Test-Path $pluginConfiguratorPath)) {
    $pluginConfiguratorPath = Join-Path $bepinexPluginsDir "PluginConfigurator.dll"
}

if (Test-Path $pluginConfiguratorPath) {
    Write-Host "PluginConfigurator detected at: $pluginConfiguratorPath" -ForegroundColor Green
    Write-Host "Enabling PluginConfigurator menu integration." -ForegroundColor Green
    $hasPluginConfigurator = "true"
} else {
    Write-Host "PluginConfigurator not found. Using standard BepInEx config only." -ForegroundColor Yellow
    $hasPluginConfigurator = "false"
}

# 3. Create a temporary properties file for MSBuild/dotnet build
Write-Host "Configuring build references..." -ForegroundColor Cyan
$propsContent = @"
<Project>
  <PropertyGroup>
    <UltrakillPath>$ultrakillPath</UltrakillPath>
    <HasPluginConfigurator>$hasPluginConfigurator</HasPluginConfigurator>
  </PropertyGroup>
</Project>
"@
$propsContent | Out-File -FilePath (Join-Path $PSScriptRoot "Directory.Build.props") -Encoding utf8 -Force

# 4. Find compiler (MSBuild or dotnet CLI)
$compilerPath = $null
$compilerArgs = ""

# Try dotnet build first
if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
    $compilerPath = "dotnet"
    $compilerArgs = "build -c Release"
    Write-Host "Using Dotnet CLI compiler." -ForegroundColor Green
} else {
    # Find MSBuild via vswhere
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsPath = & $vswhere -latest -property installationPath
        if ($vsPath) {
            $msbuildPaths = @(
                (Join-Path $vsPath "MSBuild\Current\Bin\MSBuild.exe"),
                (Join-Path $vsPath "MSBuild\15.0\Bin\MSBuild.exe")
            )
            foreach ($mPath in $msbuildPaths) {
                if (Test-Path $mPath) {
                    $compilerPath = $mPath
                    $compilerArgs = "/p:Configuration=Release"
                    Write-Host "Using Visual Studio MSBuild compiler: $mPath" -ForegroundColor Green
                    break
                }
            }
        }
    }
}

if (-not $compilerPath) {
    Write-Error "Could not find a suitable compiler (MSBuild or Dotnet CLI)! Please install Visual Studio Build Tools or the .NET SDK."
}

# 5. Run compilation
Write-Host "Compiling project..." -ForegroundColor Cyan
if ($compilerPath -eq "dotnet") {
    dotnet build -c Release
} else {
    & $compilerPath /p:Configuration=Release
}

Write-Host "=========================================" -ForegroundColor Green
Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 6. Deploy to BepInEx
$outputDll = Join-Path $PSScriptRoot "bin\Release\NoEquipAnimation.dll"
if (Test-Path $outputDll) {
    # Standard deploy
    $targetDir = Join-Path $bepinexPluginsDir "NoEquipAnimation"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }
    Copy-Item -Path $outputDll -Destination $targetDir -Force
    Write-Host "Mod deployed successfully to game folder: $targetDir" -ForegroundColor Green

    # Gale deploy
    $galeDir = "C:\Users\pc\AppData\Roaming\com.kesomannen.gale\ultrakill\profiles\Default\BepInEx\plugins"
    if (Test-Path $galeDir) {
        $galeTargetDir = Join-Path $galeDir "NoEquipAnimation"
        if (-not (Test-Path $galeTargetDir)) {
            New-Item -ItemType Directory -Path $galeTargetDir | Out-Null
        }
        Copy-Item -Path $outputDll -Destination $galeTargetDir -Force
        Write-Host "Mod deployed successfully to Gale profile: $galeTargetDir" -ForegroundColor Green
    }
} else {
    Write-Error "Compiled DLL not found at: $outputDll"
}
