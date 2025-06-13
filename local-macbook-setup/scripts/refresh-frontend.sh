#!/bin/bash

# Quick Frontend Refresh Script
# Rebuilds and restarts frontend without hot reload issues

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Main function
main() {
    log_info "🔄 Refreshing frontend with latest changes..."
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        log_error "Please run this script from the local-macbook-setup directory"
        exit 1
    fi
    
    # Quick rebuild and restart
    log_info "📦 Rebuilding frontend container..."
    if docker-compose build frontend --no-cache; then
        log_success "Frontend build completed"
    else
        log_error "Frontend build failed"
        exit 1
    fi
    
    log_info "🔄 Restarting frontend container..."
    if docker restart prs-local-frontend; then
        log_success "Frontend restarted"
    else
        log_error "Frontend restart failed"
        exit 1
    fi
    
    # Wait a moment for the container to start
    sleep 3
    
    # Test if the application is accessible
    log_info "🧪 Testing application accessibility..."
    if curl -k https://localhost:8444 --max-time 5 -I >/dev/null 2>&1; then
        log_success "✅ Application is accessible at https://localhost:8444"
        log_info "🎉 Frontend refresh completed successfully!"
    else
        log_warning "⚠️  Application may still be starting up"
        log_info "Please wait a moment and check https://localhost:8444"
    fi
    
    echo ""
    log_info "💡 To see your changes:"
    log_info "   1. Make your frontend code changes"
    log_info "   2. Run: ./scripts/refresh-frontend.sh"
    log_info "   3. Refresh your browser"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
