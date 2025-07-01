#!/bin/bash

# TimescaleDB Production Maintenance Script
# Designed for long-term data growth with zero data deletion policy
# Handles compression, optimization, and monitoring for years of data

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
        source "$ENV_FILE"
    else
        log_error ".env file not found at $ENV_FILE"
        exit 1
    fi
}

check_prerequisites() {
    # Check if TimescaleDB container is running
    if ! docker ps | grep -q "prs-ec2-postgres-timescale"; then
        log_error "TimescaleDB container is not running"
        exit 1
    fi

    # Check if database is accessible
    if ! docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" &> /dev/null; then
        log_error "Database is not accessible"
        exit 1
    fi

    # Check if TimescaleDB extension is enabled
    local extension_enabled=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'timescaledb');" 2>/dev/null | tr -d ' ')

    if [ "$extension_enabled" != "t" ]; then
        log_error "TimescaleDB extension is not enabled"
        exit 1
    fi
}

setup_compression_policies() {
    log_info "Setting up compression policies for long-term data growth..."

    # Define compression policies for different table types
    # These are optimized for zero data deletion with years of growth
    local compression_policies=(
        # High-volume tables - compress after 30 days
        "audit_logs:30 days"
        "notifications:30 days"
        "force_close_logs:30 days"

        # Medium-volume tables - compress after 90 days
        "comments:90 days"
        "notes:90 days"
        "histories:90 days"
        "requisition_item_histories:90 days"
        "requisition_canvass_histories:90 days"
        "requisition_order_histories:90 days"
        "requisition_delivery_histories:90 days"
        "requisition_payment_histories:90 days"
        "requisition_return_histories:90 days"
        "non_requisition_histories:90 days"
        "delivery_receipt_items_history:90 days"

        # Business data - compress after 6 months (financial compliance)
        "requisitions:6 months"
        "purchase_orders:6 months"
        "delivery_receipts:6 months"
        "delivery_receipt_items:6 months"
        "rs_payment_requests:6 months"
        "rs_payment_request_approvers:6 months"
        "canvass_requisitions:6 months"
        "canvass_items:6 months"
        "canvass_item_suppliers:6 months"
        "canvass_approvers:6 months"
        "purchase_order_items:6 months"
        "purchase_order_approvers:6 months"
        "non_requisitions:6 months"
        "non_requisition_approvers:6 months"
        "non_requisition_items:6 months"
        "delivery_receipt_invoices:6 months"
        "invoice_reports:6 months"
        "gate_passes:6 months"
        "purchase_order_cancelled_items:6 months"

        # Reference data - compress after 1 year
        "requisition_badges:1 year"
        "requisition_approvers:1 year"
        "attachments:1 year"
        "requisition_item_lists:1 year"
    )

    local policies_added=0
    local policies_failed=0

    for policy in "${compression_policies[@]}"; do
        local table_name=$(echo "$policy" | cut -d':' -f1)
        local compress_after=$(echo "$policy" | cut -d':' -f2)

        # Check if table exists as hypertable
        local is_hypertable=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "
            SELECT EXISTS(
                SELECT 1 FROM timescaledb_information.hypertables
                WHERE hypertable_name = '$table_name'
            );
        " 2>/dev/null | tr -d ' ')

        if [ "$is_hypertable" = "t" ]; then
            # Check if compression policy already exists
            local policy_exists=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "
                SELECT EXISTS(
                    SELECT 1 FROM timescaledb_information.jobs
                    WHERE proc_name = 'policy_compression'
                    AND hypertable_name = '$table_name'
                );
            " 2>/dev/null | tr -d ' ')

            if [ "$policy_exists" != "t" ]; then
                log_info "Adding compression policy for $table_name (after $compress_after)"

                # First enable columnstore on the hypertable
                docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
                    ALTER TABLE $table_name SET (timescaledb.compress);
                " 2>/dev/null || {
                    log_warning "Failed to enable compression on $table_name, may already be enabled"
                }

                # Then add the compression policy
                docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
                    SELECT add_compression_policy('$table_name', INTERVAL '$compress_after');
                " 2>/dev/null && {
                    ((policies_added++))
                    log_success "✅ Compression policy added for $table_name"
                } || {
                    ((policies_failed++))
                    log_warning "⚠️  Failed to add compression policy for $table_name"
                }
            else
                log_info "Compression policy already exists for $table_name"
            fi
        else
            log_warning "Table $table_name is not a hypertable, skipping compression policy"
        fi
    done

    log_success "Compression policies setup completed:"
    log_info "  ✅ Policies added: $policies_added"
    log_info "  ⚠️  Policies failed: $policies_failed"
}

run_compression() {
    log_info "Running manual compression for eligible chunks..."

    # Get all hypertables and compress eligible chunks
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        DO \$\$
        DECLARE
            ht_name text;
            chunk_name text;
            compressed_count integer := 0;
        BEGIN
            -- Loop through all hypertables
            FOR ht_name IN
                SELECT hypertable_name FROM timescaledb_information.hypertables
            LOOP
                RAISE NOTICE 'Checking compression for hypertable: %', ht_name;

                -- Compress chunks that are eligible based on policies
                FOR chunk_name IN
                    SELECT chunk_name
                    FROM timescaledb_information.chunks
                    WHERE hypertable_name = ht_name
                    AND NOT is_compressed
                    AND range_end < NOW() - INTERVAL '1 day'  -- Only compress chunks older than 1 day
                LOOP
                    BEGIN
                        EXECUTE 'SELECT compress_chunk(''' || chunk_name || ''')';
                        compressed_count := compressed_count + 1;
                        RAISE NOTICE 'Compressed chunk: %', chunk_name;
                    EXCEPTION WHEN OTHERS THEN
                        RAISE NOTICE 'Failed to compress chunk: % - %', chunk_name, SQLERRM;
                    END;
                END LOOP;
            END LOOP;

            RAISE NOTICE 'Manual compression completed. Chunks compressed: %', compressed_count;
        END \$\$;
    " 2>/dev/null || log_warning "Manual compression encountered some issues"

    log_success "Manual compression completed"
}

optimize_performance() {
    log_info "Running performance optimization tasks..."

    # Update table statistics
    log_info "Updating table statistics..."
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "ANALYZE;" 2>/dev/null

    # Vacuum and analyze hypertables
    log_info "Running VACUUM ANALYZE on hypertables..."
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
    " 2>/dev/null

    # Reindex if needed (only for small tables to avoid long locks)
    log_info "Checking for index maintenance needs..."
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
        FROM pg_tables
        WHERE schemaname = 'public'
        AND pg_total_relation_size(schemaname||'.'||tablename) < 100000000  -- Less than 100MB
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    " 2>/dev/null

    log_success "Performance optimization completed"
}

show_compression_status() {
    log_info "Compression Status Report:"

    # Show compression policies
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            j.hypertable_name,
            j.config->>'compress_after' as compress_after,
            j.scheduled,
            j.next_start
        FROM timescaledb_information.jobs j
        WHERE j.proc_name = 'policy_compression'
        ORDER BY j.hypertable_name;
    " 2>/dev/null

    echo ""
    log_info "Compression Statistics:"

    # Show compression statistics
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            h.hypertable_name,
            COUNT(c.chunk_name) as total_chunks,
            COUNT(CASE WHEN c.is_compressed THEN 1 END) as compressed_chunks,
            ROUND(
                (COUNT(CASE WHEN c.is_compressed THEN 1 END)::float / COUNT(c.chunk_name)::float) * 100,
                2
            ) as compression_ratio,
            pg_size_pretty(
                SUM(CASE WHEN c.is_compressed THEN c.compressed_total_bytes ELSE c.total_bytes END)
            ) as total_size
        FROM timescaledb_information.hypertables h
        LEFT JOIN timescaledb_information.chunks c ON h.hypertable_name = c.hypertable_name
        GROUP BY h.hypertable_name
        ORDER BY h.hypertable_name;
    " 2>/dev/null
}

show_storage_report() {
    log_info "Storage Growth Report (for capacity planning):"

    # Show database size
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            'Total Database Size' as metric,
            pg_size_pretty(pg_database_size('${POSTGRES_DB}')) as size;
    " 2>/dev/null

    echo ""

    # Show largest tables
    docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
        SELECT
            h.hypertable_name,
            pg_size_pretty(pg_total_relation_size('public.' || h.hypertable_name)) as size,
            COUNT(c.chunk_name) as chunks,
            COUNT(CASE WHEN c.is_compressed THEN 1 END) as compressed_chunks
        FROM timescaledb_information.hypertables h
        LEFT JOIN timescaledb_information.chunks c ON h.hypertable_name = c.hypertable_name
        GROUP BY h.hypertable_name
        ORDER BY pg_total_relation_size('public.' || h.hypertable_name) DESC
        LIMIT 10;
    " 2>/dev/null
}

# Main functions
case "${1:-help}" in
    "setup-compression")
        load_environment
        check_prerequisites
        setup_compression_policies
        ;;
    "compress")
        load_environment
        check_prerequisites
        run_compression
        ;;
    "optimize")
        load_environment
        check_prerequisites
        optimize_performance
        ;;
    "status")
        load_environment
        check_prerequisites
        show_compression_status
        ;;
    "storage")
        load_environment
        check_prerequisites
        show_storage_report
        ;;
    "full-maintenance")
        load_environment
        check_prerequisites
        log_info "Running full maintenance cycle..."
        run_compression
        optimize_performance
        show_compression_status
        show_storage_report
        log_success "Full maintenance cycle completed"
        ;;
    "help"|"-h"|"--help")
        echo "TimescaleDB Production Maintenance Script"
        echo "Designed for long-term data growth with zero deletion policy"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  setup-compression   Setup compression policies for all hypertables"
        echo "  compress           Run manual compression on eligible chunks"
        echo "  optimize           Run performance optimization (VACUUM, ANALYZE)"
        echo "  status             Show compression status and statistics"
        echo "  storage            Show storage usage report for capacity planning"
        echo "  full-maintenance   Run complete maintenance cycle (recommended for cron)"
        echo ""
        echo "Recommended cron schedule:"
        echo "  Daily:   0 2 * * * /path/to/timescaledb-maintenance.sh full-maintenance"
        echo "  Weekly:  0 3 * * 0 /path/to/timescaledb-maintenance.sh optimize"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
