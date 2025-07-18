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
    log_info "Setting up SSL certificates for nginx and PostgreSQL..."

    SSL_DIR="$PROJECT_DIR/ssl"
    mkdir -p "$SSL_DIR"

    # Setup nginx SSL certificates
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

        log_success "Nginx SSL certificates generated"
    else
        log_info "Nginx SSL certificates already exist"
    fi

    # Setup PostgreSQL SSL certificates
    if [ ! -f "$SSL_DIR/server.crt" ] || [ ! -f "$SSL_DIR/server.key" ]; then
        log_info "Generating PostgreSQL SSL certificates..."

        # Generate private key for PostgreSQL
        openssl genrsa -out "$SSL_DIR/server.key" 2048
        chmod 600 "$SSL_DIR/server.key"

        # Generate certificate for PostgreSQL
        openssl req -new -key "$SSL_DIR/server.key" -out "$SSL_DIR/server.csr" \
            -subj "/C=US/ST=Cloud/L=EC2/O=PRS/OU=Database/CN=postgres"

        openssl x509 -req -in "$SSL_DIR/server.csr" -signkey "$SSL_DIR/server.key" \
            -out "$SSL_DIR/server.crt" -days 365

        chmod 644 "$SSL_DIR/server.crt"
        rm "$SSL_DIR/server.csr"

        # Create root certificate (copy of server cert for this setup)
        cp "$SSL_DIR/server.crt" "$SSL_DIR/root.crt"

        log_success "PostgreSQL SSL certificates generated"
    else
        log_info "PostgreSQL SSL certificates already exist"
    fi

    if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
        log_info "Public SSL is handled by Cloudflare Tunnel automatically"
    else
        log_info "Certificates valid for internal use only"
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

pull_repositories() {
    local force_pull="${1:-false}"

    log_info "Pulling latest code from repositories..."
    if [ "$force_pull" = "true" ]; then
        log_warning "Force pull enabled - will overwrite local changes!"
    fi

    # Configuration from environment variables (loaded from .env file)
    local backend_repo_name="${BACKEND_REPO_NAME:-prs-backend-a}"
    local frontend_repo_name="${FRONTEND_REPO_NAME:-prs-frontend-a}"
    local backend_repo_url="${BACKEND_REPO_URL:-https://github.com/rcdelacruz/prs-backend-a.git}"
    local frontend_repo_url="${FRONTEND_REPO_URL:-https://github.com/rcdelacruz/prs-frontend-a.git}"
    local repos_base_dir="${REPOS_BASE_DIR:-/home/ubuntu/prs-prod}"
    local git_branch="${GIT_BRANCH:-main}"

    log_info "Repository configuration:"
    log_info "  Base directory: $repos_base_dir"
    log_info "  Backend repo: $backend_repo_name"
    log_info "  Frontend repo: $frontend_repo_name"
    log_info "  Git branch: $git_branch"
    log_info "  Force pull: $force_pull"

    # Ensure base directory exists
    if [ ! -d "$repos_base_dir" ]; then
        log_error "Repository base directory not found: $repos_base_dir"
        log_info "Please set REPOS_BASE_DIR environment variable or create the directory"
        exit 1
    fi

    cd "$repos_base_dir"

    # Pull or clone backend repository
    if [ -d "$backend_repo_name" ]; then
        log_info "Updating $backend_repo_name repository..."
        cd "$backend_repo_name"
        if git status &> /dev/null; then
            # Check if there are uncommitted changes
            if ! git diff-index --quiet HEAD -- && [ "$force_pull" != "true" ]; then
                log_warning "$backend_repo_name has uncommitted changes. Skipping pull to avoid data loss."
                log_info "To force update, use: $0 pull-force"
            else
                if [ "$force_pull" = "true" ]; then
                    log_info "Force pulling $backend_repo_name (will overwrite local changes)..."
                    git fetch origin
                    if git reset --hard "origin/$git_branch" 2>/dev/null; then
                        log_success "$backend_repo_name force updated to latest ($git_branch branch)"
                    elif git reset --hard origin/master 2>/dev/null; then
                        log_success "$backend_repo_name force updated to latest (master branch)"
                    else
                        log_warning "Could not force update $backend_repo_name - using existing code"
                    fi
                else
                    git fetch origin
                    if git pull origin "$git_branch" 2>/dev/null; then
                        log_success "$backend_repo_name updated to latest ($git_branch branch)"
                    elif git pull origin master 2>/dev/null; then
                        log_success "$backend_repo_name updated to latest (master branch)"
                    else
                        log_warning "Could not pull $backend_repo_name - using existing code"
                    fi
                fi
            fi
        else
            log_warning "$backend_repo_name directory exists but is not a git repository"
        fi
        cd "$repos_base_dir"
    else
        log_info "Cloning $backend_repo_name repository..."
        if git clone "$backend_repo_url" "$backend_repo_name"; then
            log_success "$backend_repo_name cloned successfully"
        else
            log_error "Failed to clone $backend_repo_name repository from $backend_repo_url"
            exit 1
        fi
    fi

    # Pull or clone frontend repository
    if [ -d "$frontend_repo_name" ]; then
        log_info "Updating $frontend_repo_name repository..."
        cd "$frontend_repo_name"
        if git status &> /dev/null; then
            # Check if there are uncommitted changes
            if ! git diff-index --quiet HEAD -- && [ "$force_pull" != "true" ]; then
                log_warning "$frontend_repo_name has uncommitted changes. Skipping pull to avoid data loss."
                log_info "To force update, use: $0 pull-force"
            else
                if [ "$force_pull" = "true" ]; then
                    log_info "Force pulling $frontend_repo_name (will overwrite local changes)..."
                    git fetch origin
                    if git reset --hard "origin/$git_branch" 2>/dev/null; then
                        log_success "$frontend_repo_name force updated to latest ($git_branch branch)"
                    elif git reset --hard origin/master 2>/dev/null; then
                        log_success "$frontend_repo_name force updated to latest (master branch)"
                    else
                        log_warning "Could not force update $frontend_repo_name - using existing code"
                    fi
                else
                    git fetch origin
                    if git pull origin "$git_branch" 2>/dev/null; then
                        log_success "$frontend_repo_name updated to latest ($git_branch branch)"
                    elif git pull origin master 2>/dev/null; then
                        log_success "$frontend_repo_name updated to latest (master branch)"
                    else
                        log_warning "Could not pull $frontend_repo_name - using existing code"
                    fi
                fi
            fi
        else
            log_warning "$frontend_repo_name directory exists but is not a git repository"
        fi
        cd "$repos_base_dir"
    else
        log_info "Cloning $frontend_repo_name repository..."
        if git clone "$frontend_repo_url" "$frontend_repo_name"; then
            log_success "$frontend_repo_name cloned successfully"
        else
            log_error "Failed to clone $frontend_repo_name repository from $frontend_repo_url"
            exit 1
        fi
    fi

    log_success "Repository updates completed"
}

build_images() {
    log_info "Building Docker images for ARM64..."

    # Configuration with defaults
    local backend_repo_name="${BACKEND_REPO_NAME:-prs-backend-a}"
    local frontend_repo_name="${FRONTEND_REPO_NAME:-prs-frontend-a}"
    local repos_base_dir="${REPOS_BASE_DIR:-/home/ubuntu/prs-prod}"

    cd "$PROJECT_DIR"

    # Enable BuildKit for better ARM64 support
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1

    # Method 1: Use docker-compose build (recommended - uses docker-compose.yml configuration)
    log_info "Building images using docker-compose (uses Dockerfile.prod as configured)..."
    if docker-compose build --parallel backend frontend; then
        log_success "Docker images built successfully using docker-compose"
        return 0
    else
        log_warning "docker-compose build failed, falling back to direct docker build..."
    fi

    # Method 2: Fallback to direct docker build with explicit Dockerfile.prod
    # Build backend image using Dockerfile.prod
    local backend_path="$repos_base_dir/$backend_repo_name"
    if [ -d "$backend_path" ]; then
        log_info "Building backend image for ARM64 from: $backend_path using Dockerfile.prod"
        docker build --platform linux/arm64 -f "$backend_path/Dockerfile.prod" -t prs-backend:latest "$backend_path"
    else
        log_warning "Backend directory not found: $backend_path. Skipping backend build."
    fi

    # Build frontend image using Dockerfile.prod
    local frontend_path="$repos_base_dir/$frontend_repo_name"
    if [ -d "$frontend_path" ]; then
        log_info "Building frontend image for ARM64 from: $frontend_path using Dockerfile.prod"
        docker build --platform linux/arm64 -f "$frontend_path/Dockerfile.prod" -t prs-frontend:latest "$frontend_path"
    else
        log_warning "Frontend directory not found: $frontend_path. Skipping frontend build."
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
    wait_for_database

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

    # Check if TimescaleDB extension is available and enable it
    log_info "Checking TimescaleDB extension availability..."
    local extension_check=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_available_extensions WHERE name = 'timescaledb');" 2>/dev/null | tr -d ' ')

    if [ "$extension_check" = "t" ]; then
        log_success "TimescaleDB extension is available"

        # Enable TimescaleDB extension
        log_info "Enabling TimescaleDB extension..."
        docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE EXTENSION IF NOT EXISTS timescaledb;" 2>/dev/null || {
            log_warning "Failed to enable TimescaleDB extension, continuing with regular PostgreSQL"
        }
    else
        log_info "TimescaleDB extension not available, using regular PostgreSQL"
    fi

    # Run database migrations using the correct script names from package.json
    log_info "Running database migrations (including TimescaleDB migration if available)..."
    if docker-compose exec -T backend npm run "$migrate_script"; then
        log_success "Database migrations completed"

        # Check if TimescaleDB hypertables were created and setup compression
        if [ "$extension_check" = "t" ]; then
            local hypertable_count=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT COUNT(*) FROM timescaledb_information.hypertables;" 2>/dev/null | tr -d ' ')

            if [ "$hypertable_count" -gt 0 ]; then
                log_success "TimescaleDB setup completed - $hypertable_count hypertables created"

                # Setup compression policies for long-term data growth
                log_info "Setting up compression policies for zero-deletion data growth..."
                if [ -f "$SCRIPT_DIR/timescaledb-maintenance.sh" ]; then
                    "$SCRIPT_DIR/timescaledb-maintenance.sh" setup-compression || {
                        log_warning "Failed to setup compression policies, you can run this manually later"
                    }
                else
                    log_warning "TimescaleDB maintenance script not found, compression policies not set"
                fi
            else
                log_info "No hypertables found - TimescaleDB migration may not have run yet"
            fi
        fi
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

wait_for_database() {
    log_info "Waiting for database to be ready..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker exec prs-ec2-postgres-timescale pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" > /dev/null 2>&1; then
            log_success "Database is ready"
            return 0
        fi

        log_info "Database not ready yet (attempt $attempt/$max_attempts), waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "Database failed to become ready after $max_attempts attempts"
    return 1
}

validate_foreign_keys() {
    log_info "Validating foreign key constraints after import..."

    # Check for common foreign key constraint violations
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        DO \$\$
        DECLARE
            constraint_record RECORD;
            violation_count INTEGER;
        BEGIN
            -- Check all foreign key constraints
            FOR constraint_record IN
                SELECT
                    tc.table_name,
                    tc.constraint_name,
                    kcu.column_name,
                    ccu.table_name AS foreign_table_name,
                    ccu.column_name AS foreign_column_name
                FROM information_schema.table_constraints AS tc
                JOIN information_schema.key_column_usage AS kcu
                    ON tc.constraint_name = kcu.constraint_name
                    AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage AS ccu
                    ON ccu.constraint_name = tc.constraint_name
                    AND ccu.table_schema = tc.table_schema
                WHERE tc.constraint_type = 'FOREIGN KEY'
                    AND tc.table_schema = 'public'
            LOOP
                -- Check for violations
                EXECUTE format('
                    SELECT COUNT(*) FROM %I t1
                    WHERE t1.%I IS NOT NULL
                    AND NOT EXISTS (
                        SELECT 1 FROM %I t2
                        WHERE t2.%I = t1.%I
                    )',
                    constraint_record.table_name,
                    constraint_record.column_name,
                    constraint_record.foreign_table_name,
                    constraint_record.foreign_column_name,
                    constraint_record.column_name
                ) INTO violation_count;

                IF violation_count > 0 THEN
                    RAISE WARNING 'Foreign key constraint violation: % rows in %.% reference non-existent records in %.%',
                        violation_count,
                        constraint_record.table_name,
                        constraint_record.column_name,
                        constraint_record.foreign_table_name,
                        constraint_record.foreign_column_name;
                END IF;
            END LOOP;
        END
        \$\$;
    " 2>/dev/null || true

    log_success "Foreign key validation completed"
}

fix_database_sequences() {
    log_info "Fixing database sequences after import..."

    # First, try a simple approach for common tables
    log_info "Fixing sequences for common tables..."
    local common_tables=("users" "requisitions" "companies" "projects" "departments" "comments" "attachments" "requisition_item_lists" "notifications")

    for table in "${common_tables[@]}"; do
        docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
            DO \$\$
            DECLARE
                max_id INTEGER;
                seq_name TEXT;
            BEGIN
                -- Check if table exists
                IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = '$table') THEN
                    -- Get sequence name
                    SELECT pg_get_serial_sequence('public.$table', 'id') INTO seq_name;

                    IF seq_name IS NOT NULL THEN
                        -- Get max ID
                        EXECUTE format('SELECT COALESCE(MAX(id), 0) FROM %I', '$table') INTO max_id;

                        -- Fix sequence
                        IF max_id > 0 THEN
                            EXECUTE format('SELECT setval(%L, %s)', seq_name, max_id + 1);
                            RAISE NOTICE 'Fixed sequence for table $table - set to %', max_id + 1;
                        END IF;
                    END IF;
                END IF;
            END
            \$\$;
        " 2>/dev/null || true
    done

    # Then run a simple sequence fix for any remaining sequences
    log_info "Running final sequence check..."

    # Simple approach: just fix sequences that actually exist
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        DO \$\$
        DECLARE
            seq_record RECORD;
            max_id INTEGER;
        BEGIN
            -- Get all sequences in the public schema
            FOR seq_record IN
                SELECT schemaname, sequencename
                FROM pg_sequences
                WHERE schemaname = 'public'
            LOOP
                -- Try to find the associated table and fix the sequence
                BEGIN
                    -- Extract table name from sequence name (remove _id_seq suffix)
                    DECLARE
                        table_name TEXT := regexp_replace(seq_record.sequencename, '_id_seq$', '');
                    BEGIN
                        -- Check if table exists and get max id
                        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = table_name AND table_schema = 'public') THEN
                            EXECUTE format('SELECT COALESCE(MAX(id), 0) FROM %I', table_name) INTO max_id;

                            IF max_id > 0 THEN
                                EXECUTE format('SELECT setval(%L, %s)', seq_record.schemaname||'.'||seq_record.sequencename, max_id + 1);
                                RAISE NOTICE 'Fixed sequence % for table % - set to %', seq_record.sequencename, table_name, max_id + 1;
                            END IF;
                        END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                            -- Skip this sequence if there's any error
                            CONTINUE;
                    END;
                END;
            END LOOP;
        END
        \$\$;
    " 2>/dev/null || true

    log_success "Database sequences processing completed"
}

import_database() {
    local sql_file="$1"

    if [ -z "$sql_file" ]; then
        log_error "Please provide a SQL file path"
        log_info "Usage: $0 import-db <path-to-sql-file>"
        log_info "Example: $0 import-db dump.sql"
        exit 1
    fi

    if [ ! -f "$sql_file" ]; then
        log_error "SQL file not found: $sql_file"
        exit 1
    fi

    log_info "Importing database from: $sql_file"

    # Check if database container is running
    cd "$PROJECT_DIR"
    if ! docker-compose ps postgres | grep -q "Up"; then
        log_error "PostgreSQL container is not running. Please start services first."
        exit 1
    fi

    # Wait for database to be ready
    wait_for_database

    # Clean and recreate the database to ensure fresh import
    log_info "Cleaning database before import..."
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS \"${POSTGRES_DB}\";"
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE \"${POSTGRES_DB}\";"

    # Import the SQL file with improved error handling
    log_info "Importing SQL dump with foreign key constraint handling..."

    # Create a temporary SQL file with constraint handling
    local temp_sql_file="/tmp/import_with_constraints.sql"

    # Prepare the import with constraint handling
    cat > "$temp_sql_file" << 'EOF'
-- Disable foreign key checks during import
SET session_replication_role = replica;

-- Set client encoding and other settings
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Import the actual dump
\i DUMP_FILE_PATH

-- Re-enable foreign key checks
SET session_replication_role = DEFAULT;

-- Analyze tables for better performance
ANALYZE;
EOF

    # Replace the placeholder with actual file path (inside container)
    sed -i.bak "s|DUMP_FILE_PATH|/tmp/dump.sql|g" "$temp_sql_file"

    # Copy the temp file to container and execute
    if docker cp "$temp_sql_file" prs-ec2-postgres-timescale:/tmp/import_with_constraints.sql && \
       docker cp "$sql_file" prs-ec2-postgres-timescale:/tmp/dump.sql && \
       docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -f /tmp/import_with_constraints.sql; then

        log_info "Database import completed, fixing sequences and validating constraints..."
        fix_database_sequences
        validate_foreign_keys

        # Clean up temporary files
        rm -f "$temp_sql_file" "$temp_sql_file.bak"
        docker exec prs-ec2-postgres-timescale rm -f /tmp/import_with_constraints.sql /tmp/dump.sql

        log_success "Database import, sequence fix, and validation completed successfully"
        log_info "You can now access the application with the imported data"
    else
        log_error "Database import failed"
        log_info "Trying alternative import method without constraint handling..."

        # Fallback to original method
        if docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" < "$sql_file"; then
            log_info "Fallback import succeeded, fixing sequences and validating constraints..."
            fix_database_sequences
            validate_foreign_keys
            log_success "Database import, sequence fix, and validation completed successfully"
        else
            log_error "Both import methods failed"
            log_info "Check the SQL file format and database connection"
            exit 1
        fi

        # Clean up temporary files
        rm -f "$temp_sql_file" "$temp_sql_file.bak"
        docker exec prs-ec2-postgres-timescale rm -f /tmp/import_with_constraints.sql /tmp/dump.sql 2>/dev/null || true
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

clean_database() {
    log_warning "This will completely clean the database. All data will be lost. Continue? (y/N)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Cleaning database..."

        cd "$PROJECT_DIR"
        if ! docker-compose ps postgres | grep -q "Up"; then
            log_error "PostgreSQL container is not running. Please start services first."
            exit 1
        fi

        # Wait for database to be ready
        wait_for_database

        # Drop and recreate database
        log_info "Dropping and recreating database..."
        docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS \"${POSTGRES_DB}\";"
        docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE \"${POSTGRES_DB}\";"

        log_success "Database cleaned successfully"
        log_info "You can now run 'init-db' or 'import-db' to set up the database"
    else
        log_info "Database clean cancelled"
    fi
}

# ============================================================================
# TIMESCALEDB MANAGEMENT FUNCTIONS
# ============================================================================



timescaledb_status() {
    log_info "Checking TimescaleDB status..."

    # Wait for database to be ready
    wait_for_database

    # Check if TimescaleDB extension is enabled
    log_info "TimescaleDB Extension Status:"
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            CASE
                WHEN EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'timescaledb')
                THEN '✅ TimescaleDB extension is ENABLED'
                ELSE '❌ TimescaleDB extension is NOT enabled'
            END as extension_status;
    " 2>/dev/null || {
        log_error "Failed to check TimescaleDB extension status"
        return 1
    }

    # Show TimescaleDB version if available
    log_info "TimescaleDB Version:"
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            CASE
                WHEN EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'timescaledb')
                THEN (SELECT extversion FROM pg_extension WHERE extname = 'timescaledb')
                ELSE 'Extension not enabled'
            END as timescaledb_version;
    " 2>/dev/null || true

    # Show hypertables if any exist
    log_info "Hypertables Status:"
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            CASE
                WHEN EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'timescaledb')
                THEN (
                    SELECT COALESCE(
                        (SELECT COUNT(*)::text || ' hypertables found'
                         FROM timescaledb_information.hypertables),
                        'No hypertables found'
                    )
                )
                ELSE 'TimescaleDB extension not enabled'
            END as hypertables_status;
    " 2>/dev/null || true

    # Show detailed hypertable information if available
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            hypertable_name,
            num_chunks,
            pg_size_pretty(pg_total_relation_size('public.' || hypertable_name)) as table_size
        FROM timescaledb_information.hypertables
        ORDER BY hypertable_name;
    " 2>/dev/null || true

    log_success "TimescaleDB status check completed"
}

timescaledb_backup() {
    log_info "Creating TimescaleDB backup..."

    # Create backup directory
    local backup_dir="$PROJECT_DIR/backups"
    mkdir -p "$backup_dir"

    # Generate backup filename with timestamp
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/timescaledb_backup_${timestamp}.dump"
    local sql_backup_file="$backup_dir/timescaledb_backup_${timestamp}.sql"

    # Wait for database to be ready
    wait_for_database

    # Create binary backup (custom format)
    log_info "Creating binary backup (custom format)..."
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_dump \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        -Fc \
        -f "/tmp/backup.dump" 2>/dev/null || {
        log_error "Failed to create binary backup"
        return 1
    }

    # Copy backup from container
    docker cp prs-ec2-postgres-timescale:/tmp/backup.dump "$backup_file"
    docker exec prs-ec2-postgres-timescale rm -f /tmp/backup.dump

    # Create SQL backup
    log_info "Creating SQL backup..."
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_dump \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        -f "/tmp/backup.sql" 2>/dev/null || {
        log_error "Failed to create SQL backup"
        return 1
    }

    # Copy SQL backup from container
    docker cp prs-ec2-postgres-timescale:/tmp/backup.sql "$sql_backup_file"
    docker exec prs-ec2-postgres-timescale rm -f /tmp/backup.sql

    # Show backup information
    log_success "TimescaleDB backup completed:"
    log_info "  Binary backup: $backup_file ($(du -h "$backup_file" | cut -f1))"
    log_info "  SQL backup: $sql_backup_file ($(du -h "$sql_backup_file" | cut -f1))"
    log_info "  Backup directory: $backup_dir"
}

timescaledb_optimize() {
    log_info "Running TimescaleDB optimization tasks..."

    # Wait for database to be ready
    wait_for_database

    # Check if TimescaleDB is enabled
    local extension_check=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'timescaledb');" 2>/dev/null | tr -d ' ')

    if [ "$extension_check" != "t" ]; then
        log_error "TimescaleDB extension is not enabled"
        return 1
    fi

    # Run VACUUM and ANALYZE on hypertables
    log_info "Running VACUUM and ANALYZE on hypertables..."
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        DO \$\$
        DECLARE
            ht_name text;
        BEGIN
            FOR ht_name IN
                SELECT hypertable_name FROM timescaledb_information.hypertables
            LOOP
                RAISE NOTICE 'Optimizing hypertable: %', ht_name;
                EXECUTE 'VACUUM ANALYZE ' || quote_ident(ht_name);
            END LOOP;
        END \$\$;
    " 2>/dev/null || {
        log_error "Failed to optimize hypertables"
        return 1
    }

    # Update table statistics
    log_info "Updating table statistics..."
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "ANALYZE;" 2>/dev/null || true

    log_success "TimescaleDB optimization completed"
}

show_help() {
    echo "PRS EC2 Graviton Deployment Script"
    echo "Optimized for t4g.medium (2 cores, 4GB memory, ARM64)"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy              Full deployment (pull, build, start, init/import)"
    echo "  start               Start services"
    echo "  stop                Stop services"
    echo "  restart             Restart services"
    echo "  status              Show service status and resource usage"
    echo "  logs [service]      Show logs"
    echo "  pull                Pull latest code from configured repositories (safe)"
    echo "  pull-force          Force pull code (overwrites local changes)"
    echo "  build               Build Docker images for ARM64"
    echo "  init-db             Initialize database (includes TimescaleDB setup)"
    echo "  import-db <file>    Import SQL dump file with enhanced constraint handling"
    echo "  import-db-safe <file> Import SQL dump using safe import script"
    echo "  clean-db            Clean database (drop and recreate)"
    echo "  fix-sequences       Fix database sequences after manual import"
    echo "  validate-fk         Validate foreign key constraints"
    echo "  ssl-setup           Setup internal SSL certificates"
    echo "  optimize            Optimize system for 4GB memory"
    echo "  validate            Validate configuration before deployment"
    echo "  troubleshoot        Troubleshoot Cloudflare Tunnel issues"
    echo "  monitor             Monitor system resources"
    echo "  help                Show this help"
    echo ""
    echo "Database Management Examples:"
    echo "  $0 import-db dump.sql           # Import SQL dump with enhanced handling"
    echo "  $0 clean-db                     # Clean database if import issues occur"
    echo "  $0 fix-sequences                # Fix database sequences if getting ID conflicts"
    echo "  $0 validate-fk                  # Check for foreign key constraint violations"
    echo ""
    echo "TimescaleDB Management:"
    echo "  $0 init-db                      # Initialize database (includes TimescaleDB + compression)"
    echo "  $0 timescaledb-status           # Show TimescaleDB status and hypertables"
    echo "  $0 timescaledb-backup           # Create TimescaleDB backup (binary + SQL)"
    echo "  $0 timescaledb-optimize         # Optimize TimescaleDB performance"
    echo "  $0 timescaledb-compression      # Setup compression policies for long-term growth"
    echo "  $0 timescaledb-maintenance [cmd] # Advanced maintenance (setup-compression, compress, optimize, status, storage, full-maintenance)"
    echo ""
    echo "Repository Configuration (via .env file):"
    echo "  REPOS_BASE_DIR      Base directory for repositories (default: /home/ubuntu/prs-prod)"
    echo "  BACKEND_REPO_NAME   Backend repository directory name (default: prs-backend-a)"
    echo "  FRONTEND_REPO_NAME  Frontend repository directory name (default: prs-frontend-a)"
    echo "  BACKEND_REPO_URL    Backend repository URL for cloning"
    echo "  FRONTEND_REPO_URL   Frontend repository URL for cloning"
    echo "  GIT_BRANCH          Git branch to use (default: main)"
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

        # Validate SSL configuration after setup
        log_info "Validating SSL configuration..."
        if ! "$SCRIPT_DIR/validate-ssl-config.sh"; then
            log_error "SSL validation failed. Please check configuration."
            exit 1
        fi

        pull_repositories false
        build_images
        start_services
        sleep 20

        # Auto-import database if dump file exists, then run init-db
        # Use safe import method to handle foreign key constraints properly
        # if [ -f "dump_file_fixed_lineendings.sql" ]; then
        #     log_info "Found database dump file - using safe import method"
        #     if [ -f "./scripts/import-database-safe.sh" ]; then
        #         POSTGRES_PASSWORD="$POSTGRES_PASSWORD" "$SCRIPT_DIR/import-database-safe.sh" "dump_file_fixed_lineendings.sql"
        #     else
        #         log_warning "Safe import script not found, using basic import"
        #         import_database "dump_file_fixed_lineendings.sql"
        #     fi
        #     # Run init-db after import to handle any schema updates
        #     init_database
        # elif [ -f "dump_file_20250526.sql" ]; then
        #     log_info "Found database dump file - using safe import method"
        #     if [ -f "./scripts/import-database-safe.sh" ]; then
        #         POSTGRES_PASSWORD="$POSTGRES_PASSWORD" "$SCRIPT_DIR/import-database-safe.sh" "dump_file_20250526.sql"
        #     else
        #         log_warning "Safe import script not found, using basic import"
        #         import_database "dump_file_20250526.sql"
        #     fi
        #     # Run init-db after import to handle any schema updates
        #     init_database
        # elif [ -f "dump.sql" ]; then
        #     log_info "Found database dump file - using safe import method"
        #     if [ -f "./scripts/import-database-safe.sh" ]; then
        #         POSTGRES_PASSWORD="$POSTGRES_PASSWORD" "$SCRIPT_DIR/import-database-safe.sh" "dump.sql"
        #     else
        #         log_warning "Safe import script not found, using basic import"
        #         import_database "dump.sql"
        #     fi
        #     # Run init-db after import to handle any schema updates
        #     init_database
        # else
        #     init_database
        # fi

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
    "pull")
        load_environment
        pull_repositories false
        ;;
    "pull-force")
        load_environment
        pull_repositories true
        ;;
    "build")
        check_prerequisites
        load_environment
        pull_repositories false
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
    "import-db-safe")
        load_environment
        POSTGRES_PASSWORD="$POSTGRES_PASSWORD" "$SCRIPT_DIR/import-database-safe.sh" "$2"
        ;;
    "clean-db")
        load_environment
        clean_database
        ;;
    "fix-sequences")
        load_environment
        cd "$PROJECT_DIR"
        if ! docker-compose ps postgres | grep -q "Up"; then
            log_error "PostgreSQL container is not running. Please start services first."
            exit 1
        fi
        wait_for_database
        fix_database_sequences
        ;;
    "validate-fk")
        load_environment
        cd "$PROJECT_DIR"
        if ! docker-compose ps postgres | grep -q "Up"; then
            log_error "PostgreSQL container is not running. Please start services first."
            exit 1
        fi
        wait_for_database
        validate_foreign_keys
        ;;
    "create-dump")
        load_environment
        if [ -f "./scripts/create-database-dump.sh" ]; then
            ./scripts/create-database-dump.sh "$2" "$3"
        else
            log_error "Database dump script not found: ./scripts/create-database-dump.sh"
            exit 1
        fi
        ;;
    "ssl-setup")
        load_environment
        setup_ssl_certificates
        ;;
    "ssl-validate")
        load_environment
        "$SCRIPT_DIR/validate-ssl-config.sh"
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
    "timescaledb-status")
        load_environment
        timescaledb_status
        ;;
    "timescaledb-backup")
        load_environment
        timescaledb_backup
        ;;
    "timescaledb-optimize")
        load_environment
        timescaledb_optimize
        ;;
    "timescaledb-maintenance")
        load_environment
        if [ -f "$SCRIPT_DIR/timescaledb-maintenance.sh" ]; then
            "$SCRIPT_DIR/timescaledb-maintenance.sh" "${2:-help}"
        else
            log_error "TimescaleDB maintenance script not found"
            exit 1
        fi
        ;;
    "timescaledb-compression")
        load_environment
        if [ -f "$SCRIPT_DIR/timescaledb-maintenance.sh" ]; then
            "$SCRIPT_DIR/timescaledb-maintenance.sh" setup-compression
        else
            log_error "TimescaleDB maintenance script not found"
            exit 1
        fi
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
