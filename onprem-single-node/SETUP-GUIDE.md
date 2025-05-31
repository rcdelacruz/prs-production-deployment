# PRS On-Premises Single Node Setup Guide

This guide provides step-by-step instructions for deploying PRS on a single on-premises server with NAS storage, using simple Docker containers without orchestration.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [NAS Storage Setup](#nas-storage-setup)
3. [Server Preparation](#server-preparation)
4. [Installation Steps](#installation-steps)
5. [Configuration](#configuration)
6. [Deployment](#deployment)
7. [Post-Deployment Setup](#post-deployment-setup)
8. [Access and Usage](#access-and-usage)
9. [Maintenance](#maintenance)
10. [Troubleshooting](#troubleshooting)

## System Requirements

### Hardware Requirements

**Minimum Specifications:**
- **CPU**: 4 cores (Intel i5 or AMD Ryzen 5 equivalent)
- **RAM**: 8GB (16GB recommended)
- **Storage**: 
  - 120GB SSD for OS and containers
  - NAS for database and file storage
- **Network**: Gigabit Ethernet

**Recommended Specifications:**
- **CPU**: 6+ cores (Intel i7 or AMD Ryzen 7 equivalent)
- **RAM**: 16GB+ 
- **Storage**: 
  - 240GB+ SSD for OS and containers
  - NAS with RAID for data redundancy
- **Network**: Gigabit Ethernet with UPS backup

### Software Requirements

- **Operating System**: Ubuntu 20.04+ LTS or CentOS 8+ (64-bit)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **NAS**: Synology, QNAP, TrueNAS, or similar with NFS/SMB support

### Network Requirements

- **Incoming Ports**: 80 (HTTP), 443 (HTTPS)
- **Internal Network**: Access to NAS storage
- **Internet**: For initial setup and updates
- **Domain**: Optional but recommended for SSL certificates

## NAS Storage Setup

### Synology NAS Configuration

1. **Create Shared Folder**:
   ```
   Control Panel → Shared Folder → Create
   Name: prs-data
   Description: PRS application data storage
   ```

2. **Enable NFS**:
   ```
   Control Panel → File Services → NFS → Enable NFS service
   NFS Rule: Create rule for your server IP
   Privilege: Read/Write
   Squash: Map root to admin
   ```

3. **Create Directory Structure**:
   ```
   /volume1/prs-data/
   ├── database/
   ├── uploads/
   ├── backups/
   └── logs/
   ```

### QNAP NAS Configuration

1. **Create Share**:
   ```
   Control Panel → Privilege → Shared Folders → Create
   Name: prs-data
   Path: /share/prs-data
   ```

2. **Enable NFS**:
   ```
   Control Panel → Network & File Services → NFS Service
   Enable NFS service
   Add NFS rule for server IP with RW permissions
   ```

### Generic NFS Server Setup

```bash
# On NFS server
sudo apt update && sudo apt install nfs-kernel-server

# Create export directory
sudo mkdir -p /exports/prs-data
sudo mkdir -p /exports/prs-data/{database,uploads,backups,logs}

# Configure exports
echo "/exports/prs-data *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

# Apply configuration
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
```

## Server Preparation

### 1. Install Operating System

Install Ubuntu 20.04+ LTS with the following settings:
- Minimal installation
- Enable SSH server
- Set up a non-root user with sudo privileges
- Configure static IP address

### 2. Initial System Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git htop nano ufw fail2ban

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Configure automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 3. Install Docker

```bash
# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Log out and back in for group changes to take effect
```

### 4. Optimize Docker Storage

```bash
# Configure Docker to use efficient storage driver
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF

sudo systemctl restart docker
```

## Installation Steps

### 1. Clone Repository

```bash
# Clone the deployment repository
git clone https://github.com/rcdelacruz/prs-production-deployment.git
cd prs-production-deployment/onprem-single-node

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Configure Environment

```bash
# Copy example configuration
cp .env.example .env

# Edit configuration file
nano .env
```

**Important settings to configure in `.env`:**

```bash
# Domain and Network
DOMAIN=your-server-ip-or-domain.com

# Database Security
POSTGRES_PASSWORD=YourSecurePassword123!

# Application Security  
JWT_SECRET=your-jwt-secret-key-minimum-32-characters-long
ENCRYPTION_KEY=your-encryption-key-32-chars
ROOT_USER_PASSWORD=AdminPassword123!

# Admin Tools Access
ADMIN_USER=admin
ADMIN_PASSWORD=AdminTools123!

# NAS Configuration
NAS_SERVER=192.168.1.100  # Your NAS IP
NAS_SHARE=volume1/prs-data  # Your NAS share path
NAS_MOUNT_TYPE=nfs  # or 'cifs' for SMB

# For CIFS/SMB (uncomment if using SMB):
# NAS_USERNAME=your-nas-user
# NAS_PASSWORD=your-nas-password
```

### 3. Test NAS Connectivity

```bash
# Test NFS connection
sudo apt install -y nfs-common
sudo mkdir -p /tmp/test-mount
sudo mount -t nfs your-nas-ip:/volume1/prs-data /tmp/test-mount
ls -la /tmp/test-mount
sudo umount /tmp/test-mount

# Or test CIFS connection (if using SMB)
sudo apt install -y cifs-utils
sudo mount -t cifs //your-nas-ip/prs-data /tmp/test-mount -o username=your-user,password=your-pass
ls -la /tmp/test-mount
sudo umount /tmp/test-mount
```

## Configuration

### SSL Certificate Options

**Option 1: Self-Signed Certificate (Default)**
- Automatically generated during deployment
- Browser will show security warning
- Suitable for internal use

**Option 2: Let's Encrypt Certificate**
```bash
# Install certbot
sudo apt install -y certbot

# Obtain certificate (requires domain name and port 80 access)
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates to project
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
sudo chown $USER:$USER ssl/*.pem
```

**Option 3: Commercial Certificate**
```bash
# Place your certificates in the ssl/ directory
cp your-certificate.crt ssl/cert.pem
cp your-private-key.key ssl/key.pem
```

### Application Configuration

Edit backend-specific settings if needed:

```bash
# Email settings (optional)
SMTP_HOST=smtp.your-domain.com
SMTP_PORT=587
SMTP_USER=noreply@your-domain.com
SMTP_PASSWORD=EmailPassword123!

# External API integration
CITYLAND_API_URL=https://api.cityland.gov
CITYLAND_ACCOUNTING_URL=https://accounting.cityland.gov

# File upload limits
MAX_FILE_SIZE=100MB
ALLOWED_FILE_TYPES=pdf,doc,docx,xls,xlsx,jpg,jpeg,png,gif
```

## Deployment

### Run Full Deployment

```bash
# Execute deployment script
./scripts/deploy.sh

# Or run step by step:
./scripts/deploy.sh deploy
```

The deployment script will:
1. ✅ Check system prerequisites
2. ✅ Mount NAS storage
3. ✅ Generate SSL certificates
4. ✅ Set up basic authentication
5. ✅ Generate application secrets
6. ✅ Deploy all containers
7. ✅ Initialize database
8. ✅ Configure monitoring
9. ✅ Set up automated backups
10. ✅ Perform health checks

### Monitor Deployment Progress

```bash
# Check container status
./scripts/deploy.sh status

# View logs
./scripts/deploy.sh logs

# View specific service logs
./scripts/deploy.sh logs backend
./scripts/deploy.sh logs postgres
```

## Post-Deployment Setup

### 1. Verify Services

```bash
# Check all services are running
docker ps

# Test web access
curl -k https://localhost/health
curl -k https://localhost/api/health
```

### 2. Configure Initial Admin User

1. **Access the application**: `https://your-server-ip`
2. **Login with initial admin**:
   - Username: `admin` (from ROOT_USER_NAME)
   - Email: `admin@your-domain.com` (from ROOT_USER_EMAIL)  
   - Password: `AdminPassword123!` (from ROOT_USER_PASSWORD)

### 3. System Configuration

1. **Update profile information**
2. **Configure system settings**
3. **Set up user accounts**
4. **Configure departments and workflows**

### 4. SSL Certificate Setup (Production)

For production use, replace self-signed certificates:

```bash
# Stop nginx temporarily
docker stop prs-nginx

# Replace certificates
cp your-production-cert.pem ssl/cert.pem
cp your-production-key.key ssl/key.pem

# Restart nginx
docker start prs-nginx
```

## Access and Usage

### Application Access

| Service | URL | Credentials |
|---------|-----|-------------|
| **Main Application** | `https://your-server/` | App login |
| **Backend API** | `https://your-server/api/` | API endpoints |
| **Portainer** | `https://your-server/portainer/` | admin/AdminTools123! |
| **Adminer** | `https://your-server/adminer/` | admin/AdminTools123! |
| **Grafana** | `https://your-server/grafana/` | admin/AdminTools123! |

### Database Access

**Via Adminer (Web Interface):**
1. Go to `https://your-server/adminer/`
2. Login with admin credentials
3. Connect to database:
   - Server: `postgres`
   - Username: `prs_user`
   - Database: `prs_onprem`
   - Password: (from your .env file)

**Via Command Line:**
```bash
# Connect to database container
docker exec -it prs-postgres psql -U prs_user -d prs_onprem

# Backup database
docker exec prs-postgres pg_dump -U prs_user prs_onprem > backup.sql

# Restore database
cat backup.sql | docker exec -i prs-postgres psql -U prs_user -d prs_onprem
```

### File Management

**Uploaded Files Location:**
- **Host Path**: `/mnt/nas/uploads/`
- **Container Path**: `/app/uploads`
- **Web Access**: `https://your-server/uploads/filename`

**File Upload Limits:**
- Maximum file size: 100MB (configurable)
- Allowed types: PDF, DOC, DOCX, XLS, XLSX, images

### Container Management

**Using Portainer:**
1. Access `https://your-server/portainer/`
2. Login with admin credentials
3. Manage containers, volumes, networks
4. View logs and statistics
5. Update container images

**Using Command Line:**
```bash
# View running containers
docker ps

# View all containers
docker ps -a

# View container logs
docker logs prs-backend

# Restart container
docker restart prs-backend

# Update container
docker-compose pull backend
docker-compose up -d backend
```

## Maintenance

### Daily Tasks

```bash
# Check system status
./scripts/deploy.sh status

# View system resources
docker stats

# Check disk space
df -h
du -sh /mnt/nas/*
```

### Weekly Tasks

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update container images
./scripts/deploy.sh update

# Check logs for errors
./scripts/deploy.sh logs | grep -i error

# Verify backups
ls -la /mnt/nas/backups/
```

### Monthly Tasks

```bash
# Clean up Docker system
docker system prune -f

# Rotate logs
sudo logrotate -f /etc/logrotate.d/docker

# Test backup restoration
./scripts/deploy.sh backup
# Test restore process

# Review security updates
sudo unattended-upgrades --dry-run
```

### Backup Management

**Automated Backups:**
- **Schedule**: Daily at 2:00 AM (configurable)
- **Location**: `/mnt/nas/backups/`
- **Retention**: 30 days (configurable)
- **Contents**: Database, uploaded files

**Manual Backup:**
```bash
# Run backup immediately
./scripts/deploy.sh backup

# List available backups
ls -la /mnt/nas/backups/

# Backup to external location
rsync -av /mnt/nas/backups/ user@backup-server:/backups/prs/
```

**Restore Procedure:**
```bash
# Stop application
./scripts/deploy.sh stop

# Restore database
zcat /mnt/nas/backups/prs_backup_YYYYMMDD_HHMMSS_db.sql.gz | \
    docker exec -i prs-postgres psql -U prs_user -d prs_onprem

# Restore files
tar -xzf /mnt/nas/backups/prs_backup_YYYYMMDD_HHMMSS_files.tar.gz -C /

# Start application
./scripts/deploy.sh start
```

### SSL Certificate Renewal

**Let's Encrypt (Automatic):**
```bash
# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Update container certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
docker restart prs-nginx
```

**Commercial Certificate:**
```bash
# Replace certificate files
cp new-certificate.crt ssl/cert.pem
cp new-private-key.key ssl/key.pem

# Restart nginx
docker restart prs-nginx
```

## Troubleshooting

### Common Issues

**1. Cannot Access Web Interface**

```bash
# Check if containers are running
docker ps

# Check Nginx configuration
docker logs prs-nginx

# Test internal connectivity
docker exec prs-nginx curl -f http://frontend:80/
docker exec prs-nginx curl -f http://backend:4000/health

# Check firewall
sudo ufw status
```

**2. Database Connection Failed**

```bash
# Check PostgreSQL container
docker logs prs-postgres

# Test database connectivity
docker exec prs-postgres psql -U prs_user -d prs_onprem -c "SELECT version();"

# Check NAS mount
mountpoint /mnt/nas
ls -la /mnt/nas/database/
```

**3. NAS Storage Issues**

```bash
# Check mount status
mountpoint /mnt/nas
mount | grep nas

# Remount NAS
sudo umount /mnt/nas
sudo mount -a

# Test NAS connectivity
ping your-nas-ip
telnet your-nas-ip 2049  # NFS port
```

**4. SSL Certificate Issues**

```bash
# Check certificate validity
openssl x509 -in ssl/cert.pem -text -noout

# Test SSL endpoint
curl -vI https://your-server/

# Regenerate self-signed certificate
rm ssl/cert.pem ssl/key.pem
./scripts/deploy.sh deploy
```

**5. Container Resource Issues**

```bash
# Check resource usage
docker stats

# Check disk space
df -h
docker system df

# Clean up unused resources
docker system prune -af
```

### Log Analysis

**View Application Logs:**
```bash
# All services
./scripts/deploy.sh logs

# Specific service
./scripts/deploy.sh logs backend

# Follow logs in real-time
./scripts/deploy.sh logs backend | tail -f

# Search for errors
./scripts/deploy.sh logs | grep -i error
```

**System Logs:**
```bash
# System messages
sudo journalctl -f

# Docker daemon logs
sudo journalctl -u docker.service

# Container specific logs
sudo journalctl CONTAINER_NAME=prs-backend
```

### Performance Optimization

**Database Performance:**
```bash
# Connect to database
docker exec -it prs-postgres psql -U prs_user -d prs_onprem

# Check database performance
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_database;

# Optimize database
VACUUM ANALYZE;
REINDEX DATABASE prs_onprem;
```

**Container Resources:**
```bash
# Monitor resource usage
docker stats --no-stream

# Adjust container limits in docker-compose.yml
# Then restart containers
./scripts/deploy.sh restart
```

### Recovery Procedures

**Complete System Recovery:**
1. Reinstall operating system
2. Restore NAS mount
3. Clone repository and restore configuration
4. Run deployment
5. Restore from backup

**Partial Recovery:**
```bash
# Rebuild single container
docker-compose up -d --force-recreate backend

# Reset database
docker-compose down
sudo rm -rf /mnt/nas/database/*
./scripts/deploy.sh deploy
```

### Support and Monitoring

**System Monitoring:**
- Access Grafana: `https://your-server/grafana/`
- Monitor system resources, application metrics
- Set up alerts for critical issues

**Health Checks:**
```bash
# Quick health check
./scripts/deploy.sh health

# Detailed status
./scripts/deploy.sh status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

This comprehensive guide should help you successfully deploy and maintain PRS on a single on-premises server with NAS storage. The setup provides a good balance of simplicity and functionality for small to medium-sized deployments.
