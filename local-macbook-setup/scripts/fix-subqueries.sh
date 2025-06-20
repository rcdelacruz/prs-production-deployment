#!/bin/bash

# Fix all subquery issues in the comprehensive force close script
echo "Fixing subquery issues in setup-force-close-comprehensive.sh..."

# Fix requisition subqueries
sed -i '' \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1)/g" \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1)/g" \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1)/g" \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO4' LIMIT 1)/g" \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO5' LIMIT 1)/g" \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO6' LIMIT 1)/g" \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO7' LIMIT 1)/g" \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO8' LIMIT 1)/g" \
-e "s/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9')/(SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO9' LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix project subqueries
sed -i '' \
-e "s/(SELECT id FROM projects WHERE code = 'TEST-PROJ-FC')/(SELECT id FROM projects WHERE code = 'TEST-PROJ-FC' LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix canvass requisition subqueries
sed -i '' \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-01' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-02' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-03')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-03' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3A' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3B')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-3B' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-04' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-05')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-05' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-06' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-07' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-08' LIMIT 1)/g" \
-e "s/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09')/(SELECT id FROM canvass_requisitions WHERE cs_number = 'FC-CS-09' LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix purchase order subqueries
sed -i '' \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-001' LIMIT 1)/g" \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-002' LIMIT 1)/g" \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-003' LIMIT 1)/g" \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-004' LIMIT 1)/g" \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-005')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-005' LIMIT 1)/g" \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-006')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-006' LIMIT 1)/g" \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-007')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-007' LIMIT 1)/g" \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-008' LIMIT 1)/g" \
-e "s/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009')/(SELECT id FROM purchase_orders WHERE po_number = 'TEST-PO-009' LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix delivery receipt subqueries
sed -i '' \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001' LIMIT 1)/g" \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002' LIMIT 1)/g" \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003' LIMIT 1)/g" \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-004')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-004' LIMIT 1)/g" \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-005')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-005' LIMIT 1)/g" \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-006')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-006' LIMIT 1)/g" \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-007')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-007' LIMIT 1)/g" \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-008')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-008' LIMIT 1)/g" \
-e "s/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-009')/(SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-009' LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix payment request subqueries
sed -i '' \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-01')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-01' LIMIT 1)/g" \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-02')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-02' LIMIT 1)/g" \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-03')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-03' LIMIT 1)/g" \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-04')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-04' LIMIT 1)/g" \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-05')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-05' LIMIT 1)/g" \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-06')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-06' LIMIT 1)/g" \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-07')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-07' LIMIT 1)/g" \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-08')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-08' LIMIT 1)/g" \
-e "s/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-09')/(SELECT id FROM rs_payment_requests WHERE pr_number = 'FC-PR-09' LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix supplier subqueries
sed -i '' \
-e "s/(SELECT id FROM suppliers LIMIT 1)/(SELECT id FROM suppliers LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix item subqueries
sed -i '' \
-e "s/(SELECT itm_des FROM items WHERE id = 7)/(SELECT itm_des FROM items WHERE id = 7 LIMIT 1)/g" \
-e "s/(SELECT itm_des FROM items WHERE id = 28)/(SELECT itm_des FROM items WHERE id = 28 LIMIT 1)/g" \
-e "s/(SELECT unit FROM items WHERE id = 7)/(SELECT unit FROM items WHERE id = 7 LIMIT 1)/g" \
-e "s/(SELECT unit FROM items WHERE id = 28)/(SELECT unit FROM items WHERE id = 28 LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix complex nested subqueries for requisition_item_lists
sed -i '' \
-e "s/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 7)/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 7 LIMIT 1)/g" \
-e "s/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 28)/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO1' LIMIT 1) AND item_id = 28 LIMIT 1)/g" \
-e "s/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 7)/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 7 LIMIT 1)/g" \
-e "s/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 28)/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO2' LIMIT 1) AND item_id = 28 LIMIT 1)/g" \
-e "s/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7)/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 7 LIMIT 1)/g" \
-e "s/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28)/requisition_id = (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SCENARIO3' LIMIT 1) AND item_id = 28 LIMIT 1)/g" \
setup-force-close-comprehensive.sh

# Fix delivery_receipt_invoices subqueries
sed -i '' \
-e "s/delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001' LIMIT 1))/delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-001' LIMIT 1) LIMIT 1)/g" \
-e "s/delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002' LIMIT 1))/delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-002' LIMIT 1) LIMIT 1)/g" \
-e "s/delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003' LIMIT 1))/delivery_receipt_id = (SELECT id FROM delivery_receipts WHERE dr_number = 'TEST-DR-003' LIMIT 1) LIMIT 1)/g" \
setup-force-close-comprehensive.sh

echo "Fixed all subquery issues!"
echo "Now testing the script..."
