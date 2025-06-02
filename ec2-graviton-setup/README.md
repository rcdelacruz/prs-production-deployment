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

## 🚀 Step-by-Step Setup Guide

### **Step 1: Launch EC2 Instance**

1. **Create EC2 Instance**
   - **Instance Type**: `t4g.medium` (2 vCPU, 4GB RAM, ARM64)
   - **AMI**: Amazon Linux 2 ARM64 or Ubuntu 20.04 ARM64
   - **Storage**: 20GB+ EBS volume (GP3 recommended)
   - **Key Pair**: Select or create your SSH key pair

2. **Configure Security Group (Minimal & Secure)**
   ```
   Inbound Rules:
   - SSH (22) from YOUR_IP/32 only

   Outbound Rules:
   - All traffic (0.0.0.0/0)
   ```
   **⚠️ Important**: No web ports needed! Cloudflare Tunnel handles all web traffic securely.

3. **Launch Instance and Note Public IP**

### **Step 2: Initial Server Setup**

1. **Connect to Your Instance**
   ```bash
   ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
   ```

2. **Clone Repository**
   ```bash
   git clone https://github.com/your-org/prs.git
   cd prs/prs-production-deployment/ec2-graviton-setup
   ```

3. **Run Automated Setup**
   ```bash
   ./scripts/setup-ec2.sh
   ```
   This script will:
   - ✅ Install Docker and Docker Compose
   - ✅ Optimize system for 4GB memory
   - ✅ Configure firewall and security
   - ✅ Create swap file and tune kernel
   - ✅ Install monitoring tools

4. **Logout and Login Again** (to apply Docker group membership)
   ```bash
   exit
   ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
   cd prs/prs-production-deployment/ec2-graviton-setup
   ```

### **Step 3: Setup Cloudflare Tunnel**

1. **Create Cloudflare Tunnel**
   - Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
   - Navigate to **Access > Tunnels**
   - Click **"Create a tunnel"**
   - Choose **"Cloudflared"**
   - Name: `prs-ec2-tunnel`
   - Click **"Save tunnel"**

2. **Copy Tunnel Token**
   - Copy the tunnel token from the dashboard
   - Keep this safe - you'll need it in the next step

3. **Configure Public Hostnames in Cloudflare**
   Add these hostnames in the tunnel configuration:

   | Subdomain | Domain | Service Type | URL |
   |-----------|--------|--------------|-----|
   | (leave empty) | your-domain.com | HTTP | localhost:80 |
   | grafana | your-domain.com | HTTP | localhost:3001 |
   | adminer | your-domain.com | HTTP | localhost:8080 |
   | portainer | your-domain.com | HTTP | localhost:9000 |

   **Example URLs you'll get:**
   - Main App: `https://your-domain.com`
   - Grafana: `https://grafana.your-domain.com`
   - Adminer: `https://adminer.your-domain.com`
   - Portainer: `https://portainer.your-domain.com`

### **Step 4: Configure Environment**

1. **Create Environment File**
   ```bash
   cp .env.example .env
   nano .env
   ```

2. **Essential Configuration** (Update these values):
   ```bash
   # Domain Configuration
   DOMAIN=your-domain.com

   # Cloudflare Tunnel
   CLOUDFLARE_TUNNEL_TOKEN=your-tunnel-token-from-step-3

   # Database Security (CHANGE THESE!)
   POSTGRES_PASSWORD=your-super-strong-password-123!
   POSTGRES_DB=prs_production
   POSTGRES_USER=prs_user

   # Application Security (GENERATE STRONG VALUES!)
   JWT_SECRET=your-super-secure-jwt-secret-key-minimum-32-characters
   ENCRYPTION_KEY=your-encryption-key-32-chars-minimum
   OTP_KEY=your-base64-encoded-otp-key-64-bytes-minimum
   PASS_SECRET=your-password-secret-key

   # Admin User
   ROOT_USER_NAME=admin
   ROOT_USER_EMAIL=admin@your-domain.com
   ROOT_USER_PASSWORD=your-admin-password-123!

   # Monitoring
   GRAFANA_ADMIN_PASSWORD=your-grafana-password-123!

   # Security Settings
   ENABLE_PUBLIC_ACCESS=false
   BYPASS_OTP=false
   ```

### **Step 5: Deploy Application**

1. **Full Deployment**
   ```bash
   ./scripts/deploy-ec2.sh deploy
   ```
   This will:
   - ✅ Build ARM64 Docker images
   - ✅ Generate SSL certificates (self-signed for internal use)
   - ✅ Start all services (nginx, backend, frontend, postgres, adminer, portainer)
   - ✅ Start monitoring (Grafana, Prometheus)
   - ✅ Start Cloudflare Tunnel
   - ✅ Initialize database with migrations and seeders

2. **Check Deployment Status**
   ```bash
   ./scripts/deploy-ec2.sh status
   ```

### **Step 6: Import Database** (Optional)

If you have an existing database dump:

1. **Transfer Dump File to EC2**
   ```bash
   # From your local machine
   scp -i your-key.pem your-dump-file.sql ec2-user@YOUR_EC2_IP:~/prs/prs-production-deployment/ec2-graviton-setup/
   ```

2. **Import Database**
   ```bash
   # On EC2 instance
   ./scripts/deploy-ec2.sh import-db your-dump-file.sql
   ```

### **Step 7: Verify Deployment**

1. **Check All Services**
   ```bash
   ./scripts/deploy-ec2.sh status
   docker ps
   ```

2. **Test Access URLs**
   - **Main Application**: https://your-domain.com
   - **Grafana Dashboard**: https://grafana.your-domain.com (admin / your-grafana-password)
   - **Database Admin**: https://adminer.your-domain.com
   - **Container Management**: https://portainer.your-domain.com

3. **Monitor Resources**
   ```bash
   ./scripts/deploy-ec2.sh monitor
   # Or quick check:
   monitor
   ```

### **Step 8: Final Security Steps**

1. **Update AWS Security Group** (Remove any web ports if present)
   - Ensure only SSH (22) is allowed from your IP
   - Remove HTTP (80), HTTPS (443), or any other web ports

2. **Verify No Public Access**
   ```bash
   # Check that services only bind to localhost
   sudo netstat -tuln | grep 127.0.0.1
   ```

3. **Test Cloudflare Tunnel**
   ```bash
   # Check tunnel status
   docker logs prs-ec2-cloudflared
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
./scripts/deploy-ec2.sh ssl-setup # Setup internal SSL certificates
```

## 🔒 Security Configuration

### **Cloudflare Tunnel Security**

With Cloudflare Tunnel, SSL/TLS is handled automatically:
- ✅ **Automatic SSL**: Cloudflare provides SSL certificates
- ✅ **DDoS Protection**: Built-in protection from Cloudflare
- ✅ **Zero Trust**: No public ports exposed
- ✅ **Access Control**: Configure in Cloudflare dashboard

### **AWS Security Groups (Minimal)**

Your Security Group should only have:
```
Inbound Rules:
- SSH (22) from YOUR_IP/32 only

Outbound Rules:
- All traffic (0.0.0.0/0)
```

**⚠️ Important**: Remove any HTTP/HTTPS ports - they're not needed with Cloudflare Tunnel!

### **Local Firewall**

The setup automatically configures local firewall rules for additional security.

## 📊 Monitoring

### **Grafana Dashboard**
- **URL**: https://grafana.your-domain.com (via Cloudflare Tunnel)
- **Username**: admin
- **Password**: (set in .env GRAFANA_ADMIN_PASSWORD)

### **Prometheus Metrics**
- **URL**: https://your-domain.com/prometheus (via Cloudflare Tunnel)
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

# Check backend logs for database errors
./scripts/deploy-ec2.sh logs backend

# Restart database
docker restart prs-ec2-postgres

# Manually run database migrations
docker-compose exec backend npm run migrate:dev

# Manually run database seeders
docker-compose exec backend npm run seed:dev

# Re-import database
./scripts/deploy-ec2.sh import-db your-file.sql

# Check database connection
docker exec prs-ec2-postgres psql -U prs_user -d prs_production -c "SELECT version();"
```

### **Cloudflare Tunnel Issues**
```bash
# Check tunnel status
docker logs prs-ec2-cloudflared

# Restart tunnel
docker restart prs-ec2-cloudflared

# Test tunnel connectivity
./scripts/setup-cloudflare-tunnel.sh status
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

## 📝 Quick Reference

### **Essential Commands**
```bash
# Deploy everything
./scripts/deploy-ec2.sh deploy

# Check status
./scripts/deploy-ec2.sh status

# View logs
./scripts/deploy-ec2.sh logs

# Import database
./scripts/deploy-ec2.sh import-db file.sql

# Monitor resources
./scripts/deploy-ec2.sh monitor
```

### **Access URLs**
- **Main App**: https://your-domain.com
- **Grafana**: https://grafana.your-domain.com
- **Adminer**: https://adminer.your-domain.com
- **Portainer**: https://portainer.your-domain.com

### **Security Checklist**
- [ ] EC2 Security Group: SSH (22) only
- [ ] Cloudflare Tunnel configured
- [ ] Strong passwords in .env
- [ ] Services bind to localhost only
- [ ] No public web ports exposed

---

**🎉 Congratulations! You now have a secure, production-ready PRS environment on AWS Graviton with Cloudflare Tunnel protection!** 🚀🔒
