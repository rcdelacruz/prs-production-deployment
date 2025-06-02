#!/bin/bash

# Cross-Platform PRS Setup Script
# Works on Linux, macOS, and Windows (with WSL/Git Bash)

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

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    print_status "Detected OS: $OS"
}

# Configure Docker socket path based on OS
configure_docker_socket() {
    local env_file=".env"
    
    case $OS in
        "linux"|"macos")
            DOCKER_SOCK="/var/run/docker.sock"
            ;;
        "windows")
            # Windows with Docker Desktop
            if command -v docker &> /dev/null; then
                # Try to detect if running in WSL
                if grep -qi microsoft /proc/version 2>/dev/null; then
                    DOCKER_SOCK="/var/run/docker.sock"
                    print_status "WSL detected, using Unix socket"
                else
                    DOCKER_SOCK="//var/run/docker.sock"
                    print_status "Windows detected, using Windows socket"
                fi
            else
                print_error "Docker not found. Please install Docker Desktop for Windows."
                exit 1
            fi
            ;;
        *)
            print_warning "Unknown OS, using default Docker socket path"
            DOCKER_SOCK="/var/run/docker.sock"
            ;;
    esac
    
    # Update .env file with correct Docker socket path
    if [[ -f "$env_file" ]]; then
        if grep -q "DOCKER_SOCK_PATH=" "$env_file"; then
            sed -i.bak "s|DOCKER_SOCK_PATH=.*|DOCKER_SOCK_PATH=$DOCKER_SOCK|" "$env_file"
        else
            echo "DOCKER_SOCK_PATH=$DOCKER_SOCK" >> "$env_file"
        fi
        print_success "Updated Docker socket path: $DOCKER_SOCK"
    else
        print_error ".env file not found"
        exit 1
    fi
}

# Check Docker installation and version
check_docker() {
    print_status "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        print_status "Please install Docker:"
        case $OS in
            "linux")
                echo "  - Ubuntu/Debian: sudo apt-get install docker.io docker-compose"
                echo "  - CentOS/RHEL: sudo yum install docker docker-compose"
                ;;
            "macos")
                echo "  - Install Docker Desktop for Mac from https://docker.com"
                ;;
            "windows")
                echo "  - Install Docker Desktop for Windows from https://docker.com"
                ;;
        esac
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        print_status "Please install Docker Compose or use Docker with compose plugin"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        print_status "Please start Docker service:"
        case $OS in
            "linux")
                echo "  sudo systemctl start docker"
                ;;
            "macos"|"windows")
                echo "  Start Docker Desktop application"
                ;;
        esac
        exit 1
    fi
    
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    print_success "Docker $DOCKER_VERSION is installed and running"
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check available memory
    case $OS in
        "linux")
            TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
            ;;
        "macos")
            TOTAL_MEM=$(sysctl -n hw.memsize | awk '{printf "%.0f", $1/1024/1024/1024}')
            ;;
        "windows")
            # This works in Git Bash/WSL
            TOTAL_MEM=$(wmic computersystem get TotalPhysicalMemory /value 2>/dev/null | grep = | cut -d= -f2 | awk '{printf "%.0f", $1/1024/1024/1024}' 2>/dev/null || echo "4")
            ;;
    esac
    
    if [[ $TOTAL_MEM -lt 4 ]]; then
        print_warning "System has less than 4GB RAM. Performance may be affected."
    else
        print_success "System has ${TOTAL_MEM}GB RAM"
    fi
    
    # Check available disk space
    AVAILABLE_SPACE=$(df . | tail -1 | awk '{print $4}')
    AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
    
    if [[ $AVAILABLE_GB -lt 5 ]]; then
        print_warning "Less than 5GB disk space available. Consider freeing up space."
    else
        print_success "Available disk space: ${AVAILABLE_GB}GB"
    fi
}

# Configure platform-specific settings
configure_platform_settings() {
    print_status "Configuring platform-specific settings..."
    
    local env_file=".env"
    
    case $OS in
        "windows")
            # Windows-specific configurations
            print_status "Applying Windows-specific configurations..."
            
            # Use Windows line endings for batch files if any
            if command -v dos2unix &> /dev/null; then
                find scripts/ -name "*.bat" -exec dos2unix {} \; 2>/dev/null || true
            fi
            ;;
        "macos")
            # macOS-specific configurations
            print_status "Applying macOS-specific configurations..."
            
            # Check if running on Apple Silicon
            if [[ $(uname -m) == "arm64" ]]; then
                print_status "Apple Silicon detected - Docker images will use ARM64 architecture"
            fi
            ;;
        "linux")
            # Linux-specific configurations
            print_status "Applying Linux-specific configurations..."
            
            # Check if SELinux is enabled
            if command -v getenforce &> /dev/null && [[ $(getenforce 2>/dev/null) == "Enforcing" ]]; then
                print_warning "SELinux is enforcing. You may need to configure SELinux policies for Docker volumes."
            fi
            ;;
    esac
}

# Main setup function
main() {
    echo "=========================================="
    echo "  PRS Cross-Platform Setup Script"
    echo "=========================================="
    echo
    
    detect_os
    check_docker
    check_requirements
    configure_docker_socket
    configure_platform_settings
    
    echo
    print_success "Cross-platform setup completed successfully!"
    echo
    print_status "Next steps:"
    echo "  1. Review and customize .env file if needed"
    echo "  2. Run: ./scripts/deploy-local.sh"
    echo "  3. Access PRS at: https://localhost:8444"
    echo
    print_status "Platform: $OS"
    print_status "Docker Socket: $DOCKER_SOCK"
    echo
}

# Run main function
main "$@"
