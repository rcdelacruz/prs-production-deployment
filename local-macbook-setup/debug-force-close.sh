#!/bin/bash

# Debug Force Close API Script
set -e

echo "🔍 Debugging Force Close API..."

# Configuration
BASE_URL="https://localhost:8444/api"
USERNAME="ronald"
PASSWORD="4842#O2Kv"

echo "📡 Step 1: Login to get token..."
LOGIN_RESPONSE=$(curl -k -s -X POST "$BASE_URL/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")

echo "Login Response: $LOGIN_RESPONSE"

# Extract token
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get token"
  exit 1
fi

echo "✅ Token obtained: ${TOKEN:0:20}..."

echo ""
echo "📡 Step 2: Test force close validation for different requisitions..."

# Test multiple requisition IDs
for RS_ID in 970 1012 1 2 3; do
  echo ""
  echo "🔍 Testing RS $RS_ID..."
  
  RESPONSE=$(curl -k -s -w "\nHTTP_STATUS:%{http_code}" \
    -X GET "$BASE_URL/v1/requisitions/$RS_ID/validate-force-close" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN")
  
  HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
  BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')
  
  echo "Status: $HTTP_STATUS"
  echo "Response: $BODY"
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ API call successful for RS $RS_ID"
    
    # Check if eligible
    IS_ELIGIBLE=$(echo "$BODY" | grep -o '"isEligible":[^,}]*' | cut -d: -f2)
    BUTTON_VISIBLE=$(echo "$BODY" | grep -o '"buttonVisible":[^,}]*' | cut -d: -f2)
    
    echo "  - isEligible: $IS_ELIGIBLE"
    echo "  - buttonVisible: $BUTTON_VISIBLE"
    
    if [ "$IS_ELIGIBLE" = "true" ]; then
      echo "  ✅ RS $RS_ID is eligible for force close"
    else
      echo "  ❌ RS $RS_ID is NOT eligible for force close"
      REASON=$(echo "$BODY" | grep -o '"reason":"[^"]*"' | cut -d'"' -f4)
      echo "  - Reason: $REASON"
    fi
  else
    echo "❌ API call failed for RS $RS_ID"
  fi
done

echo ""
echo "📡 Step 3: Check requisition status for RS 970..."
RS_RESPONSE=$(curl -k -s -w "\nHTTP_STATUS:%{http_code}" \
  -X GET "$BASE_URL/v1/requisitions/970" \
  -H "Authorization: Bearer $TOKEN")

RS_HTTP_STATUS=$(echo "$RS_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
RS_BODY=$(echo "$RS_RESPONSE" | sed '/HTTP_STATUS:/d')

echo "Requisition Status: $RS_HTTP_STATUS"
if [ "$RS_HTTP_STATUS" = "200" ]; then
  STATUS=$(echo "$RS_BODY" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
  CREATED_BY=$(echo "$RS_BODY" | grep -o '"createdBy":[^,}]*' | cut -d: -f2)
  echo "  - RS Status: $STATUS"
  echo "  - Created By: $CREATED_BY"
else
  echo "❌ Failed to get requisition details"
fi

echo ""
echo "🔍 Debug Summary:"
echo "- Login: ✅"
echo "- API Endpoint: $BASE_URL/v1/requisitions/{id}/validate-force-close"
echo "- Token: ✅"
echo "- Test completed"
