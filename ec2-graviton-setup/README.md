# 🚀 PRS EC2 Graviton Production Setup

This directory contains a complete production setup for the PRS application optimized for **AWS EC2 Graviton instances** (ARM64 architecture). Specifically designed for **t4g.medium** instances with 2 cores and 4GB memory.

## 🎯 Key Features

- **🏗️ ARM64 Optimized**: Built specifically for AWS Graviton processors
- **💾 Memory Efficient**: Optimized for 4GB memory constraint
- **🔒 Secure by Default**: No public access - services bind to localhost only
- **🌐 Cloudflare Tunnel**: Secure access via Cloudflare Zero Trust
- **📊 Monitoring Included**: Grafana and Prometheus with memory-optimized settings
- **🗄️ Database Import**: Easy import of your production database dumps
- **🔧 Auto-Optimization**: System tuning for optimal performance on limited resources
- **🛡️ Enterprise Security**: Rate limiting, security headers, and access controls

## 🚀 Quick Start

### 1. **Launch EC2 Instance**

Launch an AWS EC2 Graviton instance:
- **Instance Type**: t4g.medium (2 vCPU, 4GB RAM)
- **AMI**: Amazon Linux 2 ARM64 or Ubuntu 20.04 ARM64
- **Storage**: At least 20GB EBS volume
- **Security Group**: SSH (22) only - web access via Cloudflare Tunnel

### 2. **Initial Setup**

```bash
# Connect to your EC2 instance
ssh -i your-key.pem ec2-user@your-ec2-ip

# Clone your repository
git clone <your-prs-repository>
cd prs/prs-production-deployment/ec2-graviton-setup

# Run the setup script (installs Docker, optimizes system)
./scripts/setup-ec2.sh
```

### 3. **Configure Environment**

```bash
# Copy and edit environment configuration
cp .env.example .env
nano .env

# Important settings to change:
# - DOMAIN=your-domain.com
# - POSTGRES_PASSWORD=your-strong-password
# - JWT_SECRET=your-jwt-secret
# - All other passwords and secrets
```

### 4. **Deploy Application**

```bash
# Full deployment with automatic database import
./scripts/deploy-ec2.sh deploy

# Or step by step:
./scripts/deploy-ec2.sh build    # Build ARM64 images
./scripts/deploy-ec2.sh start    # Start services
./scripts/deploy-ec2.sh status   # Check status
```

### 5. **Setup Cloudflare Tunnel** (Recommended)

```bash
# Setup secure access via Cloudflare Tunnel
./scripts/setup-cloudflare-tunnel.sh setup

# Follow the interactive prompts to:
# 1. Create tunnel in Cloudflare dashboard
# 2. Configure public hostnames
# 3. Update Security Groups
```

### 6. **Import Database** (Optional)

```bash
# If you have a database dump file:
./scripts/deploy-ec2.sh import-db your-dump-file.sql
```

## 📋 Configuration

### **Environment Variables**

Key settings in `.env`:

```bash
# Domain Configuration
DOMAIN=your-ec2-domain.com
HTTP_PORT=80
HTTPS_PORT=443

# Database (use strong passwords!)
POSTGRES_PASSWORD=your-super-strong-password
POSTGRES_DB=prs_production

# Security (CHANGE THESE!)
JWT_SECRET=your-super-secure-jwt-secret-key
ENCRYPTION_KEY=your-encryption-key
ROOT_USER_PASSWORD=your-admin-password

# Memory Limits (Optimized for 4GB)
BACKEND_MEMORY_LIMIT=1g
FRONTEND_MEMORY_LIMIT=512m
POSTGRES_MEMORY_LIMIT=1.5g
GRAFANA_MEMORY_LIMIT=256m
PROMETHEUS_MEMORY_LIMIT=256m
```

### **Resource Optimization**

The setup automatically optimizes for 4GB memory:

- **PostgreSQL**: Reduced connection pool and buffer sizes
- **Prometheus**: 3-day retention, 500MB size limit
- **Grafana**: SQLite database, reduced memory usage
- **Nginx**: Optimized buffer sizes and worker processes
- **System**: 2GB swap file, kernel parameter tuning

## 🌐 Access URLs

### **Via Cloudflare Tunnel (Recommended)**
- **Main Application**: https://your-domain.com
- **Backend API**: https://your-domain.com/api
- **Grafana Dashboard**: https://grafana.your-domain.com
- **Database Admin**: https://adminer.your-domain.com
- **Container Management**: https://portainer.your-domain.com
- **Health Check**: https://your-domain.com/health

### **Via SSH Tunnel (Alternative)**
```bash
# Create SSH tunnel
ssh -L 80:localhost:80 -L 8080:localhost:8080 -L 9000:localhost:9000 -L 3001:localhost:3001 ec2-user@your-ec2-ip

# Then access locally:
# Main App: http://localhost
# Adminer: http://localhost:8080
# Portainer: http://localhost:9000
# Grafana: http://localhost:3001
```

## 🔧 Management Commands

### **Service Management**
```bash
./scripts/deploy-ec2.sh start     # Start all services
./scripts/deploy-ec2.sh stop      # Stop all services
./scripts/deploy-ec2.sh restart   # Restart all services
./scripts/deploy-ec2.sh status    # Show status and resource usage
```

### **Monitoring**
```bash
./scripts/deploy-ec2.sh monitor   # Real-time resource monitoring
./scripts/deploy-ec2.sh logs      # View all logs
./scripts/deploy-ec2.sh logs backend  # View specific service logs
monitor                           # System status command
```

### **Database Management**
```bash
./scripts/deploy-ec2.sh init-db           # Initialize fresh database
./scripts/deploy-ec2.sh import-db file.sql # Import database dump
```

### **Maintenance**
```bash
./scripts/deploy-ec2.sh build     # Rebuild ARM64 images
./scripts/deploy-ec2.sh optimize  # Re-run system optimizations
./scripts/deploy-ec2.sh ssl-setup # Setup/renew SSL certificates
```

## 🔒 Security Configuration

### **SSL Certificates**

For production, replace self-signed certificates with proper SSL:

```bash
# Using Let's Encrypt (recommended)
sudo apt install certbot
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem

# Restart nginx
./scripts/deploy-ec2.sh restart
```

### **Security Groups**

Configure AWS Security Groups:
- **Port 22**: SSH access (your IP only)
- **Port 80**: HTTP (redirect to HTTPS)
- **Port 443**: HTTPS (public)
- **Port 8080**: Adminer (your IP only)
- **Port 3001**: Grafana (your IP only)

### **Firewall**

The setup automatically configures local firewall rules.

## 📊 Monitoring

### **Grafana Dashboard**
- **URL**: http://your-domain.com:3001
- **Username**: admin
- **Password**: (set in .env GRAFANA_ADMIN_PASSWORD)

### **Prometheus Metrics**
- **URL**: https://your-domain.com/prometheus
- **Retention**: 3 days (optimized for memory)
- **Storage**: 500MB limit

### **System Monitoring**
```bash
# Real-time monitoring
./scripts/deploy-ec2.sh monitor

# Quick system check
monitor

# Docker container stats
docker stats

# Memory usage
free -h

# Disk usage
df -h
```

## 🔧 Troubleshooting

### **Memory Issues**
```bash
# Check memory usage
free -h
docker stats

# Reduce memory limits in .env if needed:
BACKEND_MEMORY_LIMIT=768m
POSTGRES_MEMORY_LIMIT=1g
```

### **Performance Issues**
```bash
# Check system load
uptime
htop

# Check container health
docker ps
./scripts/deploy-ec2.sh status
```

### **Database Issues**
```bash
# Check database logs
./scripts/deploy-ec2.sh logs postgres

# Restart database
docker restart prs-ec2-postgres

# Re-import database
./scripts/deploy-ec2.sh import-db your-file.sql
```

### **SSL Issues**
```bash
# Regenerate self-signed certificates
./scripts/deploy-ec2.sh ssl-setup

# Check certificate validity
openssl x509 -in ssl/cert.pem -text -noout
```

## 🎯 Performance Tips

### **For 4GB Memory**
- Monitor memory usage regularly with `monitor` command
- Consider disabling monitoring services if memory is tight:
  ```bash
  PROMETHEUS_ENABLED=false
  GRAFANA_ENABLED=false
  ```
- Use database connection pooling efficiently
- Enable swap if not already present

### **For Better Performance**
- Upgrade to t4g.large (8GB) for better performance
- Use EBS GP3 volumes for better I/O
- Enable CloudWatch monitoring for AWS-level metrics
- Consider RDS for database if scaling up

## 🔄 Backup Strategy

```bash
# Database backup
docker exec prs-ec2-postgres pg_dump -U prs_user prs_production > backup.sql

# Full system backup (recommended)
# Use AWS EBS snapshots for complete system backup
```

## 🚀 Scaling Up

When you outgrow t4g.medium:

1. **Upgrade Instance**: t4g.large (4 vCPU, 8GB RAM)
2. **Increase Memory Limits** in .env
3. **Enable More Monitoring**: Full Prometheus + Grafana
4. **Consider RDS**: For database scaling
5. **Load Balancer**: For multiple instances

---

**This setup provides a production-ready PRS environment optimized for AWS Graviton processors with 4GB memory!** 🚀
