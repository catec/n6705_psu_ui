@echo off
REM Author: Mouhsine Kassimi Farhaoui
REM Mail: mouhsine98@gmail.com
REM
REM @file packaging/windows/build_installer.cmd
REM @brief Wrapper to run installer build script without changing PowerShell policy.

setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%build_installer.ps1"

if not exist "%PS_SCRIPT%" (
  echo [ERROR] build_installer.ps1 not found: "%PS_SCRIPT%"
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo [ERROR] Build failed with exit code %EXIT_CODE%.
  exit /b %EXIT_CODE%
)

echo [OK] Build completed.
exit /b 0
