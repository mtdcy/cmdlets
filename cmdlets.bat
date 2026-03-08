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

REM Version
set VERSION=1.0.0

REM Configuration
set CMDLETS_DIR=%~dp0
set PREBUILTS=%CMDLETS_DIR%prebuilts
set TEMP_DIR=%TEMP%\cmdlets_%RANDOM%

REM Repository
if not defined REPO set REPO=https://pub.mtdcy.top/cmdlets/latest

REM Target Architecture (fixed for Windows)
set ARCH=x86_64-w64-mingw32

REM Add prebuilts bin to PATH
set PATH=%PREBUILTS%\bin;%PATH%

REM Jump to main code (skip function definitions)
goto :main

REM =============================================================================
REM Helper Functions
REM =============================================================================

:info
echo %~1
goto :eof

:warn
echo %~1
goto :eof

:die
echo %~1
exit /b 1

:curl
set URL=%~1
set DEST=%~2
if not defined DEST set DEST=%TEMP_DIR%\%~n1
mkdir "%~dp2" 2>nul
echo == curl < %URL%
curl -fsL -o "%DEST%" "%URL%"
if errorlevel 1 call :die "Failed to download: %URL%"
goto :eof

:unzip
set ARCHIVE=%~1
set DEST=%PREBUILTS%
echo == Extract %ARCHIVE% to %DEST%
tar -xf "%ARCHIVE%" -C "%DEST%"
if errorlevel 1 call :die "Failed to extract: %ARCHIVE%"
goto :eof

:search_manifest
set PATTERN=%~1
set MANIFEST=%PREBUILTS%\.manifest
if not exist "%MANIFEST%" call :die "Manifest not found: %MANIFEST%"
findstr /I "%PATTERN%" "%MANIFEST%"
goto :eof

:fetch
set TARGET=%~1
mkdir "%TEMP_DIR%" 2>nul
set PKGNAME=%TARGET%
set PKGVER=
set PKGPATH=
echo %TARGET% | findstr "@" >nul
if not errorlevel 1 (
    for /f "tokens=1,2 delims=@" %%A in ("%TARGET%") do (
        set PKGNAME=%%A
        set PKGVER=%%B
    )
)
echo %PKGNAME% | findstr "/" >nul
if not errorlevel 1 (
    for /f "tokens=1,2 delims=/" %%A in ("%PKGNAME%") do (
        set PKGPATH=%%A
        set PKGNAME=%%B
    )
)
if defined PKGVER (set PKGFILE=%PKGNAME%@%PKGVER%.tar.gz) else (set PKGFILE=%PKGNAME%.tar.gz)
if defined PKGPATH (set PKGFILE=%PKGPATH%/%PKGFILE%)

REM Try v3 (manifest-based) first
if not exist "%PREBUILTS%\.manifest" goto :fetch_v2
call :search_manifest "%PKGNAME%" > "%TEMP_DIR%\search.txt"
if not exist "%TEMP_DIR%\search.txt" goto :fetch_v2
for /f "tokens=2" %%A in ("%TEMP_DIR%\search.txt") do set PKGFILE=%%A
if not defined PKGFILE goto :fetch_v2
echo #3 Fetch %TARGET% < %PKGFILE%
call :fetch_v3
goto :fetch_done

:fetch_v2
echo #2 Fetch %TARGET% < %PKGFILE%
call :fetch_direct

:fetch_done
echo %TARGET% >> "%PREBUILTS%\.cmdlets"
rmdir /s /q "%TEMP_DIR%" 2>nul
echo ✅ Fetch completed: %TARGET%
goto :eof

:fetch_v3
set PKGURL=%REPO%/%ARCH%/%PKGFILE%
call :curl "%PKGURL%" "%TEMP_DIR%\%PKGFILE%"
call :unzip "%TEMP_DIR%\%PKGFILE%"
goto :eof

:fetch_direct
set PKGURL=%REPO%/%ARCH%/%PKGFILE%
call :curl "%PKGURL%" "%TEMP_DIR%\%PKGFILE%"
call :unzip "%TEMP_DIR%\%PKGFILE%"
goto :eof

:list
set PKGNAME=%~1
if not exist "%PREBUILTS%\.cmdlets" (echo No packages installed. & goto :eof)
if defined PKGNAME (
    echo === Files for %PKGNAME% ===
    findstr /B "%PKGNAME% " "%PREBUILTS%\.cmdlets" >nul
    if errorlevel 1 (echo Package not found: %PKGNAME%) else (
        if exist "%PREBUILTS%\bin\%PKGNAME%*" (dir /b "%PREBUILTS%\bin\%PKGNAME%*" 2>nul)
    )
) else (
    echo === Installed Packages ===
    type "%PREBUILTS%\.cmdlets"
    echo.
    echo === Binaries ===
    if exist "%PREBUILTS%\bin" (dir /b "%PREBUILTS%\bin\*.exe" 2>nul)
)
goto :eof

:search
set PATTERN=%~1
if not defined PATTERN call :die "Usage: cmdlets.bat search ^<pattern^>"
echo === Searching for "%PATTERN%" ===
echo.
if exist "%PREBUILTS%\.manifest" (
    echo From manifest:
    findstr /I "%PATTERN%" "%PREBUILTS%\.manifest" | findstr /V "^#" || echo (no matches)
)
echo.
echo Repository: %REPO%/%ARCH%/
echo Note: For full search, visit the repository URL
goto :eof

:remove
set PKGNAME=%~1
if not defined PKGNAME call :die "Usage: cmdlets.bat remove ^<cmdlet^>"
if not exist "%PREBUILTS%\.cmdlets" call :die "No packages installed"
echo === Removing %PKGNAME% ===
set FOUND=0
for /f "tokens=1,*" %%A in ("%PREBUILTS%\.cmdlets") do (
    if "%%A"=="%PKGNAME%" (set FOUND=1 & echo Removing: %%A)
)
if %FOUND% equ 0 (echo Package not found: %PKGNAME% & goto :eof)
findstr /V "^%PKGNAME% " "%PREBUILTS%\.cmdlets" > "%TEMP_DIR%\cmdlets.tmp"
move /y "%TEMP_DIR%\cmdlets.tmp" "%PREBUILTS%\.cmdlets" >nul
if exist "%PREBUILTS%\bin\%PKGNAME%*" (del /q "%PREBUILTS%\bin\%PKGNAME%*" 2>nul & echo Removed binaries)
echo ✅ Removed: %PKGNAME%
goto :eof

:main
if "%~1"=="" goto :help
set CMD=%~1
shift
if /i "%CMD%"=="fetch" (if "%~1"=="" (call :die "Usage: cmdlets.bat fetch ^<cmdlet^]") & call :fetch %* & goto :end)
if /i "%CMD%"=="list" (call :list %* & goto :end)
if /i "%CMD%"=="search" (call :search %* & goto :end)
if /i "%CMD%"=="remove" (call :remove %* & goto :end)
if /i "%CMD%"=="help" (call :help & goto :end)
call :die "Unknown command: %CMD%"
:end
exit /b 0

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
echo   PREBUILTS   - Installation directory ^(default: current directory^)
echo.
echo Notes:
echo   ARCH is fixed to x86_64-w64-mingw32 for Windows
goto :eof
