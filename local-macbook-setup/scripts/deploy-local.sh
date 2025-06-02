#!/bin/bash

# PRS Cross-Platform Local Deployment Script
# This script manages the local development environment for PRS
# Compatible with Linux, macOS, and Windows (WSL/Git Bash)

set -e

# Detect operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
else
    OS="unknown"
fi

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

check_prerequisites() {
    log_info "Checking prerequisites on $OS..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed."
        case $OS in
            "linux")
                log_info "Install Docker: sudo apt-get install docker.io docker-compose (Ubuntu/Debian)"
                log_info "Or: sudo yum install docker docker-compose (CentOS/RHEL)"
                ;;
            "macos")
                log_info "Install Docker Desktop for Mac from https://docker.com"
                ;;
            "windows")
                log_info "Install Docker Desktop for Windows from https://docker.com"
                ;;
        esac
        exit 1
    fi

    # Check Docker Compose (try both docker-compose and docker compose)
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed."
        case $OS in
            "linux")
                log_info "Install Docker Compose or use Docker with compose plugin"
                ;;
            "macos"|"windows")
                log_info "Docker Compose should be included with Docker Desktop"
                ;;
        esac
        exit 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running."
        case $OS in
            "linux")
                log_info "Start Docker: sudo systemctl start docker"
                ;;
            "macos"|"windows")
                log_info "Start Docker Desktop application"
                ;;
        esac
        exit 1
    fi

    log_success "Prerequisites check passed on $OS"
}

load_environment() {
    if [ -f "$ENV_FILE" ]; then
        log_info "Loading environment from $ENV_FILE"
        source "$ENV_FILE"
        HTTP_PORT=${HTTP_PORT:-8080}
        HTTPS_PORT=${HTTPS_PORT:-8443}
        DOMAIN=${DOMAIN:-localhost}
    else
        log_warning ".env file not found. Using default values."
        log_info "Run 'cp .env.example .env' to create your configuration."
    fi
}

check_ports() {
    log_info "Checking if ports $HTTP_PORT and $HTTPS_PORT are available..."

    # Cross-platform port checking
    case $OS in
        "linux"|"macos")
            if command -v lsof &> /dev/null; then
                if lsof -i :$HTTP_PORT &> /dev/null; then
                    log_warning "Port $HTTP_PORT is already in use. You may need to stop the conflicting service or change HTTP_PORT in .env"
                fi
                if lsof -i :$HTTPS_PORT &> /dev/null; then
                    log_warning "Port $HTTPS_PORT is already in use. You may need to stop the conflicting service or change HTTPS_PORT in .env"
                fi
            elif command -v netstat &> /dev/null; then
                if netstat -tuln | grep -q ":$HTTP_PORT "; then
                    log_warning "Port $HTTP_PORT is already in use. You may need to stop the conflicting service or change HTTP_PORT in .env"
                fi
                if netstat -tuln | grep -q ":$HTTPS_PORT "; then
                    log_warning "Port $HTTPS_PORT is already in use. You may need to stop the conflicting service or change HTTPS_PORT in .env"
                fi
            fi
            ;;
        "windows")
            if command -v netstat &> /dev/null; then
                if netstat -an | grep -q ":$HTTP_PORT "; then
                    log_warning "Port $HTTP_PORT is already in use. You may need to stop the conflicting service or change HTTP_PORT in .env"
                fi
                if netstat -an | grep -q ":$HTTPS_PORT "; then
                    log_warning "Port $HTTPS_PORT is already in use. You may need to stop the conflicting service or change HTTPS_PORT in .env"
                fi
            fi
            ;;
    esac
}

generate_ssl_certificates() {
    log_info "Generating SSL certificates for local development..."

    SSL_DIR="$PROJECT_DIR/ssl"
    mkdir -p "$SSL_DIR"

    if [ ! -f "$SSL_DIR/cert.pem" ] || [ ! -f "$SSL_DIR/key.pem" ]; then
        log_info "Creating self-signed SSL certificate..."

        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_DIR/key.pem" \
            -out "$SSL_DIR/cert.pem" \
            -subj "/C=US/ST=Local/L=Local/O=PRS Local/OU=Development/CN=localhost" \
            -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1"

        log_success "SSL certificate generated"
    else
        log_info "SSL certificate already exists"
    fi
}

build_images() {
    log_info "Building Docker images..."

    cd "$PROJECT_DIR"

    # Build backend image
    if [ -d "../../prs-backend" ]; then
        log_info "Building backend image..."
        docker build -t prs-backend:latest ../../prs-backend
    else
        log_warning "Backend directory not found. Skipping backend build."
    fi

    # Build frontend image
    if [ -d "../../prs-frontend" ]; then
        log_info "Building frontend image..."
        docker build -t prs-frontend:latest ../../prs-frontend
    else
        log_warning "Frontend directory not found. Skipping frontend build."
    fi

    log_success "Docker images built"
}

start_services() {
    log_info "Starting PRS local development environment..."

    cd "$PROJECT_DIR"

    # Start core services
    docker-compose up -d nginx backend frontend postgres portainer adminer

    # Start monitoring services if enabled
    if [ "${PROMETHEUS_ENABLED:-true}" = "true" ] || [ "${GRAFANA_ENABLED:-true}" = "true" ]; then
        log_info "Starting monitoring services..."
        docker-compose --profile monitoring up -d
    fi

    log_success "Services started"
}

stop_services() {
    log_info "Stopping PRS local development environment..."

    cd "$PROJECT_DIR"
    docker-compose down

    log_success "Services stopped"
}

show_status() {
    log_info "Service status:"

    cd "$PROJECT_DIR"
    docker-compose ps

    echo ""
    log_info "Access URLs:"
    echo "  Main Application: https://localhost:$HTTPS_PORT"
    echo "  Backend API:      https://localhost:$HTTPS_PORT/api"
    echo "  Portainer:        https://localhost:$HTTPS_PORT/portainer"
    echo "  Adminer:          https://localhost:$HTTPS_PORT/adminer"
    echo "  Grafana:          https://localhost:$HTTPS_PORT/grafana"
    echo "  Health Check:     https://localhost:$HTTPS_PORT/health"
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

rebuild_services() {
    log_info "Rebuilding services..."

    cd "$PROJECT_DIR"
    docker-compose down
    build_images
    start_services

    log_success "Services rebuilt and restarted"
}

reset_environment() {
    log_warning "This will remove all containers, volumes, and data. Are you sure? (y/N)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Resetting local environment..."

        cd "$PROJECT_DIR"
        docker-compose down -v --remove-orphans
        docker system prune -f

        # Remove SSL certificates
        rm -rf "$PROJECT_DIR/ssl"

        log_success "Environment reset complete"
    else
        log_info "Reset cancelled"
    fi
}

init_database() {
    log_info "Initializing database..."

    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    sleep 10

    # Run database migrations
    cd "$PROJECT_DIR"
    docker-compose exec backend npm run sequelize:migrate:dev || true
    docker-compose exec backend npm run sequelize:run:seeder:all:dev || true

    log_success "Database initialized"
}

import_database() {
    local sql_file="$1"

    if [ -z "$sql_file" ]; then
        log_error "Please provide a SQL file path"
        log_info "Usage: $0 import-db <path-to-sql-file>"
        log_info "Example: $0 import-db dump_file_20250526.sql"
        exit 1
    fi

    if [ ! -f "$sql_file" ]; then
        log_error "SQL file not found: $sql_file"
        exit 1
    fi

    log_info "Importing database from: $sql_file"

    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    sleep 5

    # Check if database container is running
    cd "$PROJECT_DIR"
    if ! docker-compose ps postgres | grep -q "Up"; then
        log_error "PostgreSQL container is not running. Please start services first."
        log_info "Run: $0 start"
        exit 1
    fi

    # Import the SQL file
    log_info "Importing SQL dump..."
    if docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres psql -U "${POSTGRES_USER:-prs_user}" -d "${POSTGRES_DB:-prs_local}" < "$sql_file"; then
        log_success "Database import completed successfully"
        log_info "You can now access the application with the imported data"
    else
        log_error "Database import failed"
        log_info "Check the SQL file format and database connection"
        exit 1
    fi
}

show_help() {
    echo "PRS Cross-Platform Local Deployment Script"
    echo "Compatible with Linux, macOS, and Windows (WSL/Git Bash)"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy              Full deployment (build, start, init/import)"
    echo "  redeploy            Reset and redeploy with fresh database import"
    echo "  start               Start services"
    echo "  stop                Stop services"
    echo "  restart             Restart services"
    echo "  status              Show service status"
    echo "  logs [service]      Show logs (optionally for specific service)"
    echo "  build               Build Docker images"
    echo "  rebuild             Rebuild and restart services"
    echo "  reset               Reset entire environment (removes all data)"
    echo "  ssl-reset           Regenerate SSL certificates"
    echo "  init-db             Initialize database"
    echo "  import-db <file>    Import SQL dump file into database"
    echo "  help                Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 deploy                        # Full deployment (auto-imports dump if found)"
    echo "  $0 redeploy                      # Reset and redeploy with fresh import"
    echo "  $0 logs backend                  # Show backend logs"
    echo "  $0 status                        # Show service status"
    echo "  $0 import-db dump_file_20250526.sql  # Import SQL dump manually"
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        check_prerequisites
        load_environment
        check_ports
        generate_ssl_certificates
        build_images
        start_services
        sleep 15

        # Check if dump file exists and import it before init
        if [ -f "dump_file_20250526.sql" ]; then
            log_info "Found dump_file_20250526.sql"
            log_info "Importing database dump before initialization..."
            import_database "dump_file_20250526.sql"
            log_info "Database dump imported successfully"
        else
            log_info "No dump file found, running standard database initialization..."
            init_database
        fi

        show_status
        ;;
    "redeploy")
        log_warning "This will reset the entire environment and redeploy with fresh database import."
        log_warning "All existing data will be lost. Continue? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            check_prerequisites
            load_environment

            # Reset environment
            log_info "Resetting environment..."
            docker-compose down -v --remove-orphans

            # Remove SSL certificates to regenerate
            rm -rf "$PROJECT_DIR/ssl"

            # Full deployment
            check_ports
            generate_ssl_certificates
            build_images
            start_services
            sleep 15

            # Import database if dump file exists
            if [ -f "dump_file_20250526.sql" ]; then
                log_info "Found dump_file_20250526.sql"
                log_info "Importing database dump..."
                import_database "dump_file_20250526.sql"
                log_info "Database dump imported successfully"
            else
                log_info "No dump file found, running standard database initialization..."
                init_database
            fi

            show_status
            log_success "Redeploy completed successfully!"
        else
            log_info "Redeploy cancelled"
        fi
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
    "rebuild")
        check_prerequisites
        load_environment
        rebuild_services
        show_status
        ;;
    "reset")
        load_environment
        reset_environment
        ;;
    "ssl-reset")
        rm -rf "$PROJECT_DIR/ssl"
        generate_ssl_certificates
        log_info "Restart nginx to use new certificates: $0 restart"
        ;;
    "init-db")
        load_environment
        init_database
        ;;
    "import-db")
        load_environment
        import_database "$2"
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
