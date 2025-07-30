#!/bin/bash

# Redis Management Script for PRS EC2 Production
# This script provides utilities for managing Redis in production

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

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}Error: .env file not found at $ENV_FILE${NC}"
    exit 1
fi

# Default values
REDIS_CONTAINER_NAME="${REDIS_CONTAINER_NAME:-prs-ec2-redis}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Redis container is running
check_redis_status() {
    if docker ps --format "table {{.Names}}" | grep -q "^${REDIS_CONTAINER_NAME}$"; then
        return 0
    else
        return 1
    fi
}

# Function to get Redis info
redis_info() {
    print_status "Getting Redis information..."
    
    if ! check_redis_status; then
        print_error "Redis container is not running"
        return 1
    fi
    
    echo -e "\n${BLUE}=== Redis Container Status ===${NC}"
    docker ps --filter "name=${REDIS_CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${BLUE}=== Redis Server Info ===${NC}"
    if [ -n "$REDIS_PASSWORD" ]; then
        docker exec "$REDIS_CONTAINER_NAME" redis-cli --no-auth-warning -a "$REDIS_PASSWORD" info server
    else
        docker exec "$REDIS_CONTAINER_NAME" redis-cli info server
    fi
    
    echo -e "\n${BLUE}=== Redis Memory Usage ===${NC}"
    if [ -n "$REDIS_PASSWORD" ]; then
        docker exec "$REDIS_CONTAINER_NAME" redis-cli --no-auth-warning -a "$REDIS_PASSWORD" info memory
    else
        docker exec "$REDIS_CONTAINER_NAME" redis-cli info memory
    fi
}

# Function to check Redis connectivity
redis_ping() {
    print_status "Testing Redis connectivity..."
    
    if ! check_redis_status; then
        print_error "Redis container is not running"
        return 1
    fi
    
    if [ -n "$REDIS_PASSWORD" ]; then
        if docker exec "$REDIS_CONTAINER_NAME" redis-cli --no-auth-warning -a "$REDIS_PASSWORD" ping > /dev/null 2>&1; then
            print_success "Redis is responding to ping"
            return 0
        else
            print_error "Redis is not responding to ping"
            return 1
        fi
    else
        if docker exec "$REDIS_CONTAINER_NAME" redis-cli ping > /dev/null 2>&1; then
            print_success "Redis is responding to ping"
            return 0
        else
            print_error "Redis is not responding to ping"
            return 1
        fi
    fi
}

# Function to monitor Redis queues
monitor_queues() {
    print_status "Monitoring Redis queues..."
    
    if ! check_redis_status; then
        print_error "Redis container is not running"
        return 1
    fi
    
    echo -e "\n${BLUE}=== BullMQ Queue Status ===${NC}"
    
    # Check for BullMQ queue keys
    if [ -n "$REDIS_PASSWORD" ]; then
        QUEUE_KEYS=$(docker exec "$REDIS_CONTAINER_NAME" redis-cli --no-auth-warning -a "$REDIS_PASSWORD" keys "bull:prs-data-sync:*" 2>/dev/null || echo "")
    else
        QUEUE_KEYS=$(docker exec "$REDIS_CONTAINER_NAME" redis-cli keys "bull:prs-data-sync:*" 2>/dev/null || echo "")
    fi
    
    if [ -n "$QUEUE_KEYS" ]; then
        echo "Found queue keys:"
        echo "$QUEUE_KEYS"
        
        # Get queue stats
        echo -e "\n${BLUE}=== Queue Statistics ===${NC}"
        if [ -n "$REDIS_PASSWORD" ]; then
            docker exec "$REDIS_CONTAINER_NAME" redis-cli --no-auth-warning -a "$REDIS_PASSWORD" eval "
                local waiting = redis.call('llen', 'bull:prs-data-sync:waiting')
                local active = redis.call('llen', 'bull:prs-data-sync:active')
                local completed = redis.call('llen', 'bull:prs-data-sync:completed')
                local failed = redis.call('llen', 'bull:prs-data-sync:failed')
                return 'Waiting: ' .. waiting .. ', Active: ' .. active .. ', Completed: ' .. completed .. ', Failed: ' .. failed
            " 0
        else
            docker exec "$REDIS_CONTAINER_NAME" redis-cli eval "
                local waiting = redis.call('llen', 'bull:prs-data-sync:waiting')
                local active = redis.call('llen', 'bull:prs-data-sync:active')
                local completed = redis.call('llen', 'bull:prs-data-sync:completed')
                local failed = redis.call('llen', 'bull:prs-data-sync:failed')
                return 'Waiting: ' .. waiting .. ', Active: ' .. active .. ', Completed: ' .. completed .. ', Failed: ' .. failed
            " 0
        fi
    else
        print_warning "No BullMQ queue keys found. This might be normal if no jobs have been queued yet."
    fi
}

# Function to clear Redis queues (use with caution)
clear_queues() {
    print_warning "This will clear all Redis queues. This action cannot be undone."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled"
        return 0
    fi
    
    if ! check_redis_status; then
        print_error "Redis container is not running"
        return 1
    fi
    
    print_status "Clearing Redis queues..."
    
    if [ -n "$REDIS_PASSWORD" ]; then
        docker exec "$REDIS_CONTAINER_NAME" redis-cli --no-auth-warning -a "$REDIS_PASSWORD" eval "
            local keys = redis.call('keys', 'bull:prs-data-sync:*')
            for i=1,#keys do
                redis.call('del', keys[i])
            end
            return #keys
        " 0
    else
        docker exec "$REDIS_CONTAINER_NAME" redis-cli eval "
            local keys = redis.call('keys', 'bull:prs-data-sync:*')
            for i=1,#keys do
                redis.call('del', keys[i])
            end
            return #keys
        " 0
    fi
    
    print_success "Redis queues cleared"
}

# Function to backup Redis data
backup_redis() {
    print_status "Creating Redis backup..."
    
    if ! check_redis_status; then
        print_error "Redis container is not running"
        return 1
    fi
    
    BACKUP_DIR="$PROJECT_DIR/backups"
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_FILE="$BACKUP_DIR/redis_backup_$(date +%Y%m%d_%H%M%S).rdb"
    
    # Trigger a background save
    if [ -n "$REDIS_PASSWORD" ]; then
        docker exec "$REDIS_CONTAINER_NAME" redis-cli --no-auth-warning -a "$REDIS_PASSWORD" bgsave
    else
        docker exec "$REDIS_CONTAINER_NAME" redis-cli bgsave
    fi
    
    # Wait for save to complete
    sleep 2
    
    # Copy the dump file
    docker cp "$REDIS_CONTAINER_NAME:/data/dump.rdb" "$BACKUP_FILE"
    
    if [ -f "$BACKUP_FILE" ]; then
        print_success "Redis backup created: $BACKUP_FILE"
    else
        print_error "Failed to create Redis backup"
        return 1
    fi
}

# Function to show Redis logs
show_logs() {
    print_status "Showing Redis logs..."
    
    if ! check_redis_status; then
        print_error "Redis container is not running"
        return 1
    fi
    
    docker logs --tail 50 -f "$REDIS_CONTAINER_NAME"
}

# Function to restart Redis
restart_redis() {
    print_status "Restarting Redis container..."
    
    cd "$PROJECT_DIR"
    docker-compose restart redis
    
    # Wait for Redis to be ready
    sleep 5
    
    if redis_ping; then
        print_success "Redis restarted successfully"
    else
        print_error "Redis restart failed or not responding"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Redis Management Script for PRS EC2 Production"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  info          Show Redis server information and status"
    echo "  ping          Test Redis connectivity"
    echo "  monitor       Monitor Redis queues and job status"
    echo "  clear         Clear all Redis queues (use with caution)"
    echo "  backup        Create a backup of Redis data"
    echo "  logs          Show Redis container logs"
    echo "  restart       Restart Redis container"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 info       # Show Redis information"
    echo "  $0 monitor   # Monitor queue status"
    echo "  $0 backup    # Create Redis backup"
}

# Main script logic
case "${1:-help}" in
    "info")
        redis_info
        ;;
    "ping")
        redis_ping
        ;;
    "monitor")
        monitor_queues
        ;;
    "clear")
        clear_queues
        ;;
    "backup")
        backup_redis
        ;;
    "logs")
        show_logs
        ;;
    "restart")
        restart_redis
        ;;
    "help"|*)
        show_help
        ;;
esac
