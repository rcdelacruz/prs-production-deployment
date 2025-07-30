#!/bin/bash

# TimescaleDB Production Monitoring and Alerting Script
# Monitors key metrics and sends alerts when thresholds are exceeded

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

# Alert thresholds
DISK_USAGE_THRESHOLD=80
COMPRESSION_RATIO_THRESHOLD=60
DB_SIZE_THRESHOLD_GB=40
QUERY_TIME_THRESHOLD_MS=5000

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

log_alert() {
    echo -e "${RED}[ALERT]${NC} $1"
    # Log to syslog for centralized monitoring
    logger -t "timescaledb-alert" "$1"
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
        log_alert "TimescaleDB container is not running!"
        return 1
    fi
    
    # Check if database is accessible
    if ! docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" &> /dev/null; then
        log_alert "Database is not accessible!"
        return 1
    fi
    
    return 0
}

check_disk_usage() {
    log_info "Checking disk usage..."
    
    # Get disk usage for Docker data directory
    local disk_usage=$(df -h /var/lib/docker 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")
    
    if [ -z "$disk_usage" ]; then
        # Fallback to root filesystem
        disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    fi
    
    log_info "Current disk usage: ${disk_usage}%"
    
    if [ "$disk_usage" -gt "$DISK_USAGE_THRESHOLD" ]; then
        log_alert "High disk usage detected: ${disk_usage}% (threshold: ${DISK_USAGE_THRESHOLD}%)"
        
        # Get database size for context
        local db_size=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT pg_size_pretty(pg_database_size('${POSTGRES_DB}'));" 2>/dev/null | tr -d ' ' || echo "Unknown")
        log_alert "Database size: $db_size"
        
        return 1
    else
        log_success "Disk usage is within acceptable limits: ${disk_usage}%"
        return 0
    fi
}

check_database_size() {
    log_info "Checking database size..."
    
    # Get database size in bytes
    local db_size_bytes=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT pg_database_size('${POSTGRES_DB}');" 2>/dev/null | tr -d ' ' || echo "0")
    
    # Convert to GB
    local db_size_gb=$((db_size_bytes / 1024 / 1024 / 1024))
    
    # Get human readable size
    local db_size_pretty=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT pg_size_pretty(pg_database_size('${POSTGRES_DB}'));" 2>/dev/null | tr -d ' ' || echo "Unknown")
    
    log_info "Current database size: $db_size_pretty (${db_size_gb} GB)"
    
    if [ "$db_size_gb" -gt "$DB_SIZE_THRESHOLD_GB" ]; then
        log_alert "Large database size detected: $db_size_pretty (threshold: ${DB_SIZE_THRESHOLD_GB} GB)"
        log_alert "Consider reviewing compression policies and data retention"
        return 1
    else
        log_success "Database size is within expected range: $db_size_pretty"
        return 0
    fi
}

check_compression_efficiency() {
    log_info "Checking compression efficiency..."
    
    # Check if TimescaleDB extension is enabled
    local extension_enabled=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'timescaledb');" 2>/dev/null | tr -d ' ')
    
    if [ "$extension_enabled" != "t" ]; then
        log_warning "TimescaleDB extension not enabled, skipping compression check"
        return 0
    fi
    
    # Get overall compression ratio
    local compression_stats=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "
        SELECT 
            COUNT(CASE WHEN is_compressed THEN 1 END) as compressed_chunks,
            COUNT(*) as total_chunks,
            ROUND(
                (COUNT(CASE WHEN is_compressed THEN 1 END)::float / NULLIF(COUNT(*), 0)::float) * 100, 
                2
            ) as compression_ratio
        FROM timescaledb_information.chunks;
    " 2>/dev/null)
    
    if [ -n "$compression_stats" ]; then
        local compressed_chunks=$(echo "$compression_stats" | awk '{print $1}')
        local total_chunks=$(echo "$compression_stats" | awk '{print $3}')
        local compression_ratio=$(echo "$compression_stats" | awk '{print $5}')
        
        log_info "Compression status: $compressed_chunks/$total_chunks chunks compressed (${compression_ratio}%)"
        
        # Check if compression ratio is below threshold
        if (( $(echo "$compression_ratio < $COMPRESSION_RATIO_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
            log_alert "Low compression efficiency: ${compression_ratio}% (threshold: ${COMPRESSION_RATIO_THRESHOLD}%)"
            log_alert "Consider running manual compression or reviewing compression policies"
            return 1
        else
            log_success "Compression efficiency is acceptable: ${compression_ratio}%"
            return 0
        fi
    else
        log_warning "Could not retrieve compression statistics"
        return 0
    fi
}

check_query_performance() {
    log_info "Checking query performance..."
    
    # Check if pg_stat_statements is available
    local pg_stat_statements=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements');" 2>/dev/null | tr -d ' ')
    
    if [ "$pg_stat_statements" = "t" ]; then
        # Get average query time for recent queries
        local avg_query_time=$(docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" prs-ec2-postgres-timescale psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -t -c "
            SELECT ROUND(AVG(mean_exec_time), 2) 
            FROM pg_stat_statements 
            WHERE calls > 10 AND mean_exec_time > 100;
        " 2>/dev/null | tr -d ' ')
        
        if [ -n "$avg_query_time" ] && [ "$avg_query_time" != "" ]; then
            log_info "Average query execution time: ${avg_query_time}ms"
            
            if (( $(echo "$avg_query_time > $QUERY_TIME_THRESHOLD_MS" | bc -l 2>/dev/null || echo "0") )); then
                log_alert "Slow query performance detected: ${avg_query_time}ms (threshold: ${QUERY_TIME_THRESHOLD_MS}ms)"
                log_alert "Consider running performance optimization"
                return 1
            else
                log_success "Query performance is acceptable: ${avg_query_time}ms"
                return 0
            fi
        else
            log_info "No significant query performance data available"
            return 0
        fi
    else
        log_info "pg_stat_statements not available, skipping query performance check"
        return 0
    fi
}

check_backup_freshness() {
    log_info "Checking backup freshness..."
    
    local backup_dir="$PROJECT_DIR/backups"
    
    if [ -d "$backup_dir" ]; then
        # Find the most recent backup file
        local latest_backup=$(find "$backup_dir" -name "*.dump" -o -name "*.sql.gz" | head -1)
        
        if [ -n "$latest_backup" ]; then
            # Check if backup is less than 25 hours old (allowing for daily backup schedule)
            local backup_age=$(find "$backup_dir" -name "*.dump" -o -name "*.sql.gz" -mtime -1 | wc -l)
            
            if [ "$backup_age" -gt 0 ]; then
                log_success "Recent backup found (less than 24 hours old)"
                return 0
            else
                log_alert "No recent backup found! Latest backup is older than 24 hours"
                log_alert "Check backup cron job and backup script"
                return 1
            fi
        else
            log_alert "No backup files found in $backup_dir"
            log_alert "Backup system may not be configured properly"
            return 1
        fi
    else
        log_warning "Backup directory not found: $backup_dir"
        return 0
    fi
}

send_summary_report() {
    local alerts_count="$1"
    
    echo ""
    echo "=============================================="
    echo "  TimescaleDB Health Check Summary"
    echo "=============================================="
    echo "Date: $(date)"
    echo "Alerts triggered: $alerts_count"
    echo ""
    
    if [ "$alerts_count" -eq 0 ]; then
        log_success "✅ All health checks passed - system is healthy"
    else
        log_alert "⚠️  $alerts_count alert(s) detected - review required"
        echo ""
        echo "Recommended actions:"
        echo "1. Check system logs: journalctl -u docker"
        echo "2. Run maintenance: ./scripts/timescaledb-maintenance.sh full-maintenance"
        echo "3. Check storage: ./scripts/timescaledb-maintenance.sh storage"
        echo "4. Review alerts above for specific issues"
    fi
    
    echo ""
    echo "For detailed analysis, run:"
    echo "  ./scripts/timescaledb-maintenance.sh status"
    echo "  ./scripts/deploy-ec2.sh monitor"
    echo ""
}

# Main monitoring function
main() {
    log_info "Starting TimescaleDB health monitoring..."
    echo ""
    
    # Load environment and check prerequisites
    load_environment
    
    if ! check_prerequisites; then
        log_alert "Prerequisites check failed - system may be down"
        exit 1
    fi
    
    local alerts_count=0
    
    # Run all health checks
    check_disk_usage || ((alerts_count++))
    echo ""
    
    check_database_size || ((alerts_count++))
    echo ""
    
    check_compression_efficiency || ((alerts_count++))
    echo ""
    
    check_query_performance || ((alerts_count++))
    echo ""
    
    check_backup_freshness || ((alerts_count++))
    echo ""
    
    # Send summary report
    send_summary_report "$alerts_count"
    
    # Exit with error code if alerts were triggered
    if [ "$alerts_count" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Show help
show_help() {
    echo "TimescaleDB Production Monitoring and Alerting Script"
    echo ""
    echo "This script monitors key TimescaleDB metrics and alerts on issues."
    echo ""
    echo "Usage: $0"
    echo ""
    echo "Monitored metrics:"
    echo "  • Disk usage (threshold: ${DISK_USAGE_THRESHOLD}%)"
    echo "  • Database size (threshold: ${DB_SIZE_THRESHOLD_GB} GB)"
    echo "  • Compression efficiency (threshold: ${COMPRESSION_RATIO_THRESHOLD}%)"
    echo "  • Query performance (threshold: ${QUERY_TIME_THRESHOLD_MS}ms)"
    echo "  • Backup freshness (threshold: 24 hours)"
    echo ""
    echo "Exit codes:"
    echo "  0 - All checks passed"
    echo "  1 - One or more alerts triggered"
    echo ""
    echo "Recommended cron schedule:"
    echo "  */30 * * * * /path/to/timescaledb-alerts.sh"
}

# Main script logic
case "${1:-monitor}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        main
        ;;
esac
