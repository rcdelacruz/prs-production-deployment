# PRS Production Logging System Documentation

## Overview

This document describes the comprehensive logging system implemented for the PRS (Purchase Requisition System) production environment on EC2 Graviton. The system provides structured logging, automatic retention management, and monitoring capabilities.

## Architecture

### Logging Components

1. **Application Logs** - Structured JSON logs from the backend application
2. **Container Logs** - Docker container stdout/stderr logs
3. **System Logs** - Infrastructure and monitoring logs
4. **Audit Logs** - Business transaction and security logs

### Log Storage

```
Production Logging Architecture:
┌─────────────────────────────────────────────────────────────┐
│                    PRS Backend Container                    │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   Application   │───▶│     /usr/app/logs/app.log       │ │
│  │   (Fastify +    │    │   (Persistent Docker Volume)   │ │
│  │    Pino Logger) │    │                                 │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
│           │                                                │
│           ▼                                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Docker Container Logs                     │ │
│  │           (Docker Logging Driver)                      │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│                 Log Management System                      │
│  • Automatic cleanup (7-day retention)                     │
│  • Log rotation and compression                            │
│  • Export and monitoring tools                             │
└─────────────────────────────────────────────────────────────┘
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_RETENTION_DAYS` | 7 | Days to retain application logs |
| `LOG_MAX_SIZE` | 100m | Maximum size per Docker log file |
| `LOG_LEVEL` | info | Application log level (debug, info, warn, error) |
| `NODE_ENV` | production | Environment mode affecting log format |

### Docker Compose Configuration

```yaml
# Backend service logging configuration
logging:
  driver: "json-file"
  options:
    max-size: "${LOG_MAX_SIZE:-100m}"  # Max 100MB per log file
    max-file: "5"                      # Keep 5 rotated files
    compress: "true"                   # Compress rotated logs
    labels: "service=prs-backend,environment=production"

# Persistent volume for application logs
volumes:
  - logs_data:/usr/app/logs  # Survives container recreation
```

## Application Logging Features

### Structured JSON Logging

The application uses **Pino** for high-performance structured logging:

```json
{
  "level": 30,
  "time": 1754955045982,
  "pid": 18,
  "hostname": "7d4aac8e2ba2",
  "x-request-id": "01989b78-dc5d-7998-b188-3a6ca264ad57",
  "type": "REQUEST",
  "requestId": "01989b78-dc5d-7998-b188-3a6ca264ad57",
  "timestamp": "2025-08-11T23:30:45.982Z",
  "method": "GET",
  "url": "/api/users",
  "clientIP": "127.0.0.1",
  "user": {
    "id": 123,
    "username": "john.doe",
    "role": "admin"
  },
  "environment": "production",
  "service": "prs-backend"
}
```

### Security Features

- **Sensitive Data Sanitization**: Passwords, tokens, and secrets are automatically redacted
- **Header Sanitization**: Authorization and cookie headers are removed from logs
- **Request/Response Logging**: Comprehensive request tracing with sanitized payloads
- **User Context**: User information included for audit trails

### Log Types

1. **Request Logs**: HTTP request details with sanitized headers and body
2. **Response Logs**: Response status, duration, and performance metrics
3. **Error Logs**: Comprehensive error context with stack traces
4. **Database Logs**: SQL queries with parameter binding (sanitized)
5. **Transaction Logs**: Business logic audit trails
6. **Worker Logs**: Background job processing logs

## Log Management

### Automated Cleanup

A cron job runs daily at 3 AM to clean up old logs:

```bash
# Cron job entry
0 3 * * * cd /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup && ./scripts/manage-logs.sh cleanup >> /var/log/prs-log-cleanup.log 2>&1
```

### Manual Log Management

Use the `manage-logs.sh` script for manual operations:

```bash
# Show log statistics
./scripts/manage-logs.sh stats

# Tail logs in real-time
./scripts/manage-logs.sh tail backend    # Backend logs
./scripts/manage-logs.sh tail nginx     # Nginx logs
./scripts/manage-logs.sh tail postgres  # Database logs
./scripts/manage-logs.sh tail all       # All services

# Search for errors
./scripts/manage-logs.sh search 24      # Last 24 hours
./scripts/manage-logs.sh search 1       # Last 1 hour

# Export logs for analysis
./scripts/manage-logs.sh export

# Manual cleanup
./scripts/manage-logs.sh cleanup
```

## Monitoring and Alerting

### Current Cron Jobs

| Time | Command | Purpose |
|------|---------|---------|
| 00:00 | `docker system prune -f` | Clean unused Docker resources |
| 03:00 | `./scripts/manage-logs.sh cleanup` | **Log retention cleanup** |
| 18:00 | `timescaledb-backup` | Database backup with 1-day retention |

### Log Monitoring

The system includes automated log monitoring:

- **Error Rate Monitoring**: Tracks 500 errors and database connection issues
- **Performance Monitoring**: Response time and resource usage tracking
- **Security Monitoring**: Authentication failures and suspicious activity
- **Health Checks**: Container and service health monitoring

### Log Files Locations

| Log Type | Location | Retention |
|----------|----------|-----------|
| Application Logs | `/usr/app/logs/app.log` (in container) | 7 days |
| Container Logs | Docker logging driver | 5 files × 100MB |
| Cleanup Logs | `/var/log/prs-log-cleanup.log` | System managed |
| Alert Logs | `/home/ubuntu/.../logs/alerts.log` | 7 days |
| Export Logs | `/home/ubuntu/.../log-exports/` | 7 days |

## Troubleshooting

### Common Issues

1. **Logs not appearing in files**
   - Check if `NODE_ENV=production` (not `local`)
   - Verify container has write access to `/usr/app/logs`
   - Check application startup logs for errors

2. **Logs disappearing after deployment**
   - ✅ **FIXED**: Logs now persist in Docker volumes
   - Application logs survive container recreation
   - Only Docker container logs are reset (by design)

3. **Disk space issues**
   - Check log retention settings
   - Run manual cleanup: `./scripts/manage-logs.sh cleanup`
   - Monitor with: `./scripts/manage-logs.sh stats`

### Verification Commands

```bash
# Check if logs are being written
docker exec prs-ec2-backend ls -la /usr/app/logs/

# Monitor live application logs
docker exec prs-ec2-backend tail -f /usr/app/logs/app.log

# Check container logs
docker logs prs-ec2-backend --tail 50

# Verify cron jobs
crontab -l

# Check cleanup log
tail -f /var/log/prs-log-cleanup.log
```

## Performance Considerations

- **Log Rotation**: Automatic rotation at 10MB with daily intervals
- **Compression**: Rotated logs are compressed to save space
- **Async Logging**: Pino provides high-performance async logging
- **Structured Format**: JSON format enables efficient parsing and analysis
- **Selective Logging**: Health checks and static files are excluded

## Security Considerations

- **Data Sanitization**: All sensitive data is automatically redacted
- **Access Control**: Log files have appropriate permissions
- **Audit Trail**: Comprehensive user action logging
- **Request Tracing**: Unique request IDs for correlation
- **Error Context**: Rich error information without exposing secrets

## Quick Reference

### Daily Operations

```bash
# Check log status
./scripts/manage-logs.sh stats

# Monitor backend logs
./scripts/manage-logs.sh tail backend

# Search for recent errors
./scripts/manage-logs.sh search 1

# Check disk usage
df -h
docker system df
```

### Emergency Procedures

```bash
# If logs are filling disk space
./scripts/manage-logs.sh cleanup
docker system prune -f

# If application logs are not working
docker exec prs-ec2-backend ls -la /usr/app/logs/
docker logs prs-ec2-backend | grep -i "log\|error"

# Export logs for analysis
./scripts/manage-logs.sh export
```

### Configuration Files

- **Main Config**: `ec2-graviton-setup/.env`
- **Docker Compose**: `ec2-graviton-setup/docker-compose.yml`
- **Log Management**: `ec2-graviton-setup/scripts/manage-logs.sh`
- **Backend Logging**: `prs-backend-a/src/infra/logs/`

## Implementation Notes

### Recent Changes (August 2025)

1. **Fixed Log Persistence**: Updated backend logging to write to persistent Docker volume
2. **Enhanced Log Management**: Improved script to handle container-based logs
3. **Automated Cleanup**: Added cron job for 7-day retention enforcement
4. **Structured Logging**: Implemented comprehensive JSON logging with security features

### Best Practices Implemented

- ✅ Structured JSON logging with Pino
- ✅ Request/response tracing with unique IDs
- ✅ Sensitive data sanitization
- ✅ Automatic log rotation and compression
- ✅ Persistent storage across deployments
- ✅ Automated retention management
- ✅ Comprehensive error logging
- ✅ Performance monitoring
- ✅ Security audit trails

---

**Last Updated**: August 11, 2025
**Version**: 1.0
**Environment**: Production EC2 Graviton t4g.medium
**Status**: ✅ Fully Operational
