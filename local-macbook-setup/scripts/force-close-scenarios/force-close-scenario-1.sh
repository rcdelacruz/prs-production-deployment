#!/bin/bash

# ============================================================================
# Force Close Scenario 1: Valid Force Close - Partial Delivery (ELIGIBLE)
# ============================================================================
# Requirements: RS Status: rs_in_progress, PO Status: for_delivery
# Delivery: Partial (Item 7: 60/100, Item 28: 30/50)
# Payment: All delivered quantities paid (ALL PR STATUS: CLOSED)
# Expected: Button VISIBLE and ENABLED
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
echo -e "${BLUE}Force Close Scenario 1: Valid Force Close - Partial Delivery${NC}"
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
echo -e "${YELLOW}Cleaning up existing Scenario 1 test data...${NC}"
execute_sql "DELETE FROM rs_payment_requests WHERE pr_number = 'FC-PR1';" "Clean payment requests"
execute_sql "DELETE FROM invoice_reports WHERE ir_number = 'FC-IR1';" "Clean invoice reports"
execute_sql "DELETE FROM delivery_receipt_items WHERE dr_id IN (SELECT id FROM delivery_receipts WHERE dr_number = 'FC-DR1');" "Clean delivery receipt items"
execute_sql "DELETE FROM delivery_receipts WHERE dr_number = 'FC-DR1';" "Clean delivery receipts"
execute_sql "DELETE FROM suppliers WHERE name = 'Test Supplier Corp';" "Clean test supplier"
execute_sql "DELETE FROM purchase_order_items WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE po_number IN ('FC-PO1A', 'FC-PO1B'));" "Clean primary and secondary PO items"
execute_sql "DELETE FROM purchase_orders WHERE po_number IN ('FC-PO1A', 'FC-PO1B');" "Clean purchase orders"
execute_sql "DELETE FROM canvass_item_suppliers WHERE canvass_item_id IN (SELECT id FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1')));" "Clean canvass item suppliers"
execute_sql "DELETE FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'));" "Clean canvass items"
execute_sql "DELETE FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1');" "Clean canvass requisitions"
execute_sql "DELETE FROM requisition_item_lists WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1');" "Clean requisition items"
execute_sql "DELETE FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1';" "Clean requisitions"

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

# Create requisition
execute_sql "
INSERT INTO requisitions (
    rs_number, rs_letter, purpose, status, created_by, assigned_to,
    company_code, company_id, department_id, date_required, delivery_address,
    charge_to, created_at, updated_at
) VALUES (
    'TEST-FC-SCENARIO1', 'A', 'Force Close Test - Partial Delivery',
    'rs_in_progress', 150, 150, '12553', 1, 1, NOW() + INTERVAL '30 days',
    'Test Delivery Address', 'Test Project', NOW(), NOW()
);" "Create Scenario 1 requisition"

# Create requisition items (Item 7: 100, Item 28: 50)
execute_sql "
INSERT INTO requisition_item_lists (
    requisition_id, item_id, quantity, item_type, notes,
    created_at, updated_at
)
SELECT r.id, 7, 100, 'ofm', 'Test Item 7 for Force Close Scenario 1', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO1'
UNION ALL
SELECT r.id, 28, 50, 'ofm', 'Test Item 28 for Force Close Scenario 1', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO1';" "Create Scenario 1 requisition items"

# Create canvass requisition
execute_sql "
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status, created_at, updated_at
)
SELECT r.id, 'FC-CS1', 'A', 'approved', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO1';" "Create Scenario 1 canvass requisition"

# Create canvass items (links requisition items to canvass)
execute_sql "
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, requisition_id, status,
    created_at, updated_at
)
SELECT cr.id, ril.id, r.id, 'approved', NOW(), NOW()
FROM canvass_requisitions cr, requisitions r, requisition_item_lists ril
WHERE r.rs_number = 'TEST-FC-SCENARIO1'
  AND cr.requisition_id = r.id
  AND ril.requisition_id = r.id;" "Create Scenario 1 canvass items"

# Create canvass item suppliers (supplier quotes)
execute_sql "
INSERT INTO canvass_item_suppliers (
    canvass_item_id, supplier_id, supplier_type, term, quantity, \\\"order\\\",
    unit_price, is_selected, created_at, updated_at
)
SELECT ci.id, 1, 'supplier', '30 days', ril.quantity, 1, 50.00, true, NOW(), NOW()
FROM canvass_items ci, requisition_item_lists ril, requisitions r
WHERE r.rs_number = 'TEST-FC-SCENARIO1'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id;" "Create Scenario 1 canvass item suppliers"

# Create multiple purchase orders as per requirements
# PO1: for_delivery (active PO with partial delivery)
execute_sql "
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id,
    supplier_type, status, total_amount, created_at, updated_at
)
SELECT 'FC-PO1A', 'A', r.id, cr.id, 1, 'supplier', 'for_delivery',
       5000.00, NOW(), NOW()
FROM requisitions r, canvass_requisitions cr
WHERE r.rs_number = 'TEST-FC-SCENARIO1' AND cr.requisition_id = r.id;" "Create Scenario 1 primary purchase order (for_delivery)"

# PO2: closed_po (as per requirements for multiple PO scenario)
execute_sql "
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id,
    supplier_type, status, total_amount, created_at, updated_at
)
SELECT 'FC-PO1B', 'B', r.id, cr.id, 2, 'supplier', 'closed_po',
       2500.00, NOW(), NOW()
FROM requisitions r, canvass_requisitions cr
WHERE r.rs_number = 'TEST-FC-SCENARIO1' AND cr.requisition_id = r.id;" "Create Scenario 1 secondary purchase order (closed_po)"

# Create PO items for primary PO (for_delivery) - partial quantities
execute_sql "
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id,
    quantity_purchased, canvass_item_supplier_id, created_at, updated_at
)
SELECT po.id, ci.id, ril.id,
       CASE WHEN ril.item_id = 7 THEN 100 ELSE 50 END, -- Full quantities for PO
       cis.id, NOW(), NOW()
FROM purchase_orders po, canvass_items ci, requisition_item_lists ril,
     canvass_item_suppliers cis, requisitions r
WHERE po.po_number = 'FC-PO1A'
  AND r.rs_number = 'TEST-FC-SCENARIO1'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id
  AND cis.canvass_item_id = ci.id
  AND cis.is_selected = true;" "Create Scenario 1 primary PO items"

# Create PO items for secondary PO (closed_po) - represents a previously completed PO
execute_sql "
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id,
    quantity_purchased, canvass_item_supplier_id, created_at, updated_at
)
SELECT
    po.id as purchase_order_id,
    ci.id as canvass_item_id,
    ril.id as requisition_item_list_id,
    CASE WHEN ril.item_id = 7 THEN 20.000 ELSE 15.000 END as quantity_purchased, -- smaller quantities for closed PO
    cis.id as canvass_item_supplier_id,
    NOW() as created_at,
    NOW() as updated_at
FROM purchase_orders po
JOIN requisitions r ON r.id = po.requisition_id
JOIN requisition_item_lists ril ON ril.requisition_id = r.id
JOIN canvass_items ci ON ci.requisition_item_list_id = ril.id
JOIN canvass_item_suppliers cis ON cis.canvass_item_id = ci.id
WHERE po.po_number = 'FC-PO1B'
  AND ril.item_id IN (7, 28)
  AND cis.is_selected = true;" "Create Scenario 1 secondary PO items"

# Create supplier if not exists
execute_sql "
INSERT INTO suppliers (user_id, name, contact_person, contact_number, tin, address, citizenship_code, nature_of_income, pay_code, ic_code, created_at, updated_at)
SELECT 150, 'Test Supplier Corp', 'John Supplier', '123-456-7890', '123456789012', '123 Supplier St', 'PH', 'BUSINESS', 'TS01', 'IC', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM suppliers WHERE name = 'Test Supplier Corp');" "Create test supplier"

# Create partial delivery receipt for primary PO (Item 7: 60/100, Item 28: 30/50)
execute_sql "
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, status, company_code, is_draft,
    latest_delivery_status, latest_delivery_date, supplier,
    created_at, updated_at
)
SELECT 'FC-DR1', r.id, po.id, 'Delivered', '12553', false,
       'Partially Delivered', NOW(), 'Test Supplier Corp', NOW(), NOW()
FROM purchase_orders po, requisitions r
WHERE po.po_number = 'FC-PO1A' AND r.rs_number = 'TEST-FC-SCENARIO1';" "Create Scenario 1 delivery receipt"

# Create delivery receipt items (partial delivery: Item 7: 60/100, Item 28: 30/50)
# Note: Pricing is calculated at payment request level, not in delivery receipt items
execute_sql "
INSERT INTO delivery_receipt_items (
    dr_id, po_id, po_item_id, item_id, item_des, qty_ordered, qty_delivered,
    unit, delivery_status, date_delivered, created_at, updated_at
)
SELECT
    dr.id as dr_id,
    po.id as po_id,
    poi.id as po_item_id,
    ril.item_id,
    CASE WHEN ril.item_id = 7 THEN 'Test Item 7' ELSE 'Test Item 28' END as item_des,
    poi.quantity_purchased as qty_ordered, -- qty_ordered from PO
    CASE WHEN ril.item_id = 7 THEN 60.000 ELSE 30.000 END as qty_delivered, -- qty_delivered (partial)
    'PCS' as unit,
    'Partially Delivered' as delivery_status,
    NOW() as date_delivered,
    NOW() as created_at,
    NOW() as updated_at
FROM delivery_receipts dr
JOIN purchase_orders po ON po.id = dr.po_id
JOIN purchase_order_items poi ON poi.purchase_order_id = po.id
JOIN requisition_item_lists ril ON ril.id = poi.requisition_item_list_id
JOIN requisitions r ON r.id = ril.requisition_id
WHERE dr.dr_number = 'FC-DR1'
  AND po.po_number = 'FC-PO1A'
  AND r.rs_number = 'TEST-FC-SCENARIO1';" "Create Scenario 1 delivery receipt items"

# Create invoice report for the delivery
execute_sql "
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, company_code,
    supplier_invoice_no, issued_invoice_date, invoice_amount, is_draft,
    status, created_by, created_at, updated_at
)
SELECT 'FC-IR1', r.id, po.id, '12553',
       'SUP-INV-001', NOW(), 4500.00, false,
       'approved', 150, NOW(), NOW()
FROM requisitions r, purchase_orders po
WHERE r.rs_number = 'TEST-FC-SCENARIO1' AND po.po_number = 'FC-PO1A';" "Create Scenario 1 invoice report"

# Create payment request (ALL PR STATUS: CLOSED as per requirements)
# Amount = unit_price_discounted * delivered quantity
# Item 7: 50.00 * 60 = 3000.00
# Item 28: 50.00 * 30 = 1500.00
# Total: 4500.00
execute_sql "
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, status, is_draft,
    total_amount, created_at, updated_at
)
SELECT 'FC-PR1', 'A', r.id, po.id, 'Closed', false, 4500.00, NOW(), NOW()
FROM requisitions r, purchase_orders po
WHERE r.rs_number = 'TEST-FC-SCENARIO1'
  AND po.po_number = 'FC-PO1A';" "Create Scenario 1 payment request (CLOSED) - calculated amount"

echo -e "${GREEN}✓ Scenario 1 setup completed successfully${NC}"
echo -e "${YELLOW}Expected Result: Button VISIBLE and ENABLED (Partial Delivery)${NC}"
echo -e "${YELLOW}Test with user: ronald (ID: 150)${NC}"
echo -e "${YELLOW}Multiple POs: PO1A (for_delivery), PO1B (closed_po)${NC}"
echo -e "${YELLOW}Delivery: Item 7: 60/100, Item 28: 30/50 (Partial)${NC}"
echo -e "${YELLOW}Payment: CLOSED (4500.00 = 50.00 * 60 + 50.00 * 30)${NC}"
echo -e "${YELLOW}Scenario: ACTIVE_PO_PARTIAL_DELIVERY${NC}"
