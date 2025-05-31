#!/bin/bash

# PRS On-Premises Single Node Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

# Function to display colored output
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons"
        log "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        log_error "Current user is not in the docker group"
        log "Run: sudo usermod -aG docker $USER"
        log "Then log out and log back in"
        exit 1
    fi
    
    # Check if .env file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error "Environment file not found: $ENV_FILE"
        log "Copy .env.example to .env and configure it first"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Function to load environment variables
load_env() {
    if [[ -f "$ENV_FILE" ]]; then
        set -a
        source "$ENV_FILE"
        set +a
        log_success "Environment variables loaded"
    else
        log_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
}

# Function to setup NAS storage
setup_storage() {
    log "Setting up NAS storage..."
    
    # Create mount point
    sudo mkdir -p /mnt/nas
    
    # Mount NAS based on type
    if [[ "$NAS_MOUNT_TYPE" == "nfs" ]]; then
        log "Mounting NFS share: $NAS_SERVER:/$NAS_SHARE"
        
        # Install NFS client if not present
        if ! command -v mount.nfs &> /dev/null; then
            log "Installing NFS client..."
            sudo apt update && sudo apt install -y nfs-common
        fi
        
        # Mount NFS
        if ! mountpoint -q /mnt/nas; then
            sudo mount -t nfs "$NAS_SERVER:/$NAS_SHARE" /mnt/nas
        fi
        
        # Add to fstab for persistent mounting
        if ! grep -q "/mnt/nas" /etc/fstab; then
            echo "$NAS_SERVER:/$NAS_SHARE /mnt/nas nfs defaults,auto,nofail,noatime,intr 0 0" | sudo tee -a /etc/fstab
        fi
        
    elif [[ "$NAS_MOUNT_TYPE" == "cifs" ]]; then
        log "Mounting CIFS/SMB share: //$NAS_SERVER/$NAS_SHARE"
        
        # Install CIFS client if not present
        if ! command -v mount.cifs &> /dev/null; then
            log "Installing CIFS client..."
            sudo apt update && sudo apt install -y cifs-utils
        fi
        
        # Create credentials file
        if [[ -n "$NAS_USERNAME" && -n "$NAS_PASSWORD" ]]; then
            sudo tee /etc/cifs-credentials > /dev/null <<EOF
username=$NAS_USERNAME
password=$NAS_PASSWORD
domain=workgroup
EOF
            sudo chmod 600 /etc/cifs-credentials
        fi
        
        # Mount CIFS
        if ! mountpoint -q /mnt/nas; then
            sudo mount -t cifs "//$NAS_SERVER/$NAS_SHARE" /mnt/nas -o credentials=/etc/cifs-credentials,uid=$(id -u),gid=$(id -g),iocharset=utf8
        fi
        
        # Add to fstab
        if ! grep -q "/mnt/nas" /etc/fstab; then
            echo "//$NAS_SERVER/$NAS_SHARE /mnt/nas cifs credentials=/etc/cifs-credentials,uid=$(id -u),gid=$(id -g),iocharset=utf8,nofail 0 0" | sudo tee -a /etc/fstab
        fi
    fi
    
    # Create required directories on NAS
    sudo mkdir -p /mnt/nas/{database,uploads,backups,logs/{backend,nginx}}
    sudo chown -R $(id -u):$(id -g) /mnt/nas
    
    log_success "NAS storage setup completed"
}

# Function to generate SSL certificates
setup_ssl() {
    log "Setting up SSL certificates..."
    
    mkdir -p "$PROJECT_DIR/ssl"
    
    if [[ ! -f "$PROJECT_DIR/ssl/cert.pem" ]]; then
        log "Generating self-signed SSL certificate..."
        
        # Generate DH parameters
        if [[ ! -f "$PROJECT_DIR/ssl/dhparam.pem" ]]; then
            openssl dhparam -out "$PROJECT_DIR/ssl/dhparam.pem" 2048
        fi
        
        # Generate private key
        openssl genrsa -out "$PROJECT_DIR/ssl/key.pem" 2048
        
        # Generate certificate
        openssl req -new -x509 -key "$PROJECT_DIR/ssl/key.pem" -out "$PROJECT_DIR/ssl/cert.pem" -days 365 \
            -subj "/C=PH/ST=Metro Manila/L=Quezon City/O=PRS System/CN=$DOMAIN"
        
        log_success "Self-signed SSL certificate generated"
        log_warning "For production, replace with a proper SSL certificate"
    else
        log_success "SSL certificate already exists"
    fi
}

# Function to setup basic authentication
setup_auth() {
    log "Setting up basic authentication..."
    
    # Install htpasswd if not available
    if ! command -v htpasswd &> /dev/null; then
        sudo apt update && sudo apt install -y apache2-utils
    fi
    
    # Create .htpasswd file
    mkdir -p "$PROJECT_DIR/nginx"
    echo "$ADMIN_PASSWORD" | htpasswd -i -c "$PROJECT_DIR/nginx/.htpasswd" "$ADMIN_USER"
    
    log_success "Basic authentication configured"
}

# Function to generate secure secrets
generate_secrets() {
    log "Generating application secrets..."
    
    # Backup existing .env
    if [[ -f "$ENV_FILE" ]]; then
        cp "$ENV_FILE" "$ENV_FILE.backup"
    fi
    
    # Generate secrets if they don't exist
    if grep -q "your-jwt-secret" "$ENV_FILE"; then
        JWT_SECRET=$(openssl rand -hex 32)
        sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" "$ENV_FILE"
    fi
    
    if grep -q "your-encryption-key" "$ENV_FILE"; then
        ENCRYPTION_KEY=$(openssl rand -hex 32)
        sed -i "s/ENCRYPTION_KEY=.*/ENCRYPTION_KEY=$ENCRYPTION_KEY/" "$ENV_FILE"
    fi
    
    if grep -q "your-otp-key" "$ENV_FILE"; then
        OTP_KEY=$(openssl rand -base64 32)
        sed -i "s/OTP_KEY=.*/OTP_KEY=$OTP_KEY/" "$ENV_FILE"
    fi
    
    if grep -q "your-password-secret" "$ENV_FILE"; then
        PASS_SECRET=$(openssl rand -hex 16)
        sed -i "s/PASS_SECRET=.*/PASS_SECRET=$PASS_SECRET/" "$ENV_FILE"
    fi
    
    if grep -q "backup-encryption-key" "$ENV_FILE"; then
        BACKUP_KEY=$(openssl rand -hex 32)
        sed -i "s/BACKUP_ENCRYPTION_KEY=.*/BACKUP_ENCRYPTION_KEY=$BACKUP_KEY/" "$ENV_FILE"
    fi
    
    log_success "Application secrets generated"
}

# Function to setup PostgreSQL certificates
setup_postgres_ssl() {
    log "Setting up PostgreSQL SSL certificates..."
    
    mkdir -p "$PROJECT_DIR/config/postgres"
    
    if [[ ! -f "$PROJECT_DIR/config/postgres/server.crt" ]]; then
        # Generate PostgreSQL SSL certificates
        openssl genrsa -out "$PROJECT_DIR/config/postgres/server.key" 2048
        openssl req -new -key "$PROJECT_DIR/config/postgres/server.key" \
            -out "$PROJECT_DIR/config/postgres/server.csr" \
            -subj "/C=PH/ST=Metro Manila/L=Quezon City/O=PRS System/CN=postgres"
        openssl x509 -req -in "$PROJECT_DIR/config/postgres/server.csr" \
            -signkey "$PROJECT_DIR/config/postgres/server.key" \
            -out "$PROJECT_DIR/config/postgres/server.crt" -days 365
        
        # Set permissions
        chmod 600 "$PROJECT_DIR/config/postgres/server.key"
        
        log_success "PostgreSQL SSL certificates generated"
    else
        log_success "PostgreSQL SSL certificates already exist"
    fi
}

# Function to deploy containers
deploy_containers() {
    log "Deploying containers..."
    
    cd "$PROJECT_DIR"
    
    # Pull latest images
    docker-compose pull
    
    # Build custom images if needed
    docker-compose build
    
    # Deploy containers
    docker-compose up -d
    
    log_success "Containers deployed"
}

# Function to initialize database
init_database() {
    log "Initializing database..."
    
    # Wait for database to be ready
    log "Waiting for database to be ready..."
    sleep 30
    
    # Check if backend container is running
    if docker ps | grep -q prs-backend; then
        # Run migrations
        log "Running database migrations..."
        docker exec prs-backend npm run migrate || log_warning "Migration command failed - this is normal on first run"
        
        # Run seeders
        log "Running database seeders..."
        docker exec prs-backend npm run seed || log_warning "Seed command failed - this is normal if data already exists"
        
        log_success "Database initialization completed"
    else
        log_error "Backend container is not running"
        return 1
    fi
}

# Function to setup monitoring
setup_monitoring() {
    log "Setting up monitoring configuration..."
    
    # Create Prometheus config
    mkdir -p "$PROJECT_DIR/config/prometheus"
    cat > "$PROJECT_DIR/config/prometheus/prometheus.yml" <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'prs-backend'
    static_configs:
      - targets: ['backend:4000']
    metrics_path: '/metrics'

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
EOF

    # Create Grafana provisioning
    mkdir -p "$PROJECT_DIR/config/grafana/provisioning/datasources"
    cat > "$PROJECT_DIR/config/grafana/provisioning/datasources/prometheus.yml" <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    log_success "Monitoring configuration setup completed"
}

# Function to check service health
health_check() {
    log "Performing health check..."
    
    # Wait for services to start
    sleep 30
    
    # Check container status
    if docker-compose ps | grep -q "Up"; then
        log_success "Containers are running"
    else
        log_error "Some containers are not running"
        docker-compose ps
        return 1
    fi
    
    # Test web endpoints
    if command -v curl &> /dev/null; then
        log "Testing web endpoints..."
        
        # Test main application (allow self-signed cert)
        if curl -k -f -s "https://localhost/health" > /dev/null; then
            log_success "Main application is responding"
        else
            log_error "Main application health check failed"
        fi
        
        # Test API endpoint
        if curl -k -f -s "https://localhost/api/health" > /dev/null; then
            log_success "API is responding"
        else
            log_error "API health check failed"
        fi
    fi
    
    log_success "Health check completed"
}

# Function to setup backup cron job
setup_backup() {
    log "Setting up automated backups..."
    
    # Create backup script
    cat > "$PROJECT_DIR/scripts/backup.sh" <<'EOF'
#!/bin/bash
# Automated backup script for PRS single-node

BACKUP_DIR="/mnt/nas/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="prs_backup_$TIMESTAMP"

# Database backup
docker exec prs-postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$BACKUP_DIR/${BACKUP_NAME}_db.sql.gz"

# Files backup
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_files.tar.gz" /mnt/nas/uploads/

# Cleanup old backups (keep last 30 days)
find "$BACKUP_DIR" -name "prs_backup_*.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_NAME"
EOF

    chmod +x "$PROJECT_DIR/scripts/backup.sh"
    
    # Add to crontab if BACKUP_ENABLED is true
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        # Remove existing cron job
        crontab -l 2>/dev/null | grep -v "prs_backup" | crontab -
        
        # Add new cron job
        (crontab -l 2>/dev/null; echo "$BACKUP_SCHEDULE $PROJECT_DIR/scripts/backup.sh") | crontab -
        
        log_success "Backup cron job configured"
    fi
}

# Function to display access information
show_access_info() {
    log_success "Deployment completed successfully!"
    echo ""
    echo -e "${GREEN}Access Information:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Main Application:${NC}     https://$DOMAIN"
    echo -e "${BLUE}Backend API:${NC}          https://$DOMAIN/api"
    echo -e "${BLUE}Portainer:${NC}            https://$DOMAIN/portainer"
    echo -e "${BLUE}Adminer:${NC}              https://$DOMAIN/adminer"
    echo -e "${BLUE}Grafana:${NC}              https://$DOMAIN/grafana"
    echo ""
    echo -e "${BLUE}Admin Tools Login:${NC}"
    echo -e "  Username: ${ADMIN_USER}"
    echo -e "  Password: ${ADMIN_PASSWORD}"
    echo ""
    echo -e "${BLUE}Database Connection:${NC}"
    echo -e "  Host: localhost (or use Adminer)"
    echo -e "  Database: ${POSTGRES_DB}"
    echo -e "  Username: ${POSTGRES_USER}"
    echo -e "  Password: ${POSTGRES_PASSWORD}"
    echo ""
    echo -e "${BLUE}Initial Admin User:${NC}"
    echo -e "  Username: ${ROOT_USER_NAME}"
    echo -e "  Email: ${ROOT_USER_EMAIL}"
    echo -e "  Password: ${ROOT_USER_PASSWORD}"
    echo ""
    echo -e "${YELLOW}Note: SSL certificate is self-signed. Replace with proper certificate for production.${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to show logs
show_logs() {
    local service=${1:-""}
    
    if [[ -n "$service" ]]; then
        docker-compose logs -f "$service"
    else
        docker-compose logs -f
    fi
}

# Function to stop services
stop_services() {
    log "Stopping services..."
    cd "$PROJECT_DIR"
    docker-compose down
    log_success "Services stopped"
}

# Function to restart services
restart_services() {
    log "Restarting services..."
    cd "$PROJECT_DIR"
    docker-compose restart
    log_success "Services restarted"
}

# Function to show service status
show_status() {
    log "Service Status:"
    cd "$PROJECT_DIR"
    docker-compose ps
}

# Main deployment function
deploy() {
    log "Starting PRS On-Premises Single Node deployment..."
    
    check_root
    check_prerequisites
    load_env
    setup_storage
    setup_ssl
    setup_auth
    generate_secrets
    setup_postgres_ssl
    setup_monitoring
    deploy_containers
    init_database
    health_check
    setup_backup
    show_access_info
}

# Display help
show_help() {
    echo -e "${BLUE}PRS On-Premises Single Node Deployment${NC}"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy              Full deployment"
    echo "  start               Start all services"
    echo "  stop                Stop all services"
    echo "  restart             Restart all services"
    echo "  status              Show service status"
    echo "  logs [service]      Show logs (all or specific service)"
    echo "  health              Run health check"
    echo "  backup              Run backup manually"
    echo "  update              Update containers to latest versions"
    echo "  help                Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 deploy           # Full deployment"
    echo "  $0 logs backend     # Show backend logs"
    echo "  $0 restart          # Restart all services"
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    start)
        cd "$PROJECT_DIR"
        docker-compose up -d
        log_success "Services started"
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "${2:-}"
        ;;
    health)
        health_check
        ;;
    backup)
        if [[ -f "$PROJECT_DIR/scripts/backup.sh" ]]; then
            "$PROJECT_DIR/scripts/backup.sh"
        else
            log_error "Backup script not found. Run deployment first."
        fi
        ;;
    update)
        cd "$PROJECT_DIR"
        docker-compose pull
        docker-compose up -d
        log_success "Services updated"
        ;;
    help|*)
        show_help
        ;;
esac
