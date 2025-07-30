#!/bin/bash

# ============================================================================
# Force Close Scenario 3: Invalid Force Close - No Delivery (NOT ELIGIBLE)
# ============================================================================
# Requirements: RS Status: rs_in_progress, PO Status: for_delivery
# Delivery: None (0 deliveries)
# Payment: N/A
# Expected: Button VISIBLE but DISABLED
# Reason: No deliveries yet
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

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Force Close Scenario 3: Invalid Force Close - No Delivery${NC}"
echo -e "${BLUE}============================================================================${NC}"

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

# Clean up existing test data for this scenario
echo -e "${YELLOW}Cleaning up existing Scenario 3 test data...${NC}"
execute_sql "DELETE FROM purchase_order_items WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE po_number = 'FC-PO3');" "Clean PO items"
execute_sql "DELETE FROM purchase_orders WHERE po_number = 'FC-PO3';" "Clean purchase orders"
execute_sql "DELETE FROM suppliers WHERE name = 'Test Supplier Corp 3';" "Clean test supplier"
execute_sql "DELETE FROM canvass_item_suppliers WHERE canvass_item_id IN (SELECT id FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3')));" "Clean canvass item suppliers"
execute_sql "DELETE FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'));" "Clean canvass items"
execute_sql "DELETE FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3');" "Clean canvass requisitions"
execute_sql "DELETE FROM requisition_item_lists WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3');" "Clean requisition items"
execute_sql "DELETE FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3';" "Clean requisitions"

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

# Create requisition
execute_sql "
INSERT INTO requisitions (
    rs_number, rs_letter, purpose, status, created_by, assigned_to,
    company_code, company_id, department_id, date_required, delivery_address,
    charge_to, created_at, updated_at
) VALUES (
    'TEST-FC-SCENARIO3', 'A', 'Force Close Test - No Delivery',
    'rs_in_progress', 150, 150, '12553', 1, 1, NOW() + INTERVAL '30 days',
    'Test Delivery Address', 'Test Project', NOW(), NOW()
);" "Create Scenario 3 requisition"

# Create requisition items
execute_sql "
INSERT INTO requisition_item_lists (
    requisition_id, item_id, quantity, item_type, notes,
    created_at, updated_at
)
SELECT r.id, 7, 100, 'ofm', 'Test Item 7 for Force Close Scenario 3', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO3';" "Create Scenario 3 requisition items"

# Create canvass requisition
execute_sql "
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status, created_at, updated_at
)
SELECT r.id, 'FC-CS3', 'A', 'approved', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO3';" "Create Scenario 3 canvass requisition"

# Create canvass items
execute_sql "
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, requisition_id, status,
    created_at, updated_at
)
SELECT cr.id, ril.id, r.id, 'approved', NOW(), NOW()
FROM canvass_requisitions cr, requisitions r, requisition_item_lists ril
WHERE r.rs_number = 'TEST-FC-SCENARIO3'
  AND cr.requisition_id = r.id
  AND ril.requisition_id = r.id;" "Create Scenario 3 canvass items"

# Create test supplier
execute_sql "
INSERT INTO suppliers (
    user_id, name, tin, address, citizenship_code, nature_of_income,
    pay_code, ic_code, status, created_at, updated_at
)
VALUES (
    150, 'Test Supplier Corp 3', '123456789013', 'Test Address 3',
    'PH', 'Business', 'TS03', 'IC', 'active', NOW(), NOW()
);" "Create test supplier"

# Create canvass item suppliers
execute_sql "
INSERT INTO canvass_item_suppliers (
    canvass_item_id, supplier_id, supplier_type, term, quantity, \\\"order\\\",
    unit_price, is_selected, created_at, updated_at
)
SELECT ci.id, s.id, 'supplier', '30 days', ril.quantity, 1, 50.00, true, NOW(), NOW()
FROM canvass_items ci, requisition_item_lists ril, requisitions r, suppliers s
WHERE r.rs_number = 'TEST-FC-SCENARIO3'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id
  AND s.name = 'Test Supplier Corp 3';" "Create Scenario 3 canvass item suppliers"

# Create purchase order (for_delivery status but no delivery yet)
execute_sql "
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id,
    supplier_type, status, total_amount, created_at, updated_at
)
SELECT 'FC-PO3', 'A', r.id, cr.id, s.id, 'supplier', 'for_delivery',
       5000.00, NOW(), NOW()
FROM requisitions r, canvass_requisitions cr, suppliers s
WHERE r.rs_number = 'TEST-FC-SCENARIO3'
  AND cr.requisition_id = r.id
  AND s.name = 'Test Supplier Corp 3';" "Create Scenario 3 purchase order"

# Create PO items
execute_sql "
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id,
    quantity_purchased, canvass_item_supplier_id, created_at, updated_at
)
SELECT po.id, ci.id, ril.id, ril.quantity, cis.id, NOW(), NOW()
FROM purchase_orders po, canvass_items ci, requisition_item_lists ril,
     canvass_item_suppliers cis, requisitions r
WHERE po.po_number = 'FC-PO3'
  AND r.rs_number = 'TEST-FC-SCENARIO3'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id
  AND cis.canvass_item_id = ci.id
  AND cis.is_selected = true;" "Create Scenario 3 PO items"

# NOTE: No delivery receipt created - this is the key difference for this scenario

echo -e "${GREEN}✓ Scenario 3 setup completed successfully${NC}"
echo -e "${YELLOW}Expected Result: Button VISIBLE but DISABLED (No Delivery)${NC}"
echo -e "${YELLOW}Test with user: ronald (ID: 150)${NC}"
echo -e "${YELLOW}PO Status: for_delivery${NC}"
echo -e "${YELLOW}Delivery: NONE (0 deliveries)${NC}"
echo -e "${YELLOW}Reason: No deliveries yet${NC}"
