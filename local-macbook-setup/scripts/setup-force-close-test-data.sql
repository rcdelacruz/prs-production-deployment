-- ============================================================================
-- Force Close Test Data Setup Script
-- ============================================================================
-- This script creates test requisitions in various statuses for testing
-- the force close functionality. Run this script whenever you need fresh
-- test data for force close testing.
--
-- Usage:
--   docker exec -it prs-local-postgres psql -U prs_user -d prs_local -f /scripts/setup-force-close-test-data.sql
--
-- Or manually:
--   docker exec -it prs-local-postgres psql -U prs_user -d prs_local
--   \i /scripts/setup-force-close-test-data.sql
-- ============================================================================

-- Clean up any existing test data first (in proper order to avoid foreign key issues)
DELETE FROM requisition_approvers WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM requisition_item_lists WHERE requisition_id IN (
    SELECT id FROM requisitions WHERE rs_number LIKE 'TEST-FC-%'
);
DELETE FROM requisitions WHERE rs_number LIKE 'TEST-FC-%';
DELETE FROM projects WHERE code LIKE 'TEST-PROJ-%';

-- Create test project for force close testing
INSERT INTO projects (code, name, initial, address, company_code, created_at, updated_at)
VALUES ('TEST-PROJ-FC', 'Test Project for Force Close Testing', 'TPFC', 'Test Project Address', '12553', NOW(), NOW());

-- Get the project ID (should be consistent)
-- Note: We'll use a fixed project ID approach for consistency

-- Create test requisitions with different statuses eligible for force close
INSERT INTO requisitions (
    rs_number, rs_letter, company_code, created_by, company_id, department_id, project_id,
    date_required, delivery_address, purpose, charge_to, status, type, assigned_to,
    created_at, updated_at
) VALUES
-- Test RS 1: Submitted status (eligible for force close)
('TEST-FC-SUBMITTED', 'A', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Force Close Testing - Submitted Status', 'Test Project',
 'submitted', 'regular', 144,
 NOW(), NOW()),

-- Test RS 2: Assigned status (eligible for force close)
('TEST-FC-ASSIGNED', 'B', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Force Close Testing - Assigned Status', 'Test Project',
 'assigned', 'regular', 144,
 NOW(), NOW()),

-- Test RS 3: Canvass Approval status (eligible for force close)
('TEST-FC-CANVASS-APPROVAL', 'C', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Force Close Testing - Canvass Approval Status', 'Test Project',
 'canvass_approval', 'regular', 21,
 NOW(), NOW()),

-- Test RS 4: Partially Canvassed status (eligible for force close)
('TEST-FC-PARTIAL-CANVASS', 'D', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Force Close Testing - Partially Canvassed Status', 'Test Project',
 'partially_canvassed', 'regular', 21,
 NOW(), NOW()),

-- Test RS 5: For Purchase Order scenario (if needed)
('TEST-FC-PO-SCENARIO', 'E', '12553', 150, 751, 1,
 (SELECT id FROM projects WHERE code = 'TEST-PROJ-FC'),
 '2024-12-31', 'Test Delivery Address', 'Force Close Testing - PO Scenario', 'Test Project',
 'po_creation', 'regular', 144,
 NOW(), NOW());

-- Add items to test requisitions to make them realistic
INSERT INTO requisition_item_lists (requisition_id, item_id, item_type, quantity, notes, account_code, created_at, updated_at)
VALUES
-- Items for TEST-FC-SUBMITTED
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SUBMITTED'), 7, 'non_ofm', 10, 'Test item for force close - submitted', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SUBMITTED'), 28, 'non_ofm', 5, 'Another test item - submitted', '12345', NOW(), NOW()),

-- Items for TEST-FC-ASSIGNED
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-ASSIGNED'), 7, 'non_ofm', 15, 'Test item for force close - assigned', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-ASSIGNED'), 28, 'non_ofm', 8, 'Another test item - assigned', '12345', NOW(), NOW()),

-- Items for TEST-FC-CANVASS-APPROVAL
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-CANVASS-APPROVAL'), 28, 'non_ofm', 20, 'Test item for force close - canvass approval', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-CANVASS-APPROVAL'), 7, 'non_ofm', 12, 'Another test item - canvass approval', '12345', NOW(), NOW()),

-- Items for TEST-FC-PARTIAL-CANVASS
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PARTIAL-CANVASS'), 7, 'non_ofm', 8, 'Test item for force close - partial canvass', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PARTIAL-CANVASS'), 28, 'non_ofm', 6, 'Another test item - partial canvass', '12345', NOW(), NOW()),

-- Items for TEST-FC-PO-SCENARIO
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PO-SCENARIO'), 7, 'non_ofm', 25, 'Test item for force close - PO scenario', '12345', NOW(), NOW()),
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PO-SCENARIO'), 28, 'non_ofm', 15, 'Another test item - PO scenario', '12345', NOW(), NOW());

-- Add requisition approvers for proper approval workflow
INSERT INTO requisition_approvers (
    requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status,
    created_at, updated_at
) VALUES
-- Approvers for TEST-FC-SUBMITTED
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SUBMITTED'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-SUBMITTED'), 144, 1, false, 'requisition', 'pending', NOW(), NOW()),

-- Approvers for TEST-FC-ASSIGNED
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-ASSIGNED'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-ASSIGNED'), 144, 1, false, 'requisition', 'pending', NOW(), NOW()),

-- Approvers for TEST-FC-CANVASS-APPROVAL
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-CANVASS-APPROVAL'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-CANVASS-APPROVAL'), 21, 1, false, 'requisition', 'approved', NOW(), NOW()),

-- Approvers for TEST-FC-PARTIAL-CANVASS
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PARTIAL-CANVASS'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PARTIAL-CANVASS'), 21, 1, false, 'requisition', 'approved', NOW(), NOW()),

-- Approvers for TEST-FC-PO-SCENARIO
((SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PO-SCENARIO'), (SELECT id FROM requisitions WHERE rs_number = 'TEST-FC-PO-SCENARIO'), 144, 1, false, 'requisition', 'approved', NOW(), NOW());

-- Display the created test data
SELECT
    r.id,
    r.rs_number,
    r.status,
    r.created_by,
    COUNT(ril.id) as item_count,
    c.name as company_name,
    p.name as project_name
FROM requisitions r
JOIN companies c ON r.company_id = c.id
JOIN projects p ON r.project_id = p.id
LEFT JOIN requisition_item_lists ril ON r.id = ril.requisition_id
WHERE r.rs_number LIKE 'TEST-FC-%'
GROUP BY r.id, r.rs_number, r.status, r.created_by, c.name, p.name
ORDER BY r.rs_number;

-- Display summary
\echo ''
\echo '============================================================================'
\echo 'Force Close Test Data Setup Complete!'
\echo '============================================================================'
\echo 'Created test requisitions:'
\echo '- TEST-FC-SUBMITTED (submitted status)'
\echo '- TEST-FC-ASSIGNED (assigned status)'
\echo '- TEST-FC-CANVASS-APPROVAL (canvass_approval status)'
\echo '- TEST-FC-PARTIAL-CANVASS (partially_canvassed status)'
\echo '- TEST-FC-PO-SCENARIO (po_creation status)'
\echo ''
\echo 'All requisitions are owned by user ronald (ID: 150)'
\echo 'All requisitions have items and proper foreign key relationships'
\echo ''
\echo 'To test:'
\echo '1. Login to https://localhost:8444 with ronald / 4842#O2Kv'
\echo '2. Go to Dashboard and look for TEST-FC-* requisitions'
\echo '3. Click on any requisition to test Force Close functionality'
\echo '============================================================================'
