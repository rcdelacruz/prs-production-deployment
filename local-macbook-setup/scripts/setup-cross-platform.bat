@echo off
REM Cross-Platform PRS Setup Script for Windows
REM This batch file provides Windows-specific setup for PRS

setlocal enabledelayedexpansion

echo ==========================================
echo   PRS Windows Setup Script
echo ==========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed or not in PATH
    echo Please install Docker Desktop for Windows from https://docker.com
    pause
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker daemon is not running
    echo Please start Docker Desktop application
    pause
    exit /b 1
)

echo [SUCCESS] Docker is installed and running

REM Check if Docker Compose is available
docker compose version >nul 2>&1
if errorlevel 1 (
    docker-compose --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Docker Compose is not available
        echo Please install Docker Compose or update Docker Desktop
        pause
        exit /b 1
    )
)

echo [SUCCESS] Docker Compose is available

REM Configure Docker socket path for Windows
if exist .env (
    echo [INFO] Configuring Docker socket for Windows...
    
    REM Create a temporary file to update .env
    findstr /v "DOCKER_SOCK_PATH=" .env > .env.tmp
    echo DOCKER_SOCK_PATH=//var/run/docker.sock >> .env.tmp
    move .env.tmp .env >nul
    
    echo [SUCCESS] Updated Docker socket path for Windows
) else (
    echo [ERROR] .env file not found
    pause
    exit /b 1
)

REM Check system requirements
echo [INFO] Checking system requirements...

REM Get total memory (requires wmic)
for /f "tokens=2 delims==" %%i in ('wmic computersystem get TotalPhysicalMemory /value ^| find "="') do set TOTAL_MEM=%%i
set /a TOTAL_MEM_GB=!TOTAL_MEM!/1024/1024/1024

if !TOTAL_MEM_GB! LSS 4 (
    echo [WARNING] System has less than 4GB RAM. Performance may be affected.
) else (
    echo [SUCCESS] System has !TOTAL_MEM_GB!GB RAM
)

REM Check available disk space
for /f "tokens=3" %%i in ('dir /-c ^| find "bytes free"') do set AVAILABLE_BYTES=%%i
set AVAILABLE_BYTES=!AVAILABLE_BYTES:,=!
set /a AVAILABLE_GB=!AVAILABLE_BYTES!/1024/1024/1024

if !AVAILABLE_GB! LSS 5 (
    echo [WARNING] Less than 5GB disk space available. Consider freeing up space.
) else (
    echo [SUCCESS] Available disk space: !AVAILABLE_GB!GB
)

echo.
echo [SUCCESS] Windows setup completed successfully!
echo.
echo Next steps:
echo   1. Review and customize .env file if needed
echo   2. Run: scripts\deploy-local.bat
echo   3. Access PRS at: https://localhost:8444
echo.
echo Platform: Windows
echo Docker Socket: //var/run/docker.sock
echo.

pause
