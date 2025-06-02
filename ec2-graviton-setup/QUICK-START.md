# ⚡ PRS EC2 Quick Start - Secure Setup

Ultra-fast deployment guide for PRS on EC2 with Cloudflare Tunnel security.

## 🚀 5-Minute Setup

### **1. Launch EC2 Instance**
```bash
# Instance: t4g.medium (ARM64)
# Security Group: SSH (22) only
# Storage: 20GB+ EBS
```

### **2. Connect and Setup**
```bash
ssh -i your-key.pem ec2-user@your-ec2-ip

# Clone and setup
git clone <your-repo>
cd prs/prs-production-deployment/ec2-graviton-setup
./scripts/setup-ec2.sh
```

### **3. Configure Environment**
```bash
cp .env.example .env
nano .env

# Essential changes:
DOMAIN=your-domain.com
CLOUDFLARE_TUNNEL_TOKEN=your-tunnel-token
POSTGRES_PASSWORD=strong-password-123!
JWT_SECRET=your-super-long-jwt-secret-key
```

### **4. Setup Cloudflare Tunnel**
```bash
./scripts/setup-cloudflare-tunnel.sh setup
# Follow prompts to configure tunnel
```

### **5. Deploy**
```bash
./scripts/deploy-ec2.sh deploy
```

## 🌐 Cloudflare Tunnel Configuration

### **Create Tunnel**
1. Go to https://one.dash.cloudflare.com/
2. Access > Tunnels > Create tunnel
3. Name: `prs-ec2-tunnel`
4. Copy tunnel token

### **Configure Hostnames**
| Subdomain | Service | Port |
|-----------|---------|------|
| (root) | HTTP | localhost:80 |
| grafana | HTTP | localhost:3001 |
| adminer | HTTP | localhost:8080 |
| portainer | HTTP | localhost:9000 |

## 🔒 Security Checklist

### **AWS Security Group**
- ✅ SSH (22) from your IP only
- ❌ Remove HTTP (80)
- ❌ Remove HTTPS (443)
- ❌ Remove all other web ports

### **Environment Security**
- ✅ Strong passwords in .env
- ✅ Unique JWT secrets
- ✅ ENABLE_PUBLIC_ACCESS=false

## 📊 Access Your Services

### **Public Access (via Cloudflare)**
- Main App: https://your-domain.com
- Grafana: https://grafana.your-domain.com
- Adminer: https://adminer.your-domain.com
- Portainer: https://portainer.your-domain.com

### **Local Access (via SSH tunnel)**
```bash
ssh -L 80:localhost:80 -L 8080:localhost:8080 -L 9000:localhost:9000 -L 3001:localhost:3001 ec2-user@your-ec2-ip
```

## 🔧 Essential Commands

```bash
# Service management
./scripts/deploy-ec2.sh status    # Check status
./scripts/deploy-ec2.sh logs      # View logs
./scripts/deploy-ec2.sh restart   # Restart services

# Cloudflare tunnel
./scripts/setup-cloudflare-tunnel.sh status  # Tunnel status
./scripts/setup-cloudflare-tunnel.sh deploy  # Deploy with tunnel

# Database
./scripts/deploy-ec2.sh import-db file.sql   # Import database
./scripts/deploy-ec2.sh init-db              # Fresh database

# Monitoring
./scripts/deploy-ec2.sh monitor   # Resource monitoring
monitor                          # Quick system check
```

## 🚨 Troubleshooting

### **Can't Access Services**
```bash
# Check tunnel status
docker logs prs-ec2-cloudflared

# Verify services are running
./scripts/deploy-ec2.sh status

# Check if binding to localhost
sudo netstat -tuln | grep 127.0.0.1
```

### **Memory Issues**
```bash
# Check memory usage
free -h
docker stats

# Reduce memory limits in .env:
BACKEND_MEMORY_LIMIT=768m
POSTGRES_MEMORY_LIMIT=1g
```

### **Database Issues**
```bash
# Check database logs
./scripts/deploy-ec2.sh logs postgres

# Restart database
docker restart prs-ec2-postgres
```

## 📋 Environment Template

```bash
# Domain and Tunnel
DOMAIN=your-domain.com
CLOUDFLARE_TUNNEL_TOKEN=your-tunnel-token-here

# Security (CHANGE THESE!)
POSTGRES_PASSWORD=super-strong-password-123!
JWT_SECRET=your-super-long-jwt-secret-key-minimum-32-chars
ENCRYPTION_KEY=your-encryption-key-32-chars-minimum
ROOT_USER_PASSWORD=admin-password-123!
GRAFANA_ADMIN_PASSWORD=grafana-password-123!

# Access Control
ENABLE_PUBLIC_ACCESS=false
ALLOWED_IPS=127.0.0.1,::1

# Memory Optimization (4GB instance)
BACKEND_MEMORY_LIMIT=1g
FRONTEND_MEMORY_LIMIT=512m
POSTGRES_MEMORY_LIMIT=1.5g
GRAFANA_MEMORY_LIMIT=256m
PROMETHEUS_MEMORY_LIMIT=256m
```

## 🎯 Production Checklist

- [ ] EC2 instance launched (t4g.medium)
- [ ] Security Group configured (SSH only)
- [ ] Cloudflare Tunnel created
- [ ] Environment variables configured
- [ ] Strong passwords set
- [ ] Services deployed and running
- [ ] Database imported (if needed)
- [ ] Monitoring accessible
- [ ] Backup strategy planned

## 📞 Support

- **Security Guide**: `SECURITY-GUIDE.md`
- **Full Setup**: `SETUP-GUIDE.md`
- **Comparison**: `COMPARISON.md`
- **Main README**: `README.md`

---

**Your secure PRS deployment is ready in minutes!** 🚀🔒
