#!/bin/bash

# Cloudflare Tunnel Setup Script for PRS EC2
# This script helps you set up Cloudflare Tunnel for secure access

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

check_prerequisites() {
    log_info "Checking Cloudflare Tunnel prerequisites..."

    # Check if cloudflared is installed
    if ! command -v cloudflared &> /dev/null; then
        log_info "Installing cloudflared..."

        # Download and install cloudflared for ARM64
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
        sudo mv cloudflared-linux-arm64 /usr/local/bin/cloudflared
        sudo chmod +x /usr/local/bin/cloudflared

        log_success "cloudflared installed"
    else
        log_info "cloudflared is already installed"
        cloudflared --version
    fi
}

setup_tunnel() {
    log_info "Setting up Cloudflare Tunnel..."

    echo ""
    echo "🌐 Cloudflare Tunnel Setup Instructions:"
    echo ""
    echo "1. Go to Cloudflare Zero Trust Dashboard:"
    echo "   https://one.dash.cloudflare.com/"
    echo ""
    echo "2. Navigate to Access > Tunnels"
    echo ""
    echo "3. Create a new tunnel:"
    echo "   - Click 'Create a tunnel'"
    echo "   - Choose 'Cloudflared'"
    echo "   - Give it a name (e.g., 'prs-ec2-tunnel')"
    echo ""
    echo "4. Install and run connector:"
    echo "   - Copy the tunnel token from the dashboard"
    echo "   - Add it to your .env file as CLOUDFLARE_TUNNEL_TOKEN"
    echo ""
    echo "5. Configure public hostnames in Cloudflare dashboard:"
    echo ""

    read -p "Enter your domain name (e.g., example.com): " DOMAIN

    echo "   Main Application:"
    echo "   - Subdomain: (leave empty for root domain)"
    echo "   - Domain: $DOMAIN"
    echo "   - Service: HTTP://nginx:80"
    echo ""
    echo "   Grafana Dashboard:"
    echo "   - Subdomain: grafana"
    echo "   - Domain: $DOMAIN"
    echo "   - Service: HTTP://grafana:3000"
    echo ""
    echo "   Adminer Database:"
    echo "   - Subdomain: adminer"
    echo "   - Domain: $DOMAIN"
    echo "   - Service: HTTP://adminer:8080"
    echo ""
    echo "   Portainer Container Management:"
    echo "   - Subdomain: portainer"
    echo "   - Domain: $DOMAIN"
    echo "   - Service: HTTP://portainer:9000"
    echo ""

    read -p "Press Enter when you have configured the tunnel in Cloudflare dashboard..."
}

configure_environment() {
    log_info "Configuring environment for Cloudflare Tunnel..."

    ENV_FILE="$PROJECT_DIR/.env"

    if [ ! -f "$ENV_FILE" ]; then
        log_warning ".env file not found. Creating from example..."
        cp "$PROJECT_DIR/.env.example" "$ENV_FILE"
    fi

    echo ""
    read -p "Enter your Cloudflare Tunnel Token: " TUNNEL_TOKEN
    read -p "Enter your domain (e.g., example.com): " DOMAIN

    # Update .env file
    sed -i "s/CLOUDFLARE_TUNNEL_TOKEN=.*/CLOUDFLARE_TUNNEL_TOKEN=$TUNNEL_TOKEN/" "$ENV_FILE"
    sed -i "s/DOMAIN=.*/DOMAIN=$DOMAIN/" "$ENV_FILE"
    sed -i "s/ENABLE_PUBLIC_ACCESS=.*/ENABLE_PUBLIC_ACCESS=false/" "$ENV_FILE"

    log_success "Environment configured"
}

setup_security_groups() {
    log_info "Security Group Configuration for Cloudflare Tunnel:"
    echo ""
    echo "🔒 AWS Security Group Settings:"
    echo ""
    echo "REMOVE these inbound rules (no longer needed):"
    echo "  - Port 80 (HTTP) from 0.0.0.0/0"
    echo "  - Port 443 (HTTPS) from 0.0.0.0/0"
    echo "  - Port 8080 (Adminer) from 0.0.0.0/0"
    echo "  - Port 3001 (Grafana) from 0.0.0.0/0"
    echo ""
    echo "KEEP these inbound rules:"
    echo "  - Port 22 (SSH) from your IP only"
    echo ""
    echo "The Cloudflare Tunnel will handle all web traffic securely."
    echo ""

    read -p "Press Enter when you have updated your Security Group..."
}

test_tunnel() {
    log_info "Testing Cloudflare Tunnel connection..."

    # Load environment
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
    fi

    if [ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]; then
        log_error "CLOUDFLARE_TUNNEL_TOKEN not set in .env file"
        return 1
    fi

    # Test tunnel connectivity
    log_info "Testing tunnel token..."
    if cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARE_TUNNEL_TOKEN" &
    then
        TUNNEL_PID=$!
        sleep 5
        kill $TUNNEL_PID 2>/dev/null || true
        log_success "Tunnel token is valid"
    else
        log_error "Tunnel token test failed"
        return 1
    fi
}

deploy_with_tunnel() {
    log_info "Deploying PRS with Cloudflare Tunnel..."

    cd "$PROJECT_DIR"

    # Use the main deployment script for proper service ordering
    if [ -f "./scripts/deploy-ec2.sh" ]; then
        log_info "Using main deployment script for proper service startup..."
        ./scripts/deploy-ec2.sh deploy
    else
        log_warning "Main deployment script not found, using direct docker-compose..."
        # Fallback to direct deployment with proper ordering
        docker-compose up -d postgres
        sleep 5
        docker-compose up -d backend frontend
        sleep 5
        docker-compose up -d nginx adminer portainer
        sleep 5
        docker-compose --profile monitoring up -d
        sleep 5
        docker-compose --profile cloudflare up -d
    fi

    log_success "PRS deployed with Cloudflare Tunnel"

    echo ""
    log_info "Access your services:"
    echo "  Main App:  https://$DOMAIN"
    echo "  Grafana:   https://grafana.$DOMAIN"
    echo "  Adminer:   https://adminer.$DOMAIN"
    echo "  Portainer: https://portainer.$DOMAIN"
    echo ""
    log_warning "Note: It may take a few minutes for DNS to propagate"
}

show_status() {
    log_info "Cloudflare Tunnel Status:"

    cd "$PROJECT_DIR"

    # Check if cloudflared container is running
    if docker ps | grep -q cloudflared; then
        log_success "Cloudflare Tunnel is running"
        docker logs prs-ec2-cloudflared --tail 10
    else
        log_warning "Cloudflare Tunnel is not running"
    fi

    echo ""
    log_info "Service Status:"
    docker-compose ps
}

show_help() {
    echo "Cloudflare Tunnel Setup Script for PRS EC2"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup       Complete Cloudflare Tunnel setup"
    echo "  configure   Configure environment variables"
    echo "  test        Test tunnel connection"
    echo "  deploy      Deploy with tunnel"
    echo "  status      Show tunnel status"
    echo "  help        Show this help"
    echo ""
    echo "Setup Process:"
    echo "1. Run: $0 setup"
    echo "2. Follow the interactive prompts"
    echo "3. Configure tunnel in Cloudflare dashboard"
    echo "4. Update AWS Security Groups"
    echo "5. Deploy with: $0 deploy"
}

# Main script logic
case "${1:-setup}" in
    "setup")
        check_prerequisites
        setup_tunnel
        configure_environment
        setup_security_groups
        test_tunnel
        log_success "Cloudflare Tunnel setup complete!"
        echo ""
        echo "Next steps:"
        echo "1. Update your AWS Security Groups (remove public web ports)"
        echo "2. Run: $0 deploy"
        ;;
    "configure")
        configure_environment
        ;;
    "test")
        test_tunnel
        ;;
    "deploy")
        deploy_with_tunnel
        ;;
    "status")
        show_status
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
