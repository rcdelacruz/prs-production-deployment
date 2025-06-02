# PRS Local MacBook Setup Guide

This guide will help you set up the PRS application for local development and testing on your MacBook M3, addressing common macOS issues like port 80/443 privileges.

## Quick Start

### 1. Prerequisites

**Install Docker Desktop for Mac:**
```bash
# Download from: https://docs.docker.com/desktop/mac/install/
# Or using Homebrew:
brew install --cask docker
```

**Verify Installation:**
```bash
docker --version
docker-compose --version
```

### 2. Setup

**Navigate to the local setup directory:**
```bash
cd prs-production-deployment/local-macbook-setup
```

**Create your environment configuration:**
```bash
cp .env.example .env
```

**Edit the configuration (optional):**
```bash
nano .env
```

### 3. Deploy

**Run the deployment script:**
```bash
./scripts/deploy-local.sh
```

This will:
- ✅ Check prerequisites
- ✅ Generate SSL certificates
- ✅ Build Docker images
- ✅ Start all services
- ✅ Initialize the database
- ✅ Show access URLs

### 4. Access the Application

Once deployment is complete, you can access:

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| **Main Application** | https://localhost:8443 | admin / admin123 |
| **Backend API** | https://localhost:8443/api | - |
| **Database Admin** | https://localhost:8443/adminer | Server: postgres, User: prs_user, DB: prs_local |
| **Container Management** | https://localhost:8443/portainer | - |
| **Monitoring** | https://localhost:8443/grafana | admin / admin123 |

## Key Differences from Production

### Port Configuration
- **HTTP**: 8080 (instead of 80)
- **HTTPS**: 8443 (instead of 443)
- **No root privileges required**

### Storage
- **Docker volumes** instead of NAS mounts
- **Local file system** for uploads and logs
- **Persistent data** across container restarts

### Security
- **Self-signed SSL certificates** (browser warnings are normal)
- **No basic authentication** on admin tools
- **Development-friendly CORS settings**

### Performance
- **Reduced resource limits** for local development
- **Faster startup** with fewer monitoring services
- **Optimized for development workflow**

## Common Commands

### Service Management
```bash
# Start services
./scripts/deploy-local.sh start

# Stop services
./scripts/deploy-local.sh stop

# Restart services
./scripts/deploy-local.sh restart

# Check status
./scripts/deploy-local.sh status
```

### Development Workflow
```bash
# Rebuild after code changes
./scripts/deploy-local.sh rebuild

# View logs
./scripts/deploy-local.sh logs

# View specific service logs
./scripts/deploy-local.sh logs backend
./scripts/deploy-local.sh logs postgres
```

### Database Management
```bash
# Initialize/reset database
./scripts/deploy-local.sh init-db

# Access database directly
docker exec -it prs-local-postgres psql -U prs_user -d prs_local
```

### Troubleshooting
```bash
# Reset everything (removes all data)
./scripts/deploy-local.sh reset

# Regenerate SSL certificates
./scripts/deploy-local.sh ssl-reset

# Get help
./scripts/deploy-local.sh help
```

## Troubleshooting

### Port Conflicts

If you get port conflicts:

1. **Check what's using the ports:**
   ```bash
   lsof -i :8080
   lsof -i :8443
   ```

2. **Change ports in .env:**
   ```bash
   HTTP_PORT=8081
   HTTPS_PORT=8444
   ```

3. **Restart services:**
   ```bash
   ./scripts/deploy-local.sh restart
   ```

### SSL Certificate Warnings

Browser warnings about self-signed certificates are normal for local development:

1. **Chrome/Safari**: Click "Advanced" → "Proceed to localhost"
2. **Firefox**: Click "Advanced" → "Accept the Risk and Continue"

### Docker Issues

If Docker isn't working:

1. **Make sure Docker Desktop is running**
2. **Check Docker status:**
   ```bash
   docker info
   ```
3. **Restart Docker Desktop if needed**

### Database Connection Issues

If the database isn't working:

1. **Check if PostgreSQL container is running:**
   ```bash
   docker ps | grep postgres
   ```

2. **Check database logs:**
   ```bash
   ./scripts/deploy-local.sh logs postgres
   ```

3. **Reinitialize database:**
   ```bash
   ./scripts/deploy-local.sh init-db
   ```

### Performance Issues

If the system is slow:

1. **Check Docker resource usage:**
   ```bash
   docker stats
   ```

2. **Adjust memory limits in .env:**
   ```bash
   BACKEND_MEMORY_LIMIT=256m
   POSTGRES_MEMORY_LIMIT=512m
   ```

3. **Disable monitoring services:**
   ```bash
   PROMETHEUS_ENABLED=false
   GRAFANA_ENABLED=false
   ```

## Development Integration

### Working with Local Development

This setup complements your local development workflow:

1. **Backend Development**: Run backend locally on port 4000
2. **Frontend Development**: Run frontend locally on port 3000
3. **Full Integration Testing**: Use this setup for complete system testing

### Hot Reload Support

To enable hot reload for development:

1. **Uncomment volume mounts in docker-compose.yml:**
   ```yaml
   # Uncomment for development hot reload
   # - ../../prs-backend/src:/app/src:ro
   ```

2. **Restart services:**
   ```bash
   ./scripts/deploy-local.sh restart
   ```

## Next Steps

1. **Test the application** by logging in with admin/admin123
2. **Explore the admin tools** (Portainer, Adminer, Grafana)
3. **Start developing** with your preferred workflow
4. **Use this setup** for integration testing

## Support

If you encounter issues:

1. **Check the logs** with `./scripts/deploy-local.sh logs`
2. **Review this guide** for common solutions
3. **Reset the environment** if needed with `./scripts/deploy-local.sh reset`

This local setup provides a complete PRS environment optimized for MacBook development while avoiding the common port and privilege issues of the production setup.
