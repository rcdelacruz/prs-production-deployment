#!/bin/bash

# Find Eligible Force Close Requisition Script
set -e

echo "🔍 Finding requisitions eligible for force close..."

# Configuration
BASE_URL="https://localhost:8444/api"
USERNAME="ronald"
PASSWORD="4842#O2Kv"

echo "📡 Step 1: Login to get token..."
LOGIN_RESPONSE=$(curl -k -s -X POST "$BASE_URL/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")

# Extract token
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get token"
  exit 1
fi

echo "✅ Token obtained"

echo ""
echo "📡 Step 2: Testing multiple requisitions to find eligible ones..."

# Test a range of requisition IDs
ELIGIBLE_COUNT=0
for RS_ID in {1..20} 970 1012; do
  echo ""
  echo "🔍 Testing RS $RS_ID..."
  
  RESPONSE=$(curl -k -s -w "\nHTTP_STATUS:%{http_code}" \
    -X GET "$BASE_URL/v1/requisitions/$RS_ID/validate-force-close" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN")
  
  HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
  BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')
  
  if [ "$HTTP_STATUS" = "200" ]; then
    IS_ELIGIBLE=$(echo "$BODY" | grep -o '"isEligible":[^,}]*' | cut -d: -f2)
    
    if [ "$IS_ELIGIBLE" = "true" ]; then
      echo "  ✅ RS $RS_ID is ELIGIBLE for force close!"
      SCENARIO=$(echo "$BODY" | grep -o '"scenario":"[^"]*"' | cut -d'"' -f4)
      echo "  - Scenario: $SCENARIO"
      ELIGIBLE_COUNT=$((ELIGIBLE_COUNT + 1))
      
      # Get requisition details
      RS_RESPONSE=$(curl -k -s -X GET "$BASE_URL/v1/requisitions/$RS_ID" \
        -H "Authorization: Bearer $TOKEN")
      STATUS=$(echo "$RS_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
      echo "  - Status: $STATUS"
      
      if [ "$STATUS" = "rs_in_progress" ]; then
        echo "  🎯 RS $RS_ID is PERFECT for testing! (eligible + rs_in_progress)"
      fi
    else
      REASON=$(echo "$BODY" | grep -o '"reason":"[^"]*"' | cut -d'"' -f4)
      echo "  ❌ RS $RS_ID is not eligible: $REASON"
    fi
  else
    echo "  ⚠️  RS $RS_ID: HTTP $HTTP_STATUS (may not exist)"
  fi
done

echo ""
echo "📊 Summary:"
echo "  - Total eligible requisitions found: $ELIGIBLE_COUNT"

if [ "$ELIGIBLE_COUNT" -eq 0 ]; then
  echo ""
  echo "🔧 No eligible requisitions found. To test force close, we need to:"
  echo "  1. Create test data with partial deliveries (Scenario 1)"
  echo "  2. Or find requisitions with closed POs and remaining quantities (Scenario 2)"
  echo "  3. Or find requisitions with pending canvass sheets (Scenario 3)"
  echo ""
  echo "💡 Force close eligibility requires specific business conditions:"
  echo "  - Scenario 1: Active POs with partial deliveries"
  echo "  - Scenario 2: Closed POs with remaining quantities"
  echo "  - Scenario 3: Closed POs with pending canvass sheet approvals"
fi
