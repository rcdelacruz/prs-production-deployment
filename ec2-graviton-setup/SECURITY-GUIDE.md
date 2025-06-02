# 🔒 PRS EC2 Security Guide

Complete security configuration guide for PRS deployment with restricted public access and Cloudflare Tunnel.

## 🎯 Security Architecture

### **Default Configuration: Restricted Access**
- ✅ All services bind to localhost only (127.0.0.1)
- ✅ No direct public internet access
- ✅ Access via Cloudflare Tunnel or SSH tunnel
- ✅ AWS Security Groups block all web ports
- ✅ Enhanced security headers and rate limiting

## 🌐 Cloudflare Tunnel Setup

### **Step 1: Create Cloudflare Tunnel**

1. **Go to Cloudflare Zero Trust Dashboard**
   ```
   https://one.dash.cloudflare.com/
   ```

2. **Navigate to Access > Tunnels**

3. **Create New Tunnel**
   - Click "Create a tunnel"
   - Choose "Cloudflared"
   - Name: `prs-ec2-tunnel`
   - Save tunnel

4. **Get Tunnel Token**
   - Copy the tunnel token
   - Add to `.env` file:
   ```bash
   CLOUDFLARE_TUNNEL_TOKEN=your-tunnel-token-here
   ```

### **Step 2: Configure Public Hostnames**

In Cloudflare dashboard, add these public hostnames:

| Subdomain | Domain | Service | Port |
|-----------|--------|---------|------|
| (root) | your-domain.com | HTTP | localhost:80 |
| grafana | your-domain.com | HTTP | localhost:3001 |
| adminer | your-domain.com | HTTP | localhost:8080 |
| portainer | your-domain.com | HTTP | localhost:9000 |

### **Step 3: Deploy with Tunnel**

```bash
# Run the Cloudflare setup script
./scripts/setup-cloudflare-tunnel.sh setup

# Or manually configure and deploy
cp .env.example .env
# Edit .env with your tunnel token and domain
./scripts/deploy-ec2.sh deploy
```

## 🔐 AWS Security Groups Configuration

### **Recommended Security Group Rules**

**Inbound Rules:**
| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| SSH | TCP | 22 | Your IP/32 | SSH access only from your IP |

**Outbound Rules:**
| Type | Protocol | Port | Destination | Description |
|------|----------|------|-------------|-------------|
| All Traffic | All | All | 0.0.0.0/0 | Allow all outbound |

### **Remove These Rules (if present):**
- ❌ HTTP (80) from 0.0.0.0/0
- ❌ HTTPS (443) from 0.0.0.0/0
- ❌ Custom TCP (8080) from 0.0.0.0/0
- ❌ Custom TCP (3001) from 0.0.0.0/0

## 🚇 SSH Tunnel Alternative

If you prefer SSH tunnels over Cloudflare Tunnel:

### **Setup SSH Tunnel**
```bash
# Forward all web services
ssh -L 80:localhost:80 \
    -L 443:localhost:443 \
    -L 8080:localhost:8080 \
    -L 9000:localhost:9000 \
    -L 3001:localhost:3001 \
    -N ec2-user@your-ec2-ip

# Then access locally:
# Main App: http://localhost
# Grafana: http://localhost:3001
# Adminer: http://localhost:8080
# Portainer: http://localhost:9000
```

### **Persistent SSH Tunnel (autossh)**
```bash
# Install autossh on your local machine
sudo apt install autossh  # Ubuntu/Debian
brew install autossh      # macOS

# Create persistent tunnel
autossh -M 20000 -L 80:localhost:80 \
        -L 443:localhost:443 \
        -L 8080:localhost:8080 \
        -L 9000:localhost:9000 \
        -L 3001:localhost:3001 \
        -N ec2-user@your-ec2-ip
```

## 🛡️ Additional Security Measures

### **1. Enable Fail2Ban**
```bash
# Install fail2ban
sudo yum install epel-release -y
sudo yum install fail2ban -y

# Configure for SSH protection
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### **2. Disable Password Authentication**
```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Set these values:
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no

# Restart SSH
sudo systemctl restart sshd
```

### **3. Configure UFW Firewall**
```bash
# Install and configure UFW
sudo yum install ufw -y

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH from your IP only
sudo ufw allow from YOUR_IP_ADDRESS to any port 22

# Enable firewall
sudo ufw enable
```

### **4. Regular Security Updates**
```bash
# Create update script
cat << 'EOF' > /home/ec2-user/update-system.sh
#!/bin/bash
sudo yum update -y
docker system prune -f
EOF

chmod +x /home/ec2-user/update-system.sh

# Add to crontab (weekly updates)
echo "0 2 * * 0 /home/ec2-user/update-system.sh" | crontab -
```

## 🔍 Monitoring and Alerting

### **1. Setup CloudWatch Monitoring**
```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
```

### **2. Configure Log Monitoring**
```bash
# Monitor auth logs for intrusion attempts
sudo tail -f /var/log/secure

# Monitor Docker logs
docker logs prs-ec2-nginx --follow
```

### **3. Setup Grafana Alerts**
Configure alerts in Grafana for:
- High CPU usage (>80%)
- High memory usage (>90%)
- Failed login attempts
- Service downtime

## 🔐 Application Security

### **1. Environment Variables Security**
```bash
# Secure .env file
chmod 600 .env
chown ec2-user:ec2-user .env

# Never commit .env to git
echo ".env" >> .gitignore
```

### **2. Database Security**
```bash
# Strong passwords in .env
POSTGRES_PASSWORD=your-super-strong-password-with-special-chars!@#$
JWT_SECRET=your-super-long-jwt-secret-key-minimum-32-characters
ENCRYPTION_KEY=your-encryption-key-32-chars-minimum
```

### **3. SSL/TLS Configuration**
```bash
# Generate strong DH parameters
openssl dhparam -out ssl/dhparam.pem 4096

# Use strong SSL ciphers (already configured in nginx.conf)
```

## 🚨 Incident Response

### **1. Suspicious Activity Detection**
```bash
# Check for failed login attempts
sudo grep "Failed password" /var/log/secure

# Check for unusual network connections
sudo netstat -tuln | grep LISTEN

# Check running processes
ps aux | grep -v "\[.*\]"
```

### **2. Emergency Procedures**
```bash
# Immediately block all traffic
sudo ufw deny incoming

# Stop all services
./scripts/deploy-ec2.sh stop

# Check system integrity
sudo find /etc -name "*.conf" -mtime -1
```

### **3. Backup and Recovery**
```bash
# Emergency database backup
docker exec prs-ec2-postgres pg_dump -U prs_user prs_production > emergency-backup-$(date +%Y%m%d-%H%M%S).sql

# Create EBS snapshot
aws ec2 create-snapshot --volume-id vol-xxxxxxxxx --description "Emergency backup $(date)"
```

## 📋 Security Checklist

### **Pre-Deployment**
- [ ] Strong passwords in .env file
- [ ] SSH key-based authentication only
- [ ] Security Groups configured (SSH only)
- [ ] Cloudflare Tunnel configured
- [ ] SSL certificates generated

### **Post-Deployment**
- [ ] Verify no public ports are accessible
- [ ] Test Cloudflare Tunnel access
- [ ] Configure monitoring alerts
- [ ] Setup automated backups
- [ ] Enable fail2ban
- [ ] Configure log monitoring

### **Ongoing Maintenance**
- [ ] Regular security updates
- [ ] Monitor access logs
- [ ] Review Grafana alerts
- [ ] Rotate passwords quarterly
- [ ] Update SSL certificates
- [ ] Review Security Group rules

## 🔧 Troubleshooting Security Issues

### **Cloudflare Tunnel Not Working**
```bash
# Check tunnel status
docker logs prs-ec2-cloudflared

# Test tunnel token
cloudflared tunnel --no-autoupdate run --token $CLOUDFLARE_TUNNEL_TOKEN

# Verify DNS settings in Cloudflare
```

### **SSH Access Issues**
```bash
# Check SSH service
sudo systemctl status sshd

# Review SSH logs
sudo tail -f /var/log/secure

# Test SSH key
ssh -vvv -i your-key.pem ec2-user@your-ec2-ip
```

### **Service Access Issues**
```bash
# Check if services are binding to localhost
sudo netstat -tuln | grep 127.0.0.1

# Verify Docker port bindings
docker port prs-ec2-nginx
```

## 📞 Emergency Contacts

Document these for your team:
- AWS Account Administrator
- Cloudflare Account Owner
- Domain Registrar Contact
- Security Team Contact

---

**This security configuration provides enterprise-grade protection for your PRS deployment!** 🛡️
