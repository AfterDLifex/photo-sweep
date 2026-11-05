@echo off
setlocal enabledelayedexpansion
title Tauri Android Environment Check

echo ============================================================
echo Tauri Android Development - Full Environment Check
echo ============================================================
echo.

set "PASS=0"
set "FAIL=0"
set "WARN=0"

:: ============================================================
:: 1. RUST TOOLCHAIN
:: ============================================================
echo --- Rust Toolchain ---
call :check_cmd rustc  "rustc (Rust compiler)"
call :check_cmd cargo  "cargo (Rust package manager)"
call :check_cmd rustup "rustup (Rust toolchain manager)"

:: ============================================================
:: 2. NODE.JS / NPM
:: ============================================================
echo.
echo --- Node.js / NPM ---
call :check_cmd node "node (Node.js runtime)"
call :check_cmd npm  "npm (Node package manager)"

:: ============================================================
:: 3. JAVA (JDK)
:: ============================================================
echo.
echo --- Java (JDK 17+) ---
if not defined JAVA_HOME (
    echo [FAIL] JAVA_HOME is not set.
    set /a FAIL+=1
) else (
    if exist "!JAVA_HOME!\bin\java.exe" (
        echo [PASS] JAVA_HOME = !JAVA_HOME!
        set /a PASS+=1
    ) else (
        echo [FAIL] JAVA_HOME = "!JAVA_HOME!" but java.exe not found there.
        set /a FAIL+=1
    )
)

:: ============================================================
:: 4. ANDROID SDK ENVIRONMENT
:: ============================================================
echo.
echo --- Android SDK Environment ---

if not defined ANDROID_HOME (
    echo [FAIL] ANDROID_HOME is not set.
    set /a FAIL+=1
) else (
    if exist "!ANDROID_HOME!" (
        echo [PASS] ANDROID_HOME = !ANDROID_HOME!
        set /a PASS+=1
    ) else (
        echo [FAIL] ANDROID_HOME = "!ANDROID_HOME!" but folder does not exist.
        set /a FAIL+=1
    )
)

if not defined NDK_HOME (
    echo [FAIL] NDK_HOME is not set.
    set /a FAIL+=1
) else (
    if exist "!NDK_HOME!" (
        echo [PASS] NDK_HOME = !NDK_HOME!
        set /a PASS+=1
    ) else (
        echo [FAIL] NDK_HOME = "!NDK_HOME!" but folder does not exist.
        set /a FAIL+=1
    )
)

:: ============================================================
:: 5. ANDROID SDK PACKAGES
:: ============================================================
echo.
echo --- Android SDK Packages ---

set "SDKMANAGER="
if defined ANDROID_HOME (
    if exist "!ANDROID_HOME!\cmdline-tools\latest\bin\sdkmanager.bat" (
        set "SDKMANAGER=!ANDROID_HOME!\cmdline-tools\latest\bin\sdkmanager.bat"
    )
)

if not defined SDKMANAGER (
    echo [FAIL] sdkmanager not found under ANDROID_HOME\cmdline-tools\latest\bin
    set /a FAIL+=1
) else (
    echo [PASS] sdkmanager found
    set /a PASS+=1

    echo Listing installed packages...
    call "!SDKMANAGER!" --list_installed > "%TEMP%\sdk_packages.txt" 2>nul

    if exist "%TEMP%\sdk_packages.txt" (
        call :check_pkg "platform-tools"       "platform-tools"
        call :check_pkg "build-tools"          "build-tools"
        call :check_pkg "platforms;android-"   "Android platform (platforms;android-*)"
    ) else (
        echo [WARN] Could not read sdkmanager package list.
        set /a WARN+=1
    )
)

:: ============================================================
:: 6. RUST ANDROID TARGETS
:: ============================================================
echo.
echo --- Rust Android Compilation Targets ---

where rustup >nul 2>&1
if errorlevel 1 (
    echo [SKIP] rustup not available; cannot check targets.
    set /a WARN+=1
) else (
    rustup target list --installed > "%TEMP%\rust_targets.txt" 2>nul
    call :check_target aarch64-linux-android
    call :check_target armv7-linux-androideabi
    call :check_target i686-linux-android
    call :check_target x86_64-linux-android
)

:: ============================================================
:: 7. TAURI CLI
:: ============================================================
echo.
echo --- Tauri CLI ---

where tauri >nul 2>&1
if errorlevel 1 (
    echo [WARN] Global tauri CLI not found. You can use "npx tauri" instead.
    set /a WARN+=1
) else (
    for /f "tokens=*" %%v in ('tauri --version 2^>nul') do set "TAURI_VER=%%v"
    echo [PASS] tauri CLI found - !TAURI_VER!
    set /a PASS+=1
)

:: ============================================================
:: 8. TAURI INFO (project-level)
:: ============================================================
echo.
echo --- Tauri Info ---

if exist "src-tauri" (
    echo Running "tauri info" from current directory...
    call tauri info
    set /a PASS+=1
) else (
    echo [WARN] No src-tauri folder in current directory.
    echo        Run this script from the root of a Tauri project to see "tauri info".
    set /a WARN+=1
)

:: ============================================================
:: SUMMARY
:: ============================================================
echo.
echo ============================================================
echo SUMMARY
echo ============================================================
echo PASS: !PASS!
echo FAIL: !FAIL!
echo WARN: !WARN!
echo.

if "!FAIL!"=="0" (
    echo RESULT: All critical checks passed!
    echo You are ready to run:  npx tauri android init
) else (
    echo RESULT: !FAIL! check^(s^) FAILED - see [FAIL] lines above.
)
echo ============================================================
pause
endlocal
exit /b 0

:: ============================================================
:: Subroutines - reachable ONLY via `call`
:: ============================================================
:check_cmd
where %~1 >nul 2>&1
if errorlevel 1 (
    echo [FAIL] %~2 not found
    set /a FAIL+=1
) else (
    echo [PASS] %~2
    set /a PASS+=1
)
exit /b 0

:check_pkg
findstr /i /c:"%~1" "%TEMP%\sdk_packages.txt" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] %~2 NOT installed
    set /a FAIL+=1
) else (
    echo [PASS] %~2 installed
    set /a PASS+=1
)
exit /b 0

:check_target
findstr /x /c:"%~1" "%TEMP%\rust_targets.txt" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Rust target %~1 NOT installed - fix: rustup target add %~1
    set /a FAIL+=1
) else (
    echo [PASS] Rust target %~1 installed
    set /a PASS+=1
)
exit /b 0