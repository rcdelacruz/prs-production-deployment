#!/bin/bash

# ============================================================================
# Force Close Scenario 2: Valid Force Close - Full Delivery with Remaining Canvass Qty (ELIGIBLE)
# ============================================================================
# Requirements: RS Status: rs_in_progress, PO Status: closed_PO
# RS Qty: Item 7 = 120, Item 28 = 75
# Canvassed Qty: Item 7 = 100, Item 28 = 50
# Remaining Canvass Qty: Item 7 = 20, Item 28 = 25
# Delivery: Full (Item 7: 100/100, Item 28: 50/50)
# Payment: All delivered quantities paid (PR STATUS: CLOSED)
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
DB_USER=${POSTGRES_USER:-prs_user}
DB_NAME=${POSTGRES_DB:-prs_production}
DB_PASSWORD=${POSTGRES_PASSWORD:-p*Ecp5YP2cvctg}

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Force Close Scenario 2: Valid Force Close - Full Delivery with Remaining Canvass Qty${NC}"
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
echo -e "${YELLOW}Cleaning up existing Scenario 2 test data...${NC}"
execute_sql "DELETE FROM rs_payment_requests WHERE pr_number = 'FC-PR2';" "Clean payment requests"
execute_sql "DELETE FROM invoice_reports WHERE ir_number = 'FC-IR2';" "Clean invoice reports"
execute_sql "DELETE FROM delivery_receipt_items WHERE dr_id IN (SELECT id FROM delivery_receipts WHERE dr_number = 'FC-DR2');" "Clean delivery receipt items"
execute_sql "DELETE FROM delivery_receipts WHERE dr_number = 'FC-DR2';" "Clean delivery receipts"
execute_sql "DELETE FROM suppliers WHERE name = 'Test Supplier Corp 2';" "Clean test supplier"
execute_sql "DELETE FROM purchase_order_items WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE po_number = 'FC-PO2');" "Clean PO items"
execute_sql "DELETE FROM purchase_orders WHERE po_number = 'FC-PO2';" "Clean purchase orders"
execute_sql "DELETE FROM canvass_item_suppliers WHERE canvass_item_id IN (SELECT id FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2')));" "Clean canvass item suppliers"
execute_sql "DELETE FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'));" "Clean canvass items"
execute_sql "DELETE FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2');" "Clean canvass requisitions"
execute_sql "DELETE FROM requisition_item_lists WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2');" "Clean requisition items"
execute_sql "DELETE FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2';" "Clean requisitions"

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

# Create requisition
execute_sql "
INSERT INTO requisitions (
    rs_number, rs_letter, purpose, status, created_by, assigned_to,
    company_code, company_id, department_id, date_required, delivery_address,
    charge_to, created_at, updated_at
) VALUES (
    'TEST-FC-SCENARIO2', 'A', 'Force Close Test - Remaining Canvass Qty',
    'rs_in_progress', 150, 150, '12553', 1, 1, NOW() + INTERVAL '30 days',
    'Test Delivery Address', 'Test Project', NOW(), NOW()
);" "Create Scenario 2 requisition"

# Create requisition items (Item 7: 120, Item 28: 75 as per requirements)
execute_sql "
INSERT INTO requisition_item_lists (
    requisition_id, item_id, quantity, item_type, notes,
    created_at, updated_at
)
SELECT r.id, 7, 120, 'ofm', 'Test Item 7 for Force Close Scenario 2', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO2'
UNION ALL
SELECT r.id, 28, 75, 'ofm', 'Test Item 28 for Force Close Scenario 2', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO2';" "Create Scenario 2 requisition items"

# Create canvass requisition
execute_sql "
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status, created_at, updated_at
)
SELECT r.id, 'FC-CS2', 'A', 'approved', NOW(), NOW()
FROM requisitions r WHERE r.rs_number = 'TEST-FC-SCENARIO2';" "Create Scenario 2 canvass requisition"

# Create canvass items (approved quantities: Item 7: 100/120, Item 28: 50/75)
execute_sql "
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, requisition_id, status,
    created_at, updated_at
)
SELECT cr.id, ril.id, r.id, 'approved', NOW(), NOW()
FROM canvass_requisitions cr, requisitions r, requisition_item_lists ril
WHERE r.rs_number = 'TEST-FC-SCENARIO2'
  AND cr.requisition_id = r.id
  AND ril.requisition_id = r.id;" "Create Scenario 2 canvass items"

# Create test supplier
execute_sql "
INSERT INTO suppliers (
    user_id, name, tin, address, citizenship_code, nature_of_income,
    pay_code, ic_code, status, created_at, updated_at
)
VALUES (
    150, 'Test Supplier Corp 2', '123456789012', 'Test Address 2',
    'PH', 'Business', 'TS02', 'IC', 'active', NOW(), NOW()
);" "Create test supplier"

# Create canvass item suppliers (approved quantities: Item 7: 100, Item 28: 50)
execute_sql "
INSERT INTO canvass_item_suppliers (
    canvass_item_id, supplier_id, supplier_type, term, quantity, \\\"order\\\",
    unit_price, is_selected, created_at, updated_at
)
SELECT ci.id, s.id, 'supplier', '30 days',
       CASE WHEN ril.item_id = 7 THEN 100 ELSE 50 END,
       1, 50.00, true, NOW(), NOW()
FROM canvass_items ci, requisition_item_lists ril, requisitions r, suppliers s
WHERE r.rs_number = 'TEST-FC-SCENARIO2'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id
  AND s.name = 'Test Supplier Corp 2';" "Create Scenario 2 canvass item suppliers"

# Create purchase order (Closed status)
execute_sql "
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id,
    supplier_type, status, total_amount, created_at, updated_at
)
SELECT 'FC-PO2', 'A', r.id, cr.id, s.id, 'supplier', 'closed_po',
       7500.00, NOW(), NOW()
FROM requisitions r, canvass_requisitions cr, suppliers s
WHERE r.rs_number = 'TEST-FC-SCENARIO2'
  AND cr.requisition_id = r.id
  AND s.name = 'Test Supplier Corp 2';" "Create Scenario 2 purchase order"

# Create PO items (Item 7: 100, Item 28: 50)
execute_sql "
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id,
    quantity_purchased, canvass_item_supplier_id, created_at, updated_at
)
SELECT po.id, ci.id, ril.id, cis.quantity, cis.id, NOW(), NOW()
FROM purchase_orders po, canvass_items ci, requisition_item_lists ril,
     canvass_item_suppliers cis, requisitions r
WHERE po.po_number = 'FC-PO2'
  AND r.rs_number = 'TEST-FC-SCENARIO2'
  AND ril.requisition_id = r.id
  AND ci.requisition_item_list_id = ril.id
  AND cis.canvass_item_id = ci.id
  AND cis.is_selected = true;" "Create Scenario 2 PO items"

# Create full delivery receipt (Item 7: 100/100, Item 28: 50/50)
execute_sql "
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, status, company_code, is_draft,
    created_at, updated_at
)
SELECT 'FC-DR2', r.id, po.id, 'Delivered', '12553', false, NOW(), NOW()
FROM purchase_orders po, requisitions r
WHERE po.po_number = 'FC-PO2' AND r.rs_number = 'TEST-FC-SCENARIO2';" "Create Scenario 2 delivery receipt"

# Create delivery receipt items (full delivery: Item 7: 100/100, Item 28: 50/50)
execute_sql "
INSERT INTO delivery_receipt_items (
    dr_id, po_id, po_item_id, item_id, item_des, qty_ordered, qty_delivered,
    unit, created_at, updated_at
)
SELECT dr.id, po.id, poi.id, ril.item_id,
       CASE WHEN ril.item_id = 7 THEN 'Test Item 7' ELSE 'Test Item 28' END,
       cis.quantity, cis.quantity,
       'PCS', NOW(), NOW()
FROM delivery_receipts dr, purchase_orders po, purchase_order_items poi,
     requisition_item_lists ril, canvass_item_suppliers cis, requisitions r
WHERE dr.dr_number = 'FC-DR2'
  AND po.po_number = 'FC-PO2'
  AND poi.purchase_order_id = po.id
  AND ril.id = poi.requisition_item_list_id
  AND cis.id = poi.canvass_item_supplier_id
  AND r.rs_number = 'TEST-FC-SCENARIO2'
  AND ril.requisition_id = r.id;" "Create Scenario 2 delivery receipt items"

# Update delivery receipt with latest_delivery_status (since items are fully delivered)
execute_sql "
UPDATE delivery_receipts
SET latest_delivery_status = 'Fully Delivered',
    latest_delivery_date = NOW()
WHERE dr_number = 'FC-DR2';" "Update Scenario 2 delivery receipt status"

# Create delivery receipt invoice (required for payment validation)
execute_sql "
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales,
    created_at, updated_at
)
SELECT dr.id, 'FC-INV2', NOW(), 7500.00, NOW(), NOW()
FROM delivery_receipts dr
WHERE dr.dr_number = 'FC-DR2';" "Create Scenario 2 delivery receipt invoice"

# Create invoice report for the delivery
execute_sql "
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, company_code,
    supplier_invoice_no, issued_invoice_date, invoice_amount, is_draft,
    status, created_by, created_at, updated_at
)
SELECT 'FC-IR2', r.id, po.id, '12553',
       'SUP-INV-002', NOW(), 7500.00, false,
       'approved', 150, NOW(), NOW()
FROM requisitions r, purchase_orders po
WHERE r.rs_number = 'TEST-FC-SCENARIO2' AND po.po_number = 'FC-PO2';" "Create Scenario 2 invoice report"

# Create payment request (ALL PR STATUS: CLOSED as per requirements)
# Amount = unit_price * delivered quantity
# Item 7: 50.00 * 100 = 5000.00
# Item 28: 50.00 * 50 = 2500.00
# Total: 7500.00
execute_sql "
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id,
    status, is_draft, total_amount, created_at, updated_at
)
SELECT 'FC-PR2', 'A', r.id, po.id, dri.id, 'Closed', false, 7500.00, NOW(), NOW()
FROM requisitions r, purchase_orders po, delivery_receipts dr, delivery_receipt_invoices dri
WHERE r.rs_number = 'TEST-FC-SCENARIO2'
  AND po.po_number = 'FC-PO2'
  AND dr.dr_number = 'FC-DR2'
  AND dri.delivery_receipt_id = dr.id;" "Create Scenario 2 payment request (CLOSED) - calculated amount"

# Link payment request to invoice report (required for frontend total calculation)
execute_sql "
UPDATE invoice_reports
SET payment_request_id = (
    SELECT pr.id
    FROM rs_payment_requests pr
    JOIN requisitions r ON pr.requisition_id = r.id
    WHERE r.rs_number = 'TEST-FC-SCENARIO2'
)
WHERE ir_number = 'FC-IR2';" "Link invoice report to payment request"

echo -e "${GREEN}✓ Scenario 2 setup completed successfully${NC}"
echo -e "${YELLOW}Expected Result: Button VISIBLE and ENABLED (Full Delivery with Remaining Canvass Qty)${NC}"
echo -e "${YELLOW}Test with user: ronald (ID: 150)${NC}"
echo -e "${YELLOW}RS Qty: Item 7: 120, Item 28: 75${NC}"
echo -e "${YELLOW}Canvassed Qty: Item 7: 100, Item 28: 50${NC}"
echo -e "${YELLOW}Remaining Canvass Qty: Item 7: 20, Item 28: 25${NC}"
echo -e "${YELLOW}PO Status: closed_po${NC}"
echo -e "${YELLOW}Delivery: Item 7: 100/100, Item 28: 50/50 (FULL)${NC}"
echo -e "${YELLOW}Payment: CLOSED (7500.00 = 50.00 * 100 + 50.00 * 50)${NC}"
echo -e "${YELLOW}Check: Total Closed PR Amount = Total DR Amount${NC}"
echo -e "${YELLOW}Scenario: CLOSED_PO_WITH_REMAINING_CANVASS_QTY${NC}"
