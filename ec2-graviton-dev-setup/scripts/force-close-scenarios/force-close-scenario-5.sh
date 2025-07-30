#!/bin/bash

# ============================================================================
# Force Close Scenario 5: Invalid - Single PO Not For Delivery (NOT ELIGIBLE)
# ============================================================================
# Requirements: RS Status: rs_in_progress
# PO Status: for_PO_review, for_PO_approval, for_sending, PO_rejected (status before for_delivery)
# Expected: Button HIDDEN
# Reason: No POs with "For Delivery" status
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Force Close Scenario 5: Invalid - Single PO Not For Delivery${NC}"
echo -e "${BLUE}============================================================================${NC}"

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
echo -e "${YELLOW}Cleaning up existing Scenario 5 test data...${NC}"
execute_sql "DELETE FROM purchase_order_items WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE po_number = 'FC-PO5');" "Clean PO items"
execute_sql "DELETE FROM purchase_orders WHERE po_number = 'FC-PO5';" "Clean purchase orders"
execute_sql "DELETE FROM canvass_item_suppliers WHERE canvass_item_id IN (SELECT id FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5')));" "Clean canvass item suppliers"
execute_sql "DELETE FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5'));" "Clean canvass items"
execute_sql "DELETE FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5');" "Clean canvass requisitions"
execute_sql "DELETE FROM requisition_item_lists WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5');" "Clean requisition items"
execute_sql "DELETE FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5';" "Clean requisitions"

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

# Create requisition
execute_sql "
INSERT INTO requisitions (
    rs_number, rs_letter, purpose, status, created_by, assigned_to,
    company_code, company_id, department_id, date_required, delivery_address,
    charge_to, created_at, updated_at
) VALUES (
    'TEST-FC-SCENARIO5', 'A', 'Force Close Test - PO Not For Delivery',
    'rs_in_progress', 150, 150, '12553', 1, 1, NOW() + INTERVAL '30 days',
    'Test Delivery Address', 'Test Project', NOW(), NOW()
);" "Create Scenario 5 requisition"

# Create requisition items
execute_sql "
INSERT INTO requisition_item_lists (
    requisition_id, item_id, quantity, item_type, notes,
    created_at, updated_at
)
SELECT r.id, 7, 100, 'ofm', 'Test Item 7 for Force Close Scenario 5', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO5';" "Create Scenario 5 requisition items"

# Create canvass requisition
execute_sql "
INSERT INTO canvass_requisitions (
    requisition_id, cs_letter, status, created_at, updated_at
)
SELECT r.id, 'A', 'approved', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO5';" "Create Scenario 5 canvass requisition"

# Create canvass items
execute_sql "
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, requisition_id, status,
    created_at, updated_at
)
SELECT cr.id, ril.id, r.id, 'approved', NOW(), NOW()
FROM canvass_requisitions cr, requisitions r, requisition_item_lists ril
WHERE r.rs_number = 'TEST-FC-SCENARIO5'
  AND cr.requisition_id = r.id
  AND ril.requisition_id = r.id;" "Create Scenario 5 canvass items"

# Create canvass item suppliers
execute_sql "
INSERT INTO canvass_item_suppliers (
    canvass_item_id, supplier_id, supplier_type, term, quantity, \\\"order\\\",
    unit_price, is_selected, created_at, updated_at
)
SELECT ci.id, 1, 'supplier', '30 days', ril.quantity, 1, 50.00, true, NOW(), NOW()
FROM canvass_items ci, requisition_item_lists ril, requisitions r
WHERE r.rs_number = 'TEST-FC-SCENARIO5'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id;" "Create Scenario 5 canvass item suppliers"

# Create purchase order with status BEFORE For Delivery
execute_sql "
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id,
    supplier_type, status, total_amount, created_at, updated_at
)
SELECT 'FC-PO5', 'A', r.id, cr.id, 1, 'supplier', 'for_po_approval',
       5000.00, NOW(), NOW()
FROM requisitions r, canvass_requisitions cr
WHERE r.rs_number = 'TEST-FC-SCENARIO5' AND cr.requisition_id = r.id;" "Create Scenario 5 purchase order (For Approval status)"

# Create PO items
execute_sql "
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id,
    quantity_purchased, canvass_item_supplier_id, created_at, updated_at
)
SELECT po.id, ci.id, ril.id, ril.quantity, cis.id, NOW(), NOW()
FROM purchase_orders po, canvass_items ci, requisition_item_lists ril,
     canvass_item_suppliers cis, requisitions r
WHERE po.po_number = 'FC-PO5'
  AND r.rs_number = 'TEST-FC-SCENARIO5'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id
  AND cis.canvass_item_id = ci.id
  AND cis.is_selected = true;" "Create Scenario 5 PO items"

echo -e "${GREEN}✓ Scenario 5 setup completed successfully${NC}"
echo -e "${YELLOW}Expected Result: Button HIDDEN (Single PO Not For Delivery)${NC}"
echo -e "${YELLOW}Test with user: ronald (ID: 150)${NC}"
echo -e "${YELLOW}PO Status: For Approval (before For Delivery)${NC}"
echo -e "${YELLOW}Reason: No POs with 'For Delivery' status${NC}"
