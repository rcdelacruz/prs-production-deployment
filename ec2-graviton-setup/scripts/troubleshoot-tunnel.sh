#!/bin/bash

# Cloudflare Tunnel Troubleshooting Script
# This script helps diagnose and fix common Cloudflare Tunnel issues

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

check_tunnel_status() {
    log_info "Checking Cloudflare Tunnel status..."

    cd "$PROJECT_DIR"

    # Check if cloudflared container is running
    if docker ps | grep -q prs-ec2-cloudflared; then
        log_success "Cloudflare Tunnel container is running"

        # Show recent logs
        echo ""
        log_info "Recent tunnel logs:"
        docker logs prs-ec2-cloudflared --tail 10

    else
        log_error "Cloudflare Tunnel container is not running"

        # Check if it exists but stopped
        if docker ps -a | grep -q prs-ec2-cloudflared; then
            log_warning "Container exists but is stopped. Checking logs..."
            docker logs prs-ec2-cloudflared --tail 20
        else
            log_error "Container does not exist. Run deployment first."
        fi
        return 1
    fi
}

check_service_connectivity() {
    log_info "Checking service connectivity from tunnel container..."

    cd "$PROJECT_DIR"

    if ! docker ps | grep -q prs-ec2-cloudflared; then
        log_error "Cloudflare Tunnel container is not running"
        return 1
    fi

    # Test connectivity to each service
    local services=("nginx:80" "grafana:3000" "adminer:8080" "portainer:9000")

    for service in "${services[@]}"; do
        log_info "Testing connectivity to $service..."

        if docker exec prs-ec2-cloudflared wget -q --spider --timeout=5 "http://$service" 2>/dev/null; then
            log_success "$service is reachable"
        else
            log_error "$service is NOT reachable"

            # Check if the service container is running
            service_name=$(echo "$service" | cut -d: -f1)
            if docker ps | grep -q "prs-ec2-$service_name"; then
                log_warning "$service_name container is running but not responding"
            else
                log_error "$service_name container is not running"
            fi
        fi
    done
}

check_network_configuration() {
    log_info "Checking Docker network configuration..."

    cd "$PROJECT_DIR"

    # Check if network exists
    if docker network ls | grep -q prs_ec2_network; then
        log_success "Docker network prs_ec2_network exists"

        # Show network details
        echo ""
        log_info "Network configuration:"
        docker network inspect prs_ec2_network --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'

    else
        log_error "Docker network prs_ec2_network does not exist"
        return 1
    fi
}

check_cloudflare_configuration() {
    log_info "Checking Cloudflare Tunnel configuration..."

    # Load environment
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
    fi

    if [ -z "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
        log_error "CLOUDFLARE_TUNNEL_TOKEN not set in .env file"
        return 1
    fi

    # Validate token format
    if [[ ! "${CLOUDFLARE_TUNNEL_TOKEN}" =~ ^[A-Za-z0-9_-]+$ ]]; then
        log_error "CLOUDFLARE_TUNNEL_TOKEN format appears invalid"
        return 1
    fi

    log_success "Cloudflare Tunnel token is configured"

    echo ""
    log_info "Expected Cloudflare Dashboard Configuration:"
    echo "  Main App:  nginx:80"
    echo "  Grafana:   grafana:3000"
    echo "  Adminer:   adminer:8080"
    echo "  Portainer: portainer:9000"
}

fix_common_issues() {
    log_info "Attempting to fix common issues..."

    cd "$PROJECT_DIR"

    # Stop tunnel first to avoid conflicts
    log_info "Stopping Cloudflare Tunnel..."
    docker-compose --profile cloudflare down 2>/dev/null || true

    # Check if services are running and healthy
    local services=("nginx" "grafana" "adminer" "portainer")

    for service in "${services[@]}"; do
        if ! docker ps | grep -q "prs-ec2-$service"; then
            log_warning "$service container is not running. Starting..."
            docker-compose up -d "$service" 2>/dev/null || log_error "Failed to start $service"
        fi
    done

    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 10

    # Restart the entire stack with proper order
    log_info "Restarting services in proper order..."
    docker-compose up -d postgres
    sleep 5
    docker-compose up -d backend frontend
    sleep 5
    docker-compose up -d nginx adminer portainer
    sleep 5

    # Start monitoring if enabled
    if [ "${PROMETHEUS_ENABLED:-true}" = "true" ] || [ "${GRAFANA_ENABLED:-true}" = "true" ]; then
        docker-compose --profile monitoring up -d
        sleep 5
    fi

    # Finally start tunnel
    log_info "Starting Cloudflare Tunnel..."
    docker-compose --profile cloudflare up -d cloudflared

    # Wait and check tunnel status
    sleep 10
    if docker ps | grep -q prs-ec2-cloudflared; then
        log_success "Cloudflare Tunnel restarted successfully"
    else
        log_error "Failed to restart Cloudflare Tunnel"
        docker logs prs-ec2-cloudflared --tail 10 2>/dev/null || true
    fi

    log_success "Common fixes applied"
}

show_tunnel_logs() {
    log_info "Showing Cloudflare Tunnel logs..."

    cd "$PROJECT_DIR"

    if docker ps | grep -q prs-ec2-cloudflared; then
        echo ""
        echo "=== Cloudflare Tunnel Logs ==="
        docker logs prs-ec2-cloudflared --tail 50
    else
        log_error "Cloudflare Tunnel container is not running"
    fi
}

test_external_access() {
    log_info "Testing external access..."

    # Load environment
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
    fi

    if [ -z "${DOMAIN:-}" ]; then
        log_warning "DOMAIN not set in .env file. Cannot test external access."
        return 1
    fi

    local urls=(
        "https://$DOMAIN"
        "https://grafana.$DOMAIN"
        "https://adminer.$DOMAIN"
        "https://portainer.$DOMAIN"
    )

    for url in "${urls[@]}"; do
        log_info "Testing $url..."

        if curl -s --max-time 10 "$url" > /dev/null 2>&1; then
            log_success "$url is accessible"
        else
            log_error "$url is NOT accessible"
        fi
    done
}

show_configuration_guide() {
    echo ""
    echo "=== Cloudflare Dashboard Configuration Guide ==="
    echo ""
    echo "1. Go to: https://one.dash.cloudflare.com/"
    echo "2. Navigate to: Access > Tunnels"
    echo "3. Edit your tunnel configuration"
    echo "4. Update Public Hostnames with these settings:"
    echo ""
    echo "   Main Application:"
    echo "   - Subdomain: (empty)"
    echo "   - Domain: your-domain.com"
    echo "   - Service: HTTP"
    echo "   - URL: nginx:80"
    echo ""
    echo "   Grafana:"
    echo "   - Subdomain: grafana"
    echo "   - Domain: your-domain.com"
    echo "   - Service: HTTP"
    echo "   - URL: grafana:3000"
    echo ""
    echo "   Adminer:"
    echo "   - Subdomain: adminer"
    echo "   - Domain: your-domain.com"
    echo "   - Service: HTTP"
    echo "   - URL: adminer:8080"
    echo ""
    echo "   Portainer:"
    echo "   - Subdomain: portainer"
    echo "   - Domain: your-domain.com"
    echo "   - Service: HTTP"
    echo "   - URL: portainer:9000"
    echo ""
    echo "5. Save the configuration"
    echo "6. Wait 1-2 minutes for changes to propagate"
}

show_help() {
    echo "Cloudflare Tunnel Troubleshooting Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      Check tunnel status and recent logs"
    echo "  test        Test service connectivity from tunnel"
    echo "  network     Check Docker network configuration"
    echo "  config      Check Cloudflare configuration"
    echo "  fix         Attempt to fix common issues"
    echo "  logs        Show detailed tunnel logs"
    echo "  external    Test external access to services"
    echo "  guide       Show Cloudflare configuration guide"
    echo "  full        Run all diagnostic checks"
    echo "  help        Show this help"
}

# Main script logic
case "${1:-full}" in
    "status")
        check_tunnel_status
        ;;
    "test")
        check_service_connectivity
        ;;
    "network")
        check_network_configuration
        ;;
    "config")
        check_cloudflare_configuration
        ;;
    "fix")
        fix_common_issues
        ;;
    "logs")
        show_tunnel_logs
        ;;
    "external")
        test_external_access
        ;;
    "guide")
        show_configuration_guide
        ;;
    "full")
        check_tunnel_status
        echo ""
        check_service_connectivity
        echo ""
        check_network_configuration
        echo ""
        check_cloudflare_configuration
        echo ""
        show_configuration_guide
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
