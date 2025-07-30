# 🚀 PRS EC2 Graviton Setup Guide

Complete step-by-step guide to deploy PRS on AWS EC2 Graviton instances.

## 📋 Prerequisites

### AWS EC2 Instance Requirements
- **Instance Type**: t4g.medium (2 vCPU, 4GB RAM) or larger
- **Architecture**: ARM64 (Graviton)
- **AMI**: Amazon Linux 2 ARM64 or Ubuntu 20.04 ARM64
- **Storage**: Minimum 20GB EBS volume (GP3 recommended)
- **Security Group**: Ports 22, 80, 443, 8080, 3001

### Local Requirements
- SSH key pair for EC2 access
- Domain name (optional but recommended)
- SSL certificates (Let's Encrypt recommended)

## 🎯 Step 1: Launch EC2 Instance

### 1.1 Create EC2 Instance
```bash
# Using AWS CLI (optional)
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --instance-type t4g.medium \
    --key-name your-key-pair \
    --security-group-ids sg-xxxxxxxxx \
    --subnet-id subnet-xxxxxxxxx \
    --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]'
```

### 1.2 Configure Security Group
Allow these ports:
- **22**: SSH access
- **80**: HTTP (redirects to HTTPS)
- **443**: HTTPS (main application)
- **8080**: Adminer (database admin)
- **3001**: Grafana (monitoring)

## 🔧 Step 2: Initial Server Setup

### 2.1 Connect to Instance
```bash
# For Amazon Linux 2
ssh -i your-key.pem ec2-user@your-ec2-ip

# For Ubuntu
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 2.2 Run Setup Script
```bash
# Clone repository
git clone https://github.com/your-org/prs.git
cd prs/prs-production-deployment/ec2-graviton-setup

# Run automated setup
./scripts/setup-ec2.sh
```

The setup script will:
- ✅ Install Docker and Docker Compose
- ✅ Optimize system for 4GB memory
- ✅ Configure firewall
- ✅ Create swap file
- ✅ Install monitoring tools
- ✅ Set up project structure

### 2.3 Logout and Login
```bash
# Logout to apply Docker group membership
exit

# Login again
ssh -i your-key.pem ec2-user@your-ec2-ip
```

## ⚙️ Step 3: Configure Application

### 3.1 Environment Configuration
```bash
cd prs/prs-production-deployment/ec2-graviton-setup

# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

### 3.2 Critical Settings to Change
```bash
# Domain Configuration
DOMAIN=your-domain.com  # Your actual domain

# Database Security
POSTGRES_PASSWORD=your-super-strong-password-123!
POSTGRES_DB=prs_production
POSTGRES_USER=prs_user

# Application Security
JWT_SECRET=your-super-secure-jwt-secret-key-32-chars-minimum
ENCRYPTION_KEY=your-super-secure-encryption-key-32-chars
OTP_KEY=your-base64-encoded-otp-key-64-bytes-minimum
PASS_SECRET=your-password-secret-key

# Admin User
ROOT_USER_NAME=admin
ROOT_USER_EMAIL=admin@your-domain.com
ROOT_USER_PASSWORD=your-admin-password-123!

# Monitoring
GRAFANA_ADMIN_PASSWORD=your-grafana-password-123!

# CORS (add your domain)
CORS_ORIGIN=https://your-domain.com,https://www.your-domain.com
```

### 3.3 Memory Optimization (if needed)
For 4GB instances, these are already optimized:
```bash
# Container Memory Limits
BACKEND_MEMORY_LIMIT=1g
FRONTEND_MEMORY_LIMIT=512m
POSTGRES_MEMORY_LIMIT=1.5g
GRAFANA_MEMORY_LIMIT=256m
PROMETHEUS_MEMORY_LIMIT=256m

# Database Settings
POSTGRES_SHARED_BUFFERS=128MB
POSTGRES_EFFECTIVE_CACHE_SIZE=512MB
POSTGRES_WORK_MEM=4MB
```

## 🚀 Step 4: Deploy Application

### 4.1 Full Deployment
```bash
# Deploy everything
./scripts/deploy-ec2.sh deploy
```

This will:
- ✅ Build ARM64 Docker images
- ✅ Generate SSL certificates
- ✅ Start all services
- ✅ Initialize database
- ✅ Import database dump (if found)

### 4.2 Monitor Deployment
```bash
# Check status
./scripts/deploy-ec2.sh status

# Monitor resources
./scripts/deploy-ec2.sh monitor

# View logs
./scripts/deploy-ec2.sh logs
```

## 🗄️ Step 5: Database Import (Optional)

### 5.1 Prepare Database Dump
```bash
# If you have a database dump from local setup
scp -i your-key.pem dump_file_fixed_lineendings.sql ec2-user@your-ec2-ip:~/prs/prs-production-deployment/ec2-graviton-setup/
```

### 5.2 Import Database
```bash
# Import the dump
./scripts/deploy-ec2.sh import-db dump_file_fixed_lineendings.sql
```

## 🔒 Step 6: SSL Configuration (Production)

### 6.1 Install Certbot (Let's Encrypt)
```bash
# Amazon Linux 2
sudo yum install -y certbot

# Ubuntu
sudo apt install -y certbot
```

### 6.2 Generate SSL Certificate
```bash
# Stop nginx temporarily
./scripts/deploy-ec2.sh stop

# Generate certificate
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ssl/key.pem
sudo chown ec2-user:ec2-user ssl/*.pem

# Generate DH parameters
openssl dhparam -out ssl/dhparam.pem 2048

# Restart services
./scripts/deploy-ec2.sh start
```

### 6.3 Auto-Renewal Setup
```bash
# Add to crontab
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

## 🌐 Step 7: DNS Configuration

### 7.1 Point Domain to EC2
Create DNS A record:
- **Name**: your-domain.com
- **Type**: A
- **Value**: your-ec2-public-ip

### 7.2 Verify DNS
```bash
# Check DNS resolution
nslookup your-domain.com
dig your-domain.com
```

## 📊 Step 8: Monitoring Setup

### 8.1 Access Monitoring
- **Grafana**: http://your-domain.com:3001
- **Prometheus**: https://your-domain.com/prometheus

### 8.2 Grafana Configuration
1. Login with admin/your-grafana-password
2. Prometheus datasource should be auto-configured
3. Import PRS dashboard from config/grafana/dashboards/

## ✅ Step 9: Verification

### 9.1 Test All Services
```bash
# Run comprehensive tests
./scripts/deploy-ec2.sh status

# Check individual services
curl -k https://your-domain.com/health
curl -k https://your-domain.com/api/health
```

### 9.2 Access URLs
- **Main App**: https://your-domain.com
- **API**: https://your-domain.com/api
- **Database**: http://your-domain.com:8080
- **Monitoring**: http://your-domain.com:3001

## 🔧 Step 10: Ongoing Maintenance

### 10.1 Regular Monitoring
```bash
# Check system resources
monitor

# View container stats
docker stats

# Check logs
./scripts/deploy-ec2.sh logs
```

### 10.2 Backup Strategy
```bash
# Database backup
docker exec prs-ec2-postgres pg_dump -U prs_user prs_production > backup-$(date +%Y%m%d).sql

# System backup (use EBS snapshots)
aws ec2 create-snapshot --volume-id vol-xxxxxxxxx --description "PRS backup $(date)"
```

### 10.3 Updates
```bash
# Update application
git pull
./scripts/deploy-ec2.sh build
./scripts/deploy-ec2.sh restart
```

## 🚨 Troubleshooting

### Memory Issues
```bash
# Check memory usage
free -h
docker stats

# Reduce memory limits if needed
nano .env  # Adjust *_MEMORY_LIMIT values
./scripts/deploy-ec2.sh restart
```

### Performance Issues
```bash
# Check system load
uptime
htop

# Monitor I/O
iostat -x 1

# Check disk space
df -h
```

### SSL Issues
```bash
# Check certificate
openssl x509 -in ssl/cert.pem -text -noout

# Regenerate if needed
./scripts/deploy-ec2.sh ssl-setup
```

### Database Issues
```bash
# Check database logs
./scripts/deploy-ec2.sh logs postgres

# Restart database
docker restart prs-ec2-postgres

# Check connections
docker exec prs-ec2-postgres psql -U prs_user -d prs_production -c "SELECT version();"
```

## 📈 Scaling Recommendations

### When to Scale Up
- Memory usage consistently > 80%
- CPU usage consistently > 70%
- Response times increasing
- Database connection pool exhausted

### Scaling Options
1. **Vertical**: Upgrade to t4g.large (8GB RAM)
2. **Horizontal**: Multiple instances + load balancer
3. **Database**: Move to RDS PostgreSQL
4. **Storage**: Upgrade to larger EBS volumes

---

**Your PRS application is now running on AWS EC2 Graviton!** 🚀
