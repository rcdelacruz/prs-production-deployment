#!/bin/bash

# PRS Production Log Management Script
# This script provides utilities for managing production logs

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_RETENTION_DAYS=${LOG_RETENTION_DAYS:-7}
LOG_MAX_SIZE=${LOG_MAX_SIZE:-100m}

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

# Function to show log statistics
show_log_stats() {
    log "📊 Production Log Statistics"
    echo "=================================="
    
    # Docker container logs
    echo -e "\n${BLUE}Docker Container Logs:${NC}"
    for container in prs-ec2-backend prs-ec2-nginx prs-ec2-postgres-timescale; do
        if docker ps -q -f name=$container > /dev/null 2>&1; then
            log_size=$(docker logs $container 2>&1 | wc -c | numfmt --to=iec)
            log_lines=$(docker logs $container 2>&1 | wc -l)
            echo "  $container: $log_lines lines, $log_size"
        else
            warning "  $container: Container not running"
        fi
    done
    
    # Application logs directory
    if [ -d "$PROJECT_DIR/logs" ]; then
        echo -e "\n${BLUE}Application Log Files:${NC}"
        find "$PROJECT_DIR/logs" -name "*.log" -type f -exec ls -lh {} \; | awk '{print "  " $9 ": " $5}'
    fi
    
    # Docker system logs usage
    echo -e "\n${BLUE}Docker System Log Usage:${NC}"
    docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}"
}

# Function to tail logs in real-time
tail_logs() {
    local service=${1:-all}
    
    case $service in
        backend|be)
            log "📋 Tailing backend logs..."
            docker logs -f prs-ec2-backend
            ;;
        nginx)
            log "📋 Tailing nginx logs..."
            docker logs -f prs-ec2-nginx
            ;;
        postgres|db)
            log "📋 Tailing postgres logs..."
            docker logs -f prs-ec2-postgres-timescale
            ;;
        all)
            log "📋 Tailing all service logs..."
            docker-compose -f "$PROJECT_DIR/docker-compose.yml" logs -f backend nginx postgres
            ;;
        *)
            error "Unknown service: $service"
            echo "Available services: backend, nginx, postgres, all"
            exit 1
            ;;
    esac
}

# Function to search logs for errors
search_errors() {
    local hours=${1:-1}
    local since_time=$(date -d "$hours hours ago" --iso-8601=seconds)
    
    log "🔍 Searching for errors in the last $hours hour(s)..."
    echo "=================================="
    
    # Search backend logs for errors
    echo -e "\n${RED}Backend Errors:${NC}"
    docker logs prs-ec2-backend --since="$since_time" 2>&1 | grep -i -E "(error|500|internal server error|exception)" | tail -20
    
    # Search nginx logs for 5xx errors
    echo -e "\n${RED}Nginx 5xx Errors:${NC}"
    docker logs prs-ec2-nginx --since="$since_time" 2>&1 | grep -E " 5[0-9][0-9] " | tail -20
    
    # Search postgres logs for errors
    echo -e "\n${RED}Database Errors:${NC}"
    docker logs prs-ec2-postgres-timescale --since="$since_time" 2>&1 | grep -i -E "(error|fatal|panic)" | tail -20
}

# Function to export logs for analysis
export_logs() {
    local output_dir="$PROJECT_DIR/log-exports/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    log "📦 Exporting logs to: $output_dir"
    
    # Export container logs
    for container in prs-ec2-backend prs-ec2-nginx prs-ec2-postgres-timescale; do
        if docker ps -q -f name=$container > /dev/null 2>&1; then
            info "Exporting $container logs..."
            docker logs $container > "$output_dir/${container}.log" 2>&1
        fi
    done
    
    # Export application logs if they exist
    if [ -d "$PROJECT_DIR/logs" ]; then
        info "Copying application logs..."
        cp -r "$PROJECT_DIR/logs" "$output_dir/app-logs"
    fi
    
    # Create summary
    cat > "$output_dir/export-summary.txt" << EOF
Log Export Summary
==================
Export Date: $(date)
Export Directory: $output_dir
System Info: $(uname -a)
Docker Version: $(docker --version)
Compose Version: $(docker-compose --version)

Container Status:
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

System Resources:
$(free -h)
$(df -h)
EOF
    
    log "✅ Log export completed: $output_dir"
}

# Function to clean old logs
cleanup_logs() {
    log "🧹 Cleaning up old logs (older than $LOG_RETENTION_DAYS days)..."
    
    # Clean application logs
    if [ -d "$PROJECT_DIR/logs" ]; then
        find "$PROJECT_DIR/logs" -name "*.log" -type f -mtime +$LOG_RETENTION_DAYS -delete
        info "Cleaned application logs older than $LOG_RETENTION_DAYS days"
    fi
    
    # Clean log exports
    if [ -d "$PROJECT_DIR/log-exports" ]; then
        find "$PROJECT_DIR/log-exports" -type d -mtime +$LOG_RETENTION_DAYS -exec rm -rf {} +
        info "Cleaned log exports older than $LOG_RETENTION_DAYS days"
    fi
    
    # Clean Docker logs (this requires stopping and starting containers)
    warning "Docker container logs are managed by Docker's logging driver"
    warning "Configure max-size and max-file in docker-compose.yml for automatic rotation"
    
    log "✅ Log cleanup completed"
}

# Function to show help
show_help() {
    cat << EOF
PRS Production Log Management Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    stats                   Show log statistics and usage
    tail [SERVICE]         Tail logs in real-time (backend|nginx|postgres|all)
    search [HOURS]         Search for errors in the last N hours (default: 1)
    export                 Export all logs for analysis
    cleanup                Clean up old logs based on retention policy
    help                   Show this help message

Examples:
    $0 stats               # Show log statistics
    $0 tail backend        # Tail backend logs
    $0 search 24           # Search for errors in last 24 hours
    $0 export              # Export all logs
    $0 cleanup             # Clean up old logs

Environment Variables:
    LOG_RETENTION_DAYS     Number of days to keep logs (default: 7)
    LOG_MAX_SIZE          Maximum size per log file (default: 100m)
EOF
}

# Main script logic
case "${1:-help}" in
    stats)
        show_log_stats
        ;;
    tail)
        tail_logs "$2"
        ;;
    search)
        search_errors "${2:-1}"
        ;;
    export)
        export_logs
        ;;
    cleanup)
        cleanup_logs
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
