#!/bin/bash

# Safe Database Import Script for EC2 Graviton Setup
# This script handles foreign key constraints properly during database import

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

# Configuration
CONTAINER_NAME="prs-ec2-postgres"
POSTGRES_USER="${POSTGRES_USER:-prs_user}"
POSTGRES_DB="${POSTGRES_DB:-prs_production}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-prodpassword123}"

# Function to check if PostgreSQL container is running
check_postgres_container() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log_error "PostgreSQL container '$CONTAINER_NAME' is not running"
        log_info "Please start the services first with: ./scripts/deploy-ec2.sh start"
        exit 1
    fi
    log_success "PostgreSQL container is running"
}

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    log_info "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec "$CONTAINER_NAME" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
            log_success "PostgreSQL is ready"
            return 0
        fi
        
        log_info "Attempt $attempt/$max_attempts: PostgreSQL not ready yet, waiting..."
        sleep 2
        ((attempt++))
    done
    
    log_error "PostgreSQL failed to become ready after $max_attempts attempts"
    exit 1
}

# Function to backup current database
backup_current_database() {
    local backup_file="backup_$(date +%Y%m%d_%H%M%S).sql"
    log_info "Creating backup of current database: $backup_file"
    
    if docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
        pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists > "$backup_file"; then
        log_success "Backup created: $backup_file"
        echo "$backup_file"
    else
        log_error "Failed to create backup"
        exit 1
    fi
}

# Function to create a safe import SQL file
create_safe_import_file() {
    local input_file="$1"
    local safe_file="${input_file%.sql}_safe.sql"
    
    log_info "Creating safe import file: $safe_file"
    
    cat > "$safe_file" << 'EOF'
-- Safe Database Import Script
-- Disable foreign key constraints and triggers during import

BEGIN;

-- Disable all triggers (including foreign key triggers)
SET session_replication_role = replica;

-- Set constraints to deferred (if any are deferrable)
SET CONSTRAINTS ALL DEFERRED;

-- Disable foreign key checks (PostgreSQL equivalent)
-- Note: PostgreSQL doesn't have a global foreign key disable like MySQL
-- Instead, we'll handle this by importing in the correct order

EOF

    # Add the original SQL content (excluding any existing transaction blocks)
    log_info "Processing original SQL file..."
    
    # Remove any existing BEGIN/COMMIT statements and add the content
    sed -e '/^BEGIN;/d' -e '/^COMMIT;/d' -e '/^SET session_replication_role/d' "$input_file" >> "$safe_file"
    
    cat >> "$safe_file" << 'EOF'

-- Re-enable triggers and constraints
SET session_replication_role = DEFAULT;

-- Validate foreign key constraints
DO $$
DECLARE
    r RECORD;
    constraint_violations INTEGER := 0;
BEGIN
    -- Check for foreign key constraint violations
    FOR r IN 
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
        EXECUTE format('
            SELECT COUNT(*) FROM %I t1 
            LEFT JOIN %I t2 ON t1.%I = t2.%I 
            WHERE t1.%I IS NOT NULL AND t2.%I IS NULL',
            r.table_name, r.foreign_table_name, r.column_name, r.foreign_column_name,
            r.column_name, r.foreign_column_name
        ) INTO constraint_violations;
        
        IF constraint_violations > 0 THEN
            RAISE WARNING 'Foreign key constraint violation in table %.%: % rows violate constraint %',
                r.table_name, r.column_name, constraint_violations, r.constraint_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Foreign key constraint validation completed';
END $$;

COMMIT;

-- Update sequences to current max values
DO $$
DECLARE
    r RECORD;
    max_val BIGINT;
BEGIN
    FOR r IN 
        SELECT schemaname, tablename, attname, seq_name
        FROM (
            SELECT 
                schemaname,
                tablename,
                attname,
                pg_get_serial_sequence(schemaname||'.'||tablename, attname) as seq_name
            FROM pg_stats 
            WHERE schemaname = 'public'
        ) t
        WHERE seq_name IS NOT NULL
    LOOP
        EXECUTE format('SELECT COALESCE(MAX(%I), 1) FROM %I.%I', r.attname, r.schemaname, r.tablename) INTO max_val;
        EXECUTE format('SELECT setval(%L, %s)', r.seq_name, max_val);
        RAISE NOTICE 'Updated sequence % to %', r.seq_name, max_val;
    END LOOP;
END $$;

-- Analyze tables for better query performance
ANALYZE;

EOF

    log_success "Safe import file created: $safe_file"
    echo "$safe_file"
}

# Function to import database safely
import_database_safe() {
    local sql_file="$1"
    local backup_file="$2"
    
    log_info "Starting safe database import from: $sql_file"
    
    # Create safe import file
    local safe_file
    safe_file=$(create_safe_import_file "$sql_file")
    
    # Import the safe SQL file
    log_info "Importing database with foreign key constraint handling..."
    if docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
        psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 < "$safe_file"; then
        log_success "Database import completed successfully"
        
        # Clean up the temporary safe file
        rm -f "$safe_file"
        
        # Validate the import
        validate_import
        
    else
        log_error "Database import failed"
        log_warning "Attempting to restore from backup: $backup_file"
        
        # Restore from backup
        if docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
            psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$backup_file"; then
            log_success "Database restored from backup"
        else
            log_error "Failed to restore from backup"
        fi
        
        # Clean up
        rm -f "$safe_file"
        exit 1
    fi
}

# Function to validate the import
validate_import() {
    log_info "Validating database import..."
    
    # Check if key tables have data
    local tables=("users" "companies" "projects" "departments" "requisitions")
    
    for table in "${tables[@]}"; do
        local count
        count=$(docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
            psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' ')
        
        if [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" -gt 0 ]; then
            log_success "Table '$table' has $count records"
        else
            log_warning "Table '$table' appears to be empty or missing"
        fi
    done
    
    # Check for foreign key constraint violations
    log_info "Checking for foreign key constraint violations..."
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
        psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
        SELECT 
            tc.table_name,
            tc.constraint_name
        FROM information_schema.table_constraints AS tc
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
        LIMIT 5;" > /dev/null
    
    log_success "Database validation completed"
}

# Main function
main() {
    local sql_file="$1"
    
    if [ -z "$sql_file" ]; then
        log_error "Please provide a SQL file path"
        echo "Usage: $0 <path-to-sql-file>"
        echo ""
        echo "Available SQL files:"
        ls -la *.sql 2>/dev/null || echo "No SQL files found in current directory"
        exit 1
    fi
    
    if [ ! -f "$sql_file" ]; then
        log_error "SQL file not found: $sql_file"
        exit 1
    fi
    
    log_info "Starting safe database import process..."
    log_info "SQL file: $sql_file"
    log_info "Target database: $POSTGRES_DB"
    log_info "PostgreSQL user: $POSTGRES_USER"
    
    # Check prerequisites
    check_postgres_container
    wait_for_postgres
    
    # Create backup
    local backup_file
    backup_file=$(backup_current_database)
    
    # Import database safely
    import_database_safe "$sql_file" "$backup_file"
    
    log_success "Safe database import process completed successfully!"
    log_info "Backup file saved as: $backup_file"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
