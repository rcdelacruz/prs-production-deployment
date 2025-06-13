# Database Management Guide

This guide covers the enhanced database management tools for the EC2 Graviton setup, including safe import/export functionality that properly handles foreign key constraints.

## Overview

The EC2 Graviton setup now includes enhanced database management scripts that:

- ✅ **Handle foreign key constraints properly** during import/export
- ✅ **Create automatic backups** before importing
- ✅ **Validate data integrity** after operations
- ✅ **Support multiple dump formats** (full, schema-only, both)
- ✅ **Provide detailed logging** and error handling

## Scripts Available

### 1. Safe Database Import (`import-database-safe.sh`)

Safely imports SQL dump files with proper foreign key constraint handling.

**Features:**
- Disables foreign key constraints during import
- Creates automatic backup before import
- Validates data integrity after import
- Handles sequence updates automatically
- Provides rollback capability on failure

**Usage:**
```bash
# Using the main deploy script (recommended)
./scripts/deploy-ec2.sh import-db-safe dump_file.sql

# Using the script directly
./scripts/import-database-safe.sh dump_file.sql
```

### 2. Database Dump Creation (`create-database-dump.sh`)

Creates clean database dumps optimized for safe importing.

**Features:**
- Creates dumps with foreign key constraint handling
- Supports multiple dump types (full, schema, both)
- Includes sequence reset functionality
- Validates dump file integrity
- Shows database statistics

**Usage:**
```bash
# Using the main deploy script
./scripts/deploy-ec2.sh create-dump [type] [name]

# Using the script directly
./scripts/create-database-dump.sh [type] [name]

# Examples:
./scripts/deploy-ec2.sh create-dump full my_backup
./scripts/deploy-ec2.sh create-dump schema
./scripts/deploy-ec2.sh create-dump both production_backup
```

**Dump Types:**
- `full` (default): Complete database with data
- `schema`: Schema structure only
- `both`: Creates both full and schema dumps

## Command Reference

### Main Deploy Script Commands

```bash
# Database Import (Basic - legacy method)
./scripts/deploy-ec2.sh import-db <file>

# Database Import (Safe - recommended)
./scripts/deploy-ec2.sh import-db-safe <file>

# Create Database Dump
./scripts/deploy-ec2.sh create-dump [type] [name]

# Initialize Database
./scripts/deploy-ec2.sh init-db
```

### Direct Script Usage

```bash
# Safe import with automatic backup and validation
./scripts/import-database-safe.sh dump_file.sql

# Create different types of dumps
./scripts/create-database-dump.sh full my_backup
./scripts/create-database-dump.sh schema
./scripts/create-database-dump.sh both production_backup
```

## Best Practices

### Before Importing

1. **Always create a backup** (done automatically with safe import)
2. **Validate the dump file** exists and is readable
3. **Check available disk space** for backup and import
4. **Ensure PostgreSQL container is running**

### During Import

1. **Use the safe import method** (`import-db-safe`) for production
2. **Monitor the import process** for any warnings or errors
3. **Don't interrupt the import process** once started

### After Import

1. **Verify data integrity** (done automatically)
2. **Check application functionality**
3. **Monitor database performance**
4. **Keep backup files** for rollback if needed

## Troubleshooting

### Common Issues

**Import fails with foreign key constraint errors:**
```bash
# Use the safe import method
./scripts/deploy-ec2.sh import-db-safe your_dump.sql
```

**PostgreSQL container not running:**
```bash
# Start services first
./scripts/deploy-ec2.sh start
```

**Dump file not found:**
```bash
# Check available SQL files
ls -la *.sql

# Use absolute path if needed
./scripts/deploy-ec2.sh import-db-safe /full/path/to/dump.sql
```

**Permission denied errors:**
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Validation Failures

If validation fails after import:

1. **Check the logs** for specific error messages
2. **Verify foreign key relationships** in the database
3. **Consider restoring from backup** if data is corrupted
4. **Contact support** with error details

## File Locations

- **Scripts:** `./scripts/`
  - `import-database-safe.sh` - Safe import functionality
  - `create-database-dump.sh` - Dump creation functionality
  - `deploy-ec2.sh` - Main deployment script (updated)

- **Dump Files:** Root directory
  - `dump_*.sql` - Database dump files
  - `backup_*.sql` - Automatic backup files
  - `schema_*.sql` - Schema-only dumps

## Environment Variables

The scripts use these environment variables (set automatically by deploy script):

```bash
POSTGRES_USER=prs_user
POSTGRES_DB=prs_production
POSTGRES_PASSWORD=prodpassword123
```

## Safety Features

### Automatic Backups

Before any import operation, the safe import script automatically creates a backup:

```
backup_YYYYMMDD_HHMMSS.sql
```

### Foreign Key Constraint Handling

The scripts properly handle PostgreSQL foreign key constraints by:

1. **Disabling triggers** during import (`SET session_replication_role = replica`)
2. **Deferring constraints** where possible
3. **Validating relationships** after import
4. **Re-enabling constraints** after successful import

### Data Validation

After import, the scripts validate:

- **Table record counts** for key tables
- **Foreign key constraint violations**
- **Sequence values** and updates
- **Database connectivity** and basic functionality

## Migration from Legacy Import

If you're currently using the basic `import-db` command:

**Old method:**
```bash
./scripts/deploy-ec2.sh import-db dump_file.sql
```

**New method (recommended):**
```bash
./scripts/deploy-ec2.sh import-db-safe dump_file.sql
```

The new method provides:
- ✅ Better error handling
- ✅ Automatic backups
- ✅ Foreign key constraint handling
- ✅ Data validation
- ✅ Rollback capability

## Support

For issues with database management:

1. **Check the logs** for detailed error messages
2. **Verify prerequisites** (container running, file exists, permissions)
3. **Use validation commands** to check system state
4. **Review this documentation** for best practices
5. **Contact support** with specific error details and logs
