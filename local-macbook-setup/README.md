# 🌍 PRS Cross-Platform Local Development Setup

This directory contains a complete cross-platform setup for local development and testing of the PRS application. Works seamlessly on **Linux**, **macOS**, and **Windows** (with WSL/Git Bash).

## 🚀 Key Features

- **🌍 Cross-Platform**: Works on Linux, macOS, and Windows
- **🔧 Smart Configuration**: Auto-detects OS and configures accordingly
- **🔒 Secure Ports**: Uses ports 8080 (HTTP) and 8444 (HTTPS) instead of 80/443
- **Complete Monitoring**: Includes Grafana and Prometheus dashboards
- **Production Data Import**: Easy import of your production database dumps
- **Storage**: Uses Docker volumes instead of NAS mounts
- **SSL**: Self-signed certificates for local development
- **No Root Required**: Can run without sudo privileges

## 🚀 Quick Start

### 1. **Prerequisites**

#### Linux (Ubuntu/Debian)
```bash
# Install Docker and Docker Compose
sudo apt-get update
sudo apt-get install docker.io docker-compose
sudo systemctl start docker
sudo usermod -aG docker $USER  # Logout and login again
```

#### macOS
```bash
# Install Docker Desktop for Mac
# https://docs.docker.com/desktop/mac/install/
```

#### Windows
```bash
# Install Docker Desktop for Windows
# https://docs.docker.com/desktop/windows/install/
# Or use WSL2 with Docker
```

#### Verify Installation (All Platforms)
```bash
docker --version
docker-compose --version  # or: docker compose version
```

### 2. **Cross-Platform Setup**

```bash
cd prs-production-deployment/local-macbook-setup

# Run cross-platform setup (auto-detects your OS)
./scripts/setup-cross-platform.sh
# Windows users: scripts\setup-cross-platform.bat

# Copy and configure environment
cp .env.example .env
# Edit .env as needed (nano/vim on Linux/Mac, notepad on Windows)
```

### 3. **Deploy**

```bash
# Deploy with monitoring services
./scripts/deploy-local.sh deploy
```

4. **Import Production Data** (Optional):
   ```bash
   # If you have a production database dump, import it:
   ./scripts/deploy-local.sh import-db your-dump-file.sql
   ```

5. **Access**:
   - **Main Application**: https://localhost:8444
   - **Backend API**: https://localhost:8444/api
   - **Database Admin**: https://localhost:8444/adminer
   - **Container Management**: https://localhost:8444/portainer
   - **📊 Grafana Dashboard**: https://localhost:8444/grafana
   - **📈 Prometheus Metrics**: https://localhost:8444/prometheus

## Configuration

### Environment Variables

Key settings in `.env`:

```bash
# Local Development Settings
DOMAIN=localhost
HTTP_PORT=8080
HTTPS_PORT=8444

# Database (using Docker volume)
POSTGRES_PASSWORD=localdev123

# Application Security
JWT_SECRET=local-development-jwt-secret-key
ROOT_USER_PASSWORD=admin123
```

### Storage

All data is stored in Docker volumes:
- `prs_local_database` - PostgreSQL data
- `prs_local_uploads` - File uploads
- `prs_local_logs` - Application logs

## Development Workflow

### Starting Services
```bash
./scripts/deploy-local.sh start
```

### Stopping Services
```bash
./scripts/deploy-local.sh stop
```

### Viewing Logs
```bash
./scripts/deploy-local.sh logs
./scripts/deploy-local.sh logs backend
./scripts/deploy-local.sh logs grafana
./scripts/deploy-local.sh logs prometheus
```

### Rebuilding After Code Changes
```bash
./scripts/deploy-local.sh rebuild
```

### Database Management
```bash
# Access database via Adminer
open https://localhost:8444/adminer

# Or via command line
docker exec -it prs-local-postgres psql -U prs_user -d prs_local

# Import production database dump
./scripts/deploy-local.sh import-db your-dump-file.sql
```

### Production Data Import

To import your production database:

1. **Get your SQL dump file** from production
2. **Fix line endings** (if needed):
   ```bash
   # If your dump has Windows line endings, fix them:
   tr -d '\r' < your-dump-file.sql > fixed-dump-file.sql
   ```
3. **Import the data**:
   ```bash
   ./scripts/deploy-local.sh import-db fixed-dump-file.sql
   ```

**Note**: The import process will handle ownership issues automatically. You may see "role 'admin' does not exist" warnings - these are normal and don't affect the data import.

## Monitoring and Administration

### Grafana Dashboard
- **URL**: https://localhost:8444/grafana/
- **Username**: admin
- **Password**: admin123
- **Features**: Pre-configured dashboard for PRS local development monitoring

### Prometheus Metrics
- **URL**: https://localhost:8444/prometheus/
- **Features**: Metrics collection and querying interface

### Database Administration
- **Adminer**: https://localhost:8444/adminer/
  - Server: postgres
  - Username: prs_user
  - Password: localdev123
  - Database: prs_local

### Container Management
- **Portainer**: https://localhost:8444/portainer/
- **Features**: Docker container management interface

### Testing Your Setup
```bash
# Run comprehensive tests
./scripts/test-setup.sh

# This will verify:
# - All services are running
# - All endpoints are accessible
# - Database connectivity
# - Monitoring services
```

## Troubleshooting

### Port Conflicts
If ports 8080 or 8444 are in use:
```bash
# Check what's using the ports
lsof -i :8080
lsof -i :8444

# Edit .env to use different ports
HTTP_PORT=8081
HTTPS_PORT=8445
```

### SSL Certificate Issues
```bash
# Regenerate certificates
./scripts/deploy-local.sh ssl-reset
```

### Reset Everything
```bash
# Stop and remove all containers and volumes
./scripts/deploy-local.sh reset
```

## Integration with Development

This setup is designed to work alongside your local development environment:

1. **Backend Development**: You can still run the backend locally on port 4000 for development
2. **Frontend Development**: You can run the frontend locally on port 3000 for development
3. **Full Stack Testing**: Use this setup to test the complete integrated system

## Performance Notes

- **Resource Usage**: Optimized for local development with reduced resource limits
- **Startup Time**: Faster startup by excluding heavy monitoring services
- **Hot Reload**: Supports volume mounting for development files

## Security Notes

- **Local Only**: This setup is for local development only
- **Self-Signed Certs**: Browser will show security warnings (normal for local dev)
- **Default Passwords**: Change default passwords for any shared development environments

## What's Included

This setup provides a complete local development environment with:

✅ **Core Application Services**
- Frontend (React)
- Backend API (Node.js)
- PostgreSQL Database
- Nginx Reverse Proxy with SSL

✅ **Monitoring Stack**
- Grafana dashboards with pre-configured PRS monitoring
- Prometheus metrics collection
- Real-time performance monitoring

✅ **Administration Tools**
- Adminer for database management
- Portainer for container management
- Comprehensive logging

✅ **Production Data Support**
- Easy import of production database dumps
- Automatic handling of line ending issues
- Preservation of all relationships and data integrity

✅ **MacBook Optimized**
- No root privileges required
- Uses non-privileged ports (8080/8444)
- Optimized for Apple Silicon and Intel Macs
- Docker volume storage (no NAS dependencies)

This setup gives you a complete replica of your production environment running locally on your MacBook! 🚀
