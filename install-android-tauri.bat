@echo off
setlocal enabledelayedexpansion
title Tauri Android Setup

set "DOWNLOAD_DIR=C:\temp"
set "SDK_ROOT=C:\Android\sdk"
set "NDK_INSTALL_DIR=%SDK_ROOT%\ndk"
set "CMDLINE_URL=https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
set "NDK_URL=https://dl.google.com/android/repository/android-ndk-r27d-windows.zip"

:: AVD defaults
set "AVD_NAME=Pixel_34"
set "AVD_DEVICE=pixel_6"
set "SYS_IMG_ANDROID=34"

set "JAVA_OK=0"
set "FAIL=0"
set "WARN=0"

echo ============================================================
echo Tauri Android Setup
echo ============================================================
echo.

:: ============================================================
:: STEP 0 - Detect JDK
:: ============================================================
echo [0/7] Checking JDK...

if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" (
        set "JAVA_OK=1"
        echo       [PASS] JAVA_HOME already set: %JAVA_HOME%
    )
)

if "!JAVA_OK!"=="0" (
    set "JAVA_EXE="
    for /f "delims=" %%J in ('where java 2^>nul') do (
        if not defined JAVA_EXE set "JAVA_EXE=%%J"
    )
    if defined JAVA_EXE (
        for %%J in ("!JAVA_EXE!") do (
            for %%H in ("%%~dpJ..") do set "JAVA_HOME=%%~fH"
        )
        if exist "!JAVA_HOME!\bin\java.exe" (
            set "JAVA_OK=1"
            echo       [PASS] Detected JDK via "where java": !JAVA_HOME!
        )
    )
)

if "!JAVA_OK!"=="0" (
    for %%P in (
        "C:\Program Files\Eclipse Adoptium\jdk-*"
        "C:\Program Files\Eclipse Adoptium\Temurin-*"
        "C:\Program Files\Microsoft\jdk-*"
        "C:\Program Files\Amazon Corretto\jdk*"
        "C:\Program Files\Java\jdk-*"
        "C:\Program Files\Android\Android Studio\jbr"
        "%LOCALAPPDATA%\Programs\Eclipse Adoptium\jdk-*"
        "%LOCALAPPDATA%\Programs\Eclipse Adoptium\Temurin-*"
    ) do (
        if "!JAVA_OK!"=="0" (
            if exist "%%~P\bin\java.exe" (
                set "JAVA_HOME=%%~P"
                set "JAVA_OK=1"
                echo       [PASS] Found JDK: !JAVA_HOME!
            )
        )
    )
)

if "!JAVA_OK!"=="1" (
    setx JAVA_HOME "!JAVA_HOME!" >nul
    set "PATH=!JAVA_HOME!\bin;!PATH!"
) else (
    echo       [FAIL] No JDK 17+ found.
    echo              Install one with: winget install EclipseAdoptium.Temurin.17.JDK
    echo              or https://adoptium.net/temurin/releases/
    set /a FAIL+=1
)

:: ============================================================
:: STEP 1 - Download
:: ============================================================
echo.
echo [1/7] Downloading Android command-line tools and NDK...
if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"
cd /d "%DOWNLOAD_DIR%"

if exist "cmdline-tools.zip" (
    echo       cmdline-tools.zip already present - skipping download.
) else (
    echo       Downloading command-line tools - about 146 MB - please wait...
    curl -L --max-time 600 -o "cmdline-tools.zip" "%CMDLINE_URL%"
    if errorlevel 1 (
        echo ERROR: Failed to download command-line tools.
        pause
        exit /b 1
    )
)

if exist "android-ndk.zip" (
    echo       android-ndk.zip already present - skipping download.
) else (
    echo       Downloading Android NDK r27d - about 745 MB - please wait...
    curl -L --max-time 600 -o "android-ndk.zip" "%NDK_URL%"
    if errorlevel 1 (
        echo ERROR: Failed to download NDK.
        pause
        exit /b 1
    )
)

:: ============================================================
:: STEP 2 - Extract command-line tools
:: ============================================================
echo.
echo [2/7] Extracting command-line tools...

if exist "%SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat" (
    echo       Already extracted - skipping.
) else (
    if not exist "%SDK_ROOT%\cmdline-tools" mkdir "%SDK_ROOT%\cmdline-tools"
    if exist "%DOWNLOAD_DIR%\cmdline-tools-extracted" rmdir /s /q "%DOWNLOAD_DIR%\cmdline-tools-extracted"
    echo       Extracting...
    powershell -Command "Expand-Archive -Path '%DOWNLOAD_DIR%\cmdline-tools.zip' -DestinationPath '%DOWNLOAD_DIR%\cmdline-tools-extracted' -Force"
    if exist "%SDK_ROOT%\cmdline-tools\latest" rmdir /s /q "%SDK_ROOT%\cmdline-tools\latest"
    move "%DOWNLOAD_DIR%\cmdline-tools-extracted\cmdline-tools" "%SDK_ROOT%\cmdline-tools\latest" >nul
    rmdir /s /q "%DOWNLOAD_DIR%\cmdline-tools-extracted"
    echo       Done.
)

:: ============================================================
:: STEP 3 - Extract NDK
:: ============================================================
echo.
echo [3/7] Extracting NDK...

set "NDK_FOLDER_NAME="
for /d %%D in ("%NDK_INSTALL_DIR%\android-ndk-*") do (
    set "NDK_FOLDER_NAME=%%~nxD"
    goto :ndk_already_there
)
:ndk_already_there
if defined NDK_FOLDER_NAME (
    echo       Already extracted as !NDK_FOLDER_NAME! - skipping.
) else (
    if not exist "%NDK_INSTALL_DIR%" mkdir "%NDK_INSTALL_DIR%"
    if exist "%DOWNLOAD_DIR%\ndk-extracted" rmdir /s /q "%DOWNLOAD_DIR%\ndk-extracted"
    echo       Extracting...
    powershell -Command "Expand-Archive -Path '%DOWNLOAD_DIR%\android-ndk.zip' -DestinationPath '%DOWNLOAD_DIR%\ndk-extracted' -Force"
    for /d %%D in ("%DOWNLOAD_DIR%\ndk-extracted\android-ndk-*") do (
        set "NDK_FOLDER_NAME=%%~nxD"
        if exist "%NDK_INSTALL_DIR%\%%~nxD" rmdir /s /q "%NDK_INSTALL_DIR%\%%~nxD"
        move "%%D" "%NDK_INSTALL_DIR%\%%~nxD" >nul
    )
    rmdir /s /q "%DOWNLOAD_DIR%\ndk-extracted"
    echo       Done.
)

:: ============================================================
:: STEP 4 - Environment variables
:: ============================================================
echo.
echo [4/7] Setting environment variables...

setx ANDROID_HOME "%SDK_ROOT%" >nul
setx ANDROID_SDK_ROOT "%SDK_ROOT%" >nul

if defined NDK_FOLDER_NAME (
    setx NDK_HOME "%NDK_INSTALL_DIR%\%NDK_FOLDER_NAME%" >nul
    setx ANDROID_NDK_HOME "%NDK_INSTALL_DIR%\%NDK_FOLDER_NAME%" >nul
    setx ANDROID_NDK_ROOT "%NDK_INSTALL_DIR%\%NDK_FOLDER_NAME%" >nul
    echo       NDK_HOME = %NDK_INSTALL_DIR%\%NDK_FOLDER_NAME%
) else (
    echo       [WARN] Could not detect NDK folder name.
    set /a WARN+=1
)
echo       ANDROID_HOME = %SDK_ROOT%

:: Add emulator, cmdline-tools, and platform-tools to current-session PATH
set "PATH=%SDK_ROOT%\emulator;%SDK_ROOT%\cmdline-tools\latest\bin;%SDK_ROOT%\platform-tools;%PATH%"

:: ============================================================
:: STEP 5 - SDK packages + Rust targets
:: ============================================================
echo.
echo [5/7] Installing SDK packages and Rust targets...

if "!JAVA_OK!"=="0" (
    echo       SKIPPED - JDK required.
    set /a FAIL+=1
    goto :emu_step
)

set "SDKMANAGER=%SDK_ROOT%\cmdline-tools\latest\bin\sdkmanager.bat"
if not exist "%SDKMANAGER%" (
    echo       [FAIL] sdkmanager not found at %SDKMANAGER%
    set /a FAIL+=1
    goto :emu_step
)

echo       Accepting SDK licenses - type y if prompted...
call "%SDKMANAGER%" --licenses

echo       Checking installed SDK packages...
call "%SDKMANAGER%" --list_installed > "%TEMP%\sdk_packages.txt" 2>nul

for %%P in ("platform-tools" "build-tools;34.0.0" "platforms;android-34") do (
    findstr /i "%%~P" "%TEMP%\sdk_packages.txt" >nul
    if errorlevel 1 (
        echo       Installing %%~P...
        call "%SDKMANAGER%" "%%~P"
        if errorlevel 1 (
            echo       [FAIL] Failed to install %%~P
            set /a FAIL+=1
        ) else (
            echo       [PASS] %%~P installed.
        )
    ) else (
        echo       [PASS] %%~P already installed.
    )
)

:rust_targets
where rustup >nul 2>&1
if errorlevel 1 (
    echo       [WARN] rustup not found. Skipping Rust target installation.
    set /a WARN+=1
    goto :emu_step
)

echo       Checking Rust Android targets...
rustup target list --installed > "%TEMP%\rust_targets.txt" 2>nul

for %%T in (aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android) do (
    findstr /x "%%T" "%TEMP%\rust_targets.txt" >nul
    if errorlevel 1 (
        echo       Adding Rust target %%T...
        rustup target add %%T
        if errorlevel 1 (
            echo       [FAIL] Failed to add %%T
            set /a FAIL+=1
        ) else (
            echo       [PASS] %%T added.
        )
    ) else (
        echo       [PASS] %%T already installed.
    )
)

:: ============================================================
:: STEP 6 - Install emulator package and system image
:: ============================================================
:emu_step
echo.
echo [6/7] Installing Android Emulator and system image...

if "!JAVA_OK!"=="0" (
    echo       SKIPPED - JDK required.
    goto :emu_create
)

:: Detect architecture - x86_64 for normal Windows, arm64-v8a for Windows on ARM
set "SYS_IMG_ABI=x86_64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "SYS_IMG_ABI=arm64-v8a"
set "SYS_IMG=system-images;android-%SYS_IMG_ANDROID%;google_apis;%SYS_IMG_ABI%"
echo       System image: %SYS_IMG%

call "%SDKMANAGER%" --list_installed > "%TEMP%\sdk_packages2.txt" 2>nul

:: Emulator package
findstr /i "emulator" "%TEMP%\sdk_packages2.txt" >nul
if errorlevel 1 (
    echo       Installing emulator package - about 300 MB - please wait...
    call "%SDKMANAGER%" "emulator"
    if errorlevel 1 (
        echo       [FAIL] Failed to install emulator package.
        set /a FAIL+=1
    ) else (
        echo       [PASS] emulator installed.
    )
) else (
    echo       [PASS] emulator already installed.
)

:: System image
findstr /i "%SYS_IMG%" "%TEMP%\sdk_packages2.txt" >nul
if errorlevel 1 (
    echo       Installing %SYS_IMG% - about 1.2 GB - please wait...
    call "%SDKMANAGER%" "%SYS_IMG%"
    if errorlevel 1 (
        echo       [FAIL] Failed to install system image.
        set /a FAIL+=1
    ) else (
        echo       [PASS] system image installed.
    )
) else (
    echo       [PASS] system image already installed.
)

:: ============================================================
:: STEP 7 - Create AVD and (optionally) launch
:: ============================================================
:emu_create
echo.
echo [7/7] Creating AVD "%AVD_NAME%"...

set "AVDMANAGER=%SDK_ROOT%\cmdline-tools\latest\bin\avdmanager.bat"
set "EMULATOR=%SDK_ROOT%\emulator\emulator.exe"

if not exist "%EMULATOR%" (
    echo       [FAIL] emulator.exe not found at %EMULATOR%
    set /a FAIL+=1
    goto :summary
)

if exist "%USERPROFILE%\.android\avd\%AVD_NAME%.avd" (
    echo       [PASS] AVD "%AVD_NAME%" already exists - skipping creation.
) else (
    if not exist "%AVDMANAGER%" (
        echo       [FAIL] avdmanager not found at %AVDMANAGER%
        set /a FAIL+=1
        goto :summary
    )
    echo       Creating AVD - answering "no" to custom hardware profile...
    echo no | call "%AVDMANAGER%" create avd -n %AVD_NAME% -k "%SYS_IMG%" -d %AVD_DEVICE%
    if errorlevel 1 (
        echo       [FAIL] Failed to create AVD.
        set /a FAIL+=1
        goto :summary
    ) else (
        echo       [PASS] AVD "%AVD_NAME%" created.
    )
)

:: Hardware acceleration check
echo       Checking hardware acceleration...
"%EMULATOR%" -accel-check >nul 2>&1
if errorlevel 1 (
    echo       [WARN] No hardware acceleration detected - emulator will be slow.
    echo              Enable Windows Hypervisor Platform or Intel VT-x / AMD-V in BIOS.
    set /a WARN+=1
) else (
    echo       [PASS] Hardware acceleration available.
)

:: Confirm launch
echo.
set "LAUNCH="
set /p "LAUNCH=Launch the emulator now? [Y/n]: "
if /i "!LAUNCH!"=="n" goto :summary

:: Skip launch if an emulator is already running
set "EMU_RUNNING=0"
call "%SDK_ROOT%\platform-tools\adb.exe" devices 2>nul | findstr /i "emulator-" >nul
if not errorlevel 1 set "EMU_RUNNING=1"

if "!EMU_RUNNING!"=="1" (
    echo       An emulator is already running - not launching a second one.
    goto :summary
)

echo       Launching emulator in a new window...
start "Android Emulator" "%EMULATOR%" -avd %AVD_NAME%
echo       Emulator starting - wait for the Android home screen before running tauri.

:: ============================================================
:: SUMMARY
:: ============================================================
:summary
echo.
echo ============================================================
echo Setup Complete
echo ============================================================
echo SDK root:   %SDK_ROOT%
if defined NDK_FOLDER_NAME (
    echo NDK home:   %NDK_INSTALL_DIR%\%NDK_FOLDER_NAME%
)
if "!JAVA_OK!"=="1" (
    echo JAVA_HOME:  !JAVA_HOME!
)
echo AVD name:   %AVD_NAME%
echo.

if "!JAVA_OK!"=="0" (
    echo [ACTION REQUIRED] Install JDK 17+ then re-run this script.
) else (
    echo [OK] Environment ready.
    echo.
    echo NEXT STEPS:
    echo   1. Close and reopen your terminal so env vars take effect.
    echo   2. Launch the emulator - if not launched above:
    echo        "%EMULATOR%" -avd %AVD_NAME%
    echo   3. Wait for the Android home screen to appear.
    echo   4. In your Tauri project folder run:
    echo        npx tauri android dev
)

if "%FAIL%" NEQ "0" (
    echo.
    echo [NOTE] %FAIL% issue^(s^) above need attention.
)

echo.
echo Reminder: Rust on Windows also needs Microsoft C++ Build Tools:
echo   winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --norestart"
echo.
echo ============================================================
pause
endlocal