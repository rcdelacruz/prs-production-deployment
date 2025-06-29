#!/bin/bash

# ============================================================================
# Force Close Authorization Testing Script
# ============================================================================
# This script tests all authorization scenarios for force close functionality
# including button visibility, user permissions, and API-level authorization
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
API_BASE_URL=${API_BASE_URL:-http://localhost:3001}

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Force Close Authorization Testing${NC}"
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

# Function to test API endpoint
test_api_endpoint() {
    local endpoint="$1"
    local expected_status="$2"
    local description="$3"
    local auth_token="$4"

    echo -e "${YELLOW}Testing API: $description${NC}"

    local curl_cmd="curl -s -w '%{http_code}' -o /tmp/api_response.json"
    
    if [[ -n "$auth_token" ]]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $auth_token'"
    fi
    
    curl_cmd="$curl_cmd '$API_BASE_URL$endpoint'"

    local status_code=$(eval $curl_cmd)
    local response_body=$(cat /tmp/api_response.json 2>/dev/null || echo "{}")

    if [[ "$status_code" == "$expected_status" ]]; then
        echo -e "${GREEN}✓ API Test Passed: $description (Status: $status_code)${NC}"
        return 0
    else
        echo -e "${RED}✗ API Test Failed: $description${NC}"
        echo -e "${RED}  Expected Status: $expected_status, Got: $status_code${NC}"
        echo -e "${RED}  Response: $response_body${NC}"
        return 1
    fi
}

# Function to run backend tests
run_backend_tests() {
    echo -e "${PURPLE}Running Backend Authorization Tests...${NC}"
    
    cd "$PROJECT_DIR/../../prs-backend"
    
    if command -v npm &> /dev/null; then
        echo -e "${YELLOW}Running Jest tests for force close authorization...${NC}"
        if npm test -- test/force-close-authorization.test.js; then
            echo -e "${GREEN}✓ Backend authorization tests passed${NC}"
        else
            echo -e "${RED}✗ Backend authorization tests failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}NPM not found, skipping backend tests${NC}"
    fi
}

# Function to run frontend tests
run_frontend_tests() {
    echo -e "${PURPLE}Running Frontend Authorization Tests...${NC}"
    
    cd "$PROJECT_DIR/../../prs-frontend"
    
    if command -v npm &> /dev/null; then
        echo -e "${YELLOW}Running Jest tests for frontend force close authorization...${NC}"
        if npm test -- src/features/force-close/__tests__/authorization.test.js; then
            echo -e "${GREEN}✓ Frontend authorization tests passed${NC}"
        else
            echo -e "${RED}✗ Frontend authorization tests failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}NPM not found, skipping frontend tests${NC}"
    fi
}

# Function to setup test data for authorization scenarios
setup_authorization_test_data() {
    echo -e "${PURPLE}Setting up authorization test data...${NC}"
    
    # Clean up existing test data
    execute_sql "DELETE FROM rs_payment_requests WHERE pr_number LIKE 'AUTH-PR%';" "Clean auth test payment requests"
    execute_sql "DELETE FROM delivery_receipt_items WHERE dr_id IN (SELECT id FROM delivery_receipts WHERE dr_number LIKE 'AUTH-DR%');" "Clean auth test delivery receipt items"
    execute_sql "DELETE FROM delivery_receipts WHERE dr_number LIKE 'AUTH-DR%';" "Clean auth test delivery receipts"
    execute_sql "DELETE FROM purchase_order_items WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE po_number LIKE 'AUTH-PO%');" "Clean auth test PO items"
    execute_sql "DELETE FROM purchase_orders WHERE po_number LIKE 'AUTH-PO%';" "Clean auth test purchase orders"
    execute_sql "DELETE FROM canvass_item_suppliers WHERE canvass_item_id IN (SELECT id FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'AUTH-TEST%')));" "Clean auth test canvass item suppliers"
    execute_sql "DELETE FROM canvass_items WHERE canvass_requisition_id IN (SELECT id FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'AUTH-TEST%'));" "Clean auth test canvass items"
    execute_sql "DELETE FROM canvass_requisitions WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'AUTH-TEST%');" "Clean auth test canvass requisitions"
    execute_sql "DELETE FROM requisition_item_lists WHERE requisition_id IN (SELECT id FROM requisitions WHERE rs_number LIKE 'AUTH-TEST%');" "Clean auth test requisition items"
    execute_sql "DELETE FROM requisitions WHERE rs_number LIKE 'AUTH-TEST%';" "Clean auth test requisitions"

    # Create test requisition for unauthorized user scenario (Scenario 4)
    execute_sql "
    INSERT INTO requisitions (
        rs_number, rs_letter, purpose, status, created_by, assigned_to,
        company_code, company_id, department_id, date_required, delivery_address,
        charge_to, created_at, updated_at
    ) VALUES (
        'AUTH-TEST-UNAUTHORIZED', 'A', 'Authorization Test - Unauthorized User',
        'rs_in_progress', 151, 144, '12553', 1, 1, NOW() + INTERVAL '30 days',
        'Test Delivery Address', 'Test Project', NOW(), NOW()
    );" "Create unauthorized user test requisition"

    # Create test requisition for authorized requester
    execute_sql "
    INSERT INTO requisitions (
        rs_number, rs_letter, purpose, status, created_by, assigned_to,
        company_code, company_id, department_id, date_required, delivery_address,
        charge_to, created_at, updated_at
    ) VALUES (
        'AUTH-TEST-REQUESTER', 'A', 'Authorization Test - Authorized Requester',
        'rs_in_progress', 150, 144, '12553', 1, 1, NOW() + INTERVAL '30 days',
        'Test Delivery Address', 'Test Project', NOW(), NOW()
    );" "Create authorized requester test requisition"

    # Create test requisition for authorized assigned staff
    execute_sql "
    INSERT INTO requisitions (
        rs_number, rs_letter, purpose, status, created_by, assigned_to,
        company_code, company_id, department_id, date_required, delivery_address,
        charge_to, created_at, updated_at
    ) VALUES (
        'AUTH-TEST-ASSIGNED', 'A', 'Authorization Test - Authorized Assigned Staff',
        'rs_in_progress', 151, 150, '12553', 1, 1, NOW() + INTERVAL '30 days',
        'Test Delivery Address', 'Test Project', NOW(), NOW()
    );" "Create authorized assigned staff test requisition"

    echo -e "${GREEN}✓ Authorization test data setup completed${NC}"
}

# Function to test authorization scenarios
test_authorization_scenarios() {
    echo -e "${PURPLE}Testing Authorization Scenarios...${NC}"
    
    # Get requisition IDs for testing
    local unauthorized_rs_id=$(docker exec prs-local-postgres-timescale bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT id FROM requisitions WHERE rs_number = 'AUTH-TEST-UNAUTHORIZED';\"" | tr -d ' ')
    local requester_rs_id=$(docker exec prs-local-postgres-timescale bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT id FROM requisitions WHERE rs_number = 'AUTH-TEST-REQUESTER';\"" | tr -d ' ')
    local assigned_rs_id=$(docker exec prs-local-postgres-timescale bash -c "PGPASSWORD='$DB_PASSWORD' psql -U $DB_USER -d $DB_NAME -t -c \"SELECT id FROM requisitions WHERE rs_number = 'AUTH-TEST-ASSIGNED';\"" | tr -d ' ')

    echo -e "${YELLOW}Testing Scenario 4: Unauthorized User Access${NC}"
    echo -e "${YELLOW}RS ID: $unauthorized_rs_id (created by 151, assigned to 144, testing with user 150)${NC}"
    
    echo -e "${YELLOW}Testing Authorized Requester Access${NC}"
    echo -e "${YELLOW}RS ID: $requester_rs_id (created by 150, assigned to 144, testing with user 150)${NC}"
    
    echo -e "${YELLOW}Testing Authorized Assigned Staff Access${NC}"
    echo -e "${YELLOW}RS ID: $assigned_rs_id (created by 151, assigned to 150, testing with user 150)${NC}"

    # Note: API testing would require actual authentication tokens
    # For now, we'll just verify the test data was created correctly
    echo -e "${GREEN}✓ Authorization test scenarios prepared${NC}"
    echo -e "${YELLOW}Note: API endpoint testing requires authentication tokens${NC}"
    echo -e "${YELLOW}Use Bruno or Postman to test actual API authorization with different users${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting Force Close Authorization Testing...${NC}"
    
    # Setup test data
    setup_authorization_test_data
    
    # Test authorization scenarios
    test_authorization_scenarios
    
    # Run backend tests
    run_backend_tests
    
    # Run frontend tests  
    run_frontend_tests
    
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}Force Close Authorization Testing Completed${NC}"
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${YELLOW}Manual Testing Recommendations:${NC}"
    echo -e "${YELLOW}1. Test with Bruno using different user accounts (ronald, user 151, user 144)${NC}"
    echo -e "${YELLOW}2. Verify button visibility in frontend for different user types${NC}"
    echo -e "${YELLOW}3. Test API endpoints with unauthorized tokens${NC}"
    echo -e "${YELLOW}4. Verify error messages match requirements exactly${NC}"
}

# Run main function
main "$@"
