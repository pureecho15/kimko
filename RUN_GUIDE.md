# Project Kimiko: Run Guide

This document provides a clear, step-by-step guide to setting up and running Project Kimiko on Windows using the Command Line (CMD), as well as troubleshooting common environment errors.

## How to Run Kimiko on Windows (CMD)

### Prerequisites
Before starting, ensure you have the following installed:
1.  **Flutter SDK**: [Download and Install](https://docs.flutter.dev/get-started/install/windows) (version 3.x or newer).
2.  **Git**: [Download and Install](https://git-scm.com/download/win).
3.  **Android Studio** (For Android Emulator support): [Download](https://developer.android.com/studio).
4.  **Visual Studio** (For Windows Desktop support): [Download](https://visualstudio.microsoft.com/downloads/).

### Step-by-Step Commands

1.  **Open Command Prompt (CMD)** and navigate to the project root:
    ```cmd
    cd C:\path\to\kimiko
    ```

2.  **Verify Configuration**:
    Check if `lib/config/keys.dart` exists. If not, copy `.env.example` to a new file named `.env` and use the template provided in `lib/config/keys.dart` (automatically generated if you run `start.bat`) to add your Gemini and Supabase keys.

3.  **Install Dependencies**:
    Download the required Flutter packages:
    ```cmd
    flutter pub get
    ```
    *Expected Output*: `Resolving dependencies...` followed by `Changed X dependencies!`.

4.  **Check for Available Devices**:
    List all connected devices, emulators, and browsers:
    ```cmd
    flutter devices
    ```
    *Expected Output*: A table listing device names, IDs, and platforms.

5.  **Launch the Application**:
    Launch the app on the first available device:
    ```cmd
    flutter run
    ```
    To target a specific device, use the `-d` flag with the device ID:
    - **Android**: `flutter run -d android`
    - **Chrome**: `flutter run -d chrome`
    - **Windows**: `flutter run -d windows`

    *Expected Output*: `Launching lib/main.dart on <Device Name> in debug mode...`

---

## Common CMD Error: File Excluded by Antivirus / Windows Defender

### Description
During execution, you may see errors such as:
-   `Access is denied.`
-   `Permission denied.`
-   `'flutter' is not recognized as an internal or external command.`
-   Windows Defender notifications flagging a "Threat found".

### Why it Happens
Real-time protection in Windows Defender or third-party antivirus software may incorrectly flag Flutter or Dart binaries (`flutter.exe`, `dart.exe`) as suspicious. This leads to the software quarantining or blocking the files, which interrupts the build or execution process.

### Solutions

#### 1. Add Project Folder to Windows Defender Exclusions
-   Go to **Start > Settings > Update & Security > Windows Security > Virus & threat protection**.
-   Under **Virus & threat protection settings**, select **Manage settings**.
-   Under **Exclusions**, select **Add or remove exclusions**.
-   Select **Add an exclusion > Folder**, and select your `kimiko` project directory.

#### 2. Run CMD as Administrator
-   Right-click **Command Prompt** and select **Run as administrator**. This grants the shell higher privileges to access and modify files.

#### 3. Whitelist Specific Executables
-   Add `flutter.exe` and `dart.exe` (located in your Flutter SDK `bin` folder) and `docker.exe` (if using local Supabase) to your antivirus whitelist.

#### 4. Temporarily Disable Real-time Protection
-   As a temporary measure, you can disable **Real-time protection** in your antivirus settings while running `flutter pub get`. **Caution**: Re-enable protection immediately after the process finishes.
