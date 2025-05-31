# PRS Production Deployment Guide

This guide provides step-by-step instructions for deploying the PRS (Purchase Requisition System) to a production environment using either Docker Swarm or Kubernetes.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Docker Swarm Deployment](#docker-swarm-deployment)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Monitoring Setup](#monitoring-setup)
7. [Backup Configuration](#backup-configuration)
8. [Maintenance Procedures](#maintenance-procedures)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Infrastructure Requirements

- **Minimum Resources per Node**:
  - 4 CPU cores
  - 16GB RAM
  - 100GB SSD storage
  - 1Gbps network connection

- **Recommended Production Setup**:
  - 3+ nodes for high availability
  - Load balancer (cloud or hardware)
  - Dedicated database server or managed database
  - Shared storage (NFS, cloud storage)
  - SSL certificates (Let's Encrypt or commercial)

### Software Requirements

- Docker Engine 20.10+ or Kubernetes 1.20+
- Docker Compose 2.0+ (for Swarm deployment)
- kubectl and helm (for Kubernetes deployment)
- SSL certificates for your domain
- DNS configuration pointing to your load balancer

### Domain and SSL Setup

You'll need:
- A registered domain (e.g., `your-domain.com`)
- Subdomains configured:
  - `api.your-domain.com` for the API
  - `monitoring.your-domain.com` for monitoring dashboards
- SSL certificates for all domains

## Infrastructure Setup

### 1. DNS Configuration

Configure your DNS with the following records:

```
A       your-domain.com           -> YOUR_LOAD_BALANCER_IP
A       api.your-domain.com       -> YOUR_LOAD_BALANCER_IP
A       monitoring.your-domain.com -> YOUR_LOAD_BALANCER_IP
CNAME   www.your-domain.com       -> your-domain.com
```

### 2. Firewall Configuration

Open the following ports:

```bash
# HTTP/HTTPS
80/tcp   (HTTP)
443/tcp  (HTTPS)

# SSH (restrict to your IP)
22/tcp   (SSH - restrict source)

# Docker Swarm (if using)
2377/tcp (cluster management)
7946/tcp (node communication)
4789/udp (overlay network)

# Kubernetes (if using)
6443/tcp (API server)
2379-2380/tcp (etcd)
10250/tcp (kubelet)
10251/tcp (kube-scheduler)
10252/tcp (kube-controller-manager)
```

### 3. Storage Configuration

For shared storage, you can use:

**NFS Setup:**
```bash
# On NFS server
sudo apt update && sudo apt install nfs-kernel-server
echo "/exports/prs-production *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# On client nodes
sudo apt install nfs-common
sudo mkdir -p /mnt/prs-storage
```

**Cloud Storage:** Configure according to your cloud provider (AWS EFS, Azure Files, GCP Filestore).

## Docker Swarm Deployment

### Step 1: Initialize Docker Swarm

On the manager node:

```bash
# Initialize swarm
docker swarm init --advertise-addr YOUR_MANAGER_IP

# Get join token for workers
docker swarm join-token worker
```

On worker nodes:
```bash
# Join the swarm (use token from manager)
docker swarm join --token SWMTKN-... MANAGER_IP:2377
```

### Step 2: Clone and Setup Repository

```bash
# Clone the deployment repository
git clone https://github.com/rcdelacruz/prs-production-deployment.git
cd prs-production-deployment

# Make scripts executable
chmod +x scripts/*.sh
```

### Step 3: Configure Environment

```bash
# Copy example configurations
cp examples/.env.production.example .env.production
cp examples/backend.prod.env.example backend.prod.env
cp examples/frontend.prod.env.example frontend.prod.env

# Edit configurations for your environment
nano .env.production
nano backend.prod.env
nano frontend.prod.env
```

**Important Environment Variables to Update:**

In `.env.production`:
```bash
DOMAIN=your-domain.com
SUBDOMAIN_API=api.your-domain.com
SUBDOMAIN_MONITOR=monitoring.your-domain.com
SSL_EMAIL=admin@your-domain.com
```

In `backend.prod.env`:
```bash
CORS_ORIGIN=https://your-domain.com,https://api.your-domain.com
ROOT_USER_EMAIL=admin@your-domain.com
CITYLAND_API_URL=https://your-actual-api-url.com
```

In `frontend.prod.env`:
```bash
VITE_APP_API_URL=https://api.your-domain.com
VITE_APP_UPLOAD_URL=https://api.your-domain.com/upload
```

### Step 4: Setup Secrets and SSL

```bash
# Create all secrets and SSL certificates
./scripts/setup-secrets.sh --all your-domain.com

# For testing, use staging SSL certificates
./scripts/setup-secrets.sh --all your-domain.com true
```

### Step 5: Deploy the Application

```bash
# Deploy the complete stack
./scripts/deploy-production.sh --deploy --init-db

# Check deployment status
./scripts/deploy-production.sh --health-check
```

### Step 6: Verify Deployment

```bash
# Check service status
docker stack services prs-production

# View service logs
./scripts/deploy-production.sh --logs backend
./scripts/deploy-production.sh --logs frontend

# Test endpoints
curl -k https://your-domain.com/health
curl -k https://api.your-domain.com/health
```

## Kubernetes Deployment

### Step 1: Prepare Kubernetes Cluster

Ensure you have a running Kubernetes cluster with:
- Ingress controller (nginx-ingress recommended)
- Cert-manager for SSL certificates
- Storage provisioner for persistent volumes

```bash
# Install nginx-ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
```

### Step 2: Create Cluster Issuer for SSL

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@your-domain.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
kubectl apply -f cluster-issuer.yaml
```

### Step 3: Create Secrets

```bash
# Create namespace first
kubectl apply -f k8s/00-namespace-configmaps.yaml

# Create secrets (adapt the secret creation script for K8s)
kubectl create secret generic postgres-secret \
  --from-literal=password="$(openssl rand -base64 32)" \
  -n prs-production

kubectl create secret generic app-secrets \
  --from-literal=jwt-secret="$(openssl rand -hex 64)" \
  --from-literal=encryption-key="$(openssl rand -hex 32)" \
  --from-literal=otp-key="$(openssl rand -base64 64)" \
  --from-literal=pass-secret="$(openssl rand -base64 32)" \
  -n prs-production

kubectl create secret generic redis-secret \
  --from-literal=password="$(openssl rand -base64 32)" \
  -n prs-production

kubectl create secret generic minio-secret \
  --from-literal=access-key="minioadmin$(openssl rand -base64 10 | tr -d '=' | cut -c1-10)" \
  --from-literal=secret-key="$(openssl rand -base64 32)" \
  -n prs-production
```

### Step 4: Deploy Applications

```bash
# Update domain names in K8s manifests
sed -i 's/your-domain.com/yourdomain.com/g' k8s/*.yaml

# Deploy applications
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n prs-production
kubectl get services -n prs-production
kubectl get ingress -n prs-production
```

### Step 5: Verify Deployment

```bash
# Check pod status
kubectl get pods -n prs-production -w

# View logs
kubectl logs -f deployment/prs-backend -n prs-production
kubectl logs -f deployment/prs-frontend -n prs-production

# Test endpoints
curl https://your-domain.com/health
curl https://api.your-domain.com/health
```

## Post-Deployment Configuration

### 1. Initial Admin User

After successful deployment, access the application and create the initial admin user:

1. Go to `https://your-domain.com`
2. Register the first admin account
3. Verify email if email service is configured
4. Log in and configure system settings

### 2. Database Initialization

```bash
# For Docker Swarm
./scripts/deploy-production.sh --init-db

# For Kubernetes
kubectl exec -it deployment/prs-backend -n prs-production -- npm run migrate
kubectl exec -it deployment/prs-backend -n prs-production -- npm run seed:production
```

### 3. Configure External Integrations

Update your configuration with actual API endpoints:

```bash
# Edit backend configuration
nano backend.prod.env

# Update these values:
CITYLAND_API_URL=https://actual-api-url.com
CITYLAND_ACCOUNTING_URL=https://actual-accounting-url.com

# Restart backend services
# Docker Swarm:
./scripts/deploy-production.sh --restart backend

# Kubernetes:
kubectl rollout restart deployment/prs-backend -n prs-production
```

## Monitoring Setup

### 1. Access Monitoring Dashboards

- **Grafana**: `https://monitoring.your-domain.com/grafana`
  - Username: `admin`
  - Password: Check secrets or deployment logs

- **Prometheus**: `https://monitoring.your-domain.com/prometheus`
- **AlertManager**: `https://monitoring.your-domain.com/alertmanager`

### 2. Configure Alerting

Update AlertManager configuration for your notification channels:

```yaml
# monitoring/alertmanager/alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@your-domain.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  email_configs:
  - to: 'admin@your-domain.com'
    subject: 'PRS Production Alert'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts'
```

### 3. Import Grafana Dashboards

Pre-configured dashboards are available in `monitoring/grafana/dashboards/`. Import them through the Grafana UI or provision them automatically.

## Backup Configuration

### 1. Automated Backups

Set up automated daily backups:

```bash
# Create backup cron job
echo "0 2 * * * /path/to/prs-production-deployment/scripts/backup.sh --backup" | crontab -

# Test backup manually
./scripts/backup.sh --backup
```

### 2. Cloud Storage Setup

Configure AWS S3 for backup storage:

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
```

### 3. Backup Verification

```bash
# List available backups
./scripts/backup.sh --list

# Verify backup integrity
./scripts/backup.sh --verify backup_file.gpg

# Test restore process
./scripts/backup.sh --restore backup_file.sql.gz
```

## Maintenance Procedures

### 1. Regular Updates

**Application Updates:**

```bash
# Docker Swarm
./scripts/deploy-production.sh --update v1.2.0

# Kubernetes
kubectl set image deployment/prs-backend backend=prs-backend:v1.2.0 -n prs-production
kubectl set image deployment/prs-frontend frontend=prs-frontend:v1.2.0 -n prs-production
```

**Security Updates:**

```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update Docker
curl -fsSL https://get.docker.com | sh

# Update Kubernetes
kubeadm upgrade plan
kubeadm upgrade apply v1.28.0
```

### 2. SSL Certificate Renewal

Certificates should auto-renew, but you can force renewal:

```bash
# Let's Encrypt certificates
docker run --rm -it \
  -v $(pwd)/security/certificates:/etc/letsencrypt \
  certbot/certbot renew

# Update Docker secrets
docker secret rm ssl_certificate ssl_private_key
docker secret create ssl_certificate ./security/certificates/live/your-domain.com/fullchain.pem
docker secret create ssl_private_key ./security/certificates/live/your-domain.com/privkey.pem
```

### 3. Database Maintenance

```bash
# Database vacuum and analyze
docker exec -it $(docker ps -q -f name=postgres-primary) psql -U prs_user -d prs_production -c "VACUUM ANALYZE;"

# Check database size
docker exec -it $(docker ps -q -f name=postgres-primary) psql -U prs_user -d prs_production -c "\l+"
```

### 4. Log Rotation

```bash
# Configure logrotate
cat > /etc/logrotate.d/prs-production << EOF
/var/log/prs-production/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker kill -s USR1 \$(docker ps -q -f name=prs-production)
    endscript
}
EOF
```

## Troubleshooting

### Common Issues

**1. Services Not Starting**

```bash
# Check service status
docker stack services prs-production
kubectl get pods -n prs-production

# View detailed logs
docker service logs prs-production_backend
kubectl logs -f deployment/prs-backend -n prs-production

# Check resource usage
docker stats
kubectl top nodes
kubectl top pods -n prs-production
```

**2. Database Connection Issues**

```bash
# Test database connectivity
docker exec -it $(docker ps -q -f name=postgres-primary) psql -U prs_user -d prs_production -c "SELECT version();"

# Check database logs
docker logs $(docker ps -q -f name=postgres-primary)

# Verify secrets
docker secret ls
kubectl get secrets -n prs-production
```

**3. SSL Certificate Issues**

```bash
# Check certificate status
openssl x509 -in ./security/certificates/live/your-domain.com/fullchain.pem -text -noout

# Test SSL endpoint
curl -vI https://your-domain.com

# Check cert-manager (Kubernetes)
kubectl get certificates -n prs-production
kubectl describe certificate prs-tls-secret -n prs-production
```

**4. Performance Issues**

```bash
# Check resource usage
docker stats
kubectl top nodes
kubectl top pods -n prs-production

# Scale services
./scripts/deploy-production.sh --scale 5 3
kubectl scale deployment prs-backend --replicas=5 -n prs-production

# Check database performance
docker exec -it $(docker ps -q -f name=postgres-primary) psql -U prs_user -d prs_production -c "SELECT * FROM pg_stat_activity;"
```

### Health Checks

**Application Health:**
```bash
# Basic health check
curl -f https://your-domain.com/health
curl -f https://api.your-domain.com/health

# Detailed health check
./scripts/deploy-production.sh --health-check
```

**Database Health:**
```bash
# Check database status
docker exec -it $(docker ps -q -f name=postgres-primary) pg_isready -U prs_user -d prs_production

# Check replication lag (if using replicas)
docker exec -it $(docker ps -q -f name=postgres-primary) psql -U prs_user -d prs_production -c "SELECT * FROM pg_stat_replication;"
```

**Monitoring Health:**
```bash
# Check monitoring stack
curl -f https://monitoring.your-domain.com/prometheus/api/v1/query?query=up
curl -f https://monitoring.your-domain.com/grafana/api/health
```

### Emergency Procedures

**1. Rollback Deployment**

```bash
# Docker Swarm
./scripts/deploy-production.sh --rollback

# Kubernetes
kubectl rollout undo deployment/prs-backend -n prs-production
kubectl rollout undo deployment/prs-frontend -n prs-production
```

**2. Emergency Database Restore**

```bash
# Stop application services
docker service scale prs-production_backend=0

# Restore from backup
./scripts/backup.sh --restore latest_backup.sql.gz

# Restart services
docker service scale prs-production_backend=3
```

**3. Scale Down for Maintenance**

```bash
# Docker Swarm
./scripts/deploy-production.sh --scale 0 0

# Kubernetes
kubectl scale deployment prs-backend --replicas=0 -n prs-production
kubectl scale deployment prs-frontend --replicas=0 -n prs-production
```

## Security Checklist

- [ ] SSL certificates properly configured and auto-renewing
- [ ] All secrets are encrypted and not stored in plain text
- [ ] Database connections use SSL/TLS
- [ ] Network policies restrict inter-pod communication
- [ ] Rate limiting configured on all public endpoints
- [ ] Security headers configured in Nginx/Ingress
- [ ] Regular security updates applied
- [ ] Backup encryption enabled
- [ ] Monitoring and alerting configured for security events
- [ ] Access logs retained for audit purposes

## Performance Optimization

### Database Optimization

```sql
-- Create indexes for common queries
CREATE INDEX CONCURRENTLY idx_requisitions_status ON requisitions(status);
CREATE INDEX CONCURRENTLY idx_requisitions_created_at ON requisitions(created_at);
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- Update table statistics
ANALYZE;
```

### Caching Strategy

1. **Application-level caching**: Configure Redis for session and data caching
2. **Database query caching**: Enable PostgreSQL query caching
3. **Static asset caching**: Configure CDN for frontend assets
4. **API response caching**: Implement response caching for read-heavy endpoints

### Resource Tuning

**PostgreSQL Configuration:**
```bash
# Edit postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
```

**Redis Configuration:**
```bash
# Edit redis.conf
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

## Disaster Recovery

### Backup Strategy

1. **Database backups**: Daily encrypted backups with 30-day retention
2. **File system backups**: Daily backups of uploaded files
3. **Configuration backups**: Version-controlled deployment configurations
4. **Testing**: Monthly restore testing

### Recovery Procedures

1. **Data Loss Recovery**: Restore from latest backup and replay transaction logs
2. **Service Outage**: Implement circuit breakers and graceful degradation
3. **Infrastructure Failure**: Multi-region deployment with automatic failover
4. **Security Incident**: Incident response plan with isolation and forensics

This comprehensive deployment guide should help you successfully deploy PRS to production with high availability, security, and monitoring. Remember to customize all configurations for your specific environment and requirements.
