@echo off
REM =============================================================================
REM  cmdlets.bat - Windows Package Manager for cmdlets
REM  
REM  Copyright (c) 2026, mtdcy.chen@gmail.com
REM  Licensed under BSD 2-Clause License
REM
REM  Usage: cmdlets.bat <command> [options]
REM    fetch <cmdlet>              - Download and extract cmdlet package
REM    list [cmdlet]               - List installed packages or files
REM    search <pattern>            - Search for packages
REM    remove <cmdlet>             - Remove installed package
REM
REM  Examples:
REM    cmdlets.bat fetch curl
REM    cmdlets.bat fetch curl@8.18.0
REM    cmdlets.bat list
REM    cmdlets.bat list curl
REM    cmdlets.bat search curl
REM    cmdlets.bat remove curl
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
set "PATTERN=%~1"
set "MANIFEST=%PREBUILTS%\.manifest"

if not exist "!MANIFEST!" (
    call :die "Manifest not found: !MANIFEST!"
)

findstr /I "!PATTERN!" "!MANIFEST!"
goto :eof

REM =============================================================================
REM Main Functions
REM =============================================================================

:fetch
REM Fetch cmdlet: name
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
    call :search_manifest "!PKGNAME!" > "%TEMP_DIR%\search.txt"
    if exist "%TEMP_DIR%\search.txt" (
        for /f "tokens=2" %%A in ("%TEMP_DIR%\search.txt") do set "PKGFILE=%%A"
        if defined PKGFILE (
            echo !info!#3 Fetch !TARGET! < !PKGFILE!!reset!
            call :fetch_v3
            goto :fetch_done
        )
    )
)

REM Fallback: direct download
echo !info!#2 Fetch !TARGET!< !PKGFILE!!reset!
call :fetch_direct
goto :fetch_done

:fetch_v3
REM Fetch v3 format
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

:list
REM List installed packages or files
set "PKGNAME=%~1"

if not exist "%PREBUILTS%\.cmdlets" (
    echo No packages installed.
    goto :eof
)

if defined PKGNAME (
    REM List files for specific package
    echo === Files for !PKGNAME! ===
    findstr /B "!PKGNAME! " "%PREBUILTS%\.cmdlets" >nul
    if errorlevel 1 (
        echo Package not found: !PKGNAME!
    ) else (
        REM List bin directory for this package
        if exist "%PREBUILTS%\bin\!PKGNAME!*" (
            dir /b "%PREBUILTS%\bin\!PKGNAME!*" 2>nul
        )
    )
) else (
    REM List all installed packages
    echo === Installed Packages ===
    type "%PREBUILTS%\.cmdlets"
    
    echo.
    echo === Binaries ===
    if exist "%PREBUILTS%\bin" (
        dir /b "%PREBUILTS%\bin\*.exe" 2>nul
    )
)
goto :eof

:search
REM Search for packages
set "PATTERN=%~1"

if not defined PATTERN (
    call :die "Usage: cmdlets.bat search ^<pattern^]"
)

echo === Searching for "!PATTERN!" ===
echo.

REM Search in manifest if exists
if exist "%PREBUILTS%\.manifest" (
    echo From manifest:
    findstr /I "!PATTERN!" "%PREBUILTS%\.manifest" | findstr /V "^#" || echo (no matches)
)

echo.
echo Repository: !REPO!/!ARCH!/
echo Note: For full search, visit the repository URL
goto :eof

:remove
REM Remove installed package
set "PKGNAME=%~1"

if not defined PKGNAME (
    call :die "Usage: cmdlets.bat remove ^<cmdlet^]"
)

if not exist "%PREBUILTS%\.cmdlets" (
    call :die "No packages installed"
)

echo === Removing !PKGNAME! ===

REM Find and remove files
set "FOUND=0"
for /f "tokens=1,*" %%A in ("%PREBUILTS%\.cmdlets") do (
    if "%%A"=="!PKGNAME!" (
        set "FOUND=1"
        echo Removing: %%A
    )
)

if !FOUND! equ 0 (
    echo Package not found: !PKGNAME!
    goto :eof
)

REM Remove from .cmdlets list
findstr /V "^!PKGNAME! " "%PREBUILTS%\.cmdlets" > "%TEMP_DIR%\cmdlets.tmp"
move /y "%TEMP_DIR%\cmdlets.tmp" "%PREBUILTS%\.cmdlets" >nul

REM Remove bin files (best effort)
if exist "%PREBUILTS%\bin\!PKGNAME!*" (
    del /q "%PREBUILTS%\bin\!PKGNAME!*" 2>nul
    echo Removed binaries
)

echo !info!✅ Removed: !PKGNAME!!reset!
goto :eof

REM =============================================================================
REM Command Dispatcher
REM =============================================================================

:help
echo cmdlets.bat %VERSION%
echo.
echo Usage: cmdlets.bat ^<command^> ^[options^]
echo.
echo Commands:
echo   fetch ^<cmdlet^]           - Download and extract cmdlet package
echo   list ^[cmdlet^]            - List installed packages or files
echo   search ^<pattern^]         - Search for packages
echo   remove ^<cmdlet^]          - Remove installed package
echo   help                       - Show this help message
echo.
echo Examples:
echo   cmdlets.bat fetch curl
echo   cmdlets.bat fetch curl@8.18.0
echo   cmdlets.bat list
echo   cmdlets.bat list curl
echo   cmdlets.bat search curl
echo   cmdlets.bat remove curl
echo.
echo Environment Variables:
echo   REPO        - Package repository ^(default: https://pub.mtdcy.top/cmdlets/latest^)
echo   ARCH        - Target architecture ^(default: x86_64-windows-gnu^)
echo   PREBUILTS   - Installation directory ^(default: current directory^)
goto :eof

REM Main entry point
if "%~1"=="" goto :help

set "CMD=%~1"
shift

if /i "%CMD%"=="fetch" (
    if "%~1"=="" (
        call :die "Usage: cmdlets.bat fetch ^<cmdlet^]"
    )
    call :fetch %*
    goto :end
)

if /i "%CMD%"=="list" (
    call :list %*
    goto :end
)

if /i "%CMD%"=="search" (
    call :search %*
    goto :end
)

if /i "%CMD%"=="remove" (
    call :remove %*
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
