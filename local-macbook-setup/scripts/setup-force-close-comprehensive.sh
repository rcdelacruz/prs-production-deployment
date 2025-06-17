#!/bin/bash

# ============================================================================
# Comprehensive Force Close Test Data Setup Script
# ============================================================================
# This script creates complete PRS workflows for realistic force close testing.
# It sets up ALL 3 force close scenarios from the requirements document:
# 1. Active PO with Partial Deliveries (paid)
# 2. All POs Closed with Remaining Quantities
# 3. Closed POs with Pending Canvass Sheet Approvals
#
# UPDATED: Includes all database fixes for proper force close functionality:
# - Delivery receipt status set to 'Delivered'
# - Delivery receipt invoices created and linked to payment requests
# - Proper po_item_id linking for delivery receipt items
# - Payment requests properly linked to delivery invoices
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

# Run the comprehensive SQL script
echo -e "${YELLOW}Setting up comprehensive force close test data...${NC}"
echo -e "${YELLOW}This will create complete PRS workflows for realistic testing...${NC}"

# Copy the comprehensive SQL script to the container and run it with password
docker exec -i prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME" << 'EOF'
-- ============================================================================
-- Comprehensive Force Close Test Data Setup
-- ============================================================================
-- This script creates complete PRS workflows to test all 3 force close scenarios:
-- 1. SCENARIO 1: Active PO with Partial Deliveries (paid) - ELIGIBLE
-- 2. SCENARIO 2: All POs Closed with Remaining Quantities - ELIGIBLE
-- 3. SCENARIO 3: Closed POs with Pending Canvass Sheet Approvals - ELIGIBLE
-- ============================================================================

-- Clean up any existing test data first (in proper order to avoid foreign key issues)
DELETE FROM rs_payment_requests WHERE requisition_id IN (
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
DELETE FROM projects WHERE code LIKE 'TEST-PROJ-%';

-- Create test project for force close testing
INSERT INTO projects (code, name, initial, address, company_code, created_at, updated_at)
VALUES ('TEST-PROJ-FC', 'Test Project for Force Close Testing', 'TPFC', 'Test Project Address', '12553', NOW(), NOW());

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
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Scenario 1: Active PO with Partial Deliveries', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 1 requisition
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'), 7, 'non_ofm', 100, 'Item 1 - partial delivery scenario', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'), 28, 'non_ofm', 50, 'Item 2 - partial delivery scenario', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 1
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 1
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'), 'FC-CS-01', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 1
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01'),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 7),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01'),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 28),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 1 (FOR_DELIVERY status)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-001', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01'),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'for_delivery',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 1 (required for PO items)
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 7)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 100, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 28)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 1 (THIS IS CRITICAL FOR FORCE CLOSE ELIGIBILITY)
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 7)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 7),
 100,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 7))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 28)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 28),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 28))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 1 (PARTIAL delivery - only 60% delivered)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-001',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 1 (partial quantities with proper po_item_id linking)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 7)),
 'Test Item 1', 100, 60, 'pcs', NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 28)),
 'Test Item 2', 50, 30, 'pcs', NOW(), NOW());

-- Create delivery receipt invoice for Scenario 1 (required for payment linking)
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001'),
 'INV-TEST-FC-001', NOW(), 15000.00, 1800.00,
 NOW(), NOW());

-- Create payment request for Scenario 1 (for delivered quantities only - PAID)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-01', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001')),
 'Closed', false,
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
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Scenario 2: Closed POs with Remaining Quantities', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 2 requisition (more items than will be canvassed)
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'), 7, 'non_ofm', 100, 'Item 1 - only 70 will be canvassed', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'), 28, 'non_ofm', 80, 'Item 2 - only 50 will be canvassed', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 2
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create canvass sheet for Scenario 2 (partial canvassing)
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'), 'FC-CS-02', 'A', 'approved', NOW(), NOW());

-- Add canvass items for Scenario 2 (only partial quantities)
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02'),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 7),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02'),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 28),
 'approved', NOW(), NOW());

-- Create purchase order for Scenario 2 (CLOSED status)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-002', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02'),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'closed',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 2
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 7)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 70, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 28)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 50, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 2 (partial quantities from requisition)
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002'),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 7)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 7),
 70,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 7))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002'),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 28)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 28),
 50,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 28))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 2 (FULL delivery of PO quantities)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-002',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002'),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 2 (full delivery of PO quantities with proper po_item_id linking)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002'),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 7)),
 'Test Item 1', 70, 70, 'pcs', NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002'),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2') AND item_id = 28)),
 'Test Item 2', 50, 50, 'pcs', NOW(), NOW());

-- Create delivery receipt invoice for Scenario 2 (required for payment linking)
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002'),
 'INV-TEST-FC-002', NOW(), 18000.00, 2160.00,
 NOW(), NOW());

-- Create payment request for Scenario 2 (PAID)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-02', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002'),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002')),
 'Closed', false,
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
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Scenario 3: Closed POs with Pending CS Approvals', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to Scenario 3 requisition
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'), 7, 'non_ofm', 100, 'Item 1 - split between 2 canvass sheets', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'), 28, 'non_ofm', 60, 'Item 2 - split between 2 canvass sheets', '12345', NOW(), NOW());

-- Add requisition approvers for Scenario 3
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Create FIRST canvass sheet for Scenario 3 (APPROVED and processed to PO)
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'), 'FC-CS-3A', 'A', 'approved', NOW(), NOW());

-- Create SECOND canvass sheet for Scenario 3 (PENDING APPROVAL)
INSERT INTO canvass_requisitions (
    requisition_id, cs_number, cs_letter, status,
    created_at, updated_at
) VALUES
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'), 'FC-CS-3B', 'B', 'for_approval', NOW(), NOW());

-- Add canvass items for FIRST canvass sheet (approved)
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A'),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 7),
 'approved', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A'),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 28),
 'approved', NOW(), NOW());

-- Add canvass items for SECOND canvass sheet (pending approval)
INSERT INTO canvass_items (
    canvass_requisition_id, requisition_item_list_id, status,
    created_at, updated_at
) VALUES
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3B'),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 7),
 'for_approval', NOW(), NOW()),
((SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3B'),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 28),
 'for_approval', NOW(), NOW());

-- Create purchase order for Scenario 3 (CLOSED status - from first canvass)
INSERT INTO purchase_orders (
    po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status,
    created_at, updated_at
) VALUES
('TEST-PO-003', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'),
 (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A'),
 (SELECT id FROM suppliers LIMIT 1), 'supplier', 'closed',
 NOW(), NOW());

-- Create canvass item suppliers for Scenario 3
INSERT INTO canvass_item_suppliers (canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, supplier_type, created_at, updated_at)
VALUES
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 7)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 70, 1, 10.00, 'fixed', true, 'supplier', NOW(), NOW()),
((SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 28)),
 (SELECT id FROM suppliers LIMIT 1), '30 days', 40, 1, 15.00, 'fixed', true, 'supplier', NOW(), NOW());

-- Add PO items for Scenario 3 (from first canvass only)
INSERT INTO purchase_order_items (
    purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id,
    created_at, updated_at
) VALUES
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003'),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 7)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 7),
 70,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 7))),
 NOW(), NOW()),
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003'),
 (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 28)),
 (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 28),
 40,
 (SELECT id FROM canvass_item_suppliers WHERE canvass_item_id = (SELECT id FROM canvass_items WHERE canvass_requisition_id = (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 28))),
 NOW(), NOW());

-- Create delivery receipt for Scenario 3 (FULL delivery)
INSERT INTO delivery_receipts (
    dr_number, requisition_id, po_id, supplier, is_draft, company_code, status,
    created_at, updated_at
) VALUES
('TEST-DR-003',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003'),
 'Test Supplier', false, '12553', 'Delivered',
 NOW(), NOW());

-- Add delivery receipt items for Scenario 3 (full delivery with proper po_item_id linking)
INSERT INTO delivery_receipt_items (
    dr_id, po_id, item_id, po_item_id, item_des, qty_ordered, qty_delivered, unit,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003'),
 7,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 7)),
 'Test Item 1', 70, 70, 'pcs', NOW(), NOW()),
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003'),
 28,
 (SELECT id FROM purchase_order_items WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003') AND requisition_item_list_id = (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3') AND item_id = 28)),
 'Test Item 2', 40, 40, 'pcs', NOW(), NOW());

-- Create delivery receipt invoice for Scenario 3 (required for payment linking)
INSERT INTO delivery_receipt_invoices (
    delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount,
    created_at, updated_at
) VALUES
((SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003'),
 'INV-TEST-FC-003', NOW(), 16000.00, 1920.00,
 NOW(), NOW());

-- Create payment request for Scenario 3 (PAID)
INSERT INTO rs_payment_requests (
    pr_number, pr_letter, requisition_id, purchase_order_id, delivery_invoice_id, status, is_draft,
    created_at, updated_at
) VALUES
('FC-PR-03', 'A',
 (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3'),
 (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003'),
 (SELECT id FROM delivery_receipt_invoices WHERE delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003')),
 'Closed', false,
 NOW(), NOW());

-- ============================================================================
-- VERIFICATION: Display all created scenarios
-- ============================================================================

SELECT 'ALL FORCE CLOSE SCENARIOS CREATED:' as status;

-- Scenario 1 verification
SELECT 'SCENARIO 1: Active PO with Partial Deliveries' as scenario;
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

-- Scenario 2 verification
SELECT 'SCENARIO 2: Closed POs with Remaining Quantities' as scenario;
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

-- Scenario 3 verification
SELECT 'SCENARIO 3: Closed POs with Pending CS Approvals' as scenario;
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

EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All 3 Force Close Scenarios setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${GREEN}Force Close Test Scenarios Created:${NC}"
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
    echo -e "${GREEN}How to Test Force Close:${NC}"
    echo -e "${YELLOW}1.${NC} Login to https://localhost:8444"
    echo -e "${YELLOW}2.${NC} Use credentials: ronald / 4842#O2Kv"
    echo -e "${YELLOW}3.${NC} Go to Dashboard and look for TEST-FC-SCENARIO1, 2, or 3"
    echo -e "${YELLOW}4.${NC} Click on any requisition to test Force Close functionality"
    echo -e "${YELLOW}5.${NC} RED 'Force Close' button should be ENABLED ✅"
    echo -e "${YELLOW}6.${NC} Click button to test modal opening and execution"
    echo ""
    echo -e "${GREEN}Expected Results:${NC}"
    echo -e "  ✅ Force Close button is visible AND enabled"
    echo -e "  ✅ Modal opens when button is clicked"
    echo -e "  ✅ Force close execution should work for all scenarios"
    echo -e "${BLUE}============================================================================${NC}"
else
    echo -e "${RED}✗ Error setting up test data${NC}"
    exit 1
fi
