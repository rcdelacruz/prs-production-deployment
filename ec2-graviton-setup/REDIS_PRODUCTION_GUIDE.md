# Redis Production Setup Guide

This guide covers the Redis production setup for the PRS application on EC2 Graviton instances.

## Overview

Redis is used in the PRS application for:
- **Background Job Processing**: BullMQ queue system for data synchronization with Cityland API
- **Caching**: Application-level caching for improved performance
- **Session Management**: Future session storage capabilities

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PRS Backend   │───▶│      Redis      │◀───│  Redis Worker   │
│   (Producer)    │    │   (Queue/Cache) │    │   (Consumer)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Configuration

### Environment Variables

The following Redis configuration is set in `.env`:

```bash
# Redis Configuration (Production Queue and Cache)
REDIS_ENABLED=true
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=R3d1sP@ssw0rd2024!
REDIS_MEMORY_LIMIT=256m
```

### Container Resource Limits

Redis is configured with memory-optimized settings for EC2 t4g.medium:

- **Memory Limit**: 256MB
- **CPU Limit**: 0.25 cores
- **Persistence**: AOF (Append Only File) enabled
- **Memory Policy**: allkeys-lru (evict least recently used keys)

## Services

### 1. Redis Server (`redis`)

- **Image**: `redis:7-alpine`
- **Container**: `prs-ec2-redis`
- **Network IP**: `172.22.0.35`
- **Persistence**: `/data` volume mounted
- **Configuration**:
  - Password authentication enabled
  - AOF persistence with `everysec` fsync
  - Memory limit with LRU eviction policy
  - Optimized for production workloads

### 2. Redis Worker (`redis-worker`)

- **Image**: `prs-backend-worker:latest`
- **Container**: `prs-ec2-redis-worker`
- **Network IP**: `172.22.0.40`
- **Purpose**: Processes background jobs from BullMQ queues
- **Dependencies**: PostgreSQL and Redis

## Queue Management

### BullMQ Queues

The application uses BullMQ for reliable job processing:

- **Queue Name**: `prs-data-sync`
- **Job Types**:
  - `supplier`: Synchronize supplier data from Cityland API
  - `item`: Synchronize item data from Cityland API
- **Retry Policy**: 3 attempts with exponential backoff
- **Concurrency**: 1 (prevents overwhelming external APIs)

### Job Processing Flow

1. **Job Creation**: Backend API creates jobs in Redis queue
2. **Job Processing**: Redis worker picks up jobs and processes them
3. **Error Handling**: Failed jobs are retried with exponential backoff
4. **Cleanup**: Completed jobs are automatically removed (keep last 100)

## Management Commands

### Basic Operations

```bash
# Check Redis status and information
./scripts/deploy-ec2.sh redis-info

# Test Redis connectivity
./scripts/deploy-ec2.sh redis-ping

# Monitor queue status and job processing
./scripts/deploy-ec2.sh redis-monitor

# View Redis logs
./scripts/deploy-ec2.sh redis-logs

# Restart Redis container
./scripts/deploy-ec2.sh redis-restart

# Create Redis backup
./scripts/deploy-ec2.sh redis-backup
```

### Advanced Management

```bash
# Direct Redis management script
./scripts/manage-redis.sh [command]

# Available commands:
# - info: Show Redis server information
# - ping: Test connectivity
# - monitor: Monitor queues
# - clear: Clear all queues (use with caution)
# - backup: Create data backup
# - logs: Show container logs
# - restart: Restart container
```

## Monitoring

### Health Checks

Redis container includes health checks:
- **Command**: `redis-cli ping` (with authentication)
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3
- **Start Period**: 30 seconds

### Queue Monitoring

Monitor queue status to ensure jobs are processing:

```bash
# Check queue statistics
./scripts/deploy-ec2.sh redis-monitor

# Expected output shows:
# - Waiting jobs count
# - Active jobs count
# - Completed jobs count
# - Failed jobs count
```

### Memory Usage

Monitor Redis memory usage:

```bash
# View memory information
./scripts/manage-redis.sh info
```

## Backup and Recovery

### Automatic Backups

Redis is configured with:
- **AOF Persistence**: Logs every write operation
- **RDB Snapshots**: Periodic snapshots for faster recovery
- **Save Points**:
  - Every 900 seconds if at least 1 key changed
  - Every 300 seconds if at least 10 keys changed
  - Every 60 seconds if at least 10000 keys changed

### Manual Backup

```bash
# Create manual backup
./scripts/deploy-ec2.sh redis-backup

# Backup location: ./backups/redis_backup_YYYYMMDD_HHMMSS.rdb
```

### Recovery

To restore from backup:

1. Stop Redis container
2. Replace `/data/dump.rdb` with backup file
3. Restart Redis container

## Security

### Authentication

- **Password Protection**: All Redis operations require authentication
- **Network Isolation**: Redis only accessible within Docker network
- **No External Exposure**: Redis port not exposed to host

### Best Practices

1. **Regular Password Rotation**: Update `REDIS_PASSWORD` periodically
2. **Monitor Access**: Review Redis logs for unauthorized access attempts
3. **Backup Encryption**: Encrypt backup files if storing externally
4. **Network Security**: Ensure Docker network isolation

## Troubleshooting

### Common Issues

#### Redis Not Starting

```bash
# Check container logs
./scripts/deploy-ec2.sh redis-logs

# Common causes:
# - Insufficient memory
# - Permission issues with data volume
# - Configuration errors
```

#### Worker Not Processing Jobs

```bash
# Check worker container status
docker-compose ps redis-worker

# Check worker logs
docker-compose logs redis-worker

# Verify Redis connectivity from worker
docker-compose exec redis-worker redis-cli -h redis -a $REDIS_PASSWORD ping
```

#### Memory Issues

```bash
# Check Redis memory usage
./scripts/manage-redis.sh info

# If memory usage is high:
# 1. Check for memory leaks in application
# 2. Adjust maxmemory policy
# 3. Increase memory limit if needed
```

### Performance Tuning

#### Memory Optimization

For production workloads, consider:

1. **Increase Memory Limit**: If queue sizes grow large
2. **Adjust Eviction Policy**: Based on access patterns
3. **Monitor Key Expiration**: Set TTL for cache keys

#### Queue Optimization

1. **Job Cleanup**: Ensure completed jobs are removed
2. **Concurrency Tuning**: Adjust worker concurrency based on load
3. **Retry Strategy**: Optimize retry attempts and delays

## Integration with Application

### Backend Integration

The PRS backend integrates with Redis through enhanced production-ready components:

- **Queue Creation**: `src/infra/queue/index.js` - Enhanced with production-specific settings
- **Redis Configuration**: `src/infra/queue/redis.js` - Production-optimized connection settings
- **Worker Processing**: `src/workers/sync.worker.js` - Enhanced error handling and monitoring

### Enhanced Production Features

#### Redis Configuration (`src/infra/queue/redis.js`)
- **Environment-aware settings**: Different configurations for development vs production
- **Connection pooling**: Optimized for production reliability
- **Retry logic**: Enhanced retry mechanisms with exponential backoff
- **Timeout handling**: Proper connection and command timeouts
- **Security**: Password authentication and connection monitoring

#### Queue Management (`src/infra/queue/index.js`)
- **Production job settings**: More retries, faster processing, better cleanup
- **Error monitoring**: Enhanced error event listeners
- **Connection testing**: Built-in Redis connectivity testing
- **Memory optimization**: Reduced job retention in production

#### Worker Processing (`src/workers/sync.worker.js`)
- **Enhanced logging**: Structured logging with context information
- **Error handling**: Production-safe error logging (no stack traces)
- **Progress tracking**: Detailed job progress reporting
- **Graceful shutdown**: Proper SIGTERM/SIGINT handling
- **Memory management**: Automatic job cleanup and memory optimization

### Environment Configuration

Ensure these environment variables are set in backend:

```bash
# Required Redis settings
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}

# Production optimization
NODE_ENV=production
LOG_LEVEL=info

# Optional Redis settings (handled automatically)
REDIS_ENABLED=true
```

## Maintenance

### Regular Tasks

1. **Monitor Queue Health**: Check for stuck or failed jobs
2. **Review Memory Usage**: Ensure Redis stays within limits
3. **Backup Verification**: Test backup restoration periodically
4. **Log Rotation**: Manage Redis log file sizes

### Scheduled Maintenance

Consider implementing:
- **Weekly Queue Cleanup**: Remove old completed/failed jobs
- **Monthly Memory Analysis**: Review memory usage patterns
- **Quarterly Performance Review**: Assess and optimize configuration

## Production Checklist

Before deploying to production:

- [ ] Redis password is secure and documented
- [ ] Memory limits are appropriate for workload
- [ ] Health checks are functioning
- [ ] Backup strategy is tested
- [ ] Monitoring is in place
- [ ] Worker containers are running
- [ ] Queue processing is verified
- [ ] Security settings are reviewed
