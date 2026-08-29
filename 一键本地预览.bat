@echo off
setlocal EnableExtensions
title Blazar Blog Local Preview

set "EXIT_CODE=0"
set "PREVIEW_URL=http://localhost:4000/"
set "BUTTERFLY_VERSION=5.7.0"

pushd "%~dp0" >nul 2>nul
if errorlevel 1 (
    echo [FAILED] Cannot enter the blog project directory: %~dp0
    set "EXIT_CODE=1"
    goto :finish
)

echo ============================================================
echo Blazar Blog Local Preview
echo Project: %CD%
echo ============================================================
echo.

where node >nul 2>nul
if errorlevel 1 (
    echo [FAILED] Node.js was not found. Install Node.js and try again.
    set "EXIT_CODE=1"
    goto :finish
)

where npm >nul 2>nul
if errorlevel 1 (
    echo [FAILED] npm was not found. Check the Node.js installation and PATH.
    set "EXIT_CODE=1"
    goto :finish
)

where git >nul 2>nul
if errorlevel 1 (
    echo [FAILED] Git was not found. Install Git and try again.
    set "EXIT_CODE=1"
    goto :finish
)

if not exist "_config.yml" (
    echo [FAILED] _config.yml was not found. Run this script from the blog project.
    set "EXIT_CODE=1"
    goto :finish
)

if not exist "themes\butterfly\layout" (
    echo [CHECK] Butterfly theme files are missing. Restoring version %BUTTERFLY_VERSION%...
    if exist "themes\butterfly\.git" (
        git -C "themes/butterfly" fetch --depth 1 origin refs/tags/%BUTTERFLY_VERSION%
        if errorlevel 1 (
            echo [FAILED] Failed to download Butterfly %BUTTERFLY_VERSION%.
            set "EXIT_CODE=1"
            goto :finish
        )
        git -C "themes/butterfly" checkout --detach FETCH_HEAD
        if errorlevel 1 (
            echo [FAILED] Failed to check out Butterfly %BUTTERFLY_VERSION%.
            set "EXIT_CODE=1"
            goto :finish
        )
    ) else (
        git clone --branch %BUTTERFLY_VERSION% --depth 1 https://github.com/jerryc127/hexo-theme-butterfly.git "themes/butterfly"
        if errorlevel 1 (
            echo [FAILED] Failed to clone Butterfly %BUTTERFLY_VERSION%.
            set "EXIT_CODE=1"
            goto :finish
        )
    )
    if not exist "themes\butterfly\layout" (
        echo [FAILED] Butterfly layout files are still missing after restoration.
        set "EXIT_CODE=1"
        goto :finish
    )
)

if not exist "node_modules\.bin\hexo.cmd" goto :install_dependencies
if not exist "node_modules\hexo-server\package.json" goto :install_dependencies
if not exist "node_modules\hexo-renderer-marked\package.json" goto :install_dependencies
goto :dependencies_ready

:install_dependencies
echo [CHECK] Local Hexo dependencies are incomplete. Running npm ci...
call npm ci
if errorlevel 1 (
    echo [FAILED] npm ci failed. Check the network, npm registry and package-lock.json.
    set "EXIT_CODE=1"
    goto :finish
)

:dependencies_ready
echo [CHECK] Preview URL: %PREVIEW_URL%
echo [CHECK] The default browser will open automatically.
echo [CHECK] Close this window or press Ctrl+C to stop previewing.
echo.

call npm run server -- --open
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo [FAILED] Hexo Server exited with code %EXIT_CODE%.
) else (
    echo.
    echo [STOPPED] Hexo Server has stopped.
)

:finish
popd >nul 2>nul
echo.
echo Press any key to close this window...
pause >nul
exit /b %EXIT_CODE%
