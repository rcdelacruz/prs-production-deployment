#!/bin/bash

# ============================================================================
# Force Close Scenario 9: Invalid - Auto-Close Detection (NOT ELIGIBLE)
# ============================================================================
# Requirements: RS Status: rs_in_progress, PO Status: closed_po (all POs closed)
# Delivery: Full (Item 7: 100/100, Item 28: 50/50)
# Payment: All delivered quantities paid (Closed)
# Canvass: All requisition quantities covered by approved canvass sheets
# Remaining Quantities: None (all items fully canvassed and delivered)
# Expected: Button HIDDEN
# Reason: "Requisition should auto-close - all conditions met for automatic closure"
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
echo -e "${BLUE}Force Close Scenario 9: Invalid - Auto-Close Detection${NC}"
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
echo -e "${YELLOW}Cleaning up existing Scenario 9 test data...${NC}"
execute_sql "DELETE FROM rs_payment_requests WHERE pr_number = 'FC-PR9';" "Clean payment requests"
execute_sql "DELETE FROM delivery_receipt_items WHERE dr_id IN (SELECT id FROM delivery_receipts WHERE dr_number = 'FC-DR9');" "Clean delivery receipt items"
execute_sql "DELETE FROM delivery_receipts WHERE dr_number = 'FC-DR9';" "Clean delivery receipts"
execute_sql "DELETE FROM purchase_order_items WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE po_number = 'FC-PO9');" "Clean PO items"
execute_sql "DELETE FROM purchase_orders WHERE po_number = 'FC-PO9';" "Clean purchase orders"
execute_sql "DELETE FROM canvass_item_suppliers WHERE canvass_item_id IN (SELECT id FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9')));" "Clean canvass item suppliers"
execute_sql "DELETE FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9'));" "Clean canvass items"
execute_sql "DELETE FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9');" "Clean canvass requisitions"
execute_sql "DELETE FROM requisition_item_lists WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9');" "Clean requisition items"
execute_sql "DELETE FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9';" "Clean requisitions"

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

# Create requisition
execute_sql "
INSERT INTO requisitions (
    rs_number, rs_letter, purpose, status, created_by, assigned_to,
    company_code, company_id, department_id, date_required, delivery_address,
    charge_to, created_at, updated_at
) VALUES (
    'TEST-FC-SCENARIO9', 'A', 'Force Close Test - Auto-Close Detection',
    'rs_in_progress', 150, 150, '12553', 1, 1, NOW() + INTERVAL '30 days',
    'Test Delivery Address', 'Test Project', NOW(), NOW()
);" "Create Scenario 9 requisition"

# Create requisition items (Item 7: 100, Item 28: 50 - fully canvassed and delivered)
execute_sql "
INSERT INTO requisition_item_lists (
    requisition_id, item_id, quantity, item_type, notes,
    created_at, updated_at
)
SELECT r.id, 7, 100, 'ofm', 'Test Item 7 for Force Close Scenario 9', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO9'
UNION ALL
SELECT r.id, 28, 50, 'ofm', 'Test Item 28 for Force Close Scenario 9', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO9';" "Create Scenario 9 requisition items"

# Create canvass requisition
execute_sql "
INSERT INTO canvass_requisitions (
    requisition_id, cs_letter, status, created_at, updated_at
)
SELECT r.id, 'A', 'approved', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO9';" "Create Scenario 9 canvass requisition"

# Create canvass items (fully canvassed - no remaining quantities)
execute_sql "
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, requisition_id, status,
    created_at, updated_at
)
SELECT cr.id, ril.id, r.id, 'approved', NOW(), NOW()
FROM canvass_requisitions cr, requisitions r, requisition_item_lists ril
WHERE r.rs_number = 'TEST-FC-SCENARIO9'
  AND cr.requisition_id = r.id
  AND ril.requisition_id = r.id;" "Create Scenario 9 canvass items"

# Create canvass item suppliers (full quantities canvassed)
execute_sql "
INSERT INTO canvass_item_suppliers (
    canvass_item_id, supplier_id, supplier_type, term, quantity, \\\"order\\\",
    unit_price, is_selected, created_at, updated_at
)
SELECT ci.id, 1, 'supplier', '30 days', ril.quantity, 1, 50.00, true, NOW(), NOW()
FROM canvass_items ci, requisition_item_lists ril, requisitions r
WHERE r.rs_number = 'TEST-FC-SCENARIO9'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id;" "Create Scenario 9 canvass item suppliers"

# Create purchase order (CLOSED status - all POs closed)
execute_sql "
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id,
    supplier_type, status, total_amount, created_at, updated_at
)
SELECT 'FC-PO9', 'A', r.id, cr.id, 1, 'supplier', 'closed_po',
       7500.00, NOW(), NOW()
FROM requisitions r, canvass_requisitions cr
WHERE r.rs_number = 'TEST-FC-SCENARIO9' AND cr.requisition_id = r.id;" "Create Scenario 9 purchase order (CLOSED)"

# Create PO items
execute_sql "
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id,
    quantity_purchased, canvass_item_supplier_id, created_at, updated_at
)
SELECT po.id, ci.id, ril.id, ril.quantity, cis.id, NOW(), NOW()
FROM purchase_orders po, canvass_items ci, requisition_item_lists ril,
     canvass_item_suppliers cis, requisitions r
WHERE po.po_number = 'FC-PO9'
  AND r.rs_number = 'TEST-FC-SCENARIO9'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id
  AND cis.canvass_item_id = ci.id
  AND cis.is_selected = true;" "Create Scenario 9 PO items"

# Create full delivery receipt (Item 7: 100/100, Item 28: 50/50)
execute_sql "
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, status, company_code,
    created_at, updated_at
)
SELECT 'FC-DR9', r.id, po.id, 'Delivered', '12553', NOW(), NOW()
FROM purchase_orders po, requisitions r
WHERE po.po_number = 'FC-PO9' AND r.rs_number = 'TEST-FC-SCENARIO9';" "Create Scenario 9 delivery receipt"

# Create delivery receipt items (full delivery: Item 7: 100/100, Item 28: 50/50)
execute_sql "
INSERT INTO delivery_receipt_items (
    dr_id, po_id, po_item_id, item_id, item_des, qty_ordered, qty_delivered,
    unit, created_at, updated_at
)
SELECT dr.id, po.id, poi.id, ril.item_id,
       CASE WHEN ril.item_id = 7 THEN 'Test Item 7' ELSE 'Test Item 28' END,
       ril.quantity, ril.quantity,
       'PCS', NOW(), NOW()
FROM delivery_receipts dr, purchase_orders po, purchase_order_items poi,
     requisition_item_lists ril, requisitions r
WHERE dr.dr_number = 'FC-DR9'
  AND po.po_number = 'FC-PO9'
  AND poi.purchase_order_id = po.id
  AND ril.id = poi.requisition_item_list_id
  AND r.rs_number = 'TEST-FC-SCENARIO9'
  AND ril.requisition_id = r.id;" "Create Scenario 9 delivery receipt items"

# Create payment request (ALL PR STATUS: CLOSED - all delivered quantities paid)
execute_sql "
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, status, is_draft,
    total_amount, created_at, updated_at
)
SELECT 'FC-PR9', 'A', r.id, po.id, 'Closed', false, 7500.00, NOW(), NOW()
FROM requisitions r, purchase_orders po
WHERE r.rs_number = 'TEST-FC-SCENARIO9'
  AND po.po_number = 'FC-PO9';" "Create Scenario 9 payment request (CLOSED)"

echo -e "${GREEN}✓ Scenario 9 setup completed successfully${NC}"
echo -e "${YELLOW}Expected Result: Button HIDDEN (Auto-Close Detection)${NC}"
echo -e "${YELLOW}Test with user: ronald (ID: 150)${NC}"
echo -e "${YELLOW}All POs: CLOSED | Delivery: FULL (100/100, 50/50) | Payment: CLOSED${NC}"
echo -e "${YELLOW}Canvass: ALL quantities covered | Remaining: NONE${NC}"
echo -e "${YELLOW}Reason: Requisition should auto-close - all conditions met for automatic closure${NC}"
