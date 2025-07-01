#!/bin/bash

# TimescaleDB Production Backup Script for EC2 Graviton
# Optimized for production environment with comprehensive backup strategies
# This script creates multiple backup formats for maximum recovery options

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

check_prerequisites() {
    log_info "Checking prerequisites for TimescaleDB backup..."
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        exit 1
    fi
    
    # Check if TimescaleDB container is running
    if ! docker ps | grep -q "prs-ec2-postgres-timescale"; then
        log_error "TimescaleDB container is not running"
        log_info "Start services first: ./deploy-ec2.sh start"
        exit 1
    fi
    
    # Check if database is accessible
    if ! docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" &> /dev/null; then
        log_error "Database is not accessible"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

create_backup_directory() {
    local backup_dir="$PROJECT_DIR/backups"
    mkdir -p "$backup_dir"
    
    # Create subdirectories for organization
    mkdir -p "$backup_dir/daily"
    mkdir -p "$backup_dir/weekly"
    mkdir -p "$backup_dir/monthly"
    
    log_info "Backup directory ready: $backup_dir"
    echo "$backup_dir"
}

create_pre_backup_info() {
    local backup_dir="$1"
    local timestamp="$2"
    local info_file="$backup_dir/backup_info_${timestamp}.txt"
    
    log_info "Creating backup information file..."
    
    cat > "$info_file" << EOF
# TimescaleDB Production Backup Information
# Generated: $(date)
# Environment: Production (EC2 Graviton)

## System Information
Hostname: $(hostname)
Architecture: $(uname -m)
Kernel: $(uname -r)
Docker Version: $(docker --version)

## Database Information
Database: ${POSTGRES_DB}
User: ${POSTGRES_USER}
Container: prs-ec2-postgres-timescale

## TimescaleDB Status
EOF
    
    # Add TimescaleDB version and hypertables info
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT 'TimescaleDB Version: ' || extversion 
        FROM pg_extension WHERE extname = 'timescaledb';
    " -t >> "$info_file" 2>/dev/null || echo "TimescaleDB extension not found" >> "$info_file"
    
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT 'Hypertables: ' || COUNT(*) 
        FROM timescaledb_information.hypertables;
    " -t >> "$info_file" 2>/dev/null || echo "No hypertables found" >> "$info_file"
    
    # Add database size information
    echo "" >> "$info_file"
    echo "## Database Size Information" >> "$info_file"
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT 
            'Total Database Size: ' || pg_size_pretty(pg_database_size('${POSTGRES_DB}'));
    " -t >> "$info_file" 2>/dev/null
    
    log_success "Backup information saved: $info_file"
}

create_schema_backup() {
    local backup_dir="$1"
    local timestamp="$2"
    local schema_file="$backup_dir/schema_${timestamp}.sql"
    
    log_info "Creating schema-only backup..."
    
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_dump \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        --schema-only \
        --no-owner \
        --no-privileges \
        -f "/tmp/schema.sql" 2>/dev/null || {
        log_error "Failed to create schema backup"
        return 1
    }
    
    # Copy schema backup from container
    docker cp prs-ec2-postgres-timescale:/tmp/schema.sql "$schema_file"
    docker exec prs-ec2-postgres-timescale rm -f /tmp/schema.sql
    
    log_success "Schema backup created: $schema_file ($(du -h "$schema_file" | cut -f1))"
}

create_data_backup() {
    local backup_dir="$1"
    local timestamp="$2"
    local data_file="$backup_dir/data_${timestamp}.sql"
    
    log_info "Creating data-only backup..."
    
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_dump \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        --data-only \
        --no-owner \
        --no-privileges \
        --disable-triggers \
        -f "/tmp/data.sql" 2>/dev/null || {
        log_error "Failed to create data backup"
        return 1
    }
    
    # Copy data backup from container
    docker cp prs-ec2-postgres-timescale:/tmp/data.sql "$data_file"
    docker exec prs-ec2-postgres-timescale rm -f /tmp/data.sql
    
    log_success "Data backup created: $data_file ($(du -h "$data_file" | cut -f1))"
}

create_full_backup() {
    local backup_dir="$1"
    local timestamp="$2"
    local full_file="$backup_dir/full_${timestamp}.sql"
    
    log_info "Creating full SQL backup..."
    
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_dump \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        --no-owner \
        --no-privileges \
        -f "/tmp/full.sql" 2>/dev/null || {
        log_error "Failed to create full backup"
        return 1
    }
    
    # Copy full backup from container
    docker cp prs-ec2-postgres-timescale:/tmp/full.sql "$full_file"
    docker exec prs-ec2-postgres-timescale rm -f /tmp/full.sql
    
    log_success "Full SQL backup created: $full_file ($(du -h "$full_file" | cut -f1))"
}

create_binary_backup() {
    local backup_dir="$1"
    local timestamp="$2"
    local binary_file="$backup_dir/binary_${timestamp}.dump"
    
    log_info "Creating binary backup (custom format)..."
    
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_dump \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        -Fc \
        --no-owner \
        --no-privileges \
        -f "/tmp/binary.dump" 2>/dev/null || {
        log_error "Failed to create binary backup"
        return 1
    }
    
    # Copy binary backup from container
    docker cp prs-ec2-postgres-timescale:/tmp/binary.dump "$binary_file"
    docker exec prs-ec2-postgres-timescale rm -f /tmp/binary.dump
    
    log_success "Binary backup created: $binary_file ($(du -h "$binary_file" | cut -f1))"
}

compress_backups() {
    local backup_dir="$1"
    local timestamp="$2"
    
    log_info "Compressing backups..."
    
    cd "$backup_dir"
    
    # Compress SQL files
    for sql_file in schema_${timestamp}.sql data_${timestamp}.sql full_${timestamp}.sql; do
        if [ -f "$sql_file" ]; then
            gzip "$sql_file"
            log_info "Compressed: $sql_file.gz"
        fi
    done
    
    log_success "Backup compression completed"
}

cleanup_old_backups() {
    local backup_dir="$1"
    local retention_days="${BACKUP_RETENTION_DAYS:-7}"
    
    log_info "Cleaning up backups older than $retention_days days..."
    
    # Clean up old backups
    find "$backup_dir" -name "*.sql.gz" -mtime +$retention_days -delete 2>/dev/null || true
    find "$backup_dir" -name "*.dump" -mtime +$retention_days -delete 2>/dev/null || true
    find "$backup_dir" -name "*.txt" -mtime +$retention_days -delete 2>/dev/null || true
    
    log_success "Old backup cleanup completed"
}

show_backup_summary() {
    local backup_dir="$1"
    local timestamp="$2"
    
    log_success "Backup completed successfully!"
    echo ""
    echo "📁 Backup Location: $backup_dir"
    echo "🕐 Timestamp: $timestamp"
    echo ""
    echo "📊 Backup Files Created:"
    
    for file in "$backup_dir"/*${timestamp}*; do
        if [ -f "$file" ]; then
            echo "  📄 $(basename "$file") - $(du -h "$file" | cut -f1)"
        fi
    done
    
    echo ""
    echo "💾 Total Backup Size: $(du -sh "$backup_dir" | cut -f1)"
    echo ""
    echo "🔄 Restore Commands:"
    echo "  Schema only: docker exec -i prs-ec2-postgres-timescale psql -U \$POSTGRES_USER -d \$POSTGRES_DB < schema_${timestamp}.sql.gz"
    echo "  Full restore: docker exec -i prs-ec2-postgres-timescale psql -U \$POSTGRES_USER -d \$POSTGRES_DB < full_${timestamp}.sql.gz"
    echo "  Binary restore: docker exec -i prs-ec2-postgres-timescale pg_restore -U \$POSTGRES_USER -d \$POSTGRES_DB binary_${timestamp}.dump"
}

# Main backup function
main() {
    local backup_type="${1:-full}"
    
    log_info "Starting TimescaleDB production backup..."
    log_info "Backup type: $backup_type"
    
    # Load environment and check prerequisites
    load_environment
    check_prerequisites
    
    # Create backup directory and timestamp
    local backup_dir=$(create_backup_directory)
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Create backup information
    create_pre_backup_info "$backup_dir" "$timestamp"
    
    # Create backups based on type
    case "$backup_type" in
        "schema")
            create_schema_backup "$backup_dir" "$timestamp"
            ;;
        "data")
            create_data_backup "$backup_dir" "$timestamp"
            ;;
        "full"|*)
            create_schema_backup "$backup_dir" "$timestamp"
            create_data_backup "$backup_dir" "$timestamp"
            create_full_backup "$backup_dir" "$timestamp"
            create_binary_backup "$backup_dir" "$timestamp"
            ;;
    esac
    
    # Compress backups
    compress_backups "$backup_dir" "$timestamp"
    
    # Cleanup old backups
    cleanup_old_backups "$backup_dir"
    
    # Show summary
    show_backup_summary "$backup_dir" "$timestamp"
}

# Show help
show_help() {
    echo "TimescaleDB Production Backup Script"
    echo ""
    echo "Usage: $0 [BACKUP_TYPE]"
    echo ""
    echo "Backup Types:"
    echo "  full     Create complete backup (schema + data + binary) [default]"
    echo "  schema   Create schema-only backup"
    echo "  data     Create data-only backup"
    echo ""
    echo "Examples:"
    echo "  $0           # Full backup"
    echo "  $0 full      # Full backup"
    echo "  $0 schema    # Schema only"
    echo "  $0 data      # Data only"
    echo ""
    echo "Environment Variables:"
    echo "  BACKUP_RETENTION_DAYS  Number of days to keep backups (default: 7)"
}

# Main script logic
case "${1:-full}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        main "$1"
        ;;
esac
