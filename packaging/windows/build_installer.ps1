<#
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file packaging/windows/build_installer.ps1
@brief Build Windows distributable (PyInstaller) and setup installer (Inno Setup).
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
#>

param(
    [string]$PythonExe = "python",
    [string]$AppVersion = "1.0.0",
    [switch]$SkipTests,
    [switch]$SkipInstaller,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$BuildRoot = Join-Path $RepoRoot "build\windows"
$DistRoot = Join-Path $RepoRoot "dist\windows"
$AppDistRoot = Join-Path $DistRoot "app"
$VenvPath = Join-Path $RepoRoot ".venv-build"

if ($Clean) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $BuildRoot
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $DistRoot
}

New-Item -ItemType Directory -Force -Path $BuildRoot | Out-Null
New-Item -ItemType Directory -Force -Path $DistRoot | Out-Null

if (-not (Test-Path (Join-Path $VenvPath "Scripts\python.exe"))) {
    & $PythonExe -m venv $VenvPath
}

$Py = Join-Path $VenvPath "Scripts\python.exe"
$Pip = Join-Path $VenvPath "Scripts\pip.exe"

& $Py -m pip install --upgrade pip setuptools wheel
& $Pip install -r (Join-Path $RepoRoot "requirements.txt")
& $Pip install pyinstaller pyinstaller-hooks-contrib pillow

if (-not $SkipTests) {
    & $Py -m unittest discover -s (Join-Path $RepoRoot "tests") -v
}

$SvgIcon = Join-Path $RepoRoot "assets\icons\n6705_app_icon.svg"
$IcoIcon = Join-Path $BuildRoot "n6705_app_icon.ico"
& $Py (Join-Path $RepoRoot "packaging\windows\make_icon.py") --svg $SvgIcon --ico $IcoIcon
$IconReady = ($LASTEXITCODE -eq 0) -and (Test-Path $IcoIcon)
if (-not $IconReady) {
    Write-Warning "Icon generation failed; continuing build without EXE icon."
}

$PyInstallerArgs = @(
    "-m", "PyInstaller",
    "--noconfirm",
    "--clean",
    "--windowed",
    "--name", "N6705PowerConsole",
    "--distpath", $AppDistRoot,
    "--workpath", (Join-Path $BuildRoot "pyinstaller-work"),
    "--specpath", (Join-Path $BuildRoot "pyinstaller-spec"),
    "--collect-all", "PySide6",
    "--add-data", "$RepoRoot\n6705_ui\presentation\qml;n6705_ui\presentation\qml",
    "--add-data", "$RepoRoot\assets;assets",
    "--add-data", "$RepoRoot\doc;doc",
    (Join-Path $RepoRoot "app.py")
)

if ($IconReady) {
    $PyInstallerArgs += @("--icon", $IcoIcon)
}

& $Py @PyInstallerArgs

$BuiltExe = Join-Path $AppDistRoot "N6705PowerConsole\N6705PowerConsole.exe"
if (-not (Test-Path $BuiltExe)) {
    throw "PyInstaller output missing: $BuiltExe"
}

if ($SkipInstaller) {
    Write-Host "App build ready: $BuiltExe"
    exit 0
}

$IsccCmd = Get-Command iscc.exe -ErrorAction SilentlyContinue
$IsccPath = $null

if ($IsccCmd) {
    $IsccPath = $IsccCmd.Source
} else {
    $candidates = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $IsccPath = $candidate
            break
        }
    }
}

if (-not $IsccPath) {
    throw "Inno Setup Compiler (ISCC.exe) not found. Install Inno Setup 6 or add ISCC.exe to PATH."
}

$InstallerInputExe = Join-Path $RepoRoot "dist\windows\app\N6705PowerConsole\N6705PowerConsole.exe"
if (-not (Test-Path $InstallerInputExe)) {
    throw "Installer input EXE not found: $InstallerInputExe"
}

& $IsccPath `
    "/DSourceRoot=$RepoRoot" `
    "/DAppVersion=$AppVersion" `
    (Join-Path $RepoRoot "packaging\windows\installer.iss")

if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed with exit code $LASTEXITCODE."
}

Write-Host "Installer build completed under: $(Join-Path $DistRoot 'installer')"
