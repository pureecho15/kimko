@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  Project Kimiko — Automated Startup Script (Windows)
::
::  This is a pure Flutter + Supabase application.
::  There is no local Python backend or Docker dependency.
::  Supabase is used as a remote hosted backend (cloud).
:: ============================================================

title Project Kimiko — Startup

echo.
echo  ===================================================
echo    Project Kimiko — Automated Startup
echo  ===================================================
echo.

:: ------------------------------------------------------------
:: 1. Check Prerequisites
:: ------------------------------------------------------------

echo [1/5] Checking prerequisites...
echo.

:: Check Flutter SDK
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo  ERROR: Flutter SDK not found in PATH.
    echo  Install Flutter: https://docs.flutter.dev/get-started/install/windows
    echo  After installing, restart your terminal and try again.
    exit /b 1
)

:: Print Flutter version
for /f "tokens=2" %%v in ('flutter --version 2^>nul ^| findstr /i "Flutter"') do (
    echo  Flutter SDK found: %%v
)

:: Check Dart SDK (bundled with Flutter)
where dart >nul 2>&1
if %errorlevel% neq 0 (
    echo  WARNING: Dart not found separately — using Flutter's bundled Dart.
)

:: Check Git
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo  WARNING: Git is not installed. Version control features unavailable.
) else (
    echo  Git found.
)

echo.
echo  Prerequisites OK.
echo.

:: ------------------------------------------------------------
:: 2. Check Configuration (lib/config/keys.dart)
:: ------------------------------------------------------------

echo [2/5] Checking configuration...
echo.

if not exist "lib\config\keys.dart" (
    echo  WARNING: lib\config\keys.dart not found!
    echo.
    echo  This file contains your Supabase and Gemini API credentials.
    echo  Creating a template for you...
    echo.

    if not exist "lib\config" mkdir "lib\config"

    (
        echo /// Centralized configuration for API keys and service endpoints.
        echo ///
        echo /// IMPORTANT: Replace the placeholder values below with your real credentials.
        echo /// This file is listed in .gitignore and will NOT be committed.
        echo.
        echo const String geminiApiKey = 'PASTE_YOUR_GEMINI_API_KEY_HERE';
        echo.
        echo const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
        echo.
        echo const String supabaseAnonKey = 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE';
        echo.
        echo /// Bypass user ID used during development ^(no Supabase Auth^).
        echo const String kBypassUserId = '00000000-0000-0000-0000-000000000000';
    ) > "lib\config\keys.dart"

    echo  Template created at lib\config\keys.dart
    echo  *** Open that file and paste your real API keys before running the app. ***
    echo.
    echo  See .env.example for the list of required credentials.
    echo.
    pause
    exit /b 1
) else (
    echo  Configuration file found: lib\config\keys.dart
)

echo.

:: ------------------------------------------------------------
:: 3. Install Flutter Dependencies
:: ------------------------------------------------------------

echo [3/5] Installing Flutter dependencies...
echo.

call flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo  ERROR: flutter pub get failed. Check pubspec.yaml for issues.
    exit /b 1
)

echo.
echo  Dependencies installed.
echo.

:: ------------------------------------------------------------
:: 4. Detect Available Devices
:: ------------------------------------------------------------

echo [4/5] Detecting available devices...
echo.

call flutter devices
echo.

:: Count connected devices
for /f %%c in ('flutter devices 2^>nul ^| findstr /r /c:"^[a-zA-Z]" ^| find /c /v ""') do set DEVICE_COUNT=%%c

if "%DEVICE_COUNT%"=="0" (
    echo  No devices found.
    echo.
    echo  To run on Android:
    echo    - Connect a physical device via USB with USB debugging enabled, OR
    echo    - Start an Android emulator from Android Studio's Device Manager.
    echo.
    echo  To run on Chrome ^(web^):
    echo    - Chrome should be detected automatically.
    echo.
    echo  To run on Windows ^(desktop^):
    echo    - Windows desktop should be detected automatically.
    echo.
    echo  After connecting a device, run this script again.
    exit /b 1
)

:: ------------------------------------------------------------
:: 5. Launch the Application
:: ------------------------------------------------------------

echo [5/5] Launching Project Kimiko...
echo.

:: Ask user to choose a target
echo  Available launch options:
echo    [1] Auto-detect (first available device)
echo    [2] Android device / emulator
echo    [3] Chrome (web)
echo    [4] Windows (desktop)
echo    [5] Custom device ID
echo.

set /p CHOICE="  Select an option (1-5, default=1): "

if "%CHOICE%"=="" set CHOICE=1

if "%CHOICE%"=="1" (
    echo.
    echo  Launching on first available device...
    call flutter run
) else if "%CHOICE%"=="2" (
    echo.
    echo  Launching on Android...
    call flutter run -d android
) else if "%CHOICE%"=="3" (
    echo.
    echo  Launching on Chrome...
    call flutter run -d chrome
) else if "%CHOICE%"=="4" (
    echo.
    echo  Launching on Windows desktop...
    call flutter run -d windows
) else if "%CHOICE%"=="5" (
    set /p DEVICE_ID="  Enter device ID: "
    echo.
    echo  Launching on device: !DEVICE_ID!
    call flutter run -d !DEVICE_ID!
) else (
    echo  Invalid choice. Launching on first available device...
    call flutter run
)

if %errorlevel% neq 0 (
    echo.
    echo  ERROR: flutter run failed. See output above for details.
    exit /b 1
)

echo.
echo  Kimiko session ended.
endlocal
