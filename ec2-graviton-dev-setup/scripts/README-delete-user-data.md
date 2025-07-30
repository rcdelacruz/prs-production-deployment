# Delete User Data Script

## Overview
This script (`delete-user-data.sh`) allows you to completely delete ALL data related to a specific user from the PRS system. This is useful for cleaning up test data or removing user data when needed.

## ⚠️ WARNING
**This script permanently deletes ALL data for the specified user and CANNOT be undone!**

Use this script only for:
- Test data cleanup
- Development environment cleanup
- Authorized data removal with proper approval

## Usage

### Basic Usage
```bash
./scripts/delete-user-data.sh "Full Name"
```

### Examples
```bash
# Delete all data for user "Bom Park"
./scripts/delete-user-data.sh "Bom Park"

# Delete all data for user "John Doe"
./scripts/delete-user-data.sh "John Doe"

# Delete all data for user "Maria Santos"
./scripts/delete-user-data.sh "Maria Santos"
```

## What Gets Deleted

The script deletes data in the following order to maintain referential integrity:

### 1. Payment Request Data
- Payment request approvers
- Invoice reports
- Payment requests

### 2. Delivery Receipt Data
- Delivery receipt items
- Delivery receipts

### 3. Purchase Order Data
- Purchase order items
- Purchase order approvers
- Purchase orders

### 4. Canvass Data
- Canvass item suppliers
- Canvass items
- Canvass approvers
- Canvass requisitions

### 5. Requisition Data
- Requisition approvers
- Requisition item lists
- Comments related to requisitions
- Notes related to requisitions
- Attachments related to requisitions
- Requisitions

## Safety Features

### 1. User Verification
- Checks if the user exists before proceeding
- Shows a breakdown of data to be deleted
- Requires explicit confirmation (type 'DELETE')

### 2. Progress Tracking
- Shows step-by-step progress
- Counts deleted records for each table
- Provides a final summary

### 3. Final Verification
- Verifies complete deletion
- Shows total records deleted
- Confirms no remaining data

## Sample Output

```
========================================
 PRS User Data Deletion Script
========================================
Target User: Bom Park

[INFO] Checking data for user: Bom Park
[FOUND] User has 5 requisition(s)

[INFO] Analyzing data to be deleted...
     table_name      | count 
--------------------+-------
 requisition_item_lists | 8
 delivery_receipts      | 8
 canvass_requisitions   | 6
 purchase_orders        | 5
 requisitions           | 5

[WARNING] This will permanently delete ALL data for user: Bom Park
[WARNING] This action cannot be undone!

Are you sure you want to continue? (type 'DELETE' to confirm): DELETE

[STARTING] Deletion process for user: Bom Park

Step 1: Deleting Payment Request data...
[DELETING] payment request approvers
[DELETED] 15 records from payment request approvers
...

========================================
 DELETION SUMMARY
========================================
User: Bom Park
Total records deleted: 158
Remaining records: 0
[SUCCESS] All data for user 'Bom Park' has been completely deleted!
========================================
```

## Error Handling

The script includes error handling for:
- Missing user name parameter
- Non-existent users
- Database connection issues
- Failed deletions

## Requirements

- Docker environment with PRS containers running
- Access to the database container
- Proper database credentials configured in the script

## Security Notes

- The script contains database credentials - keep it secure
- Only authorized personnel should have access to this script
- Always verify the user name before running
- Consider backing up data before deletion if needed

## Troubleshooting

### Script won't run
```bash
# Make sure the script is executable
chmod +x scripts/delete-user-data.sh
```

### Database connection issues
- Verify containers are running: `docker ps`
- Check database container name and credentials in the script

### Partial deletion
- The script will show which step failed
- You may need to manually clean up remaining data
- Check database logs for specific error messages
