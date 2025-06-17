#!/bin/bash

# Test Force Close Eligibility for Scenario 1
set -e

echo "🔍 Testing Force Close Eligibility for TEST-FC-SCENARIO1..."

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
echo "📡 Step 2: Get requisition details..."

# Get requisition details first
RS_RESPONSE=$(curl -k -s -w "\nHTTP_STATUS:%{http_code}" \
  -X GET "$BASE_URL/v1/requisitions" \
  -H "Authorization: Bearer $TOKEN")

RS_HTTP_STATUS=$(echo "$RS_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RS_BODY=$(echo "$RS_RESPONSE" | sed '/HTTP_STATUS:/d')

if [ "$RS_HTTP_STATUS" = "200" ]; then
  # Find TEST-FC-SCENARIO1 in the response
  SCENARIO1_ID=$(echo "$RS_BODY" | grep -o '"id":[0-9]*[^}]*"rsNumber":"TEST-FC-SCENARIO1"' | grep -o '"id":[0-9]*' | cut -d: -f2)
  
  if [ -n "$SCENARIO1_ID" ]; then
    echo "✅ Found TEST-FC-SCENARIO1 with ID: $SCENARIO1_ID"
  else
    echo "❌ TEST-FC-SCENARIO1 not found in requisitions list"
    exit 1
  fi
else
  echo "❌ Failed to get requisitions list"
  exit 1
fi

echo ""
echo "📡 Step 3: Test force close validation for TEST-FC-SCENARIO1..."

RESPONSE=$(curl -k -s -w "\nHTTP_STATUS:%{http_code}" \
  -X GET "$BASE_URL/v1/requisitions/$SCENARIO1_ID/validate-force-close" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "Status: $HTTP_STATUS"
echo "Response: $BODY"

if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ API call successful"
  
  # Check if eligible
  IS_ELIGIBLE=$(echo "$BODY" | grep -o '"isEligible":[^,}]*' | cut -d: -f2)
  BUTTON_VISIBLE=$(echo "$BODY" | grep -o '"buttonVisible":[^,}]*' | cut -d: -f2)
  
  echo ""
  echo "🔍 Force Close Eligibility Results:"
  echo "  - isEligible: $IS_ELIGIBLE"
  echo "  - buttonVisible: $BUTTON_VISIBLE"
  
  if [ "$IS_ELIGIBLE" = "true" ]; then
    echo "  ✅ TEST-FC-SCENARIO1 is ELIGIBLE for force close!"
    SCENARIO=$(echo "$BODY" | grep -o '"scenario":"[^"]*"' | cut -d'"' -f4)
    echo "  - Scenario: $SCENARIO"
    echo ""
    echo "🎉 SUCCESS! Force Close button should now be visible in the frontend!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Open: https://localhost:8444/dashboard/requisitions/$SCENARIO1_ID"
    echo "2. Look for the RED 'Force Close' button"
    echo "3. Click the button to test the modal"
    echo "4. Fill in the reason and click 'Continue'"
  else
    echo "  ❌ TEST-FC-SCENARIO1 is NOT eligible for force close"
    REASON=$(echo "$BODY" | grep -o '"reason":"[^"]*"' | cut -d'"' -f4)
    echo "  - Reason: $REASON"
    echo ""
    echo "🔧 The test data may need adjustment to meet force close requirements"
  fi
else
  echo "❌ API call failed"
fi
