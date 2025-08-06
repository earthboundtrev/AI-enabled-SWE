#!/bin/bash

# ==============================================================================
# Deployment script for AI-Driven Software Engineering Project
# 
# This script provides easy commands for building and running the application
# in different environments.
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to build the production image
build_production() {
    print_status "Building production Docker image..."
    
    # Create necessary directories if they don't exist
    mkdir -p data logs
    
    # Build the image
    docker build -t ai-driven-inventory:latest .
    
    if [ $? -eq 0 ]; then
        print_success "Production image built successfully!"
    else
        print_error "Failed to build production image"
        exit 1
    fi
}

# Function to build the development image
build_development() {
    print_status "Building development Docker image..."
    
    # Create necessary directories if they don't exist
    mkdir -p data logs
    
    # Build the image
    docker build -f Dockerfile.dev -t ai-driven-inventory:dev .
    
    if [ $? -eq 0 ]; then
        print_success "Development image built successfully!"
    else
        print_error "Failed to build development image"
        exit 1
    fi
}

# Function to run the production container
run_production() {
    print_status "Starting production container..."
    
    # Create necessary directories if they don't exist
    mkdir -p data logs
    
    # Stop existing container if running
    docker stop ai-driven-inventory-prod 2>/dev/null || true
    docker rm ai-driven-inventory-prod 2>/dev/null || true
    
    # Run the container
    docker run -d \
        --name ai-driven-inventory-prod \
        -p 8000:8000 \
        -v $(pwd)/data:/app/data \
        -v $(pwd)/logs:/app/logs \
        --restart unless-stopped \
        ai-driven-inventory:latest
    
    if [ $? -eq 0 ]; then
        print_success "Production container started!"
        print_status "Application is available at: http://localhost:8000"
        print_status "API documentation: http://localhost:8000/docs"
    else
        print_error "Failed to start production container"
        exit 1
    fi
}

# Function to run the development container
run_development() {
    print_status "Starting development container..."
    
    # Create necessary directories if they don't exist
    mkdir -p data logs
    
    # Stop existing container if running
    docker stop ai-driven-inventory-dev 2>/dev/null || true
    docker rm ai-driven-inventory-dev 2>/dev/null || true
    
    # Run the container
    docker run -d \
        --name ai-driven-inventory-dev \
        -p 8001:8000 \
        -v $(pwd)/app:/app/app \
        -v $(pwd)/utils.py:/app/utils.py \
        -v $(pwd)/requirements.txt:/app/requirements.txt \
        -v $(pwd)/artifacts/React:/app/frontend \
        -v $(pwd)/data:/app/data \
        -v $(pwd)/logs:/app/logs \
        --restart unless-stopped \
        ai-driven-inventory:dev
    
    if [ $? -eq 0 ]; then
        print_success "Development container started!"
        print_status "Application is available at: http://localhost:8001"
        print_status "API documentation: http://localhost:8001/docs"
    else
        print_error "Failed to start development container"
        exit 1
    fi
}

# Function to stop containers
stop_containers() {
    print_status "Stopping containers..."
    docker stop ai-driven-inventory-prod ai-driven-inventory-dev 2>/dev/null || true
    docker rm ai-driven-inventory-prod ai-driven-inventory-dev 2>/dev/null || true
    print_success "Containers stopped and removed!"
}

# Function to show logs
show_logs() {
    local container_name=${1:-ai-driven-inventory-prod}
    print_status "Showing logs for $container_name..."
    docker logs -f $container_name
}

# Function to clean up
cleanup() {
    print_status "Cleaning up Docker resources..."
    docker system prune -f
    print_success "Cleanup completed!"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build-prod     Build production Docker image"
    echo "  build-dev      Build development Docker image"
    echo "  run-prod       Run production container"
    echo "  run-dev        Run development container"
    echo "  stop           Stop all containers"
    echo "  logs [name]    Show container logs (default: ai-driven-inventory-prod)"
    echo "  cleanup        Clean up Docker resources"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build-prod && $0 run-prod"
    echo "  $0 build-dev && $0 run-dev"
    echo "  $0 logs ai-driven-inventory-dev"
}

# Main script logic
main() {
    check_docker
    
    case "${1:-help}" in
        "build-prod")
            build_production
            ;;
        "build-dev")
            build_development
            ;;
        "run-prod")
            run_production
            ;;
        "run-dev")
            run_development
            ;;
        "stop")
            stop_containers
            ;;
        "logs")
            show_logs "$2"
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@" 