# PRS Production Scripts

This directory contains management scripts for the PRS production environment on EC2 Graviton.

## Scripts Overview

### 🗂️ Log Management
- **`manage-logs.sh`** - Comprehensive log management and monitoring
- **`log-monitor.sh`** - Real-time log monitoring and alerting

### 🚀 Deployment
- **`deploy-ec2.sh`** - Main deployment and service management script

### 🗄️ Database Management
- **`timescaledb-production-backup.sh`** - Database backup and maintenance
- **`manage-redis.sh`** - Redis cache and queue management

## Log Management Script Usage

### Quick Commands

```bash
# Show current log status
./manage-logs.sh stats

# Monitor logs in real-time
./manage-logs.sh tail backend    # Backend application logs
./manage-logs.sh tail nginx     # Web server logs
./manage-logs.sh tail postgres  # Database logs
./manage-logs.sh tail all       # All services

# Search for errors
./manage-logs.sh search 1       # Last 1 hour
./manage-logs.sh search 24      # Last 24 hours

# Export logs for analysis
./manage-logs.sh export

# Clean up old logs (7+ days)
./manage-logs.sh cleanup
```

### Example Output

```bash
$ ./manage-logs.sh stats

[2025-08-11 23:32:58] 📊 Production Log Statistics
==================================

Docker Container Logs:
  prs-ec2-backend: 49 lines, 3.0K
  prs-ec2-nginx: 31571 lines, 8.8M
  prs-ec2-postgres-timescale: 5910 lines, 26M

Application Log Files (in container):
  /usr/app/logs/app.log: 420.5K

Local Application Log Files:
  /home/ubuntu/.../logs/alerts.log: 101

Docker System Log Usage:
TYPE            TOTAL     SIZE      RECLAIMABLE
Images          15        8.662GB   2.712GB (31%)
Containers      12        48.06MB   0B (0%)
Local Volumes   8         581.7MB   0B (0%)
Build Cache     41        1.133GB   1.133GB
```

## Automated Processes

### Cron Jobs

The following cron jobs are configured for automated maintenance:

```bash
# Daily at midnight - Clean unused Docker resources
0 0 * * * /usr/bin/docker system prune -f > /dev/null 2>&1

# Daily at 3 AM - Clean old logs (7+ days)
0 3 * * * cd /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup && ./scripts/manage-logs.sh cleanup >> /var/log/prs-log-cleanup.log 2>&1

# Daily at 6 PM - Database backup with 1-day retention
0 18 * * * /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup/scripts/deploy-ec2.sh timescaledb-backup && find /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup/backups/ -name 'timescaledb_backup_*.dump' -mtime +1 -delete && find /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup/backups/ -name 'timescaledb_backup_*.sql' -mtime +1 -delete
```

### Log Retention Policy

- **Application Logs**: 7 days (configurable via `LOG_RETENTION_DAYS`)
- **Docker Container Logs**: 5 files × 100MB each (automatic rotation)
- **Database Backups**: 1 day retention
- **Log Exports**: 7 days retention

## Environment Variables

Key environment variables affecting script behavior:

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_RETENTION_DAYS` | 7 | Days to keep application logs |
| `LOG_MAX_SIZE` | 100m | Maximum Docker log file size |
| `LOG_LEVEL` | info | Application logging level |

## Troubleshooting

### Common Issues

1. **Script permissions**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Log cleanup not working**
   ```bash
   # Check cron job status
   crontab -l
   
   # Check cleanup log
   tail -f /var/log/prs-log-cleanup.log
   
   # Run manual cleanup
   ./scripts/manage-logs.sh cleanup
   ```

3. **Container not found errors**
   ```bash
   # Check running containers
   docker ps
   
   # Check service status
   ./scripts/deploy-ec2.sh status
   ```

### Monitoring

```bash
# Check script execution logs
tail -f /var/log/prs-log-cleanup.log

# Monitor system resources
./scripts/manage-logs.sh stats

# Check cron service
systemctl status cron
```

## Security Notes

- Scripts sanitize sensitive data in logs
- Log files have appropriate permissions
- Cleanup logs are stored in `/var/log/` for system monitoring
- All operations are logged for audit purposes

---

For detailed logging system documentation, see: `../LOGGING_SYSTEM_DOCUMENTATION.md`
