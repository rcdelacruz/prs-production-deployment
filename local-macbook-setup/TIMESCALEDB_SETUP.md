# Production-Grade TimescaleDB Setup Guide for PRS

This guide explains how to set up and use TimescaleDB with your PRS environment in a production-ready configuration that preserves all data.

## What is TimescaleDB?

TimescaleDB is a PostgreSQL extension that adds time-series database capabilities to your existing PostgreSQL database. It provides:

- **Faster time-based queries** - Optimized for timestamp-based data
- **Automatic data compression** - Reduces storage requirements for older data
- **Continuous aggregates** - Real-time analytics and reporting
- **Retention policies** - Automatic cleanup of old data
- **Horizontal scaling** - Better performance for large datasets

## Benefits for PRS

Your PRS application has many time-series data patterns:
- Audit logs with `created_at` timestamps
- Requisition tracking over time
- Purchase order history
- Delivery receipt timelines
- Notification streams
- Force close operation logs

TimescaleDB optimizes these queries and provides better analytics capabilities.

## Setup Instructions

### 1. Update Your Environment

The setup has already been configured in your Docker Compose files:

- **PostgreSQL Image**: Changed from `postgres:15-alpine` to `timescale/timescaledb:latest-pg15`
- **Memory Settings**: Increased for better TimescaleDB performance
- **Extensions**: TimescaleDB extension enabled automatically

### 2. Deploy with TimescaleDB

Start your environment as usual:

```bash
cd /Users/ronalddelacruz/Documents/augment-projects/prs/prs-production-deployment/local-macbook-setup
./scripts/deploy-local.sh deploy
```

The deployment script will automatically:
1. Start the TimescaleDB-enabled PostgreSQL container
2. Setup the TimescaleDB extension
3. Create hypertables for time-series data
4. Configure compression and retention policies
5. Create continuous aggregates for analytics

### 3. Manual TimescaleDB Setup

If you need to setup TimescaleDB manually:

```bash
# Setup TimescaleDB extension and hypertables
./scripts/deploy-local.sh setup-timescaledb

# Check TimescaleDB status
./scripts/deploy-local.sh timescaledb-status
```

### 4. Verify Installation

Check that TimescaleDB is working:

```bash
# Show TimescaleDB status
./scripts/deploy-local.sh timescaledb-status
```

You should see:
- TimescaleDB version information
- List of hypertables created
- Continuous aggregates configured
- Compression policies active

## Hypertables Created

The following tables have been converted to hypertables for time-series optimization:

| Table | Chunk Interval | Purpose |
|-------|----------------|---------|
| `audit_logs` | 1 day | High-volume audit tracking |
| `force_close_logs` | 1 week | Force close operation logs |
| `notes` | 1 week | Comments and notes |
| `notifications` | 1 day | User notifications |
| `requisitions` | 1 month | Core business data |
| `purchase_orders` | 1 month | Purchase order tracking |
| `delivery_receipts` | 1 month | Delivery tracking |
| `invoices` | 1 month | Financial data |
| `non_requisition_invoices` | 1 month | Additional invoices |
| `payment_requests` | 1 month | Payment workflows |

## Production-Grade Data Retention

**🔒 ZERO DATA LOSS POLICY**: Per product owner requirements, NO data retention policies are enabled. All data is preserved indefinitely.

- **All tables**: Data is kept forever (no automatic deletion)
- **Compliance**: Meets requirements for data preservation
- **Storage**: Managed through compression instead of deletion

## Production-Grade Compression Policies

Lossless compression is used to optimize storage while preserving all data:

- **Audit logs**: Compressed after 30 days (production-grade retention)
- **Notifications**: Compressed after 90 days (extended retention)
- **Force close logs**: Compressed after 90 days (compliance-friendly)
- **Business data**: Compressed after 6 months (financial records)
- **Notes**: Compressed after 1 year (long-term reference)

**Note**: Compression is completely lossless - all data remains accessible and queryable.

## Continuous Aggregates

Pre-computed analytics views are available:

### Daily Requisition Summary
```sql
SELECT * FROM daily_requisition_summary
WHERE day >= NOW() - INTERVAL '30 days'
ORDER BY day DESC;
```

### Weekly Purchase Order Summary
```sql
SELECT * FROM weekly_po_summary
WHERE week >= NOW() - INTERVAL '3 months'
ORDER BY week DESC;
```

## Performance Benefits

### Before TimescaleDB
```sql
-- Slow query on large audit_logs table
SELECT COUNT(*) FROM audit_logs
WHERE created_at >= NOW() - INTERVAL '30 days';
```

### After TimescaleDB
```sql
-- Fast query using time-based partitioning
SELECT COUNT(*) FROM audit_logs
WHERE created_at >= NOW() - INTERVAL '30 days';
-- Uses only relevant chunks, much faster!
```

## Monitoring and Analytics

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

### Using Continuous Aggregates
```sql
-- Fast analytics using pre-computed data
SELECT * FROM daily_requisition_summary
WHERE day >= NOW() - INTERVAL '90 days'
AND status = 'approved'
ORDER BY day DESC;
```

## Troubleshooting

### Check TimescaleDB Status
```bash
./scripts/deploy-local.sh timescaledb-status
```

### Manual Extension Setup
If TimescaleDB isn't working, you can manually enable it:

```sql
-- Connect to your database and run:
CREATE EXTENSION IF NOT EXISTS timescaledb;
```

### View Hypertable Information
```sql
-- See all hypertables
SELECT * FROM timescaledb_information.hypertables;

-- See chunk information
SELECT * FROM timescaledb_information.chunks;

-- See compression stats
SELECT * FROM timescaledb_information.compression_settings;
```

### Performance Monitoring
```sql
-- Check query performance
SELECT * FROM timescaledb_information.job_stats;

-- View continuous aggregate refresh stats
SELECT * FROM timescaledb_information.continuous_aggregate_stats;
```

## Migration Notes

- **Existing Data**: All existing data is preserved during the hypertable conversion
- **Application Code**: No changes needed in your application code
- **Queries**: All existing queries continue to work, but run faster
- **Indexes**: Existing indexes are preserved and optimized

## Production Tools

### Backup and Recovery
```bash
# Create production-grade backup (binary + SQL formats)
./scripts/deploy-local.sh timescaledb-backup

# Backups are stored in: prs-production-deployment/local-macbook-setup/backups/
```

### Health Monitoring
```bash
# Show comprehensive health metrics
./scripts/deploy-local.sh timescaledb-health

# Show detailed storage usage
./scripts/timescaledb-production-tools.sh storage
```

### Performance Optimization
```bash
# Run performance optimization tasks
./scripts/deploy-local.sh timescaledb-optimize

# Validate data integrity
./scripts/timescaledb-production-tools.sh validate
```

## Environment Variables

Production-grade TimescaleDB environment variables in `.env`:

```bash
# Production-Grade TimescaleDB Settings
POSTGRES_MAX_CONNECTIONS=100
POSTGRES_SHARED_BUFFERS=256MB
POSTGRES_EFFECTIVE_CACHE_SIZE=1GB
POSTGRES_WORK_MEM=8MB
POSTGRES_MAINTENANCE_WORK_MEM=64MB
POSTGRES_WAL_BUFFERS=16MB
POSTGRES_MAX_WAL_SIZE=2GB
POSTGRES_MIN_WAL_SIZE=512MB

# TimescaleDB Production Configuration
TIMESCALEDB_TELEMETRY=off
TIMESCALEDB_MAX_BACKGROUND_WORKERS=16

# Container Resource Limits (Production-Grade)
POSTGRES_MEMORY_LIMIT=2g
BACKEND_MEMORY_LIMIT=1g
```

## Next Steps

1. **Monitor Performance**: Use the continuous aggregates for dashboard analytics
2. **Custom Aggregates**: Create additional continuous aggregates for specific reporting needs
3. **Retention Policies**: Adjust retention periods based on your compliance requirements
4. **Compression**: Monitor storage savings from automatic compression

For more information, see the [TimescaleDB Documentation](https://docs.timescale.com/).
