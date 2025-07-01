# TimescaleDB Production Setup Guide for EC2 Graviton

This guide covers the complete TimescaleDB setup and management for the PRS production environment on EC2 Graviton (ARM64).

## 🎯 Overview

TimescaleDB is now enabled in the production environment to provide:
- **Faster time-based queries** - Optimized for timestamp-based data
- **Automatic data compression** - Reduces storage requirements for older data
- **Better performance** - Optimized for large datasets with time-series patterns
- **Production-grade reliability** - Zero data loss with comprehensive backup strategies

## 📋 Prerequisites

- EC2 t4g.medium instance (2 cores, 4GB memory, ARM64)
- Docker and Docker Compose installed
- PRS production environment deployed
- Access to the deployment scripts

## 🚀 Quick Start

### 1. Initialize Database with TimescaleDB

```bash
cd /path/to/prs-production-deployment/ec2-graviton-setup

# Initialize database (includes TimescaleDB setup and Sequelize migration)
./scripts/deploy-ec2.sh init-db
```

**Note**: This automatically:
- Enables the TimescaleDB extension
- Runs all Sequelize migrations including your TimescaleDB migration at:
  `/home/ubuntu/prs-prod/prs-backend-a/src/infra/database/migrations/20250628120000-timescaledb-setup.js`
- Creates 38 hypertables with zero data loss

### 2. Verify Installation

```bash
# Check TimescaleDB status
./scripts/deploy-ec2.sh timescaledb-status
```

### 3. Create Backup

```bash
# Create production backup
./scripts/deploy-ec2.sh timescaledb-backup
```

## 🔧 Configuration Details

### Docker Compose Changes

The production setup now uses:
- **Image**: `timescale/timescaledb:latest-pg15` (instead of `postgres:15-alpine`)
- **Container**: `prs-ec2-postgres-timescale` (updated name)
- **TimescaleDB settings**: Optimized for EC2 t4g.medium

### Environment Variables

Key TimescaleDB settings in `.env`:

```bash
# TimescaleDB Core Settings
TIMESCALEDB_TELEMETRY=off
TIMESCALEDB_MAX_BACKGROUND_WORKERS=8

# PostgreSQL Performance (ARM64 Optimized)
POSTGRES_MAX_CONNECTIONS=30
POSTGRES_SHARED_BUFFERS=128MB
POSTGRES_EFFECTIVE_CACHE_SIZE=512MB
POSTGRES_WORK_MEM=4MB
POSTGRES_MAINTENANCE_WORK_MEM=32MB

# Worker Process Settings
POSTGRES_MAX_WORKER_PROCESSES=16
POSTGRES_MAX_PARALLEL_WORKERS=8
POSTGRES_MAX_PARALLEL_WORKERS_PER_GATHER=2

# WAL Settings
POSTGRES_WAL_BUFFERS=8MB
POSTGRES_MAX_WAL_SIZE=1GB
POSTGRES_MIN_WAL_SIZE=256MB
```

## 📊 Hypertables Created

The following tables are converted to hypertables for time-series optimization:

| Table | Chunk Interval | Purpose |
|-------|----------------|---------|
| `audit_logs` | 1 week | High-volume audit tracking |
| `force_close_logs` | 1 week | Force close operation logs |
| `notes` | 1 month | Comments and notes |
| `notifications` | 1 week | User notifications |
| `requisitions` | 1 month | Core business data |
| `purchase_orders` | 1 month | Purchase order tracking |
| `delivery_receipts` | 1 month | Delivery tracking |
| `comments` | 1 week | User interactions |
| `delivery_receipt_items` | 1 month | Core business transactions |

## 🛠️ Management Commands

### Setup and Status

```bash
# Initialize database with TimescaleDB (run once after deployment)
./scripts/deploy-ec2.sh init-db

# Check status and hypertables
./scripts/deploy-ec2.sh timescaledb-status
```

### Backup and Recovery

```bash
# Create comprehensive backup (binary + SQL)
./scripts/deploy-ec2.sh timescaledb-backup

# Backups are stored in: ./backups/
# - timescaledb_backup_YYYYMMDD_HHMMSS.dump (binary)
# - timescaledb_backup_YYYYMMDD_HHMMSS.sql (SQL)
```

### Performance Optimization

```bash
# Run optimization tasks
./scripts/deploy-ec2.sh timescaledb-optimize

# Advanced maintenance for long-term growth
./scripts/deploy-ec2.sh timescaledb-maintenance full-maintenance

# This performs:
# - VACUUM ANALYZE on all hypertables
# - Update table statistics
# - Compress eligible chunks
# - Optimize query performance
```

### Long-Term Maintenance (Years of Data)
```bash
# Setup compression policies (done automatically during init-db)
./scripts/deploy-ec2.sh timescaledb-compression

# Check compression status and storage usage
./scripts/deploy-ec2.sh timescaledb-maintenance status
./scripts/deploy-ec2.sh timescaledb-maintenance storage

# Force compression of eligible chunks
./scripts/deploy-ec2.sh timescaledb-maintenance compress

# Health monitoring and alerting
./scripts/timescaledb-alerts.sh
```

## 📈 Performance Benefits

### Before TimescaleDB
```sql
-- Slow query on large audit_logs table
SELECT COUNT(*) FROM audit_logs
WHERE created_at >= NOW() - INTERVAL '30 days';
-- Scans entire table
```

### After TimescaleDB
```sql
-- Fast query using time-based partitioning
SELECT COUNT(*) FROM audit_logs
WHERE created_at >= NOW() - INTERVAL '30 days';
-- Uses only relevant chunks, much faster!
```

## 🔍 Monitoring and Analytics

### Time-based Queries
```sql
-- Requisitions created per day (last 30 days)
SELECT
    DATE(created_at) as date,
    COUNT(*) as count
FROM requisitions
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date;

-- Purchase orders by status over time
SELECT
    time_bucket('1 week', created_at) as week,
    status,
    COUNT(*) as count
FROM purchase_orders
WHERE created_at >= NOW() - INTERVAL '6 months'
GROUP BY week, status
ORDER BY week, status;
```

### Hypertable Information
```sql
-- View all hypertables
SELECT * FROM timescaledb_information.hypertables;

-- Check chunk information
SELECT * FROM timescaledb_information.chunks;

-- Monitor table sizes
SELECT
  hypertable_name,
  pg_size_pretty(pg_total_relation_size('public.' || hypertable_name)) as size,
  num_chunks
FROM timescaledb_information.hypertables
ORDER BY pg_total_relation_size('public.' || hypertable_name) DESC;
```

## 🔒 Production Data Retention & Compression

**ZERO DATA LOSS POLICY**: Per product owner requirements, NO data retention policies are enabled. All data is preserved indefinitely.

- **All tables**: Data is kept forever (no automatic deletion)
- **Compliance**: Meets requirements for data preservation
- **Storage optimization**: Managed through **automatic lossless compression**

### 🗜️ Automatic Compression Policies

The system automatically compresses data to handle **years of growth**:

| Table Category | Compress After | Storage Savings |
|----------------|----------------|-----------------|
| **High-Volume Logs** | 30 days | 70-90% reduction |
| **User Interactions** | 90 days | 60-80% reduction |
| **Business Data** | 6 months | 50-70% reduction |
| **Reference Data** | 1 year | 40-60% reduction |

**Benefits**:
- **Massive storage savings** for long-term data growth
- **Zero data loss** - all data remains fully queryable
- **Automatic operation** - no manual intervention required
- **Cost efficiency** - significant storage cost reduction over years

## 📦 Compression Policies

Lossless compression is used to optimize storage while preserving all data:

- **Audit logs**: Compressed after 30 days
- **Notifications**: Compressed after 90 days
- **Force close logs**: Compressed after 90 days
- **Business data**: Compressed after 6 months
- **Notes**: Compressed after 1 year

**Note**: Compression is completely lossless - all data remains accessible and queryable.

## 🚨 Troubleshooting

### Check TimescaleDB Extension
```bash
# Verify extension is loaded
./scripts/deploy-ec2.sh timescaledb-status

# Manual check
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" prs-ec2-postgres-timescale \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT * FROM pg_extension WHERE extname = 'timescaledb';"
```

### Migration Issues
```bash
# Check if migration ran successfully
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" prs-ec2-postgres-timescale \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT * FROM prs_timescaledb_status ORDER BY table_name;"

# Manual migration (if needed)
cd /path/to/prs-backend-a
npx sequelize-cli db:migrate --env production
```

### Performance Issues
```bash
# Run optimization
./scripts/deploy-ec2.sh timescaledb-optimize

# Check resource usage
./scripts/deploy-ec2.sh monitor

# View slow queries
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" prs-ec2-postgres-timescale \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

### Container Issues
```bash
# Restart TimescaleDB container
docker restart prs-ec2-postgres-timescale

# Check container logs
docker logs prs-ec2-postgres-timescale

# Check container health
docker exec prs-ec2-postgres-timescale pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

## 📋 Production Checklist

- [ ] TimescaleDB extension enabled
- [ ] All hypertables created successfully
- [ ] Compression policies configured
- [ ] Backup strategy implemented
- [ ] Performance monitoring in place
- [ ] Documentation updated
- [ ] Team trained on new commands

## 🔄 Maintenance Schedule

### Daily
- Monitor system resources
- Check backup completion

### Weekly
- Run performance optimization
- Review slow query logs

### Monthly
- Analyze storage usage
- Review compression effectiveness
- Update documentation if needed

## 📚 Additional Resources

- [TimescaleDB Documentation](https://docs.timescale.com/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [EC2 Graviton Best Practices](https://docs.aws.amazon.com/ec2/latest/userguide/graviton-performance.html)

---

**Your PRS production environment now has TimescaleDB enabled for optimal time-series performance!** 🚀
