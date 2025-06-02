#!/bin/bash

# PRS Local MacBook Test Script
# This script tests the local development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

# Default values
HTTP_PORT=8080
HTTPS_PORT=8443
DOMAIN=localhost

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

load_environment() {
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        HTTP_PORT=${HTTP_PORT:-8080}
        HTTPS_PORT=${HTTPS_PORT:-8443}
        DOMAIN=${DOMAIN:-localhost}
    fi
}

test_service() {
    local service_name="$1"
    local url="$2"
    local expected_status="${3:-200}"

    log_info "Testing $service_name at $url"

    local status_code
    status_code=$(curl -k -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)

    # Accept expected status, redirects (301, 302, 307), and for some services, specific codes
    if [ "$status_code" = "$expected_status" ] || [ "$status_code" = "301" ] || [ "$status_code" = "302" ] || [ "$status_code" = "307" ]; then
        log_success "$service_name is responding correctly"
        return 0
    else
        log_error "$service_name is not responding correctly"
        log_error "Expected: $expected_status (or redirect), Got: $status_code"
        return 1
    fi
}

test_container() {
    local container_name="$1"

    if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        log_success "Container $container_name is running"
        return 0
    else
        log_error "Container $container_name is not running"
        return 1
    fi
}

run_tests() {
    log_info "Starting PRS Local Environment Tests"
    echo "=================================="

    load_environment

    local failed_tests=0

    # Test Docker containers
    log_info "Testing Docker containers..."
    test_container "prs-local-nginx" || ((failed_tests++))
    test_container "prs-local-backend" || ((failed_tests++))
    test_container "prs-local-frontend" || ((failed_tests++))
    test_container "prs-local-postgres" || ((failed_tests++))
    test_container "prs-local-portainer" || ((failed_tests++))
    test_container "prs-local-adminer" || ((failed_tests++))

    echo ""

    # Test HTTP endpoints
    log_info "Testing HTTP endpoints..."

    # Wait a moment for services to be ready
    sleep 5

    test_service "Health Check" "https://$DOMAIN:$HTTPS_PORT/health" "200" || ((failed_tests++))
    test_service "Frontend" "https://$DOMAIN:$HTTPS_PORT/" "200" || ((failed_tests++))
    test_service "Backend API" "https://$DOMAIN:$HTTPS_PORT/api/" "404" || ((failed_tests++))
    test_service "Portainer" "https://$DOMAIN:$HTTPS_PORT/portainer/" "200" || ((failed_tests++))
    test_service "Adminer" "https://$DOMAIN:$HTTPS_PORT/adminer/" "200" || ((failed_tests++))

    # Test optional monitoring services
    if docker ps --format "table {{.Names}}" | grep -q "prs-local-grafana"; then
        test_service "Grafana" "https://$DOMAIN:$HTTPS_PORT/grafana/" "200" || ((failed_tests++))
    else
        log_info "Grafana not running (optional service)"
    fi

    if docker ps --format "table {{.Names}}" | grep -q "prs-local-prometheus"; then
        test_service "Prometheus" "https://$DOMAIN:$HTTPS_PORT/prometheus/" "200" || ((failed_tests++))
    else
        log_info "Prometheus not running (optional service)"
    fi

    echo ""

    # Test database connectivity
    log_info "Testing database connectivity..."
    if docker exec prs-local-postgres pg_isready -U prs_user -d prs_local > /dev/null 2>&1; then
        log_success "Database is ready and accepting connections"
    else
        log_error "Database is not ready"
        ((failed_tests++))
    fi

    echo ""

    # Summary
    if [ $failed_tests -eq 0 ]; then
        log_success "All tests passed! 🎉"
        echo ""
        log_info "Your PRS local environment is ready to use:"
        echo "  Main Application: https://$DOMAIN:$HTTPS_PORT"
        echo "  Backend API:      https://$DOMAIN:$HTTPS_PORT/api"
        echo "  Database Admin:   https://$DOMAIN:$HTTPS_PORT/adminer"
        echo "  Container Mgmt:   https://$DOMAIN:$HTTPS_PORT/portainer"
        echo ""
        log_info "Default login: admin / admin123"
        return 0
    else
        log_error "$failed_tests test(s) failed"
        echo ""
        log_info "Troubleshooting tips:"
        echo "  1. Check service logs: ./scripts/deploy-local.sh logs"
        echo "  2. Restart services: ./scripts/deploy-local.sh restart"
        echo "  3. Reset environment: ./scripts/deploy-local.sh reset"
        return 1
    fi
}

show_help() {
    echo "PRS Local MacBook Test Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  test    Run all tests (default)"
    echo "  help    Show this help"
    echo ""
    echo "This script tests the local PRS development environment to ensure"
    echo "all services are running correctly and accessible."
}

# Main script logic
case "${1:-test}" in
    "test")
        run_tests
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
