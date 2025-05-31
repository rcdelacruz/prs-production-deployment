#!/bin/bash
# PRS Single Node Backup Script
# Simple backup solution for single node deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Configuration
BACKUP_DIR="${BACKUPS_PATH:-/mnt/nas/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="prs_onprem_backup_$TIMESTAMP"

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check if backup directory exists
ensure_backup_directory() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
}

# Database backup
backup_database() {
    log "Creating database backup..."
    
    # Check if PostgreSQL container is running
    if ! docker ps | grep -q "prs-postgres"; then
        log_error "PostgreSQL container is not running"
        return 1
    fi
    
    # Create database backup
    if docker exec prs-postgres pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" | gzip > "$BACKUP_DIR/${BACKUP_NAME}_db.sql.gz"; then
        log_success "Database backup completed: ${BACKUP_NAME}_db.sql.gz"
        return 0
    else
        log_error "Database backup failed"
        return 1
    fi
}

# File system backup
backup_files() {
    log "Creating file system backup..."
    
    # Backup uploaded files from NAS
    if [[ -d "/mnt/nas/uploads" ]]; then
        if tar -czf "$BACKUP_DIR/${BACKUP_NAME}_uploads.tar.gz" -C /mnt/nas uploads/ 2>/dev/null; then
            log_success "Uploads backup completed: ${BACKUP_NAME}_uploads.tar.gz"
        else
            log_error "Uploads backup failed"
            return 1
        fi
    else
        log_warning "Uploads directory not found: /mnt/nas/uploads"
    fi
    
    # Backup logs
    if [[ -d "/mnt/nas/logs" ]]; then
        if tar -czf "$BACKUP_DIR/${BACKUP_NAME}_logs.tar.gz" -C /mnt/nas logs/ 2>/dev/null; then
            log_success "Logs backup completed: ${BACKUP_NAME}_logs.tar.gz"
        else
            log_warning "Logs backup failed (non-critical)"
        fi
    fi
    
    return 0
}

# Configuration backup
backup_configs() {
    log "Creating configuration backup..."
    
    # Create temporary directory for configs
    temp_config_dir="/tmp/config_backup_$TIMESTAMP"
    mkdir -p "$temp_config_dir"
    
    # Copy configuration files (excluding sensitive data)
    cp "$PROJECT_DIR/.env.example" "$temp_config_dir/" 2>/dev/null || true
    cp "$PROJECT_DIR/docker-compose.yml" "$temp_config_dir/" 2>/dev/null || true
    cp -r "$PROJECT_DIR/nginx/" "$temp_config_dir/" 2>/dev/null || true
    cp -r "$PROJECT_DIR/config/" "$temp_config_dir/" 2>/dev/null || true
    
    # Create sanitized .env file (remove sensitive values)
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        # Remove passwords and secrets from backup
        sed -E 's/(PASSWORD|SECRET|KEY)=.*/\1=REDACTED/' "$PROJECT_DIR/.env" > "$temp_config_dir/.env.sanitized" 2>/dev/null || true
    fi
    
    # Create configuration backup
    if tar -czf "$BACKUP_DIR/${BACKUP_NAME}_configs.tar.gz" -C /tmp "config_backup_$TIMESTAMP" 2>/dev/null; then
        log_success "Configuration backup completed: ${BACKUP_NAME}_configs.tar.gz"
    else
        log_error "Configuration backup failed"
        return 1
    fi
    
    # Cleanup temporary directory
    rm -rf "$temp_config_dir"
    return 0
}

# Encrypt backup (optional)
encrypt_backup() {
    local file=$1
    
    if [[ -n "$BACKUP_ENCRYPTION_KEY" && -f "$file" ]]; then
        log "Encrypting backup: $(basename "$file")"
        
        if echo "$BACKUP_ENCRYPTION_KEY" | gpg --symmetric --cipher-algo AES256 --batch --yes --passphrase-fd 0 --output "${file}.gpg" "$file" 2>/dev/null; then
            rm "$file"
            log_success "Encrypted: $(basename "$file").gpg"
            return 0
        else
            log_error "Failed to encrypt: $(basename "$file")"
            return 1
        fi
    fi
    
    return 0
}

# Clean old backups
cleanup_old_backups() {
    log "Cleaning up old backups (keeping last $RETENTION_DAYS days)..."
    
    # Remove local backups older than retention period
    find "$BACKUP_DIR" -name "prs_onprem_backup_*.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "prs_onprem_backup_*.gpg" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    
    # Count remaining backups
    backup_count=$(find "$BACKUP_DIR" -name "prs_onprem_backup_*" | wc -l)
    log_success "Cleanup completed. $backup_count backups remaining."
}

# Verify backup integrity
verify_backup() {
    local backup_file=$1
    
    if [[ "$backup_file" == *.gpg ]]; then
        if echo "$BACKUP_ENCRYPTION_KEY" | gpg --quiet --batch --decrypt --passphrase-fd 0 "$backup_file" > /dev/null 2>&1; then
            log_success "Backup verified: $(basename "$backup_file")"
            return 0
        else
            log_error "Backup verification failed: $(basename "$backup_file")"
            return 1
        fi
    elif [[ "$backup_file" == *.gz ]]; then
        if gunzip -t "$backup_file" 2>/dev/null; then
            log_success "Backup verified: $(basename "$backup_file")"
            return 0
        else
            log_error "Backup verification failed: $(basename "$backup_file")"
            return 1
        fi
    fi
    
    return 0
}

# Main backup process
main_backup() {
    log "Starting PRS Single Node backup process..."
    
    ensure_backup_directory
    
    local backup_files=()
    local failed=false
    
    # Database backup
    if backup_database; then
        backup_files+=("$BACKUP_DIR/${BACKUP_NAME}_db.sql.gz")
    else
        failed=true
    fi
    
    # File system backup
    if backup_files; then
        if [[ -f "$BACKUP_DIR/${BACKUP_NAME}_uploads.tar.gz" ]]; then
            backup_files+=("$BACKUP_DIR/${BACKUP_NAME}_uploads.tar.gz")
        fi
        if [[ -f "$BACKUP_DIR/${BACKUP_NAME}_logs.tar.gz" ]]; then
            backup_files+=("$BACKUP_DIR/${BACKUP_NAME}_logs.tar.gz")
        fi
    else
        failed=true
    fi
    
    # Configuration backup
    if backup_configs; then
        backup_files+=("$BACKUP_DIR/${BACKUP_NAME}_configs.tar.gz")
    else
        failed=true
    fi
    
    # Encrypt backups if encryption is enabled
    if [[ -n "$BACKUP_ENCRYPTION_KEY" ]]; then
        for file in "${backup_files[@]}"; do
            if [[ -f "$file" ]]; then
                encrypt_backup "$file"
            fi
        done
    fi
    
    # Verify backups
    for file in "${backup_files[@]}"; do
        if [[ -n "$BACKUP_ENCRYPTION_KEY" ]]; then
            verify_backup "${file}.gpg"
        else
            verify_backup "$file"
        fi
    done
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Calculate total backup size
    if [[ -n "$BACKUP_ENCRYPTION_KEY" ]]; then
        backup_size=$(du -sh "$BACKUP_DIR"/${BACKUP_NAME}_*.gpg 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "Unknown")
    else
        backup_size=$(du -sh "$BACKUP_DIR"/${BACKUP_NAME}_*.gz 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "Unknown")
    fi
    
    if [[ "$failed" == "true" ]]; then
        log_error "Backup process completed with errors"
        exit 1
    else
        log_success "Backup process completed successfully"
        log "Backup size: $backup_size"
        log "Backup location: $BACKUP_DIR"
    fi
}

# Restore function
restore_backup() {
    local backup_file=$1
    
    if [[ -z "$backup_file" ]]; then
        echo "Usage: $0 --restore <backup_file>"
        echo "Example: $0 --restore /mnt/nas/backups/prs_onprem_backup_20231201_120000_db.sql.gz"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log "Starting restore process from: $(basename "$backup_file")"
    
    # Decrypt if needed
    temp_file="$backup_file"
    if [[ "$backup_file" == *.gpg ]]; then
        log "Decrypting backup file..."
        temp_file="/tmp/restore_$(basename "${backup_file%.gpg}")"
        
        if echo "$BACKUP_ENCRYPTION_KEY" | gpg --decrypt --batch --passphrase-fd 0 "$backup_file" > "$temp_file" 2>/dev/null; then
            log_success "Backup decrypted successfully"
        else
            log_error "Failed to decrypt backup file"
            exit 1
        fi
    fi
    
    # Determine backup type and restore
    if [[ "$(basename "$temp_file")" == *_db.sql.gz ]]; then
        log "Restoring database..."
        if docker exec -i prs-postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" < <(zcat "$temp_file") 2>/dev/null; then
            log_success "Database restore completed"
        else
            log_error "Database restore failed"
            exit 1
        fi
    elif [[ "$(basename "$temp_file")" == *_uploads.tar.gz ]]; then
        log "Restoring uploaded files..."
        if tar -xzf "$temp_file" -C /mnt/nas/ 2>/dev/null; then
            log_success "Files restore completed"
        else
            log_error "Files restore failed"
            exit 1
        fi
    elif [[ "$(basename "$temp_file")" == *_configs.tar.gz ]]; then
        log "Restoring configuration files..."
        temp_extract_dir="/tmp/config_restore_$$"
        mkdir -p "$temp_extract_dir"
        
        if tar -xzf "$temp_file" -C "$temp_extract_dir" 2>/dev/null; then
            log_success "Configuration restore completed"
            log "Extracted to: $temp_extract_dir"
            log "Please manually review and copy needed files"
        else
            log_error "Configuration restore failed"
            exit 1
        fi
    else
        log_error "Unknown backup type: $(basename "$temp_file")"
        exit 1
    fi
    
    # Cleanup temporary file if it was decrypted
    if [[ "$temp_file" != "$backup_file" ]]; then
        rm -f "$temp_file"
    fi
}

# List available backups
list_backups() {
    log "Available backups in $BACKUP_DIR:"
    echo ""
    
    if [[ -d "$BACKUP_DIR" ]]; then
        # Group backups by timestamp
        for backup_group in $(find "$BACKUP_DIR" -name "prs_onprem_backup_*" | sed 's/.*prs_onprem_backup_\([0-9]*_[0-9]*\).*/\1/' | sort -u); do
            echo -e "${BLUE}Backup Set: $backup_group${NC}"
            find "$BACKUP_DIR" -name "prs_onprem_backup_${backup_group}*" -exec ls -lh {} \; | awk '{print "  " $9 " (" $5 ")"}'
            echo ""
        done
    else
        log_error "Backup directory not found: $BACKUP_DIR"
    fi
}

# Show help
show_help() {
    echo -e "${BLUE}PRS Single Node Backup Script${NC}"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --backup                   Perform full backup"
    echo "  --restore <file>           Restore from backup file"
    echo "  --list                     List available backups"
    echo "  --cleanup                  Clean old backups only"
    echo "  --help                     Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --backup               # Perform full backup"
    echo "  $0 --restore /mnt/nas/backups/prs_onprem_backup_20231201_120000_db.sql.gz"
    echo "  $0 --list                 # List all backups"
    echo ""
    echo "Configuration:"
    echo "  BACKUP_DIR: $BACKUP_DIR"
    echo "  RETENTION_DAYS: $RETENTION_DAYS"
    echo "  ENCRYPTION: $(if [[ -n "$BACKUP_ENCRYPTION_KEY" ]]; then echo "Enabled"; else echo "Disabled"; fi)"
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
    --help|*)
        show_help
        ;;
esac
