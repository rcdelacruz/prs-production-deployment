#!/bin/bash

# Quick Fix for Cloudflare Tunnel DNS Issues
# This script fixes the "server misbehaving" DNS resolution errors

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

main() {
    log_info "🔧 Quick Fix for Cloudflare Tunnel DNS Issues"
    echo ""
    
    cd "$PROJECT_DIR"
    
    # Step 1: Stop tunnel to prevent conflicts
    log_info "Step 1: Stopping Cloudflare Tunnel..."
    docker-compose --profile cloudflare down 2>/dev/null || true
    
    # Step 2: Restart Docker daemon to fix DNS issues
    log_info "Step 2: Restarting Docker daemon to fix DNS resolution..."
    sudo systemctl restart docker
    sleep 10
    
    # Step 3: Restart services in proper order
    log_info "Step 3: Starting services in proper order..."
    
    # Start database first
    log_info "  Starting PostgreSQL..."
    docker-compose up -d postgres
    sleep 10
    
    # Start backend and frontend
    log_info "  Starting backend and frontend..."
    docker-compose up -d backend frontend
    sleep 15
    
    # Start nginx (reverse proxy)
    log_info "  Starting nginx..."
    docker-compose up -d nginx
    sleep 10
    
    # Start other services
    log_info "  Starting adminer and portainer..."
    docker-compose up -d adminer portainer
    sleep 10
    
    # Start monitoring if enabled
    if [ -f ".env" ]; then
        source .env
        if [ "${PROMETHEUS_ENABLED:-true}" = "true" ] || [ "${GRAFANA_ENABLED:-true}" = "true" ]; then
            log_info "  Starting monitoring services..."
            docker-compose --profile monitoring up -d
            sleep 10
        fi
    fi
    
    # Step 4: Verify services are healthy
    log_info "Step 4: Verifying services are healthy..."
    
    local services=("nginx" "backend" "frontend" "postgres" "adminer" "portainer")
    local all_healthy=true
    
    for service in "${services[@]}"; do
        if docker ps | grep -q "prs-ec2-$service.*Up"; then
            log_success "  ✅ $service is running"
        else
            log_error "  ❌ $service is not running properly"
            all_healthy=false
        fi
    done
    
    if [ "$all_healthy" = false ]; then
        log_error "Some services are not healthy. Please check logs before starting tunnel."
        echo ""
        echo "Check logs with:"
        echo "  docker-compose logs nginx"
        echo "  docker-compose logs backend"
        echo "  docker-compose logs frontend"
        exit 1
    fi
    
    # Step 5: Test internal connectivity
    log_info "Step 5: Testing internal service connectivity..."
    
    # Test if nginx can reach backend
    if docker exec prs-ec2-nginx wget -q --spider --timeout=5 http://backend:4000 2>/dev/null; then
        log_success "  ✅ nginx → backend connectivity OK"
    else
        log_error "  ❌ nginx → backend connectivity FAILED"
        all_healthy=false
    fi
    
    # Test if nginx can reach frontend
    if docker exec prs-ec2-nginx wget -q --spider --timeout=5 http://frontend:3000 2>/dev/null; then
        log_success "  ✅ nginx → frontend connectivity OK"
    else
        log_error "  ❌ nginx → frontend connectivity FAILED"
        all_healthy=false
    fi
    
    if [ "$all_healthy" = false ]; then
        log_error "Internal connectivity issues detected. Please check service logs."
        exit 1
    fi
    
    # Step 6: Start Cloudflare Tunnel
    log_info "Step 6: Starting Cloudflare Tunnel..."
    docker-compose --profile cloudflare up -d cloudflared
    sleep 15
    
    # Step 7: Verify tunnel is working
    log_info "Step 7: Verifying Cloudflare Tunnel..."
    
    if docker ps | grep -q "prs-ec2-cloudflared.*Up"; then
        log_success "  ✅ Cloudflare Tunnel container is running"
        
        # Check recent logs for errors
        log_info "  Checking tunnel logs for errors..."
        if docker logs prs-ec2-cloudflared --tail 10 2>&1 | grep -q "ERR"; then
            log_warning "  ⚠️  Found errors in tunnel logs:"
            docker logs prs-ec2-cloudflared --tail 5 2>&1 | grep "ERR" || true
        else
            log_success "  ✅ No errors found in recent tunnel logs"
        fi
    else
        log_error "  ❌ Cloudflare Tunnel failed to start"
        echo ""
        echo "Tunnel logs:"
        docker logs prs-ec2-cloudflared --tail 20 2>&1 || true
        exit 1
    fi
    
    # Step 8: Test tunnel connectivity
    log_info "Step 8: Testing tunnel connectivity to services..."
    
    local tunnel_services=("nginx:80" "adminer:8080" "portainer:9000")
    
    for service in "${tunnel_services[@]}"; do
        if docker exec prs-ec2-cloudflared wget -q --spider --timeout=5 "http://$service" 2>/dev/null; then
            log_success "  ✅ tunnel → $service connectivity OK"
        else
            log_warning "  ⚠️  tunnel → $service connectivity issues"
        fi
    done
    
    # Final status
    echo ""
    echo "🎉 DNS Fix Complete!"
    echo ""
    log_info "Next steps:"
    echo "1. Wait 2-3 minutes for tunnel to fully stabilize"
    echo "2. Test your public URLs:"
    
    if [ -f ".env" ]; then
        source .env
        echo "   - Main App: https://${DOMAIN:-your-domain.com}"
        echo "   - Adminer:  https://adminer.${DOMAIN:-your-domain.com}"
        echo "   - Portainer: https://portainer.${DOMAIN:-your-domain.com}"
        if [ "${GRAFANA_ENABLED:-true}" = "true" ]; then
            echo "   - Grafana:  https://grafana.${DOMAIN:-your-domain.com}"
        fi
    fi
    
    echo ""
    echo "3. Monitor tunnel logs:"
    echo "   docker logs prs-ec2-cloudflared -f"
    echo ""
    echo "4. If issues persist, run:"
    echo "   ./scripts/troubleshoot-tunnel.sh"
}

# Run the fix
main "$@"
