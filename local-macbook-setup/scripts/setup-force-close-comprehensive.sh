#!/bin/bash

# ============================================================================
# Comprehensive Force Close Test Data Setup Script
# ============================================================================
# This script creates complete PRS workflows for realistic force close testing.
# It sets up ALL 3 ELIGIBLE force close scenarios AND 6 NOT ELIGIBLE scenarios:
#
# ELIGIBLE SCENARIOS:
# 1. Active PO with Partial Deliveries (paid)
# 2. All POs Closed with Remaining Quantities
# 3. Closed POs with Pending Canvass Sheet Approvals
#
# NOT ELIGIBLE SCENARIOS:
# 4. Unauthorized User (Error1 - Access Denied)
# 5. RS Status Before "In Progress" (Error2 - Still eligible for RS Cancellation)
# 6. PO Status Before "For Delivery" (Error3 - User must wait for PO to progress)
# 7. No Deliveries Yet (Error3 - User should manually cancel PO first)
# 8. Unpaid Deliveries (Error4 - User should pay delivered quantities first)
# 9. Auto-Close Detection (Should auto-close instead of force close)
#
# UPDATED: Includes all database fixes for proper force close functionality:
# - Delivery receipt status set to 'Delivered'
# - Delivery receipt invoices created and linked to payment requests
# - Invoice reports created linking delivery receipts to payment requests
# - Proper po_item_id linking for delivery receipt items
# - Payment requests properly linked to delivery invoices and invoice reports
# - Comprehensive validation scenarios for all force close requirements
#
# Usage:
#   ./scripts/setup-force-close-comprehensive.sh
#
# Prerequisites:
#   - Docker containers must be running (prs-local-postgres)
#   - Database must be accessible
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Comprehensive Force Close Test Data Setup${NC}"
echo -e "${BLUE}============================================================================${NC}"

# Check if we're in the right directory
if [[ ! -f "$PROJECT_DIR/docker-compose.yml" ]]; then
    echo -e "${RED}Error: This script must be run from the local-macbook-setup directory${NC}"
    echo -e "${RED}Current directory: $(pwd)${NC}"
    echo -e "${RED}Expected directory: .../prs-production-deployment/local-macbook-setup${NC}"
    exit 1
fi

# Check if Docker containers are running
echo -e "${YELLOW}Checking if Docker containers are running...${NC}"
if ! docker ps | grep -q "prs-local-postgres"; then
    echo -e "${RED}Error: prs-local-postgres container is not running${NC}"
    echo -e "${YELLOW}Please start the containers first:${NC}"
    echo -e "${YELLOW}  ./deploy-local.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker containers are running${NC}"

# Load environment variables for database credentials
if [[ -f "$PROJECT_DIR/.env" ]]; then
    source "$PROJECT_DIR/.env"
fi

# Set default values if not found in .env
DB_USER=${DB_USER:-prs_user}
DB_NAME=${DB_NAME:-prs_local}
DB_PASSWORD=${DB_PASSWORD:-localdev123}

# Check if database is accessible
echo -e "${YELLOW}Testing database connection...${NC}"
if ! docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -c 'SELECT 1;'" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to database${NC}"
    echo -e "${YELLOW}Please ensure the database is running and accessible${NC}"
    echo -e "${YELLOW}Database credentials: User=$DB_USER, Database=$DB_NAME${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Database connection successful${NC}"

# Function to validate force close results
validate_force_close_results() {
    local rs_number="$1"
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${GREEN}Validating Force Close Results for $rs_number${NC}"
    echo -e "${BLUE}============================================================================${NC}"

    # 1. Check RS Status
    echo -e "${YELLOW}1. Checking RS Status...${NC}"
    RS_STATUS=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT status FROM requisitions WHERE rs_number = '$rs_number';\"" | tr -d ' ')
    if [ "$RS_STATUS" = "rs_closed" ]; then
        echo -e "${GREEN}   ✓ RS Status: $RS_STATUS (CORRECT)${NC}"
    else
        echo -e "${RED}   ✗ RS Status: $RS_STATUS (EXPECTED: rs_closed)${NC}"
    fi

    # 2. Check Force Close Reason in Notes
    echo -e "${YELLOW}2. Checking Force Close Reason in RS Notes...${NC}"
    RS_NOTES=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COALESCE(force_close_reason, 'NULL') FROM requisitions WHERE rs_number = '$rs_number';\"" | tr -d ' ')
    if [[ "$RS_NOTES" == *"Force Close"* ]] || [[ "$RS_NOTES" == *"force close"* ]]; then
        echo -e "${GREEN}   ✓ Force Close Reason found in force_close_reason field${NC}"
    else
        echo -e "${RED}   ✗ Force Close Reason NOT found in force_close_reason field${NC}"
    fi

    # 3. Check Draft and Pending Documents
    echo -e "${YELLOW}3. Checking Draft and Pending Documents...${NC}"

    # Check Canvass Sheets
    PENDING_CS=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM canvass_requisitions WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$rs_number') AND status IN ('draft', 'for_approval');\"" | tr -d ' ')
    if [ "$PENDING_CS" -eq 0 ]; then
        echo -e "${GREEN}   ✓ No pending canvass sheets${NC}"
    else
        echo -e "${RED}   ✗ Found $PENDING_CS pending canvass sheets${NC}"
    fi

    # Check Invoice Reports
    PENDING_IR=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM invoice_reports WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$rs_number') AND status IN ('draft', 'pending');\"" | tr -d ' ')
    if [ "$PENDING_IR" -eq 0 ]; then
        echo -e "${GREEN}   ✓ No pending invoice reports${NC}"
    else
        echo -e "${RED}   ✗ Found $PENDING_IR pending invoice reports${NC}"
    fi

    # 4. Check PO Updates
    echo -e "${YELLOW}4. Checking PO Updates...${NC}"

    # Check if PO system_generated_notes contain force close information
    PO_NOTES=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COALESCE(system_generated_notes, 'NULL') FROM purchase_orders WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$rs_number') LIMIT 1;\"")
    if [[ "$PO_NOTES" == *"Force Close"* ]] || [[ "$PO_NOTES" == *"force close"* ]]; then
        echo -e "${GREEN}   ✓ PO system_generated_notes updated with force close information${NC}"
    else
        echo -e "${YELLOW}   ! PO system_generated_notes may need force close information${NC}"
    fi

    # 5. Check OFM Quantity Return
    echo -e "${YELLOW}5. Checking OFM Quantity Return to GFQ...${NC}"

    OFM_ITEMS=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$rs_number') AND item_type = 'ofm';\"" | tr -d ' ')
    if [ "$OFM_ITEMS" -gt 0 ]; then
        echo -e "${GREEN}   ✓ Found $OFM_ITEMS OFM items to check${NC}"
        echo -e "${YELLOW}   → Manual verification required for GFQ quantity return${NC}"
    else
        echo -e "${YELLOW}   ! No OFM items found in this requisition${NC}"
    fi

    echo -e "${BLUE}============================================================================${NC}"
}

# Run the comprehensive SQL script
echo -e "${YELLOW}Setting up comprehensive force close test data...${NC}"
echo -e "${YELLOW}This will create complete PRS workflows for realistic testing...${NC}"

# Validate required data exists before proceeding
echo -e "${YELLOW}Validating required data...${NC}"

# Check if required items exist
ITEM_COUNT=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM items WHERE id IN (7, 28);\"" | tr -d ' ')
if [ "$ITEM_COUNT" -lt 2 ]; then
    echo -e "${RED}✗ Error: Required items (id: 7, 28) not found in database${NC}"
    echo -e "${YELLOW}Please ensure the database has been properly initialized with test data${NC}"
    exit 1
fi

# Check if suppliers exist
SUPPLIER_COUNT=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM suppliers;\"" | tr -d ' ')
if [ "$SUPPLIER_COUNT" -lt 1 ]; then
    echo -e "${RED}✗ Error: No suppliers found in database${NC}"
    echo -e "${YELLOW}Please ensure the database has been properly initialized with test data${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Validation completed successfully${NC}"

# Copy the comprehensive SQL script to the container and run it with password
docker exec -i prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME" << 'EOF'
-- ============================================================================
-- Comprehensive Force Close Test Data Setup
-- ============================================================================
-- This script creates complete PRS workflows to test ALL force close scenarios:
-- ELIGIBLE SCENARIOS:
-- 1. SCENARIO 1: Active PO with Partial Deliveries (paid) - ELIGIBLE
-- 2. SCENARIO 2: All POs Closed with Remaining Quantities - ELIGIBLE
-- 3. SCENARIO 3: Closed POs with Pending Canvass Sheet Approvals - ELIGIBLE
-- NOT ELIGIBLE SCENARIOS:
-- 4. SCENARIO 4: Unauthorized User (Error1 - Access Denied) - NOT ELIGIBLE
-- 5. SCENARIO 5: RS Status Before "In Progress" (Error2) - NOT ELIGIBLE
-- 6. SCENARIO 6: PO Status Before "For Delivery" (Error3) - NOT ELIGIBLE
-- 7. SCENARIO 7: No Deliveries Yet (Error3) - NOT ELIGIBLE
-- 8. SCENARIO 8: Unpaid Deliveries (Error4) - NOT ELIGIBLE
-- 9. SCENARIO 9: Auto-Close Detection - NOT ELIGIBLE
-- ============================================================================

-- Clean up any existing test data first (in proper order to avoid foreign key issues)
-- First, clean up force_close_logs that reference requisitions
DELETE FROM force_close_logs WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);

-- Clean up canvass_item_suppliers first (they reference canvass_items)
DELETE FROM canvass_item_suppliers WHERE canvass_item_id IN (
    SELECT id FROM canvass_items WHERE canvass_requisition_id IN (
        SELECT id FROM canvass_requisitions WHERE requisition_id IN (
            SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
        )
    )
);

DELETE FROM rs_payment_requests WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM invoice_reports WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM delivery_receipt_invoices WHERE delivery_receipt_id IN (
    SELECT id FROM delivery_receipts WHERE requisition_id IN (
        SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
    )
);
DELETE FROM delivery_receipt_items WHERE dr_id IN (
    SELECT id FROM delivery_receipts WHERE requisition_id IN (
        SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
    )
);
DELETE FROM delivery_receipts WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM purchase_order_items WHERE purchase_order_id IN (
    SELECT id FROM purchase_orders WHERE requisition_id IN (
        SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
    )
);
DELETE FROM purchase_orders WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM canvass_items WHERE canvass_requisition_id IN (
    SELECT id FROM canvass_requisitions WHERE requisition_id IN (
        SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
    )
);
DELETE FROM canvass_requisitions WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM requisition_approvers WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM requisition_item_lists WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM requisitions WHERE rs_number LIKE 'TEST-FC-%';

-- Clean up projects last, but check if they exist first
DELETE FROM projects WHERE code = 'TEST-PROJ-FC';

-- Create test project for force close testing (only if it doesn't exist)
INSERT INTO projects (code, name, initial, address, company_code, created_at, updated_at)
SELECT 'TEST-PROJ-FC', 'Test Project for Force Close Testing', 'TPFC', 'Test Project Address', '12553', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM projects WHERE code = 'TEST-PROJ-FC');

-- ============================================================================
-- SCENARIO 1: Active PO with Partial Deliveries (ELIGIBLE FOR FORCE CLOSE)
-- ============================================================================
-- This creates: RS → Canvass → PO (FOR_DELIVERY) → Partial Delivery → Payment
-- Conditions: PO status FOR_DELIVERY + partial deliveries + paid
-- Result: Force close button should be ENABLED

-- Create requisition for Scenario 1
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO1', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 1: Active PO with Partial Deliveries', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 1 requisition (mix of OFM and Non-OFM for comprehensive testing)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1), 7, 'non_ofm', 100, 'Item 1 - partial delivery scenario (Non-OFM)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1), 28, 'ofm', 50, 'Item 2 - partial delivery scenario (OFM - should return to GFQ)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 1
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 1
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1), 'FC-CS-01', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 1
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 7 LIMIT 1),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 28 LIMIT 1),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 1 (FOR_DELIVERY status)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-001', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'for_delivery',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 1 (required for PO items)
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 100, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 1 (THIS IS CRITICAL FOR FORCE CLOSE ELIGIBILITY)
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 7 LIMIT 1),
 100,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 7 LIMIT 1))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 28 LIMIT 1),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 28 LIMIT 1))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 1 (PARTIAL delivery - only 60% delivered)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-001',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 1 (partial quantities with proper po_item_id linking)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT itm_des FROM items WHERE id = 7 LIMIT 1), 100, 60, (SELECT unit FROM items WHERE id = 7 LIMIT 1), NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT itm_des FROM items WHERE id = 28 LIMIT 1), 50, 30, (SELECT unit FROM items WHERE id = 28 LIMIT 1), NOW(), NOW());

-- Update delivery receipt to calculate latest_delivery_status for Scenario 1
UPDATE delivery_receipts SET latest_delivery_status = (
    SELECT CASE
        WHEN COUNT(*) = COUNT(CASE WHEN qty_delivered = qty_ordered THEN 1 END) THEN 'Fully Delivered'
        WHEN COUNT(CASE WHEN qty_delivered > 0 THEN 1 END) > 0 THEN 'Partially Delivered'
        ELSE NULL
    END
    FROM delivery_receipt_items
    WHERE dr_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001' LIMIT 1)
) WHERE dr_number = 'TEST-DR-001';

-- Create delivery receipt invoice for Scenario 1 (required for payment linking)
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001' LIMIT 1),
 'INV-TEST-FC-001', NOW(), 15000.00, 1800.00,
 NOW(), NOW());

-- Create payment request for Scenario 1 (for delivered quantities only - PAID)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-01', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001' LIMIT 1) LIMIT 1),
 'Closed', false,
 NOW(), NOW());

-- Create invoice report for Scenario 1 (linking purchase order to payment request)
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, payment_request_id, status, is_draft,
    company_code, created_by, supplier_invoice_no, issued_invoice_date, invoice_amount,
    created_at, updated_at
) VALUES
('FC-IR-01',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 (SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-01' LIMIT 1),
 'Closed', false,
 '12553', 150, 'INV-TEST-FC-001', NOW(), 15000.00,
 NOW(), NOW());

-- ============================================================================
-- SCENARIO 2: All POs Closed with Remaining Quantities (ELIGIBLE FOR FORCE CLOSE)
-- ============================================================================
-- This creates: RS → Canvass → PO (CLOSED) → Full Delivery → Payment + Remaining Qty
-- Conditions: All POs CLOSED + remaining quantities for canvassing
-- Result: Force close button should be ENABLED

-- Create requisition for Scenario 2
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO2', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 2: Closed POs with Remaining Quantities', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 2 requisition (more items than will be canvassed - mix of OFM and Non-OFM)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1), 7, 'ofm', 100, 'Item 1 - only 70 will be canvassed (OFM - remaining 30 should return to GFQ)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1), 28, 'non_ofm', 80, 'Item 2 - only 50 will be canvassed (Non-OFM)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 2
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 2 (partial canvassing)
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1), 'FC-CS-02', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 2 (only partial quantities)
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 7 LIMIT 1),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 28 LIMIT 1),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 2 (CLOSED_PO status - correct backend constant)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-002', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'closed_po',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 2
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 70, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 2 (partial quantities from requisition)
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 7 LIMIT 1),
 70,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 7 LIMIT 1))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 28 LIMIT 1),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 28 LIMIT 1))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 2 (FULL delivery of PO quantities)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-002',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 2 (full delivery of PO quantities with proper po_item_id linking)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT itm_des FROM items WHERE id = 7 LIMIT 1), 70, 70, (SELECT unit FROM items WHERE id = 7 LIMIT 1), NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT itm_des FROM items WHERE id = 28 LIMIT 1), 50, 50, (SELECT unit FROM items WHERE id = 28 LIMIT 1), NOW(), NOW());

-- Update delivery receipt to calculate latest_delivery_status for Scenario 2
UPDATE delivery_receipts SET latest_delivery_status = (
    SELECT CASE
        WHEN COUNT(*) = COUNT(CASE WHEN qty_delivered = qty_ordered THEN 1 END) THEN 'Fully Delivered'
        WHEN COUNT(CASE WHEN qty_delivered > 0 THEN 1 END) > 0 THEN 'Partially Delivered'
        ELSE NULL
    END
    FROM delivery_receipt_items
    WHERE dr_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002' LIMIT 1)
) WHERE dr_number = 'TEST-DR-002';

-- Create delivery receipt invoice for Scenario 2 (required for payment linking)
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002' LIMIT 1),
 'INV-TEST-FC-002', NOW(), 18000.00, 2160.00,
 NOW(), NOW());

-- Create payment request for Scenario 2 (PAID)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-02', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002' LIMIT 1) LIMIT 1),
 'Closed', false,
 NOW(), NOW());

-- Create invoice report for Scenario 2 (linking purchase order to payment request)
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, payment_request_id, status, is_draft,
    company_code, created_by, supplier_invoice_no, issued_invoice_date, invoice_amount,
    created_at, updated_at
) VALUES
('FC-IR-02',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1),
 (SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-02' LIMIT 1),
 'Closed', false,
 '12553', 150, 'INV-TEST-FC-002', NOW(), 18000.00,
 NOW(), NOW());

-- ============================================================================
-- SCENARIO 3: Closed POs with Pending Canvass Sheet Approvals (ELIGIBLE FOR FORCE CLOSE)
-- ============================================================================
-- This creates: RS → Canvass1 (approved) → PO (CLOSED) + Canvass2 (pending approval)
-- Conditions: All POs CLOSED + pending CS approvals exist
-- Result: Force close button should be ENABLED

-- Create requisition for Scenario 3
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO3', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 3: Closed POs with Pending CS Approvals', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 3 requisition (mix of OFM and Non-OFM for comprehensive testing)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1), 7, 'ofm', 100, 'Item 1 - split between 2 canvass sheets (OFM - pending qty should return to GFQ)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1), 28, 'non_ofm', 60, 'Item 2 - split between 2 canvass sheets (Non-OFM)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 3
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create FIRST canvass sheet for Scenario 3 (APPROVED and processed to PO)
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1), 'FC-CS-3A', 'A', 'approved', NOW(), NOW());

-- Create SECOND canvass sheet for Scenario 3 (PENDING APPROVAL)
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1), 'FC-CS-3B', 'B', 'for_approval', NOW(), NOW());

-- Add canvass items for FIRST canvass sheet (approved)
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1),
 'approved', NOW(), NOW());

-- Add canvass items for SECOND canvass sheet (pending approval)
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3B' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1),
 'for_approval', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3B' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1),
 'for_approval', NOW(), NOW());

-- Create canvass item suppliers for SECOND canvass sheet (pending approval - remaining quantities)
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3B' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 30, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3B' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 20, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Create purchase order for Scenario 3 (CLOSED_PO status - correct backend constant)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-003', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'closed_po',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 3
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 70, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 40, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 3 (from first canvass only)
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1),
 70,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1),
 40,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 3 (FULL delivery)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-003',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 3 (full delivery with proper po_item_id linking)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1)),
 (SELECT itm_des FROM items WHERE id = 7 LIMIT 1), 70, 70, (SELECT unit FROM items WHERE id = 7 LIMIT 1), NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1)),
 (SELECT itm_des FROM items WHERE id = 28 LIMIT 1), 40, 40, (SELECT unit FROM items WHERE id = 28 LIMIT 1), NOW(), NOW());

-- Update delivery receipt to calculate latest_delivery_status for Scenario 3
UPDATE delivery_receipts SET latest_delivery_status = (
    SELECT CASE
        WHEN COUNT(*) = COUNT(CASE WHEN qty_delivered = qty_ordered THEN 1 END) THEN 'Fully Delivered'
        WHEN COUNT(CASE WHEN qty_delivered > 0 THEN 1 END) > 0 THEN 'Partially Delivered'
        ELSE NULL
    END
    FROM delivery_receipt_items
    WHERE dr_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003' LIMIT 1)
) WHERE dr_number = 'TEST-DR-003';

-- Create delivery receipt invoice for Scenario 3 (required for payment linking)
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003' LIMIT 1),
 'INV-TEST-FC-003', NOW(), 16000.00, 1920.00,
 NOW(), NOW());

-- Create payment request for Scenario 3 (PAID)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-03', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003' LIMIT 1) LIMIT 1),
 'Closed', false,
 NOW(), NOW());

-- Create invoice report for Scenario 3 (linking purchase order to payment request)
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, payment_request_id, status, is_draft,
    company_code, created_by, supplier_invoice_no, issued_invoice_date, invoice_amount,
    created_at, updated_at
) VALUES
('FC-IR-03',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1),
 (SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-03' LIMIT 1),
 'Closed', false,
 '12553', 150, 'INV-TEST-FC-003', NOW(), 16000.00,
 NOW(), NOW());

-- ============================================================================
-- SCENARIO 4: Unauthorized User (NOT ELIGIBLE FOR FORCE CLOSE - Error1)
-- ============================================================================
-- This creates: RS → Canvass → PO (FOR_DELIVERY) → Partial Delivery → Payment
-- BUT created by different user (user 150) and assigned to different user (user 144)
-- Current user trying to force close: user 151 (unauthorized)
-- Conditions: User not requester AND not assigned staff
-- Result: Force close button should be HIDDEN (Access Denied)

-- Create requisition for Scenario 4 (created by user 151, assigned to user 144)
-- Current user (ronald, user 150) should be unauthorized
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO4', 'A', '12553', 151, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 4: Unauthorized User Access', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 4 requisition (mix of OFM and Non-OFM for comprehensive testing)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1), 7, 'ofm', 100, 'Item 1 - unauthorized access test (OFM)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1), 28, 'non_ofm', 50, 'Item 2 - unauthorized access test (Non-OFM)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 4
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1), 151, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 4
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1), 'FC-CS-04', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 4
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 7),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 28),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 4 (FOR_DELIVERY status)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-004', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'for_delivery',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 4
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 100, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 4
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 7),
 100,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 7))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 28),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 28))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 4 (partial delivery)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-004',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 4 (partial quantities)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-004' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 7)),
 (SELECT itm_des FROM items WHERE id = 7 LIMIT 1), 100, 60, (SELECT unit FROM items WHERE id = 7 LIMIT 1), NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-004' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1) AND item_id = 28)),
 (SELECT itm_des FROM items WHERE id = 28 LIMIT 1), 50, 30, (SELECT unit FROM items WHERE id = 28 LIMIT 1), NOW(), NOW());

-- Update delivery receipt to calculate latest_delivery_status for Scenario 4
UPDATE delivery_receipts SET latest_delivery_status = (
    SELECT CASE
        WHEN COUNT(*) = COUNT(CASE WHEN qty_delivered = qty_ordered THEN 1 END) THEN 'Fully Delivered'
        WHEN COUNT(CASE WHEN qty_delivered > 0 THEN 1 END) > 0 THEN 'Partially Delivered'
        ELSE NULL
    END
    FROM delivery_receipt_items
    WHERE dr_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-004' LIMIT 1)
) WHERE dr_number = 'TEST-DR-004';

-- Create delivery receipt invoice for Scenario 4
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-004' LIMIT 1),
 'INV-TEST-FC-004', NOW(), 15000.00, 1800.00,
 NOW(), NOW());

-- Create payment request for Scenario 4 (PAID)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-04', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-004' LIMIT 1)),
 'Closed', false,
 NOW(), NOW());

-- Create invoice report for Scenario 4 (linking purchase order to payment request)
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, payment_request_id, status, is_draft,
    company_code, created_by, supplier_invoice_no, issued_invoice_date, invoice_amount,
    created_at, updated_at
) VALUES
('FC-IR-04',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1),
 (SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-04' LIMIT 1),
 'Closed', false,
 '12553', 151, 'INV-TEST-FC-004', NOW(), 15000.00,
 NOW(), NOW());

-- ============================================================================
-- SCENARIO 5: RS Status Before "In Progress" (NOT ELIGIBLE FOR FORCE CLOSE - Error2)
-- ============================================================================
-- This creates: RS with status "for_approval" (before rs_in_progress)
-- Conditions: RS status is before "Fully Approved - RS in Progress"
-- Result: Force close button should be HIDDEN (Still eligible for RS Cancellation)

-- Create requisition for Scenario 5 (status: for_approval)
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO5', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 5: RS Status Before In Progress', 'Test Project',
 'for_rs_approval', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 5 requisition (mix of OFM and Non-OFM for comprehensive testing)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5' LIMIT 1), 7, 'ofm', 100, 'Item 1 - RS not yet in progress (OFM)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5' LIMIT 1), 28, 'non_ofm', 50, 'Item 2 - RS not yet in progress (Non-OFM)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 5 (not yet approved)
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5' LIMIT 1), 144, 1, false, 'requisition', 'pending', NOW(), NOW());

-- ============================================================================
-- SCENARIO 6: PO Status Before "For Delivery" (NOT ELIGIBLE FOR FORCE CLOSE - Error3)
-- ============================================================================
-- This creates: RS → Canvass → PO (for_po_approval - before for_delivery)
-- Conditions: PO status is before "For Delivery" (For PO Review, For PO Approval, For Sending)
-- Result: Force close button should be HIDDEN (User must wait for PO to progress)

-- Create requisition for Scenario 6
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO6', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 6: PO Status Before For Delivery', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 6 requisition (mix of OFM and Non-OFM for comprehensive testing)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1), 7, 'ofm', 100, 'Item 1 - PO not yet for delivery (OFM)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1), 28, 'non_ofm', 50, 'Item 2 - PO not yet for delivery (Non-OFM)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 6
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 6
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1), 'FC-CS-06', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 6
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 7),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 28),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 6 (for_po_approval status - BEFORE for_delivery)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-006', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'for_po_approval',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 6
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 100, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 6
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-006' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 7),
 100,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 7))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-006' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 28),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1) AND item_id = 28))),
 NOW(), NOW());

-- ============================================================================
-- SCENARIO 7: No Deliveries Yet (NOT ELIGIBLE FOR FORCE CLOSE - Error3)
-- ============================================================================
-- This creates: RS → Canvass → PO (FOR_DELIVERY) but NO delivery receipts
-- Conditions: PO status is "for_delivery" but no deliveries have been made yet
-- Result: Force close button should be HIDDEN (User should manually cancel PO first)

-- Create requisition for Scenario 7
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO7', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 7: No Deliveries Yet', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 7 requisition (mix of OFM and Non-OFM for comprehensive testing)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1), 7, 'ofm', 100, 'Item 1 - no deliveries yet (OFM)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1), 28, 'non_ofm', 50, 'Item 2 - no deliveries yet (Non-OFM)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 7
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 7
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1), 'FC-CS-07', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 7
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 7),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 28),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 7 (FOR_DELIVERY status but NO deliveries)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-007', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'for_delivery',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 7
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 100, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 7
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-007' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 7),
 100,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 7))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-007' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 28),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1) AND item_id = 28))),
 NOW(), NOW());

-- NOTE: NO delivery receipts created for Scenario 7 - this is the key difference

-- ============================================================================
-- SCENARIO 8: Unpaid Deliveries (NOT ELIGIBLE FOR FORCE CLOSE - Error4)
-- ============================================================================
-- This creates: RS → Canvass → PO (FOR_DELIVERY) → Partial Delivery → NO Payment
-- Conditions: PO status is "for_delivery", partial deliveries exist, but NOT paid
-- Result: Force close button should be HIDDEN (User should pay delivered quantities first)

-- Create requisition for Scenario 8
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO8', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 8: Unpaid Deliveries', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 8 requisition (mix of OFM and Non-OFM for comprehensive testing)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1), 7, 'ofm', 100, 'Item 1 - unpaid deliveries (OFM)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1), 28, 'non_ofm', 50, 'Item 2 - unpaid deliveries (Non-OFM)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 8
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 8
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1), 'FC-CS-08', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 8
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 7),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 28),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 8 (FOR_DELIVERY status)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-008', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'for_delivery',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 8
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 100, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 8
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 7),
 100,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 7))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 28),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 28))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 8 (partial delivery)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-008',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 8 (partial quantities)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-008' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 7)),
 (SELECT itm_des FROM items WHERE id = 7 LIMIT 1), 100, 60, (SELECT unit FROM items WHERE id = 7 LIMIT 1), NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-008' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1) AND item_id = 28)),
 (SELECT itm_des FROM items WHERE id = 28 LIMIT 1), 50, 30, (SELECT unit FROM items WHERE id = 28 LIMIT 1), NOW(), NOW());

-- Update delivery receipt to calculate latest_delivery_status for Scenario 8
UPDATE delivery_receipts SET latest_delivery_status = (
    SELECT CASE
        WHEN COUNT(*) = COUNT(CASE WHEN qty_delivered = qty_ordered THEN 1 END) THEN 'Fully Delivered'
        WHEN COUNT(CASE WHEN qty_delivered > 0 THEN 1 END) > 0 THEN 'Partially Delivered'
        ELSE NULL
    END
    FROM delivery_receipt_items
    WHERE dr_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-008' LIMIT 1)
) WHERE dr_number = 'TEST-DR-008';

-- Create delivery receipt invoice for Scenario 8
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-008' LIMIT 1),
 'INV-TEST-FC-008', NOW(), 15000.00, 1800.00,
 NOW(), NOW());

-- Create payment request for Scenario 8 (NOT PAID - correct backend constant)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-08', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-008' LIMIT 1)),
 'For PR Approval', false,
 NOW(), NOW());

-- Create invoice report for Scenario 8 (linking purchase order to payment request - but payment not yet approved)
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, payment_request_id, status, is_draft,
    company_code, created_by, supplier_invoice_no, issued_invoice_date, invoice_amount,
    created_at, updated_at
) VALUES
('FC-IR-08',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1),
 (SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-08' LIMIT 1),
 'Invoice Received', false,
 '12553', 150, 'INV-TEST-FC-008', NOW(), 15000.00,
 NOW(), NOW());

-- ============================================================================
-- SCENARIO 9: Auto-Close Detection (NOT ELIGIBLE FOR FORCE CLOSE - Should Auto-Close)
-- ============================================================================
-- This creates: RS → Canvass → PO (CLOSED) → Full Delivery → Payment
-- BUT all conditions met for auto-close: All POs closed, no remaining qty, no pending CS
-- Conditions: All POs CLOSED + no remaining quantities + no pending CS approvals
-- Result: Force close button should be HIDDEN (Requisition should auto-close instead)

-- Create requisition for Scenario 9
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO9', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1),
 '2024-12-31', 'Test Delivery Address', 'Scenario 9: Auto-Close Detection', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 9 requisition (mix of OFM and Non-OFM for comprehensive testing)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1), 7, 'ofm', 100, 'Item 1 - auto-close scenario (OFM)', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1), 28, 'non_ofm', 50, 'Item 2 - auto-close scenario (Non-OFM)', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 9
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 9 (covers ALL requisition quantities)
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1), 'FC-CS-09', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 9 (covers ALL quantities)
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 7),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 28),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 9 (CLOSED_PO status - correct backend constant)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-009', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'closed_po',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 9 (covers ALL quantities)
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 100, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 9 (covers ALL quantities)
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 7)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 7),
 100,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 7))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 28)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 28),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 28))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 9 (FULL delivery of ALL quantities)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-009',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 9 (FULL delivery)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-009' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 7)),
 (SELECT itm_des FROM items WHERE id = 7 LIMIT 1), 100, 100, (SELECT unit FROM items WHERE id = 7 LIMIT 1), NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-009' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1) AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1) AND item_id = 28)),
 (SELECT itm_des FROM items WHERE id = 28 LIMIT 1), 50, 50, (SELECT unit FROM items WHERE id = 28 LIMIT 1), NOW(), NOW());

-- Update delivery receipt to calculate latest_delivery_status for Scenario 9
UPDATE delivery_receipts SET latest_delivery_status = (
    SELECT CASE
        WHEN COUNT(*) = COUNT(CASE WHEN qty_delivered = qty_ordered THEN 1 END) THEN 'Fully Delivered'
        WHEN COUNT(CASE WHEN qty_delivered > 0 THEN 1 END) > 0 THEN 'Partially Delivered'
        ELSE NULL
    END
    FROM delivery_receipt_items
    WHERE dr_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-009' LIMIT 1)
) WHERE dr_number = 'TEST-DR-009';

-- Create delivery receipt invoice for Scenario 9
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-009' LIMIT 1),
 'INV-TEST-FC-009', NOW(), 17500.00, 2100.00,
 NOW(), NOW());

-- Create payment request for Scenario 9 (PAID)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-09', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-009' LIMIT 1)),
 'Closed', false,
 NOW(), NOW());

-- Create invoice report for Scenario 9 (linking purchase order to payment request)
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, payment_request_id, status, is_draft,
    company_code, created_by, supplier_invoice_no, issued_invoice_date, invoice_amount,
    created_at, updated_at
) VALUES
('FC-IR-09',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1),
 (SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-09' LIMIT 1),
 'Closed', false,
 '12553', 150, 'INV-TEST-FC-009', NOW(), 17500.00,
 NOW(), NOW());

-- NOTE: No remaining quantities, no pending CS approvals - should trigger auto-close detection

-- ============================================================================
-- UPDATE PURCHASE ORDERS: Add missing supplier names and total amounts
-- ============================================================================
-- This prevents "---" from displaying in the frontend

-- Update all test purchase orders with supplier name and calculated total amounts
UPDATE purchase_orders SET
    supplier_name = (SELECT name FROM suppliers WHERE id = purchase_orders.supplier_id),
    total_amount = (
        SELECT COALESCE(SUM(poi.quantity_purchased * cis.unit_price), 0)
        FROM purchase_order_items poi
        JOIN canvass_item_suppliers cis ON poi.canvass_item_supplier_id = cis.id
        WHERE poi.purchase_order_id = purchase_orders.id
    )
WHERE po_number LIKE 'TEST-PO-%';

-- Update delivery receipts to ensure supplier names are populated (prevent "---" display)
UPDATE delivery_receipts SET
    supplier = COALESCE(supplier, 'Test Supplier')
WHERE dr_number LIKE 'TEST-DR-%' AND (supplier IS NULL OR supplier = '');

-- Update requisitions to ensure all text fields are populated (prevent "---" display)
UPDATE requisitions SET
    purpose = COALESCE(purpose, 'Force Close Testing Purpose'),
    delivery_address = COALESCE(delivery_address, 'Test Delivery Address')
WHERE rs_number LIKE 'TEST-FC-%' AND (purpose IS NULL OR purpose = '' OR delivery_address IS NULL OR delivery_address = '');

-- Update canvass item suppliers to have proper supplier names (prevent frontend crashes)
UPDATE canvass_item_suppliers
SET supplier_name = (SELECT name FROM suppliers WHERE id = canvass_item_suppliers.supplier_id)
WHERE supplier_name IS NULL OR supplier_name = '';

-- Update payment requests to have proper total amounts (prevent frontend crashes)
UPDATE rs_payment_requests
SET total_amount = (
    SELECT COALESCE(SUM(dri.qty_delivered * cis.unit_price), 0)
    FROM delivery_receipt_items dri
    JOIN purchase_order_items poi ON dri.po_item_id = poi.id
    JOIN canvass_item_suppliers cis ON poi.canvass_item_supplier_id = cis.id
    JOIN purchase_orders po ON poi.purchase_order_id = po.id
    WHERE po.requisition_id = rs_payment_requests.requisition_id
)
WHERE pr_number LIKE 'FC-PR-%' AND (total_amount IS NULL OR total_amount = 0);

-- ============================================================================
-- ADDITIONAL SCENARIO: Draft Invoice Reports for Force Close Cancellation Testing
-- ============================================================================
-- This creates draft invoice reports that should be cancelled during force close
-- These are added to Scenario 1 to test the cancellation logic

-- Create additional draft invoice report for Scenario 1 (should be cancelled during force close)
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, payment_request_id, status, is_draft,
    company_code, created_by, supplier_invoice_no, issued_invoice_date, invoice_amount,
    created_at, updated_at
) VALUES
('FC-IR-01-DRAFT',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 NULL, -- No payment request yet
 'IR Draft', true,
 '12553', 150, 'INV-DRAFT-FC-001', NOW(), 5000.00,
 NOW(), NOW());

-- Create additional for_approval invoice report for Scenario 1 (should be cancelled during force close)
INSERT INTO invoice_reports (
    ir_number, requisition_id, purchase_order_id, payment_request_id, status, is_draft,
    company_code, created_by, supplier_invoice_no, issued_invoice_date, invoice_amount,
    created_at, updated_at
) VALUES
('FC-IR-01-PENDING',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1),
 NULL, -- No payment request yet
 'Invoice Received', false,
 '12553', 150, 'INV-PENDING-FC-001', NOW(), 3000.00,
 NOW(), NOW());

-- ============================================================================
-- VERIFICATION: Display all created scenarios
-- ============================================================================

SELECT 'ALL FORCE CLOSE SCENARIOS CREATED (ELIGIBLE + NOT ELIGIBLE):' as status;

-- Scenario 1 verification (ELIGIBLE)
SELECT 'SCENARIO 1: Active PO with Partial Deliveries (ELIGIBLE)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    po.po_number,
    po.status as po_status,
    COUNT(DISTINCT poi.id) as po_items,
    SUM(poi.quantity_purchased) as total_ordered,
    SUM(dri.qty_delivered) as total_delivered,
    ROUND(SUM(dri.qty_delivered) / SUM(poi.quantity_purchased) * 100, 2) as delivery_percentage,
    pr.status as payment_status
FROM requisitions r
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
LEFT JOIN delivery_receipts dr ON r.id = dr.requisition_id
LEFT JOIN delivery_receipt_items dri ON dr.id = dri.dr_id
LEFT JOIN rs_payment_requests pr ON r.id = pr.requisition_id
WHERE r.rs_number = 'TEST-FC-SCENARIO1'
GROUP BY r.id, r.rs_number, r.status, po.po_number, po.status, pr.status;

-- Scenario 2 verification (ELIGIBLE)
SELECT 'SCENARIO 2: Closed POs with Remaining Quantities (ELIGIBLE)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    po.po_number,
    po.status as po_status,
    SUM(ril.quantity) as total_requested,
    SUM(poi.quantity_purchased) as total_canvassed,
    SUM(ril.quantity) - SUM(poi.quantity_purchased) as remaining_qty,
    pr.status as payment_status
FROM requisitions r
LEFT JOIN requisition_item_lists ril ON r.id = ril.requisition_id
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
LEFT JOIN rs_payment_requests pr ON r.id = pr.requisition_id
WHERE r.rs_number = 'TEST-FC-SCENARIO2'
GROUP BY r.id, r.rs_number, r.status, po.po_number, po.status, pr.status;

-- Scenario 3 verification (ELIGIBLE)
SELECT 'SCENARIO 3: Closed POs with Pending CS Approvals (ELIGIBLE)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    po.po_number,
    po.status as po_status,
    COUNT(DISTINCT cs.id) as total_canvass_sheets,
    COUNT(DISTINCT CASE WHEN cs.status = 'approved' THEN cs.id END) as approved_cs,
    COUNT(DISTINCT CASE WHEN cs.status = 'for_approval' THEN cs.id END) as pending_cs,
    pr.status as payment_status
FROM requisitions r
LEFT JOIN canvass_requisitions cs ON r.id = cs.requisition_id
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
LEFT JOIN rs_payment_requests pr ON r.id = pr.requisition_id
WHERE r.rs_number = 'TEST-FC-SCENARIO3'
GROUP BY r.id, r.rs_number, r.status, po.po_number, po.status, pr.status;

-- Scenario 4 verification (NOT ELIGIBLE - Unauthorized User)
SELECT 'SCENARIO 4: Unauthorized User (NOT ELIGIBLE - Error1)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    r.created_by as requester_id,
    r.assigned_to as assigned_staff_id,
    po.po_number,
    po.status as po_status,
    'User 151 (unauthorized) trying to force close' as test_condition,
    'Should show Access Denied' as expected_result
FROM requisitions r
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
WHERE r.rs_number = 'TEST-FC-SCENARIO4';

-- Scenario 5 verification (NOT ELIGIBLE - RS Status Before In Progress)
SELECT 'SCENARIO 5: RS Status Before In Progress (NOT ELIGIBLE - Error2)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    'RS status is for_rs_approval (before rs_in_progress)' as test_condition,
    'Should show No Force Close Button Yet - Still eligible for RS Cancellation' as expected_result
FROM requisitions r
WHERE r.rs_number = 'TEST-FC-SCENARIO5';

-- Scenario 6 verification (NOT ELIGIBLE - PO Status Before For Delivery)
SELECT 'SCENARIO 6: PO Status Before For Delivery (NOT ELIGIBLE - Error3)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    po.po_number,
    po.status as po_status,
    'PO status is for_po_approval (before for_delivery)' as test_condition,
    'Should show User must wait for PO to progress or manually cancel PO' as expected_result
FROM requisitions r
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
WHERE r.rs_number = 'TEST-FC-SCENARIO6';

-- Scenario 7 verification (NOT ELIGIBLE - No Deliveries Yet)
SELECT 'SCENARIO 7: No Deliveries Yet (NOT ELIGIBLE - Error3)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    po.po_number,
    po.status as po_status,
    COUNT(dr.id) as delivery_count,
    'PO for_delivery but no delivery receipts' as test_condition,
    'Should show User should manually cancel PO before force closing' as expected_result
FROM requisitions r
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
LEFT JOIN delivery_receipts dr ON r.id = dr.requisition_id
WHERE r.rs_number = 'TEST-FC-SCENARIO7'
GROUP BY r.id, r.rs_number, r.status, po.po_number, po.status;

-- Scenario 8 verification (NOT ELIGIBLE - Unpaid Deliveries)
SELECT 'SCENARIO 8: Unpaid Deliveries (NOT ELIGIBLE - Error4)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    po.po_number,
    po.status as po_status,
    COUNT(dr.id) as delivery_count,
    pr.status as payment_status,
    'Partial deliveries exist but payment not closed' as test_condition,
    'Should show User should pay delivered quantities first' as expected_result
FROM requisitions r
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
LEFT JOIN delivery_receipts dr ON r.id = dr.requisition_id
LEFT JOIN rs_payment_requests pr ON r.id = pr.requisition_id
WHERE r.rs_number = 'TEST-FC-SCENARIO8'
GROUP BY r.id, r.rs_number, r.status, po.po_number, po.status, pr.status;

-- Scenario 9 verification (NOT ELIGIBLE - Auto-Close Detection)
SELECT 'SCENARIO 9: Auto-Close Detection (NOT ELIGIBLE - Should Auto-Close)' as scenario;
SELECT
    r.rs_number,
    r.status as rs_status,
    po.po_number,
    po.status as po_status,
    SUM(ril.quantity) as total_requested,
    SUM(poi.quantity_purchased) as total_canvassed,
    SUM(dri.qty_delivered) as total_delivered,
    pr.status as payment_status,
    'All POs closed + no remaining qty + no pending CS' as test_condition,
    'Should show Requisition should auto-close instead of force close' as expected_result
FROM requisitions r
LEFT JOIN requisition_item_lists ril ON r.id = ril.requisition_id
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
LEFT JOIN delivery_receipts dr ON r.id = dr.requisition_id
LEFT JOIN delivery_receipt_items dri ON dr.id = dri.dr_id
LEFT JOIN rs_payment_requests pr ON r.id = pr.requisition_id
WHERE r.rs_number = 'TEST-FC-SCENARIO9'
GROUP BY r.id, r.rs_number, r.status, po.po_number, po.status, pr.status;

-- ============================================================================
-- INVOICE REPORTS VERIFICATION
-- ============================================================================
SELECT 'INVOICE REPORTS VERIFICATION - Critical for Force Close Validation' as verification_section;

-- Show all invoice reports created for force close testing
SELECT
    ir.ir_number,
    r.rs_number,
    ir.status as ir_status,
    ir.is_draft,
    po.po_number,
    pr.pr_number,
    pr.status as pr_status,
    ir.supplier_invoice_no,
    ir.invoice_amount,
    CASE
        WHEN ir.status = 'draft' OR ir.status = 'for_approval' THEN 'Should be CANCELLED during force close'
        WHEN ir.status = 'Closed' THEN 'Already processed - no action needed'
        ELSE 'Unknown status'
    END as force_close_action
FROM invoice_reports ir
LEFT JOIN requisitions r ON ir.requisition_id = r.id
LEFT JOIN purchase_orders po ON ir.purchase_order_id = po.id
LEFT JOIN rs_payment_requests pr ON ir.payment_request_id = pr.id
WHERE r.rs_number LIKE 'TEST-FC-%'
ORDER BY r.rs_number, ir.ir_number;

-- Summary of invoice reports by scenario
SELECT
    r.rs_number,
    COUNT(ir.id) as total_invoice_reports,
    COUNT(CASE WHEN ir.status = 'draft' THEN 1 END) as draft_reports,
    COUNT(CASE WHEN ir.status = 'for_approval' THEN 1 END) as pending_reports,
    COUNT(CASE WHEN ir.status = 'Closed' THEN 1 END) as closed_reports,
    'Draft and Pending should be cancelled during force close' as note
FROM requisitions r
LEFT JOIN invoice_reports ir ON r.id = ir.requisition_id
WHERE r.rs_number LIKE 'TEST-FC-%'
GROUP BY r.rs_number
ORDER BY r.rs_number;

EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All 9 Force Close Scenarios setup completed successfully!${NC}"
    echo -e "${GREEN}✓ Invoice Reports created for comprehensive validation testing!${NC}"
    echo ""
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${GREEN}Force Close Test Scenarios Created (with Invoice Reports):${NC}"
    echo ""
    echo -e "${GREEN}ELIGIBLE SCENARIOS (Force Close Button Should Be ENABLED):${NC}"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO1${NC} - Active PO with Partial Deliveries"
    echo -e "  - RS Status: rs_in_progress ✅"
    echo -e "  - PO Status: for_delivery ✅"
    echo -e "  - Delivery: 60% delivered and PAID ✅"
    echo -e "  - Force Close: SHOULD BE ELIGIBLE ✅"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO2${NC} - Closed POs with Remaining Quantities"
    echo -e "  - RS Status: rs_in_progress ✅"
    echo -e "  - PO Status: closed ✅"
    echo -e "  - Remaining Qty: 30 units Item 1 + 30 units Item 2 ✅"
    echo -e "  - Force Close: SHOULD BE ELIGIBLE ✅"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO3${NC} - Closed POs with Pending CS Approvals"
    echo -e "  - RS Status: rs_in_progress ✅"
    echo -e "  - PO Status: closed ✅"
    echo -e "  - Pending CS: FC-CS-03B (for_approval) ✅"
    echo -e "  - Force Close: SHOULD BE ELIGIBLE ✅"
    echo ""
    echo -e "${RED}NOT ELIGIBLE SCENARIOS (Force Close Button Should Be HIDDEN):${NC}"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO4${NC} - Unauthorized User (Error1)"
    echo -e "  - Created by user 150, assigned to user 144"
    echo -e "  - Test with user 151 (unauthorized) ❌"
    echo -e "  - Expected: Access Denied ❌"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO5${NC} - RS Status Before In Progress (Error2)"
    echo -e "  - RS Status: for_rs_approval (before rs_in_progress) ❌"
    echo -e "  - Items: OFM + Non-OFM mix for comprehensive testing"
    echo -e "  - Expected: Still eligible for RS Cancellation ❌"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO6${NC} - PO Status Before For Delivery (Error3)"
    echo -e "  - PO Status: for_po_approval (before for_delivery) ❌"
    echo -e "  - Items: OFM + Non-OFM mix for comprehensive testing"
    echo -e "  - Expected: User must wait for PO to progress ❌"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO7${NC} - No Deliveries Yet (Error3)"
    echo -e "  - PO Status: for_delivery but no delivery receipts ❌"
    echo -e "  - Items: OFM + Non-OFM mix for comprehensive testing"
    echo -e "  - Expected: User should manually cancel PO first ❌"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO8${NC} - Unpaid Deliveries (Error4)"
    echo -e "  - Partial deliveries but payment status: for_approval ❌"
    echo -e "  - Items: OFM + Non-OFM mix for comprehensive testing"
    echo -e "  - Expected: User should pay delivered quantities first ❌"
    echo ""
    echo -e "${YELLOW}• TEST-FC-SCENARIO9${NC} - Auto-Close Detection"
    echo -e "  - All POs closed, no remaining qty, no pending CS ❌"
    echo -e "  - Expected: Should auto-close instead of force close ❌"
    echo ""
    echo -e "${GREEN}How to Test Force Close:${NC}"
    echo -e "${YELLOW}1.${NC} Login to https://localhost:8444"
    echo -e "${YELLOW}2.${NC} Use credentials: ronald / 4842#O2Kv"
    echo -e "${YELLOW}3.${NC} Go to Dashboard and look for TEST-FC-SCENARIO1-9"
    echo -e "${YELLOW}4.${NC} Click on any requisition to test Force Close functionality"
    echo -e "${YELLOW}5.${NC} For ELIGIBLE scenarios (1-3): RED 'Force Close' button should be ENABLED ✅"
    echo -e "${YELLOW}6.${NC} For NOT ELIGIBLE scenarios (4-9): Force Close button should be HIDDEN ❌"
    echo -e "${YELLOW}7.${NC} Click button to test modal opening and execution (eligible scenarios only)"
    echo -e "${YELLOW}8.${NC} Verify invoice reports are properly cancelled during force close execution"
    echo ""
    echo -e "${GREEN}Expected Results:${NC}"
    echo -e "  ✅ ELIGIBLE: Force Close button is visible AND enabled (Scenarios 1-3)"
    echo -e "  ❌ NOT ELIGIBLE: Force Close button is HIDDEN (Scenarios 4-9)"
    echo -e "  ✅ Modal opens when button is clicked (eligible scenarios only)"
    echo -e "  ✅ Force close execution should work for eligible scenarios"
    echo -e "  ✅ Draft and pending invoice reports should be cancelled during force close"
    echo -e "  ✅ Payment validation: DR Qty × Unit Price = PR Amount should be enforced"
    echo -e "  ✅ Authorization validation: Only Requester and Assigned Staff have access"
    echo ""
    echo -e "${GREEN}Comprehensive Validation Coverage:${NC}"
    echo -e "  • User Authorization (Requester + Assigned Staff only)"
    echo -e "  • Requisition Status (RS In Progress required)"
    echo -e "  • Purchase Order Status (FOR DELIVERY or CLOSED required)"
    echo -e "  • Payment and Delivery Validation (DR Qty × Unit Price = PR Amount)"
    echo -e "  • Three Force Close Scenarios from requirements"
    echo -e "  • Invoice Reports cancellation during force close"
    echo -e "  • All document types: CS, IR, DR, PR, PO, RS"
    echo -e "${BLUE}============================================================================${NC}"

    # Validate test data was created successfully
    echo -e "${YELLOW}Validating test data creation...${NC}"

    # Check requisitions were created
    RS_COUNT=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM requisitions WHERE rs_number LIKE 'TEST-FC-%';\"" | tr -d ' ')
    echo -e "${GREEN}✓ Created $RS_COUNT test requisitions${NC}"

    # Check purchase orders were created
    PO_COUNT=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM purchase_orders WHERE po_number LIKE 'TEST-PO-%';\"" | tr -d ' ')
    echo -e "${GREEN}✓ Created $PO_COUNT test purchase orders${NC}"

    # Check payment requests were created
    PR_COUNT=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM rs_payment_requests WHERE pr_number LIKE 'FC-PR-%';\"" | tr -d ' ')
    echo -e "${GREEN}✓ Created $PR_COUNT test payment requests${NC}"

    echo -e "${GREEN}✓ All test data created successfully!${NC}"
    echo ""
    echo -e "${YELLOW}=== FORCE CLOSE VALIDATION CHECKLIST ===${NC}"
    echo -e "${BLUE}After executing force close, verify these expectations:${NC}"
    echo ""
    echo -e "${GREEN}1. Input Force Close Reason:${NC}"
    echo "   ✓ Modal should appear with text area for reason (max 500 chars)"
    echo "   ✓ Reason should be required (cannot be empty)"
    echo "   ✓ Should accept alphanumeric + special characters (no emojis)"
    echo ""
    echo -e "${GREEN}2. Check RS Status:${NC}"
    echo "   ✓ RS status should change to 'rs_closed' after force close"
    echo "   Query: SELECT rs_number, status FROM requisitions WHERE rs_number LIKE 'TEST-FC-%';"
    echo ""
    echo -e "${GREEN}3. Force Close Reason in RS Notes:${NC}"
    echo "   ✓ Force close reason should be stored in force_close_reason field"
    echo "   Query: SELECT rs_number, force_close_reason FROM requisitions WHERE rs_number LIKE 'TEST-FC-%';"
    echo ""
    echo -e "${GREEN}4. Cannot Enter Canvass - Zero Out Remaining Qty:${NC}"
    echo "   ✓ No new canvass sheets should be creatable"
    echo "   ✓ Remaining quantities should be zeroed out"
    echo "   Query: SELECT rs_number, item_id, quantity, (SELECT COALESCE(SUM(quantity_purchased), 0) FROM purchase_order_items poi JOIN purchase_orders po ON poi.purchase_order_id = po.id WHERE poi.requisition_item_list_id = ril.id) as purchased_qty FROM requisition_item_lists ril JOIN requisitions r ON ril.requisition_id = r.id WHERE r.rs_number LIKE 'TEST-FC-%';"
    echo ""
    echo -e "${GREEN}5. Cannot Do Anything with RS:${NC}"
    echo "   ✓ RS should be read-only after force close"
    echo "   ✓ No modifications should be allowed"
    echo "   ✓ All action buttons should be disabled/hidden"
    echo ""
    echo -e "${GREEN}6. All Draft and Pending Documents Closed:${NC}"
    echo "   ✓ Check canvass sheets: SELECT cs_number, status FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%');"
    echo "   ✓ Check invoice reports: SELECT ir_number, status FROM invoice_reports WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%');"
    echo "   ✓ Check delivery receipts: SELECT dr_number, status FROM delivery_receipts WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%');"
    echo "   ✓ Check payment requests: SELECT pr_number, status FROM rs_payment_requests WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%');"
    echo ""
    echo -e "${GREEN}7. PO Updates After Force Close:${NC}"
    echo "   ✓ PO Amount should reflect total approved PR amount"
    echo "   ✓ PO Quantity should reflect total delivered RR quantity"
    echo "   ✓ Auto-generated notes should be added to PO"
    echo "   Query: SELECT po_number, total_amount, system_generated_notes FROM purchase_orders WHERE po_number LIKE 'TEST-PO-%';"
    echo "   Query: SELECT po.po_number, poi.quantity_purchased, dri.qty_delivered FROM purchase_orders po JOIN purchase_order_items poi ON po.id = poi.purchase_order_id LEFT JOIN delivery_receipt_items dri ON poi.id = dri.po_item_id WHERE po.po_number LIKE 'TEST-PO-%';"
    echo ""
    echo -e "${GREEN}8. OFM Quantity Return to GFQ:${NC}"
    echo "   ✓ For OFM items, remaining quantities should be returned to GFQ"
    echo "   ✓ Check items table for GFQ quantity updates"
    echo "   Query: SELECT i.id as item_id, i.remaining_gfq, ril.item_type, ril.quantity, (ril.quantity - COALESCE(SUM(poi.quantity_purchased), 0)) as remaining FROM items i JOIN requisition_item_lists ril ON i.id = ril.item_id LEFT JOIN purchase_order_items poi ON ril.id = poi.requisition_item_list_id WHERE ril.requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%') AND ril.item_type = 'ofm' GROUP BY i.id, i.remaining_gfq, ril.item_type, ril.quantity;"
    echo ""
    echo -e "${YELLOW}=== QUICK VALIDATION QUERIES ===${NC}"
    echo -e "${BLUE}Run these in your database to verify test data:${NC}"
    echo ""
    echo -e "${YELLOW}-- Check all test requisitions:${NC}"
    echo "SELECT rs_number, status, created_by, assigned_to FROM requisitions WHERE rs_number LIKE 'TEST-FC-%' ORDER BY rs_number;"
    echo ""
    echo -e "${YELLOW}-- Check PO statuses:${NC}"
    echo "SELECT po_number, status FROM purchase_orders WHERE po_number LIKE 'TEST-PO-%' ORDER BY po_number;"
    echo ""
    echo -e "${YELLOW}-- Check payment statuses:${NC}"
    echo "SELECT pr_number, status FROM rs_payment_requests WHERE pr_number LIKE 'FC-PR-%' ORDER BY pr_number;"
    echo ""
    echo -e "${BLUE}=== POST FORCE CLOSE VALIDATION ===${NC}"
    echo -e "${GREEN}After executing force close on any scenario, run this command to validate:${NC}"
    echo -e "${YELLOW}./scripts/validate-force-close.sh TEST-FC-SCENARIO1${NC}"
    echo ""
    echo -e "${GREEN}Or use the built-in validation function:${NC}"
    echo -e "${YELLOW}source ./scripts/setup-force-close-comprehensive.sh${NC}"
    echo -e "${YELLOW}validate_force_close_results TEST-FC-SCENARIO1${NC}"
    echo ""

else
    echo -e "${RED}✗ Error setting up test data${NC}"
    exit 1
fi
