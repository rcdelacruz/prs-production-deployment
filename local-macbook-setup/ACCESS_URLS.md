# PRS Local Development - Access URLs

This document provides all the access URLs for your local development environment.

## 🌐 **Main Application Access**

### Primary Application (via Nginx Reverse Proxy)
- **Frontend**: https://localhost:8444
- **Backend API**: https://localhost:8444/api
- **Alternative HTTP**: http://localhost:8081

## 🔧 **Development Tools - Direct Access**

### Grafana - Monitoring Dashboard
- **Direct Access**: http://localhost:3001
- **Via Nginx**: https://localhost:8444/grafana
- **Credentials**:
  - Username: `admin`
  - Password: `admin123` (from .env GRAFANA_ADMIN_PASSWORD)

### Portainer - Container Management
- **Direct Access**: http://localhost:9001
- **Via Nginx**: https://localhost:8444/portainer
- **First-time setup**: Create admin user on first visit

### Adminer - Database Management (TimescaleDB)
- **Direct Access**: http://localhost:8082
- **Via Nginx**: https://localhost:8444/adminer
- **Database Connection**:
  - System: `PostgreSQL` (TimescaleDB-enabled)
  - Server: `postgres` (or `localhost` if connecting externally)
  - Username: `prs_user`
  - Password: `localdev123`
  - Database: `prs_local`
- **TimescaleDB Features**: Time-series optimization, compression, analytics

## 📊 **Monitoring Services**

### Prometheus - Metrics Collection
- **Via Nginx**: https://localhost:8444/prometheus
- **Note**: No direct port exposed for security

## 🔐 **SSL Certificates**

- **Self-signed certificates** are used for local development
- Your browser will show security warnings - this is normal for local development
- Click "Advanced" → "Proceed to localhost" to continue

## 🚀 **Quick Start Commands**

```bash
# Start all services
docker-compose --profile monitoring up -d

# Stop all services
docker-compose --profile monitoring down

# View logs
docker-compose logs -f [service-name]

# Restart specific service
docker-compose restart [service-name]
```

## 📝 **Service Status Check**

```bash
# Check all running containers
docker-compose ps

# Check service health
docker-compose --profile monitoring ps
```

## 🔧 **Port Configuration**

All ports are configurable via the `.env` file:

```env
# Main application ports
HTTP_PORT=8081
HTTPS_PORT=8444

# Direct access ports
GRAFANA_PORT=3001
PORTAINER_PORT=9001
ADMINER_PORT=8082
```

## 🎯 **Development Workflow**

1. **Start services**: `docker-compose --profile monitoring up -d`
2. **Access application**: https://localhost:8444
3. **Monitor with Grafana**: http://localhost:3001
4. **Manage containers**: http://localhost:9001
5. **Database admin**: http://localhost:8082

## 🔍 **Troubleshooting**

### Port Conflicts
If you encounter port conflicts, update the `.env` file with different ports:
```env
GRAFANA_PORT=3002
PORTAINER_PORT=9002
ADMINER_PORT=8083
```

### Service Not Accessible
1. Check if service is running: `docker-compose ps`
2. Check service logs: `docker-compose logs [service-name]`
3. Verify port mapping: `docker port [container-name]`

### SSL Certificate Issues
- Certificates are self-signed for local development
- Add security exception in your browser
- For production, use proper SSL certificates

---

**Last Updated**: $(date)
**Environment**: Local Development (MacBook M3)
