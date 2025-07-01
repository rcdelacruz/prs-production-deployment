# TimescaleDB Long-Term Production Maintenance Guide

This guide covers maintenance strategies for TimescaleDB in production with **zero data deletion policy** and **years of continuous data growth**.

## 🎯 Overview

Your PRS system is configured for:
- **Zero data deletion** - All data preserved indefinitely
- **Automatic compression** - Reduces storage without data loss
- **Long-term growth** - Designed to handle years of data accumulation
- **Production-grade maintenance** - Automated optimization and monitoring

## 🗜️ Compression Strategy

### Compression Policies Configured

The system automatically compresses data based on business requirements:

| Table Category | Compress After | Rationale |
|----------------|----------------|-----------|
| **High-Volume Logs** | 30 days | `audit_logs`, `notifications`, `force_close_logs` |
| **User Interactions** | 90 days | `comments`, `notes`, `histories` |
| **Business Data** | 6 months | `requisitions`, `purchase_orders`, `delivery_receipts` |
| **Reference Data** | 1 year | `attachments`, `requisition_badges` |

### Compression Benefits

- **Storage Reduction**: 70-90% size reduction for compressed chunks
- **Query Performance**: Compressed data still fully queryable
- **Zero Data Loss**: Lossless compression preserves all information
- **Cost Efficiency**: Significant storage cost savings over years

## 🔧 Maintenance Commands

### Initial Setup (Run Once)
```bash
# Setup compression policies (included in init-db)
./scripts/deploy-ec2.sh timescaledb-compression
```

### Daily Operations
```bash
# Check compression status
./scripts/deploy-ec2.sh timescaledb-maintenance status

# View storage usage
./scripts/deploy-ec2.sh timescaledb-maintenance storage

# Run full maintenance cycle
./scripts/deploy-ec2.sh timescaledb-maintenance full-maintenance
```

### Manual Operations
```bash
# Force compression of eligible chunks
./scripts/deploy-ec2.sh timescaledb-maintenance compress

# Performance optimization
./scripts/deploy-ec2.sh timescaledb-maintenance optimize
```

## ⏰ Automated Maintenance with Cron Jobs

### Recommended Cron Schedule

Add these to your production server's crontab (`crontab -e`):

```bash
# TimescaleDB Production Maintenance
# Daily maintenance at 2 AM (low traffic time)
0 2 * * * cd /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup && ./scripts/timescaledb-maintenance.sh full-maintenance >> /var/log/timescaledb-maintenance.log 2>&1

# Weekly deep optimization on Sundays at 3 AM
0 3 * * 0 cd /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup && ./scripts/timescaledb-maintenance.sh optimize >> /var/log/timescaledb-weekly.log 2>&1

# Monthly storage report on 1st of month at 4 AM
0 4 1 * * cd /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup && ./scripts/timescaledb-maintenance.sh storage >> /var/log/timescaledb-monthly.log 2>&1

# Daily backup at 1 AM
0 1 * * * cd /home/ubuntu/prs-prod/prs-production-deployment/ec2-graviton-setup && ./scripts/deploy-ec2.sh timescaledb-backup >> /var/log/timescaledb-backup.log 2>&1
```

### Setting Up Cron Jobs

1. **Create log directory**:
```bash
sudo mkdir -p /var/log
sudo chown ubuntu:ubuntu /var/log/timescaledb-*.log
```

2. **Add cron jobs**:
```bash
crontab -e
# Add the cron entries above
```

3. **Verify cron jobs**:
```bash
crontab -l
```

## 📊 Monitoring and Alerting

### Daily Monitoring Checklist

Check these metrics daily (can be automated):

```bash
# Database size growth
./scripts/timescaledb-maintenance.sh storage

# Compression efficiency
./scripts/timescaledb-maintenance.sh status

# System resources
./scripts/deploy-ec2.sh monitor
```

### Key Metrics to Track

1. **Database Size Growth Rate**
   - Monitor daily growth patterns
   - Plan storage capacity accordingly
   - Alert if growth exceeds expected rates

2. **Compression Ratio**
   - Target: 70-90% compression for older data
   - Alert if compression ratio drops below 60%

3. **Query Performance**
   - Monitor slow query logs
   - Track average query response times
   - Alert on performance degradation

4. **Storage Utilization**
   - Monitor disk space usage
   - Plan for storage expansion
   - Alert at 80% capacity

### Automated Alerting Script

Create `/home/ubuntu/scripts/timescaledb-alerts.sh`:

```bash
#!/bin/bash
# TimescaleDB Monitoring and Alerting

# Check database size (alert if > 80% of available space)
DB_SIZE=$(docker exec prs-ec2-postgres-timescale du -sh /var/lib/postgresql/data | cut -f1)
DISK_USAGE=$(df -h /var/lib/docker | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -gt 80 ]; then
    echo "ALERT: Disk usage is ${DISK_USAGE}% - Database size: $DB_SIZE"
    # Add email/Slack notification here
fi

# Check compression efficiency
COMPRESSION_RATIO=$(./scripts/timescaledb-maintenance.sh status | grep "compression_ratio" | awk '{sum+=$4; count++} END {print sum/count}')

if (( $(echo "$COMPRESSION_RATIO < 60" | bc -l) )); then
    echo "ALERT: Low compression ratio: ${COMPRESSION_RATIO}%"
    # Add notification here
fi
```

## 📈 Capacity Planning

### Growth Projections

Based on typical PRS usage patterns:

| Data Type | Daily Growth | Monthly Growth | Yearly Growth |
|-----------|--------------|----------------|---------------|
| Audit Logs | 50-100 MB | 1.5-3 GB | 18-36 GB |
| Business Data | 10-20 MB | 300-600 MB | 3.6-7.2 GB |
| User Content | 5-10 MB | 150-300 MB | 1.8-3.6 GB |
| **Total (Uncompressed)** | **65-130 MB** | **2-4 GB** | **24-48 GB** |
| **Total (Compressed)** | **20-40 MB** | **600MB-1.2GB** | **7-14 GB** |

### Storage Planning Recommendations

1. **Year 1**: Plan for 50 GB total storage
2. **Year 2**: Plan for 100 GB total storage  
3. **Year 3+**: Plan for 150+ GB total storage

### When to Scale Storage

**Immediate Action Required** when:
- Disk usage > 85%
- Database growth > 200% of projected rate
- Compression ratio < 50%
- Query performance degrades > 50%

**Plan Upgrade** when:
- Disk usage > 70%
- Database growth > 150% of projected rate
- Monthly growth exceeds 5 GB

## 🚨 Troubleshooting

### Common Issues and Solutions

#### 1. High Storage Usage
```bash
# Check compression status
./scripts/timescaledb-maintenance.sh status

# Force compression
./scripts/timescaledb-maintenance.sh compress

# Check for uncompressed old chunks
docker exec prs-ec2-postgres-timescale psql -U $POSTGRES_USER -d $POSTGRES_DB -c "
SELECT chunk_name, range_end, is_compressed 
FROM timescaledb_information.chunks 
WHERE NOT is_compressed AND range_end < NOW() - INTERVAL '7 days'
ORDER BY range_end;"
```

#### 2. Slow Query Performance
```bash
# Run optimization
./scripts/timescaledb-maintenance.sh optimize

# Check for missing indexes
docker exec prs-ec2-postgres-timescale psql -U $POSTGRES_USER -d $POSTGRES_DB -c "
SELECT schemaname, tablename, attname, n_distinct, correlation 
FROM pg_stats 
WHERE schemaname = 'public' AND n_distinct > 100
ORDER BY n_distinct DESC;"
```

#### 3. Compression Policy Issues
```bash
# Check compression policies
./scripts/timescaledb-maintenance.sh status

# Recreate compression policies
./scripts/timescaledb-maintenance.sh setup-compression
```

## 📋 Maintenance Checklist

### Daily (Automated)
- [ ] Run full maintenance cycle
- [ ] Create backup
- [ ] Check compression status
- [ ] Monitor storage usage

### Weekly (Automated)
- [ ] Deep performance optimization
- [ ] Review slow query logs
- [ ] Check compression efficiency

### Monthly (Manual Review)
- [ ] Review storage growth trends
- [ ] Analyze compression statistics
- [ ] Plan capacity requirements
- [ ] Review and update maintenance scripts

### Quarterly (Strategic Review)
- [ ] Evaluate storage scaling needs
- [ ] Review backup and recovery procedures
- [ ] Update compression policies if needed
- [ ] Performance baseline review

## 🔗 Related Documentation

- **Setup Guide**: `TIMESCALEDB_PRODUCTION_GUIDE.md`
- **Backup Procedures**: `scripts/timescaledb-production-backup.sh`
- **Maintenance Script**: `scripts/timescaledb-maintenance.sh`
- **Deployment Guide**: `scripts/deploy-ec2.sh help`

---

**With this maintenance strategy, your PRS system can handle years of data growth while maintaining optimal performance and storage efficiency!** 🚀
