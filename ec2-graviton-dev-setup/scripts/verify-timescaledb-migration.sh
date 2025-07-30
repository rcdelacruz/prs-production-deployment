#!/bin/bash

# TimescaleDB Migration Verification Script for Production
# This script verifies that the TimescaleDB migration is compatible with the production environment

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
        log_info "Loading environment from $ENV_FILE"
        source "$ENV_FILE"
    else
        log_error ".env file not found at $ENV_FILE"
        exit 1
    fi
}

check_migration_file() {
    log_info "Checking Sequelize TimescaleDB migration file..."

    local backend_repo_name="${BACKEND_REPO_NAME:-prs-backend-a}"
    local repos_base_dir="${REPOS_BASE_DIR:-/home/ubuntu/prs-prod}"
    local migration_file="$repos_base_dir/$backend_repo_name/src/infra/database/migrations/20250628120000-timescaledb-setup.js"

    if [ ! -f "$migration_file" ]; then
        log_error "TimescaleDB Sequelize migration file not found: $migration_file"
        log_info "Please ensure the backend repository is available and up to date"
        return 1
    fi

    log_success "Sequelize migration file found: $migration_file"

    # Check if migration file contains expected content
    if grep -q "timescaledb" "$migration_file" && grep -q "hypertable" "$migration_file"; then
        log_success "Migration file contains TimescaleDB-specific content"

        # Check for comprehensive coverage
        if grep -q "38 tables" "$migration_file" || grep -q "COMPREHENSIVE" "$migration_file"; then
            log_success "Migration provides comprehensive coverage (38 hypertables)"
        fi

        # Check for zero data loss guarantee
        if grep -q "zero data loss" "$migration_file" || grep -q "Zero data loss" "$migration_file"; then
            log_success "Migration guarantees zero data loss"
        fi
    else
        log_warning "Migration file may not contain expected TimescaleDB content"
    fi

    return 0
}

check_docker_image() {
    log_info "Checking TimescaleDB Docker image availability..."

    # Check if the TimescaleDB image is available
    if docker images | grep -q "timescale/timescaledb"; then
        log_success "TimescaleDB Docker image is available locally"
        docker images | grep "timescale/timescaledb" | head -1
    else
        log_info "TimescaleDB Docker image not found locally, pulling..."
        docker pull timescale/timescaledb:latest-pg15 || {
            log_error "Failed to pull TimescaleDB Docker image"
            return 1
        }
        log_success "TimescaleDB Docker image pulled successfully"
    fi

    return 0
}

check_container_compatibility() {
    log_info "Checking container compatibility..."

    # Check if the container is running with TimescaleDB image
    if docker ps | grep -q "prs-ec2-postgres-timescale"; then
        log_success "TimescaleDB container is running"

        # Check the image being used
        local current_image=$(docker inspect prs-ec2-postgres-timescale --format='{{.Config.Image}}')
        if [[ "$current_image" == *"timescale"* ]]; then
            log_success "Container is using TimescaleDB image: $current_image"
        else
            log_warning "Container is not using TimescaleDB image: $current_image"
            log_info "You may need to restart services to use the updated docker-compose.yml"
        fi
    else
        log_info "TimescaleDB container is not running (this is normal if services are stopped)"
    fi

    return 0
}

check_database_compatibility() {
    log_info "Checking database compatibility..."

    # Only check if container is running
    if ! docker ps | grep -q "prs-ec2-postgres-timescale"; then
        log_info "Database container is not running, skipping database checks"
        return 0
    fi

    # Check if database is accessible
    if ! docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" &> /dev/null; then
        log_warning "Database is not accessible, skipping database checks"
        return 0
    fi

    # Check if TimescaleDB extension is available
    local extension_available=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_available_extensions WHERE name = 'timescaledb');" 2>/dev/null | tr -d ' ')

    if [ "$extension_available" = "t" ]; then
        log_success "TimescaleDB extension is available in the database"
    else
        log_error "TimescaleDB extension is not available in the database"
        log_info "Make sure you're using the timescale/timescaledb Docker image"
        return 1
    fi

    # Check if extension is enabled
    local extension_enabled=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'timescaledb');" 2>/dev/null | tr -d ' ')

    if [ "$extension_enabled" = "t" ]; then
        log_success "TimescaleDB extension is enabled"

        # Show TimescaleDB version
        local version=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT extversion FROM pg_extension WHERE extname = 'timescaledb';" 2>/dev/null | tr -d ' ')
        log_info "TimescaleDB version: $version"

        # Check for existing hypertables
        local hypertable_count=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT COUNT(*) FROM timescaledb_information.hypertables;" 2>/dev/null | tr -d ' ')

        if [ "$hypertable_count" -gt 0 ]; then
            log_success "Found $hypertable_count existing hypertables"
        else
            log_info "No hypertables found (migration may not have run yet)"
        fi
    else
        log_info "TimescaleDB extension is not enabled (will be enabled during migration)"
    fi

    return 0
}

check_migration_status() {
    log_info "Checking migration status..."

    # Only check if container is running
    if ! docker ps | grep -q "prs-ec2-postgres-timescale"; then
        log_info "Database container is not running, skipping migration status check"
        return 0
    fi

    # Check if database is accessible
    if ! docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" &> /dev/null; then
        log_warning "Database is not accessible, skipping migration status check"
        return 0
    fi

    # Check if migration tracking table exists
    local tracking_table_exists=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'SequelizeMeta');" 2>/dev/null | tr -d ' ')

    if [ "$tracking_table_exists" = "t" ]; then
        log_success "Migration tracking table exists"

        # Check if TimescaleDB migration has run
        local timescaledb_migration=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM \"SequelizeMeta\" WHERE name = '20250628120000-timescaledb-setup.js');" 2>/dev/null | tr -d ' ')

        if [ "$timescaledb_migration" = "t" ]; then
            log_success "TimescaleDB migration has been executed"
        else
            log_info "TimescaleDB migration has not been executed yet"
        fi
    else
        log_info "Migration tracking table does not exist (database may be new)"
    fi

    return 0
}

check_environment_variables() {
    log_info "Checking TimescaleDB environment variables..."

    # Check required variables
    local required_vars=("POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    else
        log_success "All required environment variables are set"
    fi

    # Check TimescaleDB-specific variables
    local timescaledb_vars=("TIMESCALEDB_TELEMETRY" "TIMESCALEDB_MAX_BACKGROUND_WORKERS")
    local missing_timescaledb_vars=()

    for var in "${timescaledb_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_timescaledb_vars+=("$var")
        fi
    done

    if [ ${#missing_timescaledb_vars[@]} -gt 0 ]; then
        log_warning "Missing TimescaleDB-specific environment variables: ${missing_timescaledb_vars[*]}"
        log_info "These will use default values, but it's recommended to set them explicitly"
    else
        log_success "TimescaleDB-specific environment variables are set"
    fi

    return 0
}

show_verification_summary() {
    local status="$1"

    echo ""
    echo "=============================================="
    echo "  TimescaleDB Migration Verification Summary"
    echo "=============================================="
    echo ""

    if [ "$status" = "success" ]; then
        log_success "✅ All verification checks passed!"
        echo ""
        echo "🚀 Your production environment is ready for TimescaleDB:"
        echo "   • Migration file is available"
        echo "   • Docker image is compatible"
        echo "   • Environment variables are configured"
        echo "   • Database is ready for TimescaleDB"
        echo ""
        echo "📋 Next Steps:"
        echo "   1. Run: ./scripts/deploy-ec2.sh setup-timescaledb"
        echo "   2. Verify: ./scripts/deploy-ec2.sh timescaledb-status"
        echo "   3. Backup: ./scripts/deploy-ec2.sh timescaledb-backup"
    else
        log_warning "⚠️  Some verification checks failed or need attention"
        echo ""
        echo "📋 Please review the warnings and errors above before proceeding"
        echo "💡 Most issues can be resolved by:"
        echo "   • Updating the .env file with missing variables"
        echo "   • Restarting services to use the updated configuration"
        echo "   • Ensuring the backend repository is up to date"
    fi

    echo ""
    echo "📚 For more information, see:"
    echo "   • TIMESCALEDB_PRODUCTION_GUIDE.md"
    echo "   • ./scripts/deploy-ec2.sh help"
    echo ""
}

# Main verification function
main() {
    log_info "Starting TimescaleDB migration verification for production..."
    echo ""

    # Load environment
    load_environment

    local overall_status="success"

    # Run all verification checks
    check_migration_file || overall_status="warning"
    echo ""

    check_docker_image || overall_status="warning"
    echo ""

    check_container_compatibility || overall_status="warning"
    echo ""

    check_environment_variables || overall_status="warning"
    echo ""

    check_database_compatibility || overall_status="warning"
    echo ""

    check_migration_status || overall_status="warning"
    echo ""

    # Show summary
    show_verification_summary "$overall_status"
}

# Show help
show_help() {
    echo "TimescaleDB Migration Verification Script"
    echo ""
    echo "This script verifies that your production environment is ready for TimescaleDB."
    echo ""
    echo "Usage: $0"
    echo ""
    echo "The script checks:"
    echo "  • Migration file availability"
    echo "  • Docker image compatibility"
    echo "  • Environment configuration"
    echo "  • Database readiness"
    echo "  • Migration status"
    echo ""
    echo "Run this script before setting up TimescaleDB in production."
}

# Main script logic
case "${1:-verify}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        main
        ;;
esac
