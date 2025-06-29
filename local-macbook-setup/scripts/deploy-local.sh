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
    log_info "Building Docker images for development..."

    cd "$PROJECT_DIR"

    # Build development images using docker-compose
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml build

    log_success "Docker development images built"
}

start_services() {
    log_info "Starting PRS local development environment with hot reload..."

    cd "$PROJECT_DIR"

    # Start core services with development configuration
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d nginx backend frontend postgres portainer adminer

    # Start monitoring services if enabled
    if [ "${PROMETHEUS_ENABLED:-true}" = "true" ] || [ "${GRAFANA_ENABLED:-true}" = "true" ]; then
        log_info "Starting monitoring services..."
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile monitoring up -d
    fi

    log_success "Services started with hot reload enabled"
}

stop_services() {
    log_info "Stopping PRS local development environment..."

    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

    log_success "Services stopped"
}

show_status() {
    log_info "Service status:"

    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps

    echo ""
    log_info "Access URLs:"
    echo "  Main Application: https://localhost:$HTTPS_PORT"
    echo "  Backend API:      https://localhost:$HTTPS_PORT/api"
    echo "  Portainer:        https://localhost:$HTTPS_PORT/portainer"
    echo "  Adminer:          https://localhost:$HTTPS_PORT/adminer"
    echo "  Grafana:          https://localhost:$HTTPS_PORT/grafana"
    echo "  Health Check:     https://localhost:$HTTPS_PORT/health"
    echo ""
    log_info "Development Features:"
    echo "  ✅ Backend Hot Reload:  Enabled (nodemon)"
    echo "  ✅ Frontend Hot Reload: Enabled (Vite HMR)"
    echo "  📁 Source Code:         Mounted for live editing"
}

show_logs() {
    cd "$PROJECT_DIR"

    if [ -n "$2" ]; then
        log_info "Showing logs for service: $2"
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f "$2"
    else
        log_info "Showing logs for all services"
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f
    fi
}

rebuild_services() {
    log_info "Rebuilding services with development configuration..."

    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
    build_images
    start_services

    log_success "Services rebuilt and restarted with hot reload"
}

reset_environment() {
    log_warning "This will remove all containers, volumes, and data. Are you sure? (y/N)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Resetting local environment..."

        cd "$PROJECT_DIR"
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v --remove-orphans
        docker system prune -f

        # Remove SSL certificates
        rm -rf "$PROJECT_DIR/ssl"

        log_success "Environment reset complete"
    else
        log_info "Reset cancelled"
    fi
}

wait_for_database() {
    log_info "Waiting for database to be ready..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker exec prs-local-postgres-timescale pg_isready -U "${POSTGRES_USER:-prs_user}" -d "${POSTGRES_DB:-prs_local}" > /dev/null 2>&1; then
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
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d "${POSTGRES_DB:-prs_local}" -c "
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
        docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d "${POSTGRES_DB:-prs_local}" -c "
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
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d "${POSTGRES_DB:-prs_local}" -c "
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

init_database() {
    log_info "Initializing database..."

    # Wait for database to be ready
    wait_for_database

    # Run database migrations (includes TimescaleDB setup)
    log_info "Running database migrations (includes TimescaleDB setup)..."
    cd "$PROJECT_DIR"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec backend npm run migrate:dev || true
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec backend npm run seed:dev || true

    log_success "Database initialized with TimescaleDB support"
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
    if ! docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps postgres | grep -q "Up"; then
        log_error "PostgreSQL container is not running. Please start services first."
        log_info "Run: $0 start"
        exit 1
    fi

    # Wait for database to be ready
    wait_for_database

    # Clean and recreate the database to ensure fresh import
    log_info "Cleaning database before import..."
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d postgres -c "DROP DATABASE IF EXISTS \"${POSTGRES_DB:-prs_local}\";"
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d postgres -c "CREATE DATABASE \"${POSTGRES_DB:-prs_local}\";"

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
    if docker cp "$temp_sql_file" prs-local-postgres-timescale:/tmp/import_with_constraints.sql && \
       docker cp "$sql_file" prs-local-postgres-timescale:/tmp/dump.sql && \
       docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d "${POSTGRES_DB:-prs_local}" -f /tmp/import_with_constraints.sql; then

        log_info "Database import completed, fixing sequences and validating constraints..."
        fix_database_sequences
        validate_foreign_keys

        # Clean up temporary files
        rm -f "$temp_sql_file" "$temp_sql_file.bak"
        docker exec prs-local-postgres-timescale rm -f /tmp/import_with_constraints.sql /tmp/dump.sql

        log_success "Database import, sequence fix, and validation completed successfully"
        log_info "You can now access the application with the imported data"
    else
        log_error "Database import failed"
        log_info "Trying alternative import method without constraint handling..."

        # Fallback to original method
        if docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d "${POSTGRES_DB:-prs_local}" < "$sql_file"; then
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
        docker exec prs-local-postgres-timescale rm -f /tmp/import_with_constraints.sql /tmp/dump.sql 2>/dev/null || true
    fi
}

clean_database() {
    log_warning "This will completely clean the database. All data will be lost. Continue? (y/N)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Cleaning database..."

        cd "$PROJECT_DIR"
        if ! docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps postgres | grep -q "Up"; then
            log_error "PostgreSQL container is not running. Please start services first."
            log_info "Run: $0 start"
            exit 1
        fi

        # Wait for database to be ready
        wait_for_database

        # Drop and recreate database
        log_info "Dropping and recreating database..."
        docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d postgres -c "DROP DATABASE IF EXISTS \"${POSTGRES_DB:-prs_local}\";"
        docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-localdev123}" prs-local-postgres-timescale psql -U "${POSTGRES_USER:-prs_user}" -d postgres -c "CREATE DATABASE \"${POSTGRES_DB:-prs_local}\";"

        log_success "Database cleaned successfully"
        log_info "You can now run 'init-db' or 'import-db' to set up the database"
    else
        log_info "Database clean cancelled"
    fi
}

show_help() {
    echo "PRS Cross-Platform Local Development Script with Hot Reload"
    echo "Compatible with Linux, macOS, and Windows (WSL/Git Bash)"
    echo ""
    echo "🔥 HOT RELOAD FEATURES:"
    echo "  ✅ Backend:  Automatic restart on code changes (nodemon)"
    echo "  ✅ Frontend: Live reload with Vite HMR"
    echo "  📁 Source:   Code mounted for instant development"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy              Full deployment with hot reload (build, start, init/import)"
    echo "  redeploy            Reset and redeploy with fresh database import"
    echo "  start               Start services with hot reload enabled"
    echo "  stop                Stop services"
    echo "  restart             Restart services"
    echo "  status              Show service status and hot reload info"
    echo "  logs [service]      Show logs (optionally for specific service)"
    echo "  build               Build Docker development images"
    echo "  rebuild             Rebuild and restart services with hot reload"
    echo "  refresh-frontend    Quick frontend refresh (rebuild & restart)"
    echo "  reset               Reset entire environment (removes all data)"
    echo "  ssl-reset           Regenerate SSL certificates"
    echo "  init-db             Initialize database"
    echo "  import-db <file>    Import SQL dump file into database"
    echo "  clean-db            Clean database (drop and recreate)"
    echo "  fix-sequences       Fix database sequences after manual import"
    echo "  validate-fk         Validate foreign key constraints"

    echo "  help                Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 deploy                        # Full deployment with hot reload"
    echo "  $0 redeploy                      # Reset and redeploy with fresh import"
    echo "  $0 logs backend                  # Show backend logs (watch for changes)"
    echo "  $0 status                        # Show service status and hot reload info"
    echo "  $0 import-db dump.sql            # Import SQL dump manually"
    echo "  $0 clean-db                      # Clean database if import issues occur"
    echo "  $0 fix-sequences                 # Fix database sequences if getting ID conflicts"
    echo "  $0 validate-fk                   # Check for foreign key constraint violations"
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
      #   sleep 15

      #   # Check if dump file exists and import it before init
      #  if [ -f "dump.sql" ]; then
      #       log_info "Found dump.sql"
      #       log_info "Importing database dump before initialization..."
      #       import_database "dump.sql"
      #       log_info "Database dump imported successfully"
      #   else
      #       log_info "No dump file found, running standard database initialization..."
      #       init_database
      #   fi

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
            docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v --remove-orphans

            # Additional cleanup to ensure fresh start
            log_info "Performing additional cleanup..."
            docker system prune -f --volumes

            # Remove SSL certificates to regenerate
            rm -rf "$PROJECT_DIR/ssl"

            # Full deployment
            check_ports
            generate_ssl_certificates
            build_images
            start_services

            # Wait longer for database to be fully ready
            log_info "Waiting for database to be fully ready..."
            # sleep 30

            # # Import database if dump file exists
            # if [ -f "dump.sql" ]; then
            #     log_info "Found dump.sql"
            #     log_info "Importing database dump..."
            #     import_database "dump.sql"
            #     log_info "Database dump imported successfully"
            # else
            #     log_info "No dump file found, running standard database initialization..."
            #     init_database
            # fi

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
    "refresh-frontend")
        if [ -f "./scripts/refresh-frontend.sh" ]; then
            ./scripts/refresh-frontend.sh
        else
            log_error "Frontend refresh script not found: ./scripts/refresh-frontend.sh"
            exit 1
        fi
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
    "clean-db")
        load_environment
        clean_database
        ;;
    "fix-sequences")
        load_environment
        cd "$PROJECT_DIR"
        if ! docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps postgres | grep -q "Up"; then
            log_error "PostgreSQL container is not running. Please start services first."
            log_info "Run: $0 start"
            exit 1
        fi
        wait_for_database
        fix_database_sequences
        ;;
    "validate-fk")
        load_environment
        cd "$PROJECT_DIR"
        if ! docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps postgres | grep -q "Up"; then
            log_error "PostgreSQL container is not running. Please start services first."
            log_info "Run: $0 start"
            exit 1
        fi
        wait_for_database
        validate_foreign_keys
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
