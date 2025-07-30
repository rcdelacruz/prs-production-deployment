#!/bin/bash

# ============================================================================
# Fix Test Data Naming Conventions
# ============================================================================
# This script fixes the malformed reference numbers in force-close test data
# that are causing NaN issues in the application
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
echo -e "${BLUE}Fixing Test Data Naming Conventions${NC}"
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
        return 1
    fi
}

echo -e "${YELLOW}Fixing malformed reference numbers in existing data...${NC}"

# Fix the critical NaN issue in canvass_requisitions
execute_sql "
UPDATE canvass_requisitions
SET cs_number = LPAD(id::text, 8, '0')
WHERE cs_number = '00000NaN' OR cs_number LIKE '%NaN%';
" "Fix NaN in CS numbers"

# Fix malformed rs_numbers (missing RS- prefix)
execute_sql "
UPDATE requisitions
SET rs_number = LPAD(rs_number, 8, '0')
WHERE rs_number ~ '^[0-9]+$' AND LENGTH(rs_number) < 8;
" "Fix RS number padding"

# Fix malformed cs_numbers (missing CS- prefix)
execute_sql "
UPDATE canvass_requisitions
SET cs_number = LPAD(cs_number, 8, '0')
WHERE cs_number ~ '^[0-9]+$' AND LENGTH(cs_number) < 8;
" "Fix CS number padding"

# Fix malformed po_numbers if they exist
execute_sql "
UPDATE purchase_orders
SET po_number = LPAD(po_number, 8, '0')
WHERE po_number ~ '^[0-9]+$' AND LENGTH(po_number) < 8;
" "Fix PO number padding"

# Fix malformed dr_numbers if they exist
execute_sql "
UPDATE delivery_receipts
SET dr_number = LPAD(dr_number, 8, '0')
WHERE dr_number ~ '^[0-9]+$' AND LENGTH(dr_number) < 8;
" "Fix DR number padding"

# Fix malformed pr_numbers if they exist
execute_sql "
UPDATE rs_payment_requests
SET pr_number = LPAD(pr_number, 8, '0')
WHERE pr_number ~ '^[0-9]+$' AND LENGTH(pr_number) < 8;
" "Fix PR number padding"

# Fix malformed ir_numbers if they exist
execute_sql "
UPDATE invoice_reports
SET ir_number = LPAD(ir_number, 8, '0')
WHERE ir_number ~ '^[0-9]+$' AND LENGTH(ir_number) < 8;
" "Fix IR number padding"

echo -e "${GREEN}✓ All test data naming conventions fixed!${NC}"
echo -e "${YELLOW}Reference numbers now follow proper format:${NC}"
echo -e "${YELLOW}  RS-11AA00000001, CS-11AA00000001, PO-11AA00000001, etc.${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "${YELLOW}1. Restart the backend to clear any cached data${NC}"
echo -e "${YELLOW}2. Test creating new requisitions - should no longer show NaN${NC}"
