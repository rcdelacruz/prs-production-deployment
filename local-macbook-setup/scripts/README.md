# Local Development Scripts

This directory contains utility scripts for local development and testing.

## Force Close Test Data Setup

### Quick Setup Script

**File:** `setup-force-close-test.sh`

**Usage:**
```bash
# From the local-macbook-setup directory
./scripts/setup-force-close-test.sh
```

**What it does:**
- Cleans up any existing test data
- Creates a test project for force close testing
- Creates 5 test requisitions in different statuses:
  - `TEST-FC-SUBMITTED` (submitted status)
  - `TEST-FC-ASSIGNED` (assigned status)
  - `TEST-FC-CANVASS-APPROVAL` (canvass_approval status)
  - `TEST-FC-PARTIAL-CANVASS` (partially_canvassed status)
  - `TEST-FC-PO-SCENARIO` (po_creation status)
- Adds realistic items to each requisition
- **Sets up proper approval workflows** with requisition approvers
- **Assigns users** to handle requisitions (mreyes, akm_123)
- All requisitions are owned by user `ronald` (ID: 150)
- All foreign key relationships are properly set up

**Prerequisites:**
- Docker containers must be running (`./deploy-local.sh`)
- Database must be accessible

### Manual SQL Script

**File:** `setup-force-close-test-data.sql`

**Usage:**
```bash
# Copy to container and run
docker cp scripts/setup-force-close-test-data.sql prs-local-postgres:/tmp/
docker exec -it prs-local-postgres psql -U prs_user -d prs_local -f /tmp/setup-force-close-test-data.sql

# Or run interactively
docker exec -it prs-local-postgres psql -U prs_user -d prs_local
\i /tmp/setup-force-close-test-data.sql
```

## Testing Force Close Functionality

After running the setup script:

1. **Login** to https://localhost:8444
2. **Credentials:** `ronald` / `4842#O2Kv`
3. **Navigate** to Dashboard
4. **Look for** requisitions starting with `TEST-FC-`
5. **Click** on any requisition to open the Requisition Slip
6. **Scroll down** to find the Force Close button
7. **Test** the Force Close functionality

### Expected Test Results

- **Force Close button** should appear instead of Cancel Request button
- **Warning message** should display: "This action is irreversible. All pending will not progress."
- **Modal** should open with proper form fields when clicked
- **Validation** should work for the reason field
- **Force close execution** should work and change status to "closed"

## Troubleshooting

### Script Fails with Database Connection Error
- Ensure Docker containers are running: `./deploy-local.sh`
- Check if database container is healthy: `docker ps`
- Verify database credentials in `.env` file

### No Test Requisitions Appear in Dashboard
- Check if requisitions were created: Run the script again
- Verify you're logged in as `ronald`
- Check browser console for JavaScript errors

### Force Close Button Not Visible
- Check browser console for errors
- Verify frontend is running and accessible
- Check if force close routes are properly registered in backend

## Cleanup

To remove test data:
```sql
-- Connect to database
docker exec -it prs-local-postgres psql -U prs_user -d prs_local

-- Clean up test data
DELETE FROM requisition_item_lists WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM requisitions WHERE rs_number LIKE 'TEST-FC-%';
DELETE FROM projects WHERE code LIKE 'TEST-PROJ-%';
```

## Notes

- Test data is automatically cleaned up each time you run the setup script
- All test requisitions use the same test project and company
- Items are added using existing non-OFM items (IDs 7 and 28)
- All foreign key constraints are properly satisfied
- Test data is designed to be safe and isolated from production data
