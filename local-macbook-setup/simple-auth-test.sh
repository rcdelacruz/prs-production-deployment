#!/bin/bash

# Simple authentication test
echo "Testing authentication..."

response=$(curl -k -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"rootuser","password":"rootuser"}' \
    "https://localhost:8444/api/v1/auth/login" 2>/dev/null)

# Extract status code and body
status_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | sed '$d')

echo "Status Code: $status_code"
echo "Response Body: $body"

if [ "$status_code" = "200" ]; then
    if command -v jq &> /dev/null; then
        token=$(echo "$body" | jq -r '.accessToken')
        echo "Token extracted: $token"
        
        # Test a simple API call
        echo ""
        echo "Testing API call with token..."
        api_response=$(curl -k -s -w "\n%{http_code}" \
            -H "Authorization: Bearer $token" \
            "https://localhost:8444/api/v1/requisitions?limit=1" 2>/dev/null)
        
        api_status=$(echo "$api_response" | tail -n 1)
        api_body=$(echo "$api_response" | sed '$d')
        
        echo "API Status: $api_status"
        echo "API Response: $api_body"
    else
        echo "jq not available"
    fi
else
    echo "Authentication failed"
fi
