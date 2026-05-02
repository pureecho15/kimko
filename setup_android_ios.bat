@echo off
setlocal

:: ============================================================
::  Project Kimiko — Android / iOS Build Setup (Windows)
::
::  Run this once to configure your development environment
::  for mobile builds. Requires Flutter SDK to be installed.
:: ============================================================

title Kimiko — Mobile Setup

echo.
echo  ===================================================
echo    Kimiko — Android / iOS Build Setup
echo  ===================================================
echo.

:: Check Flutter
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo  ERROR: Flutter SDK not found. Install it first.
    echo  https://docs.flutter.dev/get-started/install/windows
    exit /b 1
)

:: ------------------------------------------------------------
:: Flutter Doctor
:: ------------------------------------------------------------

echo [1/3] Running Flutter Doctor...
echo.

call flutter doctor -v
echo.

:: ------------------------------------------------------------
:: Accept Android Licenses
:: ------------------------------------------------------------

echo [2/3] Accepting Android SDK licenses...
echo.
echo  (You may need to press 'y' several times to accept all licenses.)
echo.

call flutter doctor --android-licenses

echo.

:: ------------------------------------------------------------
:: iOS Notice (Windows users)
:: ------------------------------------------------------------

echo [3/3] iOS build support...
echo.
echo  iOS builds require macOS with Xcode installed.
echo  On macOS, run the following commands:
echo.
echo    sudo xcode-select --install
echo    sudo gem install cocoapods
echo    cd ios ^&^& pod install
echo.
echo  If you are on Windows, iOS builds are not available.
echo  Use Android or web/desktop targets instead.
echo.

:: ------------------------------------------------------------
:: Summary
:: ------------------------------------------------------------

echo  ===================================================
echo    Setup complete!
echo.
echo    Android: Connect a device or start an emulator,
echo             then run start.bat and choose Android.
echo.
echo    iOS:     Only available on macOS with Xcode.
echo  ===================================================
echo.

endlocal
pause
