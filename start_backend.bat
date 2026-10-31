@echo off
title Intelligent Land Measurement - Backend Server (MongoDB Atlas)
echo ================================================================
echo  Intelligent Land Measurement - Backend Server (MongoDB Atlas)
echo ================================================================

:: Check for ADB and set up reverse port-forwarding for connected phones
set "ADB_EXE=adb"
where adb >nul 2>nul
if %errorlevel% neq 0 (
    if exist "%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" (
        set "ADB_EXE=%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe"
    )
)

echo [1/2] Checking connected Android devices...
"%ADB_EXE%" devices >nul 2>nul
if %errorlevel% equ 0 (
    "%ADB_EXE%" reverse tcp:5000 tcp:5000 >nul 2>nul
    echo       [OK] ADB reverse port 5000 forwarded to phone!
) else (
    echo       [NOTE] No ADB device detected via USB/Wi-Fi (direct Wi-Fi LAN will be used).
)

echo [2/2] Starting Node.js backend server with MongoDB Atlas...
echo.
node server.js
pause
