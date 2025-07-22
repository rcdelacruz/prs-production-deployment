#!/bin/bash

# =============================================================================
# Delete User Data Script
# =============================================================================
# This script deletes ALL data related to a specific user from the PRS system
#
# Usage: ./delete-user-data.sh "Full Name"
# Example: ./delete-user-data.sh "Bom Park"
#
# WARNING: This will permanently delete ALL data for the specified user!
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection details
DB_HOST="prs-ec2-postgres-timescale"
DB_NAME="prs_preprod"
DB_USER="prs_user"
DB_PASSWORD="p*Ecp5YP2cvctg"

# Function to execute SQL and return result
execute_sql() {
    local sql="$1"
    local description="$2"

    echo -e "${BLUE}[INFO]${NC} $description"

    docker exec -e PGPASSWORD="$DB_PASSWORD" "$DB_HOST" \
        psql -U "$DB_USER" -d "$DB_NAME" -c "$sql"
}

# Function to get count of records
get_count() {
    local sql="$1"

    docker exec -e PGPASSWORD="$DB_PASSWORD" "$DB_HOST" \
        psql -U "$DB_USER" -d "$DB_NAME" -t -c "$sql" | tr -d ' '
}

# Function to display usage
usage() {
    echo "Usage: $0 \"Full Name\""
    echo "Example: $0 \"Bom Park\""
    echo ""
    echo "This script will delete ALL data related to the specified user."
    echo "WARNING: This action is irreversible!"
    exit 1
}

# Check if user name is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}[ERROR]${NC} No user name provided"
    usage
fi

USER_NAME="$1"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW} PRS User Data Deletion Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "${BLUE}Target User:${NC} $USER_NAME"
echo ""

# First, check if user exists and show what will be deleted
echo -e "${BLUE}[INFO]${NC} Checking data for user: $USER_NAME"

# Check if user has any requisitions
REQUISITION_COUNT=$(get_count "
    SELECT COUNT(*)
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
")

if [ "$REQUISITION_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}[WARNING]${NC} No data found for user: $USER_NAME"
    exit 0
fi

echo -e "${GREEN}[FOUND]${NC} User has $REQUISITION_COUNT requisition(s)"

# Show detailed breakdown of what will be deleted
echo -e "\n${BLUE}[INFO]${NC} Analyzing data to be deleted..."

execute_sql "
SELECT
    'requisitions' as table_name,
    COUNT(*) as count
FROM requisitions r
JOIN users u ON r.created_by = u.id
WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'

UNION ALL

SELECT 'payment_requests', COUNT(*)
FROM rs_payment_requests pr
JOIN requisitions r ON pr.requisition_id = r.id
JOIN users u ON r.created_by = u.id
WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'

UNION ALL

SELECT 'canvass_requisitions', COUNT(*)
FROM canvass_requisitions cr
JOIN requisitions r ON cr.requisition_id = r.id
JOIN users u ON r.created_by = u.id
WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'

UNION ALL

SELECT 'purchase_orders', COUNT(*)
FROM purchase_orders po
JOIN requisitions r ON po.requisition_id = r.id
JOIN users u ON r.created_by = u.id
WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'

UNION ALL

SELECT 'delivery_receipts', COUNT(*)
FROM delivery_receipts dr
JOIN requisitions r ON dr.requisition_id = r.id
JOIN users u ON r.created_by = u.id
WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'

ORDER BY count DESC;
" "Data breakdown for $USER_NAME"

# Confirmation prompt
echo ""
echo -e "${RED}[WARNING]${NC} This will permanently delete ALL data for user: $USER_NAME"
echo -e "${RED}[WARNING]${NC} This action cannot be undone!"
echo ""
read -p "Are you sure you want to continue? (type 'DELETE' to confirm): " confirmation

if [ "$confirmation" != "DELETE" ]; then
    echo -e "${YELLOW}[CANCELLED]${NC} Operation cancelled by user"
    exit 0
fi

echo ""
echo -e "${GREEN}[STARTING]${NC} Deletion process for user: $USER_NAME"
echo ""

# Start deletion process
TOTAL_DELETED=0

# Function to delete and count
delete_and_count() {
    local sql="$1"
    local description="$2"

    echo -e "${BLUE}[DELETING]${NC} $description"

    local result=$(docker exec -e PGPASSWORD="$DB_PASSWORD" "$DB_HOST" \
        psql -U "$DB_USER" -d "$DB_NAME" -c "$sql" | grep "DELETE" | awk '{print $2}')

    if [ -n "$result" ]; then
        echo -e "${GREEN}[DELETED]${NC} $result records from $description"
        TOTAL_DELETED=$((TOTAL_DELETED + result))
    fi
}

# Step 1: Delete Payment Request related data
echo -e "${YELLOW}Step 1: Deleting Payment Request data...${NC}"

delete_and_count "
DELETE FROM rs_payment_request_approvers
WHERE payment_request_id IN (
    SELECT pr.id
    FROM rs_payment_requests pr
    JOIN requisitions r ON pr.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "payment request approvers"

delete_and_count "
DELETE FROM invoice_reports
WHERE payment_request_id IN (
    SELECT pr.id
    FROM rs_payment_requests pr
    JOIN requisitions r ON pr.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "invoice reports"

delete_and_count "
DELETE FROM rs_payment_requests
WHERE id IN (
    SELECT pr.id
    FROM rs_payment_requests pr
    JOIN requisitions r ON pr.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "payment requests"

# Step 2: Delete Delivery Receipt data
echo -e "${YELLOW}Step 2: Deleting Delivery Receipt data...${NC}"

delete_and_count "
DELETE FROM delivery_receipt_items
WHERE dr_id IN (
    SELECT dr.id FROM delivery_receipts dr
    JOIN requisitions r ON dr.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "delivery receipt items"

delete_and_count "
DELETE FROM delivery_receipts
WHERE requisition_id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "delivery receipts"

# Step 3: Delete Purchase Order data
echo -e "${YELLOW}Step 3: Deleting Purchase Order data...${NC}"

delete_and_count "
DELETE FROM purchase_order_items
WHERE purchase_order_id IN (
    SELECT po.id FROM purchase_orders po
    JOIN requisitions r ON po.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "purchase order items"

delete_and_count "
DELETE FROM purchase_order_approvers
WHERE purchase_order_id IN (
    SELECT po.id FROM purchase_orders po
    JOIN requisitions r ON po.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "purchase order approvers"

delete_and_count "
DELETE FROM purchase_orders
WHERE requisition_id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "purchase orders"

# Step 4: Delete Canvass data
echo -e "${YELLOW}Step 4: Deleting Canvass data...${NC}"

delete_and_count "
DELETE FROM canvass_item_suppliers
WHERE canvass_item_id IN (
    SELECT ci.id FROM canvass_items ci
    JOIN canvass_requisitions cr ON ci.canvass_requisition_id = cr.id
    JOIN requisitions r ON cr.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "canvass item suppliers"

delete_and_count "
DELETE FROM canvass_items
WHERE canvass_requisition_id IN (
    SELECT cr.id FROM canvass_requisitions cr
    JOIN requisitions r ON cr.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "canvass items"

delete_and_count "
DELETE FROM canvass_approvers
WHERE canvass_requisition_id IN (
    SELECT cr.id FROM canvass_requisitions cr
    JOIN requisitions r ON cr.requisition_id = r.id
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "canvass approvers"

delete_and_count "
DELETE FROM canvass_requisitions
WHERE requisition_id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "canvass requisitions"

# Step 5: Delete Requisition related data
echo -e "${YELLOW}Step 5: Deleting Requisition data...${NC}"

delete_and_count "
DELETE FROM requisition_approvers
WHERE requisition_id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "requisition approvers"

delete_and_count "
DELETE FROM requisition_item_lists
WHERE requisition_id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "requisition item lists"

delete_and_count "
DELETE FROM comments
WHERE model = 'requisition' AND model_id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "requisition comments"

delete_and_count "
DELETE FROM notes
WHERE model = 'requisition' AND model_id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "requisition notes"

delete_and_count "
DELETE FROM attachments
WHERE model = 'requisition' AND model_id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "requisition attachments"

# Step 6: Finally delete the requisitions
echo -e "${YELLOW}Step 6: Deleting Requisitions...${NC}"

delete_and_count "
DELETE FROM requisitions
WHERE id IN (
    SELECT r.id
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
);
" "requisitions"

# Final verification
echo ""
echo -e "${BLUE}[INFO]${NC} Verifying complete deletion..."

REMAINING_COUNT=$(get_count "
    SELECT COUNT(*)
    FROM requisitions r
    JOIN users u ON r.created_by = u.id
    WHERE u.first_name || ' ' || u.last_name = '$USER_NAME'
")

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW} DELETION SUMMARY${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "${BLUE}User:${NC} $USER_NAME"
echo -e "${GREEN}Total records deleted:${NC} $TOTAL_DELETED"
echo -e "${BLUE}Remaining records:${NC} $REMAINING_COUNT"

if [ "$REMAINING_COUNT" -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} All data for user '$USER_NAME' has been completely deleted!"
else
    echo -e "${RED}[WARNING]${NC} $REMAINING_COUNT records still remain for user '$USER_NAME'"
fi

echo -e "${YELLOW}========================================${NC}"
echo ""
