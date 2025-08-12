# Local TimescaleDB Backup Import Guide

This guide explains how to import TimescaleDB backups created by your EC2 production server into your local development environment.

## Prerequisites

- Local TimescaleDB database running (or PostgreSQL with TimescaleDB extension)
- Database credentials for your local setup
- Backup file from EC2 server (SQL dump or binary format)
- TimescaleDB extension installed locally

## Step 1: Create Backup on EC2 Server

On your EC2 server, create a backup using one of these commands:

```bash
# Create SQL backup (recommended for local import)
./scripts/deploy-ec2.sh timescaledb-backup

# Or create a custom backup
./scripts/create-database-dump.sh full my_backup
```

This creates backup files in the `backups/` directory:
- `timescaledb_backup_YYYYMMDD_HHMMSS.sql` (SQL format)
- `timescaledb_backup_YYYYMMDD_HHMMSS.dump` (Binary format)

## Step 2: Download Backup File

Transfer the backup file from your EC2 server to your local machine:

```bash
# Using SCP
scp ec2-user@your-server:/path/to/ec2-graviton-setup/backups/backup_file.sql ./

# Or using rsync
rsync -av ec2-user@your-server:/path/to/ec2-graviton-setup/backups/ ./backups/
```

## Step 3: Prepare Local TimescaleDB Database

### Option A: Using Docker Compose with TimescaleDB

```bash
# Start your local TimescaleDB database
docker-compose up -d postgres

# Clean existing database (optional)
docker-compose exec postgres psql -U your_user -d postgres -c "DROP DATABASE IF EXISTS your_db_name;"
docker-compose exec postgres psql -U your_user -d postgres -c "CREATE DATABASE your_db_name;"

# Enable TimescaleDB extension
docker-compose exec postgres psql -U your_user -d your_db_name -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
```

### Option B: Using Local PostgreSQL with TimescaleDB

```bash
# Clean existing database (optional)
psql -U your_user -d postgres -c "DROP DATABASE IF EXISTS your_db_name;"
psql -U your_user -d postgres -c "CREATE DATABASE your_db_name;"

# Enable TimescaleDB extension
psql -U your_user -d your_db_name -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
```

### Option C: Using TimescaleDB Docker Image

```bash
# Run TimescaleDB container
docker run -d --name timescaledb \
  -p 5432:5432 \
  -e POSTGRES_DB=your_db_name \
  -e POSTGRES_USER=your_user \
  -e POSTGRES_PASSWORD=your_password \
  timescale/timescaledb:latest-pg15

# Wait for container to start
sleep 10

# TimescaleDB extension is automatically available
```

## Step 4: Import Backup

### For SQL Backup Files (.sql)

#### Option A: Docker Compose Setup
```bash
# Import SQL backup
docker-compose exec -T postgres psql -U your_user -d your_db_name < backup_file.sql

# Or copy file into container first
docker cp backup_file.sql container_name:/tmp/backup.sql
docker-compose exec postgres psql -U your_user -d your_db_name -f /tmp/backup.sql
```

#### Option B: Local PostgreSQL
```bash
# Direct import
psql -U your_user -d your_db_name < backup_file.sql

# With password prompt
PGPASSWORD=your_password psql -U your_user -d your_db_name < backup_file.sql
```

### For Binary Backup Files (.dump)

#### Option A: Docker Compose Setup
```bash
# Import binary backup
docker cp backup_file.dump container_name:/tmp/backup.dump
docker-compose exec postgres pg_restore -U your_user -d your_db_name -v /tmp/backup.dump
```

#### Option B: Local PostgreSQL
```bash
# Direct import
pg_restore -U your_user -d your_db_name -v backup_file.dump
```

## Step 5: Verify TimescaleDB Setup

After importing, verify that TimescaleDB is working correctly:

```bash
# Check TimescaleDB extension
psql -U your_user -d your_db_name -c "SELECT * FROM pg_extension WHERE extname = 'timescaledb';"

# Check hypertables
psql -U your_user -d your_db_name -c "SELECT * FROM timescaledb_information.hypertables;"

# Check chunks (if any hypertables exist)
psql -U your_user -d your_db_name -c "SELECT * FROM timescaledb_information.chunks LIMIT 5;"
```

## Step 6: Fix Database Sequences (Important!)

After importing, you need to fix the database sequences to prevent ID conflicts:

### Option A: Docker Compose Setup
```bash
docker-compose exec postgres psql -U your_user -d your_db_name -c "
DO \$\$
DECLARE
    r RECORD;
    max_val BIGINT;
BEGIN
    FOR r IN
        SELECT schemaname, sequencename, tablename
        FROM pg_sequences s
        JOIN information_schema.tables t ON t.table_name = regexp_replace(s.sequencename, '_id_seq$', '')
        WHERE s.schemaname = 'public' AND t.table_schema = 'public'
    LOOP
        EXECUTE format('SELECT COALESCE(MAX(id), 1) FROM %I', regexp_replace(r.sequencename, '_id_seq$', '')) INTO max_val;
        EXECUTE format('SELECT setval(%L, %s)', r.schemaname||'.'||r.sequencename, max_val);
        RAISE NOTICE 'Updated sequence % to %', r.sequencename, max_val;
    END LOOP;
END \$\$;
"
```

### Option B: Local PostgreSQL
```bash
psql -U your_user -d your_db_name -c "
DO \$\$
DECLARE
    r RECORD;
    max_val BIGINT;
BEGIN
    FOR r IN
        SELECT schemaname, sequencename, tablename
        FROM pg_sequences s
        JOIN information_schema.tables t ON t.table_name = regexp_replace(s.sequencename, '_id_seq$', '')
        WHERE s.schemaname = 'public' AND t.table_schema = 'public'
    LOOP
        EXECUTE format('SELECT COALESCE(MAX(id), 1) FROM %I', regexp_replace(r.sequencename, '_id_seq$', '')) INTO max_val;
        EXECUTE format('SELECT setval(%L, %s)', r.schemaname||'.'||r.sequencename, max_val);
        RAISE NOTICE 'Updated sequence % to %', r.sequencename, max_val;
    END LOOP;
END \$\$;
"
```

## Step 7: Verify Import

Check that the data was imported correctly:

```bash
# Check table counts
psql -U your_user -d your_db_name -c "
SELECT
    schemaname,
    tablename,
    n_tup_ins as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY tablename;
"

# Check specific tables
psql -U your_user -d your_db_name -c "SELECT COUNT(*) FROM users;"
psql -U your_user -d your_db_name -c "SELECT COUNT(*) FROM requisitions;"

# Check TimescaleDB specific data (if you have time-series tables)
psql -U your_user -d your_db_name -c "
SELECT
    hypertable_name,
    num_chunks,
    pg_size_pretty(pg_total_relation_size('public.' || hypertable_name)) as table_size
FROM timescaledb_information.hypertables;
"
```

## Troubleshooting

### TimescaleDB Extension Issues
If TimescaleDB extension is not available:

```bash
# Check if TimescaleDB is installed
psql -U your_user -d your_db_name -c "SELECT * FROM pg_available_extensions WHERE name = 'timescaledb';"

# If not available, install TimescaleDB locally or use Docker image
docker run -d --name timescaledb -p 5432:5432 -e POSTGRES_PASSWORD=password timescale/timescaledb:latest-pg15
```

### Hypertable Recreation Issues
If hypertables don't import correctly:

```bash
# Check if tables exist but aren't hypertables
psql -U your_user -d your_db_name -c "\dt"

# Manually convert to hypertable if needed (example for a time-series table)
psql -U your_user -d your_db_name -c "SELECT create_hypertable('your_time_series_table', 'created_at');"
```

### Foreign Key Constraint Errors
If you get foreign key constraint errors during import:

```bash
# Disable foreign key checks during import
psql -U your_user -d your_db_name -c "SET session_replication_role = replica;"
# Run your import command here
psql -U your_user -d your_db_name -c "SET session_replication_role = DEFAULT;"
```

### Permission Errors
```bash
# Grant necessary permissions
psql -U your_user -d your_db_name -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_user;"
psql -U your_user -d your_db_name -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_user;"
```

### Large File Import
For very large backup files:
```bash
# Increase timeout and use verbose mode
psql -U your_user -d your_db_name -v ON_ERROR_STOP=1 < backup_file.sql
```

### Chunk/Compression Issues
If you have compression policies on production:

```bash
# Check compression status
psql -U your_user -d your_db_name -c "SELECT * FROM timescaledb_information.compression_settings;"

# Disable compression for local development (optional)
psql -U your_user -d your_db_name -c "ALTER TABLE your_hypertable SET (timescaledb.compress = false);"
```

## Quick Reference

Replace these placeholders with your actual values:
- `your_user`: Your local PostgreSQL username
- `your_db_name`: Your local database name
- `container_name`: Your PostgreSQL container name (if using Docker)
- `backup_file.sql`: Your actual backup filename

## Example Complete Workflow

```bash
# 1. Download backup from server
scp ec2-user@your-server:/path/to/backups/timescaledb_backup_20240101_120000.sql ./

# 2. Start TimescaleDB locally (using Docker)
docker run -d --name local-timescaledb \
  -p 5432:5432 \
  -e POSTGRES_DB=prs_local \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  timescale/timescaledb:latest-pg15

# 3. Wait for database to start
sleep 10

# 4. Import backup
psql -h localhost -U postgres -d prs_local < timescaledb_backup_20240101_120000.sql

# 5. Fix sequences
psql -h localhost -U postgres -d prs_local -c "
DO \$\$
DECLARE
    r RECORD;
    max_val BIGINT;
BEGIN
    FOR r IN
        SELECT schemaname, sequencename
        FROM pg_sequences WHERE schemaname = 'public'
    LOOP
        EXECUTE format('SELECT COALESCE(MAX(id), 1) FROM %I', regexp_replace(r.sequencename, '_id_seq$', '')) INTO max_val;
        EXECUTE format('SELECT setval(%L, %s)', r.schemaname||'.'||r.sequencename, max_val);
    END LOOP;
END \$\$;
"

# 6. Verify TimescaleDB and data
psql -h localhost -U postgres -d prs_local -c "SELECT COUNT(*) FROM users;"
psql -h localhost -U postgres -d prs_local -c "SELECT * FROM timescaledb_information.hypertables;"
```

## Important TimescaleDB Notes

1. **Hypertables**: Your production backup includes hypertables that will be automatically recreated during import
2. **Chunks**: Time-series data is stored in chunks that will be imported with the data
3. **Compression**: Production may have compression enabled - this is usually disabled in local development
4. **Continuous Aggregates**: If you have continuous aggregates, they'll be recreated during import
5. **Retention Policies**: Production retention policies may not be suitable for local development

## Local Development Considerations

- **Disable compression** for faster local development
- **Reduce retention periods** to save local disk space
- **Consider importing only recent data** for faster imports and smaller local databases
