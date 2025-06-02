#!/bin/bash

# PRS EC2 Graviton Deployment Script
# Optimized for EC2 t4g.medium (2 cores, 4GB memory, ARM64)
# This script manages the production environment deployment on EC2

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
HTTP_PORT=80
HTTPS_PORT=443
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

check_prerequisites() {
    log_info "Checking prerequisites for EC2 Graviton (ARM64)..."

    # Check if running on ARM64
    ARCH=$(uname -m)
    if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        log_warning "This script is optimized for ARM64 architecture. Current: $ARCH"
    else
        log_success "Running on ARM64 architecture: $ARCH"
    fi

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed."
        log_info "Install Docker on EC2: sudo yum install docker -y && sudo systemctl start docker"
        exit 1
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed."
        log_info "Install Docker Compose: sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose"
        log_info "Then: sudo chmod +x /usr/local/bin/docker-compose"
        exit 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running."
        log_info "Start Docker: sudo systemctl start docker"
        log_info "Enable Docker on boot: sudo systemctl enable docker"
        exit 1
    fi

    # Check available memory
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [ "$TOTAL_MEM" -lt 3500 ]; then
        log_warning "Available memory ($TOTAL_MEM MB) is less than recommended 4GB"
        log_warning "Performance may be impacted. Consider upgrading to a larger instance."
    else
        log_success "Memory check passed: ${TOTAL_MEM}MB available"
    fi

    # Check available disk space
    DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "${DISK_SPACE%.*}" -lt 10 ]; then
        log_warning "Available disk space (${DISK_SPACE}G) is less than recommended 10GB"
    else
        log_success "Disk space check passed: ${DISK_SPACE}G available"
    fi

    log_success "Prerequisites check completed"
}

load_environment() {
    if [ -f "$ENV_FILE" ]; then
        log_info "Loading environment from $ENV_FILE"
        source "$ENV_FILE"
        HTTP_PORT=${HTTP_PORT:-80}
        HTTPS_PORT=${HTTPS_PORT:-443}
        DOMAIN=${DOMAIN:-localhost}
    else
        log_warning ".env file not found. Using default values."
        log_info "Run 'cp .env.example .env' to create your configuration."
    fi
}

check_ports() {
    log_info "Checking port configuration..."

    if [ "${ENABLE_PUBLIC_ACCESS:-false}" = "true" ]; then
        log_warning "Public access is enabled. Checking if ports $HTTP_PORT and $HTTPS_PORT are available..."

        if netstat -tuln | grep -q ":$HTTP_PORT "; then
            log_warning "Port $HTTP_PORT is already in use. You may need to stop the conflicting service."
            netstat -tuln | grep ":$HTTP_PORT "
        fi

        if netstat -tuln | grep -q ":$HTTPS_PORT "; then
            log_warning "Port $HTTPS_PORT is already in use. You may need to stop the conflicting service."
            netstat -tuln | grep ":$HTTPS_PORT "
        fi
    else
        log_info "Public access is disabled. Services will only bind to localhost."
        log_info "Access will be available via Cloudflare Tunnel or SSH tunnel."
    fi
}

setup_ssl_certificates() {
    log_info "Setting up SSL certificates for internal nginx..."

    SSL_DIR="$PROJECT_DIR/ssl"
    mkdir -p "$SSL_DIR"

    if [ ! -f "$SSL_DIR/cert.pem" ] || [ ! -f "$SSL_DIR/key.pem" ]; then
        if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
            log_info "Creating minimal self-signed certificates for internal nginx use..."
            log_info "SSL termination is handled by Cloudflare Tunnel - these are for internal communication only"
        else
            log_info "Creating self-signed SSL certificates for local development..."
            log_warning "For production without Cloudflare Tunnel, use proper SSL certificates"
        fi

        # Create a simple self-signed certificate without problematic extensions
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_DIR/key.pem" \
            -out "$SSL_DIR/cert.pem" \
            -subj "/C=US/ST=Cloud/L=EC2/O=PRS/OU=Internal/CN=localhost"

        # Generate DH parameters for better security
        if [ ! -f "$SSL_DIR/dhparam.pem" ]; then
            log_info "Generating DH parameters (this may take a moment)..."
            openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048
        fi

        log_success "Internal SSL certificates generated"

        if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
            log_info "Public SSL is handled by Cloudflare Tunnel automatically"
        else
            log_info "Certificate valid for internal use only"
        fi
    else
        log_info "SSL certificates already exist"
    fi
}

optimize_system() {
    log_info "Optimizing system for 4GB memory..."

    # Set Docker daemon options for memory optimization
    DOCKER_DAEMON_JSON="/etc/docker/daemon.json"
    if [ ! -f "$DOCKER_DAEMON_JSON" ]; then
        log_info "Creating Docker daemon configuration for memory optimization..."
        sudo tee "$DOCKER_DAEMON_JSON" > /dev/null <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 64000,
            "Soft": 64000
        }
    }
}
EOF
        sudo systemctl restart docker
        log_success "Docker daemon optimized"
    fi

    # Set system limits for better performance
    if ! grep -q "* soft nofile 65536" /etc/security/limits.conf; then
        log_info "Setting system limits for better performance..."
        echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
        echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
    fi
}

build_images() {
    log_info "Building Docker images for ARM64..."

    cd "$PROJECT_DIR"

    # Enable BuildKit for better ARM64 support
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1

    # Build backend image
    if [ -d "../../prs-backend" ]; then
        log_info "Building backend image for ARM64..."
        docker build --platform linux/arm64 -t prs-backend:latest ../../prs-backend
    else
        log_warning "Backend directory not found. Skipping backend build."
    fi

    # Build frontend image
    if [ -d "../../prs-frontend" ]; then
        log_info "Building frontend image for ARM64..."
        docker build --platform linux/arm64 -t prs-frontend:latest ../../prs-frontend
    else
        log_warning "Frontend directory not found. Skipping frontend build."
    fi

    log_success "Docker images built for ARM64"
}

start_services() {
    log_info "Starting PRS production environment on EC2..."

    cd "$PROJECT_DIR"

    # Start database first
    log_info "Starting database..."
    docker-compose up -d postgres
    sleep 10

    # Start backend and frontend
    log_info "Starting backend and frontend..."
    docker-compose up -d backend frontend
    sleep 10

    # Start monitoring services BEFORE nginx (nginx config references them)
    if [ "${PROMETHEUS_ENABLED:-true}" = "true" ] || [ "${GRAFANA_ENABLED:-true}" = "true" ]; then
        log_info "Starting monitoring services (required for nginx)..."
        docker-compose --profile monitoring up -d
        sleep 10
    fi

    # Now start nginx (after monitoring services are running)
    log_info "Starting nginx and other services..."
    docker-compose up -d nginx adminer portainer
    sleep 10

    # Start Cloudflare Tunnel if token is provided (after all other services)
    if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
        log_info "Starting Cloudflare Tunnel..."
        # Validate tunnel token format
        if [[ "${CLOUDFLARE_TUNNEL_TOKEN}" =~ ^[A-Za-z0-9_-]+$ ]]; then
            docker-compose --profile cloudflare up -d
            sleep 5

            # Check if tunnel started successfully
            if docker ps | grep -q prs-ec2-cloudflared; then
                log_success "Cloudflare Tunnel started successfully"
            else
                log_error "Cloudflare Tunnel failed to start. Check token and logs."
                docker logs prs-ec2-cloudflared 2>/dev/null || log_warning "No tunnel logs available"
            fi
        else
            log_error "Invalid Cloudflare Tunnel token format"
            log_info "Services are only accessible via localhost or SSH tunnel."
        fi
    else
        log_info "No Cloudflare Tunnel token provided. Skipping tunnel setup."
        log_info "Services are only accessible via localhost or SSH tunnel."
    fi

    log_success "Services started"
}

stop_services() {
    log_info "Stopping PRS production environment..."

    cd "$PROJECT_DIR"

    # Stop all profiles to ensure everything is stopped
    docker-compose --profile cloudflare --profile monitoring down

    log_success "Services stopped"
}

show_status() {
    log_info "Service status:"

    cd "$PROJECT_DIR"
    docker-compose ps

    echo ""
    log_info "System Resources:"
    echo "  Memory Usage: $(free -h | awk 'NR==2{printf "%.1f/%.1fGB (%.0f%%)", $3/1024, $2/1024, $3*100/$2}')"
    echo "  Disk Usage:   $(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')"
    echo "  CPU Load:     $(uptime | awk -F'load average:' '{print $2}')"

    echo ""
    log_info "Access URLs:"

    if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
        echo "  🌐 Via Cloudflare Tunnel:"
        echo "    Main Application: https://$DOMAIN"
        echo "    Backend API:      https://$DOMAIN/api"
        echo "    Grafana:          https://grafana.$DOMAIN"
        echo "    Adminer:          https://adminer.$DOMAIN"
        echo "    Portainer:        https://portainer.$DOMAIN"
        echo "    Health Check:     https://$DOMAIN/health"
    else
        echo "  🔒 Local Access Only (via SSH tunnel):"
        echo "    Main Application: http://localhost:$HTTP_PORT"
        echo "    Backend API:      http://localhost:$HTTP_PORT/api"
        echo "    Database Admin:   http://localhost:8080"
        echo "    Portainer:        http://localhost:9000"
        echo "    Grafana:          http://localhost:3001"
        echo "    Health Check:     http://localhost:$HTTP_PORT/health"
        echo ""
        echo "  📡 SSH Tunnel Commands:"
        echo "    ssh -L 80:localhost:80 -L 443:localhost:443 -L 8080:localhost:8080 -L 9000:localhost:9000 -L 3001:localhost:3001 ec2-user@$DOMAIN"
    fi
}

show_logs() {
    cd "$PROJECT_DIR"

    if [ -n "$2" ]; then
        log_info "Showing logs for service: $2"
        docker-compose logs -f "$2"
    else
        log_info "Showing logs for all services"
        docker-compose logs -f
    fi
}

init_database() {
    log_info "Initializing database..."

    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    sleep 15

    # Check if backend container is running
    cd "$PROJECT_DIR"
    if ! docker-compose ps backend | grep -q "Up"; then
        log_error "Backend container is not running. Cannot initialize database."
        return 1
    fi

    # Determine which scripts to use based on NODE_ENV
    local migrate_script="migrate:dev"
    local seed_script="seed:dev"

    # Load environment to check NODE_ENV
    if [ -f "$PROJECT_DIR/.env" ]; then
        source "$PROJECT_DIR/.env"
        if [ "${NODE_ENV:-development}" = "production" ]; then
            migrate_script="migrate:prod"
            seed_script="seed:prod"
            log_info "Using production database scripts"
        else
            log_info "Using development database scripts"
        fi
    fi

    # Run database migrations using the correct script names from package.json
    log_info "Running database migrations..."
    if docker-compose exec -T backend npm run "$migrate_script"; then
        log_success "Database migrations completed"
    else
        log_warning "Database migrations failed - this may be normal if already migrated"
    fi

    # Run database seeders using the correct script names from package.json
    log_info "Running database seeders..."
    if docker-compose exec -T backend npm run "$seed_script"; then
        log_success "Database seeders completed"
    else
        log_warning "Database seeders failed - this may be normal if data already exists"
    fi

    log_success "Database initialization completed"
}

import_database() {
    local sql_file="$1"

    if [ -z "$sql_file" ]; then
        log_error "Please provide a SQL file path"
        log_info "Usage: $0 import-db <path-to-sql-file>"
        exit 1
    fi

    if [ ! -f "$sql_file" ]; then
        log_error "SQL file not found: $sql_file"
        exit 1
    fi

    log_info "Importing database from: $sql_file"

    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    sleep 10

    # Check if database container is running
    cd "$PROJECT_DIR"
    if ! docker-compose ps postgres | grep -q "Up"; then
        log_error "PostgreSQL container is not running. Please start services first."
        exit 1
    fi

    # Import the SQL file
    log_info "Importing SQL dump..."
    if docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" < "$sql_file"; then
        log_success "Database import completed successfully"
    else
        log_error "Database import failed"
        exit 1
    fi
}

monitor_resources() {
    log_info "Resource monitoring (Press Ctrl+C to stop):"

    while true; do
        clear
        echo "=== PRS EC2 Resource Monitor ==="
        echo "Time: $(date)"
        echo ""

        # Memory usage
        echo "Memory Usage:"
        free -h
        echo ""

        # Docker container stats
        echo "Container Resource Usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
        echo ""

        # Disk usage
        echo "Disk Usage:"
        df -h /
        echo ""

        sleep 5
    done
}

show_help() {
    echo "PRS EC2 Graviton Deployment Script"
    echo "Optimized for t4g.medium (2 cores, 4GB memory, ARM64)"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy              Full deployment (build, start, init/import)"
    echo "  start               Start services"
    echo "  stop                Stop services"
    echo "  restart             Restart services"
    echo "  status              Show service status and resource usage"
    echo "  logs [service]      Show logs"
    echo "  build               Build Docker images for ARM64"
    echo "  init-db             Initialize database"
    echo "  import-db <file>    Import SQL dump file"
    echo "  ssl-setup           Setup internal SSL certificates"
    echo "  optimize            Optimize system for 4GB memory"
    echo "  validate            Validate configuration before deployment"
    echo "  troubleshoot        Troubleshoot Cloudflare Tunnel issues"
    echo "  monitor             Monitor system resources"
    echo "  help                Show this help"
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        check_prerequisites
        load_environment

        # Run validation first
        if [ -f "$SCRIPT_DIR/validate-setup.sh" ]; then
            log_info "Running pre-deployment validation..."
            if ! "$SCRIPT_DIR/validate-setup.sh"; then
                log_error "Validation failed. Please fix errors before deploying."
                exit 1
            fi
        fi

        check_ports
        optimize_system
        setup_ssl_certificates
        build_images
        start_services
        sleep 20

        # Auto-import database if dump file exists
        if [ -f "dump_file_fixed_lineendings.sql" ]; then
            log_info "Found database dump file"
            import_database "dump_file_fixed_lineendings.sql"
        elif [ -f "dump_file_20250526.sql" ]; then
            log_info "Found database dump file"
            import_database "dump_file_20250526.sql"
        else
            init_database
        fi

        show_status
        ;;
    "start")
        load_environment
        start_services
        show_status
        ;;
    "stop")
        load_environment
        stop_services
        ;;
    "restart")
        load_environment
        stop_services
        start_services
        show_status
        ;;
    "status")
        load_environment
        show_status
        ;;
    "logs")
        load_environment
        show_logs "$@"
        ;;
    "build")
        check_prerequisites
        build_images
        ;;
    "init-db")
        load_environment
        init_database
        ;;
    "import-db")
        load_environment
        import_database "$2"
        ;;
    "ssl-setup")
        load_environment
        setup_ssl_certificates
        ;;
    "optimize")
        optimize_system
        ;;
    "validate")
        if [ -f "$SCRIPT_DIR/validate-setup.sh" ]; then
            "$SCRIPT_DIR/validate-setup.sh"
        else
            log_error "Validation script not found"
            exit 1
        fi
        ;;
    "troubleshoot")
        if [ -f "$SCRIPT_DIR/troubleshoot-tunnel.sh" ]; then
            "$SCRIPT_DIR/troubleshoot-tunnel.sh" "${2:-full}"
        else
            log_error "Troubleshooting script not found"
            exit 1
        fi
        ;;
    "monitor")
        monitor_resources
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
