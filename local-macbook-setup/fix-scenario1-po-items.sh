#!/bin/bash

# Fix Scenario 1 by adding PO items
set -e

echo "🔧 Fixing TEST-FC-SCENARIO1 by adding PO items..."

# Add PO items to make the force close validation work
docker exec prs-local-postgres bash -c "PGPASSWORD='localdev123' psql -U prs_user -d prs_local" << 'EOF'

-- Add purchase order items for TEST-PO-001
-- We'll create simple PO items that match the delivery receipt items

INSERT INTO purchase_order_items (
    purchase_order_id, item_id, item_description, quantity, unit_price, unit,
    created_at, updated_at
) VALUES
-- Item 1: 100 pieces ordered, 60 delivered (partial)
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'), 
 7, 'Test Item 1', 100, 10.00, 'pcs', NOW(), NOW()),

-- Item 2: 50 pieces ordered, 30 delivered (partial)  
((SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
 28, 'Test Item 2', 50, 15.00, 'pcs', NOW(), NOW());

-- Verify the PO now has items
SELECT 
    po.po_number,
    po.status,
    COUNT(poi.id) as item_count,
    SUM(poi.quantity) as total_ordered
FROM purchase_orders po
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
WHERE po.po_number = 'TEST-PO-001'
GROUP BY po.id, po.po_number, po.status;

-- Verify delivery receipt items match PO items
SELECT 
    'Delivery vs PO comparison:' as info;
    
SELECT 
    dr.dr_number,
    dri.item_id,
    dri.qty_ordered,
    dri.qty_delivered,
    ROUND((dri.qty_delivered::decimal / dri.qty_ordered * 100), 2) as delivery_percentage
FROM delivery_receipts dr
JOIN delivery_receipt_items dri ON dr.id = dri.dr_id
WHERE dr.dr_number = 'TEST-DR-001';

EOF

if [ $? -eq 0 ]; then
    echo "✅ PO items added successfully!"
    echo ""
    echo "🔍 Now testing force close eligibility again..."
    
    # Get token
    TOKEN=$(curl -k -s -X POST "https://localhost:8444/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"username": "ronald", "password": "4842#O2Kv"}' | \
        grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$TOKEN" ]; then
        echo "✅ Token obtained"
        
        # Test force close validation
        RESPONSE=$(curl -k -s -X GET "https://localhost:8444/api/v1/requisitions/1013/validate-force-close" \
            -H "Authorization: Bearer $TOKEN")
        
        echo ""
        echo "📡 Force Close Validation Result:"
        echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
        
        # Check if eligible
        IS_ELIGIBLE=$(echo "$RESPONSE" | grep -o '"isEligible":[^,}]*' | cut -d: -f2)
        
        if [ "$IS_ELIGIBLE" = "true" ]; then
            echo ""
            echo "🎉 SUCCESS! TEST-FC-SCENARIO1 is now ELIGIBLE for force close!"
            echo ""
            echo "📋 Test the Force Close Button:"
            echo "1. Open: https://localhost:8444/dashboard/requisitions/1013"
            echo "2. Look for the RED 'Force Close' button"
            echo "3. Click the button to test the modal"
        else
            echo ""
            echo "❌ Still not eligible. May need further adjustments."
        fi
    else
        echo "❌ Failed to get authentication token"
    fi
else
    echo "❌ Failed to add PO items"
    exit 1
fi
