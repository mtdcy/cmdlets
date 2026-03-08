@echo off
REM =============================================================================
REM  cmdlet.bat - Windows Package Fetcher for cmdlets
REM  
REM  Copyright (c) 2026, mtdcy.chen@gmail.com
REM  Licensed under BSD 2-Clause License
REM
REM  Usage: cmdlet.bat fetch <cmdlet>
REM    fetch <cmdlet>    - Download and extract cmdlet package
REM
REM  Examples:
REM    cmdlet.bat fetch bash
REM    cmdlet.bat fetch bash@3.2
REM    cmdlet.bat fetch zlib/minigzip@1.3.1
REM =============================================================================

setlocal EnableDelayedExpansion

REM Version
set VERSION=1.0.0

REM Configuration
set CMDLETS_DIR=%~dp0
set PREBUILTS=%CMDLETS_DIR%prebuilts
set TEMP_DIR=%TEMP%\cmdlets_%RANDOM%

REM Repository
if not defined REPO set REPO=https://pub.mtdcy.top/cmdlets/latest
if not defined ARCH set ARCH=x86_64-windows-gnu

REM Colors (Windows 10+ supports ANSI)
set "GREEN=[32m"
set "YELLOW=[33m"
set "RED=[31m"
set "CYAN=[36m"
set "RESET=[39m"

REM =============================================================================
REM Helper Functions
REM =============================================================================

:info
echo %GREEN%!RESET!
goto :eof

:warn
echo %YELLOW%!RESET!
goto :eof

:die
echo %RED%!RESET!
exit /b 1

:curl
REM Download file with curl
set "URL=%~1"
set "DEST=%~2"

if not defined DEST set "DEST=%TEMP_DIR%\%~n1"

mkdir "%~dp2" 2>nul

echo !info!== curl < !URL!!reset!
curl -fsL -o "!DEST!" "!URL!"
if errorlevel 1 (
    call :die "Failed to download: !URL!"
)
echo >> "!DEST!"
goto :eof

:unzip
REM Extract tar.gz file
set "ARCHIVE=%~1"
set "DEST=%PREBUILTS%"

echo !info!== Extract !ARCHIVE! to !DEST!!reset!
tar -xf "!ARCHIVE!" -C "!DEST!"
if errorlevel 1 (
    call :die "Failed to extract: !ARCHIVE!"
)
goto :eof

:search_manifest
REM Search for package in manifest (v3 format)
REM Input: pkgname[@version]
REM Output: pkgfile (e.g., bash@3.2.tar.gz)
set "PKGNAME=%~1"
set "MANIFEST=%PREBUILTS%\.manifest"

if not exist "!MANIFEST!" (
    call :die "Manifest not found: !MANIFEST!"
)

REM Simple grep-like search
findstr /R "^!PKGNAME!@ " "!MANIFEST!" > "%TEMP_DIR%\search_result.txt"
if errorlevel 1 (
    findstr /R "^!PKGNAME!$" "!MANIFEST!" > "%TEMP_DIR%\search_result.txt"
)

for /f "tokens=2" %%A in ("%TEMP_DIR%\search_result.txt") do set "PKGFILE=%%A"
goto :eof

REM =============================================================================
REM Main Functions
REM =============================================================================

:fetch
REM Fetch cmdlet: name
REM Input: name[@version]
set "TARGET=%~1"

REM Create temp directory
mkdir "%TEMP_DIR%" 2>nul

REM Parse package name and version
set "PKGNAME=%TARGET%"
set "PKGVER="
set "PKGPATH="

REM Check for version (@version)
echo "!TARGET!" | findstr "@" >nul
if not errorlevel 1 (
    for /f "tokens=1,2 delims=@" %%A in ("!TARGET!") do (
        set "PKGNAME=%%A"
        set "PKGVER=%%B"
    )
)

REM Check for path (pkgname/file)
echo "!PKGNAME!" | findstr "/" >nul
if not errorlevel 1 (
    for /f "tokens=1,2 delims=/" %%A in ("!PKGNAME!") do (
        set "PKGPATH=%%A"
        set "PKGNAME=%%B"
    )
)

REM Build package file name
if defined PKGVER (
    set "PKGFILE=!PKGNAME!@!PKGVER!.tar.gz"
) else (
    set "PKGFILE=!PKGNAME!.tar.gz"
)

if defined PKGPATH (
    set "PKGFILE=!PKGPATH!/!PKGFILE!"
)

REM Try v3 (manifest-based) first
if exist "%PREBUILTS%\.manifest" (
    call :search_manifest "!PKGNAME!"
    if defined PKGFILE (
        echo !info!#3 Fetch !TARGET! < !PKGFILE!!reset!
        call :fetch_v3
        goto :fetch_done
    )
)

REM Fallback: direct download
echo !info!#2 Fetch !TARGET!< !PKGFILE!!reset!
call :fetch_direct
goto :fetch_done

:fetch_v3
REM Fetch v3 format: name pkgfile sha pkgbuild
set "PKGURL=!REPO!/!ARCH!/!PKGFILE!"
call :curl "!PKGURL!" "%TEMP_DIR%\!PKGFILE!"
call :unzip "%TEMP_DIR%\!PKGFILE!"
goto :eof

:fetch_direct
REM Direct download from repo
set "PKGURL=!REPO!/!ARCH!/!PKGFILE!"
call :curl "!PKGURL!" "%TEMP_DIR%\!PKGFILE!"
call :unzip "%TEMP_DIR%\!PKGFILE!"
goto :eof

:fetch_done
REM Update installed list
echo !TARGET! >> "%PREBUILTS%\.cmdlets"

REM Cleanup
rmdir /s /q "%TEMP_DIR%" 2>nul

echo !info!✅ Fetch completed: !TARGET!!reset!
goto :eof

REM =============================================================================
REM Command Dispatcher
REM =============================================================================

:help
echo cmdlet.bat %VERSION%
echo.
echo Usage: cmdlet.bat ^<command^> ^[options^]
echo.
echo Commands:
echo   fetch ^<cmdlet^]    - Download and extract cmdlet package
echo   help                - Show this help message
echo.
echo Examples:
echo   cmdlet.bat fetch bash
echo   cmdlet.bat fetch bash@3.2
echo   cmdlet.bat fetch zlib/minigzip@1.3.1
echo.
echo Environment Variables:
echo   REPO        - Package repository (default: https://pub.mtdcy.top/cmdlets/latest)
echo   ARCH        - Target architecture (default: x86_64-windows-gnu)
echo   PREBUILTS   - Installation directory (default: current directory)
goto :eof

REM Main entry point
if "%~1"=="" goto :help

set "CMD=%~1"
shift

if /i "%CMD%"=="fetch" (
    if "%~1"=="" (
        call :die "Usage: cmdlet.bat fetch ^<cmdlet^]"
    )
    call :fetch %*
    goto :end
)

if /i "%CMD%"=="help" (
    call :help
    goto :end
)

call :die "Unknown command: %CMD%"

:end
endlocal
exit /b 0
