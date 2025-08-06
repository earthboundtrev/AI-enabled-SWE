@echo off
REM ==============================================================================
REM Deployment script for AI-Driven Software Engineering Project (Windows)
REM 
REM This script provides easy commands for building and running the application
REM in different environments on Windows systems.
REM ==============================================================================

setlocal enabledelayedexpansion

REM Function to print colored output
:print_status
echo [INFO] %~1
goto :eof

:print_success
echo [SUCCESS] %~1
goto :eof

:print_warning
echo [WARNING] %~1
goto :eof

:print_error
echo [ERROR] %~1
goto :eof

REM Function to check if Docker is running
:check_docker
docker info >nul 2>&1
if errorlevel 1 (
    call :print_error "Docker is not running. Please start Docker and try again."
    exit /b 1
)
goto :eof

REM Function to build the production image
:build_production
call :print_status "Building production Docker image..."

REM Create necessary directories if they don't exist
if not exist "data" mkdir data
if not exist "logs" mkdir logs

REM Build the image
docker build -t ai-driven-inventory:latest .
if errorlevel 1 (
    call :print_error "Failed to build production image"
    exit /b 1
)
call :print_success "Production image built successfully!"
goto :eof

REM Function to build the development image
:build_development
call :print_status "Building development Docker image..."

REM Create necessary directories if they don't exist
if not exist "data" mkdir data
if not exist "logs" mkdir logs

REM Build the image
docker build -f Dockerfile.dev -t ai-driven-inventory:dev .
if errorlevel 1 (
    call :print_error "Failed to build development image"
    exit /b 1
)
call :print_success "Development image built successfully!"
goto :eof

REM Function to run the production container
:run_production
call :print_status "Starting production container..."

REM Create necessary directories if they don't exist
if not exist "data" mkdir data
if not exist "logs" mkdir logs

REM Stop existing container if running
docker stop ai-driven-inventory-prod 2>nul
docker rm ai-driven-inventory-prod 2>nul

REM Run the container
docker run -d --name ai-driven-inventory-prod -p 8000:8000 -v %cd%/data:/app/data -v %cd%/logs:/app/logs --restart unless-stopped ai-driven-inventory:latest
if errorlevel 1 (
    call :print_error "Failed to start production container"
    exit /b 1
)
call :print_success "Production container started!"
call :print_status "Application is available at: http://localhost:8000"
call :print_status "API documentation: http://localhost:8000/docs"
goto :eof

REM Function to run the development container
:run_development
call :print_status "Starting development container..."

REM Create necessary directories if they don't exist
if not exist "data" mkdir data
if not exist "logs" mkdir logs

REM Stop existing container if running
docker stop ai-driven-inventory-dev 2>nul
docker rm ai-driven-inventory-dev 2>nul

REM Run the container
docker run -d --name ai-driven-inventory-dev -p 8001:8000 -v %cd%/app:/app/app -v %cd%/utils.py:/app/utils.py -v %cd%/requirements.txt:/app/requirements.txt -v %cd%/artifacts/React:/app/frontend -v %cd%/data:/app/data -v %cd%/logs:/app/logs --restart unless-stopped ai-driven-inventory:dev
if errorlevel 1 (
    call :print_error "Failed to start development container"
    exit /b 1
)
call :print_success "Development container started!"
call :print_status "Application is available at: http://localhost:8001"
call :print_status "API documentation: http://localhost:8001/docs"
goto :eof

REM Function to stop containers
:stop_containers
call :print_status "Stopping containers..."
docker stop ai-driven-inventory-prod 2>nul
docker rm ai-driven-inventory-prod 2>nul
docker stop ai-driven-inventory-dev 2>nul
docker rm ai-driven-inventory-dev 2>nul
call :print_success "Containers stopped and removed!"
goto :eof

REM Function to show logs
:show_logs
set container_name=%~1
if "%container_name%"=="" set container_name=ai-driven-inventory-prod
call :print_status "Showing logs for %container_name%..."
docker logs -f %container_name%
goto :eof

REM Function to clean up
:cleanup
call :print_status "Cleaning up Docker resources..."
docker system prune -f
call :print_success "Cleanup completed!"
goto :eof

REM Function to show help
:show_help
echo Usage: %~nx0 [COMMAND]
echo.
echo Commands:
echo   build-prod     Build production Docker image
echo   build-dev      Build development Docker image
echo   run-prod       Run production container
echo   run-dev        Run development container
echo   stop           Stop all containers
echo   logs [name]    Show container logs (default: ai-driven-inventory-prod)
echo   cleanup        Clean up Docker resources
echo   help           Show this help message
echo.
echo Examples:
echo   %~nx0 build-prod ^&^& %~nx0 run-prod
echo   %~nx0 build-dev ^&^& %~nx0 run-dev
echo   %~nx0 logs ai-driven-inventory-dev
goto :eof

REM Main script logic
:main
call :check_docker
if errorlevel 1 exit /b 1

if "%1"=="" goto :show_help
if "%1"=="build-prod" goto :build_production
if "%1"=="build-dev" goto :build_development
if "%1"=="run-prod" goto :run_production
if "%1"=="run-dev" goto :run_development
if "%1"=="stop" goto :stop_containers
if "%1"=="logs" goto :show_logs
if "%1"=="cleanup" goto :cleanup
if "%1"=="help" goto :show_help

goto :show_help

REM Run main function
call :main %* 