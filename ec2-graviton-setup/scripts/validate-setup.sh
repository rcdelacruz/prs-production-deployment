#!/bin/bash

# PRS EC2 Setup Validation Script
# This script validates the configuration before deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

validate_environment_file() {
    log_info "Validating environment file..."
    
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env file not found. Run: cp .env.example .env"
        ((VALIDATION_ERRORS++))
        return
    fi
    
    source "$ENV_FILE"
    
    # Required variables
    local required_vars=(
        "DOMAIN"
        "POSTGRES_PASSWORD"
        "JWT_SECRET"
        "ENCRYPTION_KEY"
        "ROOT_USER_PASSWORD"
        "GRAFANA_ADMIN_PASSWORD"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required variable $var is not set in .env"
            ((VALIDATION_ERRORS++))
        fi
    done
    
    # Password strength validation
    if [ ${#POSTGRES_PASSWORD} -lt 12 ]; then
        log_warning "POSTGRES_PASSWORD should be at least 12 characters"
        ((VALIDATION_WARNINGS++))
    fi
    
    if [ ${#JWT_SECRET} -lt 32 ]; then
        log_error "JWT_SECRET must be at least 32 characters"
        ((VALIDATION_ERRORS++))
    fi
    
    # Domain validation
    if [[ "$DOMAIN" == "your-domain.com" || "$DOMAIN" == "localhost" ]]; then
        log_warning "DOMAIN is set to default value. Update with your actual domain."
        ((VALIDATION_WARNINGS++))
    fi
    
    # Cloudflare Tunnel validation
    if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
        if [[ ! "${CLOUDFLARE_TUNNEL_TOKEN}" =~ ^[A-Za-z0-9_-]+$ ]]; then
            log_error "CLOUDFLARE_TUNNEL_TOKEN format appears invalid"
            ((VALIDATION_ERRORS++))
        else
            log_success "Cloudflare Tunnel token format looks valid"
        fi
    else
        log_warning "CLOUDFLARE_TUNNEL_TOKEN not set. Services will only be accessible via SSH tunnel."
        ((VALIDATION_WARNINGS++))
    fi
    
    log_success "Environment file validation completed"
}

validate_docker_compose() {
    log_info "Validating Docker Compose configuration..."
    
    cd "$PROJECT_DIR"
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        log_error "docker-compose.yml not found"
        ((VALIDATION_ERRORS++))
        return
    fi
    
    # Validate docker-compose syntax
    if ! docker-compose config > /dev/null 2>&1; then
        log_error "Docker Compose configuration is invalid"
        docker-compose config 2>&1 | head -10
        ((VALIDATION_ERRORS++))
    else
        log_success "Docker Compose configuration is valid"
    fi
    
    # Check for required directories
    local required_dirs=(
        "nginx"
        "config/grafana"
        "config/prometheus"
        "ssl"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log_error "Required directory $dir not found"
            ((VALIDATION_ERRORS++))
        fi
    done
}

validate_system_requirements() {
    log_info "Validating system requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        ((VALIDATION_ERRORS++))
    else
        log_success "Docker is installed"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        ((VALIDATION_ERRORS++))
    else
        log_success "Docker Compose is installed"
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        ((VALIDATION_ERRORS++))
    else
        log_success "Docker is running"
    fi
    
    # Check memory
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [ "$TOTAL_MEM" -lt 3500 ]; then
        log_warning "Available memory ($TOTAL_MEM MB) is less than recommended 4GB"
        ((VALIDATION_WARNINGS++))
    else
        log_success "Memory check passed: ${TOTAL_MEM}MB available"
    fi
    
    # Check disk space
    DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "${DISK_SPACE%.*}" -lt 10 ]; then
        log_warning "Available disk space (${DISK_SPACE}G) is less than recommended 10GB"
        ((VALIDATION_WARNINGS++))
    else
        log_success "Disk space check passed: ${DISK_SPACE}G available"
    fi
}

validate_network_configuration() {
    log_info "Validating network configuration..."
    
    # Check if ports are available (only if public access is enabled)
    source "$ENV_FILE" 2>/dev/null || true
    
    if [ "${ENABLE_PUBLIC_ACCESS:-false}" = "true" ]; then
        local ports=(80 443)
        for port in "${ports[@]}"; do
            if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                log_warning "Port $port is already in use"
                ((VALIDATION_WARNINGS++))
            fi
        done
    else
        log_success "Public access disabled - no port conflicts expected"
    fi
}

validate_ssl_setup() {
    log_info "Validating SSL setup..."
    
    SSL_DIR="$PROJECT_DIR/ssl"
    
    if [ ! -d "$SSL_DIR" ]; then
        log_info "SSL directory will be created during deployment"
    else
        if [ -f "$SSL_DIR/cert.pem" ] && [ -f "$SSL_DIR/key.pem" ]; then
            # Check certificate validity
            if openssl x509 -in "$SSL_DIR/cert.pem" -noout -checkend 86400 > /dev/null 2>&1; then
                log_success "SSL certificates are valid"
            else
                log_warning "SSL certificates are expired or invalid"
                ((VALIDATION_WARNINGS++))
            fi
        else
            log_info "SSL certificates will be generated during deployment"
        fi
    fi
}

show_validation_summary() {
    echo ""
    echo "=================================="
    echo "    VALIDATION SUMMARY"
    echo "=================================="
    
    if [ $VALIDATION_ERRORS -eq 0 ] && [ $VALIDATION_WARNINGS -eq 0 ]; then
        log_success "All validations passed! Ready for deployment."
        echo ""
        echo "Next steps:"
        echo "1. Run: ./scripts/deploy-ec2.sh deploy"
        echo "2. Monitor deployment: ./scripts/deploy-ec2.sh status"
        return 0
    elif [ $VALIDATION_ERRORS -eq 0 ]; then
        log_warning "Validation completed with $VALIDATION_WARNINGS warning(s)"
        echo ""
        echo "You can proceed with deployment, but consider addressing the warnings."
        echo "Run: ./scripts/deploy-ec2.sh deploy"
        return 0
    else
        log_error "Validation failed with $VALIDATION_ERRORS error(s) and $VALIDATION_WARNINGS warning(s)"
        echo ""
        echo "Please fix the errors before proceeding with deployment."
        return 1
    fi
}

# Main validation
main() {
    log_info "Starting PRS EC2 setup validation..."
    echo ""
    
    validate_system_requirements
    echo ""
    
    validate_environment_file
    echo ""
    
    validate_docker_compose
    echo ""
    
    validate_network_configuration
    echo ""
    
    validate_ssl_setup
    echo ""
    
    show_validation_summary
}

# Run validation
main "$@"
