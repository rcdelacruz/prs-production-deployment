#!/bin/bash

echo "🔍 Debugging Frontend Force Close Issues..."

# Check if the frontend is making API calls
echo "📡 Checking backend logs for force close API calls..."
docker logs prs-local-backend --tail=50 | grep -i "force\|validate" || echo "No force close API calls found in recent logs"

echo ""
echo "📡 Checking nginx logs for API requests..."
docker logs prs-local-nginx --tail=20 | grep -i "validate-force-close" || echo "No force close API requests found in nginx logs"

echo ""
echo "🔍 Let's check what's actually in the frontend build..."
echo "Checking if force close components are built correctly..."

# Check if the force close files exist in the frontend container
docker exec prs-local-frontend ls -la /app/src/features/force-close/ 2>/dev/null || echo "Force close directory not found"

echo ""
echo "🔍 Let's test the exact requisition that should work..."
echo "RS 970 details from our API test:"
echo "  - Status: rs_in_progress ✅"
echo "  - ButtonVisible: true ✅"
echo "  - User: ronald (ID: 150) ✅"
echo "  - IsEligible: false (but button should still show)"

echo ""
echo "🔍 Checking if there are JavaScript errors..."
echo "Please open browser console and check for errors at:"
echo "https://localhost:8444/dashboard/requisitions/970"

echo ""
echo "🔍 Let's also check the exact frontend logic..."
echo "The button should show when:"
echo "  1. isRequestor = true"
echo "  2. requisition.status = 'rs_in_progress'"
echo ""
echo "Let's verify these conditions are met..."
