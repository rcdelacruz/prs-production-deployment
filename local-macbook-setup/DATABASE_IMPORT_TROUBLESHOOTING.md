# Database Import Troubleshooting Guide

## Overview

This guide helps resolve common database import issues when importing production dump files to your local development environment.

## Common Issues and Solutions

### 1. Missing References (Foreign Key Violations)

**Symptoms:**
- Error messages about missing references like "RS-1233AA00000514"
- Foreign key constraint violations during import
- Data inconsistencies after import

**Root Causes:**
- Import order issues (child tables imported before parent tables)
- Missing referenced records in the dump
- Foreign key constraints enforced during import

**Solutions:**

#### Option A: Use the Enhanced Import Script (Recommended)
```bash
# Use the improved deploy script with constraint handling
./scripts/deploy-local.sh import-db dump.sql
```

#### Option B: Create a Fixed Dump File
```bash
# Analyze your dump file first
./scripts/analyze-dump.sh analyze dump.sql

# Create a fixed version
./scripts/analyze-dump.sh fix dump.sql

# Import the fixed version
./scripts/deploy-local.sh import-db dump_fixed.sql
```

#### Option C: Manual Import with Constraint Handling
```bash
# Start services
./scripts/deploy-local.sh start

# Import with constraints disabled
docker exec -i -e PGPASSWORD="localdev123" prs-local-postgres psql -U prs_user -d prs_local << 'EOF'
-- Disable foreign key checks
SET session_replication_role = replica;

-- Import your dump here
\i /path/to/your/dump.sql

-- Re-enable foreign key checks
SET session_replication_role = DEFAULT;
EOF

# Fix sequences
./scripts/deploy-local.sh fix-sequences

# Validate foreign keys
./scripts/deploy-local.sh validate-fk
```

### 2. Sequence Issues

**Symptoms:**
- Duplicate key errors when creating new records
- Primary key constraint violations
- Auto-increment IDs starting from 1 instead of continuing from imported data

**Solution:**
```bash
# Fix all sequences after import
./scripts/deploy-local.sh fix-sequences
```

### 3. User 150 Missing Issues

**Analysis:**
Based on your dump file, user 150 (ronald, ronaldo.delacruz@stratpoint.com) exists in the dump. If you're getting missing user errors:

1. **Check if user was imported:**
```bash
docker exec -e PGPASSWORD="localdev123" prs-local-postgres psql -U prs_user -d prs_local -c "SELECT id, username, email FROM users WHERE id = 150;"
```

2. **If user is missing, check import logs:**
```bash
./scripts/deploy-local.sh logs postgres
```

3. **Manually verify user data in dump:**
```bash
grep "^150\s" dump.sql
```

### 4. Notification Reference Issues

**The RS-1233AA00000514 reference:**
- This appears in the notifications table (line 34153 in your dump)
- It references requisition ID 945
- Associated with user 150

**Verification steps:**
```bash
# Check if requisition 945 exists
docker exec -e PGPASSWORD="localdev123" prs-local-postgres psql -U prs_user -d prs_local -c "SELECT id, rs_number FROM requisitions WHERE id = 945;"

# Check notification
docker exec -e PGPASSWORD="localdev123" prs-local-postgres psql -U prs_user -d prs_local -c "SELECT * FROM notifications WHERE message LIKE '%RS-1233AA00000514%';"
```

## Step-by-Step Troubleshooting Process

### Step 1: Analyze Your Dump File
```bash
./scripts/analyze-dump.sh analyze dump.sql
```

This will show:
- File size and encoding
- Number of tables
- Presence of user 150
- Presence of RS-1233AA00000514 reference
- Row counts for major tables

### Step 2: Start Services
```bash
./scripts/deploy-local.sh start
```

### Step 3: Import with Enhanced Method
```bash
# Option A: Direct import with enhanced script
./scripts/deploy-local.sh import-db dump.sql

# Option B: Use fixed dump file
./scripts/analyze-dump.sh fix dump.sql
./scripts/deploy-local.sh import-db dump_fixed.sql
```

### Step 4: Validate Import
```bash
# Check sequences
./scripts/deploy-local.sh fix-sequences

# Validate foreign keys
./scripts/deploy-local.sh validate-fk

# Check specific data
docker exec -e PGPASSWORD="localdev123" prs-local-postgres psql -U prs_user -d prs_local -c "
SELECT 
    (SELECT COUNT(*) FROM users) as user_count,
    (SELECT COUNT(*) FROM requisitions) as requisition_count,
    (SELECT COUNT(*) FROM notifications) as notification_count;
"
```

### Step 5: Test Application
```bash
./scripts/deploy-local.sh status
```

Access the application at https://localhost:8443

## Advanced Troubleshooting

### Check Foreign Key Violations
```bash
./scripts/deploy-local.sh validate-fk
```

### Manual Constraint Checking
```bash
docker exec -e PGPASSWORD="localdev123" prs-local-postgres psql -U prs_user -d prs_local -c "
-- Check for orphaned notifications
SELECT COUNT(*) as orphaned_notifications
FROM notifications n
WHERE n.sender_id IS NOT NULL 
AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = n.sender_id);

-- Check for orphaned requisitions
SELECT COUNT(*) as orphaned_requisitions  
FROM requisitions r
WHERE r.created_by IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = r.created_by);
"
```

### Reset and Retry
If all else fails:
```bash
# Complete reset
./scripts/deploy-local.sh reset

# Redeploy with fresh import
./scripts/deploy-local.sh redeploy
```

## Prevention Tips

1. **Always use the enhanced import script** instead of manual psql imports
2. **Analyze dump files** before importing to catch issues early
3. **Keep backups** of working dump files
4. **Test imports** in a separate environment first
5. **Monitor logs** during import for warnings

## Getting Help

If you continue to experience issues:

1. **Check logs:**
```bash
./scripts/deploy-local.sh logs postgres
./scripts/deploy-local.sh logs backend
```

2. **Analyze the specific error** in the PostgreSQL logs
3. **Use the validation tools** provided in the enhanced script
4. **Create a minimal test case** with just the problematic data

## Files Modified

- `scripts/deploy-local.sh` - Enhanced with constraint handling and validation
- `scripts/analyze-dump.sh` - New tool for dump analysis and fixing
- This troubleshooting guide

## Next Steps

After resolving import issues, consider:
1. Setting up automated database backups
2. Creating sanitized test data sets
3. Implementing database migration scripts
4. Adding data validation tests
