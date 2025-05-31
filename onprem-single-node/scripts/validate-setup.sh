#!/bin/bash
# PRS Single Node Setup Validation Script
# This script validates the prerequisites and configuration for single node deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

log() {
    echo -e "${BLUE}[VALIDATE] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[⚠] $1${NC}"
}

log_error() {
    echo -e "${RED}[✗] $1${NC}"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    local issues=0
    
    # Check Docker
    if command -v docker &> /dev/null; then
        docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker is installed (version: $docker_version)"
    else
        log_error "Docker is not installed"
        ((issues++))
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        compose_version=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker Compose is installed (version: $compose_version)"
    else
        log_error "Docker Compose is not installed"
        ((issues++))
    fi
    
    # Check if user is in docker group
    if groups | grep -q docker; then
        log_success "User is in docker group"
    else
        log_error "User is not in docker group. Run: sudo usermod -aG docker \$USER"
        ((issues++))
    fi
    
    # Check environment file
    if [[ -f "$ENV_FILE" ]]; then
        log_success "Environment file exists: $ENV_FILE"
    else
        log_error "Environment file missing: $ENV_FILE"
        log "Create it by copying: cp .env.example .env"
        ((issues++))
    fi
    
    # Check system resources
    total_memory=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [[ $total_memory -ge 8 ]]; then
        log_success "Sufficient memory: ${total_memory}GB"
    else
        log_warning "Low memory: ${total_memory}GB (recommended: 8GB+)"
    fi
    
    cpu_cores=$(nproc)
    if [[ $cpu_cores -ge 4 ]]; then
        log_success "Sufficient CPU cores: $cpu_cores"
    else
        log_warning "Low CPU cores: $cpu_cores (recommended: 4+)"
    fi
    
    return $issues
}

check_network_connectivity() {
    log "Checking network connectivity..."
    
    local issues=0
    
    # Load environment variables
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
    fi
    
    # Check NAS connectivity
    if [[ -n "$NAS_SERVER" ]]; then
        if ping -c 1 -W 3 "$NAS_SERVER" &> /dev/null; then
            log_success "NAS server is reachable: $NAS_SERVER"
        else
            log_error "Cannot reach NAS server: $NAS_SERVER"
            ((issues++))
        fi
        
        # Check NFS port if using NFS
        if [[ "$NAS_MOUNT_TYPE" == "nfs" ]]; then
            if nc -z "$NAS_SERVER" 2049 2>/dev/null; then
                log_success "NFS port (2049) is accessible on $NAS_SERVER"
            else
                log_error "NFS port (2049) is not accessible on $NAS_SERVER"
                ((issues++))
            fi
        fi
        
        # Check SMB port if using CIFS
        if [[ "$NAS_MOUNT_TYPE" == "cifs" ]]; then
            if nc -z "$NAS_SERVER" 445 2>/dev/null; then
                log_success "SMB port (445) is accessible on $NAS_SERVER"
            else
                log_error "SMB port (445) is not accessible on $NAS_SERVER"
                ((issues++))
            fi
        fi
    else
        log_warning "NAS_SERVER not configured in environment file"
    fi
    
    # Check internet connectivity for Docker image pulls
    if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        log_success "Internet connectivity available"
    else
        log_warning "No internet connectivity (may affect Docker image pulls)"
    fi
    
    return $issues
}

check_storage() {
    log "Checking storage configuration..."
    
    local issues=0
    
    # Check if NAS is mounted
    if mountpoint -q /mnt/nas 2>/dev/null; then
        log_success "NAS is mounted at /mnt/nas"
        
        # Check write permissions
        if touch /mnt/nas/test_write 2>/dev/null; then
            rm -f /mnt/nas/test_write
            log_success "NAS has write permissions"
        else
            log_error "No write permissions on NAS mount"
            ((issues++))
        fi
        
        # Check available space
        available_gb=$(df -BG /mnt/nas 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
        if [[ $available_gb -gt 10 ]]; then
            log_success "Sufficient NAS storage: ${available_gb}GB available"
        else
            log_warning "Low NAS storage: ${available_gb}GB available"
        fi
    else
        log_error "NAS is not mounted at /mnt/nas"
        log "Run deployment script to mount NAS or mount manually"
        ((issues++))
    fi
    
    # Check local disk space
    local_available_gb=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
    if [[ $local_available_gb -gt 20 ]]; then
        log_success "Sufficient local storage: ${local_available_gb}GB available"
    else
        log_warning "Low local storage: ${local_available_gb}GB available"
    fi
    
    return $issues
}

check_ssl_certificates() {
    log "Checking SSL certificates..."
    
    local issues=0
    
    if [[ -f "$PROJECT_DIR/ssl/cert.pem" && -f "$PROJECT_DIR/ssl/key.pem" ]]; then
        log_success "SSL certificates exist"
        
        # Check certificate validity
        if openssl x509 -in "$PROJECT_DIR/ssl/cert.pem" -noout -checkend 86400 2>/dev/null; then
            log_success "SSL certificate is valid"
        else
            log_warning "SSL certificate expires within 24 hours or is invalid"
        fi
    else
        log_warning "SSL certificates not found (will be generated during deployment)"
    fi
    
    return $issues
}

check_configuration() {
    log "Checking configuration files..."
    
    local issues=0
    
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        
        # Check required variables
        required_vars=("DOMAIN" "POSTGRES_PASSWORD" "JWT_SECRET" "ADMIN_PASSWORD")
        for var in "${required_vars[@]}"; do
            if [[ -n "${!var}" ]]; then
                log_success "$var is configured"
            else
                log_error "$var is not configured in $ENV_FILE"
                ((issues++))
            fi
        done
        
        # Check for default/example values
        if [[ "$POSTGRES_PASSWORD" == "SecurePassword123!" ]]; then
            log_warning "Using default password for PostgreSQL (change for production)"
        fi
        
        if [[ "$JWT_SECRET" == "your-jwt-secret-key-minimum-32-characters-long" ]]; then
            log_error "JWT_SECRET contains example value"
            ((issues++))
        fi
    fi
    
    return $issues
}

check_docker_environment() {
    log "Checking Docker environment..."
    
    local issues=0
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        log_success "Docker daemon is running"
    else
        log_error "Docker daemon is not running"
        ((issues++))
    fi
    
    # Check Docker disk usage
    docker_root=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo "/var/lib/docker")
    docker_space=$(df -BG "$docker_root" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")
    if [[ $docker_space -gt 10 ]]; then
        log_success "Sufficient Docker storage: ${docker_space}GB available"
    else
        log_warning "Low Docker storage: ${docker_space}GB available"
    fi
    
    return $issues
}

check_ports() {
    log "Checking port availability..."
    
    local issues=0
    required_ports=(80 443)
    
    for port in "${required_ports[@]}"; do
        if ! ss -tlnp | grep ":$port " &> /dev/null; then
            log_success "Port $port is available"
        else
            log_error "Port $port is already in use"
            ((issues++))
        fi
    done
    
    return $issues
}

run_all_checks() {
    log "=== PRS Single Node Setup Validation ==="
    echo ""
    
    local total_issues=0
    
    check_prerequisites
    total_issues=$((total_issues + $?))
    echo ""
    
    check_network_connectivity
    total_issues=$((total_issues + $?))
    echo ""
    
    check_storage
    total_issues=$((total_issues + $?))
    echo ""
    
    check_ssl_certificates
    total_issues=$((total_issues + $?))
    echo ""
    
    check_configuration
    total_issues=$((total_issues + $?))
    echo ""
    
    check_docker_environment
    total_issues=$((total_issues + $?))
    echo ""
    
    check_ports
    total_issues=$((total_issues + $?))
    echo ""
    
    if [[ $total_issues -eq 0 ]]; then
        log_success "=== All validation checks passed! ==="
        log_success "Your system is ready for PRS single node deployment"
        echo ""
        log "Next steps:"
        log "1. Review your .env configuration"
        log "2. Run: ./scripts/deploy.sh"
    else
        log_error "=== Found $total_issues issues ==="
        log_error "Please resolve the issues above before proceeding with deployment"
        exit 1
    fi
}

show_help() {
    echo -e "${BLUE}PRS Single Node Setup Validation${NC}"
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  --all           Run all validation checks (default)"
    echo "  --prereq        Check prerequisites only"
    echo "  --network       Check network connectivity only"
    echo "  --storage       Check storage configuration only"
    echo "  --ssl           Check SSL certificates only"
    echo "  --config        Check configuration files only"
    echo "  --docker        Check Docker environment only"
    echo "  --ports         Check port availability only"
    echo "  --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all checks"
    echo "  $0 --prereq     # Check prerequisites only"
    echo "  $0 --network    # Check network connectivity only"
}

# Parse command line arguments
case "${1:---all}" in
    --all)
        run_all_checks
        ;;
    --prereq)
        check_prerequisites
        ;;
    --network)
        check_network_connectivity
        ;;
    --storage)
        check_storage
        ;;
    --ssl)
        check_ssl_certificates
        ;;
    --config)
        check_configuration
        ;;
    --docker)
        check_docker_environment
        ;;
    --ports)
        check_ports
        ;;
    --help|*)
        show_help
        ;;
esac
