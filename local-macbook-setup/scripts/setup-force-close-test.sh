#!/bin/bash

# ============================================================================
# Force Close Test Data Setup Script
# ============================================================================
# This script sets up test requisitions for force close functionality testing.
# It creates requisitions in various statuses that are eligible for force close.
#
# Usage:
#   ./scripts/setup-force-close-test.sh
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
echo -e "${BLUE}Force Close Test Data Setup${NC}"
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

# Run the SQL script
echo -e "${YELLOW}Setting up force close test data...${NC}"

# Copy the SQL script to the container and run it with password
docker exec -i prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME" << 'EOF'
-- ============================================================================
-- Force Close Test Data Setup Script
-- ============================================================================

-- Clean up any existing test data first (in proper order to avoid foreign key issues)
-- Clean up payment requests first
DELETE FROM rs_payment_requests WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);

-- Clean up delivery receipt items
DELETE FROM delivery_receipt_items WHERE delivery_receipt_id IN (
    SELECT id FROM delivery_receipts WHERE requisition_id IN (
        SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
    )
);

-- Clean up delivery receipts
DELETE FROM delivery_receipts WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);

-- Clean up purchase order items
DELETE FROM purchase_order_items WHERE purchase_order_id IN (
    SELECT id FROM purchase_orders WHERE requisition_id IN (
        SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
    )
);

-- Clean up purchase orders
DELETE FROM purchase_orders WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);

-- Clean up canvass items
DELETE FROM canvass_items WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);

-- Clean up canvass requisitions
DELETE FROM canvass_requisitions WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);

-- Clean up requisition approvers
DELETE FROM requisition_approvers WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);

-- Clean up requisition items
DELETE FROM requisition_item_lists WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);

-- Clean up requisitions
DELETE FROM requisitions WHERE rs_number LIKE 'TEST-FC-%';

-- Clean up test projects
DELETE FROM projects WHERE code LIKE 'TEST-PROJ-%';

-- Create test project for force close testing
INSERT INTO projects (code, name, initial, address, company_code, created_at, updated_at)
VALUES ('TEST-PROJ-FC', 'Test Project for Force Close Testing', 'TPFC', 'Test Project Address', '12553', NOW(), NOW());

-- ============================================================================
-- SCENARIO 1: Active PO with Partial Deliveries (Force Close Eligible)
-- ============================================================================

-- Create requisition for Scenario 1
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to, category,
    created_at, updated_at
) VALUES
('TEST-FC-SCENARIO1', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Force Close Scenario 1: Active PO with Partial Deliveries', 'Test Project',
 'rs_in_progress', 'regular', 144, 'association',
 NOW(), NOW());

-- Add items to test requisitions to make them realistic
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
-- Items for TEST-FC-SUBMITTED
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SUBMITTED'), 7, 'non_ofm', 10, 'Test item for force close - submitted', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SUBMITTED'), 28, 'non_ofm', 5, 'Another test item - submitted', '12345', NOW(), NOW()),

-- Items for TEST-FC-ASSIGNED
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-ASSIGNED'), 7, 'non_ofm', 15, 'Test item for force close - assigned', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-ASSIGNED'), 28, 'non_ofm', 8, 'Another test item - assigned', '12345', NOW(), NOW()),

-- Items for TEST-FC-CANVASS-APPROVAL
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-CANVASS-APPROVAL'), 28, 'non_ofm', 20, 'Test item for force close - canvass approval', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-CANVASS-APPROVAL'), 7, 'non_ofm', 12, 'Another test item - canvass approval', '12345', NOW(), NOW()),

-- Items for TEST-FC-PARTIAL-CANVASS
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PARTIAL-CANVASS'), 7, 'non_ofm', 8, 'Test item for force close - partial canvass', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PARTIAL-CANVASS'), 28, 'non_ofm', 6, 'Another test item - partial canvass', '12345', NOW(), NOW()),

-- Items for TEST-FC-PO-SCENARIO
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PO-SCENARIO'), 7, 'non_ofm', 25, 'Test item for force close - PO scenario', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PO-SCENARIO'), 28, 'non_ofm', 15, 'Another test item - PO scenario', '12345', NOW(), NOW());

-- Add requisition approvers for proper approval workflow
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
-- Approvers for TEST-FC-SUBMITTED
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SUBMITTED'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SUBMITTED'), 144, 1, false, 'requisition', 'pending', NOW(), NOW()),

-- Approvers for TEST-FC-ASSIGNED
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-ASSIGNED'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-ASSIGNED'), 144, 1, false, 'requisition', 'pending', NOW(), NOW()),

-- Approvers for TEST-FC-CANVASS-APPROVAL
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-CANVASS-APPROVAL'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-CANVASS-APPROVAL'), 21, 1, false, 'requisition', 'approved', NOW(), NOW()),

-- Approvers for TEST-FC-PARTIAL-CANVASS
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PARTIAL-CANVASS'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PARTIAL-CANVASS'), 21, 1, false, 'requisition', 'approved', NOW(), NOW()),

-- Approvers for TEST-FC-PO-SCENARIO
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PO-SCENARIO'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PO-SCENARIO'), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Display the created test data
SELECT
    r.id,
    r.rs_number,
    r.status,
    COUNT(ril.id) as item_count
FROM requisitions r
LEFT JOIN requisition_item_lists ril ON r.id = ril.requisition_id
WHERE r.rs_number LIKE 'TEST-FC-%'
GROUP BY r.id, r.rs_number, r.status
ORDER BY r.rs_number;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Force close test data setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${GREEN}Test Requisitions Created:${NC}"
    echo -e "${YELLOW}• TEST-FC-SUBMITTED${NC} (submitted status)"
    echo -e "${YELLOW}• TEST-FC-ASSIGNED${NC} (assigned status)"
    echo -e "${YELLOW}• TEST-FC-CANVASS-APPROVAL${NC} (canvass_approval status)"
    echo -e "${YELLOW}• TEST-FC-PARTIAL-CANVASS${NC} (partially_canvassed status)"
    echo -e "${YELLOW}• TEST-FC-PO-SCENARIO${NC} (po_creation status)"
    echo ""
    echo -e "${GREEN}How to Test:${NC}"
    echo -e "${YELLOW}1.${NC} Login to https://localhost:8444"
    echo -e "${YELLOW}2.${NC} Use credentials: ronald / 4842#O2Kv"
    echo -e "${YELLOW}3.${NC} Go to Dashboard and look for TEST-FC-* requisitions"
    echo -e "${YELLOW}4.${NC} Click on any requisition to test Force Close functionality"
    echo -e "${BLUE}============================================================================${NC}"
else
    echo -e "${RED}✗ Error setting up test data${NC}"
    exit 1
fi
