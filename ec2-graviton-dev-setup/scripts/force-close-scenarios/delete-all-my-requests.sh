#!/bin/bash

# ============================================================================
# Delete Force Close Test Scenarios Script
# ============================================================================
# This script deletes only the force close test scenarios (TEST-FC-SCENARIO*)
# Safe to use - only deletes test data created by the scenario scripts
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection parameters
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [[ -f "$PROJECT_DIR/.env" ]]; then
    source "$PROJECT_DIR/.env"
fi

# Set default values
DB_USER=${POSTGRES_USER:-prs_user}
DB_NAME=${POSTGRES_DB:-prs_production}
DB_PASSWORD=${POSTGRES_PASSWORD:-p*Ecp5YP2cvctg}
USER_ID=${USER_ID:-150}  # Default to ronald's user ID

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Delete Force Close Test Scenarios Script${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${YELLOW}This will delete only force close test scenarios (TEST-FC-SCENARIO*)${NC}"
echo -e "${YELLOW}Safe to use - only affects test data${NC}"
echo ""

# Function to execute SQL
execute_sql() {
    local sql="$1"
    local description="$2"

    echo -e "${YELLOW}Executing: $description${NC}"

    if docker exec prs-ec2-postgres-timescale bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -c \"$sql\"" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Success: $description${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed: $description${NC}"
        docker exec prs-ec2-postgres-timescale bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -c \"$sql\""
        return 1
    fi
}

# Function to get count of test scenario requisitions
get_requisition_count() {
    docker exec prs-ec2-postgres-timescale bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM requisitions WHERE rs_number LIKE 'TEST-FC-SCENARIO%';\"" | tr -d ' '
}

# Check how many test scenarios will be deleted
REQUISITION_COUNT=$(get_requisition_count)
echo -e "${YELLOW}Found $REQUISITION_COUNT force close test scenarios${NC}"

if [ "$REQUISITION_COUNT" -eq 0 ]; then
    echo -e "${GREEN}No force close test scenarios found${NC}"
    exit 0
fi

# Ask for confirmation
echo ""
read -p "Delete $REQUISITION_COUNT force close test scenarios? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting deletion process...${NC}"

# Delete in proper order to respect foreign key constraints

# 1. Delete payment requests
execute_sql "
DELETE FROM rs_payment_requests
WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete payment requests"

# 2. Delete invoice reports
execute_sql "
DELETE FROM invoice_reports
WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete invoice reports"

# 3. Delete delivery receipt invoices
execute_sql "
DELETE FROM delivery_receipt_invoices
WHERE delivery_receipt_id IN (
    SELECT dr.id FROM delivery_receipts dr
    JOIN requisitions r ON dr.requisition_id = r.id
    WHERE r.rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete delivery receipt invoices"

# 4. Delete delivery receipt items
execute_sql "
DELETE FROM delivery_receipt_items
WHERE dr_id IN (
    SELECT dr.id FROM delivery_receipts dr
    JOIN requisitions r ON dr.requisition_id = r.id
    WHERE r.rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete delivery receipt items"

# 5. Delete delivery receipts
execute_sql "
DELETE FROM delivery_receipts
WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete delivery receipts"

# 6. Delete purchase order items
execute_sql "
DELETE FROM purchase_order_items
WHERE purchase_order_id IN (
    SELECT po.id FROM purchase_orders po
    JOIN requisitions r ON po.requisition_id = r.id
    WHERE r.rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete purchase order items"

# 7. Delete purchase orders
execute_sql "
DELETE FROM purchase_orders
WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete purchase orders"

# 8. Delete canvass item suppliers
execute_sql "
DELETE FROM canvass_item_suppliers
WHERE canvass_item_id IN (
    SELECT ci.id FROM canvass_items ci
    JOIN requisitions r ON ci.requisition_id = r.id
    WHERE r.rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete canvass item suppliers"

# 9. Delete canvass items
execute_sql "
DELETE FROM canvass_items
WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete canvass items"

# 10. Delete canvass requisitions
execute_sql "
DELETE FROM canvass_requisitions
WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete canvass requisitions"

# 11. Delete requisition item lists
execute_sql "
DELETE FROM requisition_item_lists
WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-SCENARIO%'
);" "Delete requisition item lists"

# 12. Delete suppliers created for test scenarios
execute_sql "
DELETE FROM suppliers
WHERE name LIKE 'Test Supplier Corp%';" "Delete test suppliers"

# 13. Finally, delete test scenario requisitions
execute_sql "
DELETE FROM requisitions
WHERE rs_number LIKE 'TEST-FC-SCENARIO%';" "Delete test scenario requisitions"

# Verify deletion
REMAINING_COUNT=$(get_requisition_count)
echo ""
if [ "$REMAINING_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ All force close test scenarios successfully deleted!${NC}"
    echo -e "${GREEN}✓ Deleted $REQUISITION_COUNT test scenarios and all related data${NC}"
else
    echo -e "${RED}✗ Warning: $REMAINING_COUNT test scenarios still remain${NC}"
fi

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Force close test scenario cleanup completed${NC}"
echo -e "${BLUE}============================================================================${NC}"
