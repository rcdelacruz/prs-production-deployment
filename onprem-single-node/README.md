# On-Premises Single Node Setup

This directory contains a simplified deployment configuration for on-premises single-node deployments using Docker containers without orchestration.

## Architecture

```
Internet → [Nginx Proxy :80/443] → Internal Services
                    ├── Frontend App
                    ├── Backend API  
                    ├── Portainer (Container Management)
                    ├── Adminer (Database Management)
                    └── Grafana (Monitoring)

Storage Layout:
├── SSD (OS + Containers)
└── NAS (Database + Files + Backups)
```

## Features

- **Single Node**: Simple Docker containers without orchestration
- **Simplified Stack**: No MinIO, no Redis, no clustering
- **NAS Storage**: Database, files, and backups stored on NAS
- **Web Proxy**: All services accessible through Nginx on standard ports
- **Container Management**: Portainer for easy container management
- **Database Management**: Adminer for PostgreSQL administration
- **Monitoring**: Basic Grafana dashboards

## Quick Start

1. **Prepare the server**:
   ```bash
   git clone https://github.com/rcdelacruz/prs-production-deployment.git
   cd prs-production-deployment/onprem-single-node
   ```

2. **Configure storage**:
   ```bash
   # Mount NAS storage
   sudo mkdir -p /mnt/nas
   sudo mount -t nfs your-nas-server:/volume1/prs /mnt/nas
   
   # Setup directories
   ./scripts/setup-storage.sh
   ```

3. **Configure environment**:
   ```bash
   cp .env.example .env
   nano .env  # Edit for your environment
   ```

4. **Deploy**:
   ```bash
   ./scripts/deploy.sh
   ```

5. **Access services**:
   - **Application**: https://your-domain.com
   - **Portainer**: https://your-domain.com/portainer
   - **Adminer**: https://your-domain.com/adminer  
   - **Grafana**: https://your-domain.com/grafana

## Directory Structure

```
onprem-single-node/
├── docker-compose.yml          # Main container configuration
├── .env.example               # Environment variables template
├── nginx/                     # Nginx proxy configuration
│   ├── nginx.conf
│   └── sites-enabled/
├── scripts/                   # Setup and management scripts
│   ├── deploy.sh
│   ├── setup-storage.sh
│   └── backup.sh
├── config/                    # Service configurations
│   ├── grafana/
│   └── prometheus/
└── README.md                  # This file
```

## Storage Configuration

- **OS & Containers**: Local SSD (`/var/lib/docker`)
- **Database**: NAS (`/mnt/nas/database`)
- **Uploads**: NAS (`/mnt/nas/uploads`) 
- **Backups**: NAS (`/mnt/nas/backups`)
- **Logs**: NAS (`/mnt/nas/logs`)

## Service URLs

All services are accessible through the main domain with path-based routing:

- `https://your-domain.com/` - Main application
- `https://your-domain.com/api/` - Backend API
- `https://your-domain.com/portainer/` - Container management
- `https://your-domain.com/adminer/` - Database management
- `https://your-domain.com/grafana/` - Monitoring dashboards

## Requirements

- **Hardware**: 4+ CPU cores, 8+ GB RAM, SSD for OS
- **Network**: NAS accessible via NFS/SMB
- **Software**: Docker, Docker Compose, SSL certificates
- **Ports**: Only 80 and 443 need to be open to internet

## Security

- SSL/TLS encryption for all web traffic
- Internal container networking (no direct external access)
- Basic authentication for admin tools
- Regular automated backups to NAS
