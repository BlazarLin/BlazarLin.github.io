@echo off
setlocal EnableExtensions
title Blazar Blog Publish

set "EXIT_CODE=0"
set "EXPECTED_SOURCE_BRANCH=dev_source"
set "SITE_URL=https://BlazarLin.github.io/"
set "BUTTERFLY_VERSION=5.7.0"

pushd "%~dp0" >nul 2>nul
if errorlevel 1 (
    echo [FAILED] Cannot enter the blog project directory: %~dp0
    set "EXIT_CODE=1"
    goto :finish
)

echo ============================================================
echo Blazar Blog One-Click Publish
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

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [FAILED] The script directory is not a Git repository.
    set "EXIT_CODE=1"
    goto :finish
)

set "SOURCE_BRANCH="
for /f "delims=" %%B in ('git branch --show-current 2^>nul') do set "SOURCE_BRANCH=%%B"
if not defined SOURCE_BRANCH (
    echo [FAILED] The repository is in detached HEAD state.
    set "EXIT_CODE=1"
    goto :finish
)

if /I not "%SOURCE_BRANCH%"=="%EXPECTED_SOURCE_BRANCH%" (
    echo [FAILED] Current branch is "%SOURCE_BRANCH%"; expected "%EXPECTED_SOURCE_BRANCH%".
    echo          This script never switches the local branch automatically.
    set "EXIT_CODE=1"
    goto :finish
)

findstr /C:"branch: dev" "_config.yml" >nul 2>nul
if errorlevel 1 (
    echo [FAILED] The Hexo deploy branch in _config.yml is not dev.
    set "EXIT_CODE=1"
    goto :finish
)

echo [CHECK] Local source branch: %SOURCE_BRANCH%
echo [CHECK] Remote website branch: dev
echo [CHECK] Node.js version:
node --version
echo [CHECK] npm version:
call npm --version
echo.

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

if not exist "node_modules\.bin\hexo.cmd" (
    echo [1/4] Local Hexo dependencies are missing. Running npm ci...
    call npm ci
    if errorlevel 1 (
        echo [FAILED] npm ci failed. Check the network, npm registry and package-lock.json.
        set "EXIT_CODE=1"
        goto :finish
    )
) else (
    echo [1/4] Local Hexo dependencies already exist. Skipping npm ci.
)

echo.
echo [2/4] Cleaning the Hexo cache and previous output...
call npm run clean
if errorlevel 1 (
    echo [FAILED] Hexo clean failed.
    set "EXIT_CODE=1"
    goto :finish
)

echo.
echo [3/4] Generating the static website...
call npm run build
if errorlevel 1 (
    echo [FAILED] Hexo generate failed. Remote deployment was not started.
    set "EXIT_CODE=1"
    goto :finish
)

if not exist "public\index.html" (
    echo [FAILED] public\index.html was not generated. Remote deployment was not started.
    set "EXIT_CODE=1"
    goto :finish
)

for %%F in ("public\index.html") do if %%~zF LEQ 0 (
    echo [FAILED] public\index.html is empty. Remote deployment was not started.
    set "EXIT_CODE=1"
    goto :finish
)

if /I "%~1"=="--build-only" (
    echo.
    echo [4/4] Build-only mode: remote deployment was skipped.
    goto :success
)

echo.
echo [4/4] Deploying the static website to the remote dev branch...
call npm run deploy
if errorlevel 1 (
    echo [FAILED] Hexo deploy failed. Check the network and GitHub credentials.
    set "EXIT_CODE=1"
    goto :finish
)

:success
set "CURRENT_BRANCH="
for /f "delims=" %%B in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%B"
if /I not "%CURRENT_BRANCH%"=="%SOURCE_BRANCH%" (
    echo [FAILED] The local branch changed unexpectedly: %SOURCE_BRANCH% -^> %CURRENT_BRANCH%
    set "EXIT_CODE=1"
    goto :finish
)

echo.
echo ============================================================
if /I "%~1"=="--build-only" (
    echo [SUCCESS] Local website generation passed. Nothing was deployed.
) else (
    echo [SUCCESS] The website was deployed to the remote dev branch.
    echo Website: %SITE_URL%
    echo GitHub Pages may need a short time to refresh.
)
echo The local repository is still on: %CURRENT_BRANCH%
echo ============================================================

:finish
if "%EXIT_CODE%"=="0" (
    echo.
) else (
    echo.
    echo Publish did not complete. Fix the failure above and try again.
)

popd >nul 2>nul
echo Press any key to close this window...
pause >nul
exit /b %EXIT_CODE%
