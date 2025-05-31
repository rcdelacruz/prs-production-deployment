#!/bin/bash

# Automated Backup Script for Production Environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="/backups"
RETENTION_DAYS=30
S3_BUCKET="prs-backups-$(date +%Y)"
STACK_NAME="prs-production"

# Create timestamped backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="prs_backup_$TIMESTAMP"

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a /var/log/backup.log
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a /var/log/backup.log
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}" | tee -a /var/log/backup.log
}

# Database backup
function backup_database {
    log "Creating database backup..."
    
    # Get the PostgreSQL container
    postgres_container=$(docker ps --filter "name=${STACK_NAME}_postgres-primary" --format "{{.ID}}" | head -n1)
    
    if [[ -z "$postgres_container" ]]; then
        log_error "PostgreSQL container not found"
        return 1
    fi
    
    # Create database backup
    if docker exec "$postgres_container" pg_dump -U $POSTGRES_USER $POSTGRES_DB | gzip > "$BACKUP_DIR/${BACKUP_NAME}_db.sql.gz"; then
        log_success "Database backup completed: ${BACKUP_NAME}_db.sql.gz"
    else
        log_error "Database backup failed"
        return 1
    fi
}

# File system backup
function backup_files {
    log "Creating file system backup..."
    
    # Backup uploaded files
    if tar -czf "$BACKUP_DIR/${BACKUP_NAME}_files.tar.gz" \
        /var/lib/docker/volumes/${STACK_NAME}_upload_files/_data/ 2>/dev/null; then
        log_success "File system backup completed: ${BACKUP_NAME}_files.tar.gz"
    else
        log_error "File system backup failed"
        return 1
    fi
}

# Configuration backup
function backup_configs {
    log "Creating configuration backup..."
    
    # Create temporary directory for configs
    temp_config_dir="/tmp/config_backup_$TIMESTAMP"
    mkdir -p "$temp_config_dir"
    
    # Copy configuration files
    cp .env.production "$temp_config_dir/" 2>/dev/null || true
    cp backend.prod.env "$temp_config_dir/" 2>/dev/null || true
    cp frontend.prod.env "$temp_config_dir/" 2>/dev/null || true
    cp -r nginx/ "$temp_config_dir/" 2>/dev/null || true
    cp -r monitoring/ "$temp_config_dir/" 2>/dev/null || true
    cp -r k8s/ "$temp_config_dir/" 2>/dev/null || true
    cp -r compose/ "$temp_config_dir/" 2>/dev/null || true
    
    # Create configuration backup
    if tar -czf "$BACKUP_DIR/${BACKUP_NAME}_configs.tar.gz" -C /tmp "config_backup_$TIMESTAMP"; then
        log_success "Configuration backup completed: ${BACKUP_NAME}_configs.tar.gz"
    else
        log_error "Configuration backup failed"
        return 1
    fi
    
    # Cleanup temporary directory
    rm -rf "$temp_config_dir"
}

# Docker volumes backup
function backup_volumes {
    log "Creating Docker volumes backup..."
    
    # Backup important volumes
    volumes=(
        "${STACK_NAME}_postgres_data"
        "${STACK_NAME}_grafana_data"
        "${STACK_NAME}_prometheus_data"
        "${STACK_NAME}_loki_data"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume inspect "$volume" &>/dev/null; then
            log "Backing up volume: $volume"
            docker run --rm -v "$volume":/volume -v "$BACKUP_DIR":/backup alpine \
                tar -czf "/backup/${BACKUP_NAME}_${volume##*_}.tar.gz" -C /volume . 2>/dev/null || true
        fi
    done
    
    log_success "Docker volumes backup completed"
}

# Encrypt backups
function encrypt_backups {
    log "Encrypting backups..."
    
    # Check if encryption key exists
    if [[ ! -f "/run/secrets/backup_encryption_key" ]]; then
        log_error "Backup encryption key not found"
        return 1
    fi
    
    for file in "$BACKUP_DIR/${BACKUP_NAME}_"*.{sql.gz,tar.gz}; do
        if [[ -f "$file" ]]; then
            log "Encrypting: $(basename "$file")"
            if gpg --symmetric --cipher-algo AES256 --batch --yes \
                --passphrase-file "/run/secrets/backup_encryption_key" \
                --output "${file}.gpg" "$file"; then
                rm "$file"
                log_success "Encrypted: $(basename "$file").gpg"
            else
                log_error "Failed to encrypt: $(basename "$file")"
            fi
        fi
    done
    
    log_success "Backup encryption completed"
}

# Upload to cloud storage
function upload_to_cloud {
    log "Uploading backups to cloud storage..."
    
    # Check if AWS CLI is available and configured
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found, skipping cloud upload"
        return 1
    fi
    
    # Create S3 bucket if it doesn't exist
    if ! aws s3 ls "s3://$S3_BUCKET" &>/dev/null; then
        log "Creating S3 bucket: $S3_BUCKET"
        aws s3 mb "s3://$S3_BUCKET"
    fi
    
    # Upload encrypted backups to S3
    for file in "$BACKUP_DIR/${BACKUP_NAME}_"*.gpg; do
        if [[ -f "$file" ]]; then
            log "Uploading: $(basename "$file")"
            if aws s3 cp "$file" "s3://$S3_BUCKET/daily/$(basename "$file")"; then
                log_success "Uploaded: $(basename "$file")"
            else
                log_error "Failed to upload: $(basename "$file")"
            fi
        fi
    done
    
    log_success "Cloud upload completed"
}

# Clean old backups
function cleanup_old_backups {
    log "Cleaning up old backups..."
    
    # Remove local backups older than retention period
    find "$BACKUP_DIR" -name "prs_backup_*.gpg" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    
    # Remove old S3 backups if AWS CLI is available
    if command -v aws &> /dev/null; then
        cutoff_date=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)
        
        aws s3 ls "s3://$S3_BUCKET/daily/" | while read -r line; do
            file_date=$(echo "$line" | awk '{print $1}')
            file_name=$(echo "$line" | awk '{print $4}')
            
            if [[ "$file_date" < "$cutoff_date" ]]; then
                log "Removing old backup: $file_name"
                aws s3 rm "s3://$S3_BUCKET/daily/$file_name"
            fi
        done
    fi
    
    log_success "Cleanup completed"
}

# Verify backup integrity
function verify_backups {
    log "Verifying backup integrity..."
    
    for file in "$BACKUP_DIR/${BACKUP_NAME}_"*.gpg; do
        if [[ -f "$file" ]]; then
            if gpg --quiet --batch --decrypt --passphrase-file "/run/secrets/backup_encryption_key" \
                "$file" > /dev/null 2>&1; then
                log_success "Backup verified: $(basename "$file")"
            else
                log_error "Backup verification failed: $(basename "$file")"
                return 1
            fi
        fi
    done
    
    log_success "All backups verified successfully"
}

# Send notification
function send_notification {
    local status=$1
    local message=$2
    
    # Send to Slack if webhook is configured
    if [[ -f "/run/secrets/alertmanager_slack_webhook" ]]; then
        webhook_url=$(cat /run/secrets/alertmanager_slack_webhook)
        
        if [[ "$status" == "success" ]]; then
            color="good"
        else
            color="danger"
        fi
        
        payload=$(cat <<EOF
{
    "attachments": [
        {
            "color": "$color",
            "title": "PRS Production Backup $status",
            "text": "$message",
            "fields": [
                {
                    "title": "Environment",
                    "value": "Production",
                    "short": true
                },
                {
                    "title": "Timestamp",
                    "value": "$TIMESTAMP",
                    "short": true
                }
            ]
        }
    ]
}
EOF
        )
        
        curl -X POST -H 'Content-type: application/json' \
            --data "$payload" "$webhook_url" &>/dev/null || true
    fi
}

# Health check before backup
function health_check {
    log "Performing health check before backup..."
    
    # Check if Docker services are running
    if ! docker stack services "$STACK_NAME" --format "{{.Replicas}}" | grep -q "0/"; then
        log_success "All services are running"
        return 0
    else
        log_error "Some services are not running, aborting backup"
        return 1
    fi
}

# Main backup process
function main_backup {
    log "Starting backup process"
    
    # Ensure backup directory exists
    mkdir -p "$BACKUP_DIR"
    
    # Perform health check
    if ! health_check; then
        send_notification "failed" "Backup aborted due to health check failure"
        exit 1
    fi
    
    # Run backup functions
    if backup_database && backup_files && backup_configs && backup_volumes; then
        log_success "All backup operations completed successfully"
        
        # Encrypt backups
        if encrypt_backups; then
            # Verify backup integrity
            if verify_backups; then
                # Upload to cloud
                upload_to_cloud
                
                # Cleanup old backups
                cleanup_old_backups
                
                # Calculate backup size
                backup_size=$(du -sh "$BACKUP_DIR/${BACKUP_NAME}_"*.gpg 2>/dev/null | awk '{total+=$1} END {print total}' || echo "Unknown")
                
                log_success "Backup process completed successfully"
                send_notification "success" "Backup completed successfully. Size: $backup_size"
            else
                log_error "Backup verification failed"
                send_notification "failed" "Backup verification failed"
                exit 1
            fi
        else
            log_error "Backup encryption failed"
            send_notification "failed" "Backup encryption failed"
            exit 1
        fi
    else
        log_error "One or more backup operations failed"
        send_notification "failed" "Backup process failed"
        exit 1
    fi
}

# Restore function
function restore_backup {
    local backup_file=$1
    
    if [[ -z "$backup_file" ]]; then
        echo "Usage: $0 --restore <backup_file>"
        exit 1
    fi
    
    log "Starting restore process from: $backup_file"
    
    # Decrypt backup
    if [[ "$backup_file" == *.gpg ]]; then
        log "Decrypting backup file..."
        decrypted_file="${backup_file%.gpg}"
        gpg --decrypt --batch --passphrase-file "/run/secrets/backup_encryption_key" \
            "$backup_file" > "$decrypted_file"
        backup_file="$decrypted_file"
    fi
    
    # Determine backup type and restore
    if [[ "$backup_file" == *_db.sql.gz ]]; then
        log "Restoring database..."
        postgres_container=$(docker ps --filter "name=${STACK_NAME}_postgres-primary" --format "{{.ID}}" | head -n1)
        zcat "$backup_file" | docker exec -i "$postgres_container" psql -U $POSTGRES_USER $POSTGRES_DB
        log_success "Database restore completed"
    elif [[ "$backup_file" == *_files.tar.gz ]]; then
        log "Restoring files..."
        tar -xzf "$backup_file" -C /var/lib/docker/volumes/${STACK_NAME}_upload_files/_data/
        log_success "Files restore completed"
    else
        log_error "Unknown backup type: $backup_file"
        exit 1
    fi
}

# Display help
function show_help {
    echo -e "${BLUE}PRS Production Backup Script${NC}"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --backup                   Perform full backup"
    echo "  --restore <file>           Restore from backup file"
    echo "  --list                     List available backups"
    echo "  --cleanup                  Clean old backups"
    echo "  --verify <file>            Verify backup integrity"
    echo "  --help                     Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --backup               # Perform full backup"
    echo "  $0 --restore backup.sql.gz # Restore database"
    echo "  $0 --list                 # List backups"
}

# List backups
function list_backups {
    echo -e "${BLUE}Local backups:${NC}"
    ls -lh "$BACKUP_DIR"/prs_backup_* 2>/dev/null || echo "No local backups found"
    
    echo -e "\n${BLUE}Cloud backups:${NC}"
    if command -v aws &> /dev/null; then
        aws s3 ls "s3://$S3_BUCKET/daily/" 2>/dev/null || echo "No cloud backups found or AWS CLI not configured"
    else
        echo "AWS CLI not available"
    fi
}

# Parse command line arguments
case "${1:-}" in
    --backup)
        main_backup
        ;;
    --restore)
        restore_backup "$2"
        ;;
    --list)
        list_backups
        ;;
    --cleanup)
        cleanup_old_backups
        ;;
    --verify)
        if [[ -n "$2" ]]; then
            verify_backups "$2"
        else
            echo "Please specify backup file to verify"
            exit 1
        fi
        ;;
    --help|*)
        show_help
        ;;
esac
