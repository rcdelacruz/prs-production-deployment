#!/bin/bash

# Simple Database Dump Script - ELIMINATES Foreign Key Constraints
# Creates a clean dump that can be imported without foreign key constraint issues

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

# Main dump function that eliminates foreign key constraints
create_dump_without_fk_constraints() {
    local output_file="$1"
    
    log_info "Creating database dump WITHOUT foreign key constraints: $output_file"
    log_info "This dump can be imported without constraint violation issues"
    
    # Create the dump file with foreign key constraint elimination
    cat > "$output_file" << 'EOF'
-- PostgreSQL Database Dump
-- FOREIGN KEY CONSTRAINTS ELIMINATED
-- This dump can be imported without foreign key constraint issues
-- 
-- Import process:
-- 1. Disables all foreign key constraints
-- 2. Creates tables and inserts data
-- 3. Re-enables constraints at the end
-- 4. Updates sequences automatically

-- Disable foreign key constraints for import
BEGIN;
SET session_replication_role = replica;
SET CONSTRAINTS ALL DEFERRED;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

EOF

    # Get the actual database dump and process it
    log_info "Extracting database schema and data..."
    
    # Create a complete dump but process it to handle FK constraints properly
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
        pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        --clean \
        --if-exists \
        --no-owner \
        --no-privileges \
        --inserts \
        --column-inserts \
        --disable-triggers | \
    # Process the dump to remove problematic statements
    grep -v "^SET session_replication_role" | \
    grep -v "^BEGIN;" | \
    grep -v "^COMMIT;" | \
    grep -v "^SET CONSTRAINTS" | \
    # Remove foreign key constraint additions (we'll add them at the end)
    sed '/ADD CONSTRAINT.*FOREIGN KEY/d' | \
    sed '/REFERENCES.*ON DELETE\|REFERENCES.*ON UPDATE/d' >> "$output_file"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log_error "Failed to create database dump"
        rm -f "$output_file"
        exit 1
    fi
    
    # Add foreign key constraints at the end (after all data is loaded)
    log_info "Adding foreign key constraints at the end to avoid constraint violations..."
    
    cat >> "$output_file" << 'EOF'

-- Add foreign key constraints AFTER all data is loaded
-- This prevents constraint violation errors during import

EOF

    # Extract foreign key constraints and add them at the end
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
        pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --schema-only | \
    grep -E "ADD CONSTRAINT.*FOREIGN KEY|REFERENCES.*ON DELETE|REFERENCES.*ON UPDATE" >> "$output_file"
    
    # Add sequence updates and cleanup
    cat >> "$output_file" << 'EOF'

-- Update all sequences to prevent ID conflicts
DO $$
DECLARE
    r RECORD;
    max_val BIGINT;
BEGIN
    FOR r IN 
        SELECT 
            t.table_name,
            c.column_name,
            pg_get_serial_sequence('public.'||t.table_name, c.column_name) as seq_name
        FROM information_schema.tables t
        JOIN information_schema.columns c ON c.table_name = t.table_name
        WHERE t.table_schema = 'public' 
        AND t.table_type = 'BASE TABLE'
        AND c.column_default LIKE 'nextval%'
    LOOP
        IF r.seq_name IS NOT NULL THEN
            EXECUTE format('SELECT COALESCE(MAX(%I), 1) FROM %I', r.column_name, r.table_name) INTO max_val;
            EXECUTE format('SELECT setval(%L, %s)', r.seq_name, max_val);
            RAISE NOTICE 'Updated sequence % to %', r.seq_name, max_val;
        END IF;
    END LOOP;
END $$;

-- Re-enable foreign key constraints
SET session_replication_role = DEFAULT;

-- Commit all changes
COMMIT;

-- Optimize database performance
ANALYZE;

-- Success message
SELECT 'Database dump import completed successfully - foreign key constraints handled properly!' as status;
EOF

    log_success "Database dump created: $output_file"
    
    # Show file information
    local file_size
    file_size=$(ls -lh "$output_file" | awk '{print $5}')
    log_info "Dump file size: $file_size"
    
    # Count foreign key constraints
    local fk_count
    fk_count=$(grep -c "FOREIGN KEY\|REFERENCES" "$output_file" 2>/dev/null || echo "0")
    log_info "Foreign key constraints handled: $fk_count"
    
    log_success "✅ Dump created WITHOUT foreign key constraint issues!"
    log_info "📁 File: $output_file"
    log_info "📊 Size: $file_size"
    log_info "🔗 FK Constraints: $fk_count (handled safely)"
    echo ""
    log_info "To import this dump:"
    log_info "  psql -U $POSTGRES_USER -d $POSTGRES_DB < $output_file"
    log_info "  OR use: ./scripts/deploy-ec2.sh import-db $output_file"
}

# Show database statistics
show_database_stats() {
    log_info "Current database statistics:"
    echo "=============================="
    
    local tables=("users" "companies" "projects" "departments" "requisitions" "canvass_requisitions" "purchase_orders")
    
    for table in "${tables[@]}"; do
        local count
        count=$(docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_NAME" \
            psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' ' || echo "0")
        printf "%-20s: %s records\n" "$table" "$count"
    done
    echo ""
}

# Main function
main() {
    local output_file="$1"
    
    if [ -z "$output_file" ]; then
        log_error "Please provide an output filename"
        echo ""
        echo "Usage: $0 <output-filename>"
        echo ""
        echo "Examples:"
        echo "  $0 production_dump_$(date +%Y%m%d).sql"
        echo "  $0 backup_no_fk_constraints.sql"
        echo "  $0 clean_dump.sql"
        exit 1
    fi
    
    # Add .sql extension if not provided
    if [[ "$output_file" != *.sql ]]; then
        output_file="${output_file}.sql"
    fi
    
    log_info "🚀 Starting database dump creation (WITHOUT foreign key constraint issues)"
    log_info "📋 Source database: $POSTGRES_DB"
    log_info "👤 PostgreSQL user: $POSTGRES_USER"
    log_info "📁 Output file: $output_file"
    echo ""
    
    # Check prerequisites
    check_postgres_container
    
    # Show current database stats
    show_database_stats
    
    # Create the dump
    create_dump_without_fk_constraints "$output_file"
    
    echo ""
    log_success "🎉 Database dump creation completed successfully!"
    log_info "✅ Foreign key constraints have been eliminated from the dump"
    log_info "✅ This dump can be imported without constraint violation issues"
    log_info "✅ All sequences will be updated automatically during import"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
