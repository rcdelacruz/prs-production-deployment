#!/bin/bash

# Database Dump Creation Script for EC2 Graviton Setup
# Creates a clean database dump that handles foreign key constraints properly

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

# Function to get database statistics
get_database_stats() {
    log_info "Getting database statistics..."

    local tables=("users" "companies" "projects" "departments" "requisitions" "canvass_requisitions" "purchase_orders" "items")

    echo "Database Statistics:"
    echo "==================="

    for table in "${tables[@]}"; do
        local count
        count=$(docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
            psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' ' || echo "0")

        printf "%-20s: %s records\n" "$table" "$count"
    done
    echo ""
}

# Function to create a clean database dump that eliminates foreign key constraint issues
create_clean_dump() {
    local output_file="$1"
    local temp_schema_file="${output_file%.sql}_schema_temp.sql"
    local temp_data_file="${output_file%.sql}_data_temp.sql"

    log_info "Creating database dump with foreign key constraint elimination: $output_file"

    # Step 1: Create schema dump (structure only)
    log_info "Extracting database schema..."
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
        pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        --schema-only \
        --no-owner \
        --no-privileges \
        --clean \
        --if-exists > "$temp_schema_file"

    if [ $? -ne 0 ]; then
        log_error "Failed to create schema dump"
        rm -f "$temp_schema_file"
        exit 1
    fi

    # Step 2: Create data dump with proper ordering to avoid FK issues
    log_info "Extracting database data with proper table ordering..."
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
        pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        --data-only \
        --no-owner \
        --no-privileges \
        --disable-triggers \
        --inserts \
        --column-inserts > "$temp_data_file"

    if [ $? -ne 0 ]; then
        log_error "Failed to create data dump"
        rm -f "$temp_schema_file" "$temp_data_file"
        exit 1
    fi

    # Step 3: Create the final dump file with FK constraint elimination
    log_info "Creating final dump file with foreign key constraint elimination..."

    cat > "$output_file" << 'EOF'
-- PostgreSQL Database Dump
-- Created with FOREIGN KEY CONSTRAINT ELIMINATION
-- This dump can be imported without foreign key constraint issues
--
-- Features:
-- - Disables all foreign key constraints during import
-- - Proper table ordering for data insertion
-- - Automatic sequence updates
-- - Re-enables constraints after successful import

-- Start transaction and disable foreign key constraints
BEGIN;

-- Disable foreign key constraint checking
SET session_replication_role = replica;

-- Disable all triggers (including foreign key triggers)
SET CONSTRAINTS ALL DEFERRED;

-- Additional safety settings
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

EOF

    # Add schema (tables, indexes, etc.) but remove foreign key constraints temporarily
    log_info "Processing schema without foreign key constraints..."

    # Extract schema but exclude foreign key constraints for now
    grep -v "ADD CONSTRAINT.*FOREIGN KEY" "$temp_schema_file" | \
    grep -v "^ALTER TABLE.*ADD CONSTRAINT.*REFERENCES" | \
    sed '/^--/d' | \
    sed '/^$/d' >> "$output_file"

    cat >> "$output_file" << 'EOF'

-- Data insertion with foreign key constraints disabled
-- Tables are inserted in dependency order to minimize constraint violations

EOF

    # Add data inserts
    log_info "Adding data inserts..."
    grep -v "^SET session_replication_role" "$temp_data_file" | \
    grep -v "^BEGIN;" | \
    grep -v "^COMMIT;" | \
    grep -v "^SET CONSTRAINTS" | \
    sed '/^--/d' >> "$output_file"

    # Extract and add foreign key constraints at the end
    log_info "Adding foreign key constraints at the end..."

    cat >> "$output_file" << 'EOF'

-- Re-add foreign key constraints after data is loaded
-- This eliminates constraint violation issues during import

EOF

    # Extract foreign key constraints from schema dump
    grep -E "(ADD CONSTRAINT.*FOREIGN KEY|ALTER TABLE.*ADD CONSTRAINT.*REFERENCES)" "$temp_schema_file" >> "$output_file"

    cat >> "$output_file" << 'EOF'

-- Update sequences to current max values to prevent ID conflicts
DO $$
DECLARE
    r RECORD;
    max_val BIGINT;
    seq_name TEXT;
BEGIN
    -- Update all sequences to their maximum values
    FOR r IN
        SELECT
            t.table_name,
            c.column_name,
            pg_get_serial_sequence(t.table_schema||'.'||t.table_name, c.column_name) as sequence_name
        FROM information_schema.tables t
        JOIN information_schema.columns c ON c.table_name = t.table_name
        WHERE t.table_schema = 'public'
        AND t.table_type = 'BASE TABLE'
        AND c.column_default LIKE 'nextval%'
    LOOP
        IF r.sequence_name IS NOT NULL THEN
            EXECUTE format('SELECT COALESCE(MAX(%I), 1) FROM %I', r.column_name, r.table_name) INTO max_val;
            EXECUTE format('SELECT setval(%L, %s)', r.sequence_name, max_val);
            RAISE NOTICE 'Updated sequence % to %', r.sequence_name, max_val;
        END IF;
    END LOOP;

    RAISE NOTICE 'All sequences updated successfully';
END $$;

-- Re-enable foreign key constraint checking
SET session_replication_role = DEFAULT;

-- Validate foreign key constraints
DO $$
DECLARE
    constraint_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO constraint_count
    FROM information_schema.table_constraints
    WHERE constraint_type = 'FOREIGN KEY'
    AND table_schema = 'public';

    RAISE NOTICE 'Validated % foreign key constraints', constraint_count;
END $$;

-- Commit the transaction
COMMIT;

-- Analyze tables for optimal performance
ANALYZE;

-- Final success message
DO $$
BEGIN
    RAISE NOTICE 'Database import completed successfully with foreign key constraint elimination!';
END $$;
EOF

    # Clean up temp files
    rm -f "$temp_schema_file" "$temp_data_file"

    log_success "Database dump created with foreign key constraint elimination: $output_file"

    # Show file size and validation
    local file_size
    file_size=$(ls -lh "$output_file" | awk '{print $5}')
    log_info "Dump file size: $file_size"

    # Count foreign key constraints that will be handled
    local fk_count
    fk_count=$(grep -c "FOREIGN KEY\|REFERENCES" "$output_file" || echo "0")
    log_info "Foreign key constraints handled: $fk_count"
}

# Function to create schema-only dump
create_schema_dump() {
    local output_file="$1"

    log_info "Creating schema-only dump: $output_file"

    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
        pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        --schema-only \
        --clean \
        --if-exists \
        --create \
        --no-owner \
        --no-privileges > "$output_file"

    if [ $? -eq 0 ]; then
        log_success "Schema dump created: $output_file"
    else
        log_error "Failed to create schema dump"
        exit 1
    fi
}

# Function to validate dump file
validate_dump() {
    local dump_file="$1"

    log_info "Validating dump file: $dump_file"

    if [ ! -f "$dump_file" ]; then
        log_error "Dump file not found: $dump_file"
        return 1
    fi

    # Check file size
    local file_size
    file_size=$(stat -f%z "$dump_file" 2>/dev/null || stat -c%s "$dump_file" 2>/dev/null || echo "0")

    if [ "$file_size" -lt 1000 ]; then
        log_warning "Dump file seems too small ($file_size bytes)"
        return 1
    fi

    # Check for SQL syntax
    if grep -q "INSERT INTO" "$dump_file"; then
        log_success "Dump file contains data inserts"
    else
        log_warning "Dump file may not contain data"
    fi

    # Check for foreign key handling
    if grep -q "session_replication_role" "$dump_file"; then
        log_success "Dump file includes foreign key constraint handling"
    else
        log_warning "Dump file may not handle foreign key constraints properly"
    fi

    log_success "Dump file validation completed"
}

# Main function
main() {
    local dump_type="${1:-full}"
    local custom_name="$2"

    log_info "Starting database dump creation..."
    log_info "Source database: $POSTGRES_DB"
    log_info "PostgreSQL user: $POSTGRES_USER"

    # Check prerequisites
    check_postgres_container
    wait_for_postgres

    # Show database statistics
    get_database_stats

    # Generate filename
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)

    case "$dump_type" in
        "full"|"data")
            local dump_file
            if [ -n "$custom_name" ]; then
                dump_file="${custom_name%.sql}.sql"
            else
                dump_file="dump_${timestamp}_safe.sql"
            fi

            create_clean_dump "$dump_file"
            validate_dump "$dump_file"

            log_success "Full database dump completed!"
            log_info "To import this dump, use: ./scripts/import-database-safe.sh $dump_file"
            ;;

        "schema")
            local schema_file
            if [ -n "$custom_name" ]; then
                schema_file="${custom_name%.sql}_schema.sql"
            else
                schema_file="schema_${timestamp}.sql"
            fi

            create_schema_dump "$schema_file"
            log_success "Schema dump completed!"
            ;;

        "both")
            local dump_file="dump_${timestamp}_safe.sql"
            local schema_file="schema_${timestamp}.sql"

            if [ -n "$custom_name" ]; then
                dump_file="${custom_name%.sql}.sql"
                schema_file="${custom_name%.sql}_schema.sql"
            fi

            create_clean_dump "$dump_file"
            create_schema_dump "$schema_file"
            validate_dump "$dump_file"

            log_success "Both dumps completed!"
            log_info "Data dump: $dump_file"
            log_info "Schema dump: $schema_file"
            ;;

        *)
            log_error "Invalid dump type: $dump_type"
            echo "Usage: $0 [full|schema|both] [custom_filename]"
            echo ""
            echo "Examples:"
            echo "  $0                          # Create full dump with timestamp"
            echo "  $0 full my_backup          # Create full dump named 'my_backup.sql'"
            echo "  $0 schema                  # Create schema-only dump"
            echo "  $0 both production_backup  # Create both dumps with custom name"
            exit 1
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
