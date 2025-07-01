#!/bin/bash

# PRS Production Log Monitoring and Alerting Script
# This script monitors logs for errors and sends alerts

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ALERT_LOG="$PROJECT_DIR/logs/alerts.log"
ERROR_THRESHOLD=${ERROR_THRESHOLD:-5}  # Number of errors in time window to trigger alert
TIME_WINDOW=${TIME_WINDOW:-300}        # Time window in seconds (5 minutes)
CHECK_INTERVAL=${CHECK_INTERVAL:-60}   # Check interval in seconds (1 minute)

# Alert configuration
WEBHOOK_URL=${WEBHOOK_URL:-""}         # Slack/Discord webhook URL
EMAIL_TO=${EMAIL_TO:-""}               # Email address for alerts
ENABLE_ALERTS=${ENABLE_ALERTS:-true}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Create alert log directory
mkdir -p "$(dirname "$ALERT_LOG")"

# Function to send alert
send_alert() {
    local alert_type="$1"
    local message="$2"
    local details="$3"

    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local alert_message="🚨 PRS Production Alert - $alert_type

Time: $timestamp
Environment: Production
Service: PRS Backend

$message

Details:
$details

Server: $(hostname)
"

    # Log the alert
    echo "[$timestamp] ALERT: $alert_type - $message" >> "$ALERT_LOG"

    if [ "$ENABLE_ALERTS" = "true" ]; then
        # Send to webhook if configured
        if [ -n "$WEBHOOK_URL" ]; then
            curl -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"$alert_message\"}" \
                "$WEBHOOK_URL" 2>/dev/null || warning "Failed to send webhook alert"
        fi

        # Send email if configured
        if [ -n "$EMAIL_TO" ] && command -v mail >/dev/null 2>&1; then
            echo "$alert_message" | mail -s "PRS Production Alert - $alert_type" "$EMAIL_TO" || \
                warning "Failed to send email alert"
        fi
    fi

    error "$alert_type: $message"
}

# Function to check for 500 errors
check_500_errors() {
    local since_time=$(date -d "$TIME_WINDOW seconds ago" --iso-8601=seconds)
    local error_count=0

    # Check backend logs for 500 errors
    if docker ps -q -f name=prs-ec2-backend >/dev/null 2>&1; then
        error_count=$(docker logs prs-ec2-backend --since="$since_time" 2>&1 | \
            grep -E "(500|Internal Server Error|INTERNAL_SERVER_ERROR)" | wc -l || echo "0")
    fi

    if [ "$error_count" -ge "$ERROR_THRESHOLD" ]; then
        local error_details=$(docker logs prs-ec2-backend --since="$since_time" 2>&1 | \
            grep -E "(500|Internal Server Error|INTERNAL_SERVER_ERROR)" | tail -5)

        send_alert "HIGH_ERROR_RATE" \
            "Detected $error_count 500 errors in the last $((TIME_WINDOW/60)) minutes" \
            "$error_details"
    fi
}

# Function to check database connectivity
check_database_health() {
    if ! docker exec prs-ec2-postgres-timescale pg_isready -U "${POSTGRES_USER:-prs_user}" >/dev/null 2>&1; then
        send_alert "DATABASE_DOWN" \
            "PostgreSQL database is not responding" \
            "Database health check failed"
    fi
}

# Function to check container health
check_container_health() {
    local containers=("prs-ec2-backend" "prs-ec2-nginx" "prs-ec2-postgres-timescale")

    for container in "${containers[@]}"; do
        if ! docker ps -q -f name="$container" >/dev/null 2>&1; then
            send_alert "CONTAINER_DOWN" \
                "Container $container is not running" \
                "Container status check failed"
        fi
    done
}

# Function to check disk space
check_disk_space() {
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ "$disk_usage" -ge 90 ]; then
        send_alert "DISK_SPACE_CRITICAL" \
            "Disk usage is at ${disk_usage}%" \
            "$(df -h /)"
    elif [ "$disk_usage" -ge 80 ]; then
        warning "Disk usage is at ${disk_usage}%"
    fi
}

# Function to check memory usage
check_memory_usage() {
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')

    if [ "$mem_usage" -ge 90 ]; then
        send_alert "MEMORY_CRITICAL" \
            "Memory usage is at ${mem_usage}%" \
            "$(free -h)"
    elif [ "$mem_usage" -ge 80 ]; then
        warning "Memory usage is at ${mem_usage}%"
    fi
}

# Function to check application health endpoint
check_app_health() {
    local health_url="http://localhost:4000/health"

    if ! curl -f -s "$health_url" >/dev/null 2>&1; then
        send_alert "APP_HEALTH_FAILED" \
            "Application health check endpoint is not responding" \
            "Health endpoint: $health_url"
    fi
}

# Function to analyze error patterns
analyze_error_patterns() {
    local since_time=$(date -d "$TIME_WINDOW seconds ago" --iso-8601=seconds)

    # Check for specific error patterns
    if docker ps -q -f name=prs-ec2-backend >/dev/null 2>&1; then
        local logs=$(docker logs prs-ec2-backend --since="$since_time" 2>&1)

        # Check for database connection errors
        local db_errors=$(echo "$logs" | grep -i "database.*error\|connection.*refused\|sequelize.*error" | wc -l || echo "0")
        if [ "$db_errors" -ge 3 ]; then
            send_alert "DATABASE_ERRORS" \
                "Multiple database errors detected ($db_errors)" \
                "$(echo "$logs" | grep -i "database.*error\|connection.*refused\|sequelize.*error" | tail -3)"
        fi

        # Check for authentication errors
        local auth_errors=$(echo "$logs" | grep -i "unauthorized\|forbidden\|authentication.*failed" | wc -l || echo "0")
        if [ "$auth_errors" -ge 10 ]; then
            send_alert "AUTH_ERRORS" \
                "High number of authentication errors ($auth_errors)" \
                "Possible security issue or misconfiguration"
        fi
    fi
}

# Function to run all checks
run_monitoring_checks() {
    info "Running production monitoring checks..."

    check_500_errors
    check_database_health
    check_container_health
    check_disk_space
    check_memory_usage
    check_app_health
    analyze_error_patterns

    log "Monitoring checks completed"
}

# Function to start continuous monitoring
start_monitoring() {
    log "Starting continuous log monitoring (interval: ${CHECK_INTERVAL}s)"
    log "Error threshold: $ERROR_THRESHOLD errors in $((TIME_WINDOW/60)) minutes"
    log "Alerts enabled: $ENABLE_ALERTS"

    while true; do
        run_monitoring_checks
        sleep "$CHECK_INTERVAL"
    done
}

# Function to show monitoring status
show_status() {
    log "📊 PRS Production Monitoring Status"
    echo "=================================="

    echo -e "\n${BLUE}Configuration:${NC}"
    echo "  Error threshold: $ERROR_THRESHOLD errors in $((TIME_WINDOW/60)) minutes"
    echo "  Check interval: ${CHECK_INTERVAL}s"
    echo "  Alerts enabled: $ENABLE_ALERTS"
    echo "  Alert log: $ALERT_LOG"

    echo -e "\n${BLUE}Container Status:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=prs-ec2"

    echo -e "\n${BLUE}System Resources:${NC}"
    echo "  Memory: $(free -h | awk 'NR==2{printf "%s/%s (%.0f%%)", $3,$2,$3*100/$2}')"
    echo "  Disk: $(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3,$2,$5}')"

    echo -e "\n${BLUE}Recent Alerts:${NC}"
    if [ -f "$ALERT_LOG" ]; then
        tail -5 "$ALERT_LOG" || echo "  No recent alerts"
    else
        echo "  No alert log found"
    fi
}

# Function to show help
show_help() {
    cat << EOF
PRS Production Log Monitoring Script

Usage: $0 [COMMAND]

Commands:
    start                   Start continuous monitoring
    check                   Run monitoring checks once
    status                  Show monitoring status
    help                    Show this help message

Environment Variables:
    ERROR_THRESHOLD         Number of errors to trigger alert (default: 5)
    TIME_WINDOW            Time window in seconds (default: 300)
    CHECK_INTERVAL         Check interval in seconds (default: 60)
    WEBHOOK_URL            Slack/Discord webhook URL for alerts
    EMAIL_TO               Email address for alerts
    ENABLE_ALERTS          Enable/disable alerts (default: true)

Examples:
    $0 start               # Start continuous monitoring
    $0 check               # Run checks once
    $0 status              # Show current status
EOF
}

# Main script logic
case "${1:-help}" in
    start)
        start_monitoring
        ;;
    check)
        run_monitoring_checks
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
