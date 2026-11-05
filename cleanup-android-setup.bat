@echo off
setlocal

:: ============================================================
:: PATHS - must match the paths used in your install script
:: ============================================================
set "DOWNLOAD_DIR=C:\temp"
set "SDK_ROOT=C:\Android\sdk"

echo ============================================================
echo Android / Tauri setup cleanup
echo ============================================================
echo.

echo [Mode 1] Download files and temporary extraction folders:
if exist "%DOWNLOAD_DIR%\cmdline-tools.zip"        echo   - %DOWNLOAD_DIR%\cmdline-tools.zip
if exist "%DOWNLOAD_DIR%\android-ndk.zip"          echo   - %DOWNLOAD_DIR%\android-ndk.zip
if exist "%DOWNLOAD_DIR%\cmdline-tools-extracted"  echo   - %DOWNLOAD_DIR%\cmdline-tools-extracted\
if exist "%DOWNLOAD_DIR%\ndk-extracted"            echo   - %DOWNLOAD_DIR%\ndk-extracted\
echo.

echo [Mode 2] Full reset - ALSO deletes the installed SDK/NDK:
if exist "%SDK_ROOT%\cmdline-tools\latest"         echo   - %SDK_ROOT%\cmdline-tools\latest\
if exist "%SDK_ROOT%\ndk"                          echo   - %SDK_ROOT%\ndk\
if exist "%SDK_ROOT%\platform-tools"               echo   - %SDK_ROOT%\platform-tools\
if exist "%SDK_ROOT%\build-tools"                  echo   - %SDK_ROOT%\build-tools\
if exist "%SDK_ROOT%\platforms"                    echo   - %SDK_ROOT%\platforms\
echo.

echo Which cleanup do you want?
echo   1 = Delete download files only (keeps installed SDK/NDK)
echo   2 = Full reset (delete downloads AND installed SDK/NDK)
echo   3 = Cancel
set "CHOICE="
set /p "CHOICE=Enter 1, 2, or 3: "

if "%CHOICE%"=="3" goto :cancel
if "%CHOICE%"=="1" goto :mode1
if "%CHOICE%"=="2" goto :mode2
goto :invalid

:: ------------------------------------------------------------
:mode1
echo.
echo Deleting download files...
del /f /q "%DOWNLOAD_DIR%\cmdline-tools.zip"        2>nul
del /f /q "%DOWNLOAD_DIR%\android-ndk.zip"          2>nul
rmdir /s /q "%DOWNLOAD_DIR%\cmdline-tools-extracted" 2>nul
rmdir /s /q "%DOWNLOAD_DIR%\ndk-extracted"          2>nul
echo   Done.
goto :done

:: ------------------------------------------------------------
:mode2
echo.
echo Deleting download files...
del /f /q "%DOWNLOAD_DIR%\cmdline-tools.zip"        2>nul
del /f /q "%DOWNLOAD_DIR%\android-ndk.zip"          2>nul
rmdir /s /q "%DOWNLOAD_DIR%\cmdline-tools-extracted" 2>nul
rmdir /s /q "%DOWNLOAD_DIR%\ndk-extracted"          2>nul
echo   Done.

echo.
echo Deleting installed SDK components...
rmdir /s /q "%SDK_ROOT%\cmdline-tools"  2>nul
rmdir /s /q "%SDK_ROOT%\ndk"            2>nul
rmdir /s /q "%SDK_ROOT%\platform-tools" 2>nul
rmdir /s /q "%SDK_ROOT%\build-tools"    2>nul
rmdir /s /q "%SDK_ROOT%\platforms"      2>nul
echo   Done.

echo.
echo NOTE: Mode 2 left these user environment variables pointing
echo at deleted folders. Remove them via:
echo   Control Panel - System - Advanced system settings
echo   - Environment Variables
echo or from an ADMIN command prompt:
echo.
echo   reg delete "HKCU\Environment" /F /V ANDROID_HOME     2>nul
echo   reg delete "HKCU\Environment" /F /V ANDROID_SDK_ROOT 2>nul
echo   reg delete "HKCU\Environment" /F /V NDK_HOME         2>nul
echo   reg delete "HKCU\Environment" /F /V ANDROID_NDK_HOME 2>nul
goto :done

:: ------------------------------------------------------------
:invalid
echo Invalid choice.
pause
exit /b 1

:cancel
echo Cancelled.
pause
exit /b 0

:done
echo.
echo ============================================================
echo Cleanup complete. You can re-run install-android-tauri.bat.
echo ============================================================
pause
exit /b 0