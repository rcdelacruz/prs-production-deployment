-- ============================================================================
-- Fix PO Items for Force Close Testing
-- ============================================================================
-- This script adds the missing PO items to make TEST-FC-SCENARIO1 eligible for force close
-- The issue is that the PO was created without items, which makes force close validation fail
-- ============================================================================

-- First, let's check what we have
SELECT 'CURRENT STATE:' as status;
SELECT 
    r.rs_number,
    po.po_number,
    po.status as po_status,
    COUNT(poi.id) as po_item_count,
    COUNT(dri.id) as delivery_item_count
FROM requisitions r
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
LEFT JOIN delivery_receipts dr ON r.id = dr.requisition_id
LEFT JOIN delivery_receipt_items dri ON dr.id = dri.dr_id
WHERE r.rs_number = 'TEST-FC-SCENARIO1'
GROUP BY r.id, r.rs_number, po.po_number, po.status;

-- Get the IDs we need
\set requisition_id (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1')
\set po_id (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001')
\set canvass_id (SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01')

-- Get requisition item list IDs
SELECT 'REQUISITION ITEMS:' as status;
SELECT id, item_id, quantity, notes 
FROM requisition_item_lists 
WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1');

-- Create PO items that match the requisition items and delivery receipt items
-- We need to create PO items that correspond to what was delivered

-- For item_id 7 (100 ordered, 60 delivered)
INSERT INTO purchase_order_items (
    purchase_order_id,
    requisition_item_list_id,
    item_id,
    item_description,
    quantity_purchased,
    unit_price,
    total_amount,
    unit,
    created_at,
    updated_at
) VALUES (
    (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
    (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 7),
    7,
    'Test Item 1 for Force Close',
    100,
    10.00,
    1000.00,
    'pcs',
    NOW(),
    NOW()
);

-- For item_id 28 (50 ordered, 30 delivered)
INSERT INTO purchase_order_items (
    purchase_order_id,
    requisition_item_list_id,
    item_id,
    item_description,
    quantity_purchased,
    unit_price,
    total_amount,
    unit,
    created_at,
    updated_at
) VALUES (
    (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001'),
    (SELECT id FROM requisition_item_lists WHERE requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1') AND item_id = 28),
    28,
    'Test Item 2 for Force Close',
    50,
    15.00,
    750.00,
    'pcs',
    NOW(),
    NOW()
);

-- Verify the PO items were created
SELECT 'PO ITEMS AFTER FIX:' as status;
SELECT 
    poi.id,
    poi.item_id,
    poi.item_description,
    poi.quantity_purchased,
    poi.unit_price,
    poi.total_amount
FROM purchase_order_items poi
WHERE poi.purchase_order_id = (SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001');

-- Verify the complete scenario
SELECT 'COMPLETE SCENARIO VERIFICATION:' as status;
SELECT 
    r.rs_number,
    r.status as rs_status,
    po.po_number,
    po.status as po_status,
    COUNT(DISTINCT poi.id) as po_items,
    COUNT(DISTINCT dri.id) as delivery_items,
    SUM(poi.quantity_purchased) as total_ordered,
    SUM(dri.qty_delivered) as total_delivered,
    ROUND(SUM(dri.qty_delivered) / SUM(poi.quantity_purchased) * 100, 2) as delivery_percentage
FROM requisitions r
LEFT JOIN purchase_orders po ON r.id = po.requisition_id
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
LEFT JOIN delivery_receipts dr ON r.id = dr.requisition_id
LEFT JOIN delivery_receipt_items dri ON dr.id = dri.dr_id
WHERE r.rs_number = 'TEST-FC-SCENARIO1'
GROUP BY r.id, r.rs_number, r.status, po.po_number, po.status;

-- Show what should make this eligible for force close
SELECT 'FORCE CLOSE ELIGIBILITY FACTORS:' as status;
SELECT 
    'Active PO with partial deliveries that are paid' as scenario,
    po.status as po_status,
    pr.status as payment_status,
    CASE 
        WHEN SUM(dri.qty_delivered) < SUM(poi.quantity_purchased) THEN 'Partial delivery (eligible for force close)'
        ELSE 'Full delivery'
    END as delivery_status
FROM purchase_orders po
LEFT JOIN purchase_order_items poi ON po.id = poi.purchase_order_id
LEFT JOIN delivery_receipts dr ON po.requisition_id = dr.requisition_id
LEFT JOIN delivery_receipt_items dri ON dr.id = dri.dr_id
LEFT JOIN rs_payment_requests pr ON po.requisition_id = pr.requisition_id
WHERE po.po_number = 'TEST-PO-001'
GROUP BY po.status, pr.status;
