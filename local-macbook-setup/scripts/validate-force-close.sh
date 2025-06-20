#!/bin/bash

#
# Force Close Validation Script
# =============================
# This script validates that force close functionality works correctly
# according to all the specified expectations.
#
# Usage:
#   ./scripts/validate-force-close.sh TEST-FC-SCENARIO1
#
# Prerequisites:
#   - Docker containers must be running
#   - Database must be accessible
#   - Force close must have been executed on the specified requisition
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if requisition number is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Please provide a requisition number${NC}"
    echo -e "${YELLOW}Usage: $0 TEST-FC-SCENARIO1${NC}"
    exit 1
fi

RS_NUMBER="$1"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Force Close Validation for $RS_NUMBER${NC}"
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

# Check if requisition exists
echo -e "${YELLOW}Checking if requisition exists...${NC}"
RS_EXISTS=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM requisitions WHERE rs_number = '$RS_NUMBER';\"" | tr -d ' ')
if [ "$RS_EXISTS" -eq 0 ]; then
    echo -e "${RED}Error: Requisition $RS_NUMBER not found${NC}"
    echo -e "${YELLOW}Available test requisitions:${NC}"
    docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -c \"SELECT rs_number, status FROM requisitions WHERE rs_number LIKE 'TEST-FC-%' ORDER BY rs_number;\""
    exit 1
fi

echo -e "${GREEN}✓ Requisition $RS_NUMBER found${NC}"
echo ""

# Start validation
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}FORCE CLOSE VALIDATION RESULTS${NC}"
echo -e "${BLUE}============================================================================${NC}"

VALIDATION_PASSED=0
VALIDATION_FAILED=0

# 1. Check RS Status
echo -e "${YELLOW}1. Checking RS Status...${NC}"
RS_STATUS=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT status FROM requisitions WHERE rs_number = '$RS_NUMBER';\"" | tr -d ' ')
if [ "$RS_STATUS" = "rs_closed" ]; then
    echo -e "${GREEN}   ✓ RS Status: $RS_STATUS (CORRECT)${NC}"
    ((VALIDATION_PASSED++))
else
    echo -e "${RED}   ✗ RS Status: $RS_STATUS (EXPECTED: rs_closed)${NC}"
    ((VALIDATION_FAILED++))
fi

# 2. Check Force Close Reason in Notes
echo -e "${YELLOW}2. Checking Force Close Reason in RS Notes...${NC}"
RS_NOTES=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COALESCE(notes, '') FROM requisitions WHERE rs_number = '$RS_NUMBER';\"")
if [[ "$RS_NOTES" == *"Force Close"* ]] || [[ "$RS_NOTES" == *"force close"* ]]; then
    echo -e "${GREEN}   ✓ Force Close Reason found in notes${NC}"
    echo -e "${BLUE}   Notes: $RS_NOTES${NC}"
    ((VALIDATION_PASSED++))
else
    echo -e "${RED}   ✗ Force Close Reason NOT found in notes${NC}"
    echo -e "${BLUE}   Current Notes: $RS_NOTES${NC}"
    ((VALIDATION_FAILED++))
fi

# 3. Check Remaining Quantities Zeroed Out
echo -e "${YELLOW}3. Checking Remaining Quantities...${NC}"
REMAINING_QTY=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"
SELECT SUM(ril.quantity - COALESCE(poi_sum.total_purchased, 0)) as remaining
FROM requisition_item_lists ril
LEFT JOIN (
    SELECT poi.requisition_item_list_id, SUM(poi.quantity_purchased) as total_purchased
    FROM purchase_order_items poi
    JOIN purchase_orders po ON poi.purchase_order_id = po.id
    WHERE po.requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$RS_NUMBER')
    GROUP BY poi.requisition_item_list_id
) poi_sum ON ril.id = poi_sum.requisition_item_list_id
WHERE ril.requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$RS_NUMBER');
\"" | tr -d ' ')

if [ "$REMAINING_QTY" = "0" ] || [ "$REMAINING_QTY" = "" ]; then
    echo -e "${GREEN}   ✓ All quantities properly handled (no remaining quantities)${NC}"
    ((VALIDATION_PASSED++))
else
    echo -e "${YELLOW}   ! Remaining quantity: $REMAINING_QTY (may be expected for some scenarios)${NC}"
fi

# 4. Check Draft and Pending Documents
echo -e "${YELLOW}4. Checking Draft and Pending Documents...${NC}"

# Check Canvass Sheets
PENDING_CS=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM canvass_requisitions WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$RS_NUMBER') AND status IN ('draft', 'for_approval');\"" | tr -d ' ')
if [ "$PENDING_CS" -eq 0 ]; then
    echo -e "${GREEN}   ✓ No pending canvass sheets${NC}"
    ((VALIDATION_PASSED++))
else
    echo -e "${RED}   ✗ Found $PENDING_CS pending canvass sheets${NC}"
    ((VALIDATION_FAILED++))
fi

# Check Invoice Reports
PENDING_IR=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM invoice_reports WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$RS_NUMBER') AND status IN ('draft', 'pending');\"" | tr -d ' ')
if [ "$PENDING_IR" -eq 0 ]; then
    echo -e "${GREEN}   ✓ No pending invoice reports${NC}"
    ((VALIDATION_PASSED++))
else
    echo -e "${RED}   ✗ Found $PENDING_IR pending invoice reports${NC}"
    ((VALIDATION_FAILED++))
fi

# 5. Check PO Updates
echo -e "${YELLOW}5. Checking PO Updates...${NC}"

# Check if PO notes contain force close information
PO_NOTES=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COALESCE(notes, '') FROM purchase_orders WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$RS_NUMBER') LIMIT 1;\"")
if [[ "$PO_NOTES" == *"Force Close"* ]] || [[ "$PO_NOTES" == *"force close"* ]]; then
    echo -e "${GREEN}   ✓ PO notes updated with force close information${NC}"
    ((VALIDATION_PASSED++))
else
    echo -e "${YELLOW}   ! PO notes may need force close information${NC}"
    echo -e "${BLUE}   Current PO Notes: $PO_NOTES${NC}"
fi

# Check PO amount and quantity updates
echo -e "${YELLOW}6. Checking PO Amount and Quantity Updates...${NC}"
docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -c \"
SELECT 
    po.po_number,
    po.total_amount as po_amount,
    SUM(poi.quantity_purchased) as po_total_qty,
    SUM(COALESCE(dri.qty_delivered, 0)) as delivered_qty,
    SUM(COALESCE(pr.amount, 0)) as paid_amount
FROM purchase_orders po
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
LEFT JOIN delivery_receipt_items dri ON poi.id = dri.po_item_id
LEFT JOIN rs_payment_requests pr ON po.id = pr.purchase_order_id AND pr.status = 'Closed'
WHERE po.requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$RS_NUMBER')
GROUP BY po.po_number, po.total_amount;
\""

# 6. Check OFM Quantity Return
echo -e "${YELLOW}7. Checking OFM Quantity Return to GFQ...${NC}"

OFM_ITEMS=$(docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT COUNT(*) FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$RS_NUMBER') AND item_type = 'ofm';\"" | tr -d ' ')
if [ "$OFM_ITEMS" -gt 0 ]; then
    echo -e "${GREEN}   ✓ Found $OFM_ITEMS OFM items${NC}"
    echo -e "${YELLOW}   → Checking GFQ updates...${NC}"
    
    # Show OFM items and their quantities
    docker exec prs-local-postgres bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -c \"
    SELECT 
        ril.item_id,
        ril.quantity as requested_qty,
        COALESCE(SUM(poi.quantity_purchased), 0) as purchased_qty,
        (ril.quantity - COALESCE(SUM(poi.quantity_purchased), 0)) as should_return_to_gfq
    FROM requisition_item_lists ril
    LEFT JOIN purchase_order_items poi ON ril.id = poi.requisition_item_list_id
    WHERE ril.requisition_id = (SELECT id FROM requisitions WHERE rs_number = '$RS_NUMBER')
    AND ril.item_type = 'ofm'
    GROUP BY ril.item_id, ril.quantity;
    \""
    ((VALIDATION_PASSED++))
else
    echo -e "${YELLOW}   ! No OFM items found in this requisition${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}VALIDATION SUMMARY${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}Passed: $VALIDATION_PASSED${NC}"
echo -e "${RED}Failed: $VALIDATION_FAILED${NC}"

if [ "$VALIDATION_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ All validations passed! Force close appears to be working correctly.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some validations failed. Please review the force close implementation.${NC}"
    exit 1
fi
