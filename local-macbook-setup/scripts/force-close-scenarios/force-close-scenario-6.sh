#!/bin/bash

# ============================================================================
# Force Close Scenario 6: Invalid - Multiple POs Mixed Status (NOT ELIGIBLE)
# ============================================================================
# Requirements: RS Status: rs_in_progress
# PO1 Status: for_delivery
# PO2 Status: for_po_approval (status before for_delivery)
# Expected: Button HIDDEN
# Reason: Mixed PO statuses - least progressed status must be "For Delivery"
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
DB_USER=${DB_USER:-prs_user}
DB_NAME=${DB_NAME:-prs_local}
DB_PASSWORD=${DB_PASSWORD:-localdev123}

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Force Close Scenario 6: Invalid - Multiple POs Mixed Status${NC}"
echo -e "${BLUE}============================================================================${NC}"

# Function to execute SQL
execute_sql() {
    local sql="$1"
    local description="$2"

    echo -e "${YELLOW}Executing: $description${NC}"

    if docker exec prs-local-postgres-timescale bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -c \"$sql\"" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Success: $description${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed: $description${NC}"
        docker exec prs-local-postgres-timescale bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -c \"$sql\""
        return 1
    fi
}

# Clean up existing test data for this scenario
echo -e "${YELLOW}Cleaning up existing Scenario 6 test data...${NC}"
execute_sql "DELETE FROM purchase_order_items WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE po_number IN ('FC-PO6A', 'FC-PO6B'));" "Clean PO items"
execute_sql "DELETE FROM purchase_orders WHERE po_number IN ('FC-PO6A', 'FC-PO6B');" "Clean purchase orders"
execute_sql "DELETE FROM canvass_item_suppliers WHERE canvass_item_id IN (SELECT id FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6')));" "Clean canvass item suppliers"
execute_sql "DELETE FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6'));" "Clean canvass items"
execute_sql "DELETE FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6');" "Clean canvass requisitions"
execute_sql "DELETE FROM requisition_item_lists WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6');" "Clean requisition items"
execute_sql "DELETE FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6';" "Clean requisitions"

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

# Create requisition
execute_sql "
INSERT INTO requisitions (
    rs_number, rs_letter, purpose, status, created_by, assigned_to,
    company_code, company_id, department_id, date_required, delivery_address,
    charge_to, created_at, updated_at
) VALUES (
    'TEST-FC-SCENARIO6', 'A', 'Force Close Test - Multiple POs Mixed Status',
    'rs_in_progress', 150, 150, '12553', 1, 1, NOW() + INTERVAL '30 days',
    'Test Delivery Address', 'Test Project', NOW(), NOW()
);" "Create Scenario 6 requisition"

# Create requisition items
execute_sql "
INSERT INTO requisition_item_lists (
    requisition_id, item_id, quantity, item_type, notes,
    created_at, updated_at
)
SELECT r.id, 7, 200, 'ofm', 'Test Item 7 for Force Close Scenario 6', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO6';" "Create Scenario 6 requisition items"

# Create canvass requisitions (two separate canvass sheets)
execute_sql "
INSERT INTO canvass_requisitions (
    requisition_id, cs_letter, status, created_at, updated_at
)
SELECT r.id, 'A', 'approved', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO6'
UNION ALL
SELECT r.id, 'B', 'approved', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO6';" "Create Scenario 6 canvass requisitions"

# Create canvass items
execute_sql "
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, requisition_id, status,
    created_at, updated_at
)
SELECT cr.id, ril.id, r.id, 'approved', NOW(), NOW()
FROM canvass_requisitions cr, requisitions r, requisition_item_lists ril
WHERE r.rs_number = 'TEST-FC-SCENARIO6'
  AND cr.requisition_id = r.id
  AND ril.requisition_id = r.id;" "Create Scenario 6 canvass items"

# Create canvass item suppliers
execute_sql "
INSERT INTO canvass_item_suppliers (
    canvass_item_id, supplier_id, supplier_type, term, quantity, \\\"order\\\",
    unit_price, is_selected, created_at, updated_at
)
SELECT ci.id,
       CASE WHEN cr.cs_letter = 'A' THEN 1 ELSE 2 END,
       'supplier', '30 days', 100, 1, 50.00, true, NOW(), NOW()
FROM canvass_items ci, canvass_requisitions cr, requisitions r
WHERE r.rs_number = 'TEST-FC-SCENARIO6'
  AND cr.requisition_id = r.id
  AND ci.canvass_requisition_id = cr.id;" "Create Scenario 6 canvass item suppliers"

# Create first purchase order (for_delivery)
execute_sql "
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id,
    supplier_type, status, total_amount, created_at, updated_at
)
SELECT 'FC-PO6A', 'A', r.id, cr.id, 1, 'supplier', 'for_delivery',
       5000.00, NOW(), NOW()
FROM requisitions r, canvass_requisitions cr
WHERE r.rs_number = 'TEST-FC-SCENARIO6' AND cr.cs_letter = 'A';" "Create Scenario 6 first purchase order (for_delivery)"

# Create second purchase order (for_po_approval - mixed status)
execute_sql "
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id,
    supplier_type, status, total_amount, created_at, updated_at
)
SELECT 'FC-PO6B', 'B', r.id, cr.id, 2, 'supplier', 'for_po_approval',
       5000.00, NOW(), NOW()
FROM requisitions r, canvass_requisitions cr
WHERE r.rs_number = 'TEST-FC-SCENARIO6' AND cr.cs_letter = 'B';" "Create Scenario 6 second purchase order (for_po_approval)"

# Create PO items for both POs
execute_sql "
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id,
    quantity_purchased, canvass_item_supplier_id, created_at, updated_at
)
SELECT po.id, ci.id, ril.id, 100, cis.id, NOW(), NOW()
FROM purchase_orders po, canvass_items ci, requisition_item_lists ril,
     canvass_item_suppliers cis, canvass_requisitions cr, requisitions r
WHERE po.po_number IN ('FC-PO6A', 'FC-PO6B')
  AND r.rs_number = 'TEST-FC-SCENARIO6'
  AND ril.requisition_id = r.id
  AND cr.requisition_id = r.id
  AND ci.canvass_requisition_id = cr.id
  AND ci.requisition_item_list_id = ril.id
  AND cis.canvass_item_id = ci.id
  AND cis.is_selected = true
  AND po.canvass_requisition_id = cr.id;" "Create Scenario 6 PO items"

echo -e "${GREEN}✓ Scenario 6 setup completed successfully${NC}"
echo -e "${YELLOW}Expected Result: Button HIDDEN (Multiple POs Mixed Status)${NC}"
echo -e "${YELLOW}Test with user: ronald (ID: 150)${NC}"
echo -e "${YELLOW}PO1 Status: for_delivery, PO2 Status: for_po_approval${NC}"
echo -e "${YELLOW}Reason: Mixed PO statuses - least progressed status must be 'For Delivery'${NC}"
